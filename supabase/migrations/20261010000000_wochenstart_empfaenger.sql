-- Wer bekommt den Wochenstart?
--
-- Nicht "alle im Vorstand": in jedem Verein gibt es jemanden, der den
-- Montagabend nicht mit einer Mail beginnen will, und eine Uebersicht, die
-- ungefragt kommt, wird nach drei Wochen weggeklickt wie Werbung. Die
-- Vereinsadministration waehlt aus, und zwar namentlich.
--
-- Die Auswahl steht als Liste von users.id, nicht als Rollenregel. Eine
-- Rollenregel ("alle BOARD") aendert sich still mit, sobald jemand
-- aufgenommen wird -- und dann bekommt eine Person Post, die niemand dafuer
-- vorgesehen hat.

ALTER TABLE public.floky_einstellungen
  ADD COLUMN IF NOT EXISTS wochenstart_an text[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN public.floky_einstellungen.wochenstart_an IS
  'users.id derjenigen, die den Wochenstart am Montagabend erhalten. '
  'Leer = niemand; es wird dann nichts verschickt.';


CREATE OR REPLACE FUNCTION public.floky_wochenstart_empfaenger()
RETURNS text[]
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce((SELECT f.wochenstart_an FROM public.floky_einstellungen f
                    WHERE f."tenantId" = public.current_tenant()), '{}'::text[]);
$$;
REVOKE ALL ON FUNCTION public.floky_wochenstart_empfaenger() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_wochenstart_empfaenger() TO authenticated;


CREATE OR REPLACE FUNCTION public.floky_wochenstart_setzen(p_ids text[])
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_gueltig text[]; v_n int;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration waehlt die Empfaenger.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  -- Nur Personen aus DIESEM Verein, nur mit Adresse, nur Vorstand oder
  -- Verwaltung. Eine fremde id in der Liste waere eine Mail an jemanden,
  -- der mit diesem Verein nichts zu tun hat.
  SELECT coalesce(array_agg(u.id ORDER BY u."displayName"), '{}')
    INTO v_gueltig
    FROM public.users u
   WHERE u.id = ANY (coalesce(p_ids, '{}'))
     AND u."tenantId" = v_verein
     AND u.email IS NOT NULL AND u.email LIKE '%@%'
     AND u.role IN ('BOARD','ADMIN','SUPER_ADMIN');

  INSERT INTO public.floky_einstellungen AS f ("tenantId", wochenstart_an)
  VALUES (v_verein, v_gueltig)
  ON CONFLICT ("tenantId") DO UPDATE
    SET wochenstart_an = excluded.wochenstart_an, geaendert_am = now();

  v_n := coalesce(array_length(v_gueltig, 1), 0);
  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.floky_wochenstart_setzen(text[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_wochenstart_setzen(text[]) TO authenticated;


-- Wer kaeme ueberhaupt in Frage? Die Maske soll keine Liste bauen, die
-- die Datenbank hinterher verwirft.
CREATE OR REPLACE FUNCTION public.floky_wochenstart_waehlbar()
RETURNS TABLE (id text, name text, email text, rolle text, ausgewaehlt boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT u.id, u."displayName", u.email, u.role,
         u.id = ANY (public.floky_wochenstart_empfaenger())
    FROM public.users u
   WHERE u."tenantId" = public.current_tenant()
     AND u.email IS NOT NULL AND u.email LIKE '%@%'
     AND u.role IN ('BOARD','ADMIN','SUPER_ADMIN')
   ORDER BY u.role, u."displayName";
$$;
REVOKE ALL ON FUNCTION public.floky_wochenstart_waehlbar() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.floky_wochenstart_waehlbar() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_quelle text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='floky_einstellungen'
                    AND column_name='wochenstart_an') THEN
    RAISE EXCEPTION 'Spalte wochenstart_an fehlt.';
  END IF;

  -- Vorgabe muss LEER sein. Stuende dort etwas, bekaeme am naechsten Montag
  -- jemand Post, der nie zugestimmt hat.
  SELECT count(*) INTO v_n FROM public.floky_einstellungen
   WHERE coalesce(array_length(wochenstart_an,1),0) > 0;
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Verein(e) haetten sofort Empfaenger -- ungefragt.', v_n;
  END IF;

  -- Die Wache muss da sein, und BOARD darf sie nicht umgehen.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='floky_wochenstart_setzen';
  IF v_quelle !~ 'is_platform_admin' OR v_quelle !~ 'SUPER_ADMIN' THEN
    RAISE EXCEPTION 'Die Berechtigungspruefung fehlt in floky_wochenstart_setzen.';
  END IF;

  -- Und die Liste muss gefiltert werden, sonst landet eine fremde id darin.
  IF v_quelle !~ '"tenantId" = v_verein' THEN
    RAISE EXCEPTION 'floky_wochenstart_setzen filtert nicht nach Verein.';
  END IF;

  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname LIKE 'floky_wochenstart%'
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_n > 0 THEN RAISE EXCEPTION '% Funktion(en) sind fuer anon ausfuehrbar.', v_n; END IF;

  RAISE NOTICE 'Empfaengerwahl bereit. Vorgabe: niemand.';
END $$;
