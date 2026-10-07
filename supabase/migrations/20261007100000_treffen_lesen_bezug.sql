-- Ein eingeladener Verein konnte sein Treffen nie sehen.
--
-- In treffen_lesen stand seit der ersten Treffen-Migration:
--
--   EXISTS (SELECT 1 FROM public.treffen_teilnehmer t
--            WHERE t.treffen_id = id AND t."tenantId" = current_tenant())
--
-- Das unqualifizierte "id" bindet an die INNERE Tabelle, denn
-- treffen_teilnehmer hat selbst eine Spalte id. Postgres schreibt die
-- Regel entsprechend um und zeigt den Fehler im Klartext:
--
--   WHERE ((t.treffen_id = t.id) AND (t."tenantId" = current_tenant()))
--
-- Eine Teilnehmerzeile, deren eigene id gleich ihrer Treffen-id ist, gibt
-- es nicht. Der Zweig war also immer falsch, und ein eingeladener Verein
-- las aus treffen genau nichts.
--
-- Aufgefallen ist es nie, weil treffen_meine() SECURITY DEFINER ist und
-- an den Zeilenregeln vorbeigeht: die Einladungsliste in der Oberflaeche
-- funktionierte, jeder direkte Zugriff auf treffen nicht. Genau deshalb
-- ist "die Maske zeigt das Richtige" kein Beweis fuer die Regel darunter.
--
-- Gemessen als echtes Vereinspersonal (BOARD, Koretini): sichtbare
-- Treffen 0, obwohl der Verein eingeladen ist.

DROP POLICY IF EXISTS treffen_lesen ON public.treffen;
CREATE POLICY treffen_lesen ON public.treffen FOR SELECT TO anon, authenticated
  USING (
    status = 'OEFFENTLICH'
    OR public.is_platform_admin()
    OR (gastgeber IS NOT NULL
        AND gastgeber = public.current_tenant()
        AND public.is_staff()
        AND public.modul_aktiv('TREFFEN'))
    -- treffen.id ausgeschrieben. Der Name id kommt in beiden Tabellen
    -- vor; wer sich hier auf die Bindung verlaesst, bekommt die falsche.
    OR EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                WHERE te.treffen_id = public.treffen.id
                  AND te."tenantId" = public.current_tenant())
  );


-- Dieselbe Falle anderswo? Jede Regel, die eine Teilbedingung auf eine
-- Spalte stuetzt, die es in beiden beteiligten Tabellen gibt, kann so
-- danebengreifen. Hier wird gezielt nach dem Muster gesucht, das
-- Postgres bei genau diesem Fehler erzeugt: eine Tabelle, die mit sich
-- selbst verglichen wird.
DO $$
DECLARE v_verdacht text;
BEGIN
  SELECT string_agg(tablename||' / '||policyname, ', ') INTO v_verdacht
    FROM pg_policies
   WHERE schemaname = 'public'
     AND (coalesce(qual,'')||' '||coalesce(with_check,'')) ~ '\(te?\.(\w+) = te?\.\1\)';
  IF v_verdacht IS NOT NULL THEN
    RAISE WARNING 'Verdacht auf denselben Bindungsfehler in: %', v_verdacht;
  END IF;
END $$;


-- ---------------------------------------------------------- Selbsttest
-- Der Beweis gehoert in die Regel, nicht in die Oberflaeche: ein
-- eingeladener Verein muss sein Treffen sehen -- und nur seines.
DO $$
DECLARE
  v_konto text;
  v_verein text;
  v_sichtbar int;
  v_eingeladen int;
BEGIN
  -- Irgendein Vereinskonto mit Anmeldung, das zu einem Treffen
  -- eingeladen ist. Keine feste Kennung: die haelt keine Migration aus.
  SELECT u."authUserId", u."tenantId"
    INTO v_konto, v_verein
    FROM public.users u
   WHERE u."authUserId" IS NOT NULL
     AND EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te."tenantId" = u."tenantId")
   LIMIT 1;

  IF v_konto IS NULL THEN
    RAISE NOTICE 'Kein eingeladenes Vereinskonto vorhanden -- Verhalten nicht pruefbar, '
                 'die Regel ist trotzdem gesetzt.';
    RETURN;
  END IF;

  SELECT count(DISTINCT te.treffen_id) INTO v_eingeladen
    FROM public.treffen_teilnehmer te WHERE te."tenantId" = v_verein;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_konto, 'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_sichtbar FROM public.treffen;
  RESET ROLE;

  IF v_sichtbar < v_eingeladen THEN
    RAISE EXCEPTION 'Verein % ist zu % Treffen eingeladen, sieht aber nur %.',
      v_verein, v_eingeladen, v_sichtbar;
  END IF;
  RAISE NOTICE 'Verein % sieht % Treffen (eingeladen zu %).', v_verein, v_sichtbar, v_eingeladen;
END $$;
