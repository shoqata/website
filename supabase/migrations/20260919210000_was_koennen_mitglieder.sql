DO $$
DECLARE v_n int; v_g int; r record;
BEGIN
  SELECT count(*) INTO v_g FROM public.users;
  RAISE NOTICE 'Mitglieder gesamt: %', v_g;

  SELECT count(*) INTO v_n FROM public.users WHERE "authUserId" IS NOT NULL;
  RAISE NOTICE 'Kann sich schon anmelden: %', v_n;

  SELECT count(*) INTO v_n FROM public.users
   WHERE coalesce(email,'') <> '' AND email NOT ILIKE '%@koretini.legacy'
     AND email NOT ILIKE '%no-email-%' AND "authUserId" IS NULL;
  RAISE NOTICE 'Koennte sich anmelden (echte E-Mail, noch kein Konto): %', v_n;

  SELECT count(*) INTO v_n FROM public.users
   WHERE coalesce(email,'') = '' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%';
  RAISE NOTICE 'Braucht zuerst eine E-Mail-Adresse: %', v_n;

  SELECT count(*) INTO v_n FROM public.users WHERE coalesce(phone,'') <> '';
  RAISE NOTICE 'Mit Telefonnummer erreichbar: %', v_n;

  RAISE NOTICE '--- Registrierung offen? ---';
  FOR r IN SELECT system ->> 'allowRegistration' AS offen, system ->> 'systemEmail' AS mail
             FROM public.settings WHERE id='system' LOOP
    RAISE NOTICE '  allowRegistration=% systemEmail=%', r.offen, r.mail;
  END LOOP;

  RAISE NOTICE '--- Zahlwege, die wirklich hinterlegt sind ---';
  FOR r IN SELECT payment ->> 'qrIban' AS iban, payment ->> 'accountHolder' AS inhaber,
                  payment ->> 'bankName' AS bank,
                  (payment ->> 'twintUrl' IS NOT NULL) AS twint,
                  (coalesce(payment ->> 'paypalEmail','') <> '') AS paypal,
                  payment -> 'fees' AS beitraege
             FROM public.settings WHERE id='payment' LOOP
    RAISE NOTICE '  IBAN % (%, %)', r.iban, r.inhaber, r.bank;
    RAISE NOTICE '  TWINT % | PayPal %', r.twint, r.paypal;
    RAISE NOTICE '  Beitraege %', r.beitraege;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.payments WHERE status = 'PENDING';
  RAISE NOTICE 'Offene Rechnungen: %', v_n;
END $$;
