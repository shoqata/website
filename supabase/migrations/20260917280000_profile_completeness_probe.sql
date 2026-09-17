-- Warum landen bestehende Mitglieder im Einrichtungsassistenten?
--
-- Die Weiche in der Anwendung lautet schlicht: profileComplete <> true ->
-- Assistent. Ob die Daten in Wahrheit laengst vollstaendig sind, wird nicht
-- gefragt. Hier wird nachgesehen, wie viele davon betroffen sind und welche
-- Felder tatsaechlich fehlen -- bevor die Weiche umgebaut wird.
DO $$
DECLARE
  v_gesamt int; v_flag int; v_ohne_flag int;
  v_tel int; v_str int; v_ort int; v_nb int; v_land int;
  v_vollstaendig_ohne_flag int;
  r record; v_spalten text := '';
BEGIN
  FOR r IN SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name='users'
              AND column_name IN ('address','street','zip','city','country','phone','neighborhoodId','profileComplete')
            ORDER BY column_name LOOP
    v_spalten := v_spalten || r.column_name || ' ';
  END LOOP;
  RAISE NOTICE 'Vorhandene Adressfelder: %', v_spalten;

  SELECT count(*) INTO v_gesamt FROM public.users;
  SELECT count(*) INTO v_flag FROM public.users WHERE "profileComplete" IS TRUE;
  v_ohne_flag := v_gesamt - v_flag;
  RAISE NOTICE 'Mitglieder: %, als vollstaendig markiert: %, ohne Markierung: %',
    v_gesamt, v_flag, v_ohne_flag;

  SELECT count(*) INTO v_tel  FROM public.users WHERE coalesce(btrim(phone),'')   <> '';
  SELECT count(*) INTO v_str  FROM public.users WHERE coalesce(btrim(street),'')  <> '';
  SELECT count(*) INTO v_ort  FROM public.users WHERE coalesce(btrim(city),'')    <> '';
  SELECT count(*) INTO v_land FROM public.users WHERE coalesce(btrim(country),'') <> '';
  SELECT count(*) INTO v_nb   FROM public.users WHERE "neighborhoodId" IS NOT NULL;
  RAISE NOTICE 'Davon haben: Telefon %, Strasse %, Ort %, Land %, Nachbarschaft %',
    v_tel, v_str, v_ort, v_land, v_nb;

  -- Die eigentliche Frage: wie viele waeren nach jedem vernuenftigen Massstab
  -- fertig, werden aber trotzdem in den Assistenten geschickt?
  SELECT count(*) INTO v_vollstaendig_ohne_flag FROM public.users
   WHERE "profileComplete" IS NOT TRUE
     AND coalesce(btrim("displayName"),'') <> ''
     AND coalesce(btrim(street),'') <> ''
     AND coalesce(btrim(city),'') <> ''
     AND "neighborhoodId" IS NOT NULL;
  RAISE NOTICE 'Vollstaendig, aber ohne Markierung -> unnoetig im Assistenten: %',
    v_vollstaendig_ohne_flag;

  RAISE NOTICE '--- Stichprobe Canaj ---';
  FOR r IN SELECT "displayName", coalesce(phone,'-') AS tel, coalesce(street,'-') AS str,
                  coalesce(zip,'-') AS plz, coalesce(city,'-') AS ort,
                  coalesce(country,'-') AS land,
                  coalesce("neighborhoodId"::text,'-') AS nb,
                  coalesce("profileComplete"::text,'null') AS fertig
             FROM public.users WHERE "displayName" ILIKE '%canaj%' LIMIT 3 LOOP
    RAISE NOTICE '  % | Tel % | % % % (%) | Nachbarschaft % | markiert %',
      r."displayName", r.tel, r.str, r.plz, r.ort, r.land, r.nb, r.fertig;
  END LOOP;
END $$;
