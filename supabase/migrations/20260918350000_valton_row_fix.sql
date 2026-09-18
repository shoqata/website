-- Die vier Token-Felder angleichen.
--
-- GoTrue liest confirmation_token, recovery_token, email_change_token_new und
-- email_change als Zeichenketten ein. Stehen sie auf NULL, bricht der Dienst
-- mit "Database error querying schema" ab -- die Anmeldung schlaegt fehl,
-- obwohl Konto, Passwort und Identitaet stimmen. Bei den bestehenden Konten
-- steht dort der leere String.
--
-- Das ist der Grund, warum eine Anmeldezeile besser ueber die
-- Verwaltungsschnittstelle entsteht als von Hand: solche Feinheiten stehen
-- nirgends im Schema, sie zeigen sich erst beim Anmelden.
UPDATE auth.users
   SET confirmation_token     = coalesce(confirmation_token, ''),
       recovery_token         = coalesce(recovery_token, ''),
       email_change_token_new = coalesce(email_change_token_new, ''),
       email_change           = coalesce(email_change, ''),
       is_super_admin         = NULL
 WHERE email = 'valton.rexha@gmail.com';

-- Und gleich alle uebrigen mitpruefen, damit kein zweites Konto daran haengt.
UPDATE auth.users
   SET confirmation_token     = coalesce(confirmation_token, ''),
       recovery_token         = coalesce(recovery_token, ''),
       email_change_token_new = coalesce(email_change_token_new, ''),
       email_change           = coalesce(email_change, '')
 WHERE confirmation_token IS NULL OR recovery_token IS NULL
    OR email_change_token_new IS NULL OR email_change IS NULL;

DO $$
DECLARE v_neu jsonb; v_alt jsonb; k text; v_n int := 0;
BEGIN
  SELECT to_jsonb(au) INTO v_neu FROM auth.users au WHERE au.email = 'valton.rexha@gmail.com';
  SELECT to_jsonb(au) INTO v_alt FROM auth.users au WHERE au.email = 'selmani.besart@hotmail.com';
  FOR k IN SELECT jsonb_object_keys(v_alt) ORDER BY 1 LOOP
    IF k IN ('id','email','created_at','updated_at','encrypted_password',
             'email_confirmed_at','confirmed_at','last_sign_in_at') THEN CONTINUE; END IF;
    IF (v_neu -> k) IS DISTINCT FROM (v_alt -> k) THEN
      RAISE NOTICE '  Unterschied bei %: neu=% alt=%', k, (v_neu -> k)::text, (v_alt -> k)::text;
      v_n := v_n + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'Verbleibende Unterschiede: % -- erwartet 0', v_n;
END $$;
