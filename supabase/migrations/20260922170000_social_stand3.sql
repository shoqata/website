DO $$
DECLARE r record;
BEGIN
  RAISE NOTICE '=== Stecken in settings/global noch Zugangsdaten? ===';
  FOR r IN SELECT s."tenantId", s.id, k.schluessel
             FROM public.settings s,
                  LATERAL jsonb_object_keys(coalesce(s.data,'{}'::jsonb)) AS k(schluessel)
            WHERE k.schluessel ILIKE '%token%' OR k.schluessel ILIKE '%secret%'
               OR k.schluessel ILIKE '%fb%' OR k.schluessel ILIKE '%ig%' LOOP
    RAISE NOTICE '  %/% -> Schluessel %', r."tenantId", r.id, r.schluessel;
  END LOOP;

  RAISE NOTICE '=== Der eine gespeicherte Beitrag ===';
  FOR r IN SELECT to_jsonb(x) AS j FROM (
             SELECT id, left(coalesce(content,''),40) AS inhalt, status, platforms,
                    "scheduledTime", timestamp, "tenantId"
               FROM public.socialmediaposts) x LOOP
    RAISE NOTICE '  %', r.j;
  END LOOP;
END $$;
