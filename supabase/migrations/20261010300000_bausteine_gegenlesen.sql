-- Wer hat diesen Text gegengelesen?
--
-- Die albanischen Vorlagen stammen von mir und sind ein erster Wurf. Sie
-- gehen an Mitglieder hinaus -- ein schiefer Satz in einer Mahnung wird
-- gelesen und erinnert. Seit Wochen steht in den Notizen "sollte jemand
-- aus dem Referenzverein gegenlesen", und eine Notiz erledigt nichts.
--
-- Deshalb steht es jetzt an der Vorlage selbst: ungeprueft ist der
-- Normalzustand und sichtbar, geprueft wird mit Namen und Datum
-- vermerkt. Das loest das Gegenlesen nicht -- das kann nur ein Mensch,
-- der die Sprache spricht. Es sorgt dafuer, dass niemand vergisst,
-- welche Texte noch offen sind.
--
-- Eine Aenderung am Text setzt den Vermerk zurueck: gegengelesen wurde
-- die alte Fassung, nicht die neue.

ALTER TABLE public.textbausteine
  ADD COLUMN IF NOT EXISTS geprueft_am   timestamptz,
  ADD COLUMN IF NOT EXISTS geprueft_von  text,
  ADD COLUMN IF NOT EXISTS geprueft_text text;

COMMENT ON COLUMN public.textbausteine.geprueft_text IS
  'Der Wortlaut, der gegengelesen wurde. Weicht er vom heutigen ab, ist '
  'der Vermerk ueberholt -- geprueft wurde eine andere Fassung.';


DROP FUNCTION IF EXISTS public.baustein_gegengelesen(text, boolean);

CREATE OR REPLACE FUNCTION public.baustein_gegengelesen(p_id uuid, p_an boolean DEFAULT true)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_wer text; v_name text; v_text text; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_staff()) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf einen Text als gegengelesen vermerken.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_wer := public.current_user_row_id();
  SELECT u."displayName" INTO v_name FROM public.users u WHERE u.id = v_wer;

  SELECT b.text INTO v_text FROM public.textbausteine b
   WHERE b.id = p_id AND b."tenantId" = public.current_tenant();
  IF v_text IS NULL THEN
    RAISE EXCEPTION 'Diesen Textbaustein gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.textbausteine SET
    geprueft_am   = CASE WHEN p_an THEN now() ELSE NULL END,
    geprueft_von  = CASE WHEN p_an THEN coalesce(v_name, 'unbekannt') ELSE NULL END,
    geprueft_text = CASE WHEN p_an THEN v_text ELSE NULL END
   WHERE id = p_id AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Nicht vermerkt.' USING ERRCODE = 'check_violation';
  END IF;

  RETURN p_an;
END $$;
REVOKE ALL ON FUNCTION public.baustein_gegengelesen(uuid, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.baustein_gegengelesen(uuid, boolean) TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_offen int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='textbausteine'
                    AND column_name='geprueft_am') THEN
    RAISE EXCEPTION 'Spalte geprueft_am fehlt.';
  END IF;

  -- Kein Text darf als geprueft starten. Ein Haken, den niemand gesetzt
  -- hat, waere schlimmer als gar keiner: er behauptet eine Pruefung.
  SELECT count(*) INTO v_n FROM public.textbausteine WHERE geprueft_am IS NOT NULL;
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Baustein(e) gelten bereits als geprueft -- von niemandem.', v_n;
  END IF;

  -- textbausteine.id ist uuid. Mit text als Parameter scheiterte der
  -- Vergleich -- und zwar erst beim ersten Klick, nicht beim Anlegen.
  -- Der Typ wird aus proargtypes gelesen, nicht aus
  -- pg_get_function_identity_arguments: das liefert "p_id uuid" samt
  -- Parameternamen, und ein Vergleich mit 'uuid%' schlaegt dort fehl --
  -- was mir beim ersten Versuch einen falschen Alarm eingetragen hat.
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
     WHERE ns.nspname='public' AND p.proname='baustein_gegengelesen'
       AND p.proargtypes[0] = 'uuid'::regtype) THEN
    RAISE EXCEPTION 'baustein_gegengelesen nimmt nicht uuid -- der Vergleich mit id scheitert.';
  END IF;
  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
       WHERE ns.nspname='public' AND p.proname='baustein_gegengelesen') <> 1 THEN
    RAISE EXCEPTION 'Es gibt mehr als eine Fassung von baustein_gegengelesen.';
  END IF;

  SELECT count(*) INTO v_offen FROM public.textbausteine WHERE sprache = 'sq';
  RAISE NOTICE 'Gegenlesen bereit. Offen: % albanische Vorlage(n) ueber alle Vereine.', v_offen;
END $$;
