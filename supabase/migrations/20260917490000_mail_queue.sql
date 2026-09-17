-- Warteschlange fuer ausgehende E-Mails.
--
-- sendEmail() schrieb bisher in eine Tabelle 'mail' und setzte darauf, dass
-- die Firebase-Erweiterung "Trigger Email" sie abholt. Seit der Umstellung auf
-- Supabase gibt es diese Tabelle nicht mehr -- der Aufruf scheiterte still,
-- und es wurde keine einzige Nachricht versendet. Auch keine Rechnung.
--
-- Die Warteschlange ist der fehlende Unterbau: hier landet, was hinaus soll,
-- und es bleibt nachweisbar liegen, bis es tatsaechlich versendet wurde. Was
-- scheitert, verschwindet nicht, sondern traegt seinen Fehler bei sich.

CREATE TABLE IF NOT EXISTS public.mail_queue (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"   text NOT NULL,
  recipient    text NOT NULL,
  subject      text NOT NULL,
  html         text NOT NULL,
  text         text,
  attachments  jsonb NOT NULL DEFAULT '[]'::jsonb,
  kind         text NOT NULL DEFAULT 'GENERIC',
  "memberId"   text,
  "refYear"    int,
  status       text NOT NULL DEFAULT 'PENDING',
  attempts     int  NOT NULL DEFAULT 0,
  "lastError"  text,
  "scheduledFor" timestamptz NOT NULL DEFAULT now(),
  "sentAt"     timestamptz,
  "createdAt"  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT mail_queue_status_chk CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'CANCELLED'))
);

-- Ein Geburtstagsgruss je Mitglied und Jahr. Laeuft der taegliche Auftrag aus
-- irgendeinem Grund zweimal, entsteht kein zweiter Gruss.
CREATE UNIQUE INDEX IF NOT EXISTS mail_queue_once_per_year
  ON public.mail_queue (kind, "memberId", "refYear")
  WHERE "memberId" IS NOT NULL AND "refYear" IS NOT NULL;

CREATE INDEX IF NOT EXISTS mail_queue_pending
  ON public.mail_queue ("scheduledFor") WHERE status = 'PENDING';

ALTER TABLE public.mail_queue ENABLE ROW LEVEL SECURITY;

-- Die Warteschlange enthaelt Anschriften und Inhalte aller Mitglieder. Nur die
-- Geschaeftsfuehrung sieht sie; die Betreuung einer Nachbarschaft
-- ausdruecklich nicht.
DROP POLICY IF EXISTS mail_queue_staff ON public.mail_queue;
CREATE POLICY mail_queue_staff ON public.mail_queue FOR ALL TO authenticated
  USING (public.is_member_manager() AND "tenantId" = public.current_tenant())
  WITH CHECK (public.is_member_manager() AND "tenantId" = public.current_tenant());

REVOKE ALL ON public.mail_queue FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mail_queue TO authenticated;

NOTIFY pgrst, 'reload schema';
