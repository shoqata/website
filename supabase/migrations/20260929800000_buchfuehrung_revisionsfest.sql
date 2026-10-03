-- Die Buchhaltung revisionsfest machen.
--
-- Gemessen am 03.10.2026 fehlten vier Dinge, die eine Revision verlangt
-- (OR 957a: vollstaendig, wahrheitsgetreu, systematisch, nachpruefbar):
--
--   1. Buchungen liessen sich spurlos aendern und loeschen. Die Regel
--      accounting_journal_staff ist FOR ALL -- kein Protokoll, kein Archiv.
--      Ein Revisor konnte nicht ausschliessen, dass im Januar gebuchte
--      Zahlen im Juni anders lauteten.
--   2. Keine fortlaufende Belegnummer.
--   3. Die Sperre abgeschlossener Jahre stand nur im Browser. Wer die
--      Schnittstelle direkt ansprach, buchte munter in geschlossene Jahre.
--   4. Kein vollstaendiger Export und kein Revisorenzugang -- das folgt in
--      einer eigenen Migration.
--
-- accounting_journal_archiv bleibt unberuehrt: dort stehen 14 Zeilen aus
-- einer Aufraeumaktion vom 18.09.2026. Das ist ein historischer Beleg, kein
-- Protokoll -- es wird aber im Export mitgezeigt, damit nichts verschwiegen
-- ist.


-- ---------------------------------------------------- 1. Belegnummer
ALTER TABLE public.accounting_journal ADD COLUMN IF NOT EXISTS belegnr int;

-- Die vorhandenen Buchungen nachnummerieren, je Verein und Jahr in der
-- Reihenfolge, in der sie entstanden sind.
UPDATE public.accounting_journal j
   SET belegnr = n.nr
  FROM (SELECT id,
               row_number() OVER (PARTITION BY "tenantId", substr(date,1,4)
                                  ORDER BY date, "createdAt", id) AS nr
          FROM public.accounting_journal) n
 WHERE j.id = n.id AND j.belegnr IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS accounting_journal_belegnr_je_jahr
  ON public.accounting_journal ("tenantId", substr(date,1,4), belegnr);

CREATE OR REPLACE FUNCTION public.belegnummer_vergeben()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.belegnr IS NULL THEN
    SELECT coalesce(max(belegnr), 0) + 1 INTO NEW.belegnr
      FROM public.accounting_journal
     WHERE "tenantId" = NEW."tenantId" AND substr(date,1,4) = substr(NEW.date,1,4);
  END IF;
  RETURN NEW;
END $$;

-- Name mit "zz", damit der Ausloeser NACH accounting_journal_set_tenant
-- laeuft: ohne gesetzten Verein koennte er nicht zaehlen. BEFORE-Ausloeser
-- feuern in alphabetischer Reihenfolge.
DROP TRIGGER IF EXISTS accounting_journal_zz_belegnr ON public.accounting_journal;
CREATE TRIGGER accounting_journal_zz_belegnr
  BEFORE INSERT ON public.accounting_journal
  FOR EACH ROW EXECUTE FUNCTION public.belegnummer_vergeben();


-- ------------------------------------------------- 2. Aenderungsprotokoll
--
-- NACH der Nachnummerierung angelegt. Stuende der Ausloeser vorher, haette
-- das Nachtragen der Belegnummern jede der 410 bestehenden Buchungen als
-- "AENDERUNG" ins Protokoll geschrieben -- 410 Scheineintraege am ersten
-- Tag, ohne Urheber, mit identischem Vorher und Nachher. Ein Protokoll,
-- das mit Rauschen beginnt, liest niemand.
CREATE TABLE IF NOT EXISTS public.buchungsprotokoll (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  buchung_id  text NOT NULL,
  vorgang     text NOT NULL CHECK (vorgang IN ('AENDERUNG','LOESCHUNG')),
  vorher      jsonb NOT NULL,
  nachher     jsonb,
  wer         text,
  wer_email   text,
  wann        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS buchungsprotokoll_verein_zeit
  ON public.buchungsprotokoll ("tenantId", wann DESC);
CREATE INDEX IF NOT EXISTS buchungsprotokoll_buchung
  ON public.buchungsprotokoll ("tenantId", buchung_id);

ALTER TABLE public.buchungsprotokoll ENABLE ROW LEVEL SECURITY;

-- Lesen darf der Vorstand des eigenen Vereins. SCHREIBEN darf niemand --
-- auch der Vorstand nicht. Eintraege entstehen allein durch den Ausloeser,
-- und der laeuft als SECURITY DEFINER an den Regeln vorbei. Ein Protokoll,
-- das der Protokollierte aendern kann, ist keins.
DROP POLICY IF EXISTS buchungsprotokoll_lesen ON public.buchungsprotokoll;
CREATE POLICY buchungsprotokoll_lesen ON public.buchungsprotokoll
  FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());
REVOKE ALL ON public.buchungsprotokoll FROM authenticated, anon;
GRANT SELECT ON public.buchungsprotokoll TO authenticated;

CREATE OR REPLACE FUNCTION public.buchung_protokollieren()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_wer text;
  v_mail text;
BEGIN
  -- Wer es war. Ueber die Benutzerzeile, nicht ueber auth.uid() allein:
  -- die Zeilenkennung ist das, was anderswo in den Daten steht.
  SELECT u.id, u.email INTO v_wer, v_mail
    FROM public.users u
   WHERE u."authUserId" = nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
   LIMIT 1;

  INSERT INTO public.buchungsprotokoll
    ("tenantId", buchung_id, vorgang, vorher, nachher, wer, wer_email)
  VALUES (OLD."tenantId", OLD.id,
          CASE WHEN TG_OP = 'DELETE' THEN 'LOESCHUNG' ELSE 'AENDERUNG' END,
          to_jsonb(OLD),
          CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
          v_wer, v_mail);
  RETURN NULL;   -- AFTER-Ausloeser
END $$;

DROP TRIGGER IF EXISTS accounting_journal_protokoll ON public.accounting_journal;
CREATE TRIGGER accounting_journal_protokoll
  AFTER UPDATE OR DELETE ON public.accounting_journal
  FOR EACH ROW EXECUTE FUNCTION public.buchung_protokollieren();


-- -------------------------------------- 3. Abgeschlossene Jahre sperren
CREATE OR REPLACE FUNCTION public.geschlossenes_jahr_schuetzen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_zeile record;
  v_jahr int;
BEGIN
  v_zeile := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
  v_jahr := substr(v_zeile.date, 1, 4)::int;

  IF EXISTS (SELECT 1 FROM public.fiscal_years
              WHERE "tenantId" = v_zeile."tenantId" AND year = v_jahr AND status = 'CLOSED') THEN
    RAISE EXCEPTION
      'Das Geschaeftsjahr % ist abgeschlossen. Buchungen koennen nicht mehr geaendert werden.', v_jahr
      USING ERRCODE = 'restrict_violation';
  END IF;

  -- Bei einer Aenderung zaehlt auch das ALTE Jahr: sonst liesse sich eine
  -- Buchung aus einem geschlossenen Jahr herausdatieren und damit doch
  -- noch anfassen.
  IF TG_OP = 'UPDATE' AND substr(OLD.date,1,4) <> substr(NEW.date,1,4) THEN
    IF EXISTS (SELECT 1 FROM public.fiscal_years
                WHERE "tenantId" = OLD."tenantId"
                  AND year = substr(OLD.date,1,4)::int AND status = 'CLOSED') THEN
      RAISE EXCEPTION
        'Die Buchung gehoert ins abgeschlossene Jahr %. Sie laesst sich nicht umdatieren.',
        substr(OLD.date,1,4) USING ERRCODE = 'restrict_violation';
    END IF;
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;

DROP TRIGGER IF EXISTS accounting_journal_jahressperre ON public.accounting_journal;
CREATE TRIGGER accounting_journal_jahressperre
  BEFORE INSERT OR UPDATE OR DELETE ON public.accounting_journal
  FOR EACH ROW EXECUTE FUNCTION public.geschlossenes_jahr_schuetzen();
