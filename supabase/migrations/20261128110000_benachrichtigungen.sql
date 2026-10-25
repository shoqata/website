-- Das Benachrichtigungscenter.
--
-- Bisher erfuhr ein Mitglied von einer neuen Rechnung per Brief oder Mail,
-- und der Vorstand von einer neuen Spende nur, wenn er zufaellig in die
-- Liste schaute. Jetzt landet beides an einer Stelle in der App: die Glocke
-- in der Leiste, mit Zaehler fuer Ungelesenes.
--
-- Geschrieben wird nur von der Datenbank selbst (Ausloeser unten). Die App
-- liest und markiert als gelesen -- anlegen kann sie nichts, sonst koennte
-- jedes Mitglied jedem anderen "Benachrichtigungen" schicken.

CREATE TABLE public.benachrichtigungen (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  empfaenger  text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  art         text NOT NULL,          -- SPENDE, RECHNUNG, MAHNUNG, VERANSTALTUNG, NEUIGKEIT, AUFRUF
  titel       text NOT NULL,
  text        text,
  link        text,                   -- Pfad in der App, z. B. '/dashboard'
  erstellt_am timestamptz NOT NULL DEFAULT now(),
  gelesen_am  timestamptz
);

CREATE INDEX benachrichtigungen_empfaenger_idx
  ON public.benachrichtigungen (empfaenger, erstellt_am DESC);
CREATE INDEX benachrichtigungen_ungelesen_idx
  ON public.benachrichtigungen (empfaenger) WHERE gelesen_am IS NULL;

ALTER TABLE public.benachrichtigungen ENABLE ROW LEVEL SECURITY;

-- Jeder sieht nur seine eigenen -- und nur die des Vereins, auf dessen
-- Seite er gerade ist (eine Person kann in zwei Vereinen Mitglied sein).
CREATE POLICY benachrichtigungen_eigene ON public.benachrichtigungen
  FOR SELECT TO authenticated
  USING (empfaenger = public.current_user_row_id());

GRANT SELECT ON public.benachrichtigungen TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.benachrichtigungen FROM anon, authenticated;

-- Live-Zaehler: neue Zeilen kommen ueber Realtime, gefiltert durch die
-- Regel oben.
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.benachrichtigungen;
  END IF;
END $$;


-- --- Lesen und Aufraeumen (fuer die App) ---------------------------------

CREATE OR REPLACE FUNCTION public.benachrichtigungen_gelesen(p_ids uuid[] DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_ich text := public.current_user_row_id(); n integer;
BEGIN
  IF v_ich IS NULL THEN RETURN 0; END IF;
  -- Ohne Liste: alle eigenen.
  UPDATE public.benachrichtigungen SET gelesen_am = now()
   WHERE empfaenger = v_ich AND gelesen_am IS NULL
     AND (p_ids IS NULL OR id = ANY (p_ids));
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;

CREATE OR REPLACE FUNCTION public.benachrichtigung_entfernen(p_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' AS $$
  DELETE FROM public.benachrichtigungen
   WHERE id = p_id AND empfaenger = public.current_user_row_id();
$$;

REVOKE ALL ON FUNCTION public.benachrichtigungen_gelesen(uuid[]) FROM public, anon;
REVOKE ALL ON FUNCTION public.benachrichtigung_entfernen(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.benachrichtigungen_gelesen(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.benachrichtigung_entfernen(uuid) TO authenticated;


-- --- Schreiben (nur intern) ----------------------------------------------

-- Empfaenger sind nur Personen mit Zugang (authUserId): wer sich nie
-- anmelden kann, sieht die Glocke nie, und die Zeilen waeren Ballast.
CREATE OR REPLACE FUNCTION public.benachrichtigen(
  p_tenant text, p_empfaenger text[], p_art text, p_titel text,
  p_text text DEFAULT NULL, p_link text DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE n integer;
BEGIN
  IF p_tenant IS NULL OR p_empfaenger IS NULL THEN RETURN 0; END IF;
  INSERT INTO public.benachrichtigungen ("tenantId", empfaenger, art, titel, text, link)
  SELECT p_tenant, u.id, p_art, p_titel, p_text, p_link
    FROM public.users u
   WHERE u.id = ANY (p_empfaenger)
     AND u."tenantId" = p_tenant
     AND u."authUserId" IS NOT NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;
REVOKE ALL ON FUNCTION public.benachrichtigen(text, text[], text, text, text, text) FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.empfaenger_vorstand(p_tenant text)
RETURNS text[] LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
  SELECT coalesce(array_agg(id), '{}') FROM public.users
   WHERE "tenantId" = p_tenant AND role IN ('ADMIN', 'BOARD');
$$;
CREATE OR REPLACE FUNCTION public.empfaenger_mitglieder(p_tenant text)
RETURNS text[] LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
  SELECT coalesce(array_agg(id), '{}') FROM public.users
   WHERE "tenantId" = p_tenant
     AND role IN ('MEMBER', 'BOARD', 'ADMIN', 'REPRESENTATIVE')
     AND "membershipStatus" = 'ACTIVE';
$$;
REVOKE ALL ON FUNCTION public.empfaenger_vorstand(text) FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.empfaenger_mitglieder(text) FROM public, anon, authenticated;

-- Datumsfelder sind hier Text. Ein falsch geschriebener Wert darf keine
-- Rechnung und keine Veranstaltung am Speichern hindern.
CREATE OR REPLACE FUNCTION public.als_datum(t text) RETURNS date
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN RETURN nullif(t, '')::date; EXCEPTION WHEN others THEN RETURN NULL; END $$;

CREATE OR REPLACE FUNCTION public.chf(n numeric) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT 'CHF ' || replace(to_char(n, 'FM999G999G990D00'), ',', '''');
$$;


-- --- Ausloeser ----------------------------------------------------------

-- Neue Spende -> Vorstand.
CREATE OR REPLACE FUNCTION public.melde_spende() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  BEGIN
    PERFORM public.benachrichtigen(NEW."tenantId", public.empfaenger_vorstand(NEW."tenantId"),
      'SPENDE', 'Neue Spende',
      public.chf(NEW.betrag) || ' von ' ||
        CASE WHEN NEW.anonym OR coalesce(NEW.name, '') = '' THEN 'anonym' ELSE NEW.name END ||
        CASE WHEN coalesce(NEW.zweck, '') <> '' THEN ' · ' || NEW.zweck ELSE '' END,
      '/admin');
  EXCEPTION WHEN others THEN
    -- Eine Benachrichtigung ist Beiwerk: sie darf das Speichern nie verhindern.
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;
CREATE TRIGGER benachrichtigung_spende AFTER INSERT ON public.donations
  FOR EACH ROW EXECUTE FUNCTION public.melde_spende();

-- Neue Rechnung -> das Mitglied. Geplante Rechnungen (Versand spaeter)
-- melden sich nicht zu frueh.
-- Mahnstufe steigt -> das Mitglied.
CREATE OR REPLACE FUNCTION public.melde_rechnung() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_nr text := coalesce(NEW."invoiceNumber", '');
BEGIN
  BEGIN
    IF NEW."userId" IS NULL OR NEW.status <> 'PENDING' THEN RETURN NEW; END IF;
    IF TG_OP = 'INSERT' THEN
      IF NEW."scheduledDate" IS NOT NULL AND public.als_datum(NEW."scheduledDate") > current_date THEN RETURN NEW; END IF;
      PERFORM public.benachrichtigen(NEW."tenantId", ARRAY[NEW."userId"], 'RECHNUNG',
        'Neue Rechnung' || CASE WHEN v_nr <> '' THEN ' ' || v_nr ELSE '' END,
        public.chf(NEW.amount) ||
          CASE WHEN public.als_datum(NEW."dueDate") IS NOT NULL
               THEN ' · fällig am ' || to_char(public.als_datum(NEW."dueDate"), 'DD.MM.YYYY') ELSE '' END,
        '/dashboard');
    ELSIF coalesce(NEW."dunningLevel", 0) > coalesce(OLD."dunningLevel", 0) THEN
      PERFORM public.benachrichtigen(NEW."tenantId", ARRAY[NEW."userId"], 'MAHNUNG',
        'Zahlungserinnerung' || CASE WHEN v_nr <> '' THEN ' ' || v_nr ELSE '' END,
        public.chf(NEW.amount) || ' sind noch offen.', '/dashboard');
    END IF;
  EXCEPTION WHEN others THEN
    -- Eine Benachrichtigung ist Beiwerk: sie darf das Speichern nie verhindern.
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;
CREATE TRIGGER benachrichtigung_rechnung AFTER INSERT OR UPDATE OF "dunningLevel" ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.melde_rechnung();

-- Veranstaltung veroeffentlicht -> Mitglieder. Nur beim Wechsel auf
-- PUBLISHED, nicht bei jeder spaeteren Aenderung, und nicht fuer
-- Vergangenes.
CREATE OR REPLACE FUNCTION public.melde_veranstaltung() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  BEGIN
    IF NEW.status <> 'PUBLISHED' THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM 'PUBLISHED' THEN RETURN NEW; END IF;
    IF public.als_datum(NEW.date) < current_date THEN RETURN NEW; END IF;
    PERFORM public.benachrichtigen(NEW."tenantId", public.empfaenger_mitglieder(NEW."tenantId"),
      'VERANSTALTUNG', 'Neue Veranstaltung',
      coalesce(NEW.title, '') ||
        CASE WHEN public.als_datum(NEW.date) IS NOT NULL THEN ' · ' || to_char(public.als_datum(NEW.date), 'DD.MM.YYYY') ELSE '' END,
      '/events');
  EXCEPTION WHEN others THEN
    -- Eine Benachrichtigung ist Beiwerk: sie darf das Speichern nie verhindern.
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;
CREATE TRIGGER benachrichtigung_veranstaltung AFTER INSERT OR UPDATE OF status ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.melde_veranstaltung();

-- Neuigkeit veroeffentlicht -> Mitglieder. Zeitgesteuerte (publishAt in
-- der Zukunft) melden sich hier nicht; sie werden ohne Zeilenaenderung
-- sichtbar und gehen damit an der Glocke vorbei.
CREATE OR REPLACE FUNCTION public.melde_neuigkeit() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  BEGIN
    IF NEW.status <> 'PUBLISHED' THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM 'PUBLISHED' THEN RETURN NEW; END IF;
    IF NEW."publishAt" IS NOT NULL AND NEW."publishAt"::timestamptz > now() THEN RETURN NEW; END IF;
    PERFORM public.benachrichtigen(NEW."tenantId", public.empfaenger_mitglieder(NEW."tenantId"),
      'NEUIGKEIT', coalesce(NEW.title, 'Neuigkeit'), NULL, '/news/' || NEW.id);
  EXCEPTION WHEN others THEN
    -- Eine Benachrichtigung ist Beiwerk: sie darf das Speichern nie verhindern.
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;
CREATE TRIGGER benachrichtigung_neuigkeit AFTER INSERT OR UPDATE OF status ON public.news
  FOR EACH ROW EXECUTE FUNCTION public.melde_neuigkeit();

-- Spendenaufruf veroeffentlicht -> Mitglieder.
CREATE OR REPLACE FUNCTION public.melde_aufruf() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  BEGIN
    IF NEW.status <> 'OEFFENTLICH' THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM 'OEFFENTLICH' THEN RETURN NEW; END IF;
    PERFORM public.benachrichtigen(NEW."tenantId", public.empfaenger_mitglieder(NEW."tenantId"),
      'AUFRUF', 'Neuer Spendenaufruf', NEW.titel, '/spenden');
  EXCEPTION WHEN others THEN
    -- Eine Benachrichtigung ist Beiwerk: sie darf das Speichern nie verhindern.
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;
CREATE TRIGGER benachrichtigung_aufruf AFTER INSERT OR UPDATE OF status ON public.spendenaufrufe
  FOR EACH ROW EXECUTE FUNCTION public.melde_aufruf();

REVOKE ALL ON FUNCTION public.melde_spende(), public.melde_rechnung(), public.melde_veranstaltung(),
  public.melde_neuigkeit(), public.melde_aufruf() FROM public, anon, authenticated;
