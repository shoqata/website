-- Wie gross sind die Mitgliedsdatensaetze?
--
-- Der Adminbereich schickt beim Speichern den gesamten Datensatz zurueck
-- ({...selectedUser}). Steckt darin ein eingebettetes Bild als Datenzeile,
-- wird daraus eine Anfrage von mehreren Megabyte -- und der Browser meldet
-- "Failed to fetch", nicht etwa einen Zugriffsfehler.
DO $$
DECLARE r record; v_max int; v_summe bigint;
BEGIN
  SELECT max(length(coalesce("photoFileName",''))) INTO v_max FROM public.users;
  RAISE NOTICE 'Laengstes photoFileName: % Zeichen', coalesce(v_max, 0);

  RAISE NOTICE '=== Die groessten Datensaetze ===';
  FOR r IN
    SELECT u.id, coalesce(u."displayName",'-') AS nm,
           length(to_jsonb(u)::text) AS gesamt,
           length(coalesce(u."photoFileName",'')) AS bild
      FROM public.users u
     ORDER BY length(to_jsonb(u)::text) DESC LIMIT 6
  LOOP
    RAISE NOTICE '  % (%) -- gesamt % Zeichen, davon Bild %',
      r.nm, r.id, r.gesamt, r.bild;
  END LOOP;

  SELECT sum(length(to_jsonb(u)::text)) INTO v_summe FROM public.users u;
  RAISE NOTICE 'Alle Mitglieder zusammen: % Zeichen', v_summe;

  RAISE NOTICE '=== Die beiden Qazim-Zeilen ===';
  FOR r IN SELECT u.id, length(to_jsonb(u)::text) AS gesamt,
                  length(coalesce(u."photoFileName",'')) AS bild
             FROM public.users u WHERE u."displayName" ILIKE '%qazim%' LOOP
    RAISE NOTICE '  % -- % Zeichen, Bild %', r.id, r.gesamt, r.bild;
  END LOOP;
END $$;
