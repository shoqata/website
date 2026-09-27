-- Modul "Startseite Premium" -- die erste Leistung mit Aufpreis.
--
-- Dabei faellt auf, was bisher fehlte: preis_monat stand zwar in der
-- Tabelle und liess sich im Betreiberbereich eintragen, wurde aber nirgends
-- abgerechnet. Die Jahresrechnung nahm allein tenants.annualFee, eine von
-- Hand eingetippte Zahl. Ein Preis am Modul waere damit ein Schaufenster
-- ohne Kasse gewesen -- deshalb steht hier auch die Berechnung.

INSERT INTO public.modules (schluessel, name_de, name_en, name_sq,
                            beschreibung_de, beschreibung_en, beschreibung_sq,
                            ist_kern, status, braucht_einrichtung,
                            preis_monat, reihenfolge)
SELECT 'LANDINGPAGE',
  'Startseite Premium', 'Premium landing page', 'Faqja kryesore premium',
  'Eine erzaehlende Startseite, die sich beim Scrollen entfaltet: Bilder, Zahlen und Anliegen des Vereins in Bewegung statt untereinander. Ersetzt die Standardstartseite.',
  'A narrative landing page that unfolds as you scroll: the association''s images, figures and purpose in motion rather than stacked. Replaces the standard front page.',
  'Nje faqe kryesore rrefyese qe shpaloset teksa rreshqitni: imazhet, shifrat dhe qellimi i shoqates ne levizje, jo te renditura. Zevendeson faqen standarde.',
  false, 'VERFUEGBAR', false, 15.00, 15
 WHERE NOT EXISTS (SELECT 1 FROM public.modules WHERE schluessel='LANDINGPAGE');


-- Ein Besucher ist nicht angemeldet. modul_aktiv() fragt current_tenant()
-- und gibt ihm deshalb immer false -- fuer die Zeilenregeln richtig, fuer
-- die Frage "welche Startseite bekommt dieser Besucher" unbrauchbar.
CREATE OR REPLACE FUNCTION public.modul_aktiv_oeffentlich(p_modul text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT true FROM public.tenants t
      WHERE t.id = coalesce(public.current_tenant(), public.request_tenant())
        AND t.alle_module_frei),
    (SELECT true FROM public.modules m
      WHERE m.schluessel = p_modul AND m.ist_kern),
    (SELECT tm.zustand IN ('AN','TESTPHASE')
       AND (tm.testet_bis IS NULL OR tm.testet_bis >= current_date)
       FROM public.tenant_modules tm
      WHERE tm."tenantId" = coalesce(public.current_tenant(), public.request_tenant())
        AND tm.modul = p_modul),
    false);
$$;
REVOKE ALL ON FUNCTION public.modul_aktiv_oeffentlich(text) FROM public;
GRANT EXECUTE ON FUNCTION public.modul_aktiv_oeffentlich(text) TO anon, authenticated;


-- Was ein Verein im Jahr kostet: Grundpreis plus gebuchte Module.
--
-- Vereine mit alle_module_frei zahlen fuer Module nichts -- das ist keine
-- Ausnahme im Code, sondern dieselbe Regel, nach der modul_aktiv()
-- entscheidet. Koretini faellt damit von selbst heraus.
CREATE OR REPLACE FUNCTION public.jahresrechnung_betrag(p_verein text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_grund numeric;
  v_frei  boolean;
  v_posten jsonb;
  v_summe numeric;
BEGIN
  IF NOT (public.is_platform_admin() OR p_verein = public.current_tenant()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT coalesce(t."annualFee", 0), coalesce(t.alle_module_frei, false)
    INTO v_grund, v_frei
    FROM public.tenants t WHERE t.id = p_verein;
  IF v_grund IS NULL THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein USING ERRCODE='check_violation';
  END IF;

  IF v_frei THEN
    RETURN jsonb_build_object('grundpreis', v_grund, 'module', '[]'::jsonb,
                              'modulsumme', 0, 'summe', v_grund, 'alles_frei', true);
  END IF;

  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'schluessel', m.schluessel, 'name', m.name_de,
           'monat', m.preis_monat, 'jahr', round(m.preis_monat * 12, 2))
         ORDER BY m.reihenfolge), '[]'::jsonb),
         coalesce(sum(round(m.preis_monat * 12, 2)), 0)
    INTO v_posten, v_summe
    FROM public.tenant_modules tm
    JOIN public.modules m ON m.schluessel = tm.modul
   WHERE tm."tenantId" = p_verein
     AND tm.zustand = 'AN'
     AND NOT m.ist_kern
     AND coalesce(m.preis_monat, 0) > 0;

  RETURN jsonb_build_object('grundpreis', v_grund, 'module', v_posten,
                            'modulsumme', v_summe, 'summe', v_grund + v_summe,
                            'alles_frei', false);
END $$;
REVOKE ALL ON FUNCTION public.jahresrechnung_betrag(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.jahresrechnung_betrag(text) TO authenticated;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schluessel, name_de, preis_monat, status FROM public.modules
            WHERE schluessel='LANDINGPAGE' LOOP
    RAISE NOTICE 'Modul: % | % | % pro Monat | %', r.schluessel, r.name_de, r.preis_monat, r.status;
  END LOOP;
  RAISE NOTICE 'Koretini: %', public.jahresrechnung_betrag('koretini');
END $$;
