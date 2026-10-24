-- Briefe, die am Guthaben haengen geblieben sind, gehen nach einem Kauf
-- von selbst weiter.
--
-- Der Arbeiter setzte sie auf PROBLEM ("Kontingent aufgebraucht ... geht
-- hinaus, sobald Guthaben da ist") -- holte aber nur WARTEND ab. Der
-- Hinweis versprach etwas, das nie geschah. Jetzt: jede Gutschrift oder
-- jeder Kauf stellt diese Briefe des Vereins zurueck auf WARTEND. Andere
-- Probleme (PDF, Adresse) bleiben, wo sie sind -- die verlangen eine
-- Handlung, kein Guthaben.

CREATE OR REPLACE FUNCTION public.post_guthaben_weiter()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.post_ausgang
     SET zustand = 'WARTEND', naechster_versuch = now(),
         pingen_status = NULL, pingen_meldung = NULL
   WHERE "tenantId" = NEW."tenantId" AND zustand = 'PROBLEM'
     AND (pingen_status = 'ohne_guthaben' OR pingen_meldung LIKE 'Kontingent aufgebraucht%');
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS post_kontingent_weiter ON public.post_kontingent;
CREATE TRIGGER post_kontingent_weiter AFTER INSERT ON public.post_kontingent
  FOR EACH ROW WHEN (NEW.menge > 0) EXECUTE FUNCTION public.post_guthaben_weiter();

-- Fuer den Dialog vor dem Aufgeben: Guthaben, was schon wartet (noch nicht
-- abgebucht), Preis, und ob der Aufrufer kaufen darf.
CREATE OR REPLACE FUNCTION public.post_guthaben_vor_versand()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_stand jsonb; v_wartet int;
BEGIN
  IF NOT public.is_member_manager() OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  v_stand := public.post_kontingent_stand();
  SELECT count(*) INTO v_wartet FROM public.post_ausgang a
   WHERE a."tenantId" = v_verein
     AND (a.zustand = 'WARTEND'
          OR (a.zustand = 'PROBLEM' AND (a.pingen_status = 'ohne_guthaben'
                                         OR a.pingen_meldung LIKE 'Kontingent aufgebraucht%')))
     AND NOT EXISTS (SELECT 1 FROM public.post_kontingent k WHERE k."postId" = a.id);
  RETURN v_stand || jsonb_build_object(
    'wartet', v_wartet,
    'frei', greatest((v_stand ->> 'stand')::int - v_wartet, 0),
    'darf_kaufen', public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN', 'ADMIN'));
END $$;
REVOKE ALL ON FUNCTION public.post_guthaben_vor_versand() FROM public;
GRANT EXECUTE ON FUNCTION public.post_guthaben_vor_versand() TO authenticated;

-- Demo: ein Briefpreis, damit man in der Vorfuehrung Guthaben kaufen kann.
-- Die Rechnung dazu ist eine Plattformrechnung an den Demoverein (Entwurf).
INSERT INTO public.post_preise ("tenantId", einkauf_je_brief, preis_fest, waehrung, geaendert_von)
SELECT 'demo', 1.20, 1.80, 'CHF', 'migration'
 WHERE EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo')
ON CONFLICT ("tenantId") DO NOTHING;

DO $$
DECLARE v_betreiber text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = 'demo') THEN RETURN; END IF;
  SELECT email INTO v_betreiber FROM public.platform_admins LIMIT 1;
  PERFORM set_config('request.jwt.claims', json_build_object('email', v_betreiber, 'role', 'authenticated')::text, true);
  PERFORM public.demo_vorlage_speichern();
  PERFORM set_config('request.jwt.claims', '', true);
END $$;

-- Selbsttest: haengender Brief geht nach Gutschrift weiter. Zurueckgerollt.
DO $$
DECLARE v_id uuid; v_z text;
BEGIN
  BEGIN
    INSERT INTO public.post_ausgang ("tenantId","paymentId","memberId",empfaenger,dateiname,pdf,zustand,pingen_status,pingen_meldung)
    SELECT 'demo', p.id, p."userId", 'Selbsttest', 't.pdf', 'x', 'PROBLEM', 'ohne_guthaben', 'Kontingent aufgebraucht — Test'
      FROM public.payments p WHERE p."tenantId" = 'demo' LIMIT 1 RETURNING id INTO v_id;
    IF v_id IS NULL THEN RAISE EXCEPTION 'SELBSTTEST_OK'; END IF;
    INSERT INTO public.post_kontingent ("tenantId", art, menge, grund) VALUES ('demo', 'GUTSCHRIFT', 1, 'Selbsttest');
    SELECT zustand INTO v_z FROM public.post_ausgang WHERE id = v_id;
    IF v_z <> 'WARTEND' THEN RAISE EXCEPTION 'Selbsttest: Brief haengt weiter (%)', v_z; END IF;
    RAISE EXCEPTION 'SELBSTTEST_OK';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SELBSTTEST_OK' THEN RAISE; END IF;
  END;
END $$;
