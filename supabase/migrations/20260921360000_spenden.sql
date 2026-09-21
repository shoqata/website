-- Stufe 3: das Spendenmodul.
--
-- Bewusst eine eigene Tabelle statt einer Zeile in payments. Dort haengen
-- Mitgliedsnummer, Mahnstufen und Beitragsjahr; eine Spende hat davon
-- nichts, und sie wuerde die Zahlquote und das Mahnwesen verfaelschen --
-- beides rechnet ueber payments je Mitglied.
--
-- Ein Spender ist nicht zwingend Mitglied. Name und Adresse werden nur
-- erhoben, weil eine Spendenbescheinigung sie verlangt; wer keine will,
-- gibt sie nicht an.

CREATE TABLE IF NOT EXISTS public.donations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"      text NOT NULL,
  betrag          numeric(10,2) NOT NULL CHECK (betrag > 0),
  waehrung        text NOT NULL DEFAULT 'CHF' CHECK (waehrung IN ('CHF','EUR')),
  -- Der Spender. Alles freiwillig ausser dem, was eine Bescheinigung braucht.
  name            text,
  email           text,
  strasse         text,
  plz             text,
  ort             text,
  land            text,
  -- Wer anonym spenden will, soll das koennen; dann gibt es aber auch keine
  -- Bescheinigung, weil sie auf einen Namen lauten muss.
  anonym          boolean NOT NULL DEFAULT false,
  nachricht       text,
  zweck           text,
  -- Die Referenznummer der QR-Rechnung. Ueber sie ordnet sich eine
  -- eingehende Zahlung von selbst zu -- derselbe Mechanismus wie bei den
  -- Mitgliederbeitraegen.
  referenz        text,
  status          text NOT NULL DEFAULT 'OFFEN'
                  CHECK (status IN ('OFFEN','BEZAHLT','STORNIERT')),
  weg             text CHECK (weg IN ('QR','TWINT','PAYPAL','BAR','UEBERWEISUNG')),
  "userId"        text REFERENCES public.users(id) ON DELETE SET NULL,
  eingegangen_am  date,
  bescheinigt_am  timestamptz,
  gebucht         boolean NOT NULL DEFAULT false,
  erfasst_am      timestamptz NOT NULL DEFAULT now(),
  erfasst_von     text
);
CREATE INDEX IF NOT EXISTS donations_verein_idx ON public.donations ("tenantId", status);
CREATE UNIQUE INDEX IF NOT EXISTS donations_referenz_idx
  ON public.donations (referenz) WHERE referenz IS NOT NULL;

ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.donations FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.donations TO authenticated;

-- Lesen und aendern nur die Vereinsverwaltung, und nur bei gebuchtem Modul.
-- Anonyme Spender legen ueber eine Funktion an, nicht ueber die Tabelle --
-- sonst koennte jeder fremde Spenden einsehen oder faelschen.
CREATE POLICY donations_verwaltung ON public.donations
  FOR ALL TO authenticated
  USING ("tenantId" = public.current_tenant()
         AND public.is_member_manager()
         AND public.modul_aktiv('SPENDEN'))
  WITH CHECK ("tenantId" = public.current_tenant()
         AND public.is_member_manager()
         AND public.modul_aktiv('SPENDEN'));

-- Ein Mitglied sieht die eigenen Spenden -- es braucht sie fuer die
-- Steuererklaerung.
CREATE POLICY donations_eigene ON public.donations
  FOR SELECT TO authenticated
  USING ("userId" = public.current_user_row_id() AND public.modul_aktiv('SPENDEN'));

DO $$ BEGIN RAISE NOTICE 'Tabelle donations angelegt.'; END $$;
