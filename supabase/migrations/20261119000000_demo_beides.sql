-- Demo: zwei Mitglieder wollen ihre Rechnung per E-Mail UND per Post,
-- damit der Rechnungsassistent alle drei Zustellwege zeigt.
DO $$
DECLARE v_betreiber text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;
  UPDATE public.users SET "invoiceDeliveryMethod" = 'BOTH'
   WHERE "tenantId" = 'demo' AND id IN ('demo-u06', 'demo-u07');
  SELECT email INTO v_betreiber FROM public.platform_admins LIMIT 1;
  PERFORM set_config('request.jwt.claims', json_build_object('email', v_betreiber, 'role', 'authenticated')::text, true);
  PERFORM public.demo_vorlage_speichern();
  PERFORM set_config('request.jwt.claims', '', true);
END $$;
