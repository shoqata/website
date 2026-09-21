-- Der Kontenplan gehoert je Verein, nicht der ganzen Plattform.
--
-- accounting_accounts.code war vereinsuebergreifend eindeutig, und
-- accounting_journal.debitCode/creditCode verwiesen darauf ohne Verein.
-- Das funktioniert nur, solange es genau einen Verein gibt: ein zweiter
-- koennte kein Konto 1020 anlegen, weil Koretini es schon hat.
-- Aufgefallen beim Einrichten eines Probevereins, der genau daran
-- scheiterte.
--
-- 1020 heisst bei jedem Verein "Bankguthaben", und jeder braucht es. Also
-- wird die Eindeutigkeit vereinsbezogen, und die vier Fremdschluessel
-- werden zusammengesetzt.
--
-- Vorher geprueft: 0 Buchungen und 0 Ausgaben verweisen auf ein Konto
-- eines anderen Vereins, 0 ohne Vereinszuordnung.

ALTER TABLE public.accounting_journal
  DROP CONSTRAINT IF EXISTS "accounting_journal_debitCode_fkey",
  DROP CONSTRAINT IF EXISTS "accounting_journal_creditCode_fkey";
ALTER TABLE public.expenses
  DROP CONSTRAINT IF EXISTS "expenses_categoryAccountCode_fkey",
  DROP CONSTRAINT IF EXISTS "expenses_paymentAccountCode_fkey";

ALTER TABLE public.accounting_accounts
  DROP CONSTRAINT IF EXISTS accounting_accounts_code_key;
DROP INDEX IF EXISTS public.accounting_accounts_code_key;

CREATE UNIQUE INDEX IF NOT EXISTS accounting_accounts_code_je_verein
  ON public.accounting_accounts ("tenantId", code);

ALTER TABLE public.accounting_journal
  ADD CONSTRAINT accounting_journal_soll_fkey
    FOREIGN KEY ("tenantId", "debitCode")
    REFERENCES public.accounting_accounts ("tenantId", code)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  ADD CONSTRAINT accounting_journal_haben_fkey
    FOREIGN KEY ("tenantId", "creditCode")
    REFERENCES public.accounting_accounts ("tenantId", code)
    ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE public.expenses
  ADD CONSTRAINT expenses_aufwandkonto_fkey
    FOREIGN KEY ("tenantId", "categoryAccountCode")
    REFERENCES public.accounting_accounts ("tenantId", code)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  ADD CONSTRAINT expenses_zahlkonto_fkey
    FOREIGN KEY ("tenantId", "paymentAccountCode")
    REFERENCES public.accounting_accounts ("tenantId", code)
    ON UPDATE CASCADE ON DELETE RESTRICT;

DO $$
DECLARE r record; v_n int;
BEGIN
  RAISE NOTICE 'Neue Bezuege:';
  FOR r IN SELECT c.conname, pg_get_constraintdef(c.oid) AS def
             FROM pg_constraint c
            WHERE c.confrelid='public.accounting_accounts'::regclass ORDER BY 1 LOOP
    RAISE NOTICE '  % : %', rpad(r.conname,36), left(r.def, 70);
  END LOOP;
  SELECT count(*) INTO v_n FROM public.accounting_journal;
  RAISE NOTICE 'Journal unveraendert: % Buchungen ueber % CHF', v_n,
    (SELECT coalesce(sum(amount),0) FROM public.accounting_journal);
  RAISE NOTICE 'Konten bei Koretini: %',
    (SELECT count(*) FROM public.accounting_accounts WHERE "tenantId"='koretini');
END $$;
