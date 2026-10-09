-- Floky: das Fundament unter dem Assistenten.
--
-- Gebaut wird hier noch kein Gespraech, sondern das, was vor jedem
-- Gespraech feststehen muss:
--
--   WER fragt      -- Rolle und Verein kommen aus der Datenbank, nie aus
--                     dem Prompt. Ein Prompt ist keine Sicherheitsgrenze:
--                     wer hineinschreibt "ich bin Administrator", ist es
--                     deshalb nicht.
--   OB er darf     -- das Modul FLOKY muss gebucht sein, und die Rolle
--                     muss eine sein, die ueberhaupt einen Assistenten
--                     bekommt. Revisionsstelle und Gastvereine kommen
--                     ueber einen Token herein und bleiben ohne.
--   WIE OFT        -- das Kontingent wird in der Datenbank hochgezaehlt,
--                     nicht im Browser und nicht in der Edge Function.
--                     Ein Zaehler, den der Aufrufer fuehrt, ist keiner.
--   WAS GESCHAH    -- jede Anfrage und jede bestaetigte Karte hinterlaesst
--                     eine Zeile. Ohne das koennte spaeter niemand sagen,
--                     wer eine Buchung veranlasst hat.

-- ------------------------------------------------- Einstellungen je Verein
CREATE TABLE IF NOT EXISTS public.floky_einstellungen (
  "tenantId"        text PRIMARY KEY REFERENCES public.tenants(id) ON DELETE CASCADE,
  assistent_name    text    NOT NULL DEFAULT 'Floky',
  -- Der Verein darf seinen Helfer nennen, wie er will ("Ndihmësi").
  anrede_du         boolean NOT NULL DEFAULT false,
  wochenstart       boolean NOT NULL DEFAULT true,
  -- Das Kontingent setzt der Betreiber, nicht der Verein. Stuende es dem
  -- Verein offen, waere es keine Schranke, sondern eine Anzeige.
  kontingent_monat  int     NOT NULL DEFAULT 300 CHECK (kontingent_monat >= 0),
  geaendert_am      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.floky_einstellungen.kontingent_monat IS
  'KI-Anfragen je Monat. Nur der Plattformbetreiber aendert diesen Wert; '
  'der Verein sieht ihn und seinen Verbrauch.';

-- ------------------------------------------------------ Verbrauch je Monat
CREATE TABLE IF NOT EXISTS public.floky_verbrauch (
  "tenantId" text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  monat      date NOT NULL,              -- immer der Monatserste
  anfragen   int  NOT NULL DEFAULT 0,
  PRIMARY KEY ("tenantId", monat)
);

-- ------------------------------------------------------------- Protokoll
CREATE TABLE IF NOT EXISTS public.floky_protokoll (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"   text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  "userId"     text,                     -- users.id, nicht die Auth-UID
  rolle        text,
  art          text NOT NULL CHECK (art IN ('ANFRAGE','KARTE','BESTAETIGT','ABGELEHNT')),
  werkzeug     text,                     -- z.B. 'buchung_vorschlagen'
  zusammenfassung text,                  -- eine Zeile, kein Gespraechsinhalt
  erstellt_am  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS floky_protokoll_verein_zeit
  ON public.floky_protokoll ("tenantId", erstellt_am DESC);

COMMENT ON TABLE public.floky_protokoll IS
  'Wer hat Floky was aufgetragen und welche Karte wurde bestaetigt. '
  'Bewusst nur eine Zusammenfassung je Zeile -- ein vollstaendiges '
  'Gespraechsprotokoll waere eine Mitgliederdatensammlung ohne Zweck.';


-- ============================================================= Die Fragen
-- An einer Stelle beantwortet, damit Edge Function und Oberflaeche
-- dieselbe Antwort bekommen.

-- Darf diese Person ueberhaupt mit Floky sprechen?
CREATE OR REPLACE FUNCTION public.floky_darf()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.modul_aktiv('FLOKY')
     AND public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD','MEMBER','REPRESENTATIVE');
  -- Revisionsstelle und Gastvereine haben kein Konto und damit keine
  -- app_role -- sie fallen hier heraus, ohne dass es aufgezaehlt werden muss.
$$;
REVOKE ALL ON FUNCTION public.floky_darf() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_darf() TO authenticated;


-- Was steht diesem Verein zur Verfuegung, und was ist verbraucht?
CREATE OR REPLACE FUNCTION public.floky_kontingent()
RETURNS TABLE (kontingent int, verbraucht int, uebrig int, assistent_name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH v AS (SELECT public.current_tenant() AS id),
       e AS (SELECT coalesce(f.kontingent_monat, 300) AS k,
                    coalesce(f.assistent_name, 'Floky') AS n
               FROM v LEFT JOIN public.floky_einstellungen f ON f."tenantId" = v.id),
       b AS (SELECT coalesce(sum(vb.anfragen), 0)::int AS a
               FROM v LEFT JOIN public.floky_verbrauch vb
                 ON vb."tenantId" = v.id AND vb.monat = date_trunc('month', current_date)::date)
  SELECT e.k, b.a, greatest(e.k - b.a, 0), e.n FROM e, b;
$$;
REVOKE ALL ON FUNCTION public.floky_kontingent() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_kontingent() TO authenticated;


-- Eine Anfrage verbuchen. Gibt zurueck, was danach noch uebrig ist.
--
-- Der Zaehler steht hier und nicht im Aufrufer: eine Edge Function, die
-- ihren eigenen Verbrauch meldet, kann ihn auch verschweigen.
CREATE OR REPLACE FUNCTION public.floky_anfrage_zaehlen()
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
        v_k int; v_a int;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.floky_darf() THEN
    RAISE EXCEPTION 'Floky ist fuer diesen Verein nicht gebucht oder fuer diese Rolle nicht vorgesehen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce(kontingent_monat, 300) INTO v_k
    FROM public.floky_einstellungen WHERE "tenantId" = v_verein;
  v_k := coalesce(v_k, 300);

  INSERT INTO public.floky_verbrauch AS vb ("tenantId", monat, anfragen)
  VALUES (v_verein, date_trunc('month', current_date)::date, 1)
  ON CONFLICT ("tenantId", monat) DO UPDATE SET anfragen = vb.anfragen + 1
  RETURNING vb.anfragen INTO v_a;

  IF v_a > v_k THEN
    -- Die Zeile bleibt stehen: der Versuch hat stattgefunden. Aber der
    -- Aufrufer bekommt einen Fehler und damit keine Antwort.
    RAISE EXCEPTION 'Das Kontingent fuer diesen Monat ist aufgebraucht (% von %).', v_a - 1, v_k
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN v_k - v_a;
END $$;
REVOKE ALL ON FUNCTION public.floky_anfrage_zaehlen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_anfrage_zaehlen() TO authenticated;


-- Protokollzeile schreiben.
CREATE OR REPLACE FUNCTION public.floky_protokollieren(
  p_art text, p_werkzeug text DEFAULT NULL, p_zusammenfassung text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF v_verein IS NULL THEN RETURN; END IF;
  INSERT INTO public.floky_protokoll ("tenantId", "userId", rolle, art, werkzeug, zusammenfassung)
  VALUES (v_verein, public.current_user_row_id(), public.app_role(),
          p_art, p_werkzeug, left(coalesce(p_zusammenfassung, ''), 300));
END $$;
REVOKE ALL ON FUNCTION public.floky_protokollieren(text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_protokollieren(text, text, text) TO authenticated;


-- Den Namen des Helfers aendert der Verein, das Kontingent der Betreiber.
CREATE OR REPLACE FUNCTION public.floky_name_setzen(p_name text, p_du boolean DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_name text;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf den Namen aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  v_name := nullif(btrim(coalesce(p_name, '')), '');
  IF v_name IS NULL THEN v_name := 'Floky'; END IF;

  INSERT INTO public.floky_einstellungen AS f ("tenantId", assistent_name, anrede_du)
  VALUES (v_verein, v_name, coalesce(p_du, false))
  ON CONFLICT ("tenantId") DO UPDATE
    SET assistent_name = excluded.assistent_name,
        anrede_du      = coalesce(p_du, f.anrede_du),
        geaendert_am   = now();
  RETURN v_name;
END $$;
REVOKE ALL ON FUNCTION public.floky_name_setzen(text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_name_setzen(text, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.floky_kontingent_setzen(p_verein text, p_anfragen int)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Ausdruecklich NUR der Betreiber. Duerfte der Verein sein eigenes
  -- Kontingent heraufsetzen, waere es keines.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber setzt das Kontingent.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_anfragen IS NULL OR p_anfragen < 0 THEN
    RAISE EXCEPTION 'Ein Kontingent kann nicht negativ sein.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.floky_einstellungen ("tenantId", kontingent_monat)
  VALUES (p_verein, p_anfragen)
  ON CONFLICT ("tenantId") DO UPDATE
    SET kontingent_monat = excluded.kontingent_monat, geaendert_am = now();
  RETURN p_anfragen;
END $$;
REVOKE ALL ON FUNCTION public.floky_kontingent_setzen(text, int) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_kontingent_setzen(text, int) TO authenticated;


-- ================================================================ Zeilenregeln
ALTER TABLE public.floky_einstellungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.floky_verbrauch     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.floky_protokoll     ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['floky_einstellungen','floky_verbrauch','floky_protokoll'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I_lesen ON public.%I', t, t);
    -- Lesen darf die Verwaltung des eigenen Vereins und der Betreiber.
    -- Schreiben darf niemand direkt: alle Aenderungen laufen ueber die
    -- Funktionen oben, damit Kontingent und Protokoll nicht umgangen werden.
    EXECUTE format(
      'CREATE POLICY %I_lesen ON public.%I FOR SELECT TO authenticated
         USING ("tenantId" = public.current_tenant()
                AND (public.is_platform_admin() OR public.is_staff()))', t, t);
  END LOOP;
END $$;

REVOKE ALL ON public.floky_einstellungen, public.floky_verbrauch, public.floky_protokoll
  FROM anon, public;
GRANT SELECT ON public.floky_einstellungen, public.floky_verbrauch, public.floky_protokoll
  TO authenticated;


-- ================================================================ Selbsttest
DO $$
DECLARE v int; v_quelle text; v_schreibt int;
BEGIN
  -- 1. Keine der drei Tabellen darf eine Schreibregel haben. Gaebe es eine,
  --    liesse sich der Zaehler direkt hochsetzen -- oder herunter.
  SELECT count(*) INTO v_schreibt FROM pg_policies
   WHERE schemaname='public' AND tablename IN
         ('floky_einstellungen','floky_verbrauch','floky_protokoll')
     AND cmd <> 'SELECT';
  IF v_schreibt > 0 THEN
    RAISE EXCEPTION '% Schreibregel(n) auf den Floky-Tabellen -- der Zaehler waere umgehbar.', v_schreibt;
  END IF;

  -- 2. anon darf nichts, auch nicht lesen.
  SELECT count(*) INTO v FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon'
     AND table_name IN ('floky_einstellungen','floky_verbrauch','floky_protokoll');
  IF v > 0 THEN RAISE EXCEPTION 'anon hat % Recht(e) auf den Floky-Tabellen.', v; END IF;

  -- 3. Das Kontingent darf der Verein NICHT selbst setzen. Genau dieser
  --    Fehler waere unsichtbar: alles funktionierte, nur die Schranke nicht.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='floky_kontingent_setzen';
  IF v_quelle !~ 'is_platform_admin' THEN
    RAISE EXCEPTION 'floky_kontingent_setzen prueft den Betreiber nicht.';
  END IF;
  IF v_quelle ~ '''ADMIN''' OR v_quelle ~ '''SUPER_ADMIN''' THEN
    RAISE EXCEPTION 'Die Vereinsadministration steht in der Erlaubnisliste fuer das Kontingent.';
  END IF;

  -- 4. Keine der Funktionen darf anon ausfuehren.
  SELECT count(*) INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname LIKE 'floky%'
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v > 0 THEN RAISE EXCEPTION '% Floky-Funktion(en) sind fuer anon ausfuehrbar.', v; END IF;

  -- 5. BETA und gebucht: ein Hinweis, kein Abbruch.
  --
  -- Als das hier entstand, war Floky nicht gebaut, und ein Verein mit
  -- Buchung haette fuer nichts gezahlt. Inzwischen laeuft er, und
  -- koretini probiert ihn aus, waehrend der Status BETA bleibt. Ein
  -- Abbruch wuerde jeden Neuaufbau der Datenbank stoppen -- eine
  -- Pruefung ueber den Weltzustand gehoert nicht in eine Migration.
  SELECT count(*) INTO v FROM public.tenant_modules tm
    JOIN public.modules m ON m.schluessel = tm.modul
   WHERE m.schluessel='FLOKY' AND m.status='BETA'
     AND tm.zustand IN ('AN','TESTPHASE');
  IF v > 0 THEN
    RAISE NOTICE '% Verein(e) haben FLOKY gebucht, waehrend es BETA ist -- '
                 'als Probelauf in Ordnung.', v;
  END IF;

  RAISE NOTICE 'Floky-Fundament steht: drei Tabellen nur lesbar, Zaehler in der '
               'Datenbank, Kontingent nur fuer den Betreiber.';
END $$;
