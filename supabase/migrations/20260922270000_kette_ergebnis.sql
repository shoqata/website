DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT status, attempts, left(coalesce("lastError",'-'),60) AS fehler,
                  "publishedAt", "externalIds"
             FROM public.socialmediaposts WHERE id='probe-kette' LOOP
    RAISE NOTICE '  Beitrag: % | Versuche % | % | veroeffentlicht % | ids %',
      r.status, r.attempts, r.fehler, coalesce(r."publishedAt"::text,'nein'),
      coalesce(r."externalIds"::text,'-');
  END LOOP;

  FOR r IN SELECT plattform, zustand, left(coalesce(letzter_fehler,'-'),60) AS fehler
             FROM public.social_connections WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  Verbindung: % | % | %', r.plattform, r.zustand, r.fehler;
  END LOOP;

  -- Aufraeumen
  DELETE FROM public.socialmediaposts WHERE id='probe-kette';
  DELETE FROM public.social_connections WHERE zugriffstoken='PROBE-UNGUELTIG';
  RAISE NOTICE '  Probezeilen entfernt.';
END $$;
