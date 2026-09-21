-- Probespenden aus den Tests entfernen.
DELETE FROM public.donations WHERE "tenantId"='koretini';
DO $$ BEGIN RAISE NOTICE 'Spenden in der Tabelle: %', (SELECT count(*) FROM public.donations); END $$;
