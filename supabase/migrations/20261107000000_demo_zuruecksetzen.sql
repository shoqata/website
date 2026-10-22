-- Demoverein zuruecksetzen.
--
-- Nach jeder Vorfuehrung sieht der Demoverein anders aus: Rechnungen sind
-- als bezahlt markiert, Mitglieder bearbeitet, Spenden bescheinigt. Damit die
-- naechste Vorfuehrung wieder vom selben Stand ausgeht, haelt diese Migration
-- eine Vorlage fest und kann sie auf Knopfdruck wiederherstellen.
--
-- Was dazugehoert:
--   * alle Tabellen mit "tenantId", beschraenkt auf tenantId 'demo',
--   * die Passwoerter aller Zugaenge des Demovereins, auf ein gemeinsames;
--     offene Sitzungen dieser Zugaenge werden beendet.
-- Was ausdruecklich NICHT dazugehoert:
--   * Tabellen mit Geheimnissen (Zahlungsschluessel, SMTP, Social-Tokens,
--     Revisionszugaenge, Floky-Einstellungen) -- eine Vorlage darf keine
--     Kopie von Geheimnissen sein;
--   * Plattformtabellen und Treffen, an denen andere Vereine haengen;
--   * die Domains des Demovereins, damit er erreichbar bleibt;
--   * hochgeladene Dateien im Speicher.
--
-- Das Passwort steht nicht in dieser Datei, auch nicht als Hash: es wird
-- einmalig direkt in demo_stand gesetzt und landet so nicht im Git.
--
-- Nur der Plattformbetreiber darf beides aufrufen, und es betrifft fest den
-- Verein 'demo' -- ein Parameter fuer den Verein waere ein Knopf, mit dem
-- man einen echten Verein leeren koennte.

CREATE TABLE IF NOT EXISTS public.demo_vorlage (
  tabelle text  NOT NULL,
  zeile   jsonb NOT NULL
);
CREATE INDEX IF NOT EXISTS demo_vorlage_tabelle ON public.demo_vorlage (tabelle);

CREATE TABLE IF NOT EXISTS public.demo_stand (
  id                 int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  passwort_hash      text,
  vorlage_am         timestamptz,
  vorlage_von        text,
  vorlage_zeilen     int,
  zurueckgesetzt_am  timestamptz,
  zurueckgesetzt_von text
);
INSERT INTO public.demo_stand (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.demo_vorlage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demo_stand   ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demo_vorlage, public.demo_stand FROM anon, authenticated;

-- Die betroffenen Tabellen, Eltern vor Kindern. Die Reihenfolge wird aus den
-- Fremdschluesseln berechnet und nicht festgeschrieben: eine spaeter
-- hinzukommende Tabelle mit "tenantId" ist so automatisch dabei.
CREATE OR REPLACE FUNCTION public._demo_tabellen()
RETURNS text[]
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
  v_rest   text[];
  v_fertig text[] := '{}';
  v_t      text;
  v_weiter boolean;
BEGIN
  SELECT array_agg(c.table_name::text ORDER BY c.table_name) INTO v_rest
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name AND t.table_type = 'BASE TABLE'
   WHERE c.table_schema = 'public' AND c.column_name = 'tenantId'
     AND c.table_name NOT IN (
       'zahlungsgeheimnisse', 'mail_settings', 'social_connections', 'social_oauth_state',
       'revisionszugaenge', 'floky_einstellungen',
       'platform_invoices', 'platform_support', 'platform_leads',
       'treffen_teilnehmer', 'tenant_domains');

  LOOP
    EXIT WHEN coalesce(cardinality(v_rest), 0) = 0;
    v_weiter := false;
    FOREACH v_t IN ARRAY v_rest LOOP
      IF NOT EXISTS (
        SELECT 1 FROM pg_constraint k
         WHERE k.contype = 'f'
           AND k.conrelid = format('public.%I', v_t)::regclass
           AND k.confrelid <> k.conrelid
           AND (SELECT relname::text FROM pg_class WHERE oid = k.confrelid) = ANY (v_rest)
      ) THEN
        v_fertig := v_fertig || v_t;
        v_rest   := array_remove(v_rest, v_t);
        v_weiter := true;
      END IF;
    END LOOP;
    IF NOT v_weiter THEN
      RAISE EXCEPTION 'Fremdschluessel bilden einen Kreis: %', v_rest;
    END IF;
  END LOOP;
  RETURN v_fertig;
END $$;
REVOKE ALL ON FUNCTION public._demo_tabellen() FROM PUBLIC, anon, authenticated;

-- Den jetzigen Stand des Demovereins als Vorlage festhalten.
CREATE OR REPLACE FUNCTION public.demo_vorlage_speichern()
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
  v_t text;
  v_n int;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf die Demo-Vorlage speichern.'
      USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.demo_vorlage;
  FOREACH v_t IN ARRAY public._demo_tabellen() LOOP
    EXECUTE format(
      'INSERT INTO public.demo_vorlage (tabelle, zeile) SELECT %L, to_jsonb(x) FROM public.%I x WHERE x."tenantId" = %L',
      v_t, v_t, 'demo');
  END LOOP;

  SELECT count(*) INTO v_n FROM public.demo_vorlage;
  UPDATE public.demo_stand
     SET vorlage_am = now(), vorlage_von = auth.jwt() ->> 'email', vorlage_zeilen = v_n
   WHERE id = 1;
  RETURN v_n;
END $$;

-- Den Demoverein auf die Vorlage zuruecksetzen.
--
-- Die eigenen Trigger der Tabellen werden dafuer ausgeschaltet. Sonst
-- schriebe das Wiedereinfuegen einer Rechnung eine zweite Buchung, die
-- Jahressperre verweigerte das Loeschen alter Buchungen, und Belegnummern
-- wuerden neu vergeben. Die Fremdschluessel bleiben dabei in Kraft. Weil
-- ALTER TABLE in der Transaktion liegt, sieht keine andere Sitzung die
-- Trigger je ausgeschaltet; sie wartet hoechstens einen Augenblick.
CREATE OR REPLACE FUNCTION public.demo_zuruecksetzen()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE
  v_tab   text[];
  v_t     text;
  v_i     int;
  v_sp    text;
  v_hash  text;
  v_zeilen int;
  v_konten int := 0;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber darf den Demoverein zuruecksetzen.'
      USING ERRCODE = '42501';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.demo_vorlage) THEN
    RAISE EXCEPTION 'Es gibt noch keine Demo-Vorlage.';
  END IF;

  SET LOCAL lock_timeout = '5s';
  v_tab := public._demo_tabellen();

  FOREACH v_t IN ARRAY v_tab LOOP
    EXECUTE format('ALTER TABLE public.%I DISABLE TRIGGER USER', v_t);
  END LOOP;

  FOR v_i IN REVERSE cardinality(v_tab) .. 1 LOOP
    EXECUTE format('DELETE FROM public.%I WHERE "tenantId" = %L', v_tab[v_i], 'demo');
  END LOOP;

  FOREACH v_t IN ARRAY v_tab LOOP
    SELECT string_agg(quote_ident(column_name::text), ', ' ORDER BY ordinal_position) INTO v_sp
      FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = v_t AND is_generated = 'NEVER';
    EXECUTE format(
      'INSERT INTO public.%1$I (%2$s) SELECT %3$s FROM public.demo_vorlage v, jsonb_populate_record(NULL::public.%1$I, v.zeile) r WHERE v.tabelle = %4$L',
      v_t, v_sp, 'r.' || replace(v_sp, ', ', ', r.'), v_t);
  END LOOP;

  FOREACH v_t IN ARRAY v_tab LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER USER', v_t);
  END LOOP;

  -- Zugaenge: alle auf das gemeinsame Passwort, offene Sitzungen beenden.
  -- Ein Betreiberkonto ist nie dabei, auch wenn es im Demoverein eine Zeile
  -- haette.
  SELECT passwort_hash INTO v_hash FROM public.demo_stand WHERE id = 1;
  IF v_hash IS NOT NULL THEN
    WITH konten AS (
      SELECT a.id FROM auth.users a
        JOIN public.users u ON u."authUserId" = a.id::text AND u."tenantId" = 'demo'
       WHERE NOT EXISTS (SELECT 1 FROM public.platform_admins p WHERE lower(p.email) = lower(a.email))
    ), gesetzt AS (
      UPDATE auth.users a SET encrypted_password = v_hash, updated_at = now()
        FROM konten k WHERE a.id = k.id RETURNING a.id
    )
    SELECT count(*) INTO v_konten FROM gesetzt;

    DELETE FROM auth.refresh_tokens r USING public.users u
     WHERE u."tenantId" = 'demo' AND u."authUserId" = r.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId");
    DELETE FROM auth.sessions s USING public.users u
     WHERE u."tenantId" = 'demo' AND u."authUserId" = s.user_id::text
       AND NOT EXISTS (SELECT 1 FROM auth.users a JOIN public.platform_admins p ON lower(p.email) = lower(a.email) WHERE a.id::text = u."authUserId");
  END IF;

  SELECT count(*) INTO v_zeilen FROM public.demo_vorlage;
  UPDATE public.demo_stand
     SET zurueckgesetzt_am = now(), zurueckgesetzt_von = auth.jwt() ->> 'email'
   WHERE id = 1;

  RETURN jsonb_build_object('zeilen', v_zeilen, 'konten', v_konten, 'passwort', v_hash IS NOT NULL);
END $$;

-- Fuer die Anzeige im Betreiberbereich: wann zuletzt gespeichert und
-- zurueckgesetzt wurde. Den Hash gibt sie nicht heraus.
CREATE OR REPLACE FUNCTION public.demo_stand_lesen()
RETURNS TABLE (vorlage_am timestamptz, vorlage_von text, vorlage_zeilen int,
               zurueckgesetzt_am timestamptz, zurueckgesetzt_von text, passwort_gesetzt boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur fuer den Plattformbetreiber.' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY SELECT s.vorlage_am, s.vorlage_von, s.vorlage_zeilen, s.zurueckgesetzt_am,
                      s.zurueckgesetzt_von, s.passwort_hash IS NOT NULL
                 FROM public.demo_stand s WHERE s.id = 1;
END $$;

REVOKE ALL ON FUNCTION public.demo_vorlage_speichern(), public.demo_zuruecksetzen(), public.demo_stand_lesen() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.demo_vorlage_speichern(), public.demo_zuruecksetzen(), public.demo_stand_lesen() TO authenticated;
