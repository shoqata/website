-- Kontenplan erweitern, Jahreswechsel, Floky-Preis.

-- ------------------------------------------------------------ Floky
-- Entscheid des Betreibers: CHF 9.90 pro Monat fuer 300 Anfragen.
UPDATE public.modules SET preis_monat = 9.90 WHERE schluessel = 'FLOKY';

-- ------------------------------------------------------------ Konten
-- Ein Konto anlegen. Die Klasse folgt dem Schweizer KMU-Kontenrahmen aus
-- der ersten Ziffer, damit Bilanz und Erfolgsrechnung das Konto richtig
-- einordnen: 1 Aktiven, 2 Passiven, 3 Ertrag, 4-8 Aufwand, 9 Abschluss.
CREATE OR REPLACE FUNCTION public.konto_klasse_vorschlag(p_code text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE left(btrim(coalesce(p_code, '')), 1)
    WHEN '1' THEN 'ASSET' WHEN '2' THEN 'LIABILITY' WHEN '3' THEN 'REVENUE'
    WHEN '4' THEN 'EXPENSE' WHEN '5' THEN 'EXPENSE' WHEN '6' THEN 'EXPENSE'
    WHEN '7' THEN 'EXPENSE' WHEN '8' THEN 'EXPENSE' WHEN '9' THEN 'LIABILITY'
  END;
$$;

CREATE OR REPLACE FUNCTION public._konto_recht()
RETURNS text
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand pflegen den Kontenplan.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT public.modul_aktiv('BUCHHALTUNG') THEN
    RAISE EXCEPTION 'Das Modul Buchhaltung ist fuer diesen Verein nicht aktiv.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_verein;
END $$;
REVOKE ALL ON FUNCTION public._konto_recht() FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.konto_anlegen(p_code text, p_name text, p_klasse text DEFAULT NULL,
                                                p_kategorie text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._konto_recht(); v_code text := btrim(coalesce(p_code, ''));
        v_klasse text;
BEGIN
  IF v_code !~ '^[0-9]{3,6}$' THEN
    RAISE EXCEPTION 'Die Kontonummer besteht aus 3 bis 6 Ziffern, z. B. 6510.' USING ERRCODE = 'check_violation';
  END IF;
  IF coalesce(btrim(p_name), '') = '' THEN
    RAISE EXCEPTION 'Das Konto braucht einen Namen.' USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.accounting_accounts a WHERE a."tenantId" = v_verein AND a.code = v_code) THEN
    RAISE EXCEPTION 'Das Konto % gibt es schon.', v_code USING ERRCODE = 'unique_violation';
  END IF;
  v_klasse := upper(coalesce(nullif(btrim(p_klasse), ''), public.konto_klasse_vorschlag(v_code)));
  IF v_klasse NOT IN ('ASSET','LIABILITY','REVENUE','EXPENSE') THEN
    RAISE EXCEPTION 'Unbekannte Kontoart.' USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category, "systemAccount")
  VALUES (v_code, v_verein, v_code, btrim(p_name), v_klasse, nullif(btrim(p_kategorie), ''), false);
  RETURN v_code;
END $$;

-- Namen und Gruppe aendern. Nummer und Art bleiben: an ihnen haengen die
-- Buchungen und die Einordnung in Bilanz und Erfolgsrechnung.
CREATE OR REPLACE FUNCTION public.konto_aendern(p_code text, p_name text, p_kategorie text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._konto_recht();
BEGIN
  IF coalesce(btrim(p_name), '') = '' THEN
    RAISE EXCEPTION 'Das Konto braucht einen Namen.' USING ERRCODE = 'check_violation';
  END IF;
  UPDATE public.accounting_accounts SET name = btrim(p_name), category = nullif(btrim(p_kategorie), '')
   WHERE "tenantId" = v_verein AND code = p_code;
  IF NOT FOUND THEN RAISE EXCEPTION 'Konto % nicht gefunden.', p_code; END IF;
END $$;

-- Loeschen nur, solange nichts darauf gebucht ist. Systemkonten und das
-- Vortragskonto 9100 bleiben.
CREATE OR REPLACE FUNCTION public.konto_loeschen(p_code text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._konto_recht(); v_n int;
BEGIN
  IF p_code = '9100' OR EXISTS (SELECT 1 FROM public.accounting_accounts
       WHERE "tenantId" = v_verein AND code = p_code AND coalesce("systemAccount", false)) THEN
    RAISE EXCEPTION 'Dieses Konto braucht das System, es bleibt.' USING ERRCODE = 'check_violation';
  END IF;
  SELECT count(*) INTO v_n FROM public.accounting_journal j
   WHERE j."tenantId" = v_verein AND (j."debitCode" = p_code OR j."creditCode" = p_code);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'Auf Konto % sind % Buchungen. Es laesst sich nur umbenennen.', p_code, v_n
      USING ERRCODE = 'check_violation';
  END IF;
  DELETE FROM public.accounting_accounts WHERE "tenantId" = v_verein AND code = p_code;
  IF NOT FOUND THEN RAISE EXCEPTION 'Konto % nicht gefunden.', p_code; END IF;
END $$;

REVOKE ALL ON FUNCTION public.konto_anlegen(text, text, text, text) FROM public, anon;
REVOKE ALL ON FUNCTION public.konto_aendern(text, text, text) FROM public, anon;
REVOKE ALL ON FUNCTION public.konto_loeschen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.konto_anlegen(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.konto_aendern(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.konto_loeschen(text) TO authenticated;

-- ------------------------------------------------------------ Vereinsjahr
-- Das Arbeitsjahr: das Kalenderjahr, oder ein spaeteres, wenn es schon
-- eroeffnet ist. Wer im Dezember 2026 abschliesst, arbeitet danach in
-- 2027 -- ueberall, nicht nur in der Buchhaltung. Dazu die Liste der
-- waehlbaren Jahre: die letzten fuenf und alle Geschaeftsjahre.
CREATE OR REPLACE FUNCTION public.vereinsjahre()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH v AS (SELECT coalesce(public.current_tenant(), public.request_tenant()) AS verein,
                    extract(year FROM now())::int AS kalender),
  f AS (SELECT fy.year, fy.status FROM public.fiscal_years fy, v WHERE fy."tenantId" = v.verein),
  akt AS (SELECT greatest(v.kalender, coalesce((SELECT max(year) FROM f WHERE status = 'OPEN'), v.kalender)) AS jahr FROM v)
  SELECT jsonb_build_object(
    'aktuell', (SELECT jahr FROM akt),
    'jahre', (SELECT jsonb_agg(j ORDER BY j DESC) FROM (
               SELECT generate_series((SELECT kalender FROM v) - 4, (SELECT jahr FROM akt)) AS j
               UNION SELECT year FROM f) x),
    'geschlossen', coalesce((SELECT jsonb_agg(year ORDER BY year) FROM f WHERE status = 'CLOSED'), '[]'::jsonb),
    'offen', coalesce((SELECT jsonb_agg(year ORDER BY year) FROM f WHERE status = 'OPEN'), '[]'::jsonb));
$$;
REVOKE ALL ON FUNCTION public.vereinsjahre() FROM public;
GRANT EXECUTE ON FUNCTION public.vereinsjahre() TO anon, authenticated;

-- Ein neues Jahr eroeffnen, ohne Buchhaltung (Paket Light): der Verein
-- hat keinen Abschluss, braucht aber trotzdem den Wechsel ins neue Jahr.
-- Mit Buchhaltung eroeffnet jahresabschluss() das Folgejahr.
CREATE OR REPLACE FUNCTION public.vereinsjahr_eroeffnen(p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_kalender int := extract(year FROM now())::int;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF v_verein IS NULL OR NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand eroeffnen ein Jahr.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF public.modul_aktiv('BUCHHALTUNG') AND EXISTS (
       SELECT 1 FROM public.fiscal_years WHERE "tenantId" = v_verein AND year = p_jahr - 1 AND status <> 'CLOSED')
     AND EXISTS (SELECT 1 FROM public.accounting_journal WHERE "tenantId" = v_verein AND substr(date,1,4) = (p_jahr-1)::text) THEN
    RAISE EXCEPTION 'Mit Buchhaltung wird % mit dem Jahresabschluss % eroeffnet.', p_jahr, p_jahr - 1
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_jahr < v_kalender OR p_jahr > v_kalender + 1 THEN
    RAISE EXCEPTION 'Eroeffnen laesst sich das laufende oder das naechste Jahr.' USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  VALUES (p_jahr::text, v_verein, p_jahr, 'OPEN')
  ON CONFLICT ("tenantId", id) DO NOTHING;
  RETURN public.vereinsjahre();
END $$;
REVOKE ALL ON FUNCTION public.vereinsjahr_eroeffnen(int) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vereinsjahr_eroeffnen(int) TO authenticated;

NOTIFY pgrst, 'reload schema';
