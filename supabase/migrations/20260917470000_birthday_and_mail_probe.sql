-- Geburtstagsversand: gibt es die Daten dafuer, und wird ueberhaupt versendet?
--
-- Der Versand schreibt heute in eine Tabelle 'mail' und setzt darauf, dass die
-- Firebase-Erweiterung "Trigger Email" sie abholt. Das Projekt laeuft
-- inzwischen auf Supabase -- es gibt niemanden mehr, der diese Tabelle leert.
-- Bevor ein Geburtstagsversand gebaut wird, muss das auf dem Tisch liegen.
DO $$
DECLARE
  v_ges int; v_gebdat int; v_brauchbar int; v_beides int;
  v_mail_tab boolean; v_mail_zeilen int := 0;
  r record;
BEGIN
  SELECT count(*) INTO v_ges FROM public.users;
  SELECT count(*) INTO v_gebdat FROM public.users
   WHERE birthdate IS NOT NULL AND btrim(birthdate::text) <> '';
  SELECT count(*) INTO v_brauchbar FROM public.users
   WHERE email IS NOT NULL AND btrim(email) <> ''
     AND email NOT ILIKE '%@koretini.legacy' AND email NOT ILIKE '%no-email-%'
     AND email LIKE '%@%.%';
  SELECT count(*) INTO v_beides FROM public.users
   WHERE birthdate IS NOT NULL AND btrim(birthdate::text) <> ''
     AND email IS NOT NULL AND btrim(email) <> ''
     AND email NOT ILIKE '%@koretini.legacy' AND email NOT ILIKE '%no-email-%'
     AND email LIKE '%@%.%';

  RAISE NOTICE 'Mitglieder %, mit Geburtsdatum %, mit brauchbarer E-Mail %',
    v_ges, v_gebdat, v_brauchbar;
  RAISE NOTICE 'Mit BEIDEM -- nur diese koennen ueberhaupt gratuliert bekommen: %', v_beides;

  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                  WHERE table_schema='public' AND table_name='mail') INTO v_mail_tab;
  IF v_mail_tab THEN
    EXECUTE 'SELECT count(*) FROM public.mail' INTO v_mail_zeilen;
    RAISE NOTICE 'Tabelle mail vorhanden, % Zeilen -- unversandt, es holt sie niemand ab', v_mail_zeilen;
  ELSE
    RAISE NOTICE 'Tabelle mail gibt es nicht -- sendEmail() scheitert still seit der Umstellung.';
  END IF;

  IF v_gebdat > 0 THEN
    RAISE NOTICE '=== Geburtstage je Monat (von % Datensaetzen) ===', v_gebdat;
    FOR r IN SELECT EXTRACT(MONTH FROM birthdate::date)::int AS monat, count(*) AS n
               FROM public.users
              WHERE birthdate IS NOT NULL AND btrim(birthdate::text) <> ''
              GROUP BY 1 ORDER BY 1 LOOP
      RAISE NOTICE '  Monat %: %', r.monat, r.n;
    END LOOP;
  END IF;
END $$;
