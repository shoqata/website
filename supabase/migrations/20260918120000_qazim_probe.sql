-- Was ist mit den beiden Zeilen von Qazim Dervishi?
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Alle Zeilen mit diesem Namen ===';
  FOR r IN SELECT u.id, u."displayName", u.role, u."membershipStatus",
                  coalesce(u.email,'-') AS mail,
                  coalesce(u."neighborhoodId",'-') AS nb,
                  coalesce(u."authUserId",'-') AS konto,
                  (SELECT count(*) FROM public.payments p WHERE p."userId" = u.id) AS rechnungen
             FROM public.users u WHERE u."displayName" ILIKE '%qazim%' ORDER BY u.id LOOP
    RAISE NOTICE '  %', r.id;
    RAISE NOTICE '     % | Rolle % | Status % | % | Nachbarschaft %',
      r."displayName", r.role, coalesce(r."membershipStatus",'<null>'), r.mail, r.nb;
    RAISE NOTICE '     Konto % | % Rechnungen', r.konto, r.rechnungen;
  END LOOP;

  RAISE NOTICE '=== Wer betreut deren Nachbarschaft? ===';
  FOR r IN SELECT n.name, n.id,
                  coalesce(n."contactPersonIds"::text,'[]') AS ids,
                  coalesce(n."representativeId",'-') AS rep,
                  coalesce(n."managerId",'-') AS mgr
             FROM public.neighborhoods n
            WHERE n.id IN (SELECT "neighborhoodId" FROM public.users WHERE "displayName" ILIKE '%qazim%') LOOP
    RAISE NOTICE '  % (%)', r.name, r.id;
    RAISE NOTICE '     contactPersonIds % | representativeId % | managerId %', r.ids, r.rep, r.mgr;
  END LOOP;

  -- Was "Entfernen" im Adminbereich tatsaechlich tut: es setzt INACTIVE,
  -- es loescht nicht. Deshalb bleibt die Zeile ueberall sichtbar.
  RAISE NOTICE '=== Verteilung membershipStatus ===';
  FOR r IN SELECT coalesce("membershipStatus",'<null>') AS st, count(*) AS n
             FROM public.users GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  %: %', r.st, r.n;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.users WHERE role = 'REPRESENTATIVE';
  RAISE NOTICE 'Mitglieder mit Rolle REPRESENTATIVE: % -- die Betreuung darf nur MEMBER bearbeiten', v_n;
END $$;
