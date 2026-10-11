-- Welche Verantwortlichen koennen sich anmelden, und welche nicht?
--
-- Gemessen bei Koretini, und das ist der Grund fuer diese Migration:
--
--   Nachbarschaften                   27
--   mit Verantwortlichen hinterlegt    6
--   ohne Verantwortlichen             21
--   hinterlegte Personen               8
--   davon mit Anmeldung                2
--
-- Sechs Verantwortliche stehen auf dem Papier und kommen nicht herein.
-- Das ist niemandem aufgefallen, weil es keine Stelle gibt, an der man
-- es sehen koennte: die Nachbarschaftsmaske zeigt, WER hinterlegt ist,
-- aber nicht, ob diese Person den Verein auch betreten kann.
--
-- Die Faehigkeit, ein Konto anzulegen, gibt es schon -- die Funktion
-- reset-member-password legt eines an, wenn keines besteht, und
-- Vorstand wie Administration duerfen das im eigenen Verein. Sie heisst
-- nur "Passwort zuruecksetzen", und dort sucht niemand nach "gib
-- diesem Verantwortlichen einen Zugang".
--
-- Warum eine Funktion und nicht eine Abfrage aus der Anwendung:
-- "kann sich anmelden" steckt in users.authUserId, und das ist die
-- Kennung des Anmeldekontos. Sie in den Browser zu schicken, nur um
-- dort auf "ist nicht leer" zu pruefen, waere unnoetig -- die Antwort
-- ist ein Ja oder Nein, und mehr soll nicht hinausgehen.

CREATE OR REPLACE FUNCTION public.verantwortliche_stand()
RETURNS TABLE (
  r_nachbarschaft   text,
  r_name            text,
  r_person          text,
  r_person_name     text,
  r_email           text,
  r_hat_zugang      boolean,
  r_rolle           text,
  r_mitglieder      integer
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH zustaendig AS (
    -- Alle drei Wege, auf denen jemand verantwortlich sein kann. Genau
    -- dieselben, die my_neighborhoods() auswertet -- sonst zeigte diese
    -- Uebersicht jemanden als zustaendig, der es nicht ist, oder
    -- umgekehrt.
    SELECT n.id AS nb, n.name AS nb_name, p AS person
      FROM public.neighborhoods n
      CROSS JOIN LATERAL (
        SELECT n."representativeId" AS p
        UNION SELECT n."managerId"
        UNION SELECT jsonb_array_elements_text(coalesce(n."contactPersonIds", '[]'::jsonb))
      ) x
     WHERE n."tenantId" = public.current_tenant()
       AND p IS NOT NULL AND btrim(p) <> ''
  )
  SELECT z.nb, z.nb_name, z.person,
         coalesce(u."displayName", u.email, z.person),
         u.email,
         -- Das Ja oder Nein, nicht die Kennung.
         u."authUserId" IS NOT NULL,
         coalesce(u.role, '—'),
         (SELECT count(*)::int FROM public.users m
           WHERE m."tenantId" = public.current_tenant()
             AND m."neighborhoodId" = z.nb
             AND coalesce(m."membershipStatus",'ACTIVE') <> 'INACTIVE')
    FROM zustaendig z
    LEFT JOIN public.users u ON u.id = z.person
   WHERE public.is_member_manager() OR public.is_platform_admin()
   ORDER BY z.nb_name, coalesce(u."displayName", z.person);
$$;

REVOKE ALL ON FUNCTION public.verantwortliche_stand() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.verantwortliche_stand() TO authenticated;

COMMENT ON FUNCTION public.verantwortliche_stand() IS
  'Je Nachbarschaft die hinterlegten Verantwortlichen und ob sie sich '
  'anmelden koennen. Gibt bewusst nur ein Ja/Nein zurueck, nicht die '
  'Kennung des Anmeldekontos.';


-- Und die Gegenseite: Nachbarschaften ohne jeden Verantwortlichen.
-- Sie fehlen in der Liste oben zwangslaeufig -- eine Uebersicht, die
-- nur zeigt, was da ist, verschweigt gerade das Wesentliche. 21 von 27
-- haben niemanden.
CREATE OR REPLACE FUNCTION public.nachbarschaften_ohne_verantwortlichen()
RETURNS TABLE (r_id text, r_name text, r_mitglieder integer)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT n.id, n.name,
         (SELECT count(*)::int FROM public.users m
           WHERE m."tenantId" = n."tenantId" AND m."neighborhoodId" = n.id
             AND coalesce(m."membershipStatus",'ACTIVE') <> 'INACTIVE')
    FROM public.neighborhoods n
   WHERE n."tenantId" = public.current_tenant()
     AND coalesce(jsonb_array_length(n."contactPersonIds"), 0) = 0
     AND coalesce(btrim(n."representativeId"), '') = ''
     AND coalesce(btrim(n."managerId"), '') = ''
     AND (public.is_member_manager() OR public.is_platform_admin())
   ORDER BY 3 DESC, 2;
$$;

REVOKE ALL ON FUNCTION public.nachbarschaften_ohne_verantwortlichen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nachbarschaften_ohne_verantwortlichen() TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_quelle text; v_n int;
BEGIN
  -- Die Uebersicht muss GENAU die drei Wege auswerten, die
  -- my_neighborhoods() auswertet. Weicht sie ab, zeigt sie jemanden als
  -- zustaendig, der es nicht ist -- oder verschweigt einen, der es ist,
  -- und dann bleibt sein fehlender Zugang weiter unentdeckt.
  SELECT p.prosrc INTO v_quelle FROM pg_proc p
    JOIN pg_namespace ns ON ns.oid = p.pronamespace
   WHERE ns.nspname='public' AND p.proname='my_neighborhoods';

  FOREACH v_quelle IN ARRAY ARRAY['contactPersonIds','representativeId','managerId'] LOOP
    IF (SELECT p.prosrc FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
         WHERE ns.nspname='public' AND p.proname='verantwortliche_stand') NOT LIKE '%'||v_quelle||'%' THEN
      RAISE EXCEPTION 'verantwortliche_stand wertet % nicht aus -- sie weicht damit von '
                      'my_neighborhoods ab.', v_quelle;
    END IF;
  END LOOP;

  -- Die Kennung des Anmeldekontos darf nicht hinausgehen; nur das Ja/Nein.
  IF (SELECT p.prosrc FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
       WHERE ns.nspname='public' AND p.proname='verantwortliche_stand')
     !~ 'authUserId" IS NOT NULL' THEN
    RAISE EXCEPTION 'verantwortliche_stand gibt die Kontokennung heraus statt eines Ja/Nein.';
  END IF;

  -- Und die Schranke: wer nicht Vorstand oder Administration ist, sieht nichts.
  FOREACH v_quelle IN ARRAY ARRAY['verantwortliche_stand','nachbarschaften_ohne_verantwortlichen'] LOOP
    IF (SELECT p.prosrc FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
         WHERE ns.nspname='public' AND p.proname=v_quelle) !~ 'is_member_manager' THEN
      RAISE EXCEPTION 'In % fehlt die Berechtigungspruefung.', v_quelle;
    END IF;
  END LOOP;

  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public'
     AND p.proname IN ('verantwortliche_stand','nachbarschaften_ohne_verantwortlichen');
  IF v_n <> 2 THEN RAISE EXCEPTION 'Erwartet 2 Funktionen, gefunden %.', v_n; END IF;

  RAISE NOTICE 'Uebersicht der Verantwortlichen bereit, beide Wege geprueft.';
END $$;
