-- Vierte Stellung: Namen MIT Beträgen.
--
-- Bisher gab es AUS, ZAHL (nur die Anzahl) und NAMEN. Verlangt ist, dass
-- auf der Website steht, wer wie viel fuer ein Jahr bezahlt hat.
--
-- Dreierlei ist daran zu bedenken, und ich halte es hier fest, weil die
-- Entscheidung dem Verein gehoert und nicht mir:
--
--   Es sind Finanzangaben zu 353 Menschen. Wer wenig zahlt, steht damit
--   oeffentlich als jemand da, der wenig zahlt -- und die Beitraege sind
--   nicht gleich: STANDARD 120, KOSOVO 12, dazu individuelle Betraege.
--   Ein veroeffentlichter Betrag sagt also etwas ueber die Lage einer
--   Person.
--
--   Der Widerspruch ist ein Opt-out, und bisher hat NIEMAND
--   widersprochen -- gemessen 0 von 353. Nicht weil alle einverstanden
--   sind, sondern weil niemand gefragt wurde. Der Schalter steht heute
--   auf AUS; mit BETRAEGE wird aus diesem Nichtwissen eine
--   Veroeffentlichung.
--
--   Der Riegel bleibt, wo er ist: in der Datenbank. Wer die
--   Schnittstelle kennt, kommt nicht an mehr heran als die Website
--   zeigt. Eine Pruefung in der Oberflaeche umgeht jeder.
--
-- Gezeigt wird der TATSAECHLICH ERHALTENE Betrag, nicht der
-- verrechnete. "Wie viel hat er bezahlt" ist genau diese Zahl -- seit
-- den Zahlungseingaengen steht sie in payments.bezahlt. Den
-- Rechnungsbetrag zu zeigen hiesse bei einer Teilzahlung, mehr zu
-- behaupten als eingegangen ist.

CREATE OR REPLACE FUNCTION public.beitragsstand_oeffentlich(p_jahr int DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein   text := coalesce(public.current_tenant(), public.request_tenant());
  v_stellung text;
  v_jahr     int  := coalesce(p_jahr, extract(year FROM current_date)::int);
  v_anzahl   int;
  v_gesamt   int;
  v_namen    jsonb;
  v_zeilen   jsonb;
  v_summe    numeric;
  v_waehrung text;
BEGIN
  IF v_verein IS NULL THEN
    RETURN jsonb_build_object('stellung','AUS');
  END IF;

  SELECT upper(coalesce(s.system ->> 'beitraegeOeffentlich','AUS'))
    INTO v_stellung
    FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';

  IF coalesce(v_stellung,'AUS') NOT IN ('ZAHL','NAMEN','BETRAEGE') THEN
    RETURN jsonb_build_object('stellung','AUS');
  END IF;

  -- Die Zahl umfasst alle, die bezahlt haben. Sie ist eine Summe und
  -- benennt niemanden; ein Widerspruch aendert daran nichts.
  SELECT count(DISTINCT p."userId")
    INTO v_anzahl
    FROM public.payments p
   WHERE p."tenantId" = v_verein
     AND p."billingYear" = v_jahr
     AND p.status = 'PAID'
     AND p."userId" IS NOT NULL;

  SELECT count(*) INTO v_gesamt
    FROM public.users u
   WHERE u."tenantId" = v_verein
     AND coalesce(u."membershipStatus",'') = 'ACTIVE';

  IF v_stellung = 'ZAHL' THEN
    RETURN jsonb_build_object('stellung','ZAHL','jahr',v_jahr,
                              'anzahl',v_anzahl,'gesamt',v_gesamt);
  END IF;

  IF v_stellung = 'NAMEN' THEN
    SELECT jsonb_agg(x.name ORDER BY x.name)
      INTO v_namen
      FROM (SELECT DISTINCT coalesce(nullif(btrim(u."displayName"),''),
                                     btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",''))) AS name
              FROM public.payments p
              JOIN public.users u ON u.id = p."userId"
             WHERE p."tenantId" = v_verein
               AND p."billingYear" = v_jahr
               AND p.status = 'PAID'
               AND coalesce(u.nicht_oeffentlich,false) = false
               AND coalesce(u."membershipStatus",'') <> 'INACTIVE') x
     WHERE coalesce(btrim(x.name),'') <> '';

    RETURN jsonb_build_object('stellung','NAMEN','jahr',v_jahr,
                              'anzahl',v_anzahl,'gesamt',v_gesamt,
                              'namen', coalesce(v_namen,'[]'::jsonb));
  END IF;

  -- BETRAEGE: Name und Betrag, je Mitglied zusammengefasst.
  --
  -- Zusammengefasst, weil ein Mitglied mehrere Rechnungen im Jahr haben
  -- kann -- Beitrag und eine Nachforderung etwa. Zwei Zeilen fuer eine
  -- Person saehen auf der Website wie zwei Personen aus.
  --
  -- coalesce(bezahlt, amount): Zahlungen aus der Zeit vor den
  -- Zahlungseingaengen haben bezahlt = 0 und stehen auf PAID. Fuer sie
  -- ist der Rechnungsbetrag die beste verfuegbare Auskunft; bei allen
  -- neueren steht der erhaltene Betrag.
  SELECT jsonb_agg(jsonb_build_object('name', y.name, 'betrag', y.betrag)
                   ORDER BY y.betrag DESC, y.name),
         sum(y.betrag)
    INTO v_zeilen, v_summe
    FROM (
      SELECT coalesce(nullif(btrim(u."displayName"),''),
                      btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",''))) AS name,
             sum(CASE WHEN coalesce(p.bezahlt,0) > 0 THEN p.bezahlt ELSE p.amount END) AS betrag
        FROM public.payments p
        JOIN public.users u ON u.id = p."userId"
       WHERE p."tenantId" = v_verein
         AND p."billingYear" = v_jahr
         AND p.status = 'PAID'
         AND coalesce(u.nicht_oeffentlich,false) = false
         AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
       GROUP BY 1
      HAVING coalesce(btrim(coalesce(nullif(btrim(u."displayName"),''),
                      btrim(coalesce(u."firstName",'')||' '||coalesce(u."lastName",'')))),'') <> ''
    ) y;

  SELECT currency INTO v_waehrung FROM public.payments
   WHERE "tenantId" = v_verein AND "billingYear" = v_jahr AND status = 'PAID'
   LIMIT 1;

  RETURN jsonb_build_object('stellung','BETRAEGE','jahr',v_jahr,
                            'anzahl',v_anzahl,'gesamt',v_gesamt,
                            'waehrung', coalesce(v_waehrung,'CHF'),
                            'summe', coalesce(v_summe, 0),
                            'zeilen', coalesce(v_zeilen,'[]'::jsonb));
END $$;

REVOKE ALL ON FUNCTION public.beitragsstand_oeffentlich(int) FROM public;
GRANT EXECUTE ON FUNCTION public.beitragsstand_oeffentlich(int) TO anon, authenticated;


-- Welche Jahre gibt es? Fuer die Jahreswahl auf der Website.
--
-- Auch das haengt am Schalter: steht er auf AUS, gibt es keine Jahre zu
-- waehlen. Eine Jahresliste, die unabhaengig davon antwortet, verraet
-- schon, in welchen Jahren der Verein Beitraege eingenommen hat.
CREATE OR REPLACE FUNCTION public.beitragsjahre_oeffentlich()
RETURNS int[]
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := coalesce(public.current_tenant(), public.request_tenant());
  v_stellung text;
BEGIN
  IF v_verein IS NULL THEN RETURN '{}'; END IF;

  SELECT upper(coalesce(s.system ->> 'beitraegeOeffentlich','AUS'))
    INTO v_stellung FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';
  IF coalesce(v_stellung,'AUS') NOT IN ('ZAHL','NAMEN','BETRAEGE') THEN
    RETURN '{}';
  END IF;

  RETURN coalesce((
    SELECT array_agg(DISTINCT p."billingYear" ORDER BY p."billingYear" DESC)
      FROM public.payments p
     WHERE p."tenantId" = v_verein AND p.status = 'PAID'
       AND p."billingYear" IS NOT NULL), '{}');
END $$;

REVOKE ALL ON FUNCTION public.beitragsjahre_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.beitragsjahre_oeffentlich() TO anon, authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE
  v_verein text := 'koretini'; v_alt text; v_erg jsonb; v_zeilen int;
  v_mitglied text; v_name text;
BEGIN
  SELECT system ->> 'beitraegeOeffentlich' INTO v_alt
    FROM public.settings WHERE "tenantId" = v_verein AND id = 'system';

  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, true);

  -- 1. AUS gibt nichts heraus, auch nicht die Jahre.
  UPDATE public.settings SET system = coalesce(system,'{}'::jsonb)
         || jsonb_build_object('beitraegeOeffentlich','AUS')
   WHERE "tenantId" = v_verein AND id = 'system';
  v_erg := public.beitragsstand_oeffentlich(2026);
  IF v_erg->>'stellung' <> 'AUS' OR v_erg ? 'zeilen' THEN
    RAISE EXCEPTION 'Bei AUS kam etwas heraus: %', v_erg;
  END IF;
  IF array_length(public.beitragsjahre_oeffentlich(), 1) IS NOT NULL THEN
    RAISE EXCEPTION 'Bei AUS wurden Jahre herausgegeben -- das verraet schon, '
                    'in welchen Jahren Beitraege eingingen.';
  END IF;

  -- 2. BETRAEGE liefert Namen mit Betraegen.
  UPDATE public.settings SET system = system
         || jsonb_build_object('beitraegeOeffentlich','BETRAEGE')
   WHERE "tenantId" = v_verein AND id = 'system';
  v_erg := public.beitragsstand_oeffentlich(2026);
  IF v_erg->>'stellung' <> 'BETRAEGE' THEN
    RAISE EXCEPTION 'BETRAEGE wurde nicht erkannt: %', v_erg;
  END IF;
  v_zeilen := jsonb_array_length(v_erg->'zeilen');
  IF v_zeilen = 0 THEN
    RAISE EXCEPTION 'Keine Zeilen, obwohl 86 Mitglieder fuer 2026 bezahlt haben.';
  END IF;
  IF (v_erg->'zeilen'->0->>'betrag') IS NULL THEN
    RAISE EXCEPTION 'Eine Zeile ohne Betrag -- dann ist es die alte Namensliste.';
  END IF;

  -- 3. Der Widerspruch gewinnt. Ein Mitglied, das bezahlt hat, wird auf
  --    nicht_oeffentlich gesetzt und muss aus der Liste verschwinden --
  --    aber die ANZAHL darf sich nicht aendern, denn sie benennt
  --    niemanden.
  SELECT u.id, coalesce(u."displayName", u.id) INTO v_mitglied, v_name
    FROM public.payments p JOIN public.users u ON u.id = p."userId"
   WHERE p."tenantId" = v_verein AND p."billingYear" = 2026 AND p.status='PAID'
     AND coalesce(u.nicht_oeffentlich,false) = false
     AND coalesce(nullif(btrim(u."displayName"),''),'') <> ''
   LIMIT 1;

  IF v_mitglied IS NOT NULL THEN
    UPDATE public.users SET nicht_oeffentlich = true WHERE id = v_mitglied;
    v_erg := public.beitragsstand_oeffentlich(2026);
    IF v_erg::text LIKE '%' || v_name || '%' THEN
      RAISE EXCEPTION 'Der Widerspruch von % wurde uebergangen.', v_name;
    END IF;
    IF jsonb_array_length(v_erg->'zeilen') <> v_zeilen - 1 THEN
      RAISE EXCEPTION 'Der Widerspruch hat nicht genau eine Zeile entfernt.';
    END IF;
    UPDATE public.users SET nicht_oeffentlich = false WHERE id = v_mitglied;
  END IF;

  -- 4. Zurueck auf den vorherigen Stand. Diese Migration aendert keine
  --    Einstellung des Vereins -- die Entscheidung, Betraege zu zeigen,
  --    gehoert dem Verein und nicht mir.
  UPDATE public.settings SET system = system
         || jsonb_build_object('beitraegeOeffentlich', coalesce(v_alt,'AUS'))
   WHERE "tenantId" = v_verein AND id = 'system';

  PERFORM set_config('request.headers', '{}', true);

  IF coalesce((SELECT system ->> 'beitraegeOeffentlich' FROM public.settings
                WHERE "tenantId" = v_verein AND id = 'system'), 'AUS')
     IS DISTINCT FROM coalesce(v_alt, 'AUS') THEN
    RAISE EXCEPTION 'Die Einstellung des Vereins wurde nicht wiederhergestellt.';
  END IF;

  RAISE NOTICE 'Stellung BETRAEGE bereit: Namen mit erhaltenen Betraegen, '
               'Widerspruch gewinnt, Einstellung unveraendert auf %',
               coalesce(v_alt,'AUS');
END $$;
