-- Welche Schreibregeln gelten fuer users?
--
-- Ein Mitglied kommt beim Speichern des eigenen Profils nicht durch:
-- "new row violates row-level security policy". Bevor irgendetwas gelockert
-- wird, muss auf dem Tisch liegen, welche Regeln es gibt und woran genau die
-- Zeile scheitert. Eine Regel fuer users zu lockern trifft alle 350 Zeilen.
DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '--- Regeln auf public.users ---';
  FOR r IN SELECT policyname, cmd, roles::text AS rollen,
                  coalesce(qual,'(keine)')       AS lesebedingung,
                  coalesce(with_check,'(keine)') AS schreibbedingung
             FROM pg_policies WHERE schemaname='public' AND tablename='users'
            ORDER BY cmd, policyname LOOP
    RAISE NOTICE '% [%] fuer %', r.policyname, r.cmd, r.rollen;
    RAISE NOTICE '    USING      : %', r.lesebedingung;
    RAISE NOTICE '    WITH CHECK : %', r.schreibbedingung;
  END LOOP;
END $$;
