-- Woran haengen die Zeilen, die weg sollen?
--
-- Vor jedem Loeschen muss auf dem Tisch liegen, was ins Leere zeigen wuerde.
-- Die vorige Fassung scheiterte an einer Spalte, deren Typ ich angenommen
-- statt nachgesehen hatte.
DO $$
DECLARE r record; v_typ text;
BEGIN
  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='tasks' AND column_name='assignedTo';
  RAISE NOTICE 'tasks.assignedTo ist vom Typ %', coalesce(v_typ, '<Spalte gibt es nicht>');

  RAISE NOTICE '=== Verweise auf die betroffenen Zeilen ===';
  FOR r IN
    SELECT u.id, coalesce(u.email,'<keine>') AS mail, coalesce(u.role,'-') AS rolle,
           (SELECT count(*) FROM public.payments x        WHERE x."userId" = u.id)      AS zahlungen,
           (SELECT count(*) FROM public.board_members x   WHERE x."userId" = u.id)      AS vorstand,
           (SELECT count(*) FROM public.event_registrations x WHERE x."userId" = u.id)  AS anmeldungen,
           (SELECT count(*) FROM public.payment_reports x WHERE x."reportedBy" = u.id)  AS meldungen,
           (SELECT count(*) FROM public.neighborhoods x
             WHERE x."representativeId" = u.id OR x."managerId" = u.id)                 AS nb_alt,
           (SELECT count(*) FROM public.neighborhoods x
             WHERE x."contactPersonIds" IS NOT NULL
               AND x."contactPersonIds" @> to_jsonb(u.id::text))                        AS nb_kontakt
      FROM public.users u
     WHERE lower(btrim(u."displayName")) IN ('burim dervishi','valton rexha','qazim dervishi',
                                             'ledion dervishi','atest')
     ORDER BY lower(btrim(u."displayName")), u.email NULLS LAST
  LOOP
    RAISE NOTICE '  % | % [%]', r.id, r.mail, r.rolle;
    RAISE NOTICE '     Zahlungen % | Vorstandsliste % | Anmeldungen % | Meldungen % | Nachbarschaft alt % | als Kontakt %',
      r.zahlungen, r.vorstand, r.anmeldungen, r.meldungen, r.nb_alt, r.nb_kontakt;
  END LOOP;

  RAISE NOTICE '=== Vorstandsliste: zeigt sie auf gueltige Zeilen? ===';
  FOR r IN
    SELECT bm.role AS funktion, bm."userId",
           coalesce(u."displayName",'<Zeile fehlt>') AS person,
           coalesce(u.email,'-') AS mail,
           coalesce(u."membershipStatus",'-') AS status
      FROM public.board_members bm
      LEFT JOIN public.users u ON u.id = bm."userId"
     ORDER BY bm.role
  LOOP
    RAISE NOTICE '  % -> % (%) Status %', r.funktion, r.person, r.mail, r.status;
  END LOOP;
END $$;
