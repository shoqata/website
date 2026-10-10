-- Der Verein stellt selbst ein, was ein Verantwortlicher darf.
--
-- Bisher stand die Liste im Ausloeser. Das war besser als nichts -- vorher
-- stand sie nur in der Maske und war damit gar keine Schranke --, aber
-- immer noch falsch: welche Felder ein Vertreter pflegen soll, weiss der
-- Verein und nicht ich. Ein Verein mit drei Nachbarschaften und einem
-- Kassier, der alles selbst macht, will etwas anderes als einer mit
-- neun Lagje in drei Kantonen.
--
-- DREI FELDER BLEIBEN GESPERRT, auch wenn es jemand einstellen wollte:
--
--   role            -- wer sich selbst befoerdern kann, ist nicht gebunden
--   neighborhoodId  -- wer Mitglieder in seine eigene Lagje ziehen kann,
--                      vergroessert damit seinen eigenen Zustaendigkeits-
--                      bereich. Das ist keine Datenpflege, das ist
--                      Rechteausweitung.
--   tenantId, authUserId, id -- Zugehoerigkeit und Identitaet.
--
-- membershipStatus steht ebenfalls nicht zur Wahl: wer jemanden auf
-- inaktiv setzt, beendet eine Mitgliedschaft. Dafuer gibt es jetzt eine
-- Meldung an den Vorstand -- dieselbe Form wie bei der Barzahlung: der
-- Vertreter meldet, der Vorstand entscheidet.

ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS vertreter_felder text[] NOT NULL DEFAULT ARRAY[
    'firstName','lastName','displayName','salutation','birthdate',
    'street','zip','city','country','address',
    'phone','phoneSecondary','email',
    'nicht_oeffentlich','sprache',
    'membershipCategory','familyId','invoiceDeliveryMethod'];

COMMENT ON COLUMN public.tenants.vertreter_felder IS
  'Welche Felder eines Mitglieds ein Nachbarschafts-Verantwortlicher aendern '
  'darf. role, neighborhoodId, membershipStatus, tenantId, authUserId und id '
  'sind nie waehlbar -- siehe vertreter_felder_setzen().';


CREATE OR REPLACE FUNCTION public.vertreter_felder_gesperrt()
RETURNS text[] LANGUAGE sql IMMUTABLE AS $$
  SELECT ARRAY['id','tenantId','authUserId','role','neighborhoodId','membershipStatus'];
$$;


CREATE OR REPLACE FUNCTION public.vertreter_felder_setzen(p_felder text[])
RETURNS text[]
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_gut text[]; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration bestimmt die Rechte der Verantwortlichen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Nur Spalten, die es gibt, und keine gesperrte. Die Pruefung steht
  -- HIER und nicht in der Maske: eine Oberflaeche, die etwas weglaesst,
  -- ist keine Schranke -- genau daran ist die erste Fassung gescheitert.
  SELECT coalesce(array_agg(DISTINCT f ORDER BY f), '{}') INTO v_gut
    FROM unnest(coalesce(p_felder, '{}')) AS f
   WHERE f = ANY (SELECT column_name FROM information_schema.columns
                   WHERE table_schema='public' AND table_name='users')
     AND NOT (f = ANY (public.vertreter_felder_gesperrt()));

  UPDATE public.tenants SET vertreter_felder = v_gut WHERE id = v_verein;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Verein % nicht gefunden.', v_verein USING ERRCODE='check_violation';
  END IF;
  RETURN v_gut;
END $$;
REVOKE ALL ON FUNCTION public.vertreter_felder_setzen(text[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vertreter_felder_setzen(text[]) TO authenticated;


-- Der Ausloeser liest jetzt die Einstellung des Vereins.
CREATE OR REPLACE FUNCTION public.vertreter_spalten_schuetzen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text; v_verboten text; v_erlaubt text[];
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF public.is_member_manager() OR public.is_platform_admin() THEN RETURN NEW; END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW; END IF;

  SELECT t.vertreter_felder INTO v_erlaubt
    FROM public.tenants t WHERE t.id = NEW."tenantId";
  v_erlaubt := coalesce(v_erlaubt, '{}');

  -- Gesperrtes bleibt gesperrt, auch wenn es jemand in die Liste
  -- geschrieben haette. Zwei Stellen, die dasselbe pruefen, laufen sonst
  -- auseinander -- diese hier ist die letzte vor der Zeile.
  SELECT string_agg(n.key, ', ' ORDER BY n.key) INTO v_verboten
    FROM jsonb_each(to_jsonb(NEW)) n
    LEFT JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
   WHERE n.value IS DISTINCT FROM o.value
     AND (NOT (n.key = ANY (v_erlaubt))
          OR n.key = ANY (public.vertreter_felder_gesperrt()));

  IF v_verboten IS NOT NULL THEN
    RAISE EXCEPTION 'Als Verantwortlicher einer Nachbarschaft koennen Sie diese Felder '
                    'nicht aendern: %. Die Vereinsadministration bestimmt, was Sie '
                    'pflegen duerfen.', v_verboten
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;


-- ------------------------------------------- Meldung an den Vorstand
--
-- Dieselbe Form wie bei der Barzahlung: der Vertreter meldet, der
-- Vorstand entscheidet. Wer jemanden auf inaktiv setzt, beendet eine
-- Mitgliedschaft -- das ist keine Datenpflege.

CREATE TABLE IF NOT EXISTS public.mitglied_meldungen (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "memberId"    text NOT NULL,
  art           text NOT NULL CHECK (art IN ('INAKTIV','VERSTORBEN','WEGGEZOGEN','SONSTIGES')),
  bemerkung     text,
  "reportedBy"  text,
  status        text NOT NULL DEFAULT 'OFFEN' CHECK (status IN ('OFFEN','UEBERNOMMEN','ABGELEHNT')),
  "decidedBy"   text,
  "decidedAt"   timestamptz,
  entscheidung  text,
  "createdAt"   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS mitglied_meldungen_offen
  ON public.mitglied_meldungen ("tenantId", status, "createdAt" DESC);


CREATE OR REPLACE FUNCTION public.mitglied_melden(
  p_member text, p_art text, p_bemerkung text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id(); v_verein text := public.current_tenant();
        v_id uuid;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE='insufficient_privilege';
  END IF;

  -- Nur ueber Mitglieder der eigenen Nachbarschaft -- und nur, wer
  -- ueberhaupt eine betreut. Die Verwaltung braucht keine Meldung, sie
  -- kann es selbst setzen.
  IF NOT EXISTS (
    SELECT 1 FROM public.users u
     WHERE u.id = p_member AND u."tenantId" = v_verein
       AND u."neighborhoodId" IN (SELECT public.my_neighborhoods())
       AND coalesce(u.role,'MEMBER') = 'MEMBER') THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert nicht zu einer Nachbarschaft, die Sie betreuen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  -- Zweimal dasselbe offen zu melden hilft niemandem.
  SELECT id INTO v_id FROM public.mitglied_meldungen
   WHERE "tenantId"=v_verein AND "memberId"=p_member AND art=p_art AND status='OFFEN';
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  INSERT INTO public.mitglied_meldungen ("tenantId","memberId",art,bemerkung,"reportedBy")
  VALUES (v_verein, p_member, p_art, nullif(btrim(coalesce(p_bemerkung,'')),''), v_ich)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.mitglied_melden(text,text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mitglied_melden(text,text,text) TO authenticated;


CREATE OR REPLACE FUNCTION public.mitglied_meldung_entscheiden(
  p_id uuid, p_uebernehmen boolean, p_notiz text DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r record; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung entscheidet ueber Meldungen.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  SELECT * INTO r FROM public.mitglied_meldungen
   WHERE id = p_id AND "tenantId" = public.current_tenant() AND status = 'OFFEN';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diese Meldung gibt es nicht oder sie ist schon entschieden.'
      USING ERRCODE='check_violation';
  END IF;

  IF p_uebernehmen THEN
    -- Uebernommen heisst: der Vorstand setzt den Status. Nicht der
    -- Vertreter, und auch nicht dieser Ausloeser hinter dessen Ruecken.
    UPDATE public.users SET "membershipStatus" = 'INACTIVE'
     WHERE id = r."memberId" AND "tenantId" = r."tenantId";
    GET DIAGNOSTICS v_n = ROW_COUNT;
    IF v_n = 0 THEN
      RAISE EXCEPTION 'Das Mitglied liess sich nicht aendern.' USING ERRCODE='check_violation';
    END IF;
  END IF;

  UPDATE public.mitglied_meldungen
     SET status = CASE WHEN p_uebernehmen THEN 'UEBERNOMMEN' ELSE 'ABGELEHNT' END,
         "decidedBy" = public.current_user_row_id(), "decidedAt" = now(),
         entscheidung = nullif(btrim(coalesce(p_notiz,'')),'')
   WHERE id = p_id;
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.mitglied_meldung_entscheiden(uuid,boolean,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mitglied_meldung_entscheiden(uuid,boolean,text) TO authenticated;


ALTER TABLE public.mitglied_meldungen ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mitglied_meldungen_lesen ON public.mitglied_meldungen;
-- Der Vorstand sieht alle, der Vertreter die eigenen.
CREATE POLICY mitglied_meldungen_lesen ON public.mitglied_meldungen FOR SELECT TO authenticated
  USING ("tenantId" = public.current_tenant()
         AND (public.is_platform_admin() OR public.is_member_manager()
              OR "reportedBy" = public.current_user_row_id()));
REVOKE ALL ON public.mitglied_meldungen FROM anon, public;
GRANT SELECT ON public.mitglied_meldungen TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_q text;
BEGIN
  -- Der Rechnungsweg muss bei jedem Verein freigeschaltet sein -- danach
  -- war ausdruecklich gefragt. Geprueft wird der WERT in den Zeilen,
  -- nicht der Spaltenstandard: der steht als Text da und sagt nichts
  -- darueber, was wirklich drinsteht.
  SELECT count(*) INTO v_n FROM public.tenants
   WHERE NOT ('invoiceDeliveryMethod' = ANY (vertreter_felder));
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Verein(e) ohne Recht am Rechnungsweg.', v_n;
  END IF;

  -- Und keine Zeile darf ein gesperrtes Feld enthalten.
  SELECT count(*) INTO v_n FROM public.tenants t
   WHERE EXISTS (SELECT 1 FROM unnest(t.vertreter_felder) f
                  WHERE f = ANY (public.vertreter_felder_gesperrt()));
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Verein(e) haben ein gesperrtes Feld in der Liste.', v_n;
  END IF;

  -- Gesperrtes darf sich NICHT einstellen lassen.
  SELECT p.prosrc INTO v_q FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='vertreter_felder_setzen';
  IF v_q !~ 'vertreter_felder_gesperrt' THEN
    RAISE EXCEPTION 'vertreter_felder_setzen prueft die Sperrliste nicht.';
  END IF;
  SELECT p.prosrc INTO v_q FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='vertreter_spalten_schuetzen';
  IF v_q !~ 'vertreter_felder_gesperrt' THEN
    RAISE EXCEPTION 'Der Ausloeser prueft die Sperrliste nicht -- eine eingetragene '
                    'gesperrte Spalte kaeme durch.';
  END IF;

  -- Keine Schreibregel auf den Meldungen.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname='public' AND tablename='mitglied_meldungen' AND cmd <> 'SELECT';
  IF v_n > 0 THEN RAISE EXCEPTION '% Schreibregel(n) auf mitglied_meldungen.', v_n; END IF;

  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon' AND table_name='mitglied_meldungen';
  IF v_n > 0 THEN RAISE EXCEPTION 'anon hat Rechte auf mitglied_meldungen.'; END IF;

  RAISE NOTICE 'Rechte einstellbar, Meldeweg steht.';
END $$;
