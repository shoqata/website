-- Wie verteilen sich Beitragsstand und Datenqualitaet in einer Nachbarschaft?
--
-- Die Uebersicht soll der verantwortlichen Person zwei Dinge auf einen Blick
-- zeigen. Bevor ich Kennzeichen entwerfe, muss ich wissen, was sie tatsaechlich
-- zu sehen bekommt -- sonst baue ich fuer eine Verteilung, die es nicht gibt.
DO $$
DECLARE
  v_jahr int := EXTRACT(YEAR FROM current_date)::int;
  v_nb text; v_name text; r record;
  v_ges int; v_paid int; v_open int; v_none int;
  v_voll int; v_tel int; v_adr int; v_mail int;
BEGIN
  SELECT n.id, n.name INTO v_nb, v_name
    FROM public.neighborhoods n
   WHERE n."contactPersonIds" IS NOT NULL AND jsonb_array_length(n."contactPersonIds") > 0
   LIMIT 1;
  RAISE NOTICE 'Nachbarschaft % -- Beitragsjahr %', v_name, v_jahr;

  SELECT count(*) INTO v_ges FROM public.users WHERE "neighborhoodId" = v_nb;

  SELECT
    count(*) FILTER (WHERE zustand = 'PAID'),
    count(*) FILTER (WHERE zustand = 'OPEN'),
    count(*) FILTER (WHERE zustand = 'NONE')
  INTO v_paid, v_open, v_none
  FROM (
    SELECT CASE
             WHEN EXISTS (SELECT 1 FROM public.payments p
                           WHERE p."userId" = u.id AND p."billingYear"::int = v_jahr
                             AND p.status = 'PAID') THEN 'PAID'
             WHEN EXISTS (SELECT 1 FROM public.payments p
                           WHERE p."userId" = u.id AND p."billingYear"::int = v_jahr) THEN 'OPEN'
             ELSE 'NONE' END AS zustand
      FROM public.users u WHERE u."neighborhoodId" = v_nb
  ) z;

  RAISE NOTICE 'Beitrag %: bezahlt %, offen %, nichts verrechnet % (von % Mitgliedern)',
    v_jahr, v_paid, v_open, v_none, v_ges;

  -- Was der verantwortlichen Person an Angaben fehlt. Geburtsdatum bleibt
  -- aussen vor -- sie kann es in ihrer Maske gar nicht nachtragen.
  SELECT
    count(*) FILTER (WHERE coalesce(btrim(phone),'') = ''),
    count(*) FILTER (WHERE coalesce(btrim(street),'')='' OR coalesce(btrim(zip),'')='' OR coalesce(btrim(city),'')=''),
    count(*) FILTER (WHERE email IS NULL OR btrim(email)='' OR email ILIKE '%@koretini.legacy' OR email ILIKE '%no-email-%')
  INTO v_tel, v_adr, v_mail
  FROM public.users WHERE "neighborhoodId" = v_nb;

  SELECT count(*) INTO v_voll FROM public.users
   WHERE "neighborhoodId" = v_nb
     AND coalesce(btrim(phone),'')  <> ''
     AND coalesce(btrim(street),'') <> ''
     AND coalesce(btrim(zip),'')    <> ''
     AND coalesce(btrim(city),'')   <> ''
     AND email IS NOT NULL AND btrim(email) <> ''
     AND email NOT ILIKE '%@koretini.legacy' AND email NOT ILIKE '%no-email-%';

  RAISE NOTICE 'Angaben vollstaendig bei % von %', v_voll, v_ges;
  RAISE NOTICE '  ohne Telefon %, ohne vollstaendige Adresse %, ohne brauchbare E-Mail %',
    v_tel, v_adr, v_mail;

  RAISE NOTICE '=== Vorhandene Beitragsjahre ===';
  FOR r IN SELECT "billingYear", count(*) AS n FROM public.payments
            GROUP BY 1 ORDER BY 1 LOOP
    RAISE NOTICE '  %: %', coalesce(r."billingYear"::text,'<leer>'), r.n;
  END LOOP;
END $$;
