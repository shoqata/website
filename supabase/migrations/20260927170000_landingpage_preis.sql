-- Preis auf Entscheid des Betreibers: 5.00 im Monat statt 15.00. Die 15.00
-- waren ein Platzhalter von mir, keine Vorgabe.
UPDATE public.modules SET preis_monat = 5.00 WHERE schluessel = 'LANDINGPAGE';

DO $$
DECLARE r record; v_back text := current_user; v_uid text; v_mail text;
BEGIN
  FOR r IN SELECT schluessel, name_de, preis_monat FROM public.modules
            WHERE coalesce(preis_monat,0) > 0 ORDER BY reihenfolge LOOP
    RAISE NOTICE '  % | % | % im Monat, % im Jahr',
      rpad(r.schluessel,14), rpad(r.name_de,22), r.preis_monat, round(r.preis_monat*12, 2);
  END LOOP;

  -- Gegenprobe an einem Verein, der es gebucht haette.
  SELECT pa.email INTO v_mail FROM public.platform_admins pa LIMIT 1;
  SELECT u."authUserId" INTO v_uid FROM public.users u WHERE lower(u.email)=lower(v_mail) LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  RAISE NOTICE '  Koretini: %', public.jahresrechnung_betrag('koretini');
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);
END $$;
