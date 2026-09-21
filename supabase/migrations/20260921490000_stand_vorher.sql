-- Buchhalterischer Stand VOR dem Nachtragen der Referenznummern.
-- Festgehalten, damit sich hinterher beweisen laesst, dass nichts verrutscht
-- ist -- und nicht nur behaupten.
CREATE TABLE IF NOT EXISTS public.pruefstand_referenzen (
  was      text PRIMARY KEY,
  wert     numeric,
  erfasst  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.pruefstand_referenzen ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pruefstand_referenzen FROM anon, authenticated;

INSERT INTO public.pruefstand_referenzen (was, wert) VALUES
  ('rechnungen_gesamt',   (SELECT count(*) FROM public.payments)),
  ('rechnungen_bezahlt',  (SELECT count(*) FROM public.payments WHERE status='PAID')),
  ('rechnungen_offen',    (SELECT count(*) FROM public.payments WHERE status='PENDING')),
  ('summe_alle',          (SELECT coalesce(sum(amount),0) FROM public.payments)),
  ('summe_bezahlt',       (SELECT coalesce(sum(amount),0) FROM public.payments WHERE status='PAID')),
  ('journal_zeilen',      (SELECT count(*) FROM public.accounting_journal)),
  ('journal_summe',       (SELECT coalesce(sum(amount),0) FROM public.accounting_journal)),
  ('mit_referenz',        (SELECT count(*) FROM public.payments WHERE coalesce(btrim(reference),'')<>''))
ON CONFLICT (was) DO UPDATE SET wert = excluded.wert, erfasst = now();

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT was, wert FROM public.pruefstand_referenzen ORDER BY was LOOP
    RAISE NOTICE '  % : %', rpad(r.was, 20), r.wert;
  END LOOP;
END $$;
