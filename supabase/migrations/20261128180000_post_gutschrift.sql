-- Briefkontingent durch den Betreiber gutschreiben.
--
-- Ein Verein kauft sein Kontingent nicht immer ueber die Maske: Koretini
-- bezahlt bar oder auf anderem Weg, und der Betreiber bucht die Briefe
-- danach gut. Bisher ging das nur per Migration (so kam der Demoverein zu
-- seinem Guthaben) -- jetzt ueber eine Funktion, die nur der Betreiber
-- aufrufen darf und die festhaelt, wer wann wie viel gutgeschrieben hat.
--
-- Keine Rechnung von unityhub: bezahlt ist ja schon. p_preis ist der
-- Betrag je Brief, den der Verein bezahlt hat -- er geht in die Marge
-- ein wie ein Kauf. Ohne Preis ist es ein Geschenk und zaehlt als 0.

CREATE OR REPLACE FUNCTION public.post_kontingent_gutschreiben(
  p_verein text, p_menge integer, p_grund text DEFAULT NULL, p_preis numeric DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_einkauf numeric; v_waehrung text; v_stand int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Gutschreiben darf nur der Plattformbetreiber.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_verein) THEN
    RAISE EXCEPTION 'Diesen Verein gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_menge IS NULL OR p_menge < 1 OR p_menge > 10000 THEN
    RAISE EXCEPTION 'Bitte zwischen 1 und 10000 Briefe gutschreiben.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_preis IS NOT NULL AND p_preis < 0 THEN
    RAISE EXCEPTION 'Der Preis je Brief kann nicht negativ sein.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT einkauf_je_brief, waehrung INTO v_einkauf, v_waehrung
    FROM public.post_preise WHERE "tenantId" = p_verein;

  INSERT INTO public.post_kontingent
    ("tenantId", art, menge, preis_je_brief, einkauf_je_brief, waehrung, grund, erstellt_von)
  VALUES (p_verein, 'GUTSCHRIFT', p_menge, coalesce(p_preis, 0), v_einkauf,
          coalesce(v_waehrung, 'CHF'),
          left(coalesce(nullif(btrim(p_grund), ''), 'Gutschrift durch den Betreiber'), 200),
          coalesce(auth.jwt() ->> 'email', 'betreiber'));

  SELECT coalesce(sum(menge), 0) INTO v_stand
    FROM public.post_kontingent WHERE "tenantId" = p_verein;

  RETURN jsonb_build_object('gutgeschrieben', p_menge, 'stand', v_stand);
END $$;

REVOKE ALL ON FUNCTION public.post_kontingent_gutschreiben(text, integer, text, numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_kontingent_gutschreiben(text, integer, text, numeric) TO authenticated;

-- Selbsttest: ohne Betreiberrechte wird abgewiesen.
DO $$
BEGIN
  BEGIN
    PERFORM public.post_kontingent_gutschreiben('koretini', 1, 'Test', NULL);
    RAISE EXCEPTION 'Selbsttest: Gutschrift ohne Betreiberrechte ging durch';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;


-- Koretini fehlte in der Tarifliste: der Briefversand ist dort nicht als
-- Modul geschaltet, sondern ueber alle_module_frei offen. Wer nicht in
-- der Liste steht, dem kann der Betreiber auch nichts gutschreiben.
CREATE OR REPLACE FUNCTION public.post_tarife()
 RETURNS TABLE(r_verein text, r_name text, r_einkauf numeric, r_aufpreis numeric, r_fest numeric, r_verkauf numeric, r_waehrung text, r_abgefragt timestamp with time zone, r_grundlage text, r_modul text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  WITH beteiligte AS (
    -- Freigeschaltet, mit oder ohne Preis.
    SELECT tm."tenantId" AS id, tm.zustand AS modul
      FROM public.tenant_modules tm
     WHERE tm.modul = 'POSTVERSAND' AND tm.zustand IN ('AN','TESTPHASE')
    UNION
    -- Alle Module frei (Koretini): der Briefversand ist offen, auch ohne
    -- eigene Modulzeile.
    SELECT t.id, 'AN' FROM public.tenants t WHERE t.alle_module_frei
    UNION
    -- Hat einen Preis, auch wenn das Modul inzwischen aus ist.
    SELECT p."tenantId", NULL
      FROM public.post_preise p
  ), zusammen AS (
    SELECT b.id,
           -- Bei zwei Zeilen je Verein (beide Zweige) gewinnt der
           -- Modulzustand; max() nimmt ihn, weil NULL dabei verliert.
           max(b.modul) AS modul
      FROM beteiligte b GROUP BY b.id
  )
  SELECT z.id,
         coalesce(t.name, z.id),
         p.einkauf_je_brief, p.aufpreis_prozent, p.preis_fest,
         p.preis_je_brief, coalesce(p.waehrung, 'CHF'),
         p.tarif_abgefragt_am, p.tarif_grundlage,
         coalesce(z.modul, 'AUS')
    FROM zusammen z
    LEFT JOIN public.tenants t ON t.id = z.id
    LEFT JOIN public.post_preise p ON p."tenantId" = z.id
   WHERE public.is_platform_admin()
   ORDER BY 2;
$function$;
