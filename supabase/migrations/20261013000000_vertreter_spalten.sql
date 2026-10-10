-- Welche Felder ein Nachbarschafts-Verantwortlicher aendern darf.
--
-- Gemessen am 10.10., bevor etwas geaendert wurde: er konnte
-- billingGroup, customAnnualFee und membershipStatus setzen. Nicht weil
-- es jemand erlaubt haette, sondern weil Zeilenregeln fuer ZEILEN gelten
-- und nicht fuer SPALTEN -- und die Maske diese Felder schlicht nicht
-- mitschickte. Eine Oberflaeche, die etwas weglaesst, ist keine
-- Schranke: ein Aufruf an die Schnittstelle vorbei genuegt, und ein
-- Verantwortlicher haette seinen eigenen Beitrag auf einen Franken
-- setzen koennen.
--
-- Die Trennlinie ist nicht "wichtig / unwichtig", sondern:
--
--   WAS ER VOR ORT WEISS, darf er aendern. Wer umgezogen ist, welche
--   Nummer heute gilt, zu welcher Familie jemand gehoert, ob jemand
--   aktiv oder passiv dabei ist, welche Sprache er spricht. Genau
--   dafuer gibt es ihn; ohne das muesste er jede Adressaenderung dem
--   Vorstand mailen, und das tut nach dem dritten Mal niemand mehr.
--
--   WAS GELD ODER MITGLIEDSCHAFT BETRIFFT, darf er nicht. Beitragsgruppe
--   und individueller Beitrag bestimmen, was jemand zahlt. Rolle,
--   Status und Nachbarschaft bestimmen, wer jemand im Verein IST. Beides
--   entscheidet der Vorstand.

CREATE OR REPLACE FUNCTION public.vertreter_spalten_schuetzen()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text;
  v_verboten text;
  -- Was er vor Ort weiss.
  v_erlaubt text[] := ARRAY[
    'firstName','lastName','displayName','salutation','birthdate',
    'street','zip','city','country','address',
    'phone','phoneSecondary','email',
    'nicht_oeffentlich','sprache',
    'membershipCategory','familyId'];
BEGIN
  -- Zeitplaene, Migrationen, Dienstschluessel: nicht angemeldet.
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  -- Verwaltung, Vorstand und Betreiber aendern alles wie bisher.
  IF public.is_member_manager() OR public.is_platform_admin() THEN RETURN NEW; END IF;

  v_ich := public.current_user_row_id();
  -- Das eigene Profil hat seine eigene Regel; hier geht es um fremde Zeilen.
  IF v_ich IS NOT NULL AND NEW.id = v_ich THEN RETURN NEW; END IF;

  -- Ab hier aendert jemand eine FREMDE Zeile, ohne Verwalter zu sein.
  -- Nach den Zeilenregeln kann das nur ein Verantwortlicher sein.
  SELECT string_agg(n.key, ', ' ORDER BY n.key) INTO v_verboten
    FROM jsonb_each(to_jsonb(NEW)) n
    LEFT JOIN jsonb_each(to_jsonb(OLD)) o ON o.key = n.key
   WHERE n.value IS DISTINCT FROM o.value
     AND NOT (n.key = ANY (v_erlaubt));

  IF v_verboten IS NOT NULL THEN
    RAISE EXCEPTION 'Als Verantwortlicher einer Nachbarschaft koennen Sie diese Felder '
                    'nicht aendern: %. Beitrag, Rolle und Status entscheidet der Vorstand.',
                    v_verboten
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS users_vertreter_spalten ON public.users;
CREATE TRIGGER users_vertreter_spalten
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.vertreter_spalten_schuetzen();


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_quelle text;
BEGIN
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='vertreter_spalten_schuetzen';

  -- Die Geldfelder duerfen NICHT in der Erlaubnisliste stehen. Genau
  -- dieser Fehler waere unsichtbar: alles funktionierte, nur die
  -- Schranke nicht.
  IF v_quelle ~ '''billingGroup''' OR v_quelle ~ '''customAnnualFee''' THEN
    RAISE EXCEPTION 'Ein Geldfeld steht in der Erlaubnisliste des Verantwortlichen.';
  END IF;
  IF v_quelle ~ '''role''' OR v_quelle ~ '''membershipStatus''' OR v_quelle ~ '''neighborhoodId''' THEN
    RAISE EXCEPTION 'Rolle, Status oder Nachbarschaft stehen in der Erlaubnisliste.';
  END IF;
  -- Und das Gewuenschte MUSS drinstehen.
  IF v_quelle !~ '''membershipCategory''' OR v_quelle !~ '''familyId''' THEN
    RAISE EXCEPTION 'Kategorie oder Familienzuordnung fehlen in der Erlaubnisliste.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='users_vertreter_spalten') THEN
    RAISE EXCEPTION 'Der Ausloeser ist nicht gesetzt.';
  END IF;

  RAISE NOTICE 'Spaltenschranke fuer Verantwortliche steht.';
END $$;
