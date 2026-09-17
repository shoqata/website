-- Waehrend der Betreuung blieb eine Koretini-Zahlung sichtbar. Ist das die
-- eigene des Betreibers -- dann richtig -- oder eine fremde?
DO $$
DECLARE
  v_back text := current_user;
  v_owner uuid; v_mail text; v_row text; v_new text;
  v_eigene int; v_fremde int;
BEGIN
  SELECT u."authUserId", u.email, u.id INTO v_owner, v_mail, v_row
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email)=lower(u.email)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;
  IF v_owner IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR'; RETURN; END IF;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_owner::text,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  v_new := public.create_tenant('Sichtpruefung', 'sichtpruefung', 'sichtpruefung.example', NULL);
  PERFORM public.start_tenant_support(v_new, 'Sichtpruefung');

  SELECT count(*) FILTER (WHERE p."userId" = v_row),
         count(*) FILTER (WHERE p."userId" IS DISTINCT FROM v_row)
    INTO v_eigene, v_fremde
    FROM public.payments p WHERE p."tenantId" = 'koretini';

  RAISE NOTICE 'Waehrend der Betreuung sichtbare Koretini-Zahlungen: eigene=%, FREMDE=% (erwartet 0)',
    v_eigene, v_fremde;

  PERFORM public.end_tenant_support();
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.platform_support WHERE "tenantId" = v_new;
  DELETE FROM public.tenant_domains  WHERE "tenantId" = v_new;
  DELETE FROM public.tenants         WHERE id = v_new;
END $$;
