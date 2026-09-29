-- Gesamtprobe: Aufruf anlegen, Entwurf bleibt unsichtbar, veroeffentlichen,
-- Spende zuordnen, Stand steigt nach dem Bezahlen.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; r record; v_id uuid; v_n int;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;

  -- 1. Als Vereinsadministrator anlegen
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  INSERT INTO public.spendenaufrufe (id,"tenantId",titel,text,ziel_betrag,waehrung,status)
  VALUES ('probe-schule','koretini','Zwei Klassenzimmer','Bücher und Bänke für 140 Kinder.',8000,'CHF','ENTWURF');
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '1. Aufruf als Entwurf angelegt';

  -- 2. Sieht ein Besucher den Entwurf?
  PERFORM set_config('request.jwt.claims', NULL, false);
  PERFORM set_config('request.headers', json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.spendenaufrufe_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '2. Besucher sieht Entwuerfe: % (erwartet 0)', v_n;

  -- 3. Veroeffentlichen
  UPDATE public.spendenaufrufe SET status='OEFFENTLICH' WHERE id='probe-schule';
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.spendenaufrufe_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '3. nach dem Veroeffentlichen: % Aufruf(e)', v_n;

  -- 4. Spenden und zuordnen, wie es die Seite tut
  EXECUTE 'SET ROLE anon';
  SELECT * INTO r FROM public.spende_anlegen(
    250,'CHF','Probe Spenderin','ps@example.org','Weg 2','8000','Zürich','CH',NULL,NULL,false);
  v_id := r.id;
  PERFORM public.spende_aufruf_zuordnen(v_id, 'probe-schule');
  EXECUTE format('SET ROLE %I', v_back);

  EXECUTE 'SET ROLE anon';
  FOR r IN SELECT titel, gesammelt, anzahl FROM public.spendenaufrufe_oeffentlich() LOOP
    RAISE NOTICE '4. vor dem Zahlungseingang: % | gesammelt % | % Spenden', r.titel, r.gesammelt, r.anzahl;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);

  -- 5. Als bezahlt markieren
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';
  PERFORM public.spende_bezahlt(v_id, 'QR', current_date);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  EXECUTE 'SET ROLE anon';
  FOR r IN SELECT titel, gesammelt, anzahl FROM public.spendenaufrufe_oeffentlich() LOOP
    RAISE NOTICE '5. nach dem Zahlungseingang: % | gesammelt % | % Spenden', r.titel, r.gesammelt, r.anzahl;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);

  -- Aufraeumen
  DELETE FROM public.accounting_journal WHERE "referenceId" = v_id::text;
  DELETE FROM public.donations WHERE email='ps@example.org';
  DELETE FROM public.spendenaufrufe WHERE id='probe-schule';
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '6. aufgeraeumt.';
END $$;
