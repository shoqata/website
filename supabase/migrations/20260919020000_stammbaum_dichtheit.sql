-- Wer kommt an den Stammbaum heran?
-- Geprueft in den Rollen, in denen die Anwendung wirklich arbeitet.
DO $$
DECLARE v_n int; v_back text := current_user; v_a text; v_b text; v_c text;
BEGIN
  -- Zwei echte Personen fuer die Probe.
  SELECT id INTO v_a FROM public.users WHERE "tenantId"='koretini' ORDER BY id LIMIT 1;
  SELECT id INTO v_b FROM public.users WHERE "tenantId"='koretini' AND id <> v_a ORDER BY id LIMIT 1;
  SELECT id INTO v_c FROM public.users WHERE "tenantId"='koretini' AND id NOT IN (v_a,v_b) ORDER BY id LIMIT 1;

  INSERT INTO public.family_links ("tenantId", von, nach, art)
  VALUES ('koretini', v_a, v_b, 'ELTERNTEIL') ON CONFLICT DO NOTHING;
  RAISE NOTICE 'Probebeziehung angelegt: % ist Elternteil von %', left(v_a,8), left(v_b,8);

  -- Kreis: b ist Elternteil von a waere ein Zyklus.
  BEGIN
    INSERT INTO public.family_links ("tenantId", von, nach, art)
    VALUES ('koretini', v_b, v_a, 'ELTERNTEIL');
    RAISE NOTICE 'Kreis wurde angelegt -- FEHLER';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Kreis abgewiesen (richtig): %', left(SQLERRM, 60);
  END;

  -- Sich selbst als Elternteil.
  BEGIN
    INSERT INTO public.family_links ("tenantId", von, nach, art)
    VALUES ('koretini', v_a, v_a, 'ELTERNTEIL');
    RAISE NOTICE 'Selbstbezug angelegt -- FEHLER';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Selbstbezug abgewiesen (richtig)';
  END;

  -- Partner doppelt, in beide Richtungen.
  INSERT INTO public.family_links ("tenantId", von, nach, art)
  VALUES ('koretini', v_a, v_c, 'PARTNER') ON CONFLICT DO NOTHING;
  BEGIN
    INSERT INTO public.family_links ("tenantId", von, nach, art)
    VALUES ('koretini', v_c, v_a, 'PARTNER');
    RAISE NOTICE 'Partner zweimal angelegt -- FEHLER';
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Partner in Gegenrichtung abgewiesen (richtig)';
  END;

  SELECT count(*) INTO v_n FROM public.familien_uebersicht()
   WHERE familie IN (SELECT familie FROM public.familien_uebersicht() WHERE person = v_a);
  RAISE NOTICE 'Familie um die Probeperson: % Personen', v_n;

  -- --- Rollen ---
  SET LOCAL ROLE anon;
  BEGIN
    SELECT count(*) INTO v_n FROM public.family_links;
    RAISE NOTICE 'anon liest Beziehungen: % -- LOCH', v_n;
  EXCEPTION WHEN insufficient_privilege OR undefined_table THEN
    RAISE NOTICE 'anon: kein Zugriff (richtig)';
  END;

  SET LOCAL ROLE authenticated;
  BEGIN
    SELECT count(*) INTO v_n FROM public.family_links;
    IF v_n = 0 THEN
      RAISE NOTICE 'Mitglied ohne Rolle sieht 0 Beziehungen (richtig)';
    ELSE
      RAISE NOTICE 'Mitglied ohne Rolle sieht % Beziehungen -- LOCH', v_n;
    END IF;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Mitglied: kein Zugriff (richtig)';
  END;
  BEGIN
    INSERT INTO public.family_links (von, nach, art) VALUES (v_b, v_c, 'PARTNER');
    RAISE NOTICE 'Mitglied ohne Rolle legt Beziehung an -- LOCH';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Mitglied darf nichts anlegen (richtig)';
  END;

  EXECUTE format('SET ROLE %I', v_back);

  DELETE FROM public.family_links;
  RAISE NOTICE 'Proben entfernt, % Beziehungen bleiben.', (SELECT count(*) FROM public.family_links);
END $$;
