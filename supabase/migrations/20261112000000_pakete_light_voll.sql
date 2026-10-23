-- Pakete Light und Voll -- zuerst fuer den Demoverein.
--
--   Light  = die Kernmodule: Mitglieder & Nachbarschaften, Finanzen &
--            QR-Rechnung, Vorstand & Protokolle.
--   Voll   = alles, auch die oeffentliche Website.
--
-- Was hier NICHT geschieht, ist der Kern dieser Migration: modul_aktiv()
-- bleibt, wie es ist. Ein Paket ist nur eine Voreinstellung der
-- Modulschalter, die es schon gibt (tenant_modules, alle_module_frei).
-- Was die Zeilenregeln heute sperren, sperren sie damit auch im Paket
-- Light; eine zweite Pruefung, die von der ersten abweichen koennte, gibt
-- es nicht.
--
-- Der Schalter wirkt nur auf den Verein 'demo' -- fest, nicht als
-- Parameter. Koretini hat alle_module_frei und wird nicht beruehrt.

-- 1. Die oeffentliche Website als eigenes Modul. Bisher war sie immer da.
--    Damit sich fuer keinen Verein etwas aendert, bekommt jeder bestehende
--    Verein sie als AN, und jeder kuenftige ebenso (Trigger).
INSERT INTO public.modules (schluessel, name_de, name_sq, name_en,
                            beschreibung_de, beschreibung_sq, beschreibung_en,
                            ist_kern, status, braucht_einrichtung, reihenfolge)
VALUES ('WEBSITE', 'Öffentliche Website', 'Faqja publike', 'Public website',
        'Startseite, Über uns, eigene Seiten und das Kopfmenü für Besucher.',
        'Faqja kryesore, Rreth nesh, faqe vetjake dhe menyja për vizitorët.',
        'Home page, about us, custom pages and the visitor menu.',
        false, 'VERFUEGBAR', false, 35)
ON CONFLICT (schluessel) DO NOTHING;

INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
SELECT t.id, 'WEBSITE', 'AN' FROM public.tenants t
ON CONFLICT ("tenantId", modul) DO NOTHING;

CREATE OR REPLACE FUNCTION public.website_modul_fuer_neuen_verein()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES (NEW.id, 'WEBSITE', 'AN') ON CONFLICT ("tenantId", modul) DO NOTHING;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS tenants_website_modul ON public.tenants;
CREATE TRIGGER tenants_website_modul AFTER INSERT ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.website_modul_fuer_neuen_verein();

-- 2. Paket des Demovereins.
ALTER TABLE public.demo_stand ADD COLUMN IF NOT EXISTS paket text NOT NULL DEFAULT 'VOLL'
  CHECK (paket IN ('LIGHT', 'VOLL'));

-- Wendet das Paket an. Ohne Rechtepruefung, darum nicht aufrufbar von
-- aussen -- nur aus demo_paket_setzen() und demo_zuruecksetzen().
CREATE OR REPLACE FUNCTION public._demo_paket_anwenden(p_paket text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_paket = 'LIGHT' THEN
    UPDATE public.tenants SET alle_module_frei = false WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AUS' FROM public.modules m WHERE NOT m.ist_kern
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AUS', testet_bis = NULL;
  ELSIF p_paket = 'VOLL' THEN
    UPDATE public.tenants SET alle_module_frei = true WHERE id = 'demo';
    INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    SELECT 'demo', m.schluessel, 'AN' FROM public.modules m
     WHERE NOT m.ist_kern AND m.status <> 'EINGESTELLT'
    ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AN', testet_bis = NULL;
  ELSE
    RAISE EXCEPTION 'Unbekanntes Paket: %', p_paket;
  END IF;
END $$;
REVOKE ALL ON FUNCTION public._demo_paket_anwenden(text) FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.demo_paket_setzen(p_paket text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v text := upper(coalesce(p_paket, ''));
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf das Demo-Paket wechseln.' USING ERRCODE = '42501';
  END IF;
  PERFORM public._demo_paket_anwenden(v);
  INSERT INTO public.demo_stand (id, paket) VALUES (1, v)
  ON CONFLICT (id) DO UPDATE SET paket = EXCLUDED.paket;
  RETURN v;
END $$;
REVOKE ALL ON FUNCTION public.demo_paket_setzen(text) FROM public;
GRANT EXECUTE ON FUNCTION public.demo_paket_setzen(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.demo_paket_lesen()
RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur fuer den Plattformbetreiber.' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((SELECT paket FROM public.demo_stand WHERE id = 1), 'VOLL');
END $$;
REVOKE ALL ON FUNCTION public.demo_paket_lesen() FROM public;
GRANT EXECUTE ON FUNCTION public.demo_paket_lesen() TO authenticated;

-- 3. Zuruecksetzen behaelt das gewaehlte Paket. Die Vorlage bringt die
--    Modulschalter zurueck, wie sie beim Speichern standen; ohne diesen
--    Schritt stuende der Verein danach halb in Light und halb in Voll.
DO $$
DECLARE v_def text; v_neu text;
  v_alt constant text := '  SELECT count(*) INTO v_zeilen FROM public.demo_vorlage;';
BEGIN
  SELECT pg_get_functiondef('public.demo_zuruecksetzen()'::regprocedure) INTO v_def;
  IF position('_demo_paket_anwenden' in v_def) > 0 THEN RETURN; END IF;
  IF position(v_alt in v_def) = 0 THEN
    RAISE EXCEPTION 'demo_zuruecksetzen hat sich veraendert -- Stelle zum Einfuegen nicht gefunden.';
  END IF;
  v_neu := replace(v_def, v_alt,
    E'  -- Das gewaehlte Paket gilt weiter (Light oder Voll).\n'
    '  PERFORM public._demo_paket_anwenden(coalesce((SELECT paket FROM public.demo_stand WHERE id = 1), ''VOLL''));\n\n'
    || v_alt);
  EXECUTE v_neu;
END $$;

-- 4. Selbsttest: Light sperrt Voll-Module auch in den Daten, Voll gibt alles
--    frei, Koretini bleibt unberuehrt, ein Vereinsadmin darf nicht schalten.
DO $$
DECLARE
  v_eigen text := current_user; v_admin text; v_drita text;
  v_kor_vorher text; v_kor_nachher text; v_ok boolean; n int;
BEGIN
  SELECT md5(string_agg(modul || zustand, ',' ORDER BY modul)) || (SELECT alle_module_frei::text FROM public.tenants WHERE id = 'koretini')
    INTO v_kor_vorher FROM public.tenant_modules WHERE "tenantId" = 'koretini';
  SELECT "authUserId" INTO v_drita FROM public.users WHERE "tenantId" = 'demo' AND role = 'ADMIN' AND "authUserId" IS NOT NULL LIMIT 1;

  BEGIN
    PERFORM public._demo_paket_anwenden('LIGHT');
    IF EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo' AND alle_module_frei) THEN
      RAISE EXCEPTION 'Selbsttest: Light laesst alle Module frei';
    END IF;

    IF v_drita IS NOT NULL THEN
      PERFORM set_config('request.jwt.claims', json_build_object('sub', v_drita, 'role', 'authenticated')::text, true);
      SET LOCAL ROLE authenticated;
      v_ok := public.modul_aktiv('BUCHHALTUNG') OR public.modul_aktiv('WEBSITE') OR public.modul_aktiv('ANLAESSE')
              OR NOT public.modul_aktiv('MITGLIEDER') OR NOT public.modul_aktiv('FINANZEN') OR NOT public.modul_aktiv('VORSTAND');
      SELECT count(*) INTO n FROM public.accounting_journal;
      v_ok := v_ok OR n > 0;
      -- Ein Vereinsadmin schaltet nicht selbst auf Voll.
      BEGIN PERFORM public.demo_paket_setzen('VOLL'); v_ok := true;
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
      EXECUTE format('SET LOCAL ROLE %I', v_eigen);
      IF v_ok THEN RAISE EXCEPTION 'Selbsttest: Light sperrt nicht richtig (Journal % Zeilen)', n; END IF;
    END IF;

    PERFORM public._demo_paket_anwenden('VOLL');
    IF v_drita IS NOT NULL THEN
      PERFORM set_config('request.jwt.claims', json_build_object('sub', v_drita, 'role', 'authenticated')::text, true);
      SET LOCAL ROLE authenticated;
      v_ok := public.modul_aktiv('BUCHHALTUNG') AND public.modul_aktiv('WEBSITE') AND public.modul_aktiv('ANLAESSE');
      EXECUTE format('SET LOCAL ROLE %I', v_eigen);
      IF NOT v_ok THEN RAISE EXCEPTION 'Selbsttest: Voll gibt nicht alles frei'; END IF;
    END IF;

    SELECT md5(string_agg(modul || zustand, ',' ORDER BY modul)) || (SELECT alle_module_frei::text FROM public.tenants WHERE id = 'koretini')
      INTO v_kor_nachher FROM public.tenant_modules WHERE "tenantId" = 'koretini';
    IF v_kor_nachher IS DISTINCT FROM v_kor_vorher THEN RAISE EXCEPTION 'Selbsttest: Koretini veraendert'; END IF;

    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
END $$;
