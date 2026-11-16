-- Offene Rechnungen ins Ausland: Euro statt CHF, E-Mail statt Brief.
--
-- Gemessen am 16.11.2026: Koretini 35 offene Rechnungen an Adressen im
-- Ausland in CHF (31 davon auf "per Post", 4 auf E-Mail), alle mit
-- E-Mail-Adresse; im Demoverein 8 auf "per Post", eine davon in CHF.
-- Pingen stellt nur in der Schweiz zu (post_nur_schweiz), und wer im
-- Ausland wohnt, zahlt in Euro (lib/rechnungsregeln.ts:waehrungFuer).
--
-- Der Betrag bleibt: die Beitragsgruppe kennt einen Betrag, keine
-- Waehrung, und neue Rechnungen ins Ausland entstehen genauso
-- (lib/erfassen.ts) -- 120 CHF werden 120 EUR, nicht umgerechnet.
--
-- "Im Ausland" heisst dasselbe wie in post_anschrift_mangel, die
-- Funktion entscheidet selbst. Ohne brauchbare E-Mail-Adresse bleibt der
-- Zustellweg, wie er ist: die Rechnung waere sonst unterwegs nirgends.
--
-- Verschickt wird nichts. Die Mails baut die Oberflaeche (Finanzen →
-- "Ausland per E-Mail"), denn PDF und Text entstehen im Browser.

DO $$
DECLARE n_waehrung int; n_weg int;
BEGIN
  CREATE TEMP TABLE ausland ON COMMIT DROP AS
  SELECT p.id,
         nullif(btrim(coalesce(CASE WHEN u.id IS NOT NULL THEN u.email
                                    ELSE p."customRecipient"->>'email' END, '')), '') AS mail
    FROM public.payments p
    LEFT JOIN public.users u ON u.id = p."userId"
   WHERE p.status = 'PENDING'
     AND public.post_anschrift_mangel(p.id) LIKE 'Die Adresse liegt im Ausland%';

  UPDATE public.payments p SET currency = 'EUR'
    FROM ausland a
   WHERE p.id = a.id AND coalesce(p.currency, 'CHF') <> 'EUR';
  GET DIAGNOSTICS n_waehrung = ROW_COUNT;

  UPDATE public.payments p SET "deliveryMethod" = 'EMAIL'
    FROM ausland a
   WHERE p.id = a.id AND a.mail ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
     AND coalesce(p."deliveryMethod", '') <> 'EMAIL';
  GET DIAGNOSTICS n_weg = ROW_COUNT;

  RAISE NOTICE 'Auf EUR gestellt: %, auf E-Mail umgestellt: %', n_waehrung, n_weg;

  IF EXISTS (SELECT 1 FROM public.payments p JOIN ausland a ON a.id = p.id
              WHERE p.currency <> 'EUR') THEN
    RAISE EXCEPTION 'Es steht noch eine offene Rechnung ins Ausland nicht in EUR';
  END IF;
END $$;
