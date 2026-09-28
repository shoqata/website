-- Das Testvideo. Erzeugt am 28.09.2026 mit hyperframes-student-kit aus
-- Koretinis eigenen Zahlen -- 340 Mitglieder, 27 Nachbarschaften, 78 von 331
-- bezahlten Beitraegen -- und in die Ablage gelegt. Alle drei Zahlen sind
-- gemessen und nicht ausgedacht; ein Film, der mit erfundenen Zahlen wirbt,
-- ist schlimmer als keiner.
INSERT INTO public.videos (id, "tenantId", titel, beschreibung, quelle, vorschaubild,
                           dauer_s, status, reihenfolge, erstellt_von)
VALUES ('koretini-rueckblick-2026', 'koretini',
        'Shoqata Humanitare Koretini in Zahlen',
        'Ein kurzer Blick auf den Verein: wie viele wir sind, wie wir uns organisieren und wie viele den Beitrag 2026 schon geleistet haben.',
        'https://rabpkwwozkwsnyoivocy.supabase.co/storage/v1/object/public/videos/koretini/rueckblick-2026.mp4',
        'https://rabpkwwozkwsnyoivocy.supabase.co/storage/v1/object/public/videos/koretini/rueckblick-2026.jpg',
        15, 'OEFFENTLICH', 10, 'system')
ON CONFLICT (id) DO UPDATE
  SET quelle = EXCLUDED.quelle, vorschaubild = EXCLUDED.vorschaubild,
      status = EXCLUDED.status, titel = EXCLUDED.titel;

DO $$
DECLARE v_back text := current_user; r record; v_n int;
BEGIN
  -- Sieht ein fremder Besucher das Video? Die Regel verlangt beides:
  -- freigegeben UND Modul aktiv.
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.videos;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Ein Besucher von koretini.me sieht % Video(s)', v_n;

  -- Und wenn das Modul aus waere?
  UPDATE public.tenant_modules SET zustand='AUS'
   WHERE "tenantId"='koretini' AND modul='VIDEOS';
  UPDATE public.tenants SET alle_module_frei=false WHERE id='koretini';
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.videos;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE 'Mit abgeschaltetem Modul: % Video(s) -- erwartet 0', v_n;

  -- Zurueck auf den richtigen Stand. alle_module_frei gilt fuer Koretini
  -- dauerhaft; das ist eine Festlegung des Betreibers, keine Testgroesse.
  UPDATE public.tenants SET alle_module_frei=true WHERE id='koretini';
  UPDATE public.tenant_modules SET zustand='AN'
   WHERE "tenantId"='koretini' AND modul='VIDEOS';
  PERFORM set_config('request.headers', NULL, false);

  SELECT count(*) INTO v_n FROM public.tenants WHERE id='koretini' AND alle_module_frei;
  RAISE NOTICE 'Koretini wieder auf "alles frei": %', v_n;
END $$;
