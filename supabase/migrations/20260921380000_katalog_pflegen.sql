-- Den Katalog pflegt der Betreiber: Preise, Verfuegbarkeit, Beschreibung.
--
-- Bewusst keine Tabellen-Regel zum Schreiben, sondern eine Funktion: so
-- laesst sich der Schluessel nicht aendern (daran haengen die Zeilenregeln)
-- und ist_kern nicht umlegen (das wuerde die Sperre eines Kernmoduls
-- ermoeglichen).
CREATE OR REPLACE FUNCTION public.modul_katalog_speichern(
  p_schluessel text,
  p_preis_monat numeric DEFAULT NULL,
  p_preis_einmalig numeric DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_beschreibung_de text DEFAULT NULL,
  p_beschreibung_sq text DEFAULT NULL,
  p_beschreibung_en text DEFAULT NULL
) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Katalog pflegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_status IS NOT NULL AND p_status NOT IN ('VERFUEGBAR','BETA','EINGESTELLT') THEN
    RAISE EXCEPTION 'Unbekannter Status: %', p_status;
  END IF;
  IF p_preis_monat IS NOT NULL AND p_preis_monat < 0 THEN
    RAISE EXCEPTION 'Ein Preis kann nicht negativ sein.';
  END IF;

  UPDATE public.modules SET
    preis_monat     = CASE WHEN p_preis_monat    IS NULL THEN preis_monat    ELSE nullif(p_preis_monat, -1) END,
    preis_einmalig  = CASE WHEN p_preis_einmalig IS NULL THEN preis_einmalig ELSE nullif(p_preis_einmalig, -1) END,
    status          = coalesce(p_status, status),
    beschreibung_de = coalesce(p_beschreibung_de, beschreibung_de),
    beschreibung_sq = coalesce(p_beschreibung_sq, beschreibung_sq),
    beschreibung_en = coalesce(p_beschreibung_en, beschreibung_en)
  WHERE schluessel = p_schluessel;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN RAISE EXCEPTION 'Unbekanntes Modul: %', p_schluessel; END IF;
  RETURN p_schluessel;
END $$;

-- Wie viele Vereine haben welches Modul? Fuer die Betreiberansicht.
CREATE OR REPLACE FUNCTION public.modul_verbreitung()
RETURNS TABLE (schluessel text, name text, status text, ist_kern boolean,
               preis_monat numeric, vereine_an bigint, vereine_gesperrt bigint,
               vereine_gesamt bigint, reihenfolge integer)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT m.schluessel, m.name_de, m.status, m.ist_kern, m.preis_monat,
         count(*) FILTER (WHERE tm.zustand IN ('AN','TESTPHASE') OR m.ist_kern OR t.alle_module_frei),
         count(*) FILTER (WHERE tm.zustand = 'GESPERRT'),
         (SELECT count(*) FROM public.tenants),
         m.reihenfolge
    FROM public.modules m
    CROSS JOIN public.tenants t
    LEFT JOIN public.tenant_modules tm
      ON tm.modul = m.schluessel AND tm."tenantId" = t.id
   GROUP BY m.schluessel, m.name_de, m.status, m.ist_kern, m.preis_monat, m.reihenfolge
   ORDER BY m.reihenfolge;
END $$;

REVOKE ALL ON FUNCTION public.modul_katalog_speichern(text,numeric,numeric,text,text,text,text) FROM public, anon;
REVOKE ALL ON FUNCTION public.modul_verbreitung() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.modul_katalog_speichern(text,numeric,numeric,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.modul_verbreitung() TO authenticated;

DO $$
DECLARE v_back text := current_user; r record; v_uid text; v_mail text;
BEGIN
  SELECT p.email, a.id::text INTO v_mail, v_uid
    FROM public.platform_admins p JOIN auth.users a ON lower(a.email)=lower(p.email) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  FOR r IN SELECT * FROM public.modul_verbreitung() LOOP
    RAISE NOTICE '  % | % | % von % Vereinen an', rpad(r.schluessel,12),
      rpad(coalesce(r.status,''),12), r.vereine_an, r.vereine_gesamt;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
