-- Aufraeumen nach dem Trennungsnachweis.
--
-- Der Nachweis lief durch, aber das Aufraeumen darin stand womoeglich noch unter
-- der umgeschalteten Rolle -- dann loescht die Zeilensicherheit nicht, sie
-- filtert nur, und ein DELETE ohne Treffer meldet trotzdem Erfolg. Genau die
-- Sorte stiller Fehlschlag, die man nicht stehen laesst. Diese Migration laeuft
-- in einer frischen Sitzung als Eigentuemer und zaehlt nach.
DO $c$
DECLARE n int;
BEGIN
  RAISE NOTICE 'Rolle: %', current_user;
  SELECT count(*) INTO n FROM public.users WHERE id LIKE '__iso%';
  RAISE NOTICE 'gefundene Testzeilen users: %', n;

  DELETE FROM public.accounting_journal WHERE "referenceId" LIKE '__iso%';
  DELETE FROM public.payments WHERE id LIKE '__iso%';
  DELETE FROM public.users    WHERE id LIKE '__iso%';
  DELETE FROM public.tenants  WHERE id LIKE '__iso%';

  SELECT count(*) INTO n FROM public.users WHERE id LIKE '__iso%';
  IF n > 0 THEN RAISE EXCEPTION 'Testzeilen liessen sich nicht entfernen: %', n; END IF;
  SELECT count(*) INTO n FROM public.tenants WHERE id LIKE '__iso%';
  IF n > 0 THEN RAISE EXCEPTION 'Testmandanten liessen sich nicht entfernen: %', n; END IF;
  RAISE NOTICE 'AUFGERAEUMT: keine Testzeilen mehr vorhanden.';
END
$c$;
