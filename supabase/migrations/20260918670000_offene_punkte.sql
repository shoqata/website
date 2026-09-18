-- Was steht noch offen? Gemessen statt aus dem Gedaechtnis.
DO $$
DECLARE v_n int; v_chf numeric; r record;
BEGIN
  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_chf
    FROM public.accounting_journal j
   WHERE j."referenceId" IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.payments p WHERE p.id = j."referenceId");
  RAISE NOTICE 'Journalbuchungen ohne Rechnung: % ueber % CHF', v_n, v_chf;

  SELECT count(*), coalesce(sum(amount),0) INTO v_n, v_chf
    FROM public.accounting_journal WHERE "debitCode" IS NULL OR "creditCode" IS NULL;
  RAISE NOTICE 'Buchungen ohne Kontonummer: % ueber % CHF', v_n, v_chf;

  SELECT count(*) INTO v_n FROM public.users
   WHERE email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%';
  RAISE NOTICE 'Ohne brauchbare E-Mail: % von %', v_n, (SELECT count(*) FROM public.users);

  SELECT count(*) INTO v_n FROM public.users WHERE birthdate IS NULL OR btrim(birthdate)='';
  RAISE NOTICE 'Ohne Geburtsdatum: %', v_n;

  SELECT count(*) INTO v_n FROM (
    SELECT lower(btrim("displayName")) FROM public.users
     WHERE "displayName" IS NOT NULL GROUP BY 1 HAVING count(*) > 1) x;
  RAISE NOTICE 'Namen, die mehrfach vorkommen: %', v_n;

  SELECT count(*) INTO v_n FROM public.settings
   WHERE payment ? 'paypalSecret' AND coalesce(payment ->> 'paypalSecret','') <> '';
  RAISE NOTICE 'Einstellungszeilen mit PayPal-Geheimnis: %', v_n;

  SELECT count(*) INTO v_n FROM public.mail_queue WHERE status = 'PENDING';
  RAISE NOTICE 'Unversandte Nachrichten in der Warteschlange: %', v_n;

  SELECT count(*) INTO v_n FROM public.neighborhoods n
   WHERE NOT EXISTS (SELECT 1 FROM public.users u
                      WHERE n."contactPersonIds" @> to_jsonb(u.id)
                         OR n."representativeId" = u.id OR n."managerId" = u.id);
  RAISE NOTICE 'Nachbarschaften ohne verantwortliche Person: % von %',
    v_n, (SELECT count(*) FROM public.neighborhoods);

  SELECT count(*) INTO v_n FROM public.users WHERE "authUserId" IS NOT NULL;
  RAISE NOTICE 'Mitglieder mit Anmeldekonto: % von %', v_n, (SELECT count(*) FROM public.users);

  SELECT count(*) INTO v_n FROM public.payments WHERE status = 'PENDING';
  SELECT coalesce(sum(amount),0) INTO v_chf FROM public.payments WHERE status = 'PENDING';
  RAISE NOTICE 'Offene Rechnungen: % ueber % CHF', v_n, v_chf;
END $$;
