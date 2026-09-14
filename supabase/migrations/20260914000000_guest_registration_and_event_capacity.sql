-- Zwei Dinge an den Veranstaltungsanmeldungen.
--
-- 1. Gastanmeldungen waren kaputt -- verursacht durch meine eigenen Policies.
--    /events ist eine oeffentliche Seite mit einem Gastformular, aber beim
--    Zumachen von event_registrations habe ich anon vollstaendig ausgesperrt.
--    Anonyme duerfen jetzt genau eines: eine Anmeldung ohne userId anlegen.
--    Lesen bleibt der Verwaltung und dem jeweiligen Mitglied vorbehalten.
--
-- 2. events."limit" ist gesetzt (100 bzw. 150), wurde aber nirgends geprueft.
--    Die Begrenzung gehoert an die Daten und nicht ins Formular: ein Gast darf
--    fremde Anmeldungen nicht lesen und koennte sie im Browser gar nicht zaehlen.

GRANT INSERT ON TABLE public.event_registrations TO anon;

DROP POLICY IF EXISTS event_registrations_guest_insert ON public.event_registrations;
CREATE POLICY event_registrations_guest_insert ON public.event_registrations
  FOR INSERT TO anon
  WITH CHECK ("userId" IS NULL);

CREATE OR REPLACE FUNCTION public.enforce_event_capacity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit int;
  v_taken int;
BEGIN
  SELECT e."limit" INTO v_limit FROM public.events e WHERE e.id = NEW."eventId";

  IF v_limit IS NULL OR v_limit <= 0 THEN
    RETURN NEW; -- keine Begrenzung hinterlegt
  END IF;

  SELECT count(*) INTO v_taken
    FROM public.event_registrations r
   WHERE r."eventId" = NEW."eventId"
     AND COALESCE(r.status, 'PENDING') <> 'CANCELLED';

  IF v_taken >= v_limit THEN
    RAISE EXCEPTION 'Die Veranstaltung ist ausgebucht (% von % Plätzen belegt).', v_taken, v_limit
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS event_registrations_capacity ON public.event_registrations;
CREATE TRIGGER event_registrations_capacity
BEFORE INSERT ON public.event_registrations
FOR EACH ROW EXECUTE FUNCTION public.enforce_event_capacity();
