-- Das Zuruecksetzen des Demovereins (ohne angemeldete Person) schreibt
-- hunderte Zeilen neu -- das ist keine Aenderung, die jemand nachlesen will.
CREATE OR REPLACE FUNCTION public.protokoll_schreiben()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  alt jsonb := CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END;
  neu jsonb := CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END;
  zeile jsonb := coalesce(neu, alt);
  felder jsonb := '{}';
  k text;
  weg text[] := ARRAY['updatedAt','updated_at','geaendert_am','dataUpdateRequested','attachments','html'];
  v_wer_id text;
  v_mitglieder text[];
BEGIN
  IF auth.uid() IS NULL AND zeile->>'tenantId' = 'demo' THEN RETURN NULL; END IF;
  v_wer_id := public.current_user_row_id();
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
  RAISE WARNING 'protokoll_schreiben: %', SQLERRM;
  RETURN NULL;
END $$;
REVOKE ALL ON FUNCTION public.protokoll_schreiben() FROM public, anon, authenticated;
