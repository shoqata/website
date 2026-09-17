-- Zaehlt die Vorstandsansicht das richtige Jahr?
--
-- Sie filtert ueber p.timestamp.toDate().getFullYear(). Die Bruecke wandelt
-- eine Zeichenkette nur dann in ein Datum, wenn sie dem Muster
-- YYYY-MM-DDTHH:MM:SS entspricht -- sonst bleibt sie Text, und .toDate() gibt
-- es darauf nicht. Zugleich fuehren die Zahlungen ein eigenes Feld
-- billingYear, das die Rechnungsansicht ohnehin verwendet.
DO $$
DECLARE
  v_jahr int := EXTRACT(YEAR FROM current_date)::int;
  v_typ text; v_leer int; v_ohne_t int; v_ges int;
  v_nach_ts int; v_nach_by int; r record;
BEGIN
  SELECT data_type INTO v_typ FROM information_schema.columns
   WHERE table_schema='public' AND table_name='payments' AND column_name='timestamp';
  RAISE NOTICE 'Spalte timestamp ist vom Typ %', v_typ;

  SELECT count(*) INTO v_ges FROM public.payments;
  SELECT count(*) INTO v_leer FROM public.payments WHERE "timestamp" IS NULL;
  RAISE NOTICE 'Zahlungen %, davon ohne timestamp %', v_ges, v_leer;

  -- Zeichenketten ohne Uhrzeit: die Bruecke laesst sie als Text stehen, und
  -- .toDate() wuerde darauf einen Fehler werfen.
  IF v_typ = 'text' THEN
    SELECT count(*) INTO v_ohne_t FROM public.payments
     WHERE "timestamp" IS NOT NULL
       AND "timestamp"::text !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}';
    RAISE NOTICE 'timestamp ohne Uhrzeit-Muster: % -- darauf gibt es kein .toDate()', v_ohne_t;
    FOR r IN SELECT DISTINCT left("timestamp"::text, 24) AS bsp FROM public.payments
              WHERE "timestamp" IS NOT NULL LIMIT 4 LOOP
      RAISE NOTICE '  Beispiel: %', r.bsp;
    END LOOP;
  END IF;

  -- Der eigentliche Vergleich: wie viele Zahlungen zaehlt das Jahr nach dem
  -- einen und nach dem anderen Weg?
  SELECT count(*) INTO v_nach_ts FROM public.payments
   WHERE "timestamp" IS NOT NULL
     AND EXTRACT(YEAR FROM "timestamp"::timestamptz)::int = v_jahr;
  SELECT count(*) INTO v_nach_by FROM public.payments
   WHERE "billingYear" IS NOT NULL AND "billingYear"::int = v_jahr;

  RAISE NOTICE 'Jahr %: ueber timestamp %, ueber billingYear %', v_jahr, v_nach_ts, v_nach_by;

  SELECT count(*) INTO v_nach_ts FROM public.payments
   WHERE "timestamp" IS NOT NULL AND EXTRACT(YEAR FROM "timestamp"::timestamptz)::int = v_jahr
     AND status = 'PAID';
  SELECT count(*) INTO v_nach_by FROM public.payments
   WHERE "billingYear" IS NOT NULL AND "billingYear"::int = v_jahr AND status = 'PAID';
  RAISE NOTICE 'Davon bezahlt: ueber timestamp %, ueber billingYear %', v_nach_ts, v_nach_by;
END $$;
