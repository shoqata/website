-- Aufraeumen und Nachweis.
--
-- 1. Die Testanmeldungen aus der Pruefung der Gast-Policy entfernen.
-- 2. Die Kapazitaetssperre nicht nur einbauen, sondern belegen: eine
--    Wegwerf-Veranstaltung mit genau einem Platz, zwei Anmeldungen, die zweite
--    muss scheitern. Laeuft vollstaendig in dieser Transaktion und raeumt sich
--    selbst wieder ab -- es bleibt kein Datensatz zurueck.

DELETE FROM public.event_registrations WHERE id LIKE 'probe-guest-%';

DO $$
DECLARE
  v_blocked boolean := false;
BEGIN
  INSERT INTO public.events (id, title, date, "limit")
  VALUES ('__capacity_selftest', 'Kapazitaetstest', '2026-01-01', 1);

  INSERT INTO public.event_registrations (id, "eventId", name, type, status)
  VALUES ('__capacity_selftest_1', '__capacity_selftest', 'Erster', 'GUEST', 'PENDING');

  BEGIN
    INSERT INTO public.event_registrations (id, "eventId", name, type, status)
    VALUES ('__capacity_selftest_2', '__capacity_selftest', 'Zweiter', 'GUEST', 'PENDING');
  EXCEPTION WHEN check_violation THEN
    v_blocked := true;
  END;

  DELETE FROM public.event_registrations WHERE "eventId" = '__capacity_selftest';
  DELETE FROM public.events WHERE id = '__capacity_selftest';

  IF v_blocked THEN
    RAISE NOTICE 'KAPAZITAETSSPERRE: erste Anmeldung angenommen, zweite abgewiesen -- wirkt.';
  ELSE
    RAISE EXCEPTION 'KAPAZITAETSSPERRE WIRKT NICHT: die zweite Anmeldung ging durch.';
  END IF;
END $$;
