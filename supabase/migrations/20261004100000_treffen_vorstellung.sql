-- Aus einer Namensliste wird ein Teilnehmerverzeichnis.
--
-- Bisher stand in treffen_delegation ein Name, eine Rolle und eine
-- Bemerkung. Das genuegt fuer eine Kopfzahl. Es genuegt nicht fuer
-- Namensschilder, nicht fuer Essenszahlen und schon gar nicht fuer ein
-- Heft, das am Ende des Treffens alle bekommen.
--
-- Zwei Dinge bestimmen den Entwurf:
--
-- 1. Jede Person stellt sich SELBST vor. Der Delegationsleiter tippt
--    nicht ab, was er ueber seine Leute zu wissen glaubt -- er traegt
--    Namen und E-Mail ein, und jede Person bekommt ihren eigenen Link.
--
-- 2. Wer seine Vorstellung in ein Heft gibt, das alle Teilnehmer
--    bekommen, muss das selbst entscheiden duerfen. "im_heft" ist darum
--    NICHT vorbelegt: ohne ausdrueckliches Ja erscheint niemand. Ein
--    Kaestchen, das schon angekreuzt ist, ist keine Entscheidung.
--
-- Das Essen ist strukturiert UND frei: die Kueche will zaehlen koennen,
-- und "Erdnussallergie" passt in keine Liste.

ALTER TABLE public.treffen_delegation
  ADD COLUMN IF NOT EXISTS email         text,
  ADD COLUMN IF NOT EXISTS funktion      text,          -- Rolle im eigenen Verein
  ADD COLUMN IF NOT EXISTS vorstellung   text,          -- wer bin ich, was mache ich
  ADD COLUMN IF NOT EXISTS interessen    text,          -- woran bin ich interessiert
  ADD COLUMN IF NOT EXISTS essen         text DEFAULT 'KEINE_ANGABE'
    CHECK (essen IN ('KEINE_ANGABE','ALLES','VEGETARISCH','VEGAN','HALAL','GLUTENFREI','LAKTOSEFREI')),
  ADD COLUMN IF NOT EXISTS essen_hinweis text,          -- Allergien, was keine Liste abdeckt
  ADD COLUMN IF NOT EXISTS im_heft       boolean,       -- NULL = noch nicht gefragt
  ADD COLUMN IF NOT EXISTS token_hash    text,
  ADD COLUMN IF NOT EXISTS gueltig_bis   date,
  ADD COLUMN IF NOT EXISTS vorgestellt_am timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS treffen_delegation_token
  ON public.treffen_delegation (token_hash) WHERE token_hash IS NOT NULL;


-- Links fuer alle, die noch keinen haben.
--
-- Ausgestellt wird je Person, nicht je Delegation: die Vorstellung ist
-- persoenlich, und der Delegationsleiter soll sie nicht fuer andere
-- ausfuellen koennen.
--
-- Gueltig bis zum Treffen selbst, nicht nur bis zum Anmeldeschluss --
-- jemand soll sich noch am Vorabend vorstellen koennen.
CREATE OR REPLACE FUNCTION public.treffen_vorstellung_links(p_teilnehmer uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_bis date;
  v_treffen uuid;
  v_darf boolean;
  r RECORD;
  v_token text;
  v_liste jsonb := '[]'::jsonb;
BEGIN
  SELECT te.treffen_id, coalesce(t.ende, t.datum)
    INTO v_treffen, v_bis
    FROM public.treffen_teilnehmer te JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Teilnehmer nicht gefunden.'; END IF;

  -- Ausstellen darf der Gastgeber -- oder der Verein fuer seine EIGENE
  -- Delegation. Niemand sonst.
  SELECT public.is_platform_admin()
      OR EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = p_teilnehmer AND te.art = 'VEREIN'
                    AND te."tenantId" = public.current_tenant() AND public.is_staff())
    INTO v_darf;
  IF NOT coalesce(v_darf,false) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE='insufficient_privilege';
  END IF;

  FOR r IN SELECT id, name, email FROM public.treffen_delegation
            WHERE teilnehmer_id = p_teilnehmer AND token_hash IS NULL
            ORDER BY name
  LOOP
    v_token := replace(replace(replace(
                 encode(gen_random_bytes(24), 'base64'), '+','-'), '/','_'), '=','');
    UPDATE public.treffen_delegation
       SET token_hash = encode(digest(v_token, 'sha256'), 'hex'), gueltig_bis = v_bis
     WHERE id = r.id;
    v_liste := v_liste || jsonb_build_object(
      'id', r.id, 'name', r.name, 'email', r.email, 'token', v_token);
  END LOOP;

  RETURN jsonb_build_object('gueltig_bis', v_bis, 'neue', v_liste,
    'ohne_link', (SELECT count(*) FROM public.treffen_delegation
                   WHERE teilnehmer_id = p_teilnehmer AND token_hash IS NULL));
END $$;
REVOKE ALL ON FUNCTION public.treffen_vorstellung_links(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_vorstellung_links(uuid) TO authenticated;


-- Was eine Person sieht, wenn sie ihren Link oeffnet.
CREATE OR REPLACE FUNCTION public.vorstellung_lesen(p_token text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE d RECORD;
BEGIN
  SELECT dg.*, te.art, coalesce(te.name, tn.name, te."tenantId") AS verein,
         t.id AS treffen_id, t.titel, t.datum, t.ende, t.ort, t.beschreibung
    INTO d
    FROM public.treffen_delegation dg
    JOIN public.treffen_teilnehmer te ON te.id = dg.teilnehmer_id
    JOIN public.treffen t ON t.id = te.treffen_id
    LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
   WHERE dg.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  -- Dieselbe Meldung fuer "gibt es nicht" und "abgelaufen".
  IF d.id IS NULL OR d.gueltig_bis IS NULL OR d.gueltig_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  RETURN jsonb_build_object(
    'name', d.name, 'verein', d.verein, 'rolle', d.rolle,
    'email', d.email, 'funktion', d.funktion,
    'vorstellung', d.vorstellung, 'interessen', d.interessen,
    'essen', d.essen, 'essen_hinweis', d.essen_hinweis,
    'im_heft', d.im_heft, 'vorgestellt_am', d.vorgestellt_am,
    'treffen', jsonb_build_object('titel', d.titel, 'datum', d.datum,
                                  'ende', d.ende, 'ort', d.ort,
                                  'beschreibung', d.beschreibung));
END $$;
REVOKE ALL ON FUNCTION public.vorstellung_lesen(text) FROM public;
GRANT EXECUTE ON FUNCTION public.vorstellung_lesen(text) TO anon, authenticated;


CREATE OR REPLACE FUNCTION public.vorstellung_speichern(
  p_token text, p_name text, p_funktion text, p_vorstellung text,
  p_interessen text, p_essen text, p_essen_hinweis text, p_im_heft boolean)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_id uuid; v_bis date; v_zeilen int;
BEGIN
  SELECT id, gueltig_bis INTO v_id, v_bis FROM public.treffen_delegation
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_id IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  UPDATE public.treffen_delegation
     SET name        = coalesce(nullif(btrim(coalesce(p_name,'')),''), name),
         funktion    = nullif(btrim(coalesce(p_funktion,'')),''),
         vorstellung = nullif(btrim(coalesce(p_vorstellung,'')),''),
         interessen  = nullif(btrim(coalesce(p_interessen,'')),''),
         essen       = coalesce(nullif(p_essen,''), 'KEINE_ANGABE'),
         essen_hinweis = nullif(btrim(coalesce(p_essen_hinweis,'')),''),
         im_heft     = p_im_heft,
         vorgestellt_am = now()
   WHERE id = v_id;
  GET DIAGNOSTICS v_zeilen = ROW_COUNT;
  IF v_zeilen <> 1 THEN RAISE EXCEPTION 'Nicht gespeichert.'; END IF;

  RETURN jsonb_build_object('gespeichert', true);
END $$;
REVOKE ALL ON FUNCTION public.vorstellung_speichern(text,text,text,text,text,text,text,boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.vorstellung_speichern(text,text,text,text,text,text,text,boolean) TO anon, authenticated;


-- ------------------------------------------------------ Essenszahlen
-- Was die Kueche braucht: Zahlen zum Zaehlen und Hinweise zum Lesen.
--
-- Die Hinweise stehen getrennt, mit Namen. "12 vegetarisch" kann man
-- einkaufen; "Erdnussallergie" muss jemand lesen -- und wissen, zu wem
-- sie gehoert.
CREATE OR REPLACE FUNCTION public.treffen_essenszahlen(p_treffen uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (
    WITH leute AS (
      SELECT d.* FROM public.treffen_delegation d
        JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
       WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false)
    )
    SELECT jsonb_build_object(
      'gesamt', (SELECT count(*) FROM leute),
      'nach_art', (SELECT coalesce(jsonb_object_agg(essen, n), '{}'::jsonb)
                     FROM (SELECT essen, count(*) AS n FROM leute GROUP BY essen) x),
      'hinweise', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'name', name, 'essen', essen, 'hinweis', essen_hinweis)
                      ORDER BY name), '[]'::jsonb)
                     FROM leute WHERE coalesce(btrim(essen_hinweis),'') <> ''),
      'ohne_angabe', (SELECT count(*) FROM leute WHERE essen = 'KEINE_ANGABE')
    ));
END $$;
REVOKE ALL ON FUNCTION public.treffen_essenszahlen(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_essenszahlen(uuid) TO authenticated;


-- ---------------------------------------------------- Namensschilder
-- Alle, die kommen -- unabhaengig davon, ob sie ins Heft wollen. Ein
-- Namensschild traegt den Namen, der ohnehin am Empfang genannt wird;
-- es ist keine Veroeffentlichung.
CREATE OR REPLACE FUNCTION public.treffen_namensschilder(p_treffen uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
            'name', d.name, 'funktion', d.funktion, 'rolle', d.rolle,
            'verein', coalesce(te.name, tn.name, te."tenantId"))
            ORDER BY coalesce(te.name, tn.name, te."tenantId"), d.rolle, d.name), '[]'::jsonb)
            FROM public.treffen_delegation d
            JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
            LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
           WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false));
END $$;
REVOKE ALL ON FUNCTION public.treffen_namensschilder(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_namensschilder(uuid) TO authenticated;


-- ------------------------------------------------------------- Heft
-- Wer alles dabei war -- aber NUR, wer das ausdruecklich wollte.
--
-- im_heft ist nicht vorbelegt. Wer nicht gefragt wurde oder nein gesagt
-- hat, steht nicht drin. Die Zahl der Stillen wird mitgegeben, damit das
-- Heft sagen kann "und 14 weitere" statt sie zu verschweigen.
CREATE OR REPLACE FUNCTION public.treffen_heft_inhalt(p_treffen uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'treffen', (SELECT jsonb_build_object('titel', t.titel, 'beschreibung', t.beschreibung,
                  'datum', t.datum, 'ende', t.ende, 'ort', t.ort, 'adresse', t.adresse)
                  FROM public.treffen t WHERE t.id = p_treffen),
    'vereine', (SELECT coalesce(jsonb_agg(v ORDER BY v->>'name'), '[]'::jsonb) FROM (
        SELECT jsonb_build_object(
          'name', coalesce(te.name, tn.name, te."tenantId"),
          'art', te.art,
          'leute', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                       'name', d.name, 'funktion', d.funktion, 'rolle', d.rolle,
                       'vorstellung', d.vorstellung, 'interessen', d.interessen)
                       ORDER BY d.rolle, d.name), '[]'::jsonb)
                      FROM public.treffen_delegation d
                     WHERE d.teilnehmer_id = te.id AND d.im_heft IS TRUE),
          'stille', (SELECT count(*) FROM public.treffen_delegation d
                      WHERE d.teilnehmer_id = te.id AND coalesce(d.im_heft,false) = false)
        ) AS v
        FROM public.treffen_teilnehmer te
        LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
       WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false)
    ) y),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'titel', p.titel,
                    'ort', p.ort, 'spur', p.spur)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = p_treffen AND p.freigegeben),
    'stimmen', (SELECT count(*) FROM public.treffen_delegation d
                  JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                 WHERE te.treffen_id = p_treffen AND d.im_heft IS TRUE),
    'gesamt', (SELECT count(*) FROM public.treffen_delegation d
                 JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false))
  );
$$;
REVOKE ALL ON FUNCTION public.treffen_heft_inhalt(uuid) FROM public, anon, authenticated;


-- Der Gastgeber sieht das Heft jederzeit -- er muss es ja machen.
CREATE OR REPLACE FUNCTION public.treffen_heft(p_treffen uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN public.treffen_heft_inhalt(p_treffen);
END $$;
REVOKE ALL ON FUNCTION public.treffen_heft(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_heft(uuid) TO authenticated;


-- Die Teilnehmer bekommen es ab dem Tag des Treffens -- mit demselben
-- Link, mit dem sie sich vorgestellt haben. Vorher waere es halb leer:
-- die meisten stellen sich erst kurz davor vor.
CREATE OR REPLACE FUNCTION public.heft_fuer_teilnehmer(p_token text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_treffen uuid; v_ab date; v_bis date;
BEGIN
  SELECT te.treffen_id, t.datum, d.gueltig_bis
    INTO v_treffen, v_ab, v_bis
    FROM public.treffen_delegation d
    JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
    JOIN public.treffen t ON t.id = te.treffen_id
   WHERE d.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  IF v_treffen IS NULL OR v_bis IS NULL THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF current_date < v_ab THEN
    RAISE EXCEPTION 'Das Heft gibt es ab dem %.', to_char(v_ab,'DD.MM.YYYY');
  END IF;
  RETURN public.treffen_heft_inhalt(v_treffen);
END $$;
REVOKE ALL ON FUNCTION public.heft_fuer_teilnehmer(text) FROM public;
GRANT EXECUTE ON FUNCTION public.heft_fuer_teilnehmer(text) TO anon, authenticated;
