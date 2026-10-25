-- Generalversammlung von A bis Z: Traktanden, Einladung an alle, Praesenz
-- mit Beschlussfaehigkeit, Abstimmungsergebnisse, Protokoll und Versand.
--
-- Abgestimmt wird im Saal (Handzeichen). Die Plattform haelt Ergebnisse
-- fest; eine Online-Abstimmung ist bewusst nicht dabei -- sie braeuchte
-- eine Identitaetspruefung, die ein Verein nicht leisten kann.
--
-- Schreiben: Verwaltung und Vorstand (is_member_manager + darf_schreiben).
-- Lesen: dieselben. Mitglieder bekommen Einladung und Protokoll per E-Mail.

CREATE TABLE IF NOT EXISTS public.versammlungen (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"   text NOT NULL,
  titel        text NOT NULL CHECK (btrim(titel) <> ''),
  datum        date NOT NULL,
  zeit         text,
  ort          text,
  traktanden   jsonb NOT NULL DEFAULT '[]',   -- [{titel, abstimmung, ja, nein, enthaltung, beschluss}]
  quorum_prozent integer NOT NULL DEFAULT 0 CHECK (quorum_prozent BETWEEN 0 AND 100),
  status       text NOT NULL DEFAULT 'ENTWURF' CHECK (status IN ('ENTWURF','EINGELADEN','DURCHGEFUEHRT','ABGESCHLOSSEN')),
  protokoll    text,
  eingeladen_am timestamptz,
  protokoll_versandt_am timestamptz,
  erstellt_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_am timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS versammlungen_verein ON public.versammlungen ("tenantId", datum DESC);

CREATE TABLE IF NOT EXISTS public.versammlung_praesenz (
  versammlung uuid NOT NULL REFERENCES public.versammlungen(id) ON DELETE CASCADE,
  mitglied    text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  "tenantId"  text NOT NULL,
  anwesend    boolean NOT NULL DEFAULT true,
  erfasst_am  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (versammlung, mitglied)
);

ALTER TABLE public.versammlungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.versammlung_praesenz ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versammlungen FROM anon, authenticated, public;
REVOKE ALL ON public.versammlung_praesenz FROM anon, authenticated, public;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.versammlungen TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.versammlung_praesenz TO authenticated;

CREATE POLICY versammlungen_lesen ON public.versammlungen FOR SELECT TO authenticated
  USING ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()));
CREATE POLICY versammlungen_schreiben ON public.versammlungen FOR ALL TO authenticated
  USING ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()) AND (SELECT public.darf_schreiben()))
  WITH CHECK ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()) AND (SELECT public.darf_schreiben()));
CREATE POLICY praesenz_lesen ON public.versammlung_praesenz FOR SELECT TO authenticated
  USING ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()));
CREATE POLICY praesenz_schreiben ON public.versammlung_praesenz FOR ALL TO authenticated
  USING ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()) AND (SELECT public.darf_schreiben()))
  WITH CHECK ("tenantId" = (SELECT public.current_tenant()) AND (SELECT public.is_member_manager()) AND (SELECT public.darf_schreiben())
              AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = mitglied AND u."tenantId" = versammlung_praesenz."tenantId"));

-- Verein setzen, Zeitstempel nachfuehren.
CREATE OR REPLACE FUNCTION public.versammlungen_vorbereiten()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN NEW."tenantId" := public.current_tenant(); END IF;
  IF TG_OP = 'UPDATE' THEN NEW.geaendert_am := now(); END IF;
  IF jsonb_typeof(NEW.traktanden) <> 'array' OR jsonb_array_length(NEW.traktanden) > 40 THEN
    RAISE EXCEPTION 'Hoechstens 40 Traktanden.';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS versammlungen_vorbereiten_trg ON public.versammlungen;
CREATE TRIGGER versammlungen_vorbereiten_trg BEFORE INSERT OR UPDATE ON public.versammlungen
  FOR EACH ROW EXECUTE FUNCTION public.versammlungen_vorbereiten();

CREATE OR REPLACE FUNCTION public.praesenz_vorbereiten()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW."tenantId" IS NULL OR btrim(NEW."tenantId") = '' THEN NEW."tenantId" := public.current_tenant(); END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS praesenz_vorbereiten_trg ON public.versammlung_praesenz;
CREATE TRIGGER praesenz_vorbereiten_trg BEFORE INSERT ON public.versammlung_praesenz
  FOR EACH ROW EXECUTE FUNCTION public.praesenz_vorbereiten();

-- An alle aktiven Mitglieder mit brauchbarer E-Mail versenden.
-- p_art: EINLADUNG oder PROTOKOLL. Der Text kommt fertig aus der Oberflaeche;
-- die Funktion bestimmt nur die Empfaenger -- die stehen nicht im Browser.
CREATE OR REPLACE FUNCTION public.versammlung_versenden(p_id uuid, p_art text, p_betreff text, p_html text, p_text text)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v public.versammlungen; v_n integer; v_wer text;
BEGIN
  IF NOT public.is_member_manager() OR NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_art NOT IN ('EINLADUNG','PROTOKOLL') OR coalesce(btrim(p_betreff),'') = '' OR length(coalesce(p_html,'')) > 200000 THEN
    RAISE EXCEPTION 'Ungueltiger Versand.' USING ERRCODE = 'check_violation';
  END IF;
  SELECT * INTO v FROM public.versammlungen WHERE id = p_id AND "tenantId" = public.current_tenant();
  IF v.id IS NULL THEN RAISE EXCEPTION 'Versammlung nicht gefunden.'; END IF;
  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, text, kind, "memberId", absender_name)
  SELECT v."tenantId", u.email, p_betreff, p_html, p_text, 'GV_' || p_art, u.id, v_wer
    FROM public.users u
   WHERE u."tenantId" = v."tenantId"
     AND coalesce(u."membershipStatus", '') <> 'INACTIVE'
     AND u.email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     AND u.email NOT ILIKE '%.legacy';
  GET DIAGNOSTICS v_n = ROW_COUNT;

  IF p_art = 'EINLADUNG' THEN
    UPDATE public.versammlungen SET eingeladen_am = now(),
      status = CASE WHEN status = 'ENTWURF' THEN 'EINGELADEN' ELSE status END WHERE id = v.id;
  ELSE
    UPDATE public.versammlungen SET protokoll_versandt_am = now(), status = 'ABGESCHLOSSEN' WHERE id = v.id;
  END IF;
  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.versammlung_versenden(uuid, text, text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.versammlung_versenden(uuid, text, text, text, text) TO authenticated;

-- Wie viele zaehlen fuer die Beschlussfaehigkeit (aktive Mitglieder)?
CREATE OR REPLACE FUNCTION public.versammlung_stimmberechtigt()
RETURNS integer LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE WHEN public.is_member_manager() THEN
    (SELECT count(*)::int FROM public.users u WHERE u."tenantId" = public.current_tenant()
       AND coalesce(u."membershipStatus", '') <> 'INACTIVE') END;
$$;
REVOKE ALL ON FUNCTION public.versammlung_stimmberechtigt() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.versammlung_stimmberechtigt() TO authenticated;

DO $$
DECLARE v_eigen text := current_user; v_n int;
BEGIN
  PERFORM set_config('request.headers', '{"origin":"https://demo.unityhub.li"}', true);
  SET LOCAL ROLE anon;
  BEGIN SELECT count(*) INTO v_n FROM public.versammlungen; RAISE EXCEPTION 'anon liest versammlungen';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
END $$;

NOTIFY pgrst, 'reload schema';
