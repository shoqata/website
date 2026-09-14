-- Fundament fuer echte Mandantentrennung. Stufe 1 von 3.
--
-- Diese Migration aendert am laufenden Betrieb nichts Sichtbares: sie legt die
-- Plattformrolle an, ergaenzt die fehlenden Mandantenspalten, ordnet den
-- gesamten Bestand dem Mandanten 'koretini' zu und sorgt dafuer, dass kuenftig
-- keine Zeile mehr ohne Zugehoerigkeit entstehen kann. Die eigentliche
-- Abschottung in den Zugriffsregeln folgt in Stufe 2.

-- ---------------------------------------------------------------- Plattform
-- Bewusst getrennt von admin_emails: das ist die Freischaltung als
-- Vereinsadministrator. Wer die Plattform betreibt, ist etwas anderes als wer
-- einen Verein verwaltet, und die beiden duerfen nicht dieselbe Tabelle teilen.
CREATE TABLE IF NOT EXISTS public.platform_admins (
  email text PRIMARY KEY,
  note  text,
  "createdAt" timestamptz DEFAULT now()
);
ALTER TABLE public.platform_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_admins FORCE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.platform_admins FROM anon, authenticated;

INSERT INTO public.platform_admins (email, note)
VALUES ('email@dervishi.ch', 'Betreiber der Plattform')
ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.jwt() ->> 'email' IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.platform_admins
                  WHERE lower(email) = lower(auth.jwt() ->> 'email'))
$$;

REVOKE ALL ON FUNCTION public.is_platform_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_platform_admin() TO authenticated;

-- ------------------------------------------------- Fehlende Mandantenspalten
ALTER TABLE public.accounting_accounts  ADD COLUMN IF NOT EXISTS "tenantId" text;
ALTER TABLE public.board_members        ADD COLUMN IF NOT EXISTS "tenantId" text;
ALTER TABLE public.event_registrations  ADD COLUMN IF NOT EXISTS "tenantId" text;
ALTER TABLE public.inquiries            ADD COLUMN IF NOT EXISTS "tenantId" text;
ALTER TABLE public.security_logs        ADD COLUMN IF NOT EXISTS "tenantId" text;
ALTER TABLE public.settings             ADD COLUMN IF NOT EXISTS "tenantId" text;

-- ------------------------------------------------------- Bestand zuordnen
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','payments','expenses','accounting_journal','accounting_accounts',
    'fiscal_years','fiscal_budgets','board_meetings','board_members','tasks',
    'neighborhoods','events','news','polls','socialmediaposts',
    'event_registrations','inquiries','security_logs','settings'
  ] LOOP
    EXECUTE format('UPDATE public.%I SET "tenantId" = ''koretini'' WHERE "tenantId" IS NULL', t);
  END LOOP;
END $$;

-- --------------------------------------------- Kuenftig nie mehr ohne Mandant
-- Der Anwendungscode setzt tenantId nur an vier Stellen. Statt ihn ueberall
-- anzufassen, traegt ein Trigger den Mandanten der Sitzung nach. So kann keine
-- Zeile ohne Zugehoerigkeit entstehen, auch nicht durch kuenftigen Code.
CREATE OR REPLACE FUNCTION public.current_tenant()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT "tenantId" FROM public.users WHERE id = public.current_user_row_id()
$$;

REVOKE ALL ON FUNCTION public.current_tenant() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_tenant() TO authenticated;

CREATE OR REPLACE FUNCTION public.set_tenant_on_insert()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."tenantId" IS NULL THEN
    NEW."tenantId" := COALESCE(public.current_tenant(), 'koretini');
  END IF;
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','payments','expenses','accounting_journal','accounting_accounts',
    'fiscal_years','fiscal_budgets','board_meetings','board_members','tasks',
    'neighborhoods','events','news','polls','socialmediaposts',
    'event_registrations','inquiries','security_logs','settings'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', t || '_set_tenant', t);
    EXECUTE format(
      'CREATE TRIGGER %I BEFORE INSERT ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_tenant_on_insert()',
      t || '_set_tenant', t);
    EXECUTE format('ALTER TABLE public.%I ALTER COLUMN "tenantId" SET NOT NULL', t);
  END LOOP;
END $$;
