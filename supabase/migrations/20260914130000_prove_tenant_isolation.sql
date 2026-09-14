-- Nachweis der Mandantentrennung. Stufe 3 von 3.
--
-- Zwei Testvereine, je ein Administrator, ein Mitglied und eine Zahlung. Die
-- Sitzung wird in beide Administratoren versetzt und gezaehlt, was sie sehen.
--
-- Aufgeteilt in drei Anweisungen, und das ist der Kern des Aufbaus: SET LOCAL
-- gilt nur fuer die Transaktion der jeweiligen Anweisung. Der Rollenwechsel im
-- mittleren Block endet also von selbst, und der dritte laeuft wieder als
-- Eigentuemer -- ein RESET ROLE, das hier nicht zuverlaessig greift, wird gar
-- nicht erst gebraucht. Die Messwerte wandern ueber Sitzungsvariablen.

-- ---------------------------------------------------------- 1. Testaufbau
DO $setup$
BEGIN
  DELETE FROM public.accounting_journal WHERE "referenceId" LIKE '__iso%';
  DELETE FROM public.payments WHERE id LIKE '__iso%';
  DELETE FROM public.users    WHERE id LIKE '__iso%';
  DELETE FROM public.tenants  WHERE id LIKE '__iso%';

  INSERT INTO public.tenants (id, slug, name) VALUES
    ('__iso_a', '__iso_a', 'Testverein A'),
    ('__iso_b', '__iso_b', 'Testverein B');

  INSERT INTO public.users (id, "tenantId", email, role, "displayName", "membershipStatus", "authUserId") VALUES
    ('__iso_u_a', '__iso_a', 'admin-a@iso.test',  'ADMIN',  'Admin A',    'ACTIVE', '00000000-0000-0000-0000-0000000000aa'),
    ('__iso_u_b', '__iso_b', 'admin-b@iso.test',  'ADMIN',  'Admin B',    'ACTIVE', '00000000-0000-0000-0000-0000000000bb'),
    ('__iso_m_a', '__iso_a', 'member-a@iso.test', 'MEMBER', 'Mitglied A', 'ACTIVE', NULL),
    ('__iso_m_b', '__iso_b', 'member-b@iso.test', 'MEMBER', 'Mitglied B', 'ACTIVE', NULL);

  INSERT INTO public.payments (id, "tenantId", "userId", amount, status) VALUES
    ('__iso_p_a', '__iso_a', '__iso_m_a', 111, 'PENDING'),
    ('__iso_p_b', '__iso_b', '__iso_m_b', 222, 'PENDING');
END
$setup$;

-- -------------------------------------------------- 2. Messung als Mitglied
DO $mess$
DECLARE v int; urspruenglich text := current_user;
BEGIN
  SET LOCAL ROLE authenticated;

  PERFORM set_config('request.jwt.claims',
    '{"sub":"00000000-0000-0000-0000-0000000000aa","email":"admin-a@iso.test"}', true);

  -- Kontrollmessung: greift die Zeilensicherheit hier ueberhaupt? Als
  -- Eigentuemer waeren die koretini-Zeilen sichtbar und alles Weitere wertlos.
  SELECT count(*) INTO v FROM public.users WHERE "tenantId" = 'koretini';
  PERFORM set_config('iso.koretini_sichtbar', v::text, false);
  SELECT count(*) INTO v FROM public.users WHERE "tenantId" = '__iso_a';
  PERFORM set_config('iso.a_eigen', v::text, false);
  SELECT count(*) INTO v FROM public.users WHERE "tenantId" = '__iso_b';
  PERFORM set_config('iso.a_fremd', v::text, false);
  SELECT count(*) INTO v FROM public.payments WHERE "tenantId" = '__iso_a';
  PERFORM set_config('iso.a_zahl', v::text, false);
  SELECT count(*) INTO v FROM public.payments WHERE "tenantId" = '__iso_b';
  PERFORM set_config('iso.a_zahl_fremd', v::text, false);
  SELECT count(*) INTO v FROM public.accounting_journal WHERE "tenantId" <> '__iso_a';
  PERFORM set_config('iso.a_buch_fremd', v::text, false);

  PERFORM set_config('iso.a_schreibt_fremd', '0', false);
  BEGIN
    INSERT INTO public.users (id, "tenantId", email, role, "displayName", "membershipStatus")
    VALUES ('__iso_intruder', '__iso_b', 'intruder@iso.test', 'MEMBER', 'Eindringling', 'ACTIVE');
  EXCEPTION WHEN insufficient_privilege OR check_violation THEN
    PERFORM set_config('iso.a_schreibt_fremd', '1', false);
  END;

  PERFORM set_config('request.jwt.claims',
    '{"sub":"00000000-0000-0000-0000-0000000000bb","email":"admin-b@iso.test"}', true);

  SELECT count(*) INTO v FROM public.users WHERE "tenantId" = '__iso_b';
  PERFORM set_config('iso.b_eigen', v::text, false);
  SELECT count(*) INTO v FROM public.users WHERE "tenantId" = '__iso_a';
  PERFORM set_config('iso.b_fremd', v::text, false);
  SELECT count(*) INTO v FROM public.payments WHERE "tenantId" = '__iso_a';
  PERFORM set_config('iso.b_zahl_fremd', v::text, false);

  -- Rolle ausdruecklich zuruecksetzen, statt auf das Ende der Transaktion zu
  -- vertrauen: bleibt sie stehen, loescht der Aufraeumblock nichts mehr (die
  -- Zeilensicherheit filtert ihn einfach weg, ohne Fehler) und selbst der
  -- Migrationslauf kann seinen eigenen Eintrag nicht mehr schreiben.
  EXECUTE format('SET LOCAL ROLE %I', urspruenglich);
END
$mess$;

-- ------------------------------------------ 3. Aufraeumen und Auswertung
DO $pruef$
DECLARE
  k text[] := ARRAY['iso.koretini_sichtbar','iso.a_eigen','iso.a_fremd','iso.a_zahl',
                    'iso.a_zahl_fremd','iso.a_buch_fremd','iso.a_schreibt_fremd',
                    'iso.b_eigen','iso.b_fremd','iso.b_zahl_fremd'];
  s int[]  := ARRAY[0, 2, 0, 1, 0, 0, 1, 2, 0, 0];
  i int; ist int; ok boolean := true;
BEGIN
  DELETE FROM public.accounting_journal WHERE "referenceId" LIKE '__iso%';
  DELETE FROM public.payments WHERE id LIKE '__iso%';
  DELETE FROM public.users    WHERE id LIKE '__iso%';
  DELETE FROM public.tenants  WHERE id LIKE '__iso%';
  PERFORM set_config('request.jwt.claims', '', false);

  FOR i IN 1 .. array_length(k, 1) LOOP
    ist := COALESCE(current_setting(k[i], true), '-1')::int;
    RAISE NOTICE '  % ist=% soll=%', rpad(k[i], 24), ist, s[i];
    IF ist <> s[i] THEN ok := false; END IF;
  END LOOP;

  IF ok THEN
    RAISE NOTICE 'MANDANTENTRENNUNG: beide Richtungen dicht, Schreibversuch abgewiesen -- wirkt.';
  ELSE
    RAISE EXCEPTION 'MANDANTENTRENNUNG NICHT DICHT -- siehe Zahlen oben.';
  END IF;
END
$pruef$;
