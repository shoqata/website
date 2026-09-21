-- modul_aktiv() muss den Verein genauso aufloesen wie die oeffentlichen
-- Lese-Regeln, sonst faellt fuer anonyme Besucher alles weg: dort ist
-- current_tenant() leer und erst request_tenant() liefert die Domain.
CREATE OR REPLACE FUNCTION public.modul_aktiv(p_modul text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH v AS (SELECT COALESCE(public.current_tenant(), public.request_tenant()) AS verein)
  SELECT COALESCE(
    (SELECT true FROM public.tenants t, v WHERE t.id = v.verein AND t.alle_module_frei),
    (SELECT true FROM public.modules m WHERE m.schluessel = p_modul AND m.ist_kern),
    (SELECT tm.zustand IN ('AN','TESTPHASE')
       AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date)
       FROM public.tenant_modules tm, v
      WHERE tm."tenantId" = v.verein AND tm.modul = p_modul),
    false);
$$;

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '--- INSERT-Regeln, die ich noch nicht kenne ---';
  FOR r IN SELECT tablename, policyname, coalesce(with_check::text,'-') AS wc
             FROM pg_policies
            WHERE schemaname='public' AND cmd='INSERT'
              AND tablename IN ('event_registrations','sponsors','news','events',
                                'socialmediaposts','family_links','families')
            ORDER BY 1,2 LOOP
    RAISE NOTICE '  %.%: %', r.tablename, r.policyname, left(r.wc, 130);
  END LOOP;
END $$;
