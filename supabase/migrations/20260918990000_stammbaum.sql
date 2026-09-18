-- Stammbaum der Familien.
--
-- Vorhanden war nur "familyId", ein freies Textfeld zum Gruppieren -- und
-- gemessen bei 0 von 348 Mitgliedern gefuellt, also tot. Es sagt ausserdem
-- nichts ueber Verwandtschaft: wer Elternteil, Kind oder Partner von wem ist,
-- laesst sich aus einer gemeinsamen Kennung nicht ableiten.
--
-- Deshalb eine eigene Tabelle fuer Beziehungen. Zwei Arten genuegen fuer
-- einen Stammbaum:
--   ELTERNTEIL  -- "von" ist Elternteil von "nach" (gerichtet)
--   PARTNER     -- Ehe oder Partnerschaft (ungerichtet, einmal gespeichert)
-- Geschwister werden nicht gespeichert, sondern ergeben sich: zwei Personen
-- mit demselben Elternteil. Eine eigene Geschwister-Beziehung waere eine
-- zweite Wahrheit, die mit der ersten auseinanderlaufen kann.

CREATE TABLE IF NOT EXISTS public.family_links (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"  text NOT NULL,
  von         text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  nach        text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  art         text NOT NULL,
  notiz       text,
  erfasst_am  timestamptz NOT NULL DEFAULT now(),
  erfasst_von text,
  CONSTRAINT family_links_art_gueltig CHECK (art IN ('ELTERNTEIL','PARTNER')),
  -- Niemand ist mit sich selbst verwandt.
  CONSTRAINT family_links_nicht_selbst CHECK (von <> nach)
);

-- Dieselbe Beziehung nicht zweimal. Bei PARTNER zaehlt auch die umgekehrte
-- Richtung als dieselbe -- deshalb wird zusaetzlich ueber das geordnete Paar
-- eindeutig gemacht.
CREATE UNIQUE INDEX IF NOT EXISTS family_links_einmalig
  ON public.family_links (von, nach, art);
CREATE UNIQUE INDEX IF NOT EXISTS family_links_partner_einmalig
  ON public.family_links (least(von, nach), greatest(von, nach))
  WHERE art = 'PARTNER';

CREATE INDEX IF NOT EXISTS family_links_von_idx  ON public.family_links (von);
CREATE INDEX IF NOT EXISTS family_links_nach_idx ON public.family_links (nach);

ALTER TABLE public.family_links ENABLE ROW LEVEL SECURITY;

-- Lesen: wer die Mitglieder des Vereins sehen darf, darf auch die
-- Verwandtschaft sehen. Das ist die Verwaltung und die verantwortliche
-- Person einer Nachbarschaft -- dieselbe Grenze wie bei den Mitgliedsdaten
-- selbst, sonst waere ueber die Verwandtschaft ableitbar, wer dazugehoert.
CREATE POLICY family_links_lesen ON public.family_links
  FOR SELECT TO authenticated
  USING (
    "tenantId" = public.current_tenant()
    AND (public.is_member_manager() OR public.is_neighborhood_steward())
  );

-- Schreiben: nur die Verwaltung. Eine verantwortliche Person darf Adressen
-- pflegen, aber keine Abstammung festlegen.
CREATE POLICY family_links_schreiben ON public.family_links
  FOR ALL TO authenticated
  USING ("tenantId" = public.current_tenant() AND public.is_member_manager())
  WITH CHECK ("tenantId" = public.current_tenant() AND public.is_member_manager());

-- Beide Personen muessen zum selben Verein gehoeren wie die Beziehung.
CREATE OR REPLACE FUNCTION public.family_links_pruefen()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_a text; v_b text;
BEGIN
  SELECT "tenantId" INTO v_a FROM public.users WHERE id = NEW.von;
  SELECT "tenantId" INTO v_b FROM public.users WHERE id = NEW.nach;
  IF v_a IS NULL OR v_b IS NULL THEN
    RAISE EXCEPTION 'Mindestens eine der beiden Personen gibt es nicht.';
  END IF;
  IF v_a <> v_b OR v_a <> NEW."tenantId" THEN
    RAISE EXCEPTION 'Beide Personen muessen zum selben Verein gehoeren.';
  END IF;

  -- Ein Kind kann nicht Vorfahre seines eigenen Elternteils sein. Ohne diese
  -- Pruefung liesse sich ein Kreis anlegen, an dem jede Darstellung des
  -- Baums haengen bleibt.
  IF NEW.art = 'ELTERNTEIL' THEN
    IF EXISTS (
      WITH RECURSIVE vorfahren(person) AS (
        SELECT NEW.von
        UNION
        SELECT f.von FROM public.family_links f
          JOIN vorfahren v ON f.nach = v.person
         WHERE f.art = 'ELTERNTEIL'
      )
      SELECT 1 FROM vorfahren WHERE person = NEW.nach
    ) THEN
      RAISE EXCEPTION 'Das ergaebe einen Kreis: % ist bereits Vorfahre von %.',
        NEW.nach, NEW.von;
    END IF;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS family_links_pruefen_trg ON public.family_links;
CREATE TRIGGER family_links_pruefen_trg
  BEFORE INSERT OR UPDATE ON public.family_links
  FOR EACH ROW EXECUTE FUNCTION public.family_links_pruefen();

DO $$ BEGIN RAISE NOTICE 'Tabelle family_links angelegt.'; END $$;
