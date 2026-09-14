-- Oeffentliche Inhalte serverseitig auf den Verein der aufrufenden Adresse
-- begrenzen.
--
-- Bisher entschied der Client, nach welchem Verein er fragt. Wer statt der
-- Website direkt die Schnittstelle ansprach, konnte nach einem beliebigen
-- Verein fragen. Jetzt entscheidet die Anfrage selbst: fuer Angemeldete der
-- Verein der Sitzung, sonst der Verein der aufrufenden Adresse.
--
-- Gemessen, bevor es scharf geschaltet wurde: Origin www.koretini.me ergibt
-- 'koretini', eine fremde Adresse und eine Anfrage ohne Origin ergeben nichts.
-- Letzteres ist gewollt -- ein Aufruf ohne erkennbare Herkunft bekommt nichts.

-- Die Aufloesung selbst bleibt offen, sonst koennte sich keine Seite finden.
-- Sie gibt nur Adresse, Kennung und Erscheinungsbild preis.

-- ------------------------------------------------- oeffentliche Projektionen
DROP VIEW IF EXISTS public.public_members;
CREATE VIEW public.public_members AS
  SELECT id, "tenantId", "displayName", "photoFileName", city, country,
         "membershipStatus", "livesInKoretin"
    FROM public.users
   WHERE "membershipStatus" IS DISTINCT FROM 'INACTIVE'
     AND "tenantId" = COALESCE(public.current_tenant(), public.request_tenant());
GRANT SELECT ON public.public_members TO anon, authenticated;

DROP VIEW IF EXISTS public.public_settings;
CREATE VIEW public.public_settings AS
  SELECT id, "tenantId",
         (payment - 'paypalSecret' - 'paypalClientId') AS payment,
         company, branding, system, data
    FROM public.settings
   WHERE "tenantId" = COALESCE(public.current_tenant(), public.request_tenant());
GRANT SELECT ON public.public_settings TO anon, authenticated;

-- ------------------------------------------------------ oeffentliche Inhalte
DO $$
DECLARE t text; p text;
BEGIN
  FOREACH t IN ARRAY ARRAY['events','news','board_members','neighborhoods','polls'] LOOP
    p := t || '_public_read';
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p, t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO anon, authenticated
         USING ("tenantId" = COALESCE(public.current_tenant(), public.request_tenant()))',
      p, t);
  END LOOP;
END $$;

-- Die Diagnosefunktion bleibt, aber nicht fuer anonyme Aufrufer.
REVOKE EXECUTE ON FUNCTION public.request_tenant_probe() FROM anon;
