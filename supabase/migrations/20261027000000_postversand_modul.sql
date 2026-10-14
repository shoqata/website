-- Postversand als Modul im Marktplatz, mit Kontingent und Aufpreis.
--
-- Der Verein schaltet das Modul frei und kauft ein Kontingent an
-- Briefen. unityhub kauft sie bei Pingen und legt je Verein und Brief
-- einen Aufpreis darauf. Damit ist unityhub Wiederverkaeufer, und das
-- hat drei Folgen fuer den Aufbau:
--
--   Es gibt EIN Pingen-Konto, das der Plattform. Die Zuordnung je
--   Verein ist unsere Rechnung, nicht die von Pingen.
--
--   Der Katalog kennt nur preis_monat und preis_einmalig. Ein Preis JE
--   STUECK passt in keines von beiden -- darum ein eigener Preis je
--   Verein, nicht ein Missbrauch der Monatsgebuehr.
--
--   Jede Bewegung muss nachvollziehbar sein. Ein blosser Zaehler
--   "guthaben" liesse offen, woher er kommt: gekauft, verbraucht,
--   gutgeschrieben? Bei Geld ist das nicht hinnehmbar. Also ein
--   Bewegungsbuch, aus dem der Stand folgt -- dieselbe Entscheidung wie
--   bei den Zahlungseingaengen.
--
-- Vorbild fuer das Kontingent ist Floky (kontingent_monat = 150), aber
-- der Unterschied ist wesentlich: Floky bekommt monatlich ein frisches
-- Guthaben, Briefe werden gekauft und bleiben, bis sie verbraucht sind.
-- Ein Monatszaehler waere hier falsch -- ein im Dezember gekauftes
-- Kontingent verfaellt nicht am 1. Januar.

-- -------------------------------------------------- Das Modul
INSERT INTO public.modules
  (schluessel, name_de, name_sq, name_en,
   beschreibung_de, beschreibung_sq, beschreibung_en,
   preis_monat, preis_einmalig, braucht_einrichtung, status, ist_kern, reihenfolge)
VALUES ('POSTVERSAND',
  'Briefe per Post', 'Letra me postë', 'Letters by post',
  'Rechnungen und Mahnungen gehen als echter Brief hinaus — gedruckt, kuvertiert '
  || 'und frankiert, ohne dass jemand im Verein etwas davon anfasst. Abgerechnet '
  || 'wird je Brief aus einem Kontingent, das Sie hier kaufen.',
  'Faturat dhe përkujtesat dërgohen si letër e vërtetë — e shtypur, e zarfuar dhe '
  || 'e frankuar, pa që ndonjë në shoqatë të merret me të. Faturohet sipas letrës '
  || 'nga një kuotë që blini këtu.',
  'Invoices and reminders go out as real letters — printed, enveloped and stamped, '
  || 'without anyone in the association touching them. Billed per letter from a '
  || 'quota you buy here.',
  NULL, NULL, true, 'BETA', false, 95)
ON CONFLICT (schluessel) DO UPDATE
   SET name_de = EXCLUDED.name_de,
       beschreibung_de = EXCLUDED.beschreibung_de,
       braucht_einrichtung = true;


-- Die Rechnungsart erweitern.
--
-- platform_invoices.kind erlaubt nur SETUP, ANNUAL, TREFFEN, OTHER.
-- 'OTHER' waere bequem und falsch: der Wiederverkauf von Briefen ist
-- ein anderes Geschaeft als eine Jahresgebuehr, und der Betreiber muss
-- seine Erloese daraus getrennt sehen koennen. Eine Art, die alles
-- sammelt, beantwortet keine Frage.
ALTER TABLE public.platform_invoices DROP CONSTRAINT IF EXISTS platform_invoices_kind_check;
ALTER TABLE public.platform_invoices ADD CONSTRAINT platform_invoices_kind_check
  CHECK (kind IN ('SETUP','ANNUAL','TREFFEN','POSTKONTINGENT','OTHER'));


-- ---------------------------------------------- Preis je Verein
CREATE TABLE IF NOT EXISTS public.post_preise (
  "tenantId"       text PRIMARY KEY,
  -- Was der Verein je Brief zahlt. Enthaelt den Aufpreis von unityhub.
  preis_je_brief   numeric(10,2) NOT NULL,
  -- Was unityhub bei Pingen dafuer zahlt. Nur fuer die Marge, nie fuer
  -- den Verein sichtbar -- der Einkaufspreis ist unsere Sache.
  einkauf_je_brief numeric(10,2),
  waehrung         text NOT NULL DEFAULT 'CHF',
  geaendert_am     timestamptz NOT NULL DEFAULT now(),
  geaendert_von    text
);
ALTER TABLE public.post_preise ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.post_preise FROM anon, authenticated;

COMMENT ON TABLE public.post_preise IS
  'Briefpreis je Verein, inklusive Aufpreis. einkauf_je_brief ist der '
  'Einkaufspreis bei Pingen und darf einem Verein nie angezeigt werden.';


-- ------------------------------------------ Das Bewegungsbuch
CREATE TABLE IF NOT EXISTS public.post_kontingent (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  -- KAUF und GUTSCHRIFT erhoehen, VERBRAUCH und STORNO senken.
  art           text NOT NULL,
  -- Vorzeichenrichtig gespeichert: so ist der Stand eine Summe und
  -- keine Fallunterscheidung. Eine Summe, die von der Art abhaengt,
  -- wird irgendwann an einer Stelle falsch gebildet.
  menge         integer NOT NULL,
  preis_je_brief   numeric(10,2),
  einkauf_je_brief numeric(10,2),
  waehrung      text NOT NULL DEFAULT 'CHF',
  "postId"      uuid,
  "rechnungId"  uuid,
  grund         text,
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  erstellt_von  text
);

DO $$ BEGIN
  ALTER TABLE public.post_kontingent ADD CONSTRAINT post_kontingent_art
    CHECK (art IN ('KAUF','VERBRAUCH','GUTSCHRIFT','STORNO'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  -- Das Vorzeichen muss zur Art passen. Ohne diese Bedingung koennte ein
  -- Verbrauch mit positiver Menge das Guthaben erhoehen.
  ALTER TABLE public.post_kontingent ADD CONSTRAINT post_kontingent_vorzeichen
    CHECK ((art IN ('KAUF','GUTSCHRIFT') AND menge > 0)
        OR (art IN ('VERBRAUCH','STORNO') AND menge < 0));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Je Brief nur ein Verbrauch. Ohne das koennte ein zweiter Lauf
-- denselben Brief ein zweites Mal abbuchen.
CREATE UNIQUE INDEX IF NOT EXISTS post_kontingent_je_brief
  ON public.post_kontingent ("postId") WHERE "postId" IS NOT NULL;

CREATE INDEX IF NOT EXISTS post_kontingent_verein
  ON public.post_kontingent ("tenantId", erstellt_am DESC);

ALTER TABLE public.post_kontingent ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.post_kontingent FROM anon, authenticated;

COMMENT ON TABLE public.post_kontingent IS
  'Bewegungsbuch des Briefkontingents. Der Stand ist die Summe der '
  'Mengen -- kein eigener Zaehler, der auseinanderlaufen koennte.';


-- --------------------------------------------------------- Der Stand
CREATE OR REPLACE FUNCTION public.post_kontingent_stand(p_verein text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text;
  v_stand int; v_gekauft int; v_verbraucht int;
  v_preis numeric; v_waehrung text; v_modul boolean;
BEGIN
  -- Der Betreiber darf nach einem Verein fragen; ein Verein sieht nur
  -- den eigenen Stand, unabhaengig davon, was er mitschickt.
  v_verein := CASE
    WHEN public.is_platform_admin() THEN coalesce(p_verein, public.current_tenant())
    WHEN public.is_member_manager() THEN public.current_tenant()
    ELSE NULL END;
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT coalesce(sum(menge), 0),
         coalesce(sum(menge) FILTER (WHERE menge > 0), 0),
         coalesce(-sum(menge) FILTER (WHERE menge < 0), 0)
    INTO v_stand, v_gekauft, v_verbraucht
    FROM public.post_kontingent WHERE "tenantId" = v_verein;

  SELECT preis_je_brief, waehrung INTO v_preis, v_waehrung
    FROM public.post_preise WHERE "tenantId" = v_verein;

  SELECT EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = v_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')) INTO v_modul;

  RETURN jsonb_build_object(
    'verein', v_verein,
    'modul_aktiv', v_modul,
    'stand', v_stand,
    'gekauft', v_gekauft,
    'verbraucht', v_verbraucht,
    'preis_je_brief', v_preis,
    'waehrung', coalesce(v_waehrung, 'CHF'),
    -- Kein Preis heisst: der Betreiber hat noch keinen festgelegt. Dann
    -- kann nichts gekauft werden, und das soll dastehen statt stillem
    -- Nichtfunktionieren.
    'kaufbar', v_preis IS NOT NULL AND v_preis > 0);
END $$;

REVOKE ALL ON FUNCTION public.post_kontingent_stand(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_kontingent_stand(text) TO authenticated;


-- ------------------------------------------------- Preis festlegen
CREATE OR REPLACE FUNCTION public.post_preis_setzen(
  p_verein text, p_preis numeric, p_einkauf numeric DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Nur der Betreiber. Der Preis enthaelt seinen Aufpreis; ein Verein,
  -- der ihn selbst setzen koennte, kaufte zum Selbstkostenpreis.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Plattformbetreiber legt Briefpreise fest.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_preis IS NULL OR p_preis <= 0 THEN
    RAISE EXCEPTION 'Ein Briefpreis muss groesser als null sein.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF p_einkauf IS NOT NULL AND p_einkauf > p_preis THEN
    -- Kein Verbot, aber ein Hinweis waere zu leise: wer unter Einkauf
    -- verkauft, tut es nicht aus Versehen zweimal.
    RAISE EXCEPTION 'Der Verkaufspreis (%) liegt unter dem Einkauf (%). Wenn das '
                    'gewollt ist, Einkauf leer lassen.', p_preis, p_einkauf
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.post_preise ("tenantId", preis_je_brief, einkauf_je_brief,
                                  geaendert_am, geaendert_von)
  VALUES (p_verein, p_preis, p_einkauf, now(), public.current_user_row_id())
  ON CONFLICT ("tenantId") DO UPDATE
     SET preis_je_brief = EXCLUDED.preis_je_brief,
         einkauf_je_brief = EXCLUDED.einkauf_je_brief,
         geaendert_am = now(), geaendert_von = EXCLUDED.geaendert_von;

  RETURN jsonb_build_object('verein', p_verein, 'preis_je_brief', p_preis,
                            'einkauf_je_brief', p_einkauf);
END $$;

REVOKE ALL ON FUNCTION public.post_preis_setzen(text,numeric,numeric) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_preis_setzen(text,numeric,numeric) TO authenticated;


-- ------------------------------------------------------- Kontingent kaufen
--
-- Der Verein kauft, unityhub verrechnet. Es entstehen zwei Zeilen: die
-- Bewegung im Kontingentbuch und eine Rechnung in platform_invoices.
-- Beide in EINEM Vorgang -- ein Kontingent ohne Rechnung waere ein
-- Geschenk, eine Rechnung ohne Kontingent ein Aerger.
CREATE OR REPLACE FUNCTION public.post_kontingent_kaufen(p_menge integer)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_preis numeric; v_einkauf numeric; v_waehrung text;
  v_betrag numeric; v_nummer text; v_rechnung uuid; v_id uuid;
BEGIN
  IF NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Der Vorstand darf in diesem Verein nichts aendern.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  -- Kaufen heisst Geld ausgeben. Das ist Sache der Administration, nicht
  -- jedes Vorstandsmitglieds.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf ein Kontingent kaufen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_menge IS NULL OR p_menge < 1 OR p_menge > 10000 THEN
    RAISE EXCEPTION 'Bitte zwischen 1 und 10000 Briefen kaufen.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenant_modules tm
                  WHERE tm."tenantId" = v_verein AND tm.modul = 'POSTVERSAND'
                    AND tm.zustand IN ('AN','TESTPHASE')) THEN
    RAISE EXCEPTION 'Das Modul Briefversand ist fuer diesen Verein nicht aktiv.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT preis_je_brief, einkauf_je_brief, waehrung
    INTO v_preis, v_einkauf, v_waehrung
    FROM public.post_preise WHERE "tenantId" = v_verein;
  IF v_preis IS NULL OR v_preis <= 0 THEN
    RAISE EXCEPTION 'Fuer diesen Verein ist noch kein Briefpreis festgelegt. '
                    'Der Plattformbetreiber legt ihn fest.'
      USING ERRCODE = 'check_violation';
  END IF;

  v_betrag := round(v_preis * p_menge, 2);
  v_nummer := 'POST-' || to_char(now(), 'YYYYMM') || '-'
              || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 5));
  v_rechnung := gen_random_uuid();

  -- Die Rechnung von unityhub an den Verein. Dieselbe Tabelle wie bei
  -- den Treffen; eine zweite Rechnungsstelle waere eine zweite Wahrheit
  -- ueber dieselbe Forderung.
  INSERT INTO public.platform_invoices
    (id, "tenantId", kind, amount, currency, year, status, "invoiceNumber",
     "issuedAt", "dueDate", note)
  -- Zustand DRAFT, nicht 'OPEN': die Bedingung erlaubt nur DRAFT, SENT,
  -- PAID, CANCELLED. Und die Datumsfelder sind date, nicht text -- mein
  -- erster Versuch schrieb beides falsch und scheiterte mit
  -- "operator does not exist: uuid = text", also an einer dritten
  -- Stelle. Drei Annahmen ueber eine Tabelle, die ich haette nachsehen
  -- koennen.
  VALUES (v_rechnung, v_verein, 'POSTKONTINGENT', v_betrag,
          coalesce(v_waehrung, 'CHF'),
          extract(year from now())::int, 'DRAFT', v_nummer,
          current_date, current_date + 30,
          p_menge || ' Briefe à ' || v_preis || ' ' || coalesce(v_waehrung,'CHF'));

  INSERT INTO public.post_kontingent
    ("tenantId", art, menge, preis_je_brief, einkauf_je_brief, waehrung,
     "rechnungId", grund, erstellt_von)
  VALUES (v_verein, 'KAUF', p_menge, v_preis, v_einkauf, coalesce(v_waehrung,'CHF'),
          v_rechnung, 'Kontingent gekauft', public.current_user_row_id())
  RETURNING id INTO v_id;

  RETURN jsonb_build_object('gekauft', p_menge, 'betrag', v_betrag,
    'waehrung', coalesce(v_waehrung,'CHF'), 'rechnungsnummer', v_nummer,
    'stand', (public.post_kontingent_stand() -> 'stand'));
END $$;

REVOKE ALL ON FUNCTION public.post_kontingent_kaufen(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_kontingent_kaufen(integer) TO authenticated;


-- --------------------------------------------- Einen Brief abbuchen
--
-- Nur service_role: das tut die Edge Function, nachdem Pingen den Brief
-- angenommen hat. Vorher abzubuchen hiesse, ein Guthaben fuer etwas zu
-- verbrauchen, das vielleicht nie hinausgeht.
CREATE OR REPLACE FUNCTION public.post_kontingent_verbrauchen(p_post uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE b record; v_stand int; v_preis numeric; v_einkauf numeric;
BEGIN
  SELECT * INTO b FROM public.post_ausgang WHERE id = p_post;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Diesen Brief gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  -- Schon abgebucht? Dann nichts tun und das auch sagen. Der eindeutige
  -- Index faengt es ohnehin; eine Meldung ist besser als ein Fehler.
  IF EXISTS (SELECT 1 FROM public.post_kontingent WHERE "postId" = p_post) THEN
    RETURN jsonb_build_object('verbraucht', false, 'grund', 'bereits abgebucht');
  END IF;

  SELECT coalesce(sum(menge), 0) INTO v_stand
    FROM public.post_kontingent WHERE "tenantId" = b."tenantId";
  IF v_stand < 1 THEN
    RETURN jsonb_build_object('verbraucht', false, 'stand', v_stand,
      'grund', 'Kontingent aufgebraucht');
  END IF;

  SELECT preis_je_brief, einkauf_je_brief INTO v_preis, v_einkauf
    FROM public.post_preise WHERE "tenantId" = b."tenantId";

  INSERT INTO public.post_kontingent
    ("tenantId", art, menge, preis_je_brief, einkauf_je_brief, "postId", grund)
  VALUES (b."tenantId", 'VERBRAUCH', -1, v_preis, v_einkauf, p_post,
          'Brief an ' || left(coalesce(b.empfaenger, '?'), 80));

  RETURN jsonb_build_object('verbraucht', true, 'stand', v_stand - 1);
END $$;

REVOKE ALL ON FUNCTION public.post_kontingent_verbrauchen(uuid)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_kontingent_verbrauchen(uuid) TO service_role;


-- --------------------------------------------------- Die Marge, fuer unityhub
CREATE OR REPLACE FUNCTION public.post_marge()
RETURNS TABLE (
  r_verein text, r_name text, r_gekauft bigint, r_verbraucht bigint,
  r_stand bigint, r_erloes numeric, r_einkauf numeric, r_marge numeric,
  r_preis numeric
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT k."tenantId", coalesce(t.name, k."tenantId"),
         coalesce(sum(k.menge) FILTER (WHERE k.menge > 0), 0)::bigint,
         coalesce(-sum(k.menge) FILTER (WHERE k.menge < 0), 0)::bigint,
         coalesce(sum(k.menge), 0)::bigint,
         -- Erloes aus Kaeufen, Kosten aus VERBRAUCH: gekauft wird bei
         -- Pingen erst, wenn der Brief wirklich hinausgeht. Ein
         -- Kontingent, das niemand verbraucht, kostet uns nichts.
         coalesce(sum(k.menge * k.preis_je_brief) FILTER (WHERE k.menge > 0), 0),
         coalesce(-sum(k.menge * k.einkauf_je_brief) FILTER (WHERE k.menge < 0), 0),
         coalesce(sum(k.menge * k.preis_je_brief) FILTER (WHERE k.menge > 0), 0)
           - coalesce(-sum(k.menge * k.einkauf_je_brief) FILTER (WHERE k.menge < 0), 0),
         (SELECT p.preis_je_brief FROM public.post_preise p WHERE p."tenantId" = k."tenantId")
    FROM public.post_kontingent k
    LEFT JOIN public.tenants t ON t.id = k."tenantId"
   WHERE public.is_platform_admin()
   GROUP BY k."tenantId", t.name
   ORDER BY 8 DESC;
$$;

REVOKE ALL ON FUNCTION public.post_marge() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_marge() TO authenticated;


-- Das Bewegungsbuch fuer den Verein -- ohne den Einkaufspreis.
CREATE OR REPLACE FUNCTION public.post_kontingent_buch(p_grenze integer DEFAULT 100)
RETURNS TABLE (
  r_art text, r_menge integer, r_preis numeric, r_waehrung text,
  r_grund text, r_rechnung text, r_am timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT k.art, k.menge, k.preis_je_brief, k.waehrung, k.grund,
         (SELECT i."invoiceNumber" FROM public.platform_invoices i
           WHERE i.id = k."rechnungId"),
         k.erstellt_am
    FROM public.post_kontingent k
   WHERE (public.is_platform_admin()
          OR (k."tenantId" = public.current_tenant() AND public.is_member_manager()))
     AND (public.is_platform_admin() OR k."tenantId" = public.current_tenant())
   ORDER BY k.erstellt_am DESC
   LIMIT greatest(1, least(coalesce(p_grenze, 100), 500));
$$;

REVOKE ALL ON FUNCTION public.post_kontingent_buch(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_kontingent_buch(integer) TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_admin text; v_verein text; v_erg jsonb; v_zahlung text := 'selbsttest-kontingent';
  v_post uuid; v_vorher int; v_nachher int; v_quelle text; v_rechnungen int;
BEGIN
  -- Der Einkaufspreis darf einem Verein nie angezeigt werden.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='post_kontingent_buch';
  IF v_quelle ~ 'einkauf' THEN
    RAISE EXCEPTION 'post_kontingent_buch gibt den Einkaufspreis heraus.';
  END IF;
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='post_kontingent_stand';
  IF v_quelle ~ 'einkauf' THEN
    RAISE EXCEPTION 'post_kontingent_stand gibt den Einkaufspreis heraus.';
  END IF;
  -- Abbuchen darf nur die Serverrolle.
  IF has_function_privilege('authenticated',
       'public.post_kontingent_verbrauchen(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated darf Kontingent abbuchen -- damit liesse sich '
                    'das Guthaben eines Vereins von aussen leeren.';
  END IF;
  -- Und den Preis nur der Betreiber.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='post_preis_setzen';
  IF v_quelle !~ 'is_platform_admin' OR v_quelle ~ '''ADMIN''' THEN
    RAISE EXCEPTION 'post_preis_setzen laesst nicht nur den Betreiber durch -- ein '
                    'Verein koennte seinen eigenen Preis setzen.';
  END IF;

  SELECT u."tenantId", u."authUserId" INTO v_verein, v_admin FROM public.users u
   WHERE u.role IN ('SUPER_ADMIN','ADMIN') AND u."authUserId" IS NOT NULL
   ORDER BY u.id LIMIT 1;
  IF v_admin IS NULL THEN
    RAISE NOTICE 'Keine angemeldete Administration -- Verhaltenstest uebersprungen.';
    RETURN;
  END IF;

  SELECT count(*) INTO v_vorher FROM public.post_kontingent;
  SELECT count(*) INTO v_rechnungen FROM public.platform_invoices;

  -- Ohne Preis kein Kauf. Das Modul fuer den Test anschalten.
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES (v_verein, 'POSTVERSAND', 'TESTPHASE')
  ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand = 'TESTPHASE';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role','authenticated')::text, true);
  PERFORM set_config('role','authenticated', true);

  BEGIN
    PERFORM public.post_kontingent_kaufen(10);
    RAISE EXCEPTION 'Ein Kauf ohne festgelegten Preis ging durch.';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- Ein Verein darf seinen Preis nicht selbst setzen.
  BEGIN
    PERFORM public.post_preis_setzen(v_verein, 0.10);
    RAISE EXCEPTION 'Die Vereinsadministration konnte den Briefpreis setzen.';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('role','postgres', true);
  PERFORM set_config('request.jwt.claims', NULL, true);

  -- Preis als Betreiber setzen -- hier direkt in die Tabelle, weil der
  -- Test keine Betreiberkennung hat.
  INSERT INTO public.post_preise ("tenantId", preis_je_brief, einkauf_je_brief)
  VALUES (v_verein, 2.20, 1.60)
  ON CONFLICT ("tenantId") DO UPDATE
     SET preis_je_brief = 2.20, einkauf_je_brief = 1.60;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role','authenticated')::text, true);
  PERFORM set_config('role','authenticated', true);

  v_erg := public.post_kontingent_kaufen(10);
  IF (v_erg->>'gekauft')::int <> 10 OR (v_erg->>'betrag')::numeric <> 22.00 THEN
    RAISE EXCEPTION 'Der Kauf rechnet falsch: %', v_erg;
  END IF;
  IF (v_erg->>'rechnungsnummer') IS NULL THEN
    RAISE EXCEPTION 'Zum Kauf entstand keine Rechnung -- das waere ein Geschenk.';
  END IF;

  PERFORM set_config('role','postgres', true);
  PERFORM set_config('request.jwt.claims', NULL, true);

  -- Verbrauch: ein Brief senkt den Stand um genau eins, zweimal nicht.
  INSERT INTO public.payments (id,"tenantId",amount,currency,status,method,"invoiceNumber")
  VALUES (v_zahlung, v_verein, 40, 'CHF', 'PENDING', 'QR_BILL', 'KONT-SELBSTTEST');
  INSERT INTO public.post_ausgang ("tenantId","paymentId",empfaenger,dateiname,pdf)
  VALUES (v_verein, v_zahlung, 'Selbsttest', 'a.pdf', 'JVBERi0x')
  RETURNING id INTO v_post;

  v_erg := public.post_kontingent_verbrauchen(v_post);
  IF NOT (v_erg->>'verbraucht')::boolean OR (v_erg->>'stand')::int <> 9 THEN
    RAISE EXCEPTION 'Der Verbrauch stimmt nicht: %', v_erg;
  END IF;
  v_erg := public.post_kontingent_verbrauchen(v_post);
  IF (v_erg->>'verbraucht')::boolean THEN
    RAISE EXCEPTION 'Derselbe Brief wurde zweimal abgebucht.';
  END IF;

  -- Und das Vorzeichen: ein Verbrauch mit positiver Menge muss abprallen.
  BEGIN
    INSERT INTO public.post_kontingent ("tenantId", art, menge)
    VALUES (v_verein, 'VERBRAUCH', 5);
    RAISE EXCEPTION 'Ein Verbrauch mit positiver Menge wurde angenommen -- damit '
                    'liesse sich das Guthaben durch Verbrauch erhoehen.';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  -- Aufraeumen.
  DELETE FROM public.post_kontingent WHERE "tenantId" = v_verein
     AND (("postId" = v_post) OR (art = 'KAUF' AND grund = 'Kontingent gekauft'
          AND erstellt_am > now() - interval '5 minutes'));
  DELETE FROM public.post_ausgang WHERE id = v_post;
  DELETE FROM public.accounting_journal WHERE "referenceId" = v_zahlung;
  DELETE FROM public.payments WHERE id = v_zahlung;
  DELETE FROM public.platform_invoices WHERE kind = 'POSTKONTINGENT'
     AND "createdAt" > now() - interval '5 minutes';
  DELETE FROM public.post_preise WHERE "tenantId" = v_verein AND preis_je_brief = 2.20;
  DELETE FROM public.tenant_modules WHERE "tenantId" = v_verein
     AND modul = 'POSTVERSAND' AND zustand = 'TESTPHASE';

  SELECT count(*) INTO v_nachher FROM public.post_kontingent;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Bewegung(en) hinterlassen.', v_nachher - v_vorher;
  END IF;
  SELECT count(*) INTO v_nachher FROM public.platform_invoices;
  IF v_nachher <> v_rechnungen THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Rechnung(en) hinterlassen.',
      v_nachher - v_rechnungen;
  END IF;

  RAISE NOTICE 'Postversand-Modul bereit: Kauf erzeugt Rechnung, Verbrauch nur '
               'einmal je Brief, Preis nur vom Betreiber, Einkauf nicht sichtbar.';
END $$;
