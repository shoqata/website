DO $$ DECLARE v_back text := current_user; v_s boolean; v_st text; BEGIN
  SELECT coalesce(system ->> 'spendenseite','IMMER (Vorgabe)') INTO v_st
    FROM public.settings WHERE "tenantId"='koretini' AND id='system';
  PERFORM set_config('request.headers', json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon'; SELECT public.spendenseite_sichtbar() INTO v_s;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE 'Koretini: Stellung % -> Seite sichtbar: %', v_st, v_s;
END $$;
