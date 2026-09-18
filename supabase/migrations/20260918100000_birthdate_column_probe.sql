-- Wie ist birthdate gespeichert?
--
-- Ein Eingabefeld vom Typ date liefert bei leerer Eingabe eine leere
-- Zeichenkette. Ist die Spalte vom Typ date, scheitert das Schreiben daran --
-- also muss die Anwendung in diesem Fall NULL schicken. Das gehoert geklaert,
-- bevor das Feld eingebaut wird.
DO $$
DECLARE v_typ text; v_n int; v_leer int; r record;
BEGIN
  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='users' AND column_name='birthdate';
  RAISE NOTICE 'users.birthdate ist vom Typ %', v_typ;

  SELECT count(*) INTO v_n FROM public.users WHERE birthdate IS NOT NULL;
  RAISE NOTICE 'Mit Geburtsdatum: % von %', v_n, (SELECT count(*) FROM public.users);

  IF v_typ = 'text' THEN
    SELECT count(*) INTO v_leer FROM public.users WHERE birthdate = '';
    RAISE NOTICE 'Leere Zeichenketten statt NULL: %', v_leer;
    FOR r IN SELECT DISTINCT birthdate FROM public.users
              WHERE birthdate IS NOT NULL AND birthdate <> '' LIMIT 5 LOOP
      RAISE NOTICE '  Beispiel: %', r.birthdate;
    END LOOP;
  ELSE
    FOR r IN SELECT birthdate FROM public.users WHERE birthdate IS NOT NULL LIMIT 5 LOOP
      RAISE NOTICE '  Beispiel: %', r.birthdate;
    END LOOP;
  END IF;
END $$;
