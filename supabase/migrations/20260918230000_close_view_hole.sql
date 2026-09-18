-- Die Luecke in den Sichten schliessen.
--
-- Nachgewiesen in der Rolle anon, bevor hier etwas geaendert wurde:
--   * anon las socialMediaPosts (1 Zeile), waehrend die Tabelle darunter ihn
--     korrekt abwies -- die Sicht umging die Zugriffsregel.
--   * anon durfte ueber public_members loeschen. Darunter liegt users mit
--     350 Zeilen.
--   * anon durfte ueber public_tenants loeschen. Darunter liegen die Vereine.
--
-- Ursache: Sichten laufen mit den Rechten ihres Eigentuemers und umgehen damit
-- die Regeln der Tabellen darunter; zugleich war anon und authenticated auf
-- allen fuenf Sichten das volle Schreibrecht erteilt. Eine einfache Sicht auf
-- genau eine Tabelle ist in PostgreSQL automatisch beschreibbar -- damit war
-- der Weg offen.
--
-- Die vier public_-Sichten sind inhaltlich richtig gebaut: jede filtert auf den
-- Verein, und public_settings entfernt die PayPal-Geheimnisse. Sie sollen
-- gelesen werden duerfen. Geschrieben werden soll durch sie nie.

-- ------------------------------------------------- Schreibrechte entziehen
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'v' LOOP
    EXECUTE format(
      'REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.%I FROM anon, authenticated',
      r.relname);
    RAISE NOTICE 'Schreibrechte entzogen auf %', r.relname;
  END LOOP;
END $$;

-- Der Filter der Sicht soll nicht durch eine geschickt gesetzte Bedingung
-- umgangen werden koennen: security_barrier zwingt PostgreSQL, ihn zuerst
-- anzuwenden.
ALTER VIEW public.public_members        SET (security_barrier = true);
ALTER VIEW public.public_settings       SET (security_barrier = true);
ALTER VIEW public.public_tenant_domains SET (security_barrier = true);
ALTER VIEW public.public_tenants        SET (security_barrier = true);

-- ------------------------------------------------- socialMediaPosts aufloesen
-- Die Sicht war eine blosse Kopie der Tabelle unter anderem Namen, ohne
-- Filter und ohne Zugriffsschutz -- sie hatte keinen Zweck ausser dem alten
-- Namen aus Firebase-Zeiten. Der Code spricht jetzt die Tabelle selbst an,
-- auf der die Regel socialmediaposts_staff greift.
DROP VIEW IF EXISTS public."socialMediaPosts";

NOTIFY pgrst, 'reload schema';

-- ------------------------------------------------------------- Gegenprobe
DO $$
DECLARE v_back text := current_user; v_n int; v_err text; r record;
BEGIN
  EXECUTE 'SET ROLE anon';

  BEGIN
    SELECT count(*) INTO v_n FROM public.socialmediaposts;
    RAISE NOTICE '1 anon liest socialmediaposts: % -- erwartet 0', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '1 anon liest socialmediaposts: abgewiesen -- richtig';
  END;

  BEGIN
    DELETE FROM public.public_members WHERE id = '__nichts__';
    RAISE NOTICE '2 anon loescht ueber public_members: NOCH IMMER MOEGLICH -- Fehler';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '2 anon loescht ueber public_members: abgewiesen -- richtig';
  WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '2 anon loescht ueber public_members: abgewiesen (%)', left(v_err, 60);
  END;

  BEGIN
    DELETE FROM public.public_tenants WHERE id = '__nichts__';
    RAISE NOTICE '3 anon loescht ueber public_tenants: NOCH IMMER MOEGLICH -- Fehler';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '3 anon loescht ueber public_tenants: abgewiesen -- richtig';
  WHEN others THEN
    RAISE NOTICE '3 anon loescht ueber public_tenants: abgewiesen';
  END;

  -- Lesen muss weiterhin gehen, sonst ist die oeffentliche Website kaputt.
  BEGIN
    SELECT count(*) INTO v_n FROM public.public_tenant_domains;
    RAISE NOTICE '4 anon liest public_tenant_domains: % -- muss weiterhin gehen', v_n;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '4 anon liest public_tenant_domains: ABGEWIESEN -- % (Fehler)', v_err;
  END;

  BEGIN
    SELECT count(*) INTO v_n FROM public.public_tenants;
    RAISE NOTICE '5 anon liest public_tenants: % -- muss weiterhin gehen', v_n;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '5 anon liest public_tenants: ABGEWIESEN -- Fehler';
  END;

  EXECUTE format('SET ROLE %I', v_back);
END $$;
