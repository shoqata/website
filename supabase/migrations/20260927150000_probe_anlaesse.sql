DO $$
BEGIN
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES ('probe-premium','ANLAESSE','AN')
  ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand='AN';
  RAISE NOTICE 'Anlaesse fuer den Probeverein aktiv.';
END $$;
