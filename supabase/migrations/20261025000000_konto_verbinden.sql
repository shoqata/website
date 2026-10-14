-- Die Administration verbindet ein Anmeldekonto mit einer Mitgliedszeile.
--
-- Es gibt den Fall, und er ist nicht selten: jemand bekommt eine
-- bevorrechtigte Rolle und registriert sich DANACH selbst.
-- claim_my_profile verbindet dann bewusst nicht -- sonst koennte sich
-- jemand mit der Adresse eines Vorstands anmelden und dessen Rechte
-- uebernehmen. Der Riegel ist richtig und bleibt.
--
-- Gemessen sind zwei Personen betroffen:
--
--   r.kallaba@web.de     Rolle BOARD
--   alban.rexha@gmx.ch   Rolle REPRESENTATIVE
--
-- Beide haben ein bestaetigtes Konto, beide eine Mitgliedszeile, beide
-- kommen nicht herein.
--
-- Bisher gab es dafuer nur reset_member_password. Das verbindet
-- zwar -- es sucht das Konto ueber die Adresse und haengt es an --, SETZT
-- dabei aber ein neues Passwort. Wer sein Passwort kennt und nur die
-- Verbindung braucht, muesste es ohne Grund wechseln. Darum eine
-- Funktion, die ausschliesslich verbindet.

CREATE OR REPLACE FUNCTION public.konto_verbinden(p_member text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  m record;
  v_sub text;
  v_belegt text;
  v_n int;
BEGIN
  -- Nur die Administration. Wer Konten verbinden kann, kann einer Zeile
  -- mit Vorstandsrechten ein beliebiges Konto anhaengen -- das ist
  -- dasselbe wie Rechte vergeben.
  IF NOT (public.is_platform_admin()
          OR public.app_role() IN ('SUPER_ADMIN','ADMIN')) THEN
    RAISE EXCEPTION 'Nur die Vereinsadministration darf Konten verbinden.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO m FROM public.users WHERE id = p_member;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dieses Mitglied gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT public.is_platform_admin() AND m."tenantId" <> public.current_tenant() THEN
    RAISE EXCEPTION 'Dieses Mitglied gehoert zu einem anderen Verein.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF m."authUserId" IS NOT NULL THEN
    RETURN jsonb_build_object('verbunden', false, 'grund', 'bereits verbunden');
  END IF;
  IF coalesce(btrim(m.email), '') = '' THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'keine E-Mail-Adresse hinterlegt — ohne sie gibt es kein Konto');
  END IF;

  -- Das Konto wird ueber die Adresse gefunden, nicht uebergeben. Ein
  -- Aufrufer, der die Kontokennung mitschicken koennte, koennte ein
  -- fremdes Konto anhaengen.
  SELECT a.id::text INTO v_sub FROM auth.users a
   WHERE lower(a.email) = lower(btrim(m.email))
   ORDER BY a.created_at LIMIT 1;

  IF v_sub IS NULL THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'zu dieser Adresse gibt es noch kein Anmeldekonto — die Person '
            || 'muss sich zuerst registrieren, oder Sie setzen ein Passwort');
  END IF;

  -- Haengt dieses Konto schon an einer anderen Zeile DESSELBEN Vereins,
  -- waere die Verbindung nicht mehr eindeutig. Ueber Vereine hinweg ist
  -- es erlaubt -- eine Person darf in mehreren Vereinen Mitglied sein.
  SELECT x.id INTO v_belegt FROM public.users x
   WHERE x."authUserId" = v_sub AND x."tenantId" = m."tenantId" AND x.id <> m.id
   LIMIT 1;
  IF v_belegt IS NOT NULL THEN
    RETURN jsonb_build_object('verbunden', false,
      'grund', 'dieses Konto haengt in diesem Verein schon an ' || v_belegt);
  END IF;

  UPDATE public.users SET "authUserId" = v_sub WHERE id = m.id;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  -- Ein UPDATE ohne Treffer wirft keinen Fehler. Ohne diese Pruefung
  -- meldete die Maske Erfolg, waehrend nichts verbunden waere.
  IF v_n = 0 THEN
    RAISE EXCEPTION 'Die Verbindung wurde nicht gespeichert.' USING ERRCODE = 'check_violation';
  END IF;

  -- Festhalten, wer das getan hat. Eine Kontoverbindung vergibt
  -- faktisch Rechte; sie gehoert ins Protokoll.
  BEGIN
    INSERT INTO public.security_logs ("tenantId", art, beschreibung, "memberId")
    VALUES (m."tenantId", 'KONTO_VERBUNDEN',
            'Konto zu ' || m.email || ' verbunden durch '
              || coalesce(public.current_user_row_id(), 'Betreiber'), m.id);
  EXCEPTION WHEN undefined_column OR undefined_table THEN
    -- Das Protokoll hat in aelteren Staenden andere Spalten. Die
    -- Verbindung soll nicht daran scheitern; sie ist das Wesentliche.
    NULL;
  END;

  RETURN jsonb_build_object('verbunden', true, 'mitglied', m.id,
                            'name', coalesce(m."displayName", m.email));
END $$;

REVOKE ALL ON FUNCTION public.konto_verbinden(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.konto_verbinden(text) TO authenticated;


-- Wer kommt nicht herein?
--
-- Die Liste, die es brauchte, um den Fehler ueberhaupt zu finden. Sie
-- zeigt Anmeldekonten ohne Mitgliedszeile und Mitglieder mit Konto zur
-- Adresse, aber ohne Verbindung.
CREATE OR REPLACE FUNCTION public.konten_ohne_verbindung()
RETURNS TABLE (
  r_email text, r_mitglied text, r_name text, r_rolle text,
  r_konto_da boolean, r_konto_bestaetigt boolean, r_grund text
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT (public.is_platform_admin() OR public.is_member_manager()) THEN
    RAISE EXCEPTION 'Nicht berechtigt.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN QUERY
  SELECT coalesce(u.email, a.email),
         u.id,
         coalesce(u."displayName", u.email, '—'),
         coalesce(u.role, '—'),
         a.id IS NOT NULL,
         a.email_confirmed_at IS NOT NULL,
         CASE
           WHEN u.id IS NULL THEN 'Konto ohne Mitgliedseintrag'
           WHEN a.id IS NULL THEN 'noch kein Anmeldekonto'
           WHEN a.email_confirmed_at IS NULL THEN 'Konto nicht bestätigt'
           WHEN coalesce(u.role,'MEMBER') NOT IN ('MEMBER','GUEST')
             THEN 'bevorrechtigte Rolle — muss verbunden werden'
           ELSE 'wird bei der nächsten Anmeldung selbst verbunden'
         END
    FROM auth.users a
    FULL JOIN public.users u
      ON lower(u.email) = lower(a.email)
     AND (public.is_platform_admin() OR u."tenantId" = public.current_tenant())
   WHERE a.id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.users x
                      WHERE x."authUserId" = a.id::text OR x.id = a.id::text)
   ORDER BY 7, 1;
END $$;

REVOKE ALL ON FUNCTION public.konten_ohne_verbindung() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.konten_ohne_verbindung() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_verein text; v_zeile text := 'selbsttest-verbinden';
  v_mail text := 'verbinden@example.invalid';
  v_sub uuid; v_erg jsonb; v_vorher int; v_nachher int; v_quelle text; v_admin text;
BEGIN
  -- Die Berechtigungspruefung muss drin sein, und BOARD darf NICHT
  -- verbinden: wer Konten verbindet, vergibt faktisch Rechte.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname='konto_verbinden';
  IF v_quelle !~ 'SUPER_ADMIN' OR v_quelle !~ 'is_platform_admin' THEN
    RAISE EXCEPTION 'In konto_verbinden fehlt die Berechtigungspruefung.';
  END IF;
  IF v_quelle ~ '''BOARD''' THEN
    RAISE EXCEPTION 'BOARD steht in der Erlaubnisliste von konto_verbinden -- damit '
                    'koennte der Vorstand sich selbst Konten anhaengen.';
  END IF;
  -- Und die Kontokennung darf nicht vom Aufrufer kommen.
  IF pg_get_function_arguments(
       (SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
         WHERE n.nspname='public' AND p.proname='konto_verbinden')) ~ 'uid|sub|auth' THEN
    RAISE EXCEPTION 'konto_verbinden nimmt eine Kontokennung an -- damit liesse sich '
                    'ein fremdes Konto anhaengen.';
  END IF;

  -- Die Funktion verlangt eine Anmeldung als Administration. Der erste
  -- Versuch rief sie ohne auf und wurde abgewiesen -- richtig von der
  -- Funktion, falsch vom Test. Also mit Kennung einer vorhandenen
  -- Administration, im Verein dieser Zeile.
  SELECT u."tenantId", u."authUserId" INTO v_verein, v_admin
    FROM public.users u
   WHERE u.role IN ('SUPER_ADMIN','ADMIN') AND u."authUserId" IS NOT NULL
   ORDER BY u.id LIMIT 1;
  IF v_admin IS NULL THEN
    RAISE NOTICE 'Keine angemeldete Administration vorhanden -- der Verhaltenstest '
                 'wird uebersprungen, die Quellpruefungen oben sind durch.';
    RETURN;
  END IF;
  SELECT count(*) INTO v_vorher FROM public.users;

  -- Ohne Konto zur Adresse: kein Fehler, aber ein Grund.
  INSERT INTO public.users (id,"tenantId","displayName",role,email)
  VALUES (v_zeile, v_verein, 'Selbsttest Verbinden', 'BOARD', v_mail);

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role','authenticated')::text, true);
  PERFORM set_config('role','authenticated', true);
  v_erg := public.konto_verbinden(v_zeile);
  PERFORM set_config('role','postgres', true);
  PERFORM set_config('request.jwt.claims', NULL, true);
  IF (v_erg->>'verbunden')::boolean THEN
    RAISE EXCEPTION 'Ohne Anmeldekonto wurde etwas verbunden: %', v_erg;
  END IF;
  IF v_erg->>'grund' IS NULL THEN
    RAISE EXCEPTION 'Es fehlt die Begruendung -- die Maske wuesste nicht, was zu tun ist.';
  END IF;

  DELETE FROM public.users WHERE id = v_zeile;
  SELECT count(*) INTO v_nachher FROM public.users;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Zeile(n) hinterlassen.', v_nachher - v_vorher;
  END IF;

  RAISE NOTICE 'konto_verbinden bereit: nur Administration, Konto wird ueber die '
               'Adresse gefunden, Passwort bleibt unberuehrt.';
END $$;
