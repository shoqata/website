-- Kuenstlich veraenderte E-Mail-Adressen.
--
-- Drei Adressen fallen auf: qazim_dIoze@dervishi.ch, ledion_w23EC@dervishi.ch,
-- valton.rexha_IzziI@gmail.com. Das Muster ist immer dasselbe -- an den
-- oertlichen Teil wurde ein Stueck der Zeilenkennung angehaengt. So etwas
-- entsteht, wenn beim Import eine zweite Zeile mit derselben Adresse angelegt
-- werden soll und die Eindeutigkeit das verhindert.
--
-- Folge: diese Menschen erreicht keine Nachricht, und anmelden koennen sie sich
-- unter ihrer echten Adresse auch nicht -- die gehoert der anderen Zeile.
DO $$
DECLARE r record; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.users u
   WHERE u.email IS NOT NULL
     AND split_part(u.email, '@', 1) ~ '_[A-Za-z0-9]{4,6}$';
  RAISE NOTICE 'Adressen mit angehaengter Kennung: %', v_n;

  FOR r IN SELECT u.id, u."displayName", u.email, coalesce(u.role,'-') AS rolle,
                  coalesce(u."membershipStatus",'-') AS status,
                  (SELECT count(*) FROM public.payments p WHERE p."userId" = u.id) AS rechnungen
             FROM public.users u
            WHERE u.email IS NOT NULL
              AND split_part(u.email, '@', 1) ~ '_[A-Za-z0-9]{4,6}$'
            ORDER BY u."displayName" LOOP
    RAISE NOTICE '  % | % | % | % | % Rechnungen',
      r."displayName", r.email, r.rolle, r.status, r.rechnungen;
  END LOOP;

  RAISE NOTICE '=== Gibt es dazu jeweils eine Zeile mit der echten Adresse? ===';
  FOR r IN
    SELECT a."displayName" AS person,
           a.email AS veraendert,
           b.email AS echt,
           coalesce(b.role,'-') AS rolle_echt,
           coalesce(b."membershipStatus",'-') AS status_echt
      FROM public.users a
      JOIN public.users b
        ON b.id <> a.id
       AND lower(b.email) = lower(
             regexp_replace(split_part(a.email,'@',1), '_[A-Za-z0-9]{4,6}$', '')
             || '@' || split_part(a.email,'@',2))
     WHERE a.email IS NOT NULL
       AND split_part(a.email,'@',1) ~ '_[A-Za-z0-9]{4,6}$'
  LOOP
    RAISE NOTICE '  %: % gehoert zu % (% / %)',
      r.person, r.veraendert, r.echt, r.rolle_echt, r.status_echt;
  END LOOP;
  IF NOT FOUND THEN RAISE NOTICE '  keine Gegenstuecke gefunden'; END IF;

  RAISE NOTICE '=== Doppelte Namen insgesamt ===';
  SELECT count(*) INTO v_n FROM (
    SELECT lower(btrim("displayName")) AS n FROM public.users
     WHERE "displayName" IS NOT NULL AND btrim("displayName") <> ''
     GROUP BY 1 HAVING count(*) > 1) x;
  RAISE NOTICE '  Namen, die mehrfach vorkommen: %', v_n;
  FOR r IN SELECT "displayName", count(*) AS n FROM public.users
            WHERE "displayName" IS NOT NULL GROUP BY 1 HAVING count(*) > 1
            ORDER BY 2 DESC, 1 LIMIT 12 LOOP
    RAISE NOTICE '    %: % Zeilen', r."displayName", r.n;
  END LOOP;
END $$;
