-- Waere ein Facebook-Token in settings/social oeffentlich lesbar?
-- Geprueft wird so, wie ein Browser es tut: mit gesetzter Vereinskennung.
DO $$
DECLARE v_back text := current_user; v_n int; v_gefunden text;
BEGIN
  -- Probeeintrag wie ihn die Maske anlegen wuerde.
  INSERT INTO public.settings (id, "tenantId", data)
  VALUES ('social', 'koretini',
          '{"fbAccessToken":"PROBE-FB-GEHEIM-12345","igAccessToken":"PROBE-IG-GEHEIM-67890","autoPostingEnabled":true}'::jsonb)
  ON CONFLICT (id) DO UPDATE SET data = excluded.data, "tenantId" = excluded."tenantId";
  RAISE NOTICE 'Probe-Zugangsdaten in settings/social abgelegt.';

  SET LOCAL ROLE anon;
  -- Genau das schickt der Browser mit, damit die Domain zugeordnet wird.
  PERFORM set_config('request.headers',
    json_build_object('x-tenant-id','koretini')::text, true);
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_settings WHERE id = 'social';
    RAISE NOTICE 'anon sieht settings/social: % Zeilen', v_n;
    SELECT data ->> 'fbAccessToken' INTO v_gefunden
      FROM public.public_settings WHERE id = 'social';
    IF v_gefunden IS NOT NULL THEN
      RAISE NOTICE '>>> anon LIEST DAS TOKEN: % <<<', v_gefunden;
    ELSE
      RAISE NOTICE 'anon liest kein Token (richtig)';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'anon: abgewiesen (%)', left(SQLERRM, 50);
  END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, true);

  DELETE FROM public.settings WHERE id = 'social';
  RAISE NOTICE 'Probe entfernt.';
END $$;
