DO $$ DECLARE r record; BEGIN
  RAISE NOTICE '=== Alle Betreuungszeilen ===';
  FOR r IN SELECT email, "tenantId", "startedAt", "endedAt", left(coalesce(reason,'-'),40) AS grund
             FROM public.platform_support ORDER BY "startedAt" LOOP
    RAISE NOTICE '  % | % | seit % | beendet % | %',
      rpad(coalesce(r.email,'-'),22), rpad(coalesce(r."tenantId",'-'),10),
      substr(r."startedAt"::text,1,16), rpad(coalesce(substr(r."endedAt"::text,1,16),'NEIN'),16), r.grund;
  END LOOP;
END $$;
