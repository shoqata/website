-- Die zweite Vereinszeile stammt aus der Firebase-Migration und ist leer:
-- 0 Mitglieder, 0 Zahlungen, 0 Nachbarschaften, 0 Events, 0 Einstellungen und
-- keine Domain. Sie taucht nur in der Vereinsverwaltung auf und verwirrt dort.
-- Vor dem Loeschen wird die Leere noch einmal geprueft -- nicht aus dem
-- Gedaechtnis loeschen.
DO $$
DECLARE v_id text := 'b29gMh83LaLB17YvmktX'; v int; v_total int := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = v_id) THEN
    RAISE NOTICE 'Zeile % gibt es nicht (mehr) -- nichts zu tun.', v_id;
    RETURN;
  END IF;

  SELECT count(*) INTO v FROM public.users WHERE "tenantId"=v_id;            v_total := v_total + v;
  SELECT count(*) INTO v FROM public.payments WHERE "tenantId"=v_id;         v_total := v_total + v;
  SELECT count(*) INTO v FROM public.neighborhoods WHERE "tenantId"=v_id;    v_total := v_total + v;
  SELECT count(*) INTO v FROM public.events WHERE "tenantId"=v_id;           v_total := v_total + v;
  SELECT count(*) INTO v FROM public.news WHERE "tenantId"=v_id;             v_total := v_total + v;
  SELECT count(*) INTO v FROM public.settings WHERE "tenantId"=v_id;         v_total := v_total + v;
  SELECT count(*) INTO v FROM public.tenant_domains WHERE "tenantId"=v_id;   v_total := v_total + v;

  IF v_total > 0 THEN
    RAISE NOTICE 'ABBRUCH: an % haengen noch % Datensaetze. Nicht geloescht.', v_id, v_total;
    RETURN;
  END IF;

  DELETE FROM public.tenants WHERE id = v_id;
  RAISE NOTICE 'Leere Vereinszeile % entfernt.', v_id;
END $$;
