-- Nachbarschaften stellen sich vor: Text, Bilder und ihr Gebiet auf der
-- Karte.
--
-- Eine eigene Tabelle statt weiterer Spalten in neighborhoods: die ist
-- fuer jeden lesbar und traegt Verwaltungsfelder (Vertreter, Kontakte).
-- Die Vorstellung dagegen ist Inhalt der Website -- mit eigenem Schalter
-- "sichtbar", damit eine halb fertige Seite nicht schon erscheint.
--
-- Bearbeiten duerfen Verwaltung und Vorstand fuer alle Nachbarschaften,
-- Vertreter fuer ihre eigenen (my_neighborhoods). Das Gebiet ist eine
-- Liste von Punkten [breite, laenge]; mindestens drei ergeben eine Flaeche.

CREATE TABLE IF NOT EXISTS public.nachbarschaft_profil (
  nachbarschaft text PRIMARY KEY REFERENCES public.neighborhoods(id) ON DELETE CASCADE,
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  sichtbar      boolean NOT NULL DEFAULT false,
  text          jsonb NOT NULL DEFAULT '{}'::jsonb,
  bilder        jsonb NOT NULL DEFAULT '[]'::jsonb,
  gebiet        jsonb NOT NULL DEFAULT '[]'::jsonb,
  ort           text,
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_von text
);
CREATE INDEX IF NOT EXISTS nachbarschaft_profil_verein ON public.nachbarschaft_profil ("tenantId", sichtbar);

ALTER TABLE public.nachbarschaft_profil ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.nachbarschaft_profil FROM anon, authenticated, public;
GRANT SELECT ON public.nachbarschaft_profil TO anon, authenticated;

DROP POLICY IF EXISTS nachbarschaft_profil_lesen ON public.nachbarschaft_profil;
CREATE POLICY nachbarschaft_profil_lesen ON public.nachbarschaft_profil FOR SELECT
  USING ((sichtbar AND "tenantId" = (SELECT coalesce(public.current_tenant(), public.request_tenant())))
         OR ("tenantId" = (SELECT public.current_tenant())
             AND ((SELECT public.is_member_manager())
                  OR nachbarschaft IN (SELECT id FROM public.my_neighborhoods()))));

CREATE OR REPLACE FUNCTION public.nachbarschaft_profil_speichern(
  p_nachbarschaft text, p_text jsonb, p_bilder jsonb, p_gebiet jsonb, p_ort text, p_sichtbar boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant(); v_wer text; v_p jsonb; v_b jsonb;
BEGIN
  IF v_verein IS NULL OR NOT EXISTS (SELECT 1 FROM public.neighborhoods n
       WHERE n.id = p_nachbarschaft AND n."tenantId" = v_verein) THEN
    RAISE EXCEPTION 'Diese Nachbarschaft gehoert nicht zu Ihrem Verein.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT (public.is_member_manager()
          OR p_nachbarschaft IN (SELECT id FROM public.my_neighborhoods())) THEN
    RAISE EXCEPTION 'Nur Verwaltung, Vorstand und die Vertreter dieser Nachbarschaft.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Das Gebiet: hoechstens 200 Punkte, jeder ein Paar gueltiger Koordinaten.
  IF jsonb_typeof(coalesce(p_gebiet, '[]')) <> 'array' OR jsonb_array_length(coalesce(p_gebiet, '[]')) > 200 THEN
    RAISE EXCEPTION 'Das Gebiet ist ungueltig.' USING ERRCODE = 'check_violation';
  END IF;
  FOR v_p IN SELECT * FROM jsonb_array_elements(coalesce(p_gebiet, '[]')) LOOP
    IF jsonb_typeof(v_p) <> 'array' OR jsonb_array_length(v_p) <> 2
       OR jsonb_typeof(v_p->0) <> 'number' OR jsonb_typeof(v_p->1) <> 'number'
       OR abs((v_p->>0)::numeric) > 90 OR abs((v_p->>1)::numeric) > 180 THEN
      RAISE EXCEPTION 'Das Gebiet enthaelt einen ungueltigen Punkt.' USING ERRCODE = 'check_violation';
    END IF;
  END LOOP;

  -- Bilder: hoechstens 24, nur https oder Pfade von hier.
  IF jsonb_typeof(coalesce(p_bilder, '[]')) <> 'array' OR jsonb_array_length(coalesce(p_bilder, '[]')) > 24 THEN
    RAISE EXCEPTION 'Hoechstens 24 Bilder.' USING ERRCODE = 'check_violation';
  END IF;
  FOR v_b IN SELECT * FROM jsonb_array_elements(coalesce(p_bilder, '[]')) LOOP
    IF coalesce(v_b->>'url', '') !~* '^(https://|/)' THEN
      RAISE EXCEPTION 'Ein Bild braucht eine https-Adresse.' USING ERRCODE = 'check_violation';
    END IF;
  END LOOP;

  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.nachbarschaft_profil (nachbarschaft, "tenantId", sichtbar, text, bilder, gebiet, ort, geaendert_von)
  VALUES (p_nachbarschaft, v_verein, coalesce(p_sichtbar, false), coalesce(p_text, '{}'), coalesce(p_bilder, '[]'),
          coalesce(p_gebiet, '[]'), nullif(btrim(coalesce(p_ort, '')), ''), v_wer)
  ON CONFLICT (nachbarschaft) DO UPDATE SET
    sichtbar = EXCLUDED.sichtbar, text = EXCLUDED.text, bilder = EXCLUDED.bilder, gebiet = EXCLUDED.gebiet,
    ort = EXCLUDED.ort, geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;
END $$;
REVOKE ALL ON FUNCTION public.nachbarschaft_profil_speichern(text, jsonb, jsonb, jsonb, text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nachbarschaft_profil_speichern(text, jsonb, jsonb, jsonb, text, boolean) TO authenticated;

-- Fuer die Website: Nachbarschaften mit sichtbarer Vorstellung, mit Zahl
-- der aktiven Mitglieder. Ohne Namen, Adressen oder Kontakte.
CREATE OR REPLACE FUNCTION public.nachbarschaften_oeffentlich()
RETURNS TABLE (id text, name text, city text, text jsonb, bilder jsonb, gebiet jsonb, ort text, mitglieder int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT n.id, n.name, n.city, p.text, p.bilder, p.gebiet, p.ort,
         (SELECT count(*)::int FROM public.users u
           WHERE u."tenantId" = n."tenantId" AND u."neighborhoodId" = n.id
             AND coalesce(u."membershipStatus", 'ACTIVE') = 'ACTIVE')
    FROM public.neighborhoods n
    JOIN public.nachbarschaft_profil p ON p.nachbarschaft = n.id AND p.sichtbar
   WHERE n."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
     AND public.modul_aktiv('WEBSITE')
   ORDER BY n.name;
$$;
REVOKE ALL ON FUNCTION public.nachbarschaften_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.nachbarschaften_oeffentlich() TO anon, authenticated;

-- Die Seite /nachbarschaften gibt es jetzt.
CREATE OR REPLACE FUNCTION public.pfad_belegt(p_pfad text)
RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(btrim(coalesce(p_pfad,''))) = ANY (ARRAY[
    '', 'about', 'live', 'events', 'news', 'fussball', 'futsal', 'spenden',
    'videos', 'gdpr', 'privacy', 'login', 'register', 'dashboard', 'admin',
    'super-admin', 'nachbarschaft', 'nachbarschaften', 'setup-profile', 'revision', 'treffen',
    'vorstellen', 'heft', 'drucksachen', 'api', 'assets', 'static',
    'beitraege', 'chronik', 'kontakt']);
$$;

DO $$
BEGIN
  IF has_table_privilege('anon', 'public.nachbarschaft_profil', 'INSERT')
     OR has_table_privilege('authenticated', 'public.nachbarschaft_profil', 'UPDATE') THEN
    RAISE EXCEPTION 'Selbsttest: Profil direkt beschreibbar';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
