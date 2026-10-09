-- Gespraeche mit Floky: fortsetzen, neu beginnen, ablegen.
--
-- Bisher lebte ein Gespraech im Browserspeicher und war beim Neuladen
-- weg. Das ist bei einem Assistenten, der Karten vorlegt, mehr als
-- unbequem: wer eine Karte nicht sofort bestaetigt, verliert mit dem
-- Tab auch den Zusammenhang, in dem sie entstand.
--
-- Eine Entscheidung, die hier faellt: ein Gespraech gehoert DER PERSON,
-- nicht dem Verein. Auch die Vereinsadministration liest die Gespraeche
-- anderer nicht. Wer wissen will, was im Verein geschehen ist, schaut
-- ins Protokoll (floky_protokoll) -- dort steht, welche Karte wer
-- bestaetigt hat, und genau das ist die Auskunft, die ein Verein
-- braucht. Der Weg dorthin -- was jemand getippt, verworfen, noch
-- einmal anders gefragt hat -- geht niemanden sonst etwas an.

CREATE TABLE IF NOT EXISTS public.floky_gespraeche (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"   text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "userId"     text NOT NULL,
  titel        text,
  archiviert   boolean NOT NULL DEFAULT false,
  erstellt_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_am timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS floky_gespraeche_meine
  ON public.floky_gespraeche ("userId", archiviert, geaendert_am DESC);

CREATE TABLE IF NOT EXISTS public.floky_nachrichten (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gespraech_id uuid NOT NULL REFERENCES public.floky_gespraeche(id) ON DELETE CASCADE,
  rolle        text NOT NULL CHECK (rolle IN ('mensch','floky')),
  text         text NOT NULL,
  werkzeuge    text[],
  karten       jsonb,
  kuerzel      jsonb,
  erstellt_am  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS floky_nachrichten_folge
  ON public.floky_nachrichten (gespraech_id, erstellt_am);

COMMENT ON TABLE public.floky_gespraeche IS
  'Gespraeche mit dem Assistenten. Gehoeren der Person, nicht dem Verein: '
  'auch die Administration liest fremde Gespraeche nicht. Was im Verein '
  'geschehen ist, steht in floky_protokoll.';


-- ------------------------------------------------------------ Schreiben
-- Ueber Funktionen, damit "gehoert mir" an einer Stelle entschieden wird.

CREATE OR REPLACE FUNCTION public.floky_gespraech_beginnen(p_titel text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id(); v_verein text := public.current_tenant();
        v_id uuid;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.floky_darf() THEN
    RAISE EXCEPTION 'Floky ist fuer diesen Verein nicht gebucht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  INSERT INTO public.floky_gespraeche ("tenantId", "userId", titel)
  VALUES (v_verein, v_ich, nullif(btrim(coalesce(p_titel,'')), ''))
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.floky_nachricht_ablegen(
  p_gespraech uuid, p_rolle text, p_text text,
  p_werkzeuge text[] DEFAULT NULL, p_karten jsonb DEFAULT NULL, p_kuerzel jsonb DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id(); v_id uuid; v_titel text;
BEGIN
  -- Nur in eigene Gespraeche. Ohne diese Pruefung koennte jemand mit
  -- einer fremden Kennung in ein fremdes Gespraech schreiben.
  IF NOT EXISTS (SELECT 1 FROM public.floky_gespraeche g
                  WHERE g.id = p_gespraech AND g."userId" = v_ich
                    AND g."tenantId" = public.current_tenant()) THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  INSERT INTO public.floky_nachrichten (gespraech_id, rolle, text, werkzeuge, karten, kuerzel)
  VALUES (p_gespraech, p_rolle, p_text, p_werkzeuge, p_karten, p_kuerzel)
  RETURNING id INTO v_id;

  -- Der Titel ist die erste Frage, gekuerzt. Eine Liste aus
  -- "Gespraech vom 9.10., 08:33" sagt nichts; die erste Frage schon.
  SELECT titel INTO v_titel FROM public.floky_gespraeche WHERE id = p_gespraech;
  UPDATE public.floky_gespraeche
     SET geaendert_am = now(),
         titel = CASE WHEN v_titel IS NULL AND p_rolle = 'mensch'
                      THEN left(btrim(p_text), 70) ELSE titel END
   WHERE id = p_gespraech;

  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.floky_gespraech_ablegen(p_id uuid, p_archiv boolean DEFAULT true)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  UPDATE public.floky_gespraeche
     SET archiviert = coalesce(p_archiv, true), geaendert_am = now()
   WHERE id = p_id AND "userId" = public.current_user_row_id()
     AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN coalesce(p_archiv, true);
END $$;

CREATE OR REPLACE FUNCTION public.floky_gespraech_loeschen(p_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  DELETE FROM public.floky_gespraeche
   WHERE id = p_id AND "userId" = public.current_user_row_id()
     AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Dieses Gespraech gehoert Ihnen nicht.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Die Nachrichten gehen per ON DELETE CASCADE mit. Das Protokoll
  -- bleibt: was im Verein geschehen ist, loescht niemand mit seinem
  -- Gespraechsverlauf.
  RETURN true;
END $$;

DO $$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'floky_gespraech_beginnen(text)',
    'floky_nachricht_ablegen(uuid, text, text, text[], jsonb, jsonb)',
    'floky_gespraech_ablegen(uuid, boolean)',
    'floky_gespraech_loeschen(uuid)'] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION public.%s FROM public, anon', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%s TO authenticated', f);
  END LOOP;
END $$;


-- ------------------------------------------------------------- Lesen
ALTER TABLE public.floky_gespraeche  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.floky_nachrichten ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS floky_gespraeche_meine ON public.floky_gespraeche;
CREATE POLICY floky_gespraeche_meine ON public.floky_gespraeche FOR SELECT TO authenticated
  USING ("userId" = public.current_user_row_id() AND "tenantId" = public.current_tenant());

DROP POLICY IF EXISTS floky_nachrichten_meine ON public.floky_nachrichten;
CREATE POLICY floky_nachrichten_meine ON public.floky_nachrichten FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.floky_gespraeche g
                  WHERE g.id = gespraech_id
                    AND g."userId" = public.current_user_row_id()
                    AND g."tenantId" = public.current_tenant()));

REVOKE ALL ON public.floky_gespraeche, public.floky_nachrichten FROM anon, public;
GRANT SELECT ON public.floky_gespraeche, public.floky_nachrichten TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int;
BEGIN
  -- Keine Schreibregel: alles laeuft ueber die Funktionen, sonst koennte
  -- jemand mit einer fremden gespraech_id in ein fremdes Gespraech
  -- schreiben.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname='public' AND tablename IN ('floky_gespraeche','floky_nachrichten')
     AND cmd <> 'SELECT';
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Schreibregel(n) auf den Gespraechstabellen.', v_n;
  END IF;

  -- Die Leseregel muss an der PERSON haengen, nicht am Verein allein.
  -- Haengt sie nur am Verein, liest die Administration fremde Gespraeche.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname='public' AND tablename='floky_gespraeche' AND cmd='SELECT'
     AND qual LIKE '%current_user_row_id%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'Die Leseregel prueft nicht die Person -- fremde Gespraeche waeren lesbar.';
  END IF;

  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon'
     AND table_name IN ('floky_gespraeche','floky_nachrichten');
  IF v_n > 0 THEN RAISE EXCEPTION 'anon hat Rechte auf den Gespraechstabellen.'; END IF;

  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname LIKE 'floky_gespraech%'
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_n > 0 THEN RAISE EXCEPTION '% Funktion(en) sind fuer anon ausfuehrbar.', v_n; END IF;

  RAISE NOTICE 'Gespraeche bereit: eigene lesbar, Schreiben nur ueber Funktionen.';
END $$;
