-- Postversand ueber Pingen.
--
-- Gemessen, warum das zaehlt: von 348 Rechnungen gehen 241 per Post --
-- meist weil keine brauchbare E-Mail-Adresse vorliegt. Der Postweg ist
-- hier also der Hauptweg und nicht die Ausnahme, und er lief bisher von
-- Hand: drucken, kuvertieren, frankieren.
--
-- Aufgebaut wie die Mail-Warteschlange, und aus demselben Grund: ein
-- Versand, der im Augenblick des Klicks geschieht, hat keinen zweiten
-- Versuch und keinen sichtbaren Zustand. Beim Mailversand hat uns das
-- wochenlang unbemerkt stillstehen lassen.
--
-- Die Regeln von Pingen bestimmen den Aufbau:
--
--   1 PDF = 1 Brief. Alles im selben PDF landet im selben Kuvert. Also
--   genau eine Zeile je Brief, mit genau einem PDF -- keine Liste von
--   Anhaengen wie bei der Mail.
--
--   Nur A4 auf Standardpapier. Keine Beilagen, kein Spezialpapier.
--
--   Die Empfaengeradresse muss auf Seite 1 in der Adresszone liegen,
--   und die Sperrbereiche muessen frei bleiben. Welche Millimeter das
--   genau sind, rate ich NICHT: Pingen prueft es selbst und meldet
--   "PDF hat Inhalte in den Sperrbereichen" ueber den Webhook. In der
--   Testumgebung kostet dieser Irrtum nichts, in der echten ein
--   abgewiesener Brief.
--
--   Unzustellbare Briefe werden ungeoeffnet vernichtet und melden sich
--   als "Unzustellbar". Das ist eine Tatsache, die der Verein erfahren
--   muss -- eine Adresse, an die nichts ankommt, bleibt sonst jahrelang
--   in der Liste.

CREATE TABLE IF NOT EXISTS public.post_ausgang (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  -- Welche Rechnung. Nullable, weil spaeter auch Mahnungen und andere
  -- Schreiben hier hineingehen koennen.
  "paymentId"   text,
  "memberId"    text,
  empfaenger    text NOT NULL,
  dateiname     text NOT NULL,
  pdf           text NOT NULL,            -- base64, genau ein Dokument
  -- Druckoptionen. Die Vorgaben sind bewusst die guenstigen: ein
  -- Verein mit 241 Briefen im Jahr zahlt den Unterschied.
  produkt       text NOT NULL DEFAULT 'cheap',
  farbe         text NOT NULL DEFAULT 'grayscale',
  duplex        boolean NOT NULL DEFAULT true,
  adresslage    text NOT NULL DEFAULT 'left',
  zustand       text NOT NULL DEFAULT 'WARTEND',
  pingen_id     text,
  pingen_status text,
  pingen_meldung text,
  versuche      integer NOT NULL DEFAULT 0,
  letzter_fehler text,
  naechster_versuch timestamptz NOT NULL DEFAULT now(),
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  uebergeben_am timestamptz,
  erledigt_am   timestamptz
);

DO $$ BEGIN
  ALTER TABLE public.post_ausgang ADD CONSTRAINT post_ausgang_zustand
    CHECK (zustand IN ('WARTEND','UEBERGEBEN','VERSENDET','ZUGESTELLT',
                       'UNZUSTELLBAR','PROBLEM','ABGEBROCHEN'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.post_ausgang ADD CONSTRAINT post_ausgang_produkt
    CHECK (produkt IN ('cheap','fast','bulk','premium','registered'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.post_ausgang ADD CONSTRAINT post_ausgang_farbe
    CHECK (farbe IN ('color','grayscale'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Je Rechnung nur ein Brief, solange er nicht abgebrochen ist. Ohne das
-- koennte ein zweiter Klick denselben Brief ein zweites Mal verschicken
-- -- und Porto kostet Geld, anders als eine doppelte Mail.
CREATE UNIQUE INDEX IF NOT EXISTS post_ausgang_je_rechnung
  ON public.post_ausgang ("paymentId")
  WHERE "paymentId" IS NOT NULL AND zustand <> 'ABGEBROCHEN';

CREATE INDEX IF NOT EXISTS post_ausgang_offen
  ON public.post_ausgang (zustand, naechster_versuch)
  WHERE zustand = 'WARTEND';
CREATE INDEX IF NOT EXISTS post_ausgang_pingen
  ON public.post_ausgang (pingen_id) WHERE pingen_id IS NOT NULL;

ALTER TABLE public.post_ausgang ENABLE ROW LEVEL SECURITY;

-- Lesen darf die Vereinsleitung, aber NICHT das PDF. Dafuer gibt es die
-- Uebersichtsfunktion weiter unten; das Dokument selbst braucht im
-- Browser niemand, und es enthaelt Anschrift und Betrag jedes Mitglieds.
REVOKE ALL ON TABLE public.post_ausgang FROM anon, authenticated;

COMMENT ON TABLE public.post_ausgang IS
  'Briefe fuer den Postversand ueber Pingen. Eine Zeile = ein PDF = ein '
  'Kuvert. Nicht direkt lesbar; Uebersicht ueber post_uebersicht().';


-- --------------------------------------------------------- Einreihen
CREATE OR REPLACE FUNCTION public.post_einreihen(
  p_payment   text,
  p_dateiname text,
  p_pdf       text,
  p_produkt   text DEFAULT 'cheap',
  p_farbe     text DEFAULT 'grayscale',
  p_duplex    boolean DEFAULT true,
  p_adresslage text DEFAULT 'left'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  r record; m record; v_id uuid; v_name text; v_vorhanden record;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf Post aufgeben.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_pdf), '') = '' THEN
    RAISE EXCEPTION 'Ohne Dokument kein Brief.' USING ERRCODE = 'check_violation';
  END IF;

  -- Schon unterwegs? Dann nicht ein zweites Mal. Der eindeutige Index
  -- faengt es ohnehin, aber eine Meldung ist besser als ein Fehler.
  SELECT * INTO v_vorhanden FROM public.post_ausgang
   WHERE "paymentId" = p_payment AND zustand <> 'ABGEBROCHEN';
  IF FOUND THEN
    RETURN jsonb_build_object('eingereiht', false, 'zustand', v_vorhanden.zustand,
      'grund', 'Für diese Rechnung ist schon ein Brief erfasst ('
               || v_vorhanden.zustand || ').');
  END IF;

  SELECT u.* INTO m FROM public.users u WHERE u.id = r."userId";
  v_name := coalesce(
    nullif(btrim(coalesce(m."displayName", '')), ''),
    r."customRecipient" ->> 'name',
    'Unbekannt');

  INSERT INTO public.post_ausgang
    ("tenantId", "paymentId", "memberId", empfaenger, dateiname, pdf,
     produkt, farbe, duplex, adresslage)
  VALUES (r."tenantId", p_payment, m.id,
          v_name || coalesce(' · ' || nullif(btrim(coalesce(m.city,'')), ''), ''),
          left(coalesce(nullif(btrim(p_dateiname),''), 'rechnung.pdf'), 120),
          p_pdf,
          coalesce(nullif(p_produkt,''), 'cheap'),
          coalesce(nullif(p_farbe,''), 'grayscale'),
          coalesce(p_duplex, true),
          CASE WHEN lower(coalesce(p_adresslage,'')) = 'right' THEN 'right' ELSE 'left' END)
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('eingereiht', true, 'id', v_id, 'empfaenger', v_name);
END $$;

REVOKE ALL ON FUNCTION public.post_einreihen(text,text,text,text,text,boolean,text)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_einreihen(text,text,text,text,text,boolean,text)
  TO authenticated;


-- ------------------------------------------------- Zustand zurueckmelden
--
-- Nur service_role: das schreibt die Edge Function, die mit Pingen
-- spricht, und sonst niemand. Waere es fuer angemeldete Konten offen,
-- liesse sich ein Brief als "versendet" markieren, der nie hinausging.
CREATE OR REPLACE FUNCTION public.post_zustand_melden(
  p_id        uuid DEFAULT NULL,
  p_pingen_id text DEFAULT NULL,
  p_zustand   text DEFAULT NULL,
  p_status    text DEFAULT NULL,
  p_meldung   text DEFAULT NULL,
  p_fehler    text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int; v_id uuid;
BEGIN
  IF p_id IS NULL AND p_pingen_id IS NULL THEN
    RAISE EXCEPTION 'Ohne Kennung kein Zustand.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.post_ausgang
     SET zustand = coalesce(p_zustand, zustand),
         pingen_id = coalesce(p_pingen_id, pingen_id),
         pingen_status = coalesce(p_status, pingen_status),
         pingen_meldung = coalesce(p_meldung, pingen_meldung),
         letzter_fehler = CASE WHEN p_fehler IS NULL THEN letzter_fehler ELSE p_fehler END,
         versuche = CASE WHEN p_fehler IS NULL THEN versuche ELSE versuche + 1 END,
         -- Abstand zwischen den Versuchen, wie beim Mailversand: 10
         -- Minuten, eine Stunde, vier, zwoelf. Fuenf Versuche in fuenfzig
         -- Minuten haben dort waehrend eines wochenlangen Ausfalls sechs
         -- Mails verbrannt.
         naechster_versuch = CASE
           WHEN p_fehler IS NULL THEN naechster_versuch
           ELSE now() + (CASE versuche
                           WHEN 0 THEN interval '10 minutes'
                           WHEN 1 THEN interval '1 hour'
                           WHEN 2 THEN interval '4 hours'
                           ELSE interval '12 hours' END)
         END,
         uebergeben_am = CASE WHEN p_zustand = 'UEBERGEBEN' THEN now() ELSE uebergeben_am END,
         erledigt_am = CASE WHEN p_zustand IN ('VERSENDET','ZUGESTELLT','UNZUSTELLBAR')
                            THEN now() ELSE erledigt_am END
   WHERE (p_id IS NOT NULL AND id = p_id)
      OR (p_id IS NULL AND pingen_id = p_pingen_id)
  RETURNING id INTO v_id;
  GET DIAGNOSTICS v_n = ROW_COUNT;

  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Eine Statusmeldung zu
  -- einem Brief, den wir nicht kennen, ist aber eine Nachricht wert:
  -- sie bedeutet, dass Pingen etwas weiss, was wir nicht haben.
  RETURN jsonb_build_object('getroffen', v_n, 'id', v_id);
END $$;

REVOKE ALL ON FUNCTION public.post_zustand_melden(uuid,text,text,text,text,text)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_zustand_melden(uuid,text,text,text,text,text)
  TO service_role;


-- --------------------------------------------------------- Uebersicht
--
-- Ohne das PDF. Es enthaelt Anschrift und Betrag jedes Mitglieds, und im
-- Browser braucht es niemand -- die Maske zeigt Zustand und Empfaenger.
CREATE OR REPLACE FUNCTION public.post_uebersicht(p_grenze integer DEFAULT 200)
RETURNS TABLE (
  r_id uuid, r_rechnung text, r_empfaenger text, r_zustand text,
  r_produkt text, r_pingen_id text, r_status text, r_meldung text,
  r_versuche integer, r_fehler text, r_erstellt timestamptz,
  r_uebergeben timestamptz, r_erledigt timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id, p."paymentId", p.empfaenger, p.zustand, p.produkt,
         p.pingen_id, p.pingen_status, p.pingen_meldung,
         p.versuche, p.letzter_fehler, p.erstellt_am, p.uebergeben_am, p.erledigt_am
    FROM public.post_ausgang p
   WHERE (public.is_platform_admin()
          OR (p."tenantId" = public.current_tenant() AND public.is_member_manager()))
   ORDER BY p.erstellt_am DESC
   LIMIT greatest(1, least(coalesce(p_grenze, 200), 1000));
$$;

REVOKE ALL ON FUNCTION public.post_uebersicht(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_uebersicht(integer) TO authenticated;


-- Einen Brief zurueckziehen, solange er noch nicht uebergeben ist.
CREATE OR REPLACE FUNCTION public.post_abbrechen(p_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.darf_schreiben() OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  UPDATE public.post_ausgang
     SET zustand = 'ABGEBROCHEN', erledigt_am = now(),
         -- Das Dokument mit wegwerfen. Ein abgebrochener Brief muss
         -- nicht als base64 in der Datenbank liegenbleiben.
         pdf = ''
   WHERE id = p_id
     AND "tenantId" = public.current_tenant()
     -- Nur was noch nicht draussen ist. Ein uebergebener Brief laesst
     -- sich nicht zurueckholen, und ihn hier als abgebrochen zu fuehren
     -- waere eine Unwahrheit in der Uebersicht.
     AND zustand = 'WARTEND';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieser Brief ist nicht mehr zurueckziehbar -- er ist schon '
                    'uebergeben oder gehoert zu einem anderen Verein.'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.post_abbrechen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_abbrechen(uuid) TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_admin text; v_verein text; v_zahlung text := 'selbsttest-post';
  v_erg jsonb; v_id uuid; v_vorher int; v_nachher int; v_quelle text;
BEGIN
  -- Die Rueckmeldung darf NICHT fuer angemeldete Konten offen sein.
  IF has_function_privilege('authenticated',
       'public.post_zustand_melden(uuid,text,text,text,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated darf Briefzustaende melden -- damit liesse sich ein '
                    'Brief als versendet fuehren, der nie hinausging.';
  END IF;
  -- Und die Uebersicht darf das PDF nicht herausgeben.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='post_uebersicht';
  IF v_quelle ~ 'p\.pdf' THEN
    RAISE EXCEPTION 'post_uebersicht gibt das Dokument heraus.';
  END IF;

  SELECT u."tenantId", u."authUserId" INTO v_verein, v_admin FROM public.users u
   WHERE u.role IN ('SUPER_ADMIN','ADMIN') AND u."authUserId" IS NOT NULL
   ORDER BY u.id LIMIT 1;
  IF v_admin IS NULL THEN
    RAISE NOTICE 'Keine angemeldete Administration -- Verhaltenstest uebersprungen.';
    RETURN;
  END IF;

  SELECT count(*) INTO v_vorher FROM public.post_ausgang;

  INSERT INTO public.payments (id,"tenantId",amount,currency,status,method,"invoiceNumber")
  VALUES (v_zahlung, v_verein, 40, 'CHF', 'PENDING', 'QR_BILL', 'POST-SELBSTTEST');

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role','authenticated')::text, true);
  PERFORM set_config('role','authenticated', true);

  v_erg := public.post_einreihen(v_zahlung, 'test.pdf', 'JVBERi0xLjQK');
  IF NOT (v_erg->>'eingereiht')::boolean THEN
    RAISE EXCEPTION 'Der Brief wurde nicht eingereiht: %', v_erg;
  END IF;
  v_id := (v_erg->>'id')::uuid;

  -- Ein zweiter Versuch darf keinen zweiten Brief ergeben. Porto kostet
  -- Geld, anders als eine doppelte Mail.
  v_erg := public.post_einreihen(v_zahlung, 'test.pdf', 'JVBERi0xLjQK');
  IF (v_erg->>'eingereiht')::boolean THEN
    RAISE EXCEPTION 'Derselbe Brief liess sich zweimal aufgeben.';
  END IF;

  -- Zurueckziehen geht, solange er wartet.
  IF NOT public.post_abbrechen(v_id) THEN
    RAISE EXCEPTION 'Der wartende Brief liess sich nicht zurueckziehen.';
  END IF;
  -- Und danach nicht mehr.
  BEGIN
    PERFORM public.post_abbrechen(v_id);
    RAISE EXCEPTION 'Ein abgebrochener Brief liess sich erneut abbrechen.';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  PERFORM set_config('role','postgres', true);
  PERFORM set_config('request.jwt.claims', NULL, true);

  -- Das Dokument ist beim Abbrechen weg.
  IF (SELECT pdf FROM public.post_ausgang WHERE id = v_id) <> '' THEN
    RAISE EXCEPTION 'Das Dokument blieb nach dem Abbrechen liegen.';
  END IF;

  DELETE FROM public.post_ausgang WHERE id = v_id;
  DELETE FROM public.accounting_journal WHERE "referenceId" = v_zahlung;
  DELETE FROM public.payments WHERE id = v_zahlung;
  SELECT count(*) INTO v_nachher FROM public.post_ausgang;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Zeile(n) hinterlassen.', v_nachher - v_vorher;
  END IF;

  RAISE NOTICE 'Postausgang bereit: ein PDF je Brief, kein zweiter Versand, '
               'Zustand nur von der Serverrolle, Dokument nicht lesbar.';
END $$;
