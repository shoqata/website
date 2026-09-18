-- Die Vereinskennung setzt die Datenbank, nicht der Browser.
--
-- Sonst muesste der Klient sie erst erfragen und beim Einfuegen mitschicken --
-- eine Angabe, die er weder kennen noch bestimmen soll. Die Zeilenregel
-- verlangt ohnehin, dass sie zum eigenen Verein passt; hier wird sie einfach
-- richtig gesetzt.
ALTER TABLE public.family_links ALTER COLUMN "tenantId" DROP NOT NULL;

CREATE OR REPLACE FUNCTION public.family_links_verein_setzen()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN
    NEW."tenantId" := public.current_tenant();
  END IF;
  IF NEW.erfasst_von IS NULL THEN
    SELECT coalesce(u.email, auth.uid()::text) INTO NEW.erfasst_von
      FROM public.users u WHERE u.id = public.current_user_row_id();
  END IF;
  IF NEW."tenantId" IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS family_links_verein_trg ON public.family_links;
CREATE TRIGGER family_links_verein_trg
  BEFORE INSERT ON public.family_links
  FOR EACH ROW EXECUTE FUNCTION public.family_links_verein_setzen();

-- Der Pruef-Trigger muss danach laufen, sonst sieht er die Kennung noch nicht.
DROP TRIGGER IF EXISTS family_links_pruefen_trg ON public.family_links;
CREATE TRIGGER family_links_zz_pruefen_trg
  BEFORE INSERT OR UPDATE ON public.family_links
  FOR EACH ROW EXECUTE FUNCTION public.family_links_pruefen();

GRANT SELECT, INSERT, UPDATE, DELETE ON public.family_links TO authenticated;
