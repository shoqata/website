-- Worin unterscheidet sich die neue Zeile von einer, mit der die Anmeldung geht?
--
-- GoTrue meldet "Database error querying schema". Das kommt typischerweise
-- daher, dass Spalten NULL sind, die der Dienst als Zeichenkette einliest --
-- die Token-Felder werden dort mit '' gefuehrt, nicht mit NULL.
DO $$
DECLARE r record; v_neu jsonb; v_alt jsonb; k text; v_n int := 0;
BEGIN
  SELECT to_jsonb(au) INTO v_neu FROM auth.users au WHERE au.email = 'valton.rexha@gmail.com';
  SELECT to_jsonb(au) INTO v_alt FROM auth.users au WHERE au.email = 'selmani.besart@hotmail.com';

  IF v_neu IS NULL OR v_alt IS NULL THEN
    RAISE NOTICE 'Eine der beiden Zeilen fehlt.'; RETURN;
  END IF;

  RAISE NOTICE '=== Spalten, die sich unterscheiden ===';
  FOR k IN SELECT jsonb_object_keys(v_alt) ORDER BY 1 LOOP
    IF k IN ('id','email','created_at','updated_at','encrypted_password',
             'email_confirmed_at','confirmed_at','last_sign_in_at') THEN
      CONTINUE;  -- dass die sich unterscheiden, ist erwartet
    END IF;
    IF (v_neu -> k) IS DISTINCT FROM (v_alt -> k) THEN
      RAISE NOTICE '  %: neu=%  alt=%', k,
        coalesce((v_neu -> k)::text, '<fehlt>'), coalesce((v_alt -> k)::text, '<fehlt>');
      v_n := v_n + 1;
    END IF;
  END LOOP;
  RAISE NOTICE '  % Unterschiede', v_n;
END $$;
