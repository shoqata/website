-- Auch der Betreiber braucht einen Postausgang.
--
-- Gemessen: die wartende Nachricht (Kontaktanfrage von unityhub an
-- email@trifti.ch) traegt den Mandanten 'plattform'. Eingetragen war nur
-- einer fuer 'koretini'. Die Funktion fiel deshalb auf die leeren Secrets
-- zurueck und meldete "Kein Postausgang hinterlegt" -- richtig fuer diese
-- Nachricht, aber unverstaendlich fuer jemanden, der gerade einen
-- eingetragen hat.
--
-- Ueber den Postausgang eines Vereins zu versenden waere ein
-- Mandantenbruch. Der Betreiber bekommt seinen eigenen.

-- Lesen und Speichern duerfen jetzt einen Mandanten benennen -- aber nur,
-- wer Plattformverwalter ist. Fuer alle anderen bleibt es beim eigenen.
CREATE OR REPLACE FUNCTION public.mail_einstellungen_lesen(p_verein text DEFAULT NULL)
RETURNS TABLE (
  verein text, host text, port integer, benutzer text, absender text,
  absendername text, tls text, aktiv boolean, kennwort_gesetzt boolean,
  geaendert_am timestamptz, geaendert_von text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ziel text;
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(public.current_tenant(),'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge einsehen.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang einsehen.';
    END IF;
    v_ziel := coalesce(p_verein, public.current_tenant());
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
DECLARE v_ziel text; v_wer text;
BEGIN
  IF p_verein IS NOT NULL AND p_verein <> coalesce(public.current_tenant(),'') THEN
    IF NOT public.is_platform_admin() THEN
      RAISE EXCEPTION 'Nur der Plattformbetreiber darf fremde Postausgaenge aendern.';
    END IF;
    v_ziel := p_verein;
  ELSE
    IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
      RAISE EXCEPTION 'Nur die Vereinsverwaltung darf den Postausgang aendern.';
    END IF;
    v_ziel := coalesce(p_verein, public.current_tenant());
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

  RETURN 'gespeichert';
END $$;

-- Welche Mandanten haben Post offen, aber keinen Postausgang? Das beantwortet
-- die Maske, statt dass jemand raten muss.
CREATE OR REPLACE FUNCTION public.postausgang_luecken()
RETURNS TABLE (verein text, offen bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT (public.is_platform_admin() OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nicht berechtigt.';
  END IF;
  RETURN QUERY
    SELECT q."tenantId", count(*)
      FROM public.mail_queue q
     WHERE q.status = 'PENDING'
       AND NOT EXISTS (SELECT 1 FROM public.mail_settings m
                        WHERE m."tenantId" = q."tenantId" AND m.aktiv
                          AND coalesce(btrim(m.host),'') <> ''
                          AND coalesce(btrim(m.benutzer),'') <> ''
                          AND coalesce(btrim(m.kennwort),'') <> ''
                          AND coalesce(btrim(m.absender),'') <> '')
     GROUP BY 1 ORDER BY 2 DESC;
END $$;

REVOKE ALL ON FUNCTION public.mail_einstellungen_lesen(text) FROM public, anon;
REVOKE ALL ON FUNCTION public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text,text) FROM public, anon;
REVOKE ALL ON FUNCTION public.postausgang_luecken() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mail_einstellungen_lesen(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.postausgang_luecken() TO authenticated;

-- Die alten Signaturen ablegen, damit nicht zwei Fassungen nebeneinander
-- stehen und PostgREST sich die falsche aussucht.
DROP FUNCTION IF EXISTS public.mail_einstellungen_lesen();
DROP FUNCTION IF EXISTS public.mail_einstellungen_speichern(text,integer,text,text,text,text,boolean,text);

-- Kontrolle: direkt abgefragt, nicht ueber postausgang_luecken() -- die
-- Funktion prueft Rechte, und die Migrationsrolle ist weder Verwaltung noch
-- Betreiber.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT q."tenantId" AS verein, count(*) AS offen
      FROM public.mail_queue q
     WHERE q.status = 'PENDING'
       AND NOT EXISTS (SELECT 1 FROM public.mail_settings m
                        WHERE m."tenantId" = q."tenantId" AND m.aktiv
                          AND coalesce(btrim(m.host),'') <> ''
                          AND coalesce(btrim(m.benutzer),'') <> ''
                          AND coalesce(btrim(m.kennwort),'') <> ''
                          AND coalesce(btrim(m.absender),'') <> '')
     GROUP BY 1
  LOOP
    RAISE NOTICE 'Ohne Postausgang: Mandant % mit % wartenden Nachrichten', r.verein, r.offen;
  END LOOP;
END $$;
