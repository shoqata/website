-- Besucherzahlen selbst zaehlen.
--
-- Gemessen, bevor ich einen Dienst dazwischengeschaltet habe: eine
-- Datenbankfunktion sieht die Kopfzeilen der Anfrage, und zwar alle, die
-- hier gebraucht werden --
--
--   x-forwarded-for   212.35.16.80      (fuer den Zaehlwert, nie gespeichert)
--   user-agent        …iPhone…          (Geraeteart)
--   referer           google.com        (Herkunft)
--   accept-language   de-CH             (Sprache)
--   cf-ipcountry      CH                (Land, ohne eigene Zuordnung)
--
-- Damit braucht es keine Edge Function und keinen fremden Dienst. Die
-- Zahlen bleiben dort, wo die Vereinsdaten schon liegen.
--
-- Was NICHT gespeichert wird: die IP-Adresse. Statt ihrer ein Wert, der
-- sich taeglich aendert --
--
--   besucher = sha256(salz_des_tages || ip || user-agent)
--
-- Damit laesst sich zaehlen, wie viele verschiedene Menschen an einem Tag
-- da waren, und am naechsten Tag ist die Verbindung zur Person weg. Kein
-- Cookie, keine Zustimmung, keine Wiedererkennung ueber Tage. Das ist
-- nicht nur rechtlich bequemer -- es ist die einzige Fassung, bei der ich
-- dem Verein ehrlich sagen kann, dass er niemanden verfolgt.

-- ------------------------------------------------- Das Salz des Tages
CREATE TABLE IF NOT EXISTS public.zaehler_salz (
  tag  date PRIMARY KEY,
  salz text NOT NULL
);
ALTER TABLE public.zaehler_salz ENABLE ROW LEVEL SECURITY;
-- Keine Leseregel: niemand soll das Salz sehen. Waere es lesbar, liesse
-- sich der Besucherwert zu einer IP zurueckrechnen -- der ganze Aufwand
-- waere dahin.
REVOKE ALL ON TABLE public.zaehler_salz FROM anon, authenticated;

COMMENT ON TABLE public.zaehler_salz IS
  'Taeglich wechselndes Salz fuer den Besucherwert. Nicht lesbar, auch '
  'nicht fuer die Administration -- sonst waere der Wert umkehrbar.';


-- ------------------------------------------------------- Die Aufrufe
CREATE TABLE IF NOT EXISTS public.seitenaufrufe (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Null fuer die Betreiberseite (unityhub.li); sonst der Verein.
  "tenantId"  text,
  pfad        text NOT NULL,
  titel       text,
  besucher    text NOT NULL,
  herkunft    text,
  herkunft_art text NOT NULL DEFAULT 'DIREKT',
  geraet      text NOT NULL DEFAULT 'UNBEKANNT',
  sprache     text,
  land        text,
  -- Die Stunde nach Zuercher Zeit, damit "wann kommen die Leute" ohne
  -- Zeitzonenrechnung in jeder Abfrage beantwortbar ist.
  stunde      smallint NOT NULL,
  dauer_s     integer,
  ziel        text,
  gesehen_am  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS seitenaufrufe_zeit
  ON public.seitenaufrufe ("tenantId", gesehen_am DESC);
CREATE INDEX IF NOT EXISTS seitenaufrufe_besucher
  ON public.seitenaufrufe (besucher, gesehen_am DESC);
CREATE INDEX IF NOT EXISTS seitenaufrufe_pfad
  ON public.seitenaufrufe ("tenantId", pfad, gesehen_am DESC);

ALTER TABLE public.seitenaufrufe ENABLE ROW LEVEL SECURITY;

-- Rohdaten liest niemand ueber die Tabelle -- auch die Administration
-- nicht. Ausgewertet wird ueber die Funktionen weiter unten. Der
-- Besucherwert ist zwar nicht umkehrbar, aber eine Liste aller Aufrufe
-- je Wert ergibt ein Bewegungsmuster, und das braucht hier niemand.
REVOKE ALL ON TABLE public.seitenaufrufe FROM anon, authenticated;

COMMENT ON TABLE public.seitenaufrufe IS
  'Seitenaufrufe ohne IP-Adresse. besucher ist ein taeglich wechselnder '
  'Hashwert. Nicht direkt lesbar -- Auswertung ueber seo_* Funktionen.';


-- --------------------------------------------------------- Zaehlen
CREATE OR REPLACE FUNCTION public.seitenaufruf_zaehlen(
  p_pfad    text,
  p_titel   text DEFAULT NULL,
  p_verweis text DEFAULT NULL,
  p_ziel    text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  k jsonb := coalesce(current_setting('request.headers', true)::jsonb, '{}'::jsonb);
  v_tag date := (now() AT TIME ZONE 'Europe/Zurich')::date;
  v_salz text;
  v_ip text := split_part(coalesce(k->>'x-forwarded-for', ''), ',', 1);
  v_ua text := coalesce(k->>'user-agent', '');
  v_verein text := public.request_tenant();
  v_besucher text;
  v_geraet text;
  v_quelle text;
  v_art text;
  v_eigen text;
  v_id uuid;
  v_letzter uuid;
BEGIN
  IF p_pfad IS NULL OR btrim(p_pfad) = '' THEN
    RETURN NULL;   -- nichts zu zaehlen, und kein Grund zu scheitern
  END IF;

  -- Salz des Tages, bei Bedarf angelegt. Das ON CONFLICT ist nicht
  -- Zierde: am Tageswechsel treffen mehrere Aufrufe gleichzeitig ein.
  INSERT INTO public.zaehler_salz (tag, salz)
  -- Mit Schema: pgcrypto liegt in "extensions", und diese Funktion
  -- pinnt search_path = public. Das Pinnen ist richtig -- es verhindert,
  -- dass jemand ueber einen eigenen Suchpfad eine falsche Funktion
  -- unterschiebt --, also werden die beiden Aufrufe qualifiziert statt
  -- den Pfad aufzuweichen.
  VALUES (v_tag, encode(extensions.gen_random_bytes(32), 'hex'))
  ON CONFLICT (tag) DO NOTHING;
  SELECT salz INTO v_salz FROM public.zaehler_salz WHERE tag = v_tag;

  v_besucher := encode(extensions.digest(v_salz || v_ip || v_ua, 'sha256'), 'hex');

  -- Geraeteart aus dem User-Agent. Grob und absichtlich: fuer die Frage
  -- "muss die Seite auf dem Telefon taugen" genuegen drei Klassen, und
  -- eine feinere Erkennung waere eine Bibliothek, die veraltet.
  v_geraet := CASE
    WHEN v_ua ~* 'iPad|Tablet|PlayBook|Silk' THEN 'TABLET'
    WHEN v_ua ~* 'Mobi|iPhone|Android.*Mobile|Windows Phone' THEN 'HANDY'
    WHEN v_ua = '' THEN 'UNBEKANNT'
    ELSE 'RECHNER' END;

  -- Herkunft: der Verweis vom Browser hat Vorrang, weil er bei einem
  -- Wechsel innerhalb der Seite richtiger ist als die Kopfzeile.
  v_quelle := coalesce(nullif(btrim(p_verweis), ''), k->>'referer', '');
  v_quelle := lower(regexp_replace(v_quelle, '^https?://(www\.)?([^/:]+).*$', '\2'));
  v_eigen := lower(regexp_replace(coalesce(k->>'origin',''), '^https?://(www\.)?([^/:]+).*$', '\2'));

  v_art := CASE
    WHEN v_quelle = '' THEN 'DIREKT'
    -- Ein Wechsel innerhalb der eigenen Seite ist keine Herkunft.
    WHEN v_eigen <> '' AND v_quelle = v_eigen THEN 'INTERN'
    WHEN v_quelle ~ '(google|bing|duckduckgo|ecosia|yahoo|yandex|startpage|qwant)\.' THEN 'SUCHE'
    WHEN v_quelle ~ '(facebook|instagram|tiktok|twitter|^x\.com|linkedin|youtube|whatsapp|t\.co|telegram)' THEN 'SOZIAL'
    ELSE 'VERWEIS' END;

  -- Doppelt zaehlen vermeiden. Eine Einzelseiten-Anwendung ruft bei
  -- jedem Rendern auf; ohne diese Sperre stiegen die Zahlen mit der
  -- Anzahl der Neuzeichnungen und nicht mit der der Besucher.
  SELECT a.id INTO v_letzter FROM public.seitenaufrufe a
   WHERE a.besucher = v_besucher AND a.pfad = p_pfad
     AND a.gesehen_am > now() - interval '15 seconds'
   ORDER BY a.gesehen_am DESC LIMIT 1;
  IF v_letzter IS NOT NULL THEN
    RETURN v_letzter;
  END IF;

  INSERT INTO public.seitenaufrufe
    ("tenantId", pfad, titel, besucher, herkunft, herkunft_art, geraet,
     sprache, land, stunde, ziel)
  VALUES (v_verein, left(btrim(p_pfad), 300), left(coalesce(p_titel,''), 200),
          v_besucher, nullif(v_quelle,''), v_art, v_geraet,
          left(split_part(coalesce(k->>'accept-language',''), ',', 1), 10),
          upper(left(coalesce(k->>'cf-ipcountry',''), 2)),
          extract(hour from (now() AT TIME ZONE 'Europe/Zurich'))::smallint,
          nullif(btrim(coalesce(p_ziel,'')), ''))
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

-- Besucher sind nicht angemeldet -- anon muss zaehlen duerfen. Die
-- Funktion nimmt nur einen Pfad und einen Verweis an; alles, woraus sich
-- etwas ueber die Person ergeben koennte, kommt aus den Kopfzeilen und
-- nicht vom Aufrufer.
REVOKE ALL ON FUNCTION public.seitenaufruf_zaehlen(text,text,text,text) FROM public;
GRANT EXECUTE ON FUNCTION public.seitenaufruf_zaehlen(text,text,text,text)
  TO anon, authenticated;


-- Die Verweildauer kommt nach, wenn die Seite verlassen wird.
CREATE OR REPLACE FUNCTION public.seitenaufruf_dauer(p_id uuid, p_sekunden integer)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_id IS NULL OR p_sekunden IS NULL OR p_sekunden < 0 THEN RETURN; END IF;
  UPDATE public.seitenaufrufe
     -- Nach oben begrenzt: ein offener Reiter ueber Nacht ergaebe sonst
     -- eine Durchschnittsdauer von Stunden und machte die Zahl wertlos.
     -- Zwei Stunden ist grosszuegig und noch glaubhaft.
     SET dauer_s = least(p_sekunden, 7200)
   WHERE id = p_id
     -- Nur solange der Aufruf frisch ist. Sonst koennte jemand alte
     -- Zeilen nachtraeglich verbiegen.
     AND gesehen_am > now() - interval '12 hours';
END $$;

REVOKE ALL ON FUNCTION public.seitenaufruf_dauer(uuid,integer) FROM public;
GRANT EXECUTE ON FUNCTION public.seitenaufruf_dauer(uuid,integer) TO anon, authenticated;


-- ====================================================== Auswertung
--
-- Je Auswertung eine Funktion, und jede beantwortet eine Frage. Der
-- Zugriff haengt an der Rolle: die Vereinsadministration sieht ihren
-- Verein, der Betreiber sieht alle -- dieselbe Funktion, verschiedener
-- Umfang. Zwei Funktionen dafuer zu schreiben hiesse, dieselbe Rechnung
-- zweimal zu pflegen.
--
-- p_verein ist nur fuer den Betreiber: er kann damit auf einen Verein
-- einschraenken. Fuer die Vereinsadministration wird der Wert
-- ueberschrieben -- sonst saehe sie mit einem fremden Namen fremde
-- Zahlen.
CREATE OR REPLACE FUNCTION public.seo_bereich(p_verein text)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    -- Der Betreiber: was er verlangt, oder alles.
    WHEN public.is_platform_admin() THEN p_verein
    -- Der Verein: immer der eigene, unabhaengig von der Anfrage.
    WHEN public.app_role() IN ('SUPER_ADMIN','ADMIN','BOARD') THEN public.current_tenant()
    ELSE '\x00'   -- niemand sonst; ein Wert, der auf nichts passt
  END;
$$;


CREATE OR REPLACE FUNCTION public.seo_kennzahlen(
  p_von date DEFAULT NULL, p_bis date DEFAULT NULL, p_verein text DEFAULT NULL
) RETURNS TABLE (
  r_pfad text, r_aufrufe bigint, r_besucher bigint,
  r_dauer_s numeric, r_absprung numeric
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein),
  a AS (
    SELECT s.* FROM public.seitenaufrufe s, b
     WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
       AND b.verein IS DISTINCT FROM '\x00'
       AND s.gesehen_am >= coalesce(p_von, current_date - 29)
       AND s.gesehen_am < coalesce(p_bis, current_date) + 1
       AND s.herkunft_art <> 'INTERN'
  ),
  -- Ein Besuch gilt als Absprung, wenn dieser Besucher in derselben
  -- halben Stunde nur EINE Seite gesehen hat. Ohne Zeitfenster waere
  -- jeder Wiederkehrer am selben Tag kein Absprung mehr, und die Zahl
  -- saehe besser aus, als sie ist.
  sitzungen AS (
    SELECT besucher,
           div(extract(epoch from gesehen_am)::bigint, 1800) AS fenster,
           count(*) AS seiten,
           min(pfad) AS erste
      FROM a GROUP BY 1, 2
  )
  SELECT a.pfad,
         count(*)::bigint,
         count(DISTINCT a.besucher)::bigint,
         round(avg(a.dauer_s)::numeric, 1),
         round(100.0 * coalesce(
           (SELECT count(*) FROM sitzungen s
             WHERE s.erste = a.pfad AND s.seiten = 1), 0)
           / greatest((SELECT count(*) FROM sitzungen s WHERE s.erste = a.pfad), 1), 1)
    FROM a GROUP BY a.pfad ORDER BY 2 DESC;
$$;


CREATE OR REPLACE FUNCTION public.seo_herkunft(
  p_von date DEFAULT NULL, p_bis date DEFAULT NULL, p_verein text DEFAULT NULL
) RETURNS TABLE (r_art text, r_quelle text, r_aufrufe bigint, r_besucher bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein)
  SELECT s.herkunft_art, coalesce(s.herkunft, '—'),
         count(*)::bigint, count(DISTINCT s.besucher)::bigint
    FROM public.seitenaufrufe s, b
   WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
     AND b.verein IS DISTINCT FROM '\x00'
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
     AND s.herkunft_art <> 'INTERN'
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;


CREATE OR REPLACE FUNCTION public.seo_verteilung(
  p_von date DEFAULT NULL, p_bis date DEFAULT NULL, p_verein text DEFAULT NULL
) RETURNS TABLE (r_art text, r_wert text, r_aufrufe bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  -- Geraet, Stunde, Sprache, Land und Tag in einer Abfrage. Fuenf
  -- Funktionen fuer fuenf Gruppierungen waeren fuenfmal dieselbe
  -- Zugriffspruefung und fuenf Gelegenheiten, sie verschieden zu
  -- schreiben.
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein),
  a AS (
    SELECT s.* FROM public.seitenaufrufe s, b
     WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
       AND b.verein IS DISTINCT FROM '\x00'
       AND s.gesehen_am >= coalesce(p_von, current_date - 29)
       AND s.gesehen_am < coalesce(p_bis, current_date) + 1
       AND s.herkunft_art <> 'INTERN'
  )
  SELECT 'GERAET', geraet, count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'STUNDE', lpad(stunde::text, 2, '0'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'SPRACHE', coalesce(nullif(sprache,''), '—'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'LAND', coalesce(nullif(land,''), '—'), count(*)::bigint FROM a GROUP BY 2
  UNION ALL
  SELECT 'TAG', (gesehen_am AT TIME ZONE 'Europe/Zurich')::date::text,
         count(*)::bigint FROM a GROUP BY 2
  ORDER BY 1, 2;
$$;


CREATE OR REPLACE FUNCTION public.seo_ziele(
  p_von date DEFAULT NULL, p_bis date DEFAULT NULL, p_verein text DEFAULT NULL
) RETURNS TABLE (r_ziel text, r_pfad text, r_anzahl bigint, r_besucher bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH b AS (SELECT public.seo_bereich(p_verein) AS verein)
  SELECT s.ziel, s.pfad, count(*)::bigint, count(DISTINCT s.besucher)::bigint
    FROM public.seitenaufrufe s, b
   WHERE (b.verein IS NULL OR s."tenantId" = b.verein)
     AND b.verein IS DISTINCT FROM '\x00'
     AND s.ziel IS NOT NULL
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;


-- Fuer den Betreiber: je Verein eine Zeile. Beantwortet die Frage, die
-- er wirklich hat -- welche Vereinsseite laeuft, welche nicht.
CREATE OR REPLACE FUNCTION public.seo_je_verein(
  p_von date DEFAULT NULL, p_bis date DEFAULT NULL
) RETURNS TABLE (
  r_verein text, r_name text, r_aufrufe bigint, r_besucher bigint,
  r_dauer_s numeric, r_seiten bigint
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(s."tenantId", '—'),
         coalesce(t.name, CASE WHEN s."tenantId" IS NULL
                               THEN 'Betreiberseite' ELSE s."tenantId" END),
         count(*)::bigint, count(DISTINCT s.besucher)::bigint,
         round(avg(s.dauer_s)::numeric, 1), count(DISTINCT s.pfad)::bigint
    FROM public.seitenaufrufe s
    LEFT JOIN public.tenants t ON t.id = s."tenantId"
   WHERE public.is_platform_admin()
     AND s.gesehen_am >= coalesce(p_von, current_date - 29)
     AND s.gesehen_am < coalesce(p_bis, current_date) + 1
     AND s.herkunft_art <> 'INTERN'
   GROUP BY 1, 2 ORDER BY 3 DESC;
$$;

DO $$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'seo_bereich(text)',
    'seo_kennzahlen(date,date,text)',
    'seo_herkunft(date,date,text)',
    'seo_verteilung(date,date,text)',
    'seo_ziele(date,date,text)',
    'seo_je_verein(date,date)'] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION public.%s FROM public, anon', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%s TO authenticated', f);
  END LOOP;
END $$;

DROP FUNCTION IF EXISTS public._probe_header();
