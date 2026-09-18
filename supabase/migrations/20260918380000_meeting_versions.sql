-- Versionen der Sitzungsprotokolle.
--
-- Ein Protokoll ist ein Dokument, auf das sich der Verein spaeter beruft.
-- Wird es ueberarbeitet, muss nachlesbar bleiben, was vorher darin stand und
-- wer es geaendert hat -- sonst ist eine stille Korrektur von einer
-- Faelschung nicht zu unterscheiden.
--
-- Die Version entsteht im Ausloeser, nicht in der Anwendung. So entsteht sie
-- bei jeder Aenderung, auch bei einer aus der Datenbank heraus, und ein
-- veraenderter Client kann sie nicht umgehen.

ALTER TABLE public.board_meetings
  ADD COLUMN IF NOT EXISTS version int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS "updatedAt" timestamptz,
  ADD COLUMN IF NOT EXISTS "updatedBy" text;

CREATE TABLE IF NOT EXISTS public.board_meeting_versions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  "meetingId" text NOT NULL,
  version     int  NOT NULL,
  snapshot    jsonb NOT NULL,
  "changedBy" text,
  "changedAt" timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS board_meeting_versions_eindeutig
  ON public.board_meeting_versions ("meetingId", version);
CREATE INDEX IF NOT EXISTS board_meeting_versions_nach_sitzung
  ON public.board_meeting_versions ("meetingId", "changedAt" DESC);

ALTER TABLE public.board_meeting_versions ENABLE ROW LEVEL SECURITY;

-- Lesen darf der Vorstand, aendern niemand: eine Fassung, die sich
-- nachtraeglich anpassen laesst, belegt nichts.
DROP POLICY IF EXISTS board_meeting_versions_read ON public.board_meeting_versions;
CREATE POLICY board_meeting_versions_read ON public.board_meeting_versions FOR SELECT TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant());

REVOKE ALL ON public.board_meeting_versions FROM anon, authenticated;
GRANT SELECT ON public.board_meeting_versions TO authenticated;

-- ------------------------------------------------------------- Ausloeser
CREATE OR REPLACE FUNCTION public.board_meeting_versionieren()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wer text;
BEGIN
  -- Nur echte inhaltliche Aenderungen zaehlen. Ein Speichern ohne Unterschied
  -- soll keine Version erzeugen, sonst ist die Liste nach kurzer Zeit
  -- unbrauchbar.
  IF to_jsonb(OLD) - 'version' - 'updatedAt' - 'updatedBy'
     IS NOT DISTINCT FROM
     to_jsonb(NEW) - 'version' - 'updatedAt' - 'updatedBy' THEN
    RETURN NEW;
  END IF;

  v_wer := coalesce(public.current_user_row_id(), auth.jwt() ->> 'email', 'unbekannt');

  -- Festgehalten wird der Stand VOR der Aenderung, unter seiner Versionsnummer.
  INSERT INTO public.board_meeting_versions
    ("tenantId", "meetingId", version, snapshot, "changedBy")
  VALUES (OLD."tenantId", OLD.id, OLD.version, to_jsonb(OLD), v_wer)
  ON CONFLICT ("meetingId", version) DO NOTHING;

  NEW.version    := OLD.version + 1;
  NEW."updatedAt" := now();
  NEW."updatedBy" := v_wer;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS board_meetings_versionieren ON public.board_meetings;
CREATE TRIGGER board_meetings_versionieren
  BEFORE UPDATE ON public.board_meetings
  FOR EACH ROW EXECUTE FUNCTION public.board_meeting_versionieren();

-- --------------------------------------------- Zahlung als bezahlt buchen
-- An einer Stelle statt in jeder Ansicht. paidAt ist eine Textspalte -- wer
-- das nicht weiss, schreibt einen Zeitstempel hinein und die Rechnungsansicht
-- stolpert darueber.
CREATE OR REPLACE FUNCTION public.mark_payment_paid(
  p_payment text,
  p_method  text DEFAULT NULL,
  p_paid_on date DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_me text := public.current_user_row_id();
BEGIN
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Vorstand oder Administration darf eine Zahlung buchen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.payments WHERE id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF r."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Diese Rechnung gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF r.status = 'PAID' THEN
    RETURN true;  -- schon gebucht, nichts zu tun
  END IF;

  UPDATE public.payments
     SET status = 'PAID',
         "paidAt" = coalesce(p_paid_on::text, current_date::text),
         method = coalesce(p_method, method),
         "collectedBy" = coalesce("collectedBy", v_me)
   WHERE id = p_payment;

  -- Eine offene Meldung zu dieser Rechnung gilt damit als erledigt.
  UPDATE public.payment_reports
     SET status = 'CONFIRMED', "decidedBy" = v_me, "decidedAt" = now(),
         "decisionNote" = 'Direkt im Vorstandsbereich gebucht'
   WHERE "paymentId" = p_payment AND status = 'OPEN';

  RETURN true;
END $$;

GRANT EXECUTE ON FUNCTION public.mark_payment_paid(text, text, date) TO authenticated;

NOTIFY pgrst, 'reload schema';
