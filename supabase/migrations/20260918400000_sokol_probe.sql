-- Was ist beim Zuruecksetzen fuer axhija.sokol@gmail.com passiert?
DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE '=== Mitgliedszeile ===';
  FOR r IN SELECT u.id, u."displayName", u.email, coalesce(u."authUserId",'-') AS konto,
                  coalesce(u.role,'-') AS rolle, coalesce(u."membershipStatus",'-') AS status
             FROM public.users u WHERE lower(u.email) LIKE '%axhija%' OR lower(u."displayName") LIKE '%sokol%' LOOP
    RAISE NOTICE '  % | % | %', r.id, r."displayName", r.email;
    RAISE NOTICE '     Konto % | % | %', r.konto, r.rolle, r.status;
  END LOOP;

  RAISE NOTICE '=== Anmeldekonten ===';
  FOR r IN SELECT au.email, au.id,
                  (au.email_confirmed_at IS NOT NULL) AS bestaetigt,
                  (au.encrypted_password IS NOT NULL) AS passwort,
                  (au.confirmation_token IS NULL) AS tok_null,
                  (au.recovery_token IS NULL) AS rec_null,
                  (au.email_change_token_new IS NULL) AS chg_null,
                  (au.email_change IS NULL) AS mailchg_null,
                  (SELECT count(*) FROM auth.identities i WHERE i.user_id = au.id) AS identitaeten,
                  au.created_at, au.last_sign_in_at
             FROM auth.users au ORDER BY au.created_at LOOP
    RAISE NOTICE '  % (%)', r.email, r.id;
    RAISE NOTICE '     bestaetigt % | Passwort % | Identitaeten % | angelegt %',
      r.bestaetigt, r.passwort, r.identitaeten, r.created_at;
    RAISE NOTICE '     Token auf NULL -- confirmation % recovery % email_change_new % email_change %',
      r.tok_null, r.rec_null, r.chg_null, r.mailchg_null;
    RAISE NOTICE '     zuletzt angemeldet %', coalesce(r.last_sign_in_at::text, 'nie');
  END LOOP;

  RAISE NOTICE '=== Protokoll der Zuruecksetzungen ===';
  FOR r IN SELECT sl."createdAt", sl.action, sl.details,
                  coalesce(u."displayName",'-') AS person
             FROM public.security_logs sl
             LEFT JOIN public.users u ON u.id = sl."userId"
            WHERE sl.type = 'PASSWORD_RESET'
            ORDER BY sl."createdAt" DESC LIMIT 8 LOOP
    RAISE NOTICE '  % | % | % | %', r."createdAt", r.action, r.person, r.details::text;
  END LOOP;
  IF NOT FOUND THEN RAISE NOTICE '  keine Eintraege'; END IF;
END $$;
