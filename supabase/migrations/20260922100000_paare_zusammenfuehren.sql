-- Fuenf Mitglieder standen zweimal da: einmal mit echter Adresse, einmal mit
-- dem Platzhalter @koretini.legacy aus der Uebernahme der alten Liste. Der
-- Verein hat am 21.09.2026 entschieden, alle fuenf zusammenzufuehren.
--
-- Es bleibt jeweils die Zeile mit der echten E-Mail -- nur ueber die ist das
-- Mitglied erreichbar und nur die kann sich anmelden. Leere Felder werden
-- aus der Platzhalterzeile aufgefuellt, vorhandene nicht ueberschrieben: bei
-- Shpend Basha und Kastriot Klaiqi ist die echte Zeile die neuere, deren
-- Adresse also die aktuellere.
DO $$
DECLARE
  paar record; v_n int; v_vor int; v_nach int;
BEGIN
  SELECT count(*) INTO v_vor FROM public.users WHERE "tenantId"='koretini';

  FOR paar IN
    SELECT lower(u."firstName")||' '||lower(u."lastName") AS person,
           count(*) AS anzahl,
           max(u.id) FILTER (WHERE u.email NOT LIKE '%@koretini.legacy') AS bleibt,
           max(u.id) FILTER (WHERE u.email LIKE '%@koretini.legacy')     AS geht
      FROM public.users u
     WHERE u."tenantId"='koretini'
       AND lower(u."firstName")||' '||lower(u."lastName") IN
           ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani')
     GROUP BY 1 ORDER BY 1
  LOOP
    IF paar.anzahl <> 2 OR paar.bleibt IS NULL OR paar.geht IS NULL THEN
      RAISE EXCEPTION 'Bei % ist die Lage anders als gemessen (% Zeilen). Hier wird nichts geaendert.',
        paar.person, paar.anzahl;
    END IF;

    -- 1. Beide Zeilen vollstaendig festhalten.
    INSERT INTO public.security_logs (id,"tenantId",type,action,"userId",details,"timestamp","createdAt")
    SELECT gen_random_uuid(), 'koretini', 'DATA_CLEANUP', 'DUPLICATE_MERGED', paar.geht,
           jsonb_build_object('grund','Platzhalteradresse aus der Uebernahme',
                              'bleibt', (SELECT to_jsonb(x) FROM public.users x WHERE x.id=paar.bleibt),
                              'entfernt',(SELECT to_jsonb(x) FROM public.users x WHERE x.id=paar.geht)),
           now(), now();

    -- 2. Leere Felder auffuellen, gefuellte in Ruhe lassen.
    UPDATE public.users b SET
      phone             = coalesce(nullif(b.phone,''), g.phone),
      "phoneSecondary"  = coalesce(nullif(b."phoneSecondary",''), g."phoneSecondary"),
      street            = coalesce(nullif(b.street,''), g.street),
      zip               = coalesce(nullif(b.zip,''), g.zip),
      city              = coalesce(nullif(b.city,''), g.city),
      country           = coalesce(nullif(b.country,''), g.country),
      address           = coalesce(nullif(b.address,''), g.address),
      birthdate         = coalesce(b.birthdate, g.birthdate),
      "neighborhoodId"  = coalesce(nullif(b."neighborhoodId",''), g."neighborhoodId"),
      "membershipCategory" = coalesce(nullif(b."membershipCategory",''), g."membershipCategory"),
      "billingGroup"    = coalesce(nullif(b."billingGroup",''), g."billingGroup"),
      "familyId"        = coalesce(nullif(b."familyId",''), g."familyId"),
      salutation        = coalesce(nullif(b.salutation,''), g.salutation),
      "livesInKoretin"  = coalesce(b."livesInKoretin", g."livesInKoretin"),
      "customAnnualFee" = coalesce(b."customAnnualFee", g."customAnnualFee"),
      "internalNotes"   = coalesce(nullif(b."internalNotes",''), g."internalNotes"),
      -- Wer eine Rechnung von 2026 hat, ist Mitglied; PENDING auf der neueren
      -- Zeile ist nur der Stand der Selbstanmeldung.
      "membershipStatus" = CASE WHEN 'ACTIVE' IN (b."membershipStatus", g."membershipStatus")
                                THEN 'ACTIVE' ELSE b."membershipStatus" END,
      "isLegacyEmail"   = false
      FROM public.users g WHERE b.id = paar.bleibt AND g.id = paar.geht;

    -- 3. Rechnungen mitnehmen.
    UPDATE public.payments SET "userId" = paar.bleibt WHERE "userId" = paar.geht;
    GET DIAGNOSTICS v_n = ROW_COUNT;

    DELETE FROM public.users WHERE id = paar.geht;
    RAISE NOTICE '  % -> zusammengefuehrt, % Rechnung(en) uebernommen', rpad(paar.person,18), v_n;
  END LOOP;

  SELECT count(*) INTO v_nach FROM public.users WHERE "tenantId"='koretini';
  RAISE NOTICE '--- Mitglieder % -> % ---', v_vor, v_nach;
END $$;
