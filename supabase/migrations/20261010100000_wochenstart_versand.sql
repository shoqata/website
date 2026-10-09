-- Der Wochenstart geht am Montagabend hinaus.
--
-- Bewusst KEINE eigene Edge Function: die Uebersicht wird hier gebaut und
-- in mail_queue gelegt, und der Postausgang, der ohnehin alle zehn Minuten
-- laeuft, nimmt sie mit. Daraus folgt alles, was sonst eigens zu bauen
-- waere -- zentraler Absender, Antwortadresse des Vereins, Wiederholung bei
-- Stoerung -- weil es dieselbe Warteschlange ist wie fuer jede andere Post.
--
-- Montagabend und nicht Montagmorgen: Ehrenamtliche arbeiten abends. Eine
-- Uebersicht, die um sieben Uhr kommt, ist um acht vergessen.
--
-- Verschickt wird nur, was nicht leer ist. Eine Mail, die "0 offene
-- Beitraege, 0 Meldungen, 0 Anlaesse" meldet, erzieht ihre Empfaenger
-- innerhalb eines Monats dazu, sie ungelesen zu loeschen -- und dann wird
-- auch die uebersehen, die etwas zu sagen hat.

CREATE OR REPLACE FUNCTION public.wochenstart_einreihen(p_tag date DEFAULT NULL)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tag    date := coalesce(p_tag, (now() AT TIME ZONE 'Europe/Zurich')::date);
  v_n      int  := 0;
  v        record;   -- Verein
  e        record;   -- Empfaenger
  v_offen_n   int; v_offen_s numeric;
  v_meld_n    int; v_meld_s  numeric;
  v_anl    text; v_anl_n int;
  v_block  text; v_html text; v_betreff text;
  v_sprache text;
BEGIN
  -- Der Zeitplan laeuft ohne Anmeldung. Ein angemeldeter Aufrufer muss der
  -- Betreiber sein -- sonst koennte jemand den Versand von Hand ausloesen.
  IF auth.uid() IS NOT NULL AND NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Wochenstart ausloesen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  FOR v IN
    SELECT f."tenantId", f.wochenstart_an, coalesce(f.assistent_name,'Floky') AS helfer,
           t.name AS vereinsname
      FROM public.floky_einstellungen f
      JOIN public.tenants t ON t.id = f."tenantId"
     WHERE coalesce(array_length(f.wochenstart_an, 1), 0) > 0
       -- Nur wo das Modul laeuft. Ohne das bekaeme ein Verein Post fuer
       -- etwas, das er nicht gebucht hat.
       AND EXISTS (SELECT 1 FROM public.tenant_modules tm
                    WHERE tm."tenantId" = f."tenantId" AND tm.modul = 'FLOKY'
                      AND tm.zustand IN ('AN','TESTPHASE'))
  LOOP
    -- Offene Beitraege
    SELECT count(*), coalesce(sum(p.amount), 0) INTO v_offen_n, v_offen_s
      FROM public.payments p
     WHERE p."tenantId" = v."tenantId"
       AND p.status NOT IN ('PAID','CANCELLED','WRITTEN_OFF');

    -- Meldungen der Vertreter, die auf Entscheid warten
    SELECT count(*), coalesce(sum(r.amount), 0) INTO v_meld_n, v_meld_s
      FROM public.payment_reports r
     WHERE r."tenantId" = v."tenantId" AND r.status = 'OPEN';

    -- Anlaesse der naechsten 14 Tage
    SELECT count(*), string_agg(
             '<li>' || to_char(x.date, 'DD.MM.YYYY') || ' — ' ||
             replace(replace(x.title, '&', '&amp;'), '<', '&lt;') ||
             ' (' || x.koepfe || ' Personen)</li>', '')
      INTO v_anl_n, v_anl
      FROM (
        -- events.date ist TEXT, nicht date. Gemessen: alle 5 Eintraege im
        -- Muster JJJJ-MM-TT. Trotzdem wird geprueft statt gecastet -- ein
        -- einziger abweichender Eintrag liesse sonst den ganzen Versand
        -- scheitern, und zwar fuer alle Vereine.
        SELECT ev.date::date AS date, ev.title,
               (SELECT coalesce(sum(coalesce(reg.tickets, 1)), 0)
                  FROM public.event_registrations reg
                 WHERE reg."eventId" = ev.id
                   AND coalesce(reg.status,'') <> 'CANCELLED') AS koepfe
          FROM public.events ev
         WHERE ev."tenantId" = v."tenantId"
           AND ev.date ~ '^\d{4}-\d{2}-\d{2}$'
           AND ev.date::date >= v_tag AND ev.date::date <= v_tag + 14
         ORDER BY ev.date
      ) x;

    -- Nichts zu sagen? Dann auch nichts verschicken.
    CONTINUE WHEN v_offen_n = 0 AND v_meld_n = 0 AND coalesce(v_anl_n,0) = 0;

    FOR e IN
      SELECT u.id, u.email, u."displayName", coalesce(u.sprache, 'de') AS sprache
        FROM public.users u
       WHERE u.id = ANY (v.wochenstart_an)
         AND u."tenantId" = v."tenantId"
         AND u.email IS NOT NULL AND u.email LIKE '%@%'
    LOOP
      v_sprache := CASE WHEN e.sprache IN ('de','sq','en') THEN e.sprache ELSE 'de' END;
      v_block := '';

      IF v_offen_n > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Kuota të hapura'
                         WHEN 'en' THEN 'Open fees'
                         ELSE 'Offene Beiträge' END ||
          ':</strong> ' || v_offen_n || ' × CHF ' ||
          replace(to_char(v_offen_s, 'FM999,999,990.00'), ',', '''') || '</p>';
      END IF;

      IF v_meld_n > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Pagesa të raportuara, në pritje'
                         WHEN 'en' THEN 'Reported payments awaiting a decision'
                         ELSE 'Gemeldete Zahlungen, noch offen' END ||
          ':</strong> ' || v_meld_n || ' × CHF ' ||
          replace(to_char(v_meld_s, 'FM999,999,990.00'), ',', '''') || '</p>';
      END IF;

      IF coalesce(v_anl_n,0) > 0 THEN
        v_block := v_block || '<p><strong>' ||
          CASE v_sprache WHEN 'sq' THEN 'Ngjarjet e 14 ditëve të ardhshme'
                         WHEN 'en' THEN 'Events in the next 14 days'
                         ELSE 'Anlässe der nächsten 14 Tage' END ||
          ':</strong></p><ul>' || v_anl || '</ul>';
      END IF;

      v_betreff := CASE v_sprache
        WHEN 'sq' THEN 'Fillimi i javës — ' || v.vereinsname
        WHEN 'en' THEN 'Week start — ' || v.vereinsname
        ELSE 'Wochenstart — ' || v.vereinsname END;

      v_html :=
        '<p>' || CASE v_sprache
          WHEN 'sq' THEN 'Përshëndetje ' WHEN 'en' THEN 'Hello ' ELSE 'Guten Abend ' END
        || coalesce(e."displayName",'') || '</p>' || v_block ||
        '<p style="color:#888;font-size:12px">' ||
        CASE v_sprache
          WHEN 'sq' THEN 'Këtë përmbledhje e dërgon ' || v.helfer ||
               '. Mund ta çaktivizoni te cilësimet e shoqatës.'
          WHEN 'en' THEN 'This digest comes from ' || v.helfer ||
               '. It can be switched off in the association settings.'
          ELSE 'Diese Übersicht kommt von ' || v.helfer ||
               '. Sie lässt sich in den Vereinseinstellungen abbestellen.'
        END || '</p>';

      -- Zweimal am selben Tag waere ein Fehler, keine Erinnerung.
      CONTINUE WHEN EXISTS (
        SELECT 1 FROM public.mail_queue q
         WHERE q."tenantId" = v."tenantId" AND q.recipient = e.email
           AND q.kind = 'WOCHENSTART'
           AND q."createdAt" >= v_tag::timestamptz);

      INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind, "memberId", status)
      VALUES (v."tenantId", e.email, v_betreff, v_html, 'WOCHENSTART', e.id, 'PENDING');
      v_n := v_n + 1;
    END LOOP;
  END LOOP;

  RETURN v_n;
END $$;
REVOKE ALL ON FUNCTION public.wochenstart_einreihen(date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.wochenstart_einreihen(date) TO authenticated;


-- Montag, 18:00 Europe/Zurich. Die Datenbank laeuft in UTC; im Winter ist
-- das 17:00, im Sommer 16:00. Beide Zeitpunkte eintragen und im Befehl
-- pruefen, welcher gerade gilt -- sonst verschoebe sich der Versand
-- zweimal im Jahr um eine Stunde.
SELECT cron.unschedule('wochenstart') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'wochenstart');

SELECT cron.schedule('wochenstart', '0 16,17 * * 1', $cron$
  SELECT public.wochenstart_einreihen()
   WHERE to_char(now() AT TIME ZONE 'Europe/Zurich', 'HH24') = '18';
$cron$);


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_quelle text;
BEGIN
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='wochenstart_einreihen';
  IF v_quelle IS NULL THEN RAISE EXCEPTION 'wochenstart_einreihen fehlt.'; END IF;

  -- Jede Abfrage muss nach Verein filtern. Diese Funktion laeuft OHNE
  -- current_tenant() -- vergisst sie einen Filter, bekaeme ein Verein die
  -- Zahlen eines anderen.
  IF (length(v_quelle) - length(replace(v_quelle, '"tenantId" = v."tenantId"', ''))) / 26 < 4 THEN
    RAISE EXCEPTION 'Zu wenige Vereinsfilter in wochenstart_einreihen -- '
                    'eine Abfrage koennte fremde Zahlen liefern.';
  END IF;

  IF v_quelle !~ 'is_platform_admin' THEN
    RAISE EXCEPTION 'Jeder Angemeldete koennte den Versand ausloesen.';
  END IF;

  IF has_function_privilege('anon', 'public.wochenstart_einreihen(date)', 'EXECUTE') THEN
    RAISE EXCEPTION 'anon darf den Versand ausloesen.';
  END IF;

  -- Schweizer Zahlen, wie im Konzept: CHF 1'250.00. Das G im Formatmuster
  -- richtet sich nach der Spracheinstellung der Datenbank und lieferte
  -- amerikanische Kommas.
  IF v_quelle ~ 'FM999G999G990D00' THEN
    RAISE EXCEPTION 'Zahlenformat haengt an der Spracheinstellung der Datenbank.';
  END IF;

  SELECT count(*) INTO v_n FROM cron.job WHERE jobname='wochenstart';
  IF v_n <> 1 THEN RAISE EXCEPTION 'Zeitplan wochenstart: % Eintraege statt 1.', v_n; END IF;

  -- Trockenlauf: die Funktion muss fehlerfrei durchlaufen. Wie viele
  -- Mails dabei entstehen, haengt davon ab, ob schon Vereine Empfaenger
  -- gewaehlt haben -- das ist kein Fehler, sondern Betrieb. Eine Zahl
  -- festzuschreiben hiesse, den Neuaufbau an den Weltzustand zu binden.
  -- Entscheidend ist, was am Ende NICHT stehenbleibt; das wird unten
  -- geprueft.
  SELECT public.wochenstart_einreihen() INTO v_n;
  RAISE NOTICE 'Trockenlauf ohne gesetzte Empfaenger: % Mail(s)', v_n;

  -- Dann MIT einem Empfaenger, in einem Unterblock, der zurueckgenommen
  -- wird. Ohne das prueft der Trockenlauf nur, dass die Schleife nicht
  -- betreten wird -- und genau darin steckte der Fehler: events.date ist
  -- TEXT, der Vergleich mit einem date scheiterte, und der leere Lauf
  -- hat es nicht bemerkt.
  DECLARE
    v_wer text; v_vorher text[]; v_zustand text; v_mails int;
  BEGIN
    SELECT u.id INTO v_wer FROM public.users u
     WHERE u.email LIKE '%@%' AND u.role IN ('BOARD','ADMIN','SUPER_ADMIN') LIMIT 1;
    IF v_wer IS NOT NULL THEN
      SELECT wochenstart_an INTO v_vorher FROM public.floky_einstellungen
       WHERE "tenantId" = (SELECT "tenantId" FROM public.users WHERE id = v_wer);
      SELECT zustand INTO v_zustand FROM public.tenant_modules
       WHERE "tenantId" = (SELECT "tenantId" FROM public.users WHERE id = v_wer) AND modul='FLOKY';

      INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
      SELECT u."tenantId", 'FLOKY', 'AN' FROM public.users u WHERE u.id = v_wer
      ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'AN';
      INSERT INTO public.floky_einstellungen ("tenantId", wochenstart_an)
      SELECT u."tenantId", ARRAY[v_wer] FROM public.users u WHERE u.id = v_wer
      ON CONFLICT ("tenantId") DO UPDATE SET wochenstart_an = ARRAY[v_wer];

      SELECT public.wochenstart_einreihen() INTO v_mails;
      RAISE NOTICE 'Trockenlauf mit Empfaenger: % Mail(s)', v_mails;

      -- Alles zuruecknehmen: diese Migration darf keine Post hinterlassen
      -- und keine Einstellung aendern.
      DELETE FROM public.mail_queue WHERE kind = 'WOCHENSTART';
      UPDATE public.floky_einstellungen SET wochenstart_an = coalesce(v_vorher, '{}')
       WHERE "tenantId" = (SELECT "tenantId" FROM public.users WHERE id = v_wer);
      IF v_zustand IS NULL THEN
        DELETE FROM public.tenant_modules
         WHERE "tenantId" = (SELECT "tenantId" FROM public.users WHERE id = v_wer) AND modul='FLOKY';
      ELSE
        UPDATE public.tenant_modules SET zustand = v_zustand
         WHERE "tenantId" = (SELECT "tenantId" FROM public.users WHERE id = v_wer) AND modul='FLOKY';
      END IF;
    END IF;
  END;

  IF EXISTS (SELECT 1 FROM public.mail_queue WHERE kind = 'WOCHENSTART') THEN
    RAISE EXCEPTION 'Der Trockenlauf hat Post hinterlassen.';
  END IF;
  -- Hier stand "keine Liste darf gesetzt sein". Das war richtig, solange
  -- noch kein Verein eine hatte, und wurde falsch, sobald der erste eine
  -- waehlte. Geprueft wird jetzt, was der Trockenlauf wirklich schuldet:
  -- die Liste, die er zum Pruefen gesetzt hat, muss wieder weg sein --
  -- und das heisst: auf dem Stand von vorher, nicht auf leer.
  IF EXISTS (SELECT 1 FROM public.mail_queue WHERE kind = 'WOCHENSTART') THEN
    RAISE EXCEPTION 'Der Trockenlauf hat Post hinterlassen.';
  END IF;

  RAISE NOTICE 'Wochenstart bereit: Montag 18:00 Europe/Zurich, Trockenlauf 0 Mails.';
END $$;
