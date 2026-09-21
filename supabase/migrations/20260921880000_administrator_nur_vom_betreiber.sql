-- Der Administrator eines Vereins wird vom Betreiber gesetzt, nicht erworben.
--
-- Gemessen am 21.09.2026: claim_my_profile() verknuepft eine Anmeldung mit
-- JEDER unverknuepften Mitgliedszeile gleicher E-Mail -- auch mit einer, die
-- ADMIN oder SUPER_ADMIN traegt. In koretini standen fuenf solche Zeilen,
-- darunter eine mit SUPER_ADMIN. Wer sich mit dieser Adresse registriert,
-- haette die Rolle uebernommen. Fuer gewoehnliche Mitglieder ist das
-- Selbstverknuepfen richtig und bleibt (330 Zeilen warten darauf); fuer
-- bevorrechtigte Rollen ist es eine offene Tuer.

CREATE OR REPLACE FUNCTION public.claim_my_profile()
RETURNS text
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid   text := auth.uid()::text;
  v_email text := lower(auth.jwt() ->> 'email');
  v_id    text;
BEGIN
  IF v_uid IS NULL THEN RETURN NULL; END IF;

  SELECT public.current_user_row_id() INTO v_id;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  IF v_email IS NULL THEN RETURN NULL; END IF;

  -- Nur gewoehnliche Zeilen. Eine bevorrechtigte Rolle bekommt ihr
  -- Anmeldekonto vom Betreiber beziehungsweise von der Administration des
  -- Vereins gesetzt -- ueber reset_member_password, das protokolliert wird.
  UPDATE public.users
     SET "authUserId" = v_uid
   WHERE lower(email) = v_email
     AND "authUserId" IS NULL
     AND coalesce(role, 'MEMBER') IN ('MEMBER', 'GUEST')
     AND id = (SELECT id FROM public.users
                WHERE lower(email) = v_email AND "authUserId" IS NULL
                  AND coalesce(role, 'MEMBER') IN ('MEMBER', 'GUEST')
                ORDER BY "joinedAt" NULLS LAST LIMIT 1)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION public.claim_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_my_profile() TO authenticated;


-- Der Weg, auf dem der Betreiber den Administrator setzt.
--
-- Ohne diese Funktion braeuchte der Betreiber eine Betreuungssitzung, nur um
-- die id der Mitgliedszeile zu erfahren -- die Zeilenregel auf users laesst
-- ihn fremde Vereine sonst nicht sehen. Hier wird ueber die Adresse
-- gearbeitet, die er ohnehin eintippt.
CREATE OR REPLACE FUNCTION public.vereins_administrator_setzen(
  p_verein text, p_email text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_mail  text := lower(btrim(coalesce(p_email, '')));
  v_id    text;
  v_rolle text;
  v_fremd text;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf den Administrator eines Vereins setzen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_verein) THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein USING ERRCODE = 'check_violation';
  END IF;
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'Ohne echte E-Mail-Adresse gibt es kein Anmeldekonto.'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT "tenantId" INTO v_fremd FROM public.users
   WHERE lower(email) = v_mail AND "tenantId" <> p_verein LIMIT 1;
  IF v_fremd IS NOT NULL THEN
    RAISE EXCEPTION 'Die Adresse % gehoert bereits zum Verein %.', v_mail, v_fremd
      USING ERRCODE = 'unique_violation';
  END IF;

  SELECT id, coalesce(role,'MEMBER') INTO v_id, v_rolle FROM public.users
   WHERE "tenantId" = p_verein AND lower(email) = v_mail LIMIT 1;

  IF v_id IS NULL THEN
    v_id := gen_random_uuid()::text;
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (v_id, p_verein, v_mail, 'ADMIN', 'ACTIVE', v_mail, now());
  ELSIF v_rolle <> 'ADMIN' THEN
    -- Der Betreiber setzt hier bewusst. Eine SUPER_ADMIN-Zeile wird nicht
    -- heruntergestuft, alles andere wird zur Administration erhoben.
    IF v_rolle <> 'SUPER_ADMIN' THEN
      UPDATE public.users SET role = 'ADMIN' WHERE id = v_id;
    END IF;
  END IF;

  -- Legt das Anmeldekonto an, verknuepft es und protokolliert. Der Betreiber
  -- darf das vereinsuebergreifend; das prueft die Funktion selbst.
  RETURN public.reset_member_password(v_id) || jsonb_build_object('tenantId', p_verein);
END $$;

REVOKE ALL ON FUNCTION public.vereins_administrator_setzen(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.vereins_administrator_setzen(text, text) TO authenticated;
