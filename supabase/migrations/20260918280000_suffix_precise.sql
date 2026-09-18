-- Welche Adressen sind wirklich kuenstlich veraendert?
--
-- Meine erste Zaehlung suchte nach "_" plus vier bis sechs Zeichen am Ende des
-- oertlichen Teils und kam auf sieben. Das trifft aber auch ganz gewoehnliche
-- Adressen wie berat_haxhiu@ oder shpend_basha@. Kuenstlich ist eine Adresse
-- nur dann, wenn der angehaengte Teil der Anfang der Zeilenkennung ist -- so
-- entsteht das Muster beim Import.
DO $$
DECLARE r record; v_echt int := 0; v_falsch int := 0;
BEGIN
  RAISE NOTICE '=== Tatsaechlich kuenstlich: Anhaengsel = Anfang der Zeilenkennung ===';
  FOR r IN
    SELECT u.id, u."displayName" AS nm, u.email,
           substring(split_part(u.email,'@',1) from '_([A-Za-z0-9]{4,6})$') AS anhang
      FROM public.users u
     WHERE u.email IS NOT NULL
       AND split_part(u.email,'@',1) ~ '_[A-Za-z0-9]{4,6}$'
     ORDER BY u."displayName"
  LOOP
    IF r.anhang IS NOT NULL AND left(r.id, length(r.anhang)) = r.anhang THEN
      RAISE NOTICE '  JA  % | % (Kennung beginnt mit %)', r.nm, r.email, r.anhang;
      v_echt := v_echt + 1;
    ELSE
      RAISE NOTICE '  nein % | % -- gewoehnliche Adresse, mein Muster traf zu Unrecht', r.nm, r.email;
      v_falsch := v_falsch + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'Kuenstlich: %, faelschlich verdaechtigt: %', v_echt, v_falsch;
END $$;
