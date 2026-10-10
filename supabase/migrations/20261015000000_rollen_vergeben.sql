-- Wer darf Rollen vergeben?
--
-- Gemessen am 10.10., bevor etwas geaendert wurde -- drei Loecher:
--
--   Vorstand macht jemanden zum ADMIN      durchgelassen
--   Vorstand befoerdert SICH SELBST        durchgelassen
--   Letzter Admin stuft SICH herab         durchgelassen
--
-- Das erste und zweite sind Rechteausweitung: jedes Vorstandskonto
-- konnte sich zum Administrator des Vereins machen. Nicht weil es
-- jemand erlaubt haette, sondern weil die Zeilenregel fuer users
-- is_member_manager() prueft -- und darin steckt BOARD. Eine Regel, die
-- das Aendern einer Zeile erlaubt, erlaubt damit auch das Aendern der
-- Spalte, die ueber die Rechte entscheidet.
--
-- Das dritte ist kein Angriff, sondern ein Versehen mit denselben
-- Folgen: wer sich als letzter Administrator herabstuft, sperrt seinen
-- Verein aus. Danach hilft nur noch der Betreiber.
--
-- Drei Regeln, und jede beantwortet eine davon:
--
--   1. Rollen vergibt nur die Vereinsadministration.
--   2. Die EIGENE Rolle aendert niemand. Wer aufhoeren will, bestimmt
--      zuerst einen Nachfolger -- der stuft ihn dann herab. Das ist
--      keine Schikane, sondern die Reihenfolge, die ein Verein ohnehin
--      einhalten sollte.
--   3. Der letzte Administrator bleibt. Sonst steht der Verein ohne da.

CREATE OR REPLACE FUNCTION public.rollenwechsel_pruefen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text; v_uebrig int;
BEGIN
  IF NEW.role IS NOT DISTINCT FROM OLD.role THEN RETURN NEW; END IF;

  -- Zeitplaene, Migrationen, Dienstschluessel.
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  -- Der Betreiber setzt den ersten Administrator eines Vereins und darf
  -- auch sonst eingreifen -- sonst gaebe es keinen Weg zurueck.
  IF public.is_platform_admin() THEN RETURN NEW; END IF;

  IF public.app_role() NOT IN ('SUPER_ADMIN','ADMIN') THEN
    RAISE EXCEPTION 'Rollen vergibt nur die Vereinsadministration.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_ich := public.current_user_row_id();
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN
    RAISE EXCEPTION 'Die eigene Rolle koennen Sie nicht aendern. Bestimmen Sie zuerst '
                    'eine andere Person zur Administration; diese kann Sie dann herabstufen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Der letzte Administrator bleibt.
  IF coalesce(OLD.role,'MEMBER') IN ('SUPER_ADMIN','ADMIN')
     AND coalesce(NEW.role,'MEMBER') NOT IN ('SUPER_ADMIN','ADMIN') THEN
    SELECT count(*) INTO v_uebrig FROM public.users u
     WHERE u."tenantId" = NEW."tenantId" AND u.id <> NEW.id
       AND u.role IN ('SUPER_ADMIN','ADMIN');
    IF v_uebrig = 0 THEN
      RAISE EXCEPTION 'Das ist die letzte Administration dieses Vereins. Bestimmen Sie '
                      'zuerst eine andere, sonst kann niemand mehr verwalten.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS users_rollenwechsel ON public.users;
CREATE TRIGGER users_rollenwechsel
  BEFORE UPDATE OF role ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.rollenwechsel_pruefen();


-- Fuer die Maske: eine Rolle setzen, mit sprechender Antwort.
CREATE OR REPLACE FUNCTION public.rolle_setzen(p_user text, p_rolle text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Rollen vergibt nur die Vereinsadministration.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_rolle NOT IN ('MEMBER','REPRESENTATIVE','BOARD','ADMIN','SUPER_ADMIN') THEN
    RAISE EXCEPTION 'Unbekannte Rolle: %', p_rolle USING ERRCODE='check_violation';
  END IF;

  -- Der Ausloeser prueft den Rest; hier geht es nur darum, dass die
  -- Aenderung ueberhaupt die richtige Zeile trifft.
  UPDATE public.users SET role = p_rolle
   WHERE id = p_user AND "tenantId" = public.current_tenant();
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Diese Person gehoert nicht zu Ihrem Verein.'
      USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN p_rolle;
END $$;
REVOKE ALL ON FUNCTION public.rolle_setzen(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.rolle_setzen(text, text) TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_q text; v_n int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='users_rollenwechsel') THEN
    RAISE EXCEPTION 'Der Ausloeser fehlt.';
  END IF;

  SELECT p.prosrc INTO v_q FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='rollenwechsel_pruefen';

  -- BOARD darf nicht in der Erlaubnisliste stehen -- genau das war das Loch.
  IF v_q ~ 'IN \(''SUPER_ADMIN'',''ADMIN'',''BOARD''\)' OR v_q ~ 'is_member_manager' THEN
    RAISE EXCEPTION 'Der Vorstand steht wieder in der Erlaubnisliste fuer Rollen.';
  END IF;
  IF v_q !~ 'NEW.id = v_ich' THEN
    RAISE EXCEPTION 'Die Selbstbefoerderung ist nicht ausgeschlossen.';
  END IF;
  IF v_q !~ 'letzte Administration' THEN
    RAISE EXCEPTION 'Der Schutz der letzten Administration fehlt.';
  END IF;

  -- Jeder Verein muss mindestens eine Administration haben, sonst
  -- sperrt die neue Regel ihn beim ersten Wechsel aus.
  SELECT count(*) INTO v_n FROM public.tenants t
   WHERE NOT EXISTS (SELECT 1 FROM public.users u
                      WHERE u."tenantId"=t.id AND u.role IN ('SUPER_ADMIN','ADMIN'));
  IF v_n > 0 THEN
    RAISE NOTICE '% Verein(e) haben keine Administration -- der Betreiber muss eine setzen.', v_n;
  END IF;

  RAISE NOTICE 'Rollenvergabe abgesichert.';
END $$;
