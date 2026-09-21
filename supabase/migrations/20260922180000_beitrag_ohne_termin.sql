-- Ein Beitrag stand auf SCHEDULED, ohne Termin. Das ist kein Zufall: die
-- Oberflaeche schrieb das Feld scheduledFor, die Spalte heisst scheduledTime
-- -- der Termin landete nirgends. Ein Vormerk ohne Zeitpunkt kann nie
-- ausloesen und zeigte in der Liste "Invalid Date".
DO $$
DECLARE v_n int;
BEGIN
  UPDATE public.socialmediaposts
     SET status = 'DRAFT'
   WHERE status = 'SCHEDULED' AND "scheduledTime" IS NULL;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Auf Entwurf zurueckgesetzt: %', v_n;
END $$;
