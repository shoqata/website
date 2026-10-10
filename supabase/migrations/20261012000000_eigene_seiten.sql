-- Eigene Seiten fuer die Vereinswebsite.
--
-- Bisher standen alle Seiten im Quelltext: /about, /events, /news,
-- /spenden, /fussball. Ein Verein, der eine Seite "Unsere Geschichte"
-- oder "Statuten" will, musste jemanden bitten, sie zu programmieren --
-- und ein zweiter Verein mit anderen Wuenschen wieder.
--
-- Drei Entscheidungen:
--
-- BLOECKE statt Freitext-HTML. Ein Textfeld, in das jemand HTML schreibt,
-- ist bequem zu bauen und ein Einfallstor: was dort steht, laeuft im
-- Browser jedes Besuchers. Bloecke haben einen festen Satz von Arten, und
-- die Darstellung entscheidet die Anwendung.
--
-- DREISPRACHIG von Anfang an. Titel und Texte sind {de, sq, en} -- loc()
-- waehlt daraus. Ein Diasporaverein, der auf Deutsch anfaengt und spaeter
-- Albanisch nachzieht, soll das koennen, ohne dass etwas umgebaut wird.
--
-- DER PFAD IST GESCHUETZT. Eine Seite "admin" oder "login" wuerde eine
-- bestehende verdecken. Die Liste steht in der Datenbank, nicht nur in
-- der Maske: eine Oberflaeche, die etwas verhindert, ist keine Schranke.

CREATE TABLE IF NOT EXISTS public.seiten (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"   text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  pfad         text NOT NULL,
  titel        jsonb NOT NULL DEFAULT '{}'::jsonb,
  bloecke      jsonb NOT NULL DEFAULT '[]'::jsonb,
  status       text NOT NULL DEFAULT 'ENTWURF' CHECK (status IN ('ENTWURF','OEFFENTLICH')),
  im_menue     boolean NOT NULL DEFAULT false,
  reihenfolge  int NOT NULL DEFAULT 100,
  erstellt_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_am timestamptz NOT NULL DEFAULT now(),
  geaendert_von text,
  UNIQUE ("tenantId", pfad)
);
CREATE INDEX IF NOT EXISTS seiten_menue
  ON public.seiten ("tenantId", status, im_menue, reihenfolge);

COMMENT ON COLUMN public.seiten.bloecke IS
  'Liste von Bausteinen: {art, ...}. Arten: ueberschrift, text, bild, '
  'knopf, trenner, zitat. Kein freies HTML -- was im Browser des '
  'Besuchers laeuft, entscheidet die Anwendung, nicht der Inhalt.';


-- Pfade, die es schon gibt oder die reserviert sind.
CREATE OR REPLACE FUNCTION public.pfad_belegt(p_pfad text)
RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(btrim(coalesce(p_pfad,''))) = ANY (ARRAY[
    '', 'about', 'live', 'events', 'news', 'fussball', 'futsal', 'spenden',
    'videos', 'gdpr', 'privacy', 'login', 'register', 'dashboard', 'admin',
    'super-admin', 'nachbarschaft', 'setup-profile', 'revision', 'treffen',
    'vorstellen', 'heft', 'drucksachen', 'api', 'assets', 'static']);
$$;


CREATE OR REPLACE FUNCTION public.seite_speichern(
  p_id uuid, p_pfad text, p_titel jsonb, p_bloecke jsonb,
  p_status text, p_im_menue boolean, p_reihenfolge int)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_pfad text; v_id uuid; v_wer text;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf Seiten bearbeiten.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Der Pfad wird hier gebildet, nicht in der Maske: Umlaute, Leerzeichen
  -- und Schraegstriche in einer URL sind eine Fehlerquelle, die niemand
  -- sucht, wenn sie erst beim Besucher auffaellt.
  v_pfad := lower(btrim(coalesce(p_pfad, '')));
  v_pfad := translate(v_pfad, 'äöüàéèêçë', 'aouaeeece');
  v_pfad := regexp_replace(v_pfad, '[^a-z0-9]+', '-', 'g');
  v_pfad := btrim(v_pfad, '-');
  IF v_pfad = '' THEN
    RAISE EXCEPTION 'Die Seite braucht eine Adresse.' USING ERRCODE = 'check_violation';
  END IF;
  IF public.pfad_belegt(v_pfad) THEN
    RAISE EXCEPTION 'Die Adresse "%" ist bereits vergeben -- sie wuerde eine bestehende Seite verdecken.', v_pfad
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT u."displayName" INTO v_wer FROM public.users u
   WHERE u.id = public.current_user_row_id();

  IF p_id IS NULL THEN
    INSERT INTO public.seiten ("tenantId", pfad, titel, bloecke, status, im_menue,
                               reihenfolge, geaendert_von)
    VALUES (v_verein, v_pfad, coalesce(p_titel,'{}'::jsonb), coalesce(p_bloecke,'[]'::jsonb),
            coalesce(p_status,'ENTWURF'), coalesce(p_im_menue,false),
            coalesce(p_reihenfolge,100), v_wer)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.seiten SET
      pfad = v_pfad, titel = coalesce(p_titel, titel), bloecke = coalesce(p_bloecke, bloecke),
      status = coalesce(p_status, status), im_menue = coalesce(p_im_menue, im_menue),
      reihenfolge = coalesce(p_reihenfolge, reihenfolge),
      geaendert_am = now(), geaendert_von = v_wer
     WHERE id = p_id AND "tenantId" = v_verein
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Diese Seite gehoert nicht zu Ihrem Verein.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  RETURN v_id;
END $$;
REVOKE ALL ON FUNCTION public.seite_speichern(uuid, text, jsonb, jsonb, text, boolean, int)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.seite_speichern(uuid, text, jsonb, jsonb, text, boolean, int)
  TO authenticated;


CREATE OR REPLACE FUNCTION public.seite_loeschen(p_id uuid)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD')) THEN
    RAISE EXCEPTION 'Nur Vorstand oder Verwaltung darf Seiten loeschen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  DELETE FROM public.seiten WHERE id = p_id AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Seite gehoert nicht zu Ihrem Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION public.seite_loeschen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.seite_loeschen(uuid) TO authenticated;


-- ---------------------------------------------------------- Zeilenregeln
ALTER TABLE public.seiten ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS seiten_oeffentlich ON public.seiten;
-- Besucher sehen VEROEFFENTLICHTE Seiten ihres Vereins. Die Domain
-- bestimmt den Verein (request_tenant); ein Entwurf bleibt unsichtbar.
CREATE POLICY seiten_oeffentlich ON public.seiten FOR SELECT TO anon
  USING (status = 'OEFFENTLICH' AND "tenantId" = public.request_tenant());

DROP POLICY IF EXISTS seiten_intern ON public.seiten;
CREATE POLICY seiten_intern ON public.seiten FOR SELECT TO authenticated
  USING (status = 'OEFFENTLICH'
         OR ("tenantId" = public.current_tenant()
             AND (public.is_platform_admin() OR public.is_staff())));

REVOKE ALL ON public.seiten FROM anon, public;
GRANT SELECT ON public.seiten TO anon, authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int;
BEGIN
  -- Keine Schreibregel: alles laeuft ueber die Funktionen, sonst koennte
  -- jemand den Pfad an der Pruefung vorbei setzen.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname='public' AND tablename='seiten' AND cmd <> 'SELECT';
  IF v_n > 0 THEN RAISE EXCEPTION '% Schreibregel(n) auf seiten.', v_n; END IF;

  -- anon darf nur lesen, und nur Veroeffentlichtes.
  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon' AND table_name='seiten'
     AND privilege_type <> 'SELECT';
  IF v_n > 0 THEN RAISE EXCEPTION 'anon hat Schreibrechte auf seiten.'; END IF;

  -- Die Pfadsperre muss greifen, sonst verdeckt eine Seite die Verwaltung.
  IF NOT public.pfad_belegt('admin') OR NOT public.pfad_belegt('ADMIN ')
     OR NOT public.pfad_belegt('login') THEN
    RAISE EXCEPTION 'Die Pfadsperre greift nicht.';
  END IF;
  IF public.pfad_belegt('unsere-geschichte') THEN
    RAISE EXCEPTION 'Die Pfadsperre ist zu streng -- sie verbietet gewoehnliche Namen.';
  END IF;

  RAISE NOTICE 'Eigene Seiten bereit. Entwuerfe sind fuer Besucher unsichtbar.';
END $$;
