-- Wie stark verfaelschen ausgetretene Mitglieder die Datenqualitaet?
--
-- Die Zahl am Reiter schliesst INACTIVE aus, die Liste darin nicht -- und
-- beide verwenden unterschiedliche Regeln fuer "unvollstaendig". Damit stehen
-- zwei Zahlen fuer dieselbe Sache nebeneinander.
DO $$
DECLARE
  v_alle int; v_inaktiv int; v_pending int; v_aktiv int;
  v_luecken_alle int; v_luecken_aktiv int;
  v_konflikt_alle int; v_konflikt_aktiv int;
  v_schnitt_alle numeric; v_schnitt_aktiv numeric;
  r record;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE "membershipStatus" = 'INACTIVE'),
         count(*) FILTER (WHERE "membershipStatus" = 'PENDING'),
         count(*) FILTER (WHERE coalesce("membershipStatus",'ACTIVE') = 'ACTIVE')
    INTO v_alle, v_inaktiv, v_pending, v_aktiv FROM public.users;
  RAISE NOTICE 'Mitglieder %: aktiv %, wartend %, ausgetreten %', v_alle, v_aktiv, v_pending, v_inaktiv;

  -- Die Regel aus lib/memberQuality: Telefon, Geburtsdatum, Adresse,
  -- Nachbarschaft, brauchbare E-Mail.
  WITH bewertung AS (
    SELECT u."membershipStatus" AS status,
           (CASE WHEN coalesce(btrim(u.phone),'')='' THEN 1 ELSE 0 END
          + CASE WHEN u.birthdate IS NULL OR btrim(u.birthdate)='' THEN 1 ELSE 0 END
          + CASE WHEN coalesce(btrim(u.street),'')='' OR coalesce(btrim(u.zip),'')=''
                   OR coalesce(btrim(u.city),'')='' THEN 1 ELSE 0 END
          + CASE WHEN u."neighborhoodId" IS NULL THEN 1 ELSE 0 END
          + CASE WHEN u.email IS NULL OR btrim(u.email)='' OR u.email ILIKE '%@koretini.legacy'
                   OR u.email ILIKE '%no-email-%' THEN 1 ELSE 0 END) AS fehlt
      FROM public.users u
  )
  SELECT count(*) FILTER (WHERE fehlt > 0),
         count(*) FILTER (WHERE fehlt > 0 AND status IS DISTINCT FROM 'INACTIVE'),
         round(avg(greatest(0, 100 - fehlt * 20)), 1),
         round(avg(greatest(0, 100 - fehlt * 20)) FILTER (WHERE status IS DISTINCT FROM 'INACTIVE'), 1)
    INTO v_luecken_alle, v_luecken_aktiv, v_schnitt_alle, v_schnitt_aktiv
    FROM bewertung;

  RAISE NOTICE 'Mit Luecken: % ueber alle, % ohne die Ausgetretenen', v_luecken_alle, v_luecken_aktiv;
  RAISE NOTICE 'Durchschnittliche Qualitaet: %%% ueber alle, %%% ohne die Ausgetretenen',
    v_schnitt_alle, v_schnitt_aktiv;

  -- Zustellart verspricht E-Mail, es gibt aber keine brauchbare Adresse.
  SELECT count(*), count(*) FILTER (WHERE "membershipStatus" IS DISTINCT FROM 'INACTIVE')
    INTO v_konflikt_alle, v_konflikt_aktiv
    FROM public.users
   WHERE coalesce("invoiceDeliveryMethod",'EMAIL') IN ('EMAIL','BOTH')
     AND (email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy'
          OR email ILIKE '%no-email-%');
  RAISE NOTICE 'Zustellkonflikte: % ueber alle, % ohne die Ausgetretenen',
    v_konflikt_alle, v_konflikt_aktiv;

  RAISE NOTICE '=== Die Ausgetretenen im Einzelnen ===';
  FOR r IN SELECT "displayName", coalesce(email,'<keine>') AS mail, coalesce(role,'-') AS rolle
             FROM public.users WHERE "membershipStatus" = 'INACTIVE' ORDER BY "displayName" LOOP
    RAISE NOTICE '  % | % | %', r."displayName", r.mail, r.rolle;
  END LOOP;
END $$;
