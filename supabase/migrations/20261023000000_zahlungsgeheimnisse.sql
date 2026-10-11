-- Zwei Dinge an den Zahlungseinstellungen.
--
-- ERSTENS: settings/global verschwindet, aber nicht einfach so.
--
-- Die Zeile ist eine Kopie von settings/payment. Nichts liest sie --
-- geprueft im Anwendungscode, in den Edge Functions, in allen
-- Datenbankfunktionen, Regeln und Views. Sie wurde am 18.09. bewusst
-- als "Sicherung der Bankangaben" stehengelassen; eine spaetere
-- Migration hat ihr die PayPal-Zugangsdaten entfernt und die
-- Bankangaben belassen.
--
-- Eine Sicherung, die nicht mitgepflegt wird, ist aber schlechter als
-- keine: sie friert einen Stand ein, und wer sie spaeter zum
-- Wiederherstellen nimmt, holt veraltete Bankangaben zurueck. Darum
-- wird der Inhalt in ein datiertes Archiv gelegt und die Zeile
-- entfernt. Verloren geht nichts, und es gibt keine zweite Wahrheit
-- mehr.
--
-- ZWEITENS: das PayPal-Geheimnis zieht aus settings/payment aus.
--
-- Jeder Verein braucht sein eigenes -- Mitglieder ausserhalb der
-- Schweiz zahlen darueber. Es kann also kein einzelnes Secret der
-- Plattform sein, es muss in der Datenbank liegen.
--
-- In settings/payment liegt es aber falsch: die Tabelle ist fuer den
-- Vorstand lesbar. Gemessen -- ein gewoehnliches Mitglied sieht 0
-- Zeilen, der Vorstand alle 4 samt Geheimnis. Fuenf Personen koennen es
-- im Browser auslesen, und gebraucht wird es dort von niemandem.
--
-- Die oeffentliche View entfernt es schon (payment - 'paypalSecret' -
-- 'paypalClientId') -- jemand hat den Punkt also gesehen und an der
-- richtigen Stelle gelost. Die Tabelle selbst blieb offen.
--
-- Darum eine eigene Tabelle, die NIEMAND lesen kann ausser der
-- Serverrolle. Die Administration SETZT das Geheimnis und sieht
-- danach nur, dass es hinterlegt ist -- dieselbe Regel wie beim
-- SMTP-Kennwort: eintragen ja, nachlesen nein.

-- ---------------------------------------------- 1. Archiv und Abschied
CREATE TABLE IF NOT EXISTS public.settings_archiv (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId" text NOT NULL,
  kennung    text NOT NULL,
  inhalt     jsonb NOT NULL,
  grund      text,
  gelegt_am  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.settings_archiv ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.settings_archiv FROM anon, authenticated;

COMMENT ON TABLE public.settings_archiv IS
  'Weggeraeumte Einstellungszeilen, datiert. Damit "nichts geht verloren" '
  'nicht bedeutet, dass veraltete Kopien im Betrieb stehenbleiben.';

DO $$
DECLARE v_n int;
BEGIN
  INSERT INTO public.settings_archiv ("tenantId", kennung, inhalt, grund)
  SELECT s."tenantId", s.id,
         jsonb_build_object('payment', s.payment, 'company', s.company,
                            'branding', s.branding, 'system', s.system,
                            'data', s.data),
         'Kopie von settings/payment, von nichts gelesen; am 18.09. als '
         || 'Sicherung der Bankangaben stehengelassen'
    FROM public.settings s
   WHERE s.id = 'global'
     AND NOT EXISTS (SELECT 1 FROM public.settings_archiv a
                      WHERE a."tenantId" = s."tenantId" AND a.kennung = 'global');
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '% Zeile(n) settings/global archiviert', v_n;

  -- Erst loeschen, wenn der Inhalt wirklich im Archiv liegt. Die
  -- Bedingung ist nicht Zierde: ohne sie koennte ein fehlgeschlagener
  -- INSERT unbemerkt zu einem DELETE fuehren, das nichts gesichert hat.
  DELETE FROM public.settings s
   WHERE s.id = 'global'
     AND EXISTS (SELECT 1 FROM public.settings_archiv a
                  WHERE a."tenantId" = s."tenantId" AND a.kennung = 'global'
                    AND a.inhalt -> 'payment' ? 'iban');
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '% Zeile(n) settings/global entfernt', v_n;
END $$;


-- ------------------------------------------- 2. Das Geheimnis umziehen
CREATE TABLE IF NOT EXISTS public.zahlungsgeheimnisse (
  "tenantId"        text PRIMARY KEY,
  paypal_client_id  text,
  paypal_secret     text,
  geaendert_am      timestamptz NOT NULL DEFAULT now(),
  geaendert_von     text
);
ALTER TABLE public.zahlungsgeheimnisse ENABLE ROW LEVEL SECURITY;

-- Keine Regel, kein GRANT: die Tabelle ist fuer anon und authenticated
-- vollstaendig unerreichbar. Auch fuer die Administration -- sie setzt
-- ueber die Funktion unten und liest nie zurueck.
REVOKE ALL ON TABLE public.zahlungsgeheimnisse FROM anon, authenticated;

COMMENT ON TABLE public.zahlungsgeheimnisse IS
  'Zahlungszugangsdaten je Verein. Fuer kein angemeldetes Konto lesbar; '
  'nur die Serverrolle kommt heran. Gesetzt wird ueber '
  'zahlungsgeheimnis_setzen, der Stand ueber zahlungsgeheimnis_stand.';

-- Vorhandene Werte umziehen, dann aus settings entfernen.
DO $$
DECLARE v_n int;
BEGIN
  INSERT INTO public.zahlungsgeheimnisse ("tenantId", paypal_client_id, paypal_secret, geaendert_von)
  SELECT s."tenantId", s.payment ->> 'paypalClientId', s.payment ->> 'paypalSecret',
         'Umzug aus settings/payment'
    FROM public.settings s
   WHERE s.id = 'payment'
     AND coalesce(s.payment ->> 'paypalSecret', '') <> ''
  ON CONFLICT ("tenantId") DO NOTHING;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '% Zugangsdatensatz/-saetze umgezogen', v_n;

  -- Nur dort entfernen, wo der Umzug nachweislich angekommen ist.
  UPDATE public.settings s
     SET payment = s.payment - 'paypalSecret' - 'paypalClientId'
   WHERE s.id = 'payment'
     AND (s.payment ? 'paypalSecret' OR s.payment ? 'paypalClientId')
     AND EXISTS (SELECT 1 FROM public.zahlungsgeheimnisse g
                  WHERE g."tenantId" = s."tenantId"
                    AND coalesce(g.paypal_secret,'') =
                        coalesce(s.payment ->> 'paypalSecret',''));
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE '% Zeile(n) in settings bereinigt', v_n;
END $$;


-- Setzen -- und nur das.
CREATE OR REPLACE FUNCTION public.zahlungsgeheimnis_setzen(
  p_client_id text, p_secret text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_n int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Zugangsdaten sind Sache der Administration, nicht des Vorstands.
  -- Wer das Geheimnis setzen kann, kann Zahlungen umleiten.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf Zahlungszugangsdaten setzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein bestimmbar.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.zahlungsgeheimnisse
    ("tenantId", paypal_client_id, paypal_secret, geaendert_am, geaendert_von)
  VALUES (v_verein, nullif(btrim(coalesce(p_client_id,'')), ''),
          nullif(btrim(coalesce(p_secret,'')), ''), now(),
          public.current_user_row_id())
  ON CONFLICT ("tenantId") DO UPDATE
     SET paypal_client_id = EXCLUDED.paypal_client_id,
         paypal_secret = EXCLUDED.paypal_secret,
         geaendert_am = now(),
         geaendert_von = EXCLUDED.geaendert_von;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Zugangsdaten wurden nicht gespeichert.'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Gibt den STAND zurueck, nicht den Wert. Ein Rueckgabewert mit dem
  -- Geheimnis darin waere derselbe Fehler eine Ebene weiter: er stuende
  -- in der Antwort, im Protokoll des Browsers und womoeglich in einer
  -- Fehlermeldung.
  RETURN public.zahlungsgeheimnis_stand();
END $$;

REVOKE ALL ON FUNCTION public.zahlungsgeheimnis_setzen(text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zahlungsgeheimnis_setzen(text,text) TO authenticated;


-- Der Stand: ob etwas hinterlegt ist, seit wann, von wem. Nie der Wert.
CREATE OR REPLACE FUNCTION public.zahlungsgeheimnis_stand()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); g record;
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO g FROM public.zahlungsgeheimnisse WHERE "tenantId" = v_verein;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('hinterlegt', false);
  END IF;

  RETURN jsonb_build_object(
    'hinterlegt', coalesce(g.paypal_secret, '') <> '',
    'client_id_hinterlegt', coalesce(g.paypal_client_id, '') <> '',
    -- Die letzten vier Zeichen, damit man zwei Schluessel unterscheiden
    -- kann, ohne einen davon zu kennen. Vier aus etwa achtzig lassen
    -- sich nicht zurueckrechnen.
    'endet_auf', CASE WHEN length(coalesce(g.paypal_secret,'')) > 8
                      THEN right(g.paypal_secret, 4) ELSE NULL END,
    'geaendert_am', g.geaendert_am,
    'geaendert_von', (SELECT coalesce(u."displayName", u.id) FROM public.users u
                       WHERE u.id = g.geaendert_von));
END $$;

REVOKE ALL ON FUNCTION public.zahlungsgeheimnis_stand() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.zahlungsgeheimnis_stand() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int; v_quelle text;
BEGIN
  -- 1. settings/global ist weg, und der Inhalt ist im Archiv.
  SELECT count(*) INTO v_n FROM public.settings WHERE id = 'global';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'settings/global besteht noch (% Zeilen).', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM public.settings_archiv
   WHERE kennung = 'global' AND inhalt -> 'payment' ? 'iban';
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Bankangaben aus settings/global liegen NICHT im Archiv -- '
                    'dann waere die Zeile ohne Sicherung verschwunden.';
  END IF;

  -- 2. Die Bankangaben stehen weiter in settings/payment. Das ist die
  --    Zeile, die gelesen wird; waere sie leer, waeren die Rechnungen hin.
  SELECT count(*) INTO v_n FROM public.settings
   WHERE id = 'payment' AND coalesce(payment ->> 'iban','') <> '';
  IF v_n = 0 THEN
    RAISE EXCEPTION 'In settings/payment steht keine IBAN mehr.';
  END IF;

  -- 3. Das Geheimnis ist aus settings verschwunden ...
  SELECT count(*) INTO v_n FROM public.settings
   WHERE coalesce(payment ->> 'paypalSecret','') <> '';
  IF v_n > 0 THEN
    RAISE EXCEPTION '% Zeile(n) in settings tragen noch ein PayPal-Geheimnis.', v_n;
  END IF;
  -- ... und in der neuen Tabelle angekommen.
  SELECT count(*) INTO v_n FROM public.zahlungsgeheimnisse
   WHERE coalesce(paypal_secret,'') <> '';
  IF v_n = 0 THEN
    RAISE NOTICE 'Kein PayPal-Geheimnis vorhanden -- es war auch keines gesetzt.';
  END IF;

  -- 4. Niemand kann die neue Tabelle lesen.
  IF has_table_privilege('authenticated', 'public.zahlungsgeheimnisse', 'SELECT')
     OR has_table_privilege('anon', 'public.zahlungsgeheimnisse', 'SELECT') THEN
    RAISE EXCEPTION 'Die Zugangsdaten sind lesbar -- der ganze Umzug waere sinnlos.';
  END IF;

  -- 5. Und der Stand gibt den Wert nicht heraus.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='zahlungsgeheimnis_stand';
  IF v_quelle ~ '''paypal_secret''\s*,\s*g\.paypal_secret' THEN
    RAISE EXCEPTION 'zahlungsgeheimnis_stand gibt das Geheimnis zurueck.';
  END IF;
  IF v_quelle !~ 'right\(g\.paypal_secret, 4\)' THEN
    RAISE EXCEPTION 'Der Stand nennt nicht die letzten vier Zeichen -- dann lassen '
                    'sich zwei Schluessel nicht unterscheiden.';
  END IF;

  RAISE NOTICE 'settings/global archiviert und entfernt; PayPal-Geheimnis umgezogen '
               'und fuer kein Konto lesbar.';
END $$;
