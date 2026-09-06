-- Anmeldung und Mitgliederanlage reparieren.
--
-- users.email traegt einen UNIQUE-Index. Daran scheitern zwei Ablaeufe:
--
-- 1. Beim Login legt App.tsx eine zweite Zeile mit der Auth-UID an und kopiert
--    die Daten der Legacy-Zeile -- inklusive E-Mail. Das verletzt den Index,
--    der Insert scheitert mit 23505 und die Anmeldung hinterlaesst nichts.
--    Deshalb traegt keine der 341 Zeilen eine Auth-UUID.
-- 2. Neue Mitglieder werden mit email = '' angelegt. Der leere String ist ein
--    Wert wie jeder andere und kollidiert ab dem zweiten Mal. NULL dagegen darf
--    in einem UNIQUE-Index beliebig oft vorkommen.
--
-- Statt Zeilen zu duplizieren wird die vorhandene Zeile nun beansprucht: sie
-- behaelt ihre id, an der Zahlungen, Vorstandsmandate und Quartierszuordnungen
-- haengen, und bekommt die Auth-UID als zusaetzliches Merkmal.

-- --- 1. Leere E-Mails zu NULL ---------------------------------------------
UPDATE public.users SET email = NULL WHERE btrim(COALESCE(email, '')) = '';

CREATE OR REPLACE FUNCTION public.users_normalise_email()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.email := NULLIF(btrim(NEW.email), '');
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS users_normalise_email ON public.users;
CREATE TRIGGER users_normalise_email
BEFORE INSERT OR UPDATE OF email ON public.users
FOR EACH ROW EXECUTE FUNCTION public.users_normalise_email();

-- --- 2. Verknuepfung zur Auth-Identitaet -----------------------------------
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS "authUserId" text;

CREATE UNIQUE INDEX IF NOT EXISTS users_auth_user_id_key
  ON public.users ("authUserId") WHERE "authUserId" IS NOT NULL;

-- Zeilen, die bereits nach Auth-UID benannt sind, sind selbst verknuepft.
UPDATE public.users
   SET "authUserId" = id
 WHERE "authUserId" IS NULL
   AND id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- --- 3. Helfer kennen jetzt beide Wege -------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_row_id()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT id FROM public.users
   WHERE "authUserId" = auth.uid()::text OR id = auth.uid()::text
   ORDER BY ("authUserId" = auth.uid()::text) DESC
   LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.app_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT 'SUPER_ADMIN'
       WHERE auth.jwt() ->> 'email' IS NOT NULL
         AND EXISTS (SELECT 1 FROM public.admin_emails
                      WHERE lower(email) = lower(auth.jwt() ->> 'email'))),
    (SELECT role FROM public.users WHERE id = public.current_user_row_id()),
    'GUEST'
  )
$$;

CREATE OR REPLACE FUNCTION public.app_neighborhood()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT "neighborhoodId" FROM public.users WHERE id = public.current_user_row_id()
$$;

REVOKE ALL ON FUNCTION public.current_user_row_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_row_id() TO authenticated;

-- --- 4. Beanspruchen der eigenen Zeile -------------------------------------
-- Bewusst als Funktion und nicht als gelockerte Policy: so ist genau eine
-- Operation erlaubt -- die eigene, noch unverknuepfte Zeile mit der eigenen
-- Auth-Identitaet zu verbinden. Rolle, E-Mail und alles andere bleiben
-- unberuehrt, es gibt also keine Flaeche fuer Rechteausweitung.
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

  UPDATE public.users
     SET "authUserId" = v_uid
   WHERE lower(email) = v_email
     AND "authUserId" IS NULL
     AND id = (SELECT id FROM public.users
                WHERE lower(email) = v_email AND "authUserId" IS NULL
                ORDER BY "joinedAt" NULLS LAST LIMIT 1)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION public.claim_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_my_profile() TO authenticated;

-- --- 5. Policies kennen die Verknuepfung ----------------------------------
DROP POLICY IF EXISTS users_select ON public.users;
CREATE POLICY users_select ON public.users FOR SELECT TO authenticated
USING (
  public.is_member_manager()
  OR id = auth.uid()::text
  OR "authUserId" = auth.uid()::text
  OR (auth.jwt() ->> 'email' IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
);

DROP POLICY IF EXISTS users_update ON public.users;
CREATE POLICY users_update ON public.users FOR UPDATE TO authenticated
USING (
  public.is_member_manager()
  OR id = auth.uid()::text
  OR "authUserId" = auth.uid()::text
)
WITH CHECK (
  public.is_staff()
  OR (public.is_member_manager() AND COALESCE(role, 'MEMBER') IN ('MEMBER', 'GUEST'))
  OR ((id = auth.uid()::text OR "authUserId" = auth.uid()::text)
      AND COALESCE(role, 'MEMBER') = COALESCE(public.app_role(), 'MEMBER'))
);
