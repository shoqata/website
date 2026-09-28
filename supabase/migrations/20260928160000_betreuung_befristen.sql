-- Eine Betreuung endet spaetestens nach acht Stunden.
--
-- Gefunden am 28.09.2026: eine Betreuungszeile vom 17.09. stand seit elf
-- Tagen offen. Gewirkt hat sie nicht -- sie gehoert email@dervishi.ch, und
-- der steht nicht in platform_admins, also greift der Zweig gar nicht. Bei
-- einem echten Betreiber haette sie unbegrenzt weitergegolten: ein Zugriff
-- auf fremde Mitgliederdaten, den niemand mehr beendet, weil niemand mehr
-- daran denkt.
--
-- Acht Stunden sind ein Arbeitstag. Wer laenger braucht, startet sie neu --
-- und dieser zweite Start steht dann auch im Protokoll, was richtig ist.
CREATE OR REPLACE FUNCTION public.current_tenant()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT s."tenantId"
       FROM public.platform_support s
      WHERE s."endedAt" IS NULL
        AND s."startedAt" > now() - interval '8 hours'
        AND public.is_platform_admin()
        AND auth.jwt() ->> 'email' IS NOT NULL
        AND lower(s.email) = lower(auth.jwt() ->> 'email')
      ORDER BY s."startedAt" DESC
      LIMIT 1),
    (SELECT u."tenantId" FROM public.users u WHERE u.id = public.current_user_row_id())
  )
$$;
REVOKE ALL ON FUNCTION public.current_tenant() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_tenant() TO authenticated, anon;

-- Die liegengebliebene Zeile schliessen. Nicht loeschen: sie ist Protokoll.
UPDATE public.platform_support
   SET "endedAt" = "startedAt" + interval '8 hours',
       reason = coalesce(reason,'') || ' [am 28.09.2026 nachtraeglich geschlossen: lag seit dem 17.09. offen]'
 WHERE "endedAt" IS NULL;

DO $$
DECLARE v_back text := current_user; v_uid text; v_n int; v_t text; r record;
BEGIN
  SELECT count(*) INTO v_n FROM public.platform_support WHERE "endedAt" IS NULL;
  RAISE NOTICE 'Offene Betreuungen: % (erwartet 0)', v_n;

  -- Gegenprobe, dass current_tenant() fuer gewoehnliche Anmeldungen
  -- unveraendert arbeitet: der zweite Zweig ist unberuehrt, aber diese
  -- Funktion haengt an allem, deshalb wird es gemessen.
  FOR r IN SELECT u.email, u."authUserId" AS uid FROM public.users u
            WHERE u."authUserId" IS NOT NULL ORDER BY u.role LIMIT 3 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT public.current_tenant() INTO v_t;
    SELECT count(*) INTO v_n FROM public.users;
    EXECUTE format('SET ROLE %I', v_back);
    RAISE NOTICE '  % -> Verein % | % Zeilen sichtbar', rpad(r.email,26), coalesce(v_t,'-'), v_n;
  END LOOP;
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
