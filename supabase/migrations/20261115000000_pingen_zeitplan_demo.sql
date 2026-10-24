-- Briefversand (Pingen): Zeitplan und Demo.
--
-- Bisher lagen eingereihte Briefe fuer immer in WARTEND: der Arbeiter
-- pingen-versand verlangt ein Zeitplan-Kennwort, es gab aber keinen
-- Zeitplan, der ihn aufruft -- und der Knopf in der Verwaltung schickt
-- keines mit und wurde abgewiesen. Jetzt:
--   * Zeitplan alle 10 Minuten, nur wenn etwas wartet, mit demselben
--     Kennwort wie der Mailversand (mail_settings.zeitplan_token).
--   * pingen-versand nimmt zusaetzlich eine angemeldete Verwaltung an
--     (Aenderung in der Funktion selbst).

SELECT cron.unschedule('postausgang_pingen')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'postausgang_pingen');
SELECT cron.schedule('postausgang_pingen', '*/10 * * * *', $cron$
  SELECT net.http_post(
    url     := 'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/pingen-versand',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-cron-token', coalesce(
                   (SELECT zeitplan_token FROM public.mail_settings
                     WHERE zeitplan_token IS NOT NULL LIMIT 1), '')),
    body    := '{"menge": 20}'::jsonb
  ) WHERE EXISTS (SELECT 1 FROM public.post_ausgang
                   WHERE zustand = 'WARTEND' AND naechster_versuch <= now());
$cron$);

-- Demo: fuenf Mitglieder wollen ihre Rechnung per Post, ihre offenen
-- Rechnungen gehen per Post, und der Verein hat ein Guthaben von 50
-- Briefen. Danach wird die Demo-Vorlage neu gespeichert, damit
-- "Demo zuruecksetzen" genau diesen Stand wiederherstellt.
DO $$
DECLARE v_mitglieder text[] := ARRAY['demo-u03','demo-u09','demo-u12','demo-u20','demo-u24'];
        v_betreiber text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;

  UPDATE public.users SET "invoiceDeliveryMethod" = 'POST'
   WHERE "tenantId" = 'demo' AND id = ANY (v_mitglieder);
  UPDATE public.payments SET "deliveryMethod" = 'POST'
   WHERE "tenantId" = 'demo' AND "userId" = ANY (v_mitglieder) AND status <> 'PAID';

  IF NOT EXISTS (SELECT 1 FROM public.post_kontingent WHERE "tenantId" = 'demo') THEN
    INSERT INTO public.post_kontingent ("tenantId", art, menge, grund, erstellt_von)
    VALUES ('demo', 'GUTSCHRIFT', 50, 'Demo-Guthaben für die Vorführung', 'migration');
  END IF;

  -- Vorlage speichern -- die Funktion verlangt den Betreiber.
  SELECT email INTO v_betreiber FROM public.platform_admins LIMIT 1;
  PERFORM set_config('request.jwt.claims', json_build_object('email', v_betreiber, 'role', 'authenticated')::text, true);
  PERFORM public.demo_vorlage_speichern();
  PERFORM set_config('request.jwt.claims', '', true);
END $$;
