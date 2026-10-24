-- Chronik: die Entwicklung von Verein und Dorf als Zeitleiste.
--
-- Ein Eintrag hat ein Jahr, wahlweise Monat und Tag: aus der Gruendungszeit
-- kennt oft niemand mehr den Tag, aus dem letzten Fruehling schon. Ein
-- Pflichtdatum wuerde dazu fuehren, dass jemand den 1. Januar erfindet.
--
-- bereich trennt, worum es geht: der Verein (Gruendung, Vorstand,
-- Statuten) oder das Dorf (Strasse, Schule, Wasserleitung -- oft das, was
-- der Verein mitfinanziert hat). meilenstein hebt einen Eintrag hervor;
-- die Seite "Ueber uns" zeigt nur diese.
--
-- Wie bei den eigenen Seiten: kein Schreibrecht auf die Tabelle, alles
-- ueber die Funktionen. Texte sind {de, sq, en}.

CREATE TABLE IF NOT EXISTS public.chronik (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  jahr          int  NOT NULL CHECK (jahr BETWEEN 1000 AND 2200),
  monat         int  CHECK (monat BETWEEN 1 AND 12),
  tag           int  CHECK (tag BETWEEN 1 AND 31),
  titel         jsonb NOT NULL DEFAULT '{}'::jsonb,
  text          jsonb NOT NULL DEFAULT '{}'::jsonb,
  bild          text,
  bereich       text NOT NULL DEFAULT 'VEREIN' CHECK (bereich IN ('VEREIN','DORF')),
  meilenstein   boolean NOT NULL DEFAULT false,
  status        text NOT NULL DEFAULT 'OEFFENTLICH' CHECK (status IN ('ENTWURF','OEFFENTLICH')),
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_von text,
  CHECK (tag IS NULL OR monat IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS chronik_zeit ON public.chronik ("tenantId", status, jahr, monat, tag);

-- Die Seite /chronik gibt es jetzt: eine eigene Seite darf sie nicht verdecken.
CREATE OR REPLACE FUNCTION public.pfad_belegt(p_pfad text)
RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(btrim(coalesce(p_pfad,''))) = ANY (ARRAY[
    '', 'about', 'live', 'events', 'news', 'fussball', 'futsal', 'spenden',
    'videos', 'gdpr', 'privacy', 'login', 'register', 'dashboard', 'admin',
    'super-admin', 'nachbarschaft', 'setup-profile', 'revision', 'treffen',
    'vorstellen', 'heft', 'drucksachen', 'api', 'assets', 'static',
    'beitraege', 'chronik']);
$$;


CREATE OR REPLACE FUNCTION public.chronik_speichern(
  p_id uuid, p_jahr int, p_monat int, p_tag int, p_titel jsonb, p_text jsonb,
  p_bild text, p_bereich text, p_meilenstein boolean, p_status text)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_id uuid; v_wer text; v_bild text := nullif(btrim(coalesce(p_bild, '')), '');
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung pflegt die Chronik.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_jahr IS NULL OR p_jahr NOT BETWEEN 1000 AND 2200 THEN
    RAISE EXCEPTION 'Der Eintrag braucht ein Jahr.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_tag IS NOT NULL AND p_monat IS NULL THEN
    RAISE EXCEPTION 'Ein Tag ohne Monat ist kein Datum.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_tag IS NOT NULL THEN
    BEGIN
      PERFORM make_date(p_jahr, p_monat, p_tag);
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'Den %.%.% gibt es nicht.', p_tag, p_monat, p_jahr USING ERRCODE = 'check_violation';
    END;
  END IF;
  IF coalesce(p_titel, '{}'::jsonb) = '{}'::jsonb
     OR NOT EXISTS (SELECT 1 FROM jsonb_each_text(p_titel) e WHERE btrim(e.value) <> '') THEN
    RAISE EXCEPTION 'Der Eintrag braucht einen Titel.' USING ERRCODE = 'check_violation';
  END IF;
  -- Nur Bilder von hier oder ueber https. Sonst liesse sich javascript:
  -- oder eine data:-Adresse in die Seite jedes Besuchers schreiben.
  IF v_bild IS NOT NULL AND v_bild !~* '^(https://|/)' THEN
    RAISE EXCEPTION 'Das Bild braucht eine https-Adresse.' USING ERRCODE = 'check_violation';
  END IF;

  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();

  IF p_id IS NULL THEN
    INSERT INTO public.chronik ("tenantId", jahr, monat, tag, titel, text, bild, bereich,
                                meilenstein, status, geaendert_von)
    VALUES (v_verein, p_jahr, p_monat, p_tag, p_titel, coalesce(p_text, '{}'::jsonb), v_bild,
            coalesce(nullif(p_bereich, ''), 'VEREIN'), coalesce(p_meilenstein, false),
            coalesce(nullif(p_status, ''), 'OEFFENTLICH'), v_wer)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.chronik SET
      jahr = p_jahr, monat = p_monat, tag = p_tag, titel = p_titel,
      text = coalesce(p_text, '{}'::jsonb), bild = v_bild,
      bereich = coalesce(nullif(p_bereich, ''), bereich),
      meilenstein = coalesce(p_meilenstein, meilenstein),
      status = coalesce(nullif(p_status, ''), status),
      geaendert_am = now(), geaendert_von = v_wer
     WHERE id = p_id AND "tenantId" = v_verein
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Dieser Eintrag gehoert nicht zu Ihrem Verein.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.chronik_speichern(uuid, int, int, int, jsonb, jsonb, text, text, boolean, text)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.chronik_speichern(uuid, int, int, int, jsonb, jsonb, text, text, boolean, text)
  TO authenticated;


CREATE OR REPLACE FUNCTION public.chronik_loeschen(p_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung pflegt die Chronik.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  DELETE FROM public.chronik WHERE id = p_id AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieser Eintrag gehoert nicht zu Ihrem Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.chronik_loeschen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.chronik_loeschen(uuid) TO authenticated;


-- ---------------------------------------------------------- Zeilenregeln
-- Dieselbe Regel wie bei den eigenen Seiten (in der berichtigten Form vom
-- 09.11.: veroeffentlicht heisst veroeffentlicht IM EIGENEN Verein).
ALTER TABLE public.chronik ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chronik_oeffentlich ON public.chronik;
CREATE POLICY chronik_oeffentlich ON public.chronik FOR SELECT TO anon
  USING (status = 'OEFFENTLICH' AND "tenantId" = (SELECT public.request_tenant()));

DROP POLICY IF EXISTS chronik_intern ON public.chronik;
CREATE POLICY chronik_intern ON public.chronik FOR SELECT TO authenticated
  USING ((status = 'OEFFENTLICH'
          AND "tenantId" = (SELECT coalesce(public.current_tenant(), public.request_tenant())))
         OR ("tenantId" = (SELECT public.current_tenant())
             AND ((SELECT public.is_platform_admin()) OR (SELECT public.is_staff()))));

REVOKE ALL ON public.chronik FROM anon, authenticated, public;
GRANT SELECT ON public.chronik TO anon, authenticated;


-- ---------------------------------------------------------- Demo
-- Beispieleintraege fuer den Demo-Verein -- und dieselben in der Vorlage,
-- aus der das Zuruecksetzen ihn wieder aufbaut. Die Vorlage wird hier
-- ergaenzt, nicht neu gespeichert: neu speichern hiesse, den aktuellen,
-- vielleicht gerade vorgefuehrten Zustand zur Vorlage zu machen.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;
  IF EXISTS (SELECT 1 FROM public.chronik WHERE "tenantId" = 'demo') THEN RETURN; END IF;

  INSERT INTO public.chronik ("tenantId", jahr, monat, tag, titel, text, bereich, meilenstein, geaendert_von) VALUES
  ('demo', 1994, NULL, NULL,
   '{"de":"Gründung im Gemeindesaal","sq":"Themelimi në sallën e komunës","en":"Founded in the town hall"}',
   '{"de":"Zwölf Familien aus dem Dorf gründen den Verein, um sich in der Schweiz gegenseitig zu unterstützen.","sq":"Dymbëdhjetë familje nga fshati themelojnë shoqatën për t''u ndihmuar në Zvicër.","en":"Twelve families from the village found the association to support each other in Switzerland."}',
   'VEREIN', true, 'Demo'),
  ('demo', 2001, 6, NULL,
   '{"de":"Neue Wasserleitung im Dorf","sq":"Ujësjellës i ri në fshat","en":"New water supply in the village"}',
   '{"de":"Mit Spenden der Mitglieder bekommt das Oberdorf fliessendes Wasser.","sq":"Me donacionet e anëtarëve, lagja e sipërme merr ujë të rrjedhshëm.","en":"Member donations bring running water to the upper village."}',
   'DORF', true, 'Demo'),
  ('demo', 2008, NULL, NULL,
   '{"de":"Erste Statuten und gewählter Vorstand","sq":"Statuti i parë dhe kryesia e zgjedhur","en":"First statutes and elected board"}',
   '{"de":"Der Verein gibt sich Statuten und wählt erstmals einen Vorstand mit fünf Mitgliedern.","sq":"Shoqata miraton statutin dhe zgjedh për herë të parë një kryesi me pesë anëtarë.","en":"The association adopts statutes and elects a five-member board for the first time."}',
   'VEREIN', false, 'Demo'),
  ('demo', 2015, 9, NULL,
   '{"de":"Schulhaus renoviert","sq":"Shkolla u rinovua","en":"School renovated"}',
   '{"de":"Dach, Fenster und Heizung der Dorfschule werden erneuert. Der Verein trägt einen Drittel der Kosten.","sq":"Çatia, dritaret dhe ngrohja e shkollës rinovohen. Shoqata mbulon një të tretën e kostove.","en":"Roof, windows and heating of the village school are renewed. The association covers a third of the cost."}',
   'DORF', true, 'Demo'),
  ('demo', 2019, 5, 18,
   '{"de":"25 Jahre Verein","sq":"25 vjet shoqatë","en":"25 years of the association"}',
   '{"de":"Jubiläumsfest mit über 400 Gästen aus der Schweiz, Deutschland und dem Kosovo.","sq":"Festë jubilare me mbi 400 mysafirë nga Zvicra, Gjermania dhe Kosova.","en":"Anniversary celebration with over 400 guests from Switzerland, Germany and Kosovo."}',
   'VEREIN', true, 'Demo'),
  ('demo', 2023, 4, NULL,
   '{"de":"Strassenbeleuchtung bis zum Friedhof","sq":"Ndriçimi i rrugës deri te varrezat","en":"Street lighting up to the cemetery"}',
   '{"de":"Vierzig neue Solarleuchten säumen den Weg durchs Dorf.","sq":"Dyzet drita të reja solare ndriçojnë rrugën nëpër fshat.","en":"Forty new solar lights line the road through the village."}',
   'DORF', false, 'Demo'),
  ('demo', 2026, 3, NULL,
   '{"de":"Verwaltung wird digital","sq":"Administrimi bëhet digjital","en":"Administration goes digital"}',
   '{"de":"Mitglieder, Beiträge und Protokolle laufen jetzt über die eigene Vereinsplattform.","sq":"Anëtarët, kuotat dhe procesverbalet tani menaxhohen në platformën e shoqatës.","en":"Members, fees and minutes now run on the association''s own platform."}',
   'VEREIN', false, 'Demo');

  IF EXISTS (SELECT 1 FROM public.demo_vorlage) THEN
    DELETE FROM public.demo_vorlage WHERE tabelle = 'chronik';
    INSERT INTO public.demo_vorlage (tabelle, zeile)
    SELECT 'chronik', to_jsonb(c) FROM public.chronik c WHERE c."tenantId" = 'demo';
  END IF;
END $$;


-- ---------------------------------------------------------- Selbsttest
DO $$
BEGIN
  IF NOT public.pfad_belegt('chronik') THEN
    RAISE EXCEPTION 'Selbsttest: /chronik ist nicht geschuetzt';
  END IF;
  IF has_table_privilege('anon', 'public.chronik', 'INSERT')
     OR has_table_privilege('authenticated', 'public.chronik', 'UPDATE') THEN
    RAISE EXCEPTION 'Selbsttest: Chronik direkt beschreibbar';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
