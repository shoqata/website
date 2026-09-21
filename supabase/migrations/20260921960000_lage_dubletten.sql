DO $$
DECLARE r record; v_voll text[];
BEGIN
  SELECT array_agg(id) INTO v_voll FROM public.users
   WHERE email IN ('valton.rexha_IzziI@gmail.com','qazim_dIoze@dervishi.ch','ledion_w23EC@dervishi.ch');

  RAISE NOTICE '=== Die eine Zahlung auf einer Dublette ===';
  -- Welche Spalten payments wirklich hat, statt sie zu raten: p.year gibt es
  -- nicht, und ein falscher Name bricht den ganzen Block ab.
  FOR r IN SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) AS s
             FROM information_schema.columns
            WHERE table_schema='public' AND table_name='payments' LOOP
    RAISE NOTICE '  Spalten: %', r.s;
  END LOOP;
  FOR r IN SELECT to_jsonb(p) AS j FROM public.payments p WHERE p."userId" = ANY(v_voll) LOOP
    RAISE NOTICE '  %', r.j;
  END LOOP;

  RAISE NOTICE '=== Hat die Nachbarschaft Gw8s5lNhST eine Betreuung? ===';
  FOR r IN SELECT n.id, n.name,
                  (SELECT count(*) FROM public.users u
                    WHERE u."neighborhoodId" = n.id AND u.role='NEIGHBORHOOD_MANAGER') AS betreuer,
                  (SELECT count(*) FROM public.users u
                    WHERE u."neighborhoodId" = n.id AND u.role='NEIGHBORHOOD_MANAGER'
                      AND coalesce(u."membershipStatus",'') <> 'INACTIVE') AS aktive_betreuer
             FROM public.neighborhoods n WHERE n.id IN ('Gw8s5lNhST','5KwI3rPMft') LOOP
    RAISE NOTICE '  % (%) -> Betreuer % davon aktiv %', r.name, r.id, r.betreuer, r.aktive_betreuer;
  END LOOP;

  RAISE NOTICE '=== Betreuung gesamt ===';
  FOR r IN SELECT count(*) AS nb,
                  count(*) FILTER (WHERE EXISTS (SELECT 1 FROM public.users u
                    WHERE u."neighborhoodId"=n.id AND u.role='NEIGHBORHOOD_MANAGER'
                      AND coalesce(u."membershipStatus",'')<>'INACTIVE')) AS mit_aktiver
             FROM public.neighborhoods n LOOP
    RAISE NOTICE '  % Nachbarschaften, % mit aktiver Betreuung', r.nb, r.mit_aktiver;
  END LOOP;

  RAISE NOTICE '=== Weitere Namensdubletten in koretini ===';
  FOR r IN SELECT lower(coalesce(u."firstName",'')) AS vn, lower(coalesce(u."lastName",'')) AS nn,
                  count(*) AS n, string_agg(coalesce(u.email,'(ohne)')||' ['||coalesce(u."membershipStatus",'?')||']', ' | ') AS wer
             FROM public.users u
            WHERE u."tenantId"='koretini' AND coalesce(u."firstName",'')<>'' AND coalesce(u."lastName",'')<>''
            GROUP BY 1,2 HAVING count(*) > 1 ORDER BY 3 DESC, 2 LOOP
    RAISE NOTICE '  %x % % -> %', r.n, r.vn, r.nn, r.wer;
  END LOOP;

  RAISE NOTICE '=== Telefondubletten (gleiche Nummer, verschiedene Zeilen) ===';
  FOR r IN SELECT regexp_replace(coalesce(u.phone,''),'[^0-9]','','g') AS tel, count(*) AS n,
                  string_agg(coalesce(u."displayName",u.email), ' | ') AS wer
             FROM public.users u
            WHERE u."tenantId"='koretini' AND length(regexp_replace(coalesce(u.phone,''),'[^0-9]','','g')) >= 9
            GROUP BY 1 HAVING count(*) > 1 ORDER BY 2 DESC LOOP
    RAISE NOTICE '  %x % -> %', r.n, rpad(r.tel,16), r.wer;
  END LOOP;
END $$;
