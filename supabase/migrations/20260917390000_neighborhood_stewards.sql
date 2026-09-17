-- Verantwortliche Person einer Nachbarschaft.
--
-- Bisher hing alles an is_member_manager(), und dort standen auch
-- REPRESENTATIVE und NEIGHBORHOOD_MANAGER. Ueber diese eine Funktion laufen
-- 23 Regeln: wer sie erfuellt, kommt an Buchhaltung, Budgets,
-- Vorstandssitzungen, Sicherheitsprotokolle, Sponsoren, Aufgaben -- und darf
-- alle 324 Zahlungen des Vereins anlegen, aendern und loeschen. Fuer jemanden,
-- der eine Nachbarschaft betreut, ist das um ein Vielfaches zu viel.
--
-- Die Betreuung wird deshalb nicht mehr an der Rolle festgemacht, sondern an
-- der Zuordnung: verantwortlich ist, wer in der Nachbarschaft als
-- verantwortliche Person hinterlegt ist. Das ist dieselbe Stelle, an der die
-- Administration sie ohnehin eintraegt, und es wirkt unabhaengig davon, welche
-- Rollenbezeichnung jemand traegt.

-- ------------------------------------------------- Welche Nachbarschaften?
-- Neben contactPersonIds werden die beiden aelteren Felder mitgelesen. In
-- vieren der 27 Nachbarschaften stehen dort noch Platzhalter aus der
-- Erstbefuellung (rep-user-1 und aehnliche); die treffen auf keine Zeile in
-- users und gehen daher ins Leere, statt jemandem Rechte zu geben.
CREATE OR REPLACE FUNCTION public.my_neighborhoods()
RETURNS SETOF text
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
$$;

CREATE OR REPLACE FUNCTION public.is_neighborhood_steward()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.my_neighborhoods())
$$;

GRANT EXECUTE ON FUNCTION public.my_neighborhoods() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_neighborhood_steward() TO authenticated;

-- ------------------------------------------- is_member_manager() einengen
-- Ab hier bedeutet die Funktion, was ihr Name sagt: die Geschaeftsfuehrung des
-- Vereins. Die beiden Betreuungsrollen verlieren damit in einem Zug den
-- Zugriff auf Buchhaltung, Budgets, Sitzungen, Protokolle und Sponsoren.
--
-- Nachgesehen, bevor das geschieht: die Kassen-Ansicht der Vertreter wurde nie
-- zum Einzug benutzt -- collectedBy ist bei allen 324 Zahlungen leer.
CREATE OR REPLACE FUNCTION public.is_member_manager()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.app_role() IN ('SUPER_ADMIN', 'ADMIN', 'BOARD')
$$;

-- --------------------------------------------------- Mitglieder der Betreuung
-- Lesen: die eigene Nachbarschaft, nichts darueber hinaus.
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
  USING (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR (public.is_neighborhood_steward()
        AND "tenantId" = public.current_tenant()
        AND "neighborhoodId" IN (SELECT public.my_neighborhoods()))
    OR id = auth.uid()::text
    OR "authUserId" = auth.uid()::text
    OR (auth.jwt() ->> 'email' IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
  );

-- Aendern: Adressen und Erreichbarkeit der eigenen Leute.
--
-- Die Rolle bleibt aussen vor. Beide Bedingungen verlangen MEMBER: die alte
-- Zeile muss es sein, damit niemand einen Vorstand bearbeitet, und die neue
-- muss es bleiben, damit sich niemand selbst oder andere hochstuft. Ebenso
-- muss die Nachbarschaft der neuen Zeile weiterhin eine betreute sein --
-- sonst liesse sich jemand aus der eigenen Zustaendigkeit fortschreiben.
DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
  USING (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR (public.is_neighborhood_steward()
        AND "tenantId" = public.current_tenant()
        AND "neighborhoodId" IN (SELECT public.my_neighborhoods())
        AND COALESCE(role, 'MEMBER') = 'MEMBER')
    OR id = auth.uid()::text
    OR "authUserId" = auth.uid()::text
  )
  WITH CHECK (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR (public.is_neighborhood_steward()
        AND "tenantId" = public.current_tenant()
        AND "neighborhoodId" IN (SELECT public.my_neighborhoods())
        AND COALESCE(role, 'MEMBER') = 'MEMBER')
    OR ((id = auth.uid()::text OR "authUserId" = auth.uid()::text)
        AND COALESCE(role, 'MEMBER') = COALESCE(public.app_role(), 'MEMBER'))
  );

-- Anlegen bleibt der Geschaeftsfuehrung vorbehalten; der Selbst-Zweig fuer
-- echte Neuanmeldungen bleibt unveraendert bestehen.
DROP POLICY IF EXISTS users_insert ON public.users;
CREATE POLICY users_insert ON public.users FOR INSERT TO authenticated
  WITH CHECK (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR (id = auth.uid()::text
        AND COALESCE(role, 'MEMBER') = ANY (ARRAY[public.claimable_role(), 'MEMBER']))
  );

-- ------------------------------------------------------------ Rechnungen
-- Lesen ja, schreiben nein.
--
-- Die Zuordnung laeuft ueber das Mitglied, nicht ueber payments.neighborhoodId
-- -- dieses Feld ist nur bei 3 von 324 Zahlungen gefuellt und waere als
-- Grundlage wertlos.
DROP POLICY IF EXISTS payments_read ON public.payments;
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
  USING (
    (public.is_member_manager() AND "tenantId" = public.current_tenant())
    OR "userId" = public.current_user_row_id()
    OR (public.is_neighborhood_steward()
        AND "tenantId" = public.current_tenant()
        AND "userId" IN (SELECT u.id FROM public.users u
                          WHERE u."neighborhoodId" IN (SELECT public.my_neighborhoods())))
  );
-- payments_write bleibt unangetastet und meint jetzt nur noch die
-- Geschaeftsfuehrung -- der Status einer Rechnung ist damit fuer die Betreuung
-- unerreichbar.

NOTIFY pgrst, 'reload schema';
