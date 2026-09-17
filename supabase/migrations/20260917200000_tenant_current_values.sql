DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT id, name, "subscriptionPlan", "subscriptionStatus", "annualFee", "setupFee",
                  "contactName", "contactEmail", "billingNote"
             FROM public.tenants LOOP
    RAISE NOTICE 'Verein %: Plan=% Status=% Jahresgebuehr=% Einrichtung=% Ansprech=% Mail=% Notiz=%',
      r.id, r."subscriptionPlan", r."subscriptionStatus",
      COALESCE(r."annualFee"::text,'-'), COALESCE(r."setupFee"::text,'-'),
      COALESCE(r."contactName",'-'), COALESCE(r."contactEmail",'-'), COALESCE(r."billingNote",'-');
  END LOOP;
END $$;
