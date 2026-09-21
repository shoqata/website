-- Einstellungen gehoeren je Verein.
--
-- settings hatte PRIMARY KEY (id) -- also konnte es settings/payment nur
-- einmal auf der ganzen Plattform geben. Aufgefallen beim Einrichten eines
-- zweiten Vereins, der genau daran scheiterte.
--
-- Dieselbe Sorte Fehler wie beim Kontenplan: ein Schluessel, der fuer einen
-- einzigen Verein richtig aussieht und beim zweiten bricht.
ALTER TABLE public.settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE public.settings ADD PRIMARY KEY ("tenantId", id);

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT pg_get_constraintdef(c.oid) AS def FROM pg_constraint c
            WHERE c.conrelid='public.settings'::regclass AND c.contype='p' LOOP
    RAISE NOTICE 'settings: %', r.def;
  END LOOP;
  RAISE NOTICE 'Zeilen unveraendert: %', (SELECT count(*) FROM public.settings);
END $$;
