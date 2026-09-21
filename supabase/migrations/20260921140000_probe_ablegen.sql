-- Probe-Zugangsdaten ablegen, um von aussen zu pruefen, ob sie oeffentlich
-- lesbar sind. Erfundene Werte -- kein echtes Token.
INSERT INTO public.settings (id, "tenantId", data)
VALUES ('social', 'koretini',
        '{"fbAccessToken":"PROBE-FB-GEHEIM-12345","igAccessToken":"PROBE-IG-GEHEIM-67890","autoPostingEnabled":true}'::jsonb)
ON CONFLICT (id) DO UPDATE SET data = excluded.data, "tenantId" = excluded."tenantId";
