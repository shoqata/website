-- Protokolle fuer die Mitglieder freigeben.
--
-- Bisher sah nur die Geschaeftsfuehrung die Protokolle. Der Vorstand soll
-- einzelne davon fuer die Mitglieder oeffnen koennen -- nicht alle, und nicht
-- versehentlich.
--
-- Die Freigabe steht deshalb in den Zugriffsregeln, nicht in der
-- Benutzeroberflaeche: ein Mitglied bekommt ein nicht freigegebenes Protokoll
-- gar nicht erst geliefert, unabhaengig davon, was der Client anzeigen moechte.

ALTER TABLE public.board_meetings
  ADD COLUMN IF NOT EXISTS "publishedToMembers" boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "publishedAt" timestamptz,
  ADD COLUMN IF NOT EXISTS "publishedBy" text;

CREATE INDEX IF NOT EXISTS board_meetings_veroeffentlicht
  ON public.board_meetings ("tenantId", date DESC) WHERE "publishedToMembers";

-- Die bestehende Regel bleibt, wie sie ist: die Geschaeftsfuehrung darf alles.
-- Daneben duerfen Mitglieder des Vereins lesen, was freigegeben wurde.
DROP POLICY IF EXISTS board_meetings_published_read ON public.board_meetings;
CREATE POLICY board_meetings_published_read ON public.board_meetings FOR SELECT TO authenticated
  USING (
    "publishedToMembers" IS TRUE
    AND "tenantId" = public.current_tenant()
  );

-- Der Verlauf bleibt der Geschaeftsfuehrung vorbehalten. Ein Mitglied soll die
-- gueltige Fassung sehen, nicht die Entstehungsgeschichte -- fruehere Fassungen
-- koennen Zwischenstaende enthalten, die so nie beschlossen wurden.

-- Wer die Freigabe setzt, wird mitgeschrieben. Das gehoert zur Sache: eine
-- Veroeffentlichung ist eine Entscheidung, keine Einstellung.
CREATE OR REPLACE FUNCTION public.board_meeting_freigabe()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."publishedToMembers" IS DISTINCT FROM coalesce(OLD."publishedToMembers", false) THEN
    IF NEW."publishedToMembers" THEN
      NEW."publishedAt" := now();
      NEW."publishedBy" := coalesce(public.current_user_row_id(), auth.jwt() ->> 'email', 'unbekannt');
    ELSE
      NEW."publishedAt" := NULL;
      NEW."publishedBy" := NULL;
    END IF;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS board_meetings_freigabe ON public.board_meetings;
CREATE TRIGGER board_meetings_freigabe
  BEFORE UPDATE ON public.board_meetings
  FOR EACH ROW EXECUTE FUNCTION public.board_meeting_freigabe();

NOTIFY pgrst, 'reload schema';
