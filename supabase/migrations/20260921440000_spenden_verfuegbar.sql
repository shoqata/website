-- Das Spendenmodul ist gebaut: oeffentliche Seite, Referenznummer,
-- Einzahlungsschein, Verbuchung, Bescheinigung. Damit darf es aus
-- EINGESTELLT heraus.
UPDATE public.modules
   SET status = 'VERFUEGBAR',
       beschreibung_de = 'Öffentliche Spendenseite mit Einzahlungsschein, automatischer Zuordnung über die Referenznummer, Verbuchung und Spendenbescheinigung.',
       beschreibung_sq = 'Faqe publike donacionesh me fletëpagesë, njohje automatike përmes numrit të referencës, kontabilizim dhe vërtetim donacioni.',
       beschreibung_en = 'Public donation page with payment slip, automatic reconciliation via the reference number, booking and donation receipt.'
 WHERE schluessel = 'SPENDEN';

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schluessel, name_de, status FROM public.modules
            WHERE status <> 'VERFUEGBAR' OR schluessel='SPENDEN' ORDER BY reihenfolge LOOP
    RAISE NOTICE '  % | % | %', rpad(r.schluessel,12), rpad(r.name_de,26), r.status;
  END LOOP;
END $$;
