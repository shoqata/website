-- Nachweis der Betreuungssitzung.
--
-- current_tenant() steht unter jeder einzelnen Zugriffsregel. Eine Aenderung
-- daran ohne Messung waere fahrlaessig.
--
-- Zwei Erkenntnisse aus dem ersten Anlauf sind eingearbeitet:
--   * Waehrend der Betreuung bleibt genau eine Koretini-Zeile sichtbar: die
--     eigene. Das ist gewollt -- users_select laesst die eigene Zeile
--     ausdruecklich ohne Mandantenbedingung durch, sonst koennte sich niemand
--     anmelden. Geprueft wird deshalb, dass es *nur* die eigene ist.
--   * Das einzige Mitglied mit Anmeldung hat keine E-Mail-Adresse. Der Test
--     muss damit umgehen, statt an einer NOT-NULL-Bedingung zu scheitern.

DO $$
DECLARE
  v_back   text := current_user;
  v_owner  uuid; v_mail text;
  v_member uuid; v_member_mail text;
  v_probe  text; v_cnt int; v_fremd int; v_new text; v_err text;
BEGIN
  SELECT u."authUserId", u.email INTO v_owner, v_mail
    FROM public.users u JOIN public.platform_admins pa ON lower(pa.email)=lower(u.email)
   WHERE u."authUserId" IS NOT NULL LIMIT 1;
  IF v_owner IS NULL THEN RAISE NOTICE 'NICHT PRUEFBAR: kein angemeldeter Betreiber.'; RETURN; END IF;

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_owner::text,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  SELECT public.current_tenant() INTO v_probe;
  RAISE NOTICE '1 ohne Betreuung arbeitet der Betreiber in: % -- erwartet koretini', v_probe;

  BEGIN
    v_new := public.create_tenant('Selbsttest Verein', 'selbsttest-verein', 'selbsttest.example', NULL);
    RAISE NOTICE '2 Verein ohne Administrator-Adresse angelegt: %', v_new;
  EXCEPTION WHEN others THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    RAISE NOTICE '2 Verein ohne Administrator-Adresse: FEHLGESCHLAGEN -- %', v_err;
    EXECUTE format('SET ROLE %I', v_back);
    RETURN;
  END;

  PERFORM public.start_tenant_support(v_new, 'Selbsttest');
  SELECT public.current_tenant() INTO v_probe;
  RAISE NOTICE '3 mit Betreuung arbeitet er in: % -- erwartet %', v_probe, v_new;

  SELECT count(*) INTO v_cnt FROM public.users WHERE "tenantId"='koretini';
  SELECT count(*) INTO v_fremd FROM public.users
   WHERE "tenantId"='koretini' AND lower(coalesce(email,'')) <> lower(v_mail);
  RAISE NOTICE '4 waehrend der Betreuung sichtbare Koretini-Zeilen: % (davon fremde: %) -- erwartet 1 / 0',
    v_cnt, v_fremd;

  SELECT count(*) INTO v_cnt FROM public.payments WHERE "tenantId"='koretini';
  RAISE NOTICE '5 waehrend der Betreuung sichtbare Koretini-Zahlungen: % -- erwartet 0', v_cnt;

  PERFORM public.end_tenant_support();
  SELECT public.current_tenant() INTO v_probe;
  SELECT count(*) INTO v_cnt FROM public.users WHERE "tenantId"='koretini';
  RAISE NOTICE '6 nach dem Beenden: Verein % mit % sichtbaren Mitgliedern', v_probe, v_cnt;

  EXECUTE format('SET ROLE %I', v_back);

  -- ------------------------------------------------- Gegenprobe: Mitglied
  SELECT u."authUserId", u.email INTO v_member, v_member_mail
    FROM public.users u
   WHERE u.role='MEMBER' AND u."authUserId" IS NOT NULL AND u."tenantId"='koretini'
     AND u.email IS NOT NULL AND btrim(u.email) <> ''
   LIMIT 1;

  IF v_member IS NULL THEN
    -- Das einzige angemeldete Mitglied hat keine Adresse. Fuer die Gegenprobe
    -- genuegt eine erfundene Kennung -- sie steht in keiner Betreiberliste,
    -- und genau darum geht es.
    SELECT u."authUserId" INTO v_member FROM public.users u
     WHERE u.role='MEMBER' AND u."authUserId" IS NOT NULL AND u."tenantId"='koretini' LIMIT 1;
    v_member_mail := 'kein-betreiber@example.invalid';
  END IF;

  IF v_member IS NULL THEN
    RAISE NOTICE '7/8 Gegenprobe: kein angemeldetes Mitglied vorhanden.';
  ELSE
    -- Ein Eintrag wird von aussen gesetzt, so als haette ihn jemand untergeschoben.
    INSERT INTO public.platform_support (email, "tenantId", reason)
    VALUES (lower(v_member_mail), v_new, 'Untergeschobener Eintrag');

    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',v_member::text,'role','authenticated','email',v_member_mail)::text, false);
    EXECUTE 'SET ROLE authenticated';

    BEGIN
      PERFORM public.start_tenant_support(v_new, 'Versuch');
      RAISE NOTICE '7 Mitglied startet Betreuung: DURCHGELASSEN -- schwerer Fehler';
    EXCEPTION WHEN others THEN
      RAISE NOTICE '7 Mitglied startet Betreuung: abgewiesen, richtig';
    END;

    SELECT public.current_tenant() INTO v_probe;
    RAISE NOTICE '8 Mitglied mit untergeschobenem Eintrag arbeitet in: % -- erwartet koretini', v_probe;

    EXECUTE format('SET ROLE %I', v_back);
  END IF;

  PERFORM set_config('request.jwt.claims', NULL, false);

  DELETE FROM public.platform_support WHERE reason IN ('Untergeschobener Eintrag','Selbsttest') OR "tenantId" = v_new;
  DELETE FROM public.tenant_domains WHERE "tenantId" = v_new;
  DELETE FROM public.tenants        WHERE id = v_new;
  RAISE NOTICE 'Testverein entfernt.';
END $$;
