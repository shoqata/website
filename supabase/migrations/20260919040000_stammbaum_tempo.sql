-- Wie lange braucht die Uebersicht? Eine rekursive Abfrage ueber alle
-- Personen kann teuer werden -- lieber jetzt messen als spaeter bei einer
-- haengenden Maske raten.
DO $$
DECLARE t0 timestamptz; v_n int; v_ms numeric;
BEGIN
  t0 := clock_timestamp();
  SELECT count(*) INTO v_n FROM public.familien_uebersicht();
  v_ms := extract(epoch FROM clock_timestamp() - t0) * 1000;
  RAISE NOTICE 'familien_uebersicht: % Zeilen in % ms', v_n, round(v_ms);

  t0 := clock_timestamp();
  SELECT count(*) INTO v_n FROM public.haushalt_vorschlaege();
  v_ms := extract(epoch FROM clock_timestamp() - t0) * 1000;
  RAISE NOTICE 'haushalt_vorschlaege: % Zeilen in % ms', v_n, round(v_ms);
END $$;
