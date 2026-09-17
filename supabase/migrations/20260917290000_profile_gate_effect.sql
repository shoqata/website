-- Wirkung der neuen Weiche, gemessen an den echten Daten.
--
-- Die Weiche prueft jetzt Name, Telefon, Strasse, PLZ, Ort und Nachbarschaft
-- -- genau die Angaben, die der Assistent erhebt. Hier wird gezaehlt, wen das
-- vorher und nachher betrifft, damit die Behauptung "nur noch wenn wirklich
-- etwas fehlt" belegt ist und nicht bloss behauptet.
DO $$
DECLARE
  v_gesamt int; v_vorher int; v_nachher int;
  v_nur_tel int; v_nur_adr int; v_nur_nb int;
BEGIN
  SELECT count(*) INTO v_gesamt FROM public.users;
  SELECT count(*) INTO v_vorher FROM public.users WHERE "profileComplete" IS NOT TRUE;

  SELECT count(*) INTO v_nachher FROM public.users
   WHERE coalesce(btrim("displayName"),'') = ''
      OR coalesce(btrim(phone),'')         = ''
      OR coalesce(btrim(street),'')        = ''
      OR coalesce(btrim(zip),'')           = ''
      OR coalesce(btrim(city),'')          = ''
      OR "neighborhoodId" IS NULL;

  RAISE NOTICE 'Mitglieder gesamt: %', v_gesamt;
  RAISE NOTICE 'Bisher in den Assistenten geschickt: %', v_vorher;
  RAISE NOTICE 'Kuenftig in den Assistenten geschickt: %', v_nachher;
  RAISE NOTICE 'Verschont: %', v_vorher - v_nachher;

  -- Woran es bei den verbleibenden liegt -- daran laesst sich ablesen, ob der
  -- Assistent ueberhaupt das richtige Feld anbietet.
  SELECT count(*) INTO v_nur_tel FROM public.users WHERE coalesce(btrim(phone),'') = '';
  SELECT count(*) INTO v_nur_adr FROM public.users
   WHERE coalesce(btrim(street),'')='' OR coalesce(btrim(zip),'')='' OR coalesce(btrim(city),'')='';
  SELECT count(*) INTO v_nur_nb  FROM public.users WHERE "neighborhoodId" IS NULL;
  RAISE NOTICE 'Davon ohne Telefon: %, ohne vollstaendige Adresse: %, ohne Nachbarschaft: %',
    v_nur_tel, v_nur_adr, v_nur_nb;
END $$;
