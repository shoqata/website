-- Zwei Luecken, vom Betreiber gemeldet.
--
-- 1. Geschwister liessen sich nicht erfassen.
--    Sie ergeben sich aus einem gemeinsamen Elternteil -- das war richtig
--    gedacht, aber unvollstaendig: sind die Eltern verstorben oder nicht
--    Mitglied des Vereins, gibt es niemanden, ueber den sich die beiden
--    verbinden liessen. Dann bleibt nur, die Geschwisterschaft selbst zu
--    behaupten.
--
--    Die Sorge vor einer "zweiten Wahrheit" bleibt berechtigt, wird aber
--    anders geloest: eine ausdrueckliche Geschwisterkante wird in der
--    Verwandtschaftsrechnung wie ein gemeinsamer, nicht erfasster Elternteil
--    behandelt. Dadurch ergeben sich Cousins und Onkel daraus genauso
--    weiter, und sobald die Eltern nachgetragen werden, sagt beides dasselbe.
--
-- 2. Eine Familie hatte keinen Namen.
--    Sie war bisher nur eine Rechnung: alle, die ueber Kanten zusammenhaengen.
--    Damit liess sich nichts benennen und nichts festhalten.
--
--    Die Struktur bleibt gerechnet -- sie ist die Wahrheit. Der Name haengt
--    an einer Ankerperson: die Familie ist die Gruppe, in der diese Person
--    steht. Verschiebt sich die Gruppe, wandert der Name mit, statt an einer
--    Mitgliederliste zu haengen, die dann doppelt gepflegt werden muesste.

ALTER TABLE public.family_links DROP CONSTRAINT IF EXISTS family_links_art_gueltig;
ALTER TABLE public.family_links ADD CONSTRAINT family_links_art_gueltig
  CHECK (art IN ('ELTERNTEIL','PARTNER','GESCHWISTER'));

-- Geschwister sind wie Partner ungerichtet: einmal gespeichert, in beide
-- Richtungen gueltig.
CREATE UNIQUE INDEX IF NOT EXISTS family_links_geschwister_einmalig
  ON public.family_links (least(von, nach), greatest(von, nach))
  WHERE art = 'GESCHWISTER';

-- --- Familien mit Namen ----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.families (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  name          text NOT NULL,
  notiz         text,
  anker         text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_von text,
  CONSTRAINT families_name_nicht_leer CHECK (btrim(name) <> '')
);
CREATE UNIQUE INDEX IF NOT EXISTS families_anker_einmalig ON public.families (anker);

ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.families FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.families TO authenticated;

-- Dieselbe Grenze wie bei den Beziehungen: lesen darf die Verwaltung und die
-- verantwortliche Person, sofern die Ankerperson in ihrer Nachbarschaft steht.
CREATE POLICY families_lesen ON public.families
  FOR SELECT TO authenticated
  USING (
    "tenantId" = public.current_tenant()
    AND (
      public.is_member_manager()
      OR (public.is_neighborhood_steward() AND EXISTS (
            SELECT 1 FROM public.users u
             WHERE u.id = families.anker
               AND u."neighborhoodId" IN (SELECT public.my_neighborhoods())))
    )
  );

CREATE POLICY families_schreiben ON public.families
  FOR ALL TO authenticated
  USING ("tenantId" = public.current_tenant() AND public.is_member_manager())
  WITH CHECK ("tenantId" = public.current_tenant() AND public.is_member_manager());

CREATE OR REPLACE FUNCTION public.families_verein_setzen()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ankerverein text;
BEGIN
  SELECT "tenantId" INTO v_ankerverein FROM public.users WHERE id = NEW.anker;
  IF v_ankerverein IS NULL THEN
    RAISE EXCEPTION 'Die Ankerperson gibt es nicht.';
  END IF;
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN
    NEW."tenantId" := v_ankerverein;
  END IF;
  IF NEW."tenantId" <> v_ankerverein THEN
    RAISE EXCEPTION 'Die Ankerperson gehoert zu einem anderen Verein.';
  END IF;
  IF NEW.geaendert_von IS NULL THEN
    SELECT coalesce(u.email, auth.uid()::text) INTO NEW.geaendert_von
      FROM public.users u WHERE u.id = public.current_user_row_id();
  END IF;
  NEW.geaendert_am := now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS families_verein_trg ON public.families;
CREATE TRIGGER families_verein_trg BEFORE INSERT OR UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION public.families_verein_setzen();

DO $$ BEGIN RAISE NOTICE 'Geschwisterkante erlaubt, Tabelle families angelegt.'; END $$;
