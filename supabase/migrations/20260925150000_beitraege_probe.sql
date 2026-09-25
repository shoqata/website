-- Selbsttest aus der Sicht eines fremden Besuchers: Rolle anon, kein
-- Anmeldetoken, nur der Origin-Kopf der Vereinsdomain -- genau das, was ein
-- Browser mitschickt.
DO $$
DECLARE
  v_back text := current_user;
  v_alt  text;
  v_erg  jsonb;
  v_probant text;
  v_n int;
BEGIN
  SELECT s.system ->> 'beitraegeOeffentlich' INTO v_alt
    FROM public.settings s WHERE s."tenantId"='koretini' AND s.id='system';

  -- Ein Mitglied, das bezahlt hat, widerspricht.
  SELECT u.id INTO v_probant FROM public.users u
    JOIN public.payments p ON p."userId"=u.id
   WHERE u."tenantId"='koretini' AND p.status='PAID' AND p."billingYear"=2026
     AND coalesce(u.nicht_oeffentlich,false)=false
   ORDER BY u."displayName" LIMIT 1;
  UPDATE public.users SET nicht_oeffentlich = true WHERE id = v_probant;
  RAISE NOTICE 'Widerspruch gesetzt fuer: %',
    (SELECT "displayName" FROM public.users WHERE id=v_probant);

  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);

  FOR v_n IN 1..3 LOOP
    UPDATE public.settings
       SET system = jsonb_set(coalesce(system,'{}'::jsonb), '{beitraegeOeffentlich}',
                              to_jsonb((ARRAY['AUS','ZAHL','NAMEN'])[v_n]))
     WHERE "tenantId"='koretini' AND id='system';

    EXECUTE 'SET ROLE anon';
    v_erg := public.beitragsstand_oeffentlich(2026);
    EXECUTE format('SET ROLE %I', v_back);

    RAISE NOTICE '  Stellung % -> Antwort: % | Namen: %',
      rpad((ARRAY['AUS','ZAHL','NAMEN'])[v_n], 6),
      rpad(coalesce(v_erg->>'stellung','?')||' anzahl='||coalesce(v_erg->>'anzahl','-')
           ||' gesamt='||coalesce(v_erg->>'gesamt','-'), 34),
      coalesce(jsonb_array_length(v_erg->'namen')::text,'keine');
  END LOOP;

  -- Steht der Widersprechende trotzdem in der Namensliste?
  EXECUTE 'SET ROLE anon';
  v_erg := public.beitragsstand_oeffentlich(2026);
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '  Widersprechender in der Namensliste: %',
    CASE WHEN v_erg::text ILIKE '%'||
      (SELECT "displayName" FROM public.users WHERE id=v_probant)||'%'
      THEN 'JA -- LOCH' ELSE 'nein' END;

  -- Und faellt er aus dem Mitgliederlauf heraus?
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.public_members WHERE id = v_probant;
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '  Widersprechender in public_members: % (erwartet 0)', v_n;

  -- Zurueck auf den gewuenschten Stand: Koretini zeigt nur die Zahl.
  UPDATE public.users SET nicht_oeffentlich = false WHERE id = v_probant;
  UPDATE public.settings
     SET system = jsonb_set(coalesce(system,'{}'::jsonb), '{beitraegeOeffentlich}', '"ZAHL"')
   WHERE "tenantId"='koretini' AND id='system';
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '  Probe zurueckgenommen; Koretini steht auf ZAHL (vorher: %)', coalesce(v_alt,'nicht gesetzt');
END $$;
