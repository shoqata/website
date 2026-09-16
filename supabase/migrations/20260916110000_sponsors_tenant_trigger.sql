-- Der Verein darf beim Sponsorenformular nicht vom Aufrufer kommen.
--
-- Erster Anlauf hat den vom Client gesendeten "tenantId" gegen
-- COALESCE(current_tenant(), request_tenant()) geprueft. Das hat auch den
-- erlaubten Fall abgewiesen. Statt weiter zu raten, folgt diese Fassung dem
-- Muster, das bei den Gastanmeldungen nachweislich traegt: ein Trigger setzt
-- den Verein serverseitig, der vom Client gesendete Wert wird verworfen.
--
-- Damit ist der Weg fuer einen Besucher genau einer: eine neue Anfrage fuer
-- den Verein anlegen, unter dessen Adresse er gerade steht.

CREATE OR REPLACE FUNCTION public.set_sponsor_tenant()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_tenant text;
BEGIN
  v_tenant := COALESCE(public.current_tenant(), public.request_tenant());
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Sponsorenanfrage ohne erkennbaren Verein.'
      USING ERRCODE = 'check_violation';
  END IF;
  NEW."tenantId" := v_tenant;

  -- Ein Besucher legt immer eine neue Anfrage an. Bearbeitungsstand und
  -- interne Notiz gehoeren dem Vorstand.
  NEW.status := 'NEW';
  NEW."internalNote" := NULL;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS sponsors_set_tenant ON public.sponsors;
CREATE TRIGGER sponsors_set_tenant
BEFORE INSERT ON public.sponsors
FOR EACH ROW EXECUTE FUNCTION public.set_sponsor_tenant();

-- Die Pruefung kann jetzt schlicht sein: den Verein hat der Trigger gesetzt.
DROP POLICY IF EXISTS sponsors_public_insert ON public.sponsors;
CREATE POLICY sponsors_public_insert ON public.sponsors
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

-- Diagnose: zeigt, was serverseitig ankommt. Nur fuer die Inbetriebnahme,
-- wird in der naechsten Migration wieder entfernt.
CREATE OR REPLACE FUNCTION public.sponsor_tenant_probe()
RETURNS json
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT json_build_object(
    'sitzung', public.current_tenant(),
    'adresse', public.request_tenant(),
    'ergibt',  COALESCE(public.current_tenant(), public.request_tenant())
  )
$$;
GRANT EXECUTE ON FUNCTION public.sponsor_tenant_probe() TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
