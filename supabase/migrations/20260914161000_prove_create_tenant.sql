-- Nachweis fuer create_tenant(). Legt einen Wegwerf-Verein an, prueft, dass
-- Verein, Domain und Administrator zusammen entstehen, dass ein
-- Vereinsadministrator die Funktion nicht aufrufen darf, und raeumt ab.
-- Dreigeteilt, damit der Rollenwechsel in eigener Transaktion bleibt.

DO $setup$
BEGIN
  DELETE FROM public.users          WHERE "tenantId" LIKE '__ct%';
  DELETE FROM public.tenant_domains WHERE "tenantId" LIKE '__ct%';
  DELETE FROM public.tenants        WHERE id LIKE '__ct%';
  DELETE FROM public.users          WHERE email = 'chef@testverein.example';
END
$setup$;

DO $mess$
DECLARE urspruenglich text := current_user; v_id text; v int;
BEGIN
  SET LOCAL ROLE authenticated;

  -- 1. Als Betreiber: muss durchgehen
  PERFORM set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000cc","email":"email@dervishi.ch"}', true);
  v_id := public.create_tenant('Testverein Futsal', '__ct_futsal', 'futsal.example', 'chef@testverein.example');
  PERFORM set_config('ct.id', v_id, false);

  -- 2. Als gewoehnlicher Vereinsadministrator: muss scheitern
  PERFORM set_config('ct.fremd_blockt', '0', false);
  PERFORM set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000dd","email":"niemand@example.com"}', true);
  BEGIN
    PERFORM public.create_tenant('Schwarzbau', '__ct_pirat', 'pirat.example', 'pirat@example.com');
  EXCEPTION WHEN insufficient_privilege THEN
    PERFORM set_config('ct.fremd_blockt', '1', false);
  END;

  EXECUTE format('SET LOCAL ROLE %I', urspruenglich);
END
$mess$;

DO $pruef$
DECLARE v_id text := current_setting('ct.id', true); n_dom int; n_adm int; fremd int; ok boolean := true;
BEGIN
  SELECT count(*) INTO n_dom FROM public.tenant_domains WHERE "tenantId" = v_id AND domain = 'futsal.example';
  SELECT count(*) INTO n_adm FROM public.users WHERE "tenantId" = v_id AND role = 'ADMIN' AND email = 'chef@testverein.example';
  fremd := COALESCE(current_setting('ct.fremd_blockt', true), '0')::int;

  RAISE NOTICE '  Verein angelegt        : %', COALESCE(v_id, '(keiner)');
  RAISE NOTICE '  Domain zugeordnet      : % (soll 1)', n_dom;
  RAISE NOTICE '  Administrator angelegt : % (soll 1)', n_adm;
  RAISE NOTICE '  Fremdaufruf abgewiesen : % (soll 1)', fremd;

  IF v_id IS NULL OR n_dom <> 1 OR n_adm <> 1 OR fremd <> 1 THEN ok := false; END IF;

  DELETE FROM public.users          WHERE "tenantId" = v_id;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_id;
  DELETE FROM public.tenants        WHERE id = v_id;
  DELETE FROM public.tenants        WHERE id LIKE '__ct%';
  PERFORM set_config('request.jwt.claims', '', false);

  IF ok THEN
    RAISE NOTICE 'VEREINSANLAGE: Verein, Domain und Administrator entstehen zusammen; Unbefugte abgewiesen -- wirkt.';
  ELSE
    RAISE EXCEPTION 'VEREINSANLAGE FEHLERHAFT -- siehe Zahlen oben.';
  END IF;
END
$pruef$;
