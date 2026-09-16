-- Wie viele Mitglieder sind heute von der neuen Regel betroffen?
-- Bevor die Pflicht greift, soll der Vorstand wissen, was auf ihn zukommt.
DO $$
DECLARE r record; v int;
BEGIN
  SELECT count(*) INTO v FROM public.users WHERE "tenantId"='koretini';
  RAISE NOTICE 'Mitglieder gesamt: %', v;

  SELECT count(*) INTO v FROM public.users
   WHERE "tenantId"='koretini'
     AND (email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%');
  RAISE NOTICE 'ohne brauchbare E-Mail-Adresse: %', v;

  RAISE NOTICE '--- nach gewaehlter Zustellart ---';
  FOR r IN
    SELECT COALESCE("invoiceDeliveryMethod",'(nicht gesetzt)') AS art,
           count(*) AS gesamt,
           count(*) FILTER (WHERE email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%') AS ohne_mail
      FROM public.users WHERE "tenantId"='koretini'
     GROUP BY 1 ORDER BY 2 DESC
  LOOP
    RAISE NOTICE '  % : % Mitglieder, davon % ohne brauchbare Adresse', r.art, r.gesamt, r.ohne_mail;
  END LOOP;

  SELECT count(*) INTO v FROM public.users
   WHERE "tenantId"='koretini'
     AND "invoiceDeliveryMethod" IN ('EMAIL','BOTH')
     AND (email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%');
  RAISE NOTICE 'BETROFFEN (E-Mail-Versand ohne Adresse): %', v;
END $$;
