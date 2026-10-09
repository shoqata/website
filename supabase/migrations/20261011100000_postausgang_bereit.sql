-- Ist ueberhaupt ein Postausgang eingerichtet?
--
-- Diese Frage fehlte, und ihr Fehlen hat zu einer Unwahrheit gefuehrt:
-- sendEmail() stellt eine Nachricht in die Warteschlange, mehr nicht --
-- die Masken meldeten danach "verschickt". Ist kein Postausgang
-- hinterlegt, holt sie niemand ab, und sie liegt dort auf unbestimmte
-- Zeit. Gemessen am 09.10.: eine Anfrage vom 18. September wartete seit
-- drei Wochen, und niemand wusste davon.
--
-- Die Funktion gibt NUR einen Wahrheitswert zurueck. Wer sie aufruft,
-- erfaehrt nichts ueber Adresse, Konto oder Kennwort -- die Antwort
-- lautet "ja" oder "nein", und das genuegt, um ehrlich zu melden.

CREATE OR REPLACE FUNCTION public.postausgang_bereit()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.mail_settings m
     WHERE m.aktiv AND coalesce(btrim(m.kennwort), '') <> ''
  );
$$;
REVOKE ALL ON FUNCTION public.postausgang_bereit() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.postausgang_bereit() TO authenticated;


-- Wie viel liegt und wie lange schon? Fuer den Hinweis in der Maske.
CREATE OR REPLACE FUNCTION public.postausgang_stau()
RETURNS TABLE (wartend int, aeltestes timestamptz, gescheitert int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*) FILTER (WHERE status = 'PENDING')::int,
         min("createdAt") FILTER (WHERE status = 'PENDING'),
         count(*) FILTER (WHERE status = 'FAILED')::int
    FROM public.mail_queue
   WHERE "tenantId" = public.current_tenant();
$$;
REVOKE ALL ON FUNCTION public.postausgang_stau() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.postausgang_stau() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_bereit boolean; v_n int;
BEGIN
  SELECT public.postausgang_bereit() INTO v_bereit;
  RAISE NOTICE 'Postausgang eingerichtet: %', v_bereit;

  -- Die Funktion darf nichts ueber die Zugangsdaten verraten.
  IF (SELECT p.prosrc FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
       WHERE n.nspname='public' AND p.proname='postausgang_bereit') ~ 'SELECT m\.kennwort' THEN
    RAISE EXCEPTION 'postausgang_bereit gibt das Kennwort heraus.';
  END IF;

  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname LIKE 'postausgang%'
     AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_n > 0 THEN RAISE EXCEPTION '% Funktion(en) sind fuer anon ausfuehrbar.', v_n; END IF;
END $$;
