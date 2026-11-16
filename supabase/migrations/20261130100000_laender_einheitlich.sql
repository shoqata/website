-- Laender einheitlich schreiben, wie die Auswahl (lib/countries.ts).
--
-- Gemessen am 16.11.2026 ueber alle Vereine: Schweiz 278, Switzerland 2,
-- CH 1, Kosovo 6, XK 9, Holland 1. lib/erfassen.zahlungsart verglich mit
-- 'Switzerland' -- wer "Schweiz" hatte, bekam beim Erfassen eine
-- Ueberweisung statt einer QR-Rechnung. Der Code erkennt jetzt alle
-- Schreibweisen (wohnsitz); hier wird der Bestand angeglichen, damit
-- Auswertungen und Filter nicht drei Schweizen zaehlen.
--
-- Leere Laender bleiben leer: "unbekannt" ist eine Aussage, und aus ihr
-- die Schweiz zu machen, waere geraten (ein Brief nach Wels hat gezeigt,
-- wohin das fuehrt).

DO $$
DECLARE n_land int; n_weg int;
BEGIN
  UPDATE public.users SET country = CASE
      WHEN lower(btrim(country)) IN ('switzerland','ch','che','suisse','svizzera','zvicer','zvicër') THEN 'Schweiz'
      WHEN lower(btrim(country)) IN ('xk','kosova','kosovë') THEN 'Kosovo'
      WHEN lower(btrim(country)) IN ('holland','netherlands','nl') THEN 'Niederlande'
      WHEN lower(btrim(country)) IN ('germany','de') THEN 'Deutschland'
      WHEN lower(btrim(country)) IN ('austria','at','oesterreich') THEN 'Österreich'
    END
   WHERE lower(btrim(country)) IN ('switzerland','ch','che','suisse','svizzera','zvicer','zvicër',
                                   'xk','kosova','kosovë','holland','netherlands','nl',
                                   'germany','de','austria','at','oesterreich');
  GET DIAGNOSTICS n_land = ROW_COUNT;

  -- Offene Rechnungen an Mitglieder in der Schweiz, die wegen des alten
  -- Vergleichs als Ueberweisung erfasst wurden. PDF und Mail entscheiden
  -- schon nach dem Land; die Vorschau und die Liste nach dieser Spalte.
  UPDATE public.payments p SET method = 'QR_BILL'
    FROM public.users u
   WHERE u.id = p."userId" AND p.status = 'PENDING'
     AND p.method = 'BANK_TRANSFER' AND u.country = 'Schweiz';
  GET DIAGNOSTICS n_weg = ROW_COUNT;

  RAISE NOTICE 'Laender angeglichen: %, Rechnungen auf QR: %', n_land, n_weg;

  IF EXISTS (SELECT 1 FROM public.users
              WHERE lower(btrim(country)) IN ('switzerland','ch','xk','holland')) THEN
    RAISE EXCEPTION 'Es steht noch eine alte Schreibweise im Bestand';
  END IF;
END $$;
