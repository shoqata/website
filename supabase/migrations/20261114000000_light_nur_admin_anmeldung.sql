-- Paket Light im Demoverein: nur die Administration meldet sich an.
--
-- Gesperrt wird dort, wo die Anmeldung entschieden wird: im Anmeldesystem
-- (auth.users.banned_until). Eine Sperre nur in der Oberflaeche liesse
-- jeden Zugang ueber die Schnittstelle weiter herein. Offene Sitzungen der
-- gesperrten Zugaenge werden beendet.
--
-- Betroffen sind nur Zugaenge des Vereins 'demo' ausser der Rolle ADMIN --
-- nie ein Betreiberkonto. Bei Voll werden sie wieder freigegeben.

CREATE OR REPLACE FUNCTION public._demo_paket_anwenden(p_paket text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_paket = 'LIGHT' THEN
    UPDATE public.tenants SET alle_module_frei = false WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AUS' FROM public.modules m WHERE NOT m.ist_kern
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AUS', testet_bis = NULL;
  ELSIF p_paket = 'VOLL' THEN
    UPDATE public.tenants SET alle_module_frei = true WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AN' FROM public.modules m
     WHERE NOT m.ist_kern AND m.status <> 'EINGESTELLT'
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AN', testet_bis = NULL;
  ELSE
    RAISE EXCEPTION 'Unbekanntes Paket: %', p_paket;
  END IF;

  -- Zugaenge. Ein fernes Datum statt 'infinity': das Anmeldesystem liest
  -- den Wert als Zeitpunkt, und 'infinity' kann es nicht in einen solchen
  -- umwandeln -- die Anmeldung scheiterte dann mit einem Serverfehler
  -- statt mit "gesperrt".
  UPDATE auth.users a
     SET banned_until = CASE WHEN p_paket = 'LIGHT' AND u.role <> 'ADMIN'
                             THEN timestamptz '2999-12-31' ELSE NULL END
    FROM public.users u
   WHERE u."authUserId" = a.id::text AND u."tenantId" = 'demo'
     AND NOT EXISTS (SELECT 1 FROM public.platform_admins p WHERE lower(p.email) = lower(a.email));

  IF p_paket = 'LIGHT' THEN
    DELETE FROM auth.refresh_tokens r USING public.users u
     WHERE u."tenantId" = 'demo' AND u.role <> 'ADMIN' AND u."authUserId" = r.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId");
    DELETE FROM auth.sessions s USING public.users u
     WHERE u."tenantId" = 'demo' AND u.role <> 'ADMIN' AND u."authUserId" = s.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId");
  END IF;
END $$;
REVOKE ALL ON FUNCTION public._demo_paket_anwenden(text) FROM public, anon, authenticated;

-- Fuer die Anmeldeseite und den Rollenschalter: welches Paket hat der
-- Verein DIESER Adresse? Gibt nur LIGHT oder VOLL heraus, sonst nichts.
CREATE OR REPLACE FUNCTION public.paket_oeffentlich()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE WHEN coalesce(public.current_tenant(), public.request_tenant()) = 'demo'
               AND (SELECT paket FROM public.demo_stand WHERE id = 1) = 'LIGHT'
              THEN 'LIGHT' ELSE 'VOLL' END;
$$;
REVOKE ALL ON FUNCTION public.paket_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.paket_oeffentlich() TO anon, authenticated;

-- Steht die Demo schon auf Light, gilt die Sperre sofort.
SELECT public._demo_paket_anwenden(paket) FROM public.demo_stand WHERE id = 1;

-- Selbsttest, zurueckgerollt.
DO $$
DECLARE n_gesperrt int; n_admin int; n_frei int; n_kor int;
BEGIN
  SELECT count(*) INTO n_kor FROM auth.users a JOIN public.users u ON u."authUserId" = a.id::text
   WHERE u."tenantId" <> 'demo' AND a.banned_until IS NOT NULL;
  BEGIN
    PERFORM public._demo_paket_anwenden('LIGHT');
    SELECT count(*) FILTER (WHERE a.banned_until IS NOT NULL AND u.role <> 'ADMIN'),
           count(*) FILTER (WHERE a.banned_until IS NOT NULL AND u.role = 'ADMIN')
      INTO n_gesperrt, n_admin
      FROM auth.users a JOIN public.users u ON u."authUserId" = a.id::text WHERE u."tenantId" = 'demo';
    PERFORM public._demo_paket_anwenden('VOLL');
    SELECT count(*) INTO n_frei FROM auth.users a JOIN public.users u ON u."authUserId" = a.id::text
     WHERE u."tenantId" = 'demo' AND a.banned_until IS NOT NULL;
    IF n_gesperrt < 1 OR n_admin <> 0 OR n_frei <> 0 OR
       n_kor <> (SELECT count(*) FROM auth.users a JOIN public.users u ON u."authUserId" = a.id::text
                  WHERE u."tenantId" <> 'demo' AND a.banned_until IS NOT NULL) THEN
      RAISE EXCEPTION 'Selbsttest: gesperrt % / Admin gesperrt % / nach Voll gesperrt %', n_gesperrt, n_admin, n_frei;
    END IF;
    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
END $$;
