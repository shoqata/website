-- Der Postausgang wird einstellbar.
--
-- Bisher las die Funktion send-mail-queue ihre Zugangsdaten ausschliesslich
-- aus den Secrets der Funktion. In der Verwaltung stand dazu ein Hinweis aus
-- der Firebase-Zeit ("Trigger Email", "Firebase Console") -- die Erweiterung
-- gibt es hier nicht, und einstellen liess sich nichts.
--
-- Die Angaben gehoeren NICHT in settings: public_settings liefert die
-- Spalten system und data vollstaendig an anonyme Besucher aus. Ein Kennwort
-- dort waere mit dem Schluessel aus dem Bundle abrufbar -- derselbe Fehler,
-- den das PayPal-Geheimnis schon einmal hatte.
--
-- Deshalb eine eigene Tabelle ohne jede Regel: ueber die Programm-
-- schnittstelle kommt niemand heran, weder lesend noch schreibend. Der Weg
-- fuehrt ausschliesslich ueber die beiden Funktionen weiter unten, und das
-- Kennwort verlaesst die Datenbank nie in Richtung Browser.

CREATE TABLE IF NOT EXISTS public.mail_settings (
  "tenantId"     text PRIMARY KEY,
  host           text,
  port           integer NOT NULL DEFAULT 587,
  benutzer       text,
  kennwort       text,          -- verlaesst die Datenbank nie zum Browser
  absender       text,
  absendername   text,
  tls            text NOT NULL DEFAULT 'starttls',
  aktiv          boolean NOT NULL DEFAULT true,
  -- Geteiltes Kennwort fuer den Zeitplan. Wird hier erzeugt, damit niemand
  -- es von Hand in die Secrets eintragen muss.
  zeitplan_token text NOT NULL DEFAULT encode(extensions.gen_random_bytes(24), 'hex'),
  geaendert_am   timestamptz NOT NULL DEFAULT now(),
  geaendert_von  text,
  CONSTRAINT mail_settings_tls_gueltig CHECK (tls IN ('starttls','tls','keine')),
  CONSTRAINT mail_settings_port_gueltig CHECK (port > 0 AND port < 65536)
);

ALTER TABLE public.mail_settings ENABLE ROW LEVEL SECURITY;
-- Keine Regel, keine Rechte: absichtlich. Siehe oben.
REVOKE ALL ON public.mail_settings FROM anon, authenticated;

-- --- Lesen: alles ausser dem Kennwort --------------------------------------
CREATE OR REPLACE FUNCTION public.mail_einstellungen_lesen()
RETURNS TABLE (
  host text, port integer, benutzer text, absender text, absendername text,
  tls text, aktiv boolean, kennwort_gesetzt boolean,
  geaendert_am timestamptz, geaendert_von text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang einsehen.';
  END IF;

  RETURN QUERY
    SELECT m.host, m.port, m.benutzer, m.absender, m.absendername, m.tls, m.aktiv,
           coalesce(btrim(m.kennwort), '') <> '',
           m.geaendert_am, m.geaendert_von
      FROM public.mail_settings m
     WHERE m."tenantId" = v_verein;
END $$;

-- --- Speichern -------------------------------------------------------------
-- Ein leeres Kennwort bedeutet "unveraendert lassen", nicht "loeschen". Sonst
-- wuerde jedes Speichern der uebrigen Felder den Postausgang stilllegen,
-- weil das Formular das Kennwort nie zurueckbekommt und darum leer ist.
CREATE OR REPLACE FUNCTION public.mail_einstellungen_speichern(
  p_host text, p_port integer, p_benutzer text, p_absender text,
  p_absendername text, p_tls text, p_aktiv boolean, p_kennwort text DEFAULT NULL
) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant(); v_wer text;
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
  END IF;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein zugeordnet.';
  END IF;
  IF coalesce(p_tls,'') NOT IN ('starttls','tls','keine') THEN
    RAISE EXCEPTION 'Verschluesselung muss starttls, tls oder keine sein.';
  END IF;
  IF coalesce(btrim(p_absender),'') <> '' AND p_absender !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Die Absenderadresse ist keine gueltige E-Mail-Adresse.';
  END IF;

  SELECT coalesce(u.email, auth.uid()::text) INTO v_wer
    FROM public.users u WHERE u.id = public.current_user_row_id();

  INSERT INTO public.mail_settings AS m
         ("tenantId", host, port, benutzer, absender, absendername, tls, aktiv,
          kennwort, geaendert_am, geaendert_von)
  VALUES (v_verein, nullif(btrim(p_host),''), coalesce(p_port, 587),
          nullif(btrim(p_benutzer),''), nullif(btrim(p_absender),''),
          nullif(btrim(p_absendername),''), p_tls, coalesce(p_aktiv, true),
          nullif(btrim(p_kennwort),''), now(), v_wer)
  ON CONFLICT ("tenantId") DO UPDATE SET
    host = excluded.host, port = excluded.port, benutzer = excluded.benutzer,
    absender = excluded.absender, absendername = excluded.absendername,
    tls = excluded.tls, aktiv = excluded.aktiv,
    kennwort = coalesce(excluded.kennwort, m.kennwort),
    geaendert_am = now(), geaendert_von = excluded.geaendert_von;

  RETURN 'gespeichert';
END $$;

-- --- Kennwort loeschen -----------------------------------------------------
-- Ausdruecklich und getrennt, weil "leer speichern" oben bewusst nichts tut.
CREATE OR REPLACE FUNCTION public.mail_kennwort_loeschen()
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public.current_tenant();
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
  END IF;
  UPDATE public.mail_settings SET kennwort = NULL, geaendert_am = now()
   WHERE "tenantId" = v_verein;
  RETURN 'geloescht';
END $$;

REVOKE ALL ON FUNCTION public.mail_einstellungen_lesen() FROM public, anon;
REVOKE ALL ON FUNCTION public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text) FROM public, anon;
REVOKE ALL ON FUNCTION public.mail_kennwort_loeschen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mail_einstellungen_lesen() TO authenticated;
GRANT EXECUTE ON FUNCTION public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mail_kennwort_loeschen() TO authenticated;

DO $$ BEGIN RAISE NOTICE 'Tabelle und Funktionen angelegt.'; END $$;
