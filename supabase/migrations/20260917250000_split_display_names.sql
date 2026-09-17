-- Vor- und Nachname aus dem Anzeigenamen ableiten.
--
-- Beim Datenimport wurde nur "displayName" gefuellt. Die Felder Vorname und
-- Nachname im Mitglieder-Detail waren deshalb bei 328 bzw. 331 der 350
-- Mitglieder leer -- jedes Mal aufs Neue, weshalb der Eindruck entstand, die
-- Eingabe falle beim Speichern heraus. Sie war nie vorhanden.
--
-- Regel: das letzte Wort ist der Nachname, alles davor der Vorname. Bei
-- Doppelnamen wie "Ardit Muharrem Krasniqi" ergibt das Vorname "Ardit
-- Muharrem" -- fuer diesen Bestand die brauchbarere Annahme als umgekehrt.
-- Der Anzeigename selbst bleibt unberuehrt, die Ableitung laesst sich also
-- jederzeit korrigieren.

DO $$
DECLARE
  v_vorher_ohne_vor  int;
  v_vorher_ohne_nach int;
  v_geaendert        int;
  v_ein_wort         int;
  r record;
BEGIN
  SELECT count(*) INTO v_vorher_ohne_vor  FROM public.users
   WHERE "firstName" IS NULL OR btrim("firstName") = '';
  SELECT count(*) INTO v_vorher_ohne_nach FROM public.users
   WHERE "lastName"  IS NULL OR btrim("lastName")  = '';
  RAISE NOTICE 'Vorher ohne Vorname: %, ohne Nachname: %', v_vorher_ohne_vor, v_vorher_ohne_nach;

  -- Nur dort, wo noch nichts steht. Bereits erfasste Namen werden nicht angetastet.
  WITH kandidaten AS (
    SELECT id,
           regexp_split_to_array(btrim(regexp_replace("displayName", '\s+', ' ', 'g')), ' ') AS teile
      FROM public.users
     WHERE "displayName" IS NOT NULL
       AND btrim("displayName") <> ''
       AND ("firstName" IS NULL OR btrim("firstName") = '')
       AND ("lastName"  IS NULL OR btrim("lastName")  = '')
  )
  UPDATE public.users u
     SET "firstName" = CASE WHEN array_length(k.teile, 1) > 1
                            THEN array_to_string(k.teile[1:array_length(k.teile,1)-1], ' ')
                            ELSE k.teile[1] END,
         "lastName"  = CASE WHEN array_length(k.teile, 1) > 1
                            THEN k.teile[array_length(k.teile,1)]
                            ELSE NULL END
    FROM kandidaten k
   WHERE u.id = k.id;
  GET DIAGNOSTICS v_geaendert = ROW_COUNT;
  RAISE NOTICE 'Namen abgeleitet bei % Mitgliedern.', v_geaendert;

  SELECT count(*) INTO v_ein_wort FROM public.users
   WHERE "lastName" IS NULL AND "firstName" IS NOT NULL;
  RAISE NOTICE 'Nur ein Wort im Anzeigenamen, daher ohne Nachname: %', v_ein_wort;

  SELECT count(*) INTO v_vorher_ohne_vor  FROM public.users
   WHERE "firstName" IS NULL OR btrim("firstName") = '';
  RAISE NOTICE 'Nachher ohne Vorname: %', v_vorher_ohne_vor;

  RAISE NOTICE '--- Stichprobe ---';
  FOR r IN SELECT "displayName", "firstName", "lastName" FROM public.users
            WHERE "displayName" ILIKE '%canaj%' LIMIT 4 LOOP
    RAISE NOTICE '  "%" -> Vorname "%", Nachname "%"',
      r."displayName", r."firstName", COALESCE(r."lastName",'<keiner>');
  END LOOP;
END $$;
