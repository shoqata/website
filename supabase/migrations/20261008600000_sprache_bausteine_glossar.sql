-- Drei Luecken, die Floky braucht -- und die auch ohne ihn nuetzen.
--
-- Gemessen vor dieser Migration:
--   * users hat KEINE Spalte fuer die Sprache. Die Regel "Texte an
--     Mitglieder in deren hinterlegter Sprache" konnte nicht greifen.
--   * Es gibt keine Tabelle fuer Textbausteine (>Mahnung 1) und keine
--     fuer ein Vereinsglossar. Beides stand im Konzept als gegeben.
--
-- Alle drei nuetzen sofort, unabhaengig vom Assistenten: Rechnungen in
-- der richtigen Sprache, einheitliche Mahntexte, stabile Begriffe.

-- ------------------------------------------------------------ Sprache
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS sprache text
    CHECK (sprache IS NULL OR sprache IN ('de','sq','en'));

COMMENT ON COLUMN public.users.sprache IS
  'Sprache fuer Schreiben an dieses Mitglied. NULL = unbekannt; dann '
  'zweisprachig vorschlagen statt raten.';

-- Bewusst KEIN Backfill. Es gibt kein verlaessliches Merkmal: das
-- Laenderfeld ist bei 323 von 340 Mitgliedern leer, und aus einem Namen
-- auf die Sprache zu schliessen waere eine Unterstellung. NULL heisst
-- hier "noch nicht gefragt" und loest genau das aus, was das Konzept
-- vorsieht -- einen zweisprachigen Vorschlag.


-- ------------------------------------------------------- Textbausteine
-- Je Verein, je Schluessel, je Sprache genau ein Text. Ohne diese
-- Dreiheit haette ein Verein entweder nur eine Sprache oder zwei Texte
-- fuer denselben Zweck.
CREATE TABLE IF NOT EXISTS public.textbausteine (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  schluessel    text NOT NULL,
  sprache       text NOT NULL CHECK (sprache IN ('de','sq','en')),
  betreff       text,
  text          text NOT NULL,
  aktiv         boolean NOT NULL DEFAULT true,
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  geaendert_von text,
  CONSTRAINT textbausteine_einmalig UNIQUE ("tenantId", schluessel, sprache)
);
CREATE INDEX IF NOT EXISTS textbausteine_verein ON public.textbausteine ("tenantId", schluessel);

-- ------------------------------------------------------------ Glossar
-- Der Teil, der ueber die Qualitaet der albanischen Texte entscheidet.
-- Ein Verein sagt "Lagje", ein anderer "Nachbarschaft" -- wer das jedes
-- Mal neu uebersetzt, schreibt in jedem Brief etwas anderes.
CREATE TABLE IF NOT EXISTS public.glossar (
  "tenantId"    text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  begriff       text NOT NULL,
  de            text,
  sq            text,
  en            text,
  hinweis       text,
  geaendert_am  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY ("tenantId", begriff)
);


-- --------------------------------------------------------------- Rechte
ALTER TABLE public.textbausteine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.glossar       ENABLE ROW LEVEL SECURITY;

-- Lesen darf, wer zum Verein gehoert -- ein Mitglied sieht den Text, der
-- an es selbst geht. Aendern darf die Verwaltung.
DROP POLICY IF EXISTS textbausteine_lesen ON public.textbausteine;
CREATE POLICY textbausteine_lesen ON public.textbausteine FOR SELECT TO authenticated
  USING ("tenantId" = public.current_tenant() OR public.is_platform_admin());

DROP POLICY IF EXISTS textbausteine_pflegen ON public.textbausteine;
CREATE POLICY textbausteine_pflegen ON public.textbausteine FOR ALL TO authenticated
  USING (public.is_platform_admin()
         OR ("tenantId" = public.current_tenant() AND public.is_staff()))
  WITH CHECK (public.is_platform_admin()
         OR ("tenantId" = public.current_tenant() AND public.is_staff()));

DROP POLICY IF EXISTS glossar_lesen ON public.glossar;
CREATE POLICY glossar_lesen ON public.glossar FOR SELECT TO authenticated
  USING ("tenantId" = public.current_tenant() OR public.is_platform_admin());

DROP POLICY IF EXISTS glossar_pflegen ON public.glossar;
CREATE POLICY glossar_pflegen ON public.glossar FOR ALL TO authenticated
  USING (public.is_platform_admin()
         OR ("tenantId" = public.current_tenant() AND public.is_staff()))
  WITH CHECK (public.is_platform_admin()
         OR ("tenantId" = public.current_tenant() AND public.is_staff()));

-- anon bekommt hier nichts -- weder lesend noch schreibend.
REVOKE ALL ON public.textbausteine FROM anon;
REVOKE ALL ON public.glossar       FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.textbausteine TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.glossar       TO authenticated;


-- ------------------------------------------------- Glossar vorbelegen
-- Die Begriffe, die in jedem Diasporaverein vorkommen. Jeder Verein kann
-- sie aendern; vorbelegt sind sie, damit niemand bei null anfaengt.
INSERT INTO public.glossar ("tenantId", begriff, de, sq, en, hinweis)
SELECT t.id, g.begriff, g.de, g.sq, g.en, g.hinweis
  FROM public.tenants t
  CROSS JOIN (VALUES
    ('NACHBARSCHAFT','Nachbarschaft','Lagje','Neighbourhood','Ortsteil im Herkunftsdorf'),
    ('BEITRAG',      'Mitgliederbeitrag','Kontribut','Membership fee',NULL),
    ('PRAESIDENT',   'Präsident','Kryetar','President',NULL),
    ('KASSIER',      'Kassier','Arkëtar','Treasurer',NULL),
    ('AKTUAR',       'Aktuar','Sekretar','Secretary',NULL),
    ('VORSTAND',     'Vorstand','Kryesia','Board',NULL),
    ('MITGLIED',     'Mitglied','Anëtar','Member',NULL),
    ('VEREIN',       'Verein','Shoqata','Association',NULL),
    ('GV',           'Generalversammlung','Kuvendi i përgjithshëm','General assembly',NULL),
    ('SPENDE',       'Spende','Donacion','Donation',NULL),
    ('TREFFEN',      'Treffen','Takim','Gathering',NULL),
    ('MAHNUNG',      'Mahnung','Përkujtesë','Reminder',NULL)
  ) AS g(begriff, de, sq, en, hinweis)
 WHERE NOT EXISTS (SELECT 1 FROM public.glossar x
                    WHERE x."tenantId" = t.id AND x.begriff = g.begriff);


-- ------------------------------------------- Textbausteine vorbelegen
-- Platzhalter in {{ }}, damit sie beim Einsetzen erkennbar bleiben.
INSERT INTO public.textbausteine ("tenantId", schluessel, sprache, betreff, text)
SELECT t.id, b.schluessel, b.sprache, b.betreff, b.text
  FROM public.tenants t
  CROSS JOIN (VALUES
    ('MAHNUNG_1','de','Erinnerung an den Mitgliederbeitrag {{jahr}}',
     E'Liebe/r {{anrede}}\n\nUnsere Unterlagen zeigen, dass der Mitgliederbeitrag {{jahr}} über {{betrag}} noch offen ist. Vielleicht ist er untergegangen — das passiert.\n\nDie Rechnung liegt bei; mit dem QR-Code ist sie in der Banking-App in einer Minute bezahlt.\n\nFalls etwas nicht stimmt, melden Sie sich bitte bei uns.\n\nHerzliche Grüsse\n{{verein}}'),
    ('MAHNUNG_1','sq','Përkujtesë për kontributin {{jahr}}',
     E'I/E nderuar {{anrede}}\n\nSipas të dhënave tona, kontributi i anëtarësisë për {{jahr}} në shumën {{betrag}} është ende i papaguar. Ndoshta ka kaluar pa u vërejtur — ndodh.\n\nFatura është bashkëngjitur; me kodin QR paguhet brenda një minute në aplikacionin bankar.\n\nNëse diçka nuk përputhet, ju lutemi na kontaktoni.\n\nPërshëndetje\n{{verein}}'),
    ('MAHNUNG_2','de','Zweite Erinnerung — Mitgliederbeitrag {{jahr}}',
     E'Liebe/r {{anrede}}\n\nWir haben Sie bereits einmal an den Mitgliederbeitrag {{jahr}} über {{betrag}} erinnert. Er ist weiterhin offen.\n\nBitte begleichen Sie ihn bis {{frist}} oder melden Sie sich bei uns, wenn eine Ratenzahlung hilft.\n\nHerzliche Grüsse\n{{verein}}'),
    ('MAHNUNG_2','sq','Përkujtesë e dytë — kontributi {{jahr}}',
     E'I/E nderuar {{anrede}}\n\nJu kemi përkujtuar një herë për kontributin e {{jahr}} në shumën {{betrag}}. Ai është ende i papaguar.\n\nJu lutemi ta paguani deri më {{frist}}, ose na kontaktoni nëse një pagesë me këste do të ndihmonte.\n\nPërshëndetje\n{{verein}}'),
    ('DANK_SPENDE','de','Danke für Ihre Spende',
     E'Liebe/r {{anrede}}\n\nHerzlichen Dank für Ihre Spende von {{betrag}}. Sie fliesst in {{zweck}}.\n\nDie Spendenbescheinigung erhalten Sie am Jahresende.\n\n{{verein}}'),
    ('DANK_SPENDE','sq','Faleminderit për donacionin tuaj',
     E'I/E nderuar {{anrede}}\n\nFaleminderit përzemërsisht për donacionin tuaj prej {{betrag}}. Ai shkon për {{zweck}}.\n\nVërtetimin e donacionit do ta merrni në fund të vitit.\n\n{{verein}}'),
    ('EINLADUNG_GV','de','Einladung zur Generalversammlung {{jahr}}',
     E'Liebe Mitglieder\n\nHiermit laden wir euch zur Generalversammlung {{jahr}} ein.\n\nDatum: {{datum}}\nOrt: {{ort}}\n\nTraktanden:\n{{traktanden}}\n\nWir freuen uns auf euch.\n{{verein}}'),
    ('EINLADUNG_GV','sq','Ftesë për Kuvendin e përgjithshëm {{jahr}}',
     E'Të nderuar anëtarë\n\nJu ftojmë në Kuvendin e përgjithshëm {{jahr}}.\n\nData: {{datum}}\nVendi: {{ort}}\n\nRendi i ditës:\n{{traktanden}}\n\nMirëpresim pjesëmarrjen tuaj.\n{{verein}}')
  ) AS b(schluessel, sprache, betreff, text)
 WHERE NOT EXISTS (SELECT 1 FROM public.textbausteine x
                    WHERE x."tenantId" = t.id AND x.schluessel = b.schluessel
                      AND x.sprache = b.sprache);


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_spalte boolean; v_glossar int; v_texte int; v_vereine int;
        v_geraten int; v_anon int;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='users' AND column_name='sprache')
    INTO v_spalte;
  IF NOT v_spalte THEN RAISE EXCEPTION 'Spalte users.sprache fehlt.'; END IF;

  -- Niemand darf eine Sprache bekommen haben, die nicht erfragt wurde.
  SELECT count(*) INTO v_geraten FROM public.users WHERE sprache IS NOT NULL;
  IF v_geraten > 0 THEN
    RAISE EXCEPTION '% Mitglieder haben bereits eine Sprache -- diese Migration '
                    'sollte keine raten.', v_geraten;
  END IF;

  SELECT count(*) INTO v_vereine FROM public.tenants;
  SELECT count(*) INTO v_glossar FROM public.glossar;
  SELECT count(*) INTO v_texte   FROM public.textbausteine;

  IF v_glossar <> v_vereine * 12 THEN
    RAISE EXCEPTION 'Glossar: erwartet % Eintraege (% Vereine x 12), gefunden %.',
      v_vereine*12, v_vereine, v_glossar;
  END IF;
  IF v_texte <> v_vereine * 8 THEN
    RAISE EXCEPTION 'Textbausteine: erwartet % (% Vereine x 8), gefunden %.',
      v_vereine*8, v_vereine, v_texte;
  END IF;

  -- Beides sind Vereinsdaten. anon hat hier nichts verloren.
  SELECT count(*) INTO v_anon FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon'
     AND table_name IN ('textbausteine','glossar');
  IF v_anon > 0 THEN
    RAISE EXCEPTION 'anon hat Rechte auf textbausteine/glossar.';
  END IF;

  RAISE NOTICE 'Sprache, % Glossarbegriffe und % Textbausteine je Verein angelegt.',
    v_glossar / greatest(v_vereine,1), v_texte / greatest(v_vereine,1);
END $$;
