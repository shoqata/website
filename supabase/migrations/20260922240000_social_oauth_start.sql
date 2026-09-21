-- Wer das Verbinden startet, muss angemeldet sein.
--
-- Laege der Start allein in der Funktion, koennte jemand sie mit einer
-- fremden Vereinskennung aufrufen und seine eigene Facebook-Seite an einen
-- fremden Verein haengen -- die Funktion sieht keinen angemeldeten Benutzer.
-- Deshalb entsteht der Startlink hier, wo bekannt ist, wer fragt, und die
-- einmalige Kennung bindet den spaeteren Rueckruf an genau diesen Verein.
--
-- Die App-Nummer (client_id) steht offen im Link und ist kein Geheimnis. Das
-- App-Geheimnis kommt nie in die Datenbank und nie in den Browser -- es lebt
-- allein in der Umgebung der Funktion.

CREATE TABLE IF NOT EXISTS public.social_oauth_state (
  nonce       text PRIMARY KEY,
  "tenantId"  text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  benutzer    text,
  zurueck     text,
  laeuft_ab   timestamptz NOT NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.social_oauth_state ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.social_oauth_state FROM anon, authenticated;

INSERT INTO public.platform_secrets (schluessel, wert, notiz)
SELECT 'meta_app_id', '', 'Nummer der Meta-App (client_id). Kein Geheimnis, steht offen im Anmeldelink.'
 WHERE NOT EXISTS (SELECT 1 FROM public.platform_secrets WHERE schluessel='meta_app_id');

INSERT INTO public.platform_secrets (schluessel, wert, notiz)
SELECT 'meta_redirect_uri',
       'https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/meta-oauth',
       'Muss in der Meta-App als gueltige OAuth-Redirect-URI eingetragen sein.'
 WHERE NOT EXISTS (SELECT 1 FROM public.platform_secrets WHERE schluessel='meta_redirect_uri');


CREATE OR REPLACE FUNCTION public.social_verbinden_starten(p_zurueck text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_app    text;
  v_ziel   text;
  v_nonce  text;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf Kanaele verbinden.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.' USING ERRCODE='check_violation';
  END IF;

  SELECT wert INTO v_app  FROM public.platform_secrets WHERE schluessel='meta_app_id';
  SELECT wert INTO v_ziel FROM public.platform_secrets WHERE schluessel='meta_redirect_uri';
  IF coalesce(btrim(v_app),'') = '' THEN
    RAISE EXCEPTION 'Die Meta-App ist noch nicht hinterlegt. Der Betreiber muss sie zuerst eintragen.'
      USING ERRCODE='check_violation';
  END IF;

  -- Alte Kennungen aufraeumen, damit die Tabelle nicht waechst.
  DELETE FROM public.social_oauth_state WHERE laeuft_ab < now();

  v_nonce := encode(extensions.gen_random_bytes(24), 'hex');
  INSERT INTO public.social_oauth_state (nonce, "tenantId", benutzer, zurueck, laeuft_ab)
  VALUES (v_nonce, v_verein, public.current_user_row_id(),
          nullif(btrim(coalesce(p_zurueck,'')),''), now() + interval '15 minutes');

  RETURN 'https://www.facebook.com/v21.0/dialog/oauth'
      || '?client_id='     || v_app
      || '&redirect_uri='  || replace(replace(replace(v_ziel,':','%3A'),'/','%2F'),'?','%3F')
      || '&state='         || v_nonce
      || '&response_type=code'
      || '&scope='         || 'pages_show_list,pages_read_engagement,pages_manage_posts,'
                           || 'instagram_basic,instagram_content_publish,business_management';
END $$;
REVOKE ALL ON FUNCTION public.social_verbinden_starten(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.social_verbinden_starten(text) TO authenticated;


-- Wenn mehrere Seiten zur Wahl stehen, waehlt die Administration eine aus.
CREATE OR REPLACE FUNCTION public.social_seite_waehlen(p_konto_id text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_k jsonb; v_n int := 0;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand darf das.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  FOR v_k IN SELECT k FROM public.social_connections c,
                  LATERAL jsonb_array_elements(coalesce(c.kandidaten,'[]'::jsonb)) AS k
              WHERE c."tenantId"=v_verein AND c.plattform='FACEBOOK' AND c.zustand='WAEHLEN'
  LOOP
    IF v_k->>'id' = p_konto_id THEN
      UPDATE public.social_connections
         SET konto_id = v_k->>'id', konto_name = v_k->>'name',
             zugriffstoken = v_k->>'token', zustand='AKTIV',
             kandidaten = NULL, verbunden_am = now()
       WHERE "tenantId"=v_verein AND plattform='FACEBOOK';

      -- Das verknuepfte Instagram-Konto haengt an derselben Seite.
      IF coalesce(v_k->>'ig_id','') <> '' THEN
        INSERT INTO public.social_connections ("tenantId", plattform, konto_id, konto_name,
                                               zugriffstoken, zustand, verbunden_am)
        VALUES (v_verein,'INSTAGRAM', v_k->>'ig_id', coalesce(v_k->>'ig_name', v_k->>'name'),
                v_k->>'token','AKTIV', now())
        ON CONFLICT ("tenantId", plattform) DO UPDATE
          SET konto_id=EXCLUDED.konto_id, konto_name=EXCLUDED.konto_name,
              zugriffstoken=EXCLUDED.zugriffstoken, zustand='AKTIV',
              verbunden_am=now(), letzter_fehler=NULL;
      END IF;
      v_n := 1;
    END IF;
  END LOOP;

  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Seite steht nicht zur Wahl.' USING ERRCODE='check_violation';
  END IF;
  RETURN 'verbunden';
END $$;
REVOKE ALL ON FUNCTION public.social_seite_waehlen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.social_seite_waehlen(text) TO authenticated;

DO $$ BEGIN RAISE NOTICE 'OAuth-Start, Seitenwahl und Zustandstabelle stehen.'; END $$;
