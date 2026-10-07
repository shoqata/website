-- Treffen auch fuer Vereine: das Modul wandert in den Marktplatz.
--
-- Bisher stand in 20260930300000_vereinstreffen.sql ausdruecklich:
-- "Schreiben darf allein der Betreiber. Vereine sind Teilnehmer, nicht
-- Gastgeber." Das war eine Entscheidung, keine technische Schranke, und
-- sie wird hier umgedreht: ein Verein, der das Modul gebucht hat, richtet
-- eigene Treffen aus -- mit Programm, Ausfluegen, Selbstvorstellung,
-- Heft und Drucksachen.
--
-- Der Betreiber behaelt seine eigenen Treffen. Beide Faelle liegen in
-- denselben Tabellen, unterschieden durch EINE Spalte.
--
-- Entscheidend ist, dass nur EINE Funktion sagt, wer ein Treffen fuehren
-- darf. Vorher stand is_platform_admin() an einem Dutzend Stellen; haette
-- ich das Dutzend einzeln erweitert, waere frueher oder spaeter eine
-- Stelle anders gewesen als die anderen -- und ausgerechnet bei Rechten
-- faellt so etwas erst auf, wenn jemand sieht, was er nicht sehen soll.

-- ------------------------------------------------------- Wer richtet aus
-- NULL heisst: die Plattform selbst. Das ist ehrlicher als eine
-- Scheinkennung fuer den Betreiber, denn er IST kein Verein.
ALTER TABLE public.treffen
  ADD COLUMN IF NOT EXISTS gastgeber text REFERENCES public.tenants(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS treffen_gastgeber_idx ON public.treffen (gastgeber);

COMMENT ON COLUMN public.treffen.gastgeber IS
  'Der ausrichtende Verein. NULL = die Plattform richtet aus.';


-- ------------------------------------------------------- Die eine Frage
-- "Darf ich dieses Treffen fuehren?" -- an einer Stelle beantwortet.
--
-- Der Betreiber darf immer. Ein Verein nur sein eigenes, nur mit
-- Vorstand/Verwaltung, und nur solange das Modul laeuft. Faellt das Modul
-- weg, bleiben die Daten stehen und der Zugriff endet -- dieselbe Regel
-- wie ueberall im Marktplatz.
CREATE OR REPLACE FUNCTION public.treffen_gastgeber(p_treffen uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_platform_admin()
      OR EXISTS (SELECT 1 FROM public.treffen t
                  WHERE t.id = p_treffen
                    AND t.gastgeber IS NOT NULL
                    AND t.gastgeber = public.current_tenant()
                    AND public.is_staff()
                    AND public.modul_aktiv('TREFFEN'));
$$;
-- Auch anon braucht EXECUTE, so ungewohnt das aussieht: die Leseregel
-- treffen_programm_lesen gilt TO anon, und RLS wertet ihre Praedikate
-- mit den Rechten des FRAGENDEN Kontos aus. Ohne dieses Recht stirbt
-- die oeffentliche Programmanzeige an "permission denied for function".
-- Verraten wird nichts: die Funktion sagt nur, ob der Fragende selbst
-- Gastgeber ist, und fuer anon ist das immer false.
REVOKE ALL ON FUNCTION public.treffen_gastgeber(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_gastgeber(uuid) TO anon, authenticated;

-- Dieselbe Frage, bevor es das Treffen gibt: darf ich ueberhaupt eines
-- anlegen, und auf wessen Namen?
CREATE OR REPLACE FUNCTION public.treffen_darf_anlegen(p_gastgeber text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE
    -- Die Plattform richtet aus: nur der Betreiber.
    WHEN p_gastgeber IS NULL THEN public.is_platform_admin()
    -- Ein Verein richtet aus: der Betreiber darf es fuer ihn tun,
    -- sonst nur der Verein selbst und nur mit gebuchtem Modul.
    ELSE public.is_platform_admin()
      OR (p_gastgeber = public.current_tenant()
          AND public.is_staff()
          AND public.modul_aktiv('TREFFEN'))
  END;
$$;
REVOKE ALL ON FUNCTION public.treffen_darf_anlegen(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.treffen_darf_anlegen(text) TO authenticated;


-- ------------------------------------------------------------- Zeilenregeln
-- Fuenf Tabellen, eine Regel. treffen_gastgeber() faellt fuer den
-- Betreiber auf is_platform_admin() zurueck, die alten Faelle bleiben
-- also genau wie sie waren.

-- Auf der Tabelle treffen selbst steht die Bedingung ausgeschrieben und
-- NICHT als treffen_gastgeber(id). Die Funktion liest aus treffen -- eine
-- Regel auf treffen, die aus treffen liest, waere nur deshalb nicht
-- rekursiv, weil SECURITY DEFINER die Zeilenregeln umgeht. Das gilt aber
-- nur, solange FORCE ROW LEVEL SECURITY aus ist. Diese Regel haengt
-- nicht von einer Einstellung ab, die jemand spaeter umlegen kann --
-- zumal die Zeile selbst alles weiss, was gefragt ist.
DROP POLICY IF EXISTS treffen_betreiber ON public.treffen;
CREATE POLICY treffen_fuehren ON public.treffen FOR ALL TO authenticated
  USING (public.is_platform_admin()
         OR (gastgeber IS NOT NULL
             AND gastgeber = public.current_tenant()
             AND public.is_staff()
             AND public.modul_aktiv('TREFFEN')))
  -- Beim Schreiben zaehlt der Gastgeber der ZEILE, nicht der des
  -- bestehenden Treffens: sonst koennte ein Verein sein Treffen einem
  -- anderen zuschieben oder es zum Betreibertreffen machen.
  WITH CHECK (public.treffen_darf_anlegen(gastgeber));

DROP POLICY IF EXISTS treffen_teilnehmer_betreiber ON public.treffen_teilnehmer;
CREATE POLICY treffen_teilnehmer_fuehren ON public.treffen_teilnehmer FOR ALL TO authenticated
  USING (public.treffen_gastgeber(treffen_id))
  WITH CHECK (public.treffen_gastgeber(treffen_id));

DROP POLICY IF EXISTS treffen_programm_betreiber ON public.treffen_programm;
CREATE POLICY treffen_programm_fuehren ON public.treffen_programm FOR ALL TO authenticated
  USING (public.treffen_gastgeber(treffen_id))
  WITH CHECK (public.treffen_gastgeber(treffen_id));

DROP POLICY IF EXISTS treffen_delegation_betreiber ON public.treffen_delegation;
CREATE POLICY treffen_delegation_fuehren ON public.treffen_delegation FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = teilnehmer_id AND public.treffen_gastgeber(te.treffen_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.treffen_teilnehmer te
                  WHERE te.id = teilnehmer_id AND public.treffen_gastgeber(te.treffen_id)));

DROP POLICY IF EXISTS ausflug_betreiber ON public.treffen_ausflug_anmeldung;
CREATE POLICY ausflug_fuehren ON public.treffen_ausflug_anmeldung FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.treffen_programm p
                  WHERE p.id = programm_id AND public.treffen_gastgeber(p.treffen_id)))
  WITH CHECK (EXISTS (SELECT 1 FROM public.treffen_programm p
                  WHERE p.id = programm_id AND public.treffen_gastgeber(p.treffen_id)));

-- Lesen: der Gastgeber sieht sein Treffen, ein eingeladener Verein seines,
-- die Oeffentlichkeit nur das freigegebene. Der bisherige Fall
-- is_platform_admin() steckt in treffen_gastgeber().
DROP POLICY IF EXISTS treffen_lesen ON public.treffen;
CREATE POLICY treffen_lesen ON public.treffen FOR SELECT TO anon, authenticated
  USING (
    status = 'OEFFENTLICH'
    OR public.is_platform_admin()
    OR (gastgeber IS NOT NULL
        AND gastgeber = public.current_tenant()
        AND public.is_staff()
        AND public.modul_aktiv('TREFFEN'))
    OR EXISTS (SELECT 1 FROM public.treffen_teilnehmer t
                WHERE t.treffen_id = id AND t."tenantId" = public.current_tenant())
  );

DROP POLICY IF EXISTS treffen_programm_lesen ON public.treffen_programm;
CREATE POLICY treffen_programm_lesen ON public.treffen_programm FOR SELECT TO anon, authenticated
  USING (
    public.treffen_gastgeber(treffen_id)
    OR (freigegeben AND EXISTS (SELECT 1 FROM public.treffen t
                                 WHERE t.id = treffen_id AND t.status = 'OEFFENTLICH'))
  );


-- ---------------------------------------------- Die Funktionen umhaengen
-- Alle, die bisher "Nur der Gastgeber" sagten und damit den Betreiber
-- meinten. Der Wortlaut stimmte schon -- nur die Pruefung war enger als
-- das Wort.
DO $$
DECLARE
  r RECORD;
  quelle text;
  neu    text;
  n int := 0;
BEGIN
  FOR r IN
    SELECT p.oid, p.proname, pg_get_functiondef(p.oid) AS def
      FROM pg_proc p JOIN pg_namespace ns ON ns.oid = p.pronamespace
     WHERE ns.nspname = 'public'
       AND p.proname IN ('treffen_zugang_erstellen','treffen_zugang_widerrufen',
                         'treffen_essenszahlen','treffen_namensschilder','treffen_heft',
                         'treffen_ausflugslisten','treffen_programm_verschieben')
  LOOP
    quelle := r.def;
    -- Die Wache tauscht gegen die Gastgeberfrage. p_treffen heisst in den
    -- beiden Zugangsfunktionen p_teilnehmer -- dort haengt die Frage am
    -- Treffen des Teilnehmers.
    IF r.proname IN ('treffen_zugang_erstellen','treffen_zugang_widerrufen') THEN
      neu := replace(quelle, 'NOT public.is_platform_admin()',
        'NOT public.treffen_gastgeber((SELECT te.treffen_id FROM public.treffen_teilnehmer te WHERE te.id = p_teilnehmer))');
    ELSIF r.proname = 'treffen_programm_verschieben' THEN
      neu := replace(quelle, 'NOT public.is_platform_admin()',
        'NOT public.treffen_gastgeber((SELECT p.treffen_id FROM public.treffen_programm p WHERE p.id = p_punkt))');
    ELSE
      neu := replace(quelle, 'NOT public.is_platform_admin()',
        'NOT public.treffen_gastgeber(p_treffen)');
    END IF;

    IF neu = quelle THEN
      RAISE EXCEPTION 'In % stand die erwartete Wache nicht -- nicht umgehaengt, '
                      'statt sie stillschweigend offen zu lassen.', r.proname;
    END IF;
    EXECUTE neu;
    n := n + 1;
  END LOOP;
  RAISE NOTICE '% Funktionen auf treffen_gastgeber() umgehaengt', n;
END $$;

-- treffen_vorstellung_links liess den Betreiber ODER den Verein fuer die
-- EIGENE Delegation. Der ausrichtende Verein muss dazu.
CREATE OR REPLACE FUNCTION public.treffen_vorstellung_links(p_teilnehmer uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_bis date; v_treffen uuid; v_darf boolean; r RECORD;
  v_token text; v_liste jsonb := '[]'::jsonb;
BEGIN
  SELECT te.treffen_id, coalesce(t.ende, t.datum)
    INTO v_treffen, v_bis
    FROM public.treffen_teilnehmer te JOIN public.treffen t ON t.id = te.treffen_id
   WHERE te.id = p_teilnehmer;
  IF v_treffen IS NULL THEN RAISE EXCEPTION 'Teilnehmer nicht gefunden.'; END IF;

  -- Ausstellen darf der Gastgeber -- oder der eingeladene Verein fuer
  -- seine EIGENE Delegation. Niemand sonst.
  SELECT public.treffen_gastgeber(v_treffen)
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
REVOKE ALL ON FUNCTION public.treffen_vorstellung_links(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.treffen_vorstellung_links(uuid) TO authenticated;

-- treffen_verrechnen bleibt beim Betreiber. Es schreibt in
-- platform_invoices -- das ist die Rechnung der PLATTFORM an einen
-- Verein. Ein Verein, der seine Gaeste zur Kasse bittet, hat damit
-- nichts zu tun; das ueber dieselbe Tabelle laufen zu lassen, erzeugte
-- Rechnungen, die niemand stellen wollte. Lieber eine klare Grenze als
-- eine falsche Zahl.
--
-- Die Pruefung wird in die bestehende Fassung eingehaengt, nicht durch
-- eine Kopie ersetzt: sechzig Zeilen Abrechnungslogik ein zweites Mal
-- hinzuschreiben hiesse, sie zweimal pflegen zu muessen.
DO $$
DECLARE quelle text; neu text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO quelle
    FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname='treffen_verrechnen';
  IF quelle IS NULL THEN RAISE EXCEPTION 'treffen_verrechnen fehlt.'; END IF;

  neu := replace(quelle,
    'RAISE EXCEPTION ''Nur der Gastgeber.'' USING ERRCODE=''insufficient_privilege'';
  END IF;',
    'RAISE EXCEPTION ''Nur der Betreiber darf ueber die Plattform verrechnen.''
      USING ERRCODE=''insufficient_privilege'';
  END IF;
  IF (SELECT gastgeber FROM public.treffen WHERE id = p_treffen) IS NOT NULL THEN
    RAISE EXCEPTION ''Dieses Treffen richtet ein Verein aus. Die Teilnahmebeitraege sind seine Sache, nicht die der Plattform.''
      USING ERRCODE=''check_violation'';
  END IF;');

  IF neu = quelle THEN
    RAISE EXCEPTION 'Die erwartete Wache stand nicht in treffen_verrechnen -- '
                    'nicht angefasst, statt sie blind zu ueberschreiben.';
  END IF;
  EXECUTE neu;
  RAISE NOTICE 'treffen_verrechnen auf Betreiber-Treffen begrenzt';
END $$;


-- ------------------------------------------- Die oeffentliche Ankuendigung
-- Bisher lieferte das alle freigegebenen Treffen -- gedacht fuer
-- unityhub.li, wo es nur die der Plattform gab. Mit Vereinen als
-- Gastgeber muss jede Seite ihre eigenen zeigen: auf koretini.me die von
-- Koretini, auf unityhub.li die der Plattform. Die Domain sagt das
-- bereits, ueber request_tenant().
CREATE OR REPLACE FUNCTION public.treffen_oeffentlich()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(jsonb_agg(j ORDER BY j->>'datum'), '[]'::jsonb) FROM (
    SELECT jsonb_build_object(
      'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
      'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
      'ort', t.ort, 'adresse', t.adresse,
      'anmeldeschluss', t.anmeldeschluss,
      'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung,
      'gastgeber', coalesce((SELECT tn.name FROM public.tenants tn WHERE tn.id = t.gastgeber),
                            'unityhub'),
      'vereine', (SELECT coalesce(jsonb_agg(coalesce(te.name, tn.name) ORDER BY coalesce(te.name, tn.name)), '[]'::jsonb)
                    FROM public.treffen_teilnehmer te
                    LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                   WHERE te.treffen_id = t.id AND te.art IN ('VEREIN','GASTVEREIN')
                     AND coalesce(te.zugesagt,false)),
      'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                      'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                      'spur', p.spur, 'fuer', p.fuer,
                      'art', p.art, 'ziel', p.ziel, 'rueckkehr', p.rueckkehr)
                      ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                     FROM public.treffen_programm p
                    WHERE p.treffen_id = t.id AND p.freigegeben)
    ) AS j
    FROM public.treffen t
   WHERE t.status = 'OEFFENTLICH'
     -- Jede Seite zeigt ihre eigenen: der Verein seine, unityhub die der
     -- Plattform. Ohne diese Zeile stuenden Koretinis Treffen auf jeder
     -- anderen Vereinsseite.
     AND t.gastgeber IS NOT DISTINCT FROM public.request_tenant()
  ) y;
$$;
REVOKE ALL ON FUNCTION public.treffen_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_oeffentlich() TO anon, authenticated;


-- ------------------------------------------------------- Im Marktplatz
INSERT INTO public.modules (schluessel, name_de, name_sq, name_en,
                            beschreibung_de, beschreibung_sq, beschreibung_en,
                            ist_kern, status, braucht_einrichtung,
                            preis_monat, reihenfolge)
SELECT 'TREFFEN',
  'Treffen organisieren', 'Organizimi i takimeve', 'Organise gatherings',
  'Eigene Treffen ausrichten statt nur teilzunehmen: Gastvereine und Gaeste einladen, Tagesprogramm mit parallelen Spuren und Ausfluegen, Einladungslinks, Selbstvorstellung der Teilnehmer, Essenszahlen, Namensschilder, Flyer und Poster sowie ein Heft mit allen Teilnehmenden nach dem Treffen.',
  'Organizoni takimet tuaja, jo vetem te merrni pjese: ftoni shoqata e mysafire, programi i dites me shtigje paralele dhe ekskursione, lidhje ftese, vetprezantimi i pjesemarresve, numrat e ushqimit, etiketat e emrave, fletushka e poster si dhe nje libercka me te gjithe pjesemarresit pas takimit.',
  'Host your own gatherings instead of only attending: invite guest associations and guests, a day programme with parallel tracks and excursions, invitation links, participant self-introductions, meal counts, name badges, flyers and posters, plus a booklet of everyone who came.',
  false, 'VERFUEGBAR', false, 12.00, 40
 WHERE NOT EXISTS (SELECT 1 FROM public.modules WHERE schluessel='TREFFEN');


-- ---------------------------------------------------------- Selbsttest
-- Geprueft wird, dass die Trennung in BEIDE Richtungen haelt: der
-- Gastgeber kommt an sein Treffen, und an das eines anderen nicht.
-- Eine Sperre, die nur das eine zeigt, hat nichts bewiesen.
DO $$
DECLARE
  v_fremd int;
  v_modul int;
  v_spalte boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='treffen'
                    AND column_name='gastgeber') INTO v_spalte;
  IF NOT v_spalte THEN RAISE EXCEPTION 'Spalte gastgeber fehlt.'; END IF;

  SELECT count(*) INTO v_modul FROM public.modules WHERE schluessel='TREFFEN';
  IF v_modul <> 1 THEN RAISE EXCEPTION 'Modul TREFFEN steht nicht im Katalog.'; END IF;

  -- Kein bestehendes Treffen darf durch diese Migration einem Verein
  -- zugefallen sein. Die bisherigen gehoeren der Plattform.
  SELECT count(*) INTO v_fremd FROM public.treffen WHERE gastgeber IS NOT NULL;
  IF v_fremd <> 0 THEN
    RAISE EXCEPTION 'Unerwartet: % bestehende Treffen haben einen Gastgeberverein.', v_fremd;
  END IF;

  -- Die Wache muss in jeder umgehaengten Funktion stehen. Ein
  -- vergessenes replace() faellt sonst erst auf, wenn jemand zu viel darf.
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
              WHERE ns.nspname='public'
                AND p.proname IN ('treffen_zugang_erstellen','treffen_zugang_widerrufen',
                      'treffen_essenszahlen','treffen_namensschilder','treffen_heft',
                      'treffen_ausflugslisten','treffen_programm_verschieben')
                AND p.prosrc !~ 'treffen_gastgeber') THEN
    RAISE EXCEPTION 'Mindestens eine Funktion traegt die neue Wache nicht.';
  END IF;

  -- Jede Funktion, die in einer Regel FUER anon steht, muss von anon
  -- auch ausfuehrbar sein. Diese Fehlerklasse faellt sonst erst auf,
  -- wenn ein Besucher eine weisse Seite sieht -- und zwar nur er, denn
  -- angemeldet funktioniert alles.
  DECLARE v_fehlt text;
  BEGIN
    SELECT string_agg(DISTINCT f.name, ', ') INTO v_fehlt
      FROM pg_policies pol
      CROSS JOIN LATERAL regexp_matches(
             coalesce(pol.qual,'')||' '||coalesce(pol.with_check,''),
             'public\.([a-z_]+)\(', 'g') AS m(name)
      CROSS JOIN LATERAL (SELECT m.name[1] AS name) f
      JOIN pg_proc p ON p.proname = f.name
      JOIN pg_namespace ns ON ns.oid = p.pronamespace AND ns.nspname='public'
     WHERE pol.schemaname='public'
       AND 'anon' = ANY(pol.roles)
       AND NOT has_function_privilege('anon', p.oid, 'EXECUTE');
    IF v_fehlt IS NOT NULL THEN
      RAISE EXCEPTION 'In Regeln fuer anon stehen Funktionen, die anon nicht ausfuehren darf: %', v_fehlt;
    END IF;
  END;

  RAISE NOTICE 'Treffen-Modul steht im Marktplatz. Bestehende Treffen bleiben bei der Plattform.';
END $$;
