-- Stufe 2: was Verein und Betreiber vom Marktplatz sehen und tun duerfen.
--
-- Zwei Sichten auf dieselben zwei Tabellen. Der Verein sieht seinen eigenen
-- Stand, der Betreiber den jedes Vereins. Umschalten darf vorerst nur der
-- Betreiber -- ob Vereine selbst zubuchen duerfen, ist eine
-- Verkaufsentscheidung und steht noch aus. Gebaut ist es derselbe Schalter;
-- es haengt nur an der Rechtepruefung in modul_umschalten().

-- --- Was mein Verein hat -------------------------------------------------
CREATE OR REPLACE FUNCTION public.marktplatz_uebersicht(p_verein text DEFAULT NULL)
RETURNS TABLE (
  schluessel text, name text, beschreibung text,
  ist_kern boolean, status text, braucht_einrichtung boolean,
  preis_monat numeric, preis_einmalig numeric,
  zustand text, testet_bis date, seit timestamptz,
  aktiv boolean, frei_fuer_verein boolean, reihenfolge integer
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ziel text; v_eigen text := public.current_tenant();
        v_sprache text := coalesce(nullif(current_setting('request.headers', true)::json ->> 'accept-language',''), 'de');
        v_frei boolean;
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Vereine einsehen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Marktplatz einsehen.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen);
  END IF;
  IF v_ziel IS NULL THEN RETURN; END IF;

  SELECT t.alle_module_frei INTO v_frei FROM public.tenants t WHERE t.id = v_ziel;

  RETURN QUERY
  SELECT m.schluessel,
         CASE WHEN v_sprache LIKE 'sq%' THEN m.name_sq
              WHEN v_sprache LIKE 'en%' THEN m.name_en ELSE m.name_de END,
         CASE WHEN v_sprache LIKE 'sq%' THEN m.beschreibung_sq
              WHEN v_sprache LIKE 'en%' THEN m.beschreibung_en ELSE m.beschreibung_de END,
         m.ist_kern, m.status, m.braucht_einrichtung,
         m.preis_monat, m.preis_einmalig,
         coalesce(tm.zustand, CASE WHEN m.ist_kern THEN 'AN' ELSE 'AUS' END),
         tm.testet_bis, tm.seit,
         -- Genau die Rechnung, die auch die Zeilenregeln anstellen.
         (coalesce(v_frei, false)
          OR m.ist_kern
          OR (tm.zustand IN ('AN','TESTPHASE')
              AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date))),
         coalesce(v_frei, false),
         m.reihenfolge
    FROM public.modules m
    LEFT JOIN public.tenant_modules tm
      ON tm.modul = m.schluessel AND tm."tenantId" = v_ziel
   WHERE m.status <> 'EINGESTELLT' OR tm.zustand IS NOT NULL
   ORDER BY m.reihenfolge;
END $$;

-- --- Umschalten ----------------------------------------------------------
CREATE OR REPLACE FUNCTION public.modul_umschalten(
  p_verein text, p_modul text, p_zustand text, p_testet_bis date DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_kern boolean; v_wer text;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf Module umschalten.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_zustand NOT IN ('AN','AUS','TESTPHASE','GESPERRT') THEN
    RAISE EXCEPTION 'Unbekannter Zustand: %', p_zustand;
  END IF;

  SELECT ist_kern INTO v_kern FROM public.modules WHERE schluessel = p_modul;
  IF v_kern IS NULL THEN
    RAISE EXCEPTION 'Unbekanntes Modul: %', p_modul;
  END IF;
  -- Kernmodule lassen sich nicht abschalten. Ohne sie ist die Plattform kein
  -- Vereinsprogramm, und ein Schalter, der nichts bewirkt, gehoert nicht in
  -- eine Maske.
  IF v_kern AND p_zustand <> 'AN' THEN
    RAISE EXCEPTION 'Kernmodule lassen sich nicht abschalten.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand, testet_bis, seit, geaendert_von)
  VALUES (p_verein, p_modul, p_zustand, p_testet_bis, now(), v_wer)
  ON CONFLICT ("tenantId", modul) DO UPDATE SET
    zustand = excluded.zustand, testet_bis = excluded.testet_bis,
    seit = now(), geaendert_von = excluded.geaendert_von;

  RETURN p_modul || ' -> ' || p_zustand;
END $$;

REVOKE ALL ON FUNCTION public.marktplatz_uebersicht(text) FROM public, anon;
REVOKE ALL ON FUNCTION public.modul_umschalten(text,text,text,date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.marktplatz_uebersicht(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.modul_umschalten(text,text,text,date) TO authenticated;

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE 'Marktplatz fuer koretini (als Migrationsrolle, daher ohne Rechtepruefung):';
  FOR r IN SELECT m.schluessel, m.name_de, m.ist_kern, m.status FROM public.modules m
            ORDER BY m.reihenfolge LOOP
    RAISE NOTICE '  % | % | %', rpad(r.schluessel,12), rpad(r.name_de,28),
      CASE WHEN r.ist_kern THEN 'Kern' ELSE r.status END;
  END LOOP;
END $$;
