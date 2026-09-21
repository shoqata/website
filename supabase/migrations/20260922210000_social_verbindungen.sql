-- Grundlage fuer das echte Veroeffentlichen auf Facebook und Instagram.
--
-- Der Zugriffstoken einer Facebook-Seite erlaubt, im Namen des Vereins zu
-- posten. Er darf deshalb nie im Browser landen und nie in einer Sicht
-- stehen, die der Client lesen kann -- genau das war im September der Fall,
-- als public_settings die Spalte data vollstaendig herausgab.
--
-- Daher: die Tabelle traegt Zeilenschutz OHNE Regel fuer authenticated. Kein
-- angemeldeter Client kommt heran, auch kein Administrator. Lesbar ist sie
-- nur fuer service_role, also fuer die Funktion, die tatsaechlich sendet.
-- Was die Oberflaeche braucht -- welche Seite verbunden ist, seit wann, wie
-- lange noch -- liefert social_verbindungen() ohne den Token.

CREATE TABLE IF NOT EXISTS public.social_connections (
  id              text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "tenantId"      text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  plattform       text NOT NULL CHECK (plattform IN ('FACEBOOK','INSTAGRAM')),
  konto_id        text,
  konto_name      text,
  zugriffstoken   text,
  token_laeuft_ab timestamptz,
  zustand         text NOT NULL DEFAULT 'OFFEN'
                  CHECK (zustand IN ('OFFEN','WAEHLEN','AKTIV','ABGELAUFEN','FEHLER')),
  kandidaten      jsonb,          -- Seiten zur Auswahl, wenn es mehrere gibt
  letzter_fehler  text,
  verbunden_am    timestamptz,
  verbunden_von   text,
  "createdAt"     timestamptz NOT NULL DEFAULT now(),
  UNIQUE ("tenantId", plattform)
);

ALTER TABLE public.social_connections ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.social_connections FROM anon, authenticated;

-- Was die Oberflaeche sehen darf. Ohne Token, ohne Kandidaten-Token.
CREATE OR REPLACE FUNCTION public.social_verbindungen()
RETURNS TABLE (plattform text, konto_name text, zustand text,
               token_laeuft_ab timestamptz, verbunden_am timestamptz,
               letzter_fehler text, kandidaten jsonb)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT c.plattform, c.konto_name, c.zustand, c.token_laeuft_ab,
         c.verbunden_am, c.letzter_fehler,
         -- Aus den Kandidaten nur Nummer und Name, nie deren Token.
         (SELECT jsonb_agg(jsonb_build_object('id', k->>'id', 'name', k->>'name'))
            FROM jsonb_array_elements(coalesce(c.kandidaten,'[]'::jsonb)) AS k)
    FROM public.social_connections c
   WHERE c."tenantId" = public.current_tenant()
     AND public.is_staff();
$$;
REVOKE ALL ON FUNCTION public.social_verbindungen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.social_verbindungen() TO authenticated;

-- Trennen. Der Token wird geloescht, nicht nur der Zustand geaendert --
-- ein Token, der "getrennt" in der Tabelle liegen bleibt, ist immer noch
-- ein gueltiger Token.
CREATE OR REPLACE FUNCTION public.social_trennen(p_plattform text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf die Verbindung trennen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  DELETE FROM public.social_connections
   WHERE "tenantId" = public.current_tenant()
     AND (p_plattform IS NULL OR plattform = p_plattform);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n || ' Verbindung(en) getrennt';
END $$;
REVOKE ALL ON FUNCTION public.social_trennen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.social_trennen(text) TO authenticated;


-- --- Die Beitraege selbst ------------------------------------------------
ALTER TABLE public.socialmediaposts
  ADD COLUMN IF NOT EXISTS "publishedAt"  timestamptz,
  ADD COLUMN IF NOT EXISTS "externalIds"  jsonb,
  ADD COLUMN IF NOT EXISTS "lastError"    text,
  ADD COLUMN IF NOT EXISTS attempts       int NOT NULL DEFAULT 0,
  -- Die Oberflaeche schrieb dieses Feld seit jeher, die Spalte fehlte.
  ADD COLUMN IF NOT EXISTS "autoPosted"   boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.socialmediaposts.status IS
  'DRAFT, SCHEDULED, QUEUED, PUBLISHING, PUBLISHED, FAILED';

DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE 'social_connections angelegt. Regeln darauf:';
  FOR r IN SELECT policyname FROM pg_policies
            WHERE schemaname='public' AND tablename='social_connections' LOOP
    RAISE NOTICE '  %', r.policyname;
  END LOOP;
  RAISE NOTICE '(keine Regel = kein Zugriff fuer angemeldete Clients -- so gewollt)';
END $$;
