DO $$
DECLARE z text; r record;
BEGIN
  RAISE NOTICE '=== public_settings: was kommt oeffentlich heraus? ===';
  FOR z IN SELECT unnest(string_to_array(pg_get_viewdef('public.public_settings'::regclass, true), E'\n')) LOOP
    RAISE NOTICE '  %', z;
  END LOOP;

  RAISE NOTICE '=== Wer hat 2026 bezahlt? (koretini) ===';
  FOR r IN SELECT count(*) FILTER (WHERE p.status='PAID') AS bezahlt,
                  count(*) FILTER (WHERE p.status='PENDING') AS offen,
                  count(DISTINCT p."userId") FILTER (WHERE p.status='PAID') AS personen
             FROM public.payments p
            WHERE p."tenantId"='koretini' AND p."billingYear"=2026 LOOP
    RAISE NOTICE '  % bezahlte Rechnungen von % Personen, % offen', r.bezahlt, r.personen, r.offen;
  END LOOP;

  RAISE NOTICE '=== Mitglieder gesamt und wie viele oeffentlich erscheinen wuerden ===';
  FOR r IN SELECT count(*) AS gesamt,
                  count(*) FILTER (WHERE coalesce("membershipStatus",'') <> 'INACTIVE') AS in_der_sicht,
                  count(*) FILTER (WHERE coalesce("membershipStatus",'')='ACTIVE') AS aktiv
             FROM public.users WHERE "tenantId"='koretini' LOOP
    RAISE NOTICE '  % Mitglieder, % in public_members, % davon ACTIVE', r.gesamt, r.in_der_sicht, r.aktiv;
  END LOOP;
END $$;
