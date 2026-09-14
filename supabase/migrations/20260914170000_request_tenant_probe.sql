-- Erkennung des Vereins aus der Anfrage selbst -- zunaechst nur zum Pruefen.
--
-- Ein nicht angemeldeter Besucher hat keinen Verein in der Sitzung. Das einzige
-- Signal ist die Adresse, von der die Anfrage kommt: PostgREST reicht die
-- Kopfzeilen als request.headers durch, darin steht bei jedem Browseraufruf der
-- Origin. Er wird auf tenant_domains abgebildet.
--
-- Bewusst noch nicht in den Regeln verdrahtet: greift die Erkennung nicht wie
-- erwartet, waere die oeffentliche Seite schlagartig leer. Erst messen.
CREATE OR REPLACE FUNCTION public.request_tenant()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT d."tenantId"
    FROM public.tenant_domains d
   WHERE d.domain = regexp_replace(
           coalesce(
             current_setting('request.headers', true)::json ->> 'origin',
             current_setting('request.headers', true)::json ->> 'referer',
             ''),
           '^https?://([^/:]+).*$', '\1')
   LIMIT 1
$$;

-- Diagnosefunktion: zeigt, was serverseitig ueberhaupt ankommt.
CREATE OR REPLACE FUNCTION public.request_tenant_probe()
RETURNS json
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT json_build_object(
    'origin',      current_setting('request.headers', true)::json ->> 'origin',
    'referer',     current_setting('request.headers', true)::json ->> 'referer',
    'host',        current_setting('request.headers', true)::json ->> 'host',
    'erkannt',     public.request_tenant(),
    'sitzung',     public.current_tenant()
  )
$$;

GRANT EXECUTE ON FUNCTION public.request_tenant() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.request_tenant_probe() TO anon, authenticated;
