-- Anfrage von der Startseite der Plattform.
--
-- platform_leads ist ausschliesslich fuer den Betreiber les- und schreibbar,
-- und dabei bleibt es: die Tabelle enthaelt alle Gespraeche mit allen
-- Interessenten. Ein Besucher darf dort keinen Einblick bekommen und auch
-- nichts aendern -- er darf nur etwas hineinlegen.
--
-- Deshalb eine Funktion mit erhoehten Rechten statt eines offenen
-- Schreibrechts, so wie schon bei den Sponsorenanfragen. Die Funktion gibt
-- nichts zurueck als ein Ja: wer anfragt, soll nicht erfahren, ob seine
-- Adresse schon einmal vorkam.

CREATE OR REPLACE FUNCTION public.submit_platform_lead(
  p_name    text,
  p_contact text,
  p_email   text,
  p_phone   text DEFAULT NULL,
  p_city    text DEFAULT NULL,
  p_members int  DEFAULT NULL,
  p_note    text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_name    text := btrim(coalesce(p_name, ''));
  v_kontakt text := btrim(coalesce(p_contact, ''));
  v_mail    text := lower(btrim(coalesce(p_email, '')));
  v_zuletzt int;
BEGIN
  IF v_name = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_kontakt = '' THEN
    RAISE EXCEPTION 'Ansprechperson fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'E-Mail-Adresse ist unvollstaendig.' USING ERRCODE = 'check_violation';
  END IF;

  -- Eine schlichte Bremse gegen versehentliches Mehrfachsenden und gegen
  -- automatisiertes Zumuellen: dieselbe Adresse hoechstens alle fuenf Minuten.
  -- Die Antwort bleibt dieselbe -- dass bereits etwas vorliegt, erfaehrt der
  -- Absender nicht.
  SELECT count(*) INTO v_zuletzt FROM public.platform_leads
   WHERE lower(coalesce(email, '')) = v_mail
     AND "createdAt" > now() - interval '5 minutes';
  IF v_zuletzt > 0 THEN
    RETURN true;
  END IF;

  -- Laengen begrenzen: ein oeffentliches Formular ist kein Ablageort.
  INSERT INTO public.platform_leads
    (name, "contactName", email, phone, city, "expectedMembers", note, stage, "createdAt")
  VALUES (
    left(v_name, 200),
    left(v_kontakt, 200),
    left(v_mail, 200),
    left(btrim(coalesce(p_phone, '')), 60),
    left(btrim(coalesce(p_city, '')), 120),
    CASE WHEN p_members IS NULL THEN NULL
         ELSE greatest(0, least(p_members, 100000)) END,
    left(coalesce(p_note, ''), 2000),
    'LEAD',
    now()
  );

  RETURN true;
END $$;

-- Aufrufbar auch ohne Anmeldung -- das ist der Zweck. Die Tabelle selbst
-- bleibt fuer anon unerreichbar.
REVOKE ALL ON FUNCTION public.submit_platform_lead(text, text, text, text, text, int, text) FROM public;
GRANT EXECUTE ON FUNCTION public.submit_platform_lead(text, text, text, text, text, int, text)
  TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ------------------------------------------------------------- Gegenprobe
DO $$
DECLARE
  v_back text := current_user;
  v_vorher int; v_nachher int; v_err text;
BEGIN
  SELECT count(*) INTO v_vorher FROM public.platform_leads;

  EXECUTE 'SET ROLE anon';

  BEGIN
    SELECT count(*) INTO v_nachher FROM public.platform_leads;
    RAISE NOTICE '1 anon liest die Interessentenliste: % -- erwartet 0 oder abgewiesen', v_nachher;
  EXCEPTION WHEN others THEN
    RAISE NOTICE '1 anon liest die Interessentenliste: abgewiesen -- richtig';
  END;

  BEGIN
    PERFORM public.submit_platform_lead('Pruefverein', 'Eine Person', 'pruef@example.invalid',
                                        '+41 00 000 00 00', 'Zuerich', 120, 'Selbsttest');
    RAISE NOTICE '2 anon sendet eine Anfrage: angenommen -- richtig';
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '2 anon sendet eine Anfrage: ABGEWIESEN -- % (unerwartet)', v_err;
  END;

  BEGIN
    PERFORM public.submit_platform_lead('Zweiter Versuch', 'Eine Person', 'pruef@example.invalid');
    RAISE NOTICE '3 sofort noch einmal dieselbe Adresse: angenommen, aber nicht gespeichert';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '3 zweite Anfrage: abgewiesen';
  END;

  BEGIN
    PERFORM public.submit_platform_lead('Ohne Adresse', 'Jemand', 'keine-adresse');
    RAISE NOTICE '4 unvollstaendige E-Mail: DURCHGELASSEN -- Fehler';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '4 unvollstaendige E-Mail: abgewiesen -- richtig';
  END;

  BEGIN
    UPDATE public.platform_leads SET name = 'Uebernommen';
    RAISE NOTICE '5 anon aendert Interessenten: DURCHGELASSEN -- schwerer Fehler';
  EXCEPTION WHEN others THEN
    RAISE NOTICE '5 anon aendert Interessenten: abgewiesen -- richtig';
  END;

  EXECUTE format('SET ROLE %I', v_back);

  SELECT count(*) INTO v_nachher FROM public.platform_leads;
  RAISE NOTICE '6 Eintraege: vorher %, nachher % -- erwartet genau einer mehr', v_vorher, v_nachher;

  DELETE FROM public.platform_leads WHERE email = 'pruef@example.invalid';
  RAISE NOTICE 'Testanfrage entfernt, % Eintraege bleiben.', (SELECT count(*) FROM public.platform_leads);
END $$;
