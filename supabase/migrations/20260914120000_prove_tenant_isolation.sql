-- Diagnose vor dem eigentlichen Nachweis: unter welcher Rolle laeuft eine
-- Migration, wem gehoeren die Tabellen, und sind Reste frueherer Fehlversuche
-- liegengeblieben? Ergebnis: current_user = postgres, Eigentuemer der Tabellen,
-- volle Rechte, keine Reste. Damit war klar, dass der Rechtefehler im
-- Testaufbau lag und nicht an der Migrationsrolle.
DO $d$
DECLARE n int;
BEGIN
  RAISE NOTICE 'current_user=%  session_user=%', current_user, session_user;
  RAISE NOTICE 'Eigentuemer accounting_journal=%',
    (SELECT tableowner FROM pg_tables WHERE schemaname='public' AND tablename='accounting_journal');
  RAISE NOTICE 'DELETE-Recht accounting_journal: %',
    has_table_privilege(current_user, 'public.accounting_journal', 'DELETE');
  SELECT count(*) INTO n FROM public.users WHERE id LIKE '__iso%';
  RAISE NOTICE 'Reste aus Fehlversuchen: % Zeilen', n;
END
$d$;
