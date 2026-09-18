-- Die Vorstandsliste zeigte auf die falsche Zeile.
--
-- Der Eintrag "Praeseident" verwies auf IzziI1TFNxohutfElKYK -- das ist
-- Valton Rexhas Dublette mit der kuenstlich veraenderten Adresse
-- valton.rexha_IzziI@gmail.com, und sie steht auf INACTIVE. Auf der
-- oeffentlichen Seite haengt der Praesident damit an einem Datensatz, der als
-- ausgetreten gilt und den niemand erreicht.
--
-- Die aktive Zeile ist 0UMG0pIQFUWOmWLiTLZz6rP82122 mit valton.rexha@gmail.com.
DO $$
DECLARE v_alt text; v_neu text; v_n int;
BEGIN
  SELECT id INTO v_alt FROM public.users WHERE email = 'valton.rexha_IzziI@gmail.com';
  SELECT id INTO v_neu FROM public.users WHERE email = 'valton.rexha@gmail.com';

  IF v_alt IS NULL OR v_neu IS NULL THEN
    RAISE NOTICE 'Eine der beiden Zeilen fehlt -- nichts geaendert.'; RETURN;
  END IF;

  UPDATE public.board_members SET "userId" = v_neu WHERE "userId" = v_alt;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Vorstandseintraege umgehaengt: % (von % auf %)', v_n, v_alt, v_neu;
END $$;

DO $$
DECLARE r record; v_fehler int := 0;
BEGIN
  RAISE NOTICE '=== Vorstandsliste nachher ===';
  FOR r IN SELECT bm.role AS funktion,
                  coalesce(u."displayName",'<Zeile fehlt>') AS person,
                  coalesce(u.email,'-') AS mail,
                  coalesce(u."membershipStatus",'-') AS status
             FROM public.board_members bm
             LEFT JOIN public.users u ON u.id = bm."userId"
            ORDER BY bm.role LOOP
    RAISE NOTICE '  % -> % (%) %', r.funktion, r.person, r.mail, r.status;
    IF r.status <> 'ACTIVE' OR r.person = '<Zeile fehlt>' THEN v_fehler := v_fehler + 1; END IF;
  END LOOP;
  RAISE NOTICE 'Eintraege, die auf eine fehlende oder inaktive Zeile zeigen: % -- erwartet 0', v_fehler;
END $$;
