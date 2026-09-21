-- Der Betreiber traegt die Meta-App ein.
--
-- Nur die App-Nummer und die Rueckruf-Adresse -- beides steht ohnehin offen
-- im Anmeldelink und ist kein Geheimnis. Das App-Geheimnis gehoert NICHT
-- hierher: es lebt in der Umgebung der Funktion meta-oauth. Eine Maske, die
-- danach fragt, wuerde es durch den Browser schicken und in der Datenbank
-- ablegen; genau der Weg, auf dem im September Token oeffentlich wurden.
CREATE OR REPLACE FUNCTION public.plattform_geheimnis_setzen(
  p_schluessel text, p_wert text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF p_schluessel NOT IN ('meta_app_id','meta_redirect_uri') THEN
    RAISE EXCEPTION 'Dieser Schluessel laesst sich hier nicht setzen: %', p_schluessel
      USING ERRCODE='check_violation';
  END IF;

  INSERT INTO public.platform_secrets (schluessel, wert)
  VALUES (p_schluessel, btrim(coalesce(p_wert,'')))
  ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert;
  RETURN 'gesetzt';
END $$;
REVOKE ALL ON FUNCTION public.plattform_geheimnis_setzen(text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.plattform_geheimnis_setzen(text,text) TO authenticated;

-- Lesen darf der Betreiber nur, was ohnehin offen ist.
CREATE OR REPLACE FUNCTION public.plattform_geheimnisse()
RETURNS TABLE (schluessel text, wert text, notiz text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT s.schluessel, s.wert, s.notiz FROM public.platform_secrets s
   WHERE public.is_platform_admin()
     AND s.schluessel IN ('meta_app_id','meta_redirect_uri');
$$;
REVOKE ALL ON FUNCTION public.plattform_geheimnisse() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.plattform_geheimnisse() TO authenticated;

DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; r record; v_n int;
BEGIN
  -- Gegenprobe: kommt ein Vereinsadministrator an das Zeitplan-Kennwort?
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE coalesce(u.role,'MEMBER')='ADMIN' AND u."authUserId" IS NOT NULL LIMIT 1;
  IF v_uid IS NULL THEN
    SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
     WHERE u.role='BOARD' AND u."authUserId" IS NOT NULL LIMIT 1;
  END IF;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  BEGIN
    SELECT count(*) INTO v_n FROM public.plattform_geheimnisse();
    RAISE NOTICE '  Vereinsadministrator sieht % Plattformwerte (erwartet 0)', v_n;
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  Vereinsadministrator: %', left(SQLERRM,40); END;
  BEGIN
    PERFORM public.plattform_geheimnis_setzen('meta_app_id','111');
    RAISE NOTICE '  darf setzen: JA -- LOCH';
  EXCEPTION WHEN OTHERS THEN RAISE NOTICE '  darf setzen: nein'; END;
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
