-- Kann dieser Verein seine Kanaele ueberhaupt verbinden -- und was fehlt?
--
-- Bisher gab es darauf nur eine Antwort: klicken und sehen. Fehlte die
-- Meta-App des Betreibers, bekam der Verein eine Ausnahme ins Gesicht.
-- Das ist ehrlich, aber kein guter Weg: er haette es vorher wissen
-- koennen, und er haette vorher wissen sollen, was er selbst mitbringen
-- muss.
--
-- Diese Funktion gibt den Stand zurueck, ohne irgendeinen Wert
-- preiszugeben. Ob die App-Nummer gesetzt ist, ist eine Ja-Nein-Frage; die
-- Nummer selbst geht den Verein nichts an, und das App-Geheimnis liegt
-- ohnehin nur in der Umgebung der Funktion, nicht in der Datenbank.

CREATE OR REPLACE FUNCTION public.social_einrichtung()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_app    boolean;
  v_ziel   boolean;
  v_modul  boolean;
  v_aktiv  int;
  v_fehler text;
BEGIN
  IF v_verein IS NULL OR NOT public.is_staff() THEN
    RAISE EXCEPTION 'Nur Administration oder Vorstand.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT coalesce(btrim(wert),'') <> '' INTO v_app
    FROM public.platform_secrets WHERE schluessel='meta_app_id';
  SELECT coalesce(btrim(wert),'') <> '' INTO v_ziel
    FROM public.platform_secrets WHERE schluessel='meta_redirect_uri';
  v_modul := public.modul_aktiv('SOCIAL');

  SELECT count(*) FILTER (WHERE zustand='AKTIV'),
         max(letzter_fehler)
    INTO v_aktiv, v_fehler
    FROM public.social_connections WHERE "tenantId" = v_verein;

  RETURN jsonb_build_object(
    'modul_aktiv',      v_modul,
    -- Beides muss stehen, sonst fuehrt der Verweis zu Meta ins Leere.
    'plattform_bereit', coalesce(v_app,false) AND coalesce(v_ziel,false),
    'app_hinterlegt',   coalesce(v_app,false),
    'ziel_hinterlegt',  coalesce(v_ziel,false),
    'verbunden',        coalesce(v_aktiv,0) > 0,
    'anzahl_kanaele',   coalesce(v_aktiv,0),
    'letzter_fehler',   v_fehler
  );
END $$;
REVOKE ALL ON FUNCTION public.social_einrichtung() FROM public;
GRANT EXECUTE ON FUNCTION public.social_einrichtung() TO authenticated;
