-- Der Vertreter vor Ort, zum Vorfuehren.
--
-- Was es dazu schon gibt (und was NICHT gebraucht wird):
--   * RepresentativeDashboard.tsx ist der stillgelegte Vorgaenger. Er
--     haengt an is_member_manager(), das REPRESENTATIVE nicht mehr
--     einschliesst -- er koennte nichts mehr schreiben, und benutzt
--     wurde er nie (collectedBy ist bei allen 324 Zahlungen leer).
--   * Der lebende Weg ist die NACHBARSCHAFT: /nachbarschaft mit
--     NeighborhoodStewardPanel, my_neighborhoods(), report_payment_paid()
--     und decide_payment_report(). Koretini fuehrt damit 27 Nachbarschaften.
--
-- Diese Migration baut denselben Weg im Demo-Verein nach und oeffnet ihn
-- fuer die Vorfuehrung -- eng begrenzt.

-- -------------------------------------------------------- Vertreter
-- Eine eigene Mitgliederzeile. Ohne sie gaebe es niemanden, dem die
-- Meldungen zugeschrieben werden koennten -- payment_reports."reportedBy"
-- zeigt auf users.
DELETE FROM public.users WHERE id = 'demo-v01';
INSERT INTO public.users
  (id, email, "displayName", "firstName", "lastName", role, "membershipStatus",
   "tenantId", "joinedAt", city, country)
VALUES ('demo-v01','vertreter@demo.unityhub.li','Xhevat Krasniqi','Xhevat','Krasniqi',
        'REPRESENTATIVE','ACTIVE','demo', DATE '2020-04-01', 'Koretin', 'Kosovo');

-- ---------------------------------------------------- Nachbarschaften
DELETE FROM public.neighborhoods WHERE "tenantId" = 'demo';
INSERT INTO public.neighborhoods
  (id, name, city, "tenantId", "representativeId", description, status, "contactPerson")
VALUES
 ('demo-lagje-1','Lagjja e Poshtme','Koretin','demo','demo-v01',
  'Untere Nachbarschaft, 11 Haushalte.','ACTIVE','Xhevat Krasniqi'),
 ('demo-lagje-2','Lagjja e Epërme','Koretin','demo','demo-v01',
  'Obere Nachbarschaft, 8 Haushalte.','ACTIVE','Xhevat Krasniqi'),
 ('demo-lagje-3','Lagjja e Re','Koretin','demo','demo-v01',
  'Neubaugebiet, 5 Haushalte.','ACTIVE','Xhevat Krasniqi');

-- Die Mitglieder auf die drei Nachbarschaften verteilen, damit die
-- Ansicht des Vertreters nicht leer ist.
UPDATE public.users SET "neighborhoodId" =
  CASE WHEN (right(id,2))::int % 3 = 1 THEN 'demo-lagje-1'
       WHEN (right(id,2))::int % 3 = 2 THEN 'demo-lagje-2'
       ELSE 'demo-lagje-3' END
 WHERE "tenantId" = 'demo' AND id LIKE 'demo-u%';


-- ------------------------------------------- Vorfuehrung ermoeglichen
-- Der Betreiber hat keine Mitgliederzeile, also ist
-- current_user_row_id() fuer ihn NULL und my_neighborhoods() leer. Fuer
-- die Vorfuehrung bekommt er die Nachbarschaften des Demo-Vereins --
-- und NUR dort.
--
-- Die Bedingung ist absichtlich doppelt: Betreiber UND Demo-Verein. Auf
-- demo.unityhub.li liefert current_tenant() nichts (der Betreiber hat
-- keine Zeile und keine Betreuungssitzung), deshalb zusaetzlich
-- request_tenant() -- dieselbe Konstruktion wie in
-- modul_aktiv_oeffentlich.
CREATE OR REPLACE FUNCTION public.my_neighborhoods()
RETURNS TABLE(id text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT n.id
    FROM public.neighborhoods n
   WHERE public.current_user_row_id() IS NOT NULL
     AND n."tenantId" = public.current_tenant()
     AND (
          (n."contactPersonIds" IS NOT NULL
             AND n."contactPersonIds" @> to_jsonb(public.current_user_row_id()))
       OR n."representativeId" = public.current_user_row_id()
       OR n."managerId"        = public.current_user_row_id()
     )
  UNION
  -- Nur zum Vorfuehren: der Betreiber im Demo-Verein.
  SELECT n.id
    FROM public.neighborhoods n
   WHERE n."tenantId" = 'demo'
     AND public.is_platform_admin()
     AND coalesce(public.current_tenant(), public.request_tenant()) = 'demo';
$$;
REVOKE ALL ON FUNCTION public.my_neighborhoods() FROM public;
GRANT EXECUTE ON FUNCTION public.my_neighborhoods() TO authenticated;

-- Dasselbe fuer das Melden einer Barzahlung: ohne Mitgliederzeile kein
-- "reportedBy". In der Vorfuehrung wird die Meldung dem Demo-Vertreter
-- zugeschrieben -- sichtbar und nachvollziehbar, statt anonym.
-- Die Vorgabewerte muessen mitgenommen werden: CREATE OR REPLACE darf
-- sie nicht entfernen, und drei Aufrufstellen verlassen sich darauf.
CREATE OR REPLACE FUNCTION public.report_payment_paid(
  p_payment text,
  p_method  text DEFAULT NULL::text,
  p_paid_on date DEFAULT NULL::date,
  p_note    text DEFAULT NULL::text)
RETURNS uuid
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_me     text := public.current_user_row_id();
  v_tenant text := public.current_tenant();
  v_betrag numeric;
  v_id     uuid;
BEGIN
  -- Vorfuehrung: der Betreiber meldet im Namen des Demo-Vertreters.
  IF v_me IS NULL
     AND public.is_platform_admin()
     AND coalesce(public.current_tenant(), public.request_tenant()) = 'demo' THEN
    v_me := 'demo-v01';
    v_tenant := 'demo';
  END IF;

  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT p.amount INTO v_betrag FROM public.payments p WHERE p.id = p_payment;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Rechnung gibt es nicht oder sie gehoert nicht zu Ihrer Nachbarschaft.'
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.payment_reports
    ("tenantId", "paymentId", "reportedBy", method, amount, "paidOn", note)
  VALUES (v_tenant, p_payment, v_me, p_method, v_betrag, COALESCE(p_paid_on, current_date), p_note)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.report_payment_paid(text,text,date,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.report_payment_paid(text,text,date,text) TO authenticated;


-- -------------------------------------------- Zwei offene Meldungen
-- Damit die Verwaltung in der Vorfuehrung etwas zu entscheiden hat. Eine
-- Ansicht mit null offenen Meldungen zeigt den Ablauf nicht.
DELETE FROM public.payment_reports WHERE "tenantId" = 'demo';
INSERT INTO public.payment_reports
  ("tenantId","paymentId","reportedBy",method,amount,"paidOn",note,status)
SELECT 'demo', p.id, 'demo-v01', 'CASH', p.amount, current_date - 3,
       'Bar erhalten in ' || coalesce(n.name,'Koretin') || '.', 'OPEN'
  FROM public.payments p
  LEFT JOIN public.users u ON u.id = p."userId" AND u."tenantId" = 'demo'
  LEFT JOIN public.neighborhoods n ON n.id = u."neighborhoodId"
 WHERE p."tenantId" = 'demo' AND p.status = 'PENDING'
 ORDER BY p.id
 LIMIT 2;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE n int; m int; r int; fremd int;
BEGIN
  SELECT count(*) INTO n FROM public.neighborhoods WHERE "tenantId"='demo';
  SELECT count(*) INTO m FROM public.users WHERE "tenantId"='demo' AND "neighborhoodId" IS NOT NULL;
  SELECT count(*) INTO r FROM public.payment_reports WHERE "tenantId"='demo' AND status='OPEN';

  IF n <> 3 THEN RAISE EXCEPTION 'Erwartet 3 Nachbarschaften, gefunden %.', n; END IF;
  IF m < 20 THEN RAISE EXCEPTION 'Nur % Mitglieder haben eine Nachbarschaft.', m; END IF;
  IF r <> 2 THEN RAISE EXCEPTION 'Erwartet 2 offene Meldungen, gefunden %.', r; END IF;

  -- Der Kern: die Vorfuehrungs-Ausnahme darf NUR den Demo-Verein
  -- betreffen. Gaebe sie Nachbarschaften eines echten Vereins frei,
  -- waere sie ein Leck -- und zwar eines, das erst bei einer Vorfuehrung
  -- auffiele.
  SELECT count(*) INTO fremd
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname IN ('my_neighborhoods','report_payment_paid')
     AND p.prosrc ~ 'is_platform_admin'
     AND p.prosrc !~ '''demo''';
  IF fremd > 0 THEN
    RAISE EXCEPTION 'Eine Vorfuehrungs-Ausnahme ist nicht auf den Demo-Verein begrenzt.';
  END IF;

  RAISE NOTICE 'Demo-Vertreter: % Nachbarschaften, % zugeteilte Mitglieder, % offene Meldungen', n, m, r;
END $$;
