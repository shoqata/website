-- Auf der Betreiber-Domain gibt es keinen Verein: current_tenant() liefert
-- NULL, und Speichern scheiterte mit "Kein Verein zugeordnet". Fuer einen
-- Plattformverwalter ist dort der Mandant 'plattform' gemeint -- derselbe,
-- unter dem die Kontaktanfragen von unityhub in der Warteschlange liegen.
CREATE OR REPLACE FUNCTION public.mail_einstellungen_lesen(p_verein text DEFAULT NULL)
RETURNS TABLE (
  verein text, host text, port integer, benutzer text, absender text,
  absendername text, tls text, aktiv boolean, kennwort_gesetzt boolean,
  geaendert_am timestamptz, geaendert_von text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ziel text; v_eigen text := public.current_tenant();
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge einsehen.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang einsehen.';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen,
                       CASE WHEN public.is_platform_admin() THEN 'plattform' END);
  END IF;

  RETURN QUERY
    SELECT m."tenantId", m.host, m.port, m.benutzer, m.absender, m.absendername,
           m.tls, m.aktiv, coalesce(btrim(m.kennwort), '') <> '',
           m.geaendert_am, m.geaendert_von
      FROM public.mail_settings m
     WHERE m."tenantId" = v_ziel;
END $$;

CREATE OR REPLACE FUNCTION public.mail_einstellungen_speichern(
  p_host text, p_port integer, p_benutzer text, p_absender text,
  p_absendername text, p_tls text, p_aktiv boolean, p_kennwort text DEFAULT NULL,
  p_verein text DEFAULT NULL
) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ziel text; v_wer text; v_eigen text := public.current_tenant();
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(v_eigen,'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge aendern.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
    END IF;
    v_ziel := coalesce(p_verein, v_eigen,
                       CASE WHEN public.is_platform_admin() THEN 'plattform' END);
  END IF;
  IF v_ziel IS NULL THEN
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
  VALUES (v_ziel, nullif(btrim(p_host),''), coalesce(p_port, 587),
          nullif(btrim(p_benutzer),''), nullif(btrim(p_absender),''),
          nullif(btrim(p_absendername),''), p_tls, coalesce(p_aktiv, true),
          nullif(btrim(p_kennwort),''), now(), v_wer)
  ON CONFLICT ("tenantId") DO UPDATE SET
    host = excluded.host, port = excluded.port, benutzer = excluded.benutzer,
    absender = excluded.absender, absendername = excluded.absendername,
    tls = excluded.tls, aktiv = excluded.aktiv,
    kennwort = coalesce(excluded.kennwort, m.kennwort),
    geaendert_am = now(), geaendert_von = excluded.geaendert_von;

  RETURN 'gespeichert fuer ' || v_ziel;
END $$;

GRANT EXECUTE ON FUNCTION public.mail_einstellungen_lesen(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text,text) TO authenticated;
