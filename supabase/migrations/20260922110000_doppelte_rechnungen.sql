-- Nach dem Zusammenfuehren tragen drei Mitglieder zwei Rechnungen fuer 2026.
-- Jede Stornierung braucht ihre eigene Gegenbuchung, und die faellt nicht
-- ueberall gleich aus:
--
--   INV-18024170  Ibrahim Canaj    offen, nur als Forderung gebucht
--   INV-18026250  Perparim Haxhiu  offen, nur als Forderung gebucht
--       -> 3000 an 1100: Forderung und Ertrag fallen weg.
--
--   INV-18024137  Fatos Selmani    bezahlt am 05.07.2026, Geld ist eingegangen
--       -> 3000 an 2000: der Ertrag faellt weg, das Geld bleibt auf der Bank
--          und steht ab jetzt als Verbindlichkeit gegenueber dem Mitglied.
--          Die Bank wird NICHT angefasst -- ein Kontoauszug laesst sich nicht
--          nachtraeglich aendern. Sollten die CHF 120 am 05.07. in Wahrheit
--          nie eingegangen sein, lautet die Gegenbuchung 3000 an 1020.
DO $$
DECLARE
  r record; v_id text; v_status text; v_eingang int; v_n int;
  v_storno text[] := ARRAY['INV-18024170','INV-18026250','INV-18024137'];
  v_nr text;
BEGIN
  FOREACH v_nr IN ARRAY v_storno LOOP
    SELECT id, status INTO v_id, v_status FROM public.payments
     WHERE "tenantId"='koretini' AND "invoiceNumber"=v_nr;
    IF v_id IS NULL THEN RAISE EXCEPTION 'Rechnung % nicht gefunden.', v_nr; END IF;
    IF v_status = 'CANCELLED' THEN
      RAISE NOTICE '  % ist schon storniert.', v_nr; CONTINUE;
    END IF;

    SELECT count(*) INTO v_eingang FROM public.accounting_journal
     WHERE "referenceId"=v_id AND "creditCode"='1100';

    INSERT INTO public.accounting_journal
      (id,"tenantId",date,"debitCode","creditCode",amount,description,"referenceId","isSystemEntry",timestamp,"createdAt")
    SELECT gen_random_uuid()::text, 'koretini', current_date, '3000',
           CASE WHEN v_eingang > 0 THEN '2000' ELSE '1100' END,
           p.amount,
           'Storno ' || v_nr || ' -- doppelte Rechnung 2026' ||
           CASE WHEN v_eingang > 0
                THEN '; eingegangener Betrag bleibt als Guthaben des Mitglieds stehen'
                ELSE '' END,
           v_id, false, now(), now()
      FROM public.payments p WHERE p.id = v_id;

    UPDATE public.payments
       SET status='CANCELLED',
           description = coalesce(description,'') || ' -- am 21.09.2026 storniert: doppelte Rechnung 2026'
     WHERE id = v_id;

    RAISE NOTICE '  % storniert, Gegenbuchung 3000 an %',
      v_nr, CASE WHEN v_eingang > 0 THEN '2000 (Geld war eingegangen)' ELSE '1100' END;
  END LOOP;

  RAISE NOTICE '--- Hat noch jemand zwei Rechnungen fuer dasselbe Jahr? ---';
  FOR r IN SELECT coalesce(u."displayName",u.email) AS wer, p."billingYear", count(*) AS n,
                  string_agg(p."invoiceNumber"||' ('||p.status||')', ', ') AS welche
             FROM public.payments p JOIN public.users u ON u.id=p."userId"
            WHERE p."tenantId"='koretini' AND p.status <> 'CANCELLED'
            GROUP BY 1,2 HAVING count(*) > 1 LOOP
    RAISE NOTICE '  % / % -> %', r.wer, r."billingYear", r.welche;
  END LOOP;

  SELECT count(*) INTO v_n FROM public.payments WHERE "tenantId"='koretini' AND status='PENDING';
  RAISE NOTICE '--- offene Rechnungen: % ---', v_n;
  FOR r IN SELECT k.code,
             (SELECT coalesce(sum(amount),0) FROM public.accounting_journal
               WHERE "tenantId"='koretini' AND "debitCode"=k.code) -
             (SELECT coalesce(sum(amount),0) FROM public.accounting_journal
               WHERE "tenantId"='koretini' AND "creditCode"=k.code) AS saldo
             FROM (VALUES ('1020'),('1100'),('2000'),('3000')) AS k(code) LOOP
    RAISE NOTICE '  Konto % Saldo %', r.code, r.saldo;
  END LOOP;
END $$;
