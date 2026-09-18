-- Welche Spalten und Typen erwarten auth.users und auth.identities?
DO $$
DECLARE r record; v text := '';
BEGIN
  RAISE NOTICE '=== auth.users: Pflichtspalten ohne Vorgabewert ===';
  FOR r IN SELECT column_name, data_type, coalesce(column_default,'<keiner>') AS vorgabe
             FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND is_nullable='NO'
            ORDER BY ordinal_position LOOP
    RAISE NOTICE '  % (%) Vorgabe %', r.column_name, r.data_type, r.vorgabe;
  END LOOP;

  RAISE NOTICE '=== auth.users: Spalten vom Typ json/jsonb ===';
  FOR r IN SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND data_type LIKE '%json%' LOOP
    RAISE NOTICE '  %: %', r.column_name, r.data_type;
  END LOOP;

  RAISE NOTICE '=== auth.identities: alle Spalten ===';
  FOR r IN SELECT column_name, data_type, is_nullable, coalesce(column_default,'<keiner>') AS vorgabe
             FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='identities' ORDER BY ordinal_position LOOP
    RAISE NOTICE '  % (%) NULL erlaubt % Vorgabe %', r.column_name, r.data_type, r.is_nullable, r.vorgabe;
  END LOOP;

  RAISE NOTICE '=== Wie sieht ein bestehendes Konto aus? ===';
  FOR r IN SELECT au.email, au.aud, au.role, au.instance_id,
                  au.raw_app_meta_data::text AS app, au.raw_user_meta_data::text AS usr,
                  coalesce(au.confirmation_token,'<null>') AS tok
             FROM auth.users au LIMIT 1 LOOP
    RAISE NOTICE '  % | aud % | role % | instance %', r.email, r.aud, r.role, r.instance_id;
    RAISE NOTICE '     app % | user % | token %', r.app, r.usr, r.tok;
  END LOOP;
  FOR r IN SELECT i.provider, i.provider_id, i.identity_data::text AS daten
             FROM auth.identities i LIMIT 1 LOOP
    RAISE NOTICE '  Identitaet: % | % | %', r.provider, r.provider_id, r.daten;
  END LOOP;
END $$;
