-- Wer hat was geaendert: Mitglieder, Rechnungen, Stammbaum.
--
-- Ein Ausloeser je Tabelle schreibt bei jeder Aenderung nur die Felder, die
-- sich wirklich geaendert haben (alt -> neu). Gelesen wird ueber
-- protokoll_lesen(), nur von Verwaltung und Vorstand; schreiben kann
-- niemand direkt -- auch nicht die Verwaltung, sonst liesse sich die Spur
-- verwischen.

CREATE TABLE IF NOT EXISTS public.aenderungsprotokoll (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "tenantId" text NOT NULL,
  tabelle    text NOT NULL,
  zeile      text NOT NULL,
  mitglieder text[] NOT NULL DEFAULT '{}',
  aktion     text NOT NULL CHECK (aktion IN ('NEU','GEAENDERT','GELOESCHT')),
  felder     jsonb NOT NULL DEFAULT '{}',
  wer        text,
  wer_id     text,
  wann       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS aenderungsprotokoll_verein ON public.aenderungsprotokoll ("tenantId", wann DESC);
CREATE INDEX IF NOT EXISTS aenderungsprotokoll_mitglieder ON public.aenderungsprotokoll USING gin (mitglieder);
ALTER TABLE public.aenderungsprotokoll ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.aenderungsprotokoll FROM anon, authenticated, public;

CREATE OR REPLACE FUNCTION public.protokoll_schreiben()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  alt jsonb := CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END;
  neu jsonb := CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END;
  zeile jsonb := coalesce(neu, alt);
  felder jsonb := '{}';
  k text;
  -- Laufend nachgefuehrte oder grosse Spalten sagen nichts ueber eine Aenderung.
  weg text[] := ARRAY['updatedAt','updated_at','geaendert_am','dataUpdateRequested','attachments','html'];
  v_wer_id text := public.current_user_row_id();
  v_mitglieder text[];
BEGIN
  IF TG_OP = 'UPDATE' THEN
    FOR k IN SELECT jsonb_object_keys(neu) LOOP
      CONTINUE WHEN k = ANY(weg);
      IF (alt->k) IS DISTINCT FROM (neu->k) THEN
        felder := felder || jsonb_build_object(k, jsonb_build_array(alt->k, neu->k));
      END IF;
    END LOOP;
    IF felder = '{}' THEN RETURN NULL; END IF;
  ELSIF TG_TABLE_NAME = 'family_links' THEN
    felder := jsonb_build_object('art', zeile->'art', 'von', zeile->'von', 'nach', zeile->'nach');
  ELSIF TG_TABLE_NAME = 'payments' THEN
    felder := jsonb_build_object('amount', zeile->'amount', 'status', zeile->'status', 'description', zeile->'description');
  ELSE
    felder := jsonb_build_object('displayName', zeile->'displayName');
  END IF;

  v_mitglieder := CASE TG_TABLE_NAME
    WHEN 'users' THEN ARRAY[zeile->>'id']
    WHEN 'payments' THEN ARRAY[zeile->>'userId']
    WHEN 'family_links' THEN ARRAY[zeile->>'von', zeile->>'nach']
    ELSE '{}' END;

  INSERT INTO public.aenderungsprotokoll ("tenantId", tabelle, zeile, mitglieder, aktion, felder, wer, wer_id)
  VALUES (coalesce(zeile->>'tenantId', ''), TG_TABLE_NAME, zeile->>'id', array_remove(v_mitglieder, NULL),
          CASE TG_OP WHEN 'INSERT' THEN 'NEU' WHEN 'UPDATE' THEN 'GEAENDERT' ELSE 'GELOESCHT' END,
          felder,
          coalesce((SELECT u."displayName" FROM public.users u WHERE u.id = v_wer_id), CASE WHEN auth.uid() IS NULL THEN 'System' END),
          v_wer_id);
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- Das Protokoll darf nie eine Aenderung verhindern.
  RAISE WARNING 'protokoll_schreiben: %', SQLERRM;
  RETURN NULL;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['users','payments','family_links'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS protokoll_trg ON public.%I', t);
    EXECUTE format('CREATE TRIGGER protokoll_trg AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.protokoll_schreiben()', t);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.protokoll_lesen(p_mitglied text DEFAULT NULL, p_tabelle text DEFAULT NULL, p_limit integer DEFAULT 100)
RETURNS TABLE (id bigint, tabelle text, zeile text, mitglieder text[], aktion text, felder jsonb, wer text, wann timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id, a.tabelle, a.zeile, a.mitglieder, a.aktion, a.felder, a.wer, a.wann
    FROM public.aenderungsprotokoll a
   WHERE public.is_member_manager()
     AND a."tenantId" = public.current_tenant()
     AND (p_mitglied IS NULL OR p_mitglied = ANY(a.mitglieder))
     AND (p_tabelle IS NULL OR a.tabelle = p_tabelle)
   ORDER BY a.wann DESC
   LIMIT least(greatest(coalesce(p_limit, 100), 1), 500);
$$;
REVOKE ALL ON FUNCTION public.protokoll_lesen(text, text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.protokoll_lesen(text, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.protokoll_schreiben() FROM public, anon, authenticated;

-- Probe: eine Aenderung erzeugt genau eine Zeile mit genau dem Feld.
DO $$
DECLARE v_id text; v_alt text; v_n int; v_f jsonb;
BEGIN
  SELECT id, city INTO v_id, v_alt FROM public.users WHERE "tenantId" = 'demo' LIMIT 1;
  UPDATE public.users SET city = coalesce(v_alt,'') || ' ' WHERE id = v_id;
  SELECT count(*), max(felder::text)::jsonb INTO v_n, v_f FROM public.aenderungsprotokoll WHERE zeile = v_id AND wann > now() - interval '1 minute';
  UPDATE public.users SET city = v_alt WHERE id = v_id;
  IF v_n < 1 OR NOT (v_f ? 'city') OR (v_f ?| ARRAY['updatedAt']) THEN
    RAISE EXCEPTION 'Protokoll schreibt nicht wie erwartet: % %', v_n, v_f;
  END IF;
  DELETE FROM public.aenderungsprotokoll WHERE zeile = v_id AND wann > now() - interval '1 minute';
END $$;

NOTIFY pgrst, 'reload schema';
