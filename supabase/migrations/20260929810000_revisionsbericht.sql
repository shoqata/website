-- Alles, was eine Revisionsstelle braucht, in einer Abfrage.
--
-- Bisher liess sich nur ein Kontoauszug je Konto als CSV herunterladen.
-- Fuer eine Revision genuegt das nicht: sie braucht das vollstaendige
-- Journal, die Saldenliste, Bilanz und Erfolgsrechnung -- und vor allem
-- das Aenderungsprotokoll. Ohne dieses sind die Zahlen nicht pruefbar,
-- sondern nur behauptet.
--
-- Gerechnet wird in der Datenbank, nicht im Browser. Ein Bericht, den der
-- Browser aus vorgefilterten Daten zusammenstellt, zeigt am Ende das, was
-- die Oberflaeche ohnehin zeigt -- und eine Revision will genau das nicht.

CREATE OR REPLACE FUNCTION public.revisionsbericht(p_jahr int)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_verein text := public.current_tenant();
  v_ergebnis jsonb;
BEGIN
  IF v_verein IS NULL THEN
    RAISE EXCEPTION 'Kein Verein erkannt.' USING ERRCODE='insufficient_privilege';
  END IF;
  IF NOT public.is_member_manager() THEN
    RAISE EXCEPTION 'Nur der Vorstand darf den Revisionsbericht abrufen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  WITH salden AS (
    SELECT a.code, a.name, a.class, a.category,
           coalesce(sum(j.amount) FILTER (WHERE j."debitCode"  = a.code), 0) AS soll,
           coalesce(sum(j.amount) FILTER (WHERE j."creditCode" = a.code), 0) AS haben
      FROM public.accounting_accounts a
      LEFT JOIN public.accounting_journal j
             ON j."tenantId" = a."tenantId"
            AND substr(j.date,1,4) = p_jahr::text
            AND (j."debitCode" = a.code OR j."creditCode" = a.code)
     WHERE a."tenantId" = v_verein
     GROUP BY a.code, a.name, a.class, a.category
  ), mit_saldo AS (
    SELECT *, CASE WHEN class IN ('ASSET','EXPENSE') THEN soll - haben
                   ELSE haben - soll END AS saldo
      FROM salden
  )
  SELECT jsonb_build_object(
    'verein',  (SELECT jsonb_build_object('id', t.id, 'name', t.name)
                  FROM public.tenants t WHERE t.id = v_verein),
    'jahr',    p_jahr,
    'erstellt', now(),
    'abschluss', (SELECT jsonb_build_object('status', f.status, 'geschlossen_am', f."closedAt",
                                            'ergebnis', f."netProfit")
                    FROM public.fiscal_years f
                   WHERE f."tenantId" = v_verein AND f.year = p_jahr),

    'saldenliste', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                      'konto', code, 'name', name, 'klasse', class, 'gruppe', category,
                      'soll', round(soll,2), 'haben', round(haben,2), 'saldo', round(saldo,2))
                      ORDER BY code), '[]'::jsonb) FROM mit_saldo),

    'bilanz', (SELECT jsonb_build_object(
                 'aktiven',  round(coalesce(sum(saldo) FILTER (WHERE class='ASSET'),0),2),
                 'passiven', round(coalesce(sum(saldo) FILTER (WHERE class='LIABILITY'),0),2))
                 FROM mit_saldo),

    'erfolgsrechnung', (SELECT jsonb_build_object(
                 'ertrag',  round(coalesce(sum(saldo) FILTER (WHERE class='REVENUE'),0),2),
                 'aufwand', round(coalesce(sum(saldo) FILTER (WHERE class='EXPENSE'),0),2),
                 'ergebnis', round(coalesce(sum(saldo) FILTER (WHERE class='REVENUE'),0)
                                 - coalesce(sum(saldo) FILTER (WHERE class='EXPENSE'),0),2))
                 FROM mit_saldo),

    'journal', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'beleg', j.belegnr, 'datum', j.date, 'text', j.description,
                  'soll', j."debitCode", 'haben', j."creditCode",
                  'betrag', round(j.amount,2),
                  'systembuchung', coalesce(j."isSystemEntry", false),
                  'erfasst_am', j."createdAt", 'bezug', j."referenceId")
                  ORDER BY j.belegnr), '[]'::jsonb)
                  FROM public.accounting_journal j
                 WHERE j."tenantId" = v_verein AND substr(j.date,1,4) = p_jahr::text),

    -- Das Herzstueck fuer die Revision: jede nachtraegliche Aenderung und
    -- jede Loeschung, mit Urheber und Zeitpunkt. Ohne diese Liste laesst
    -- sich nicht ausschliessen, dass im Januar gebuchte Zahlen im Juni
    -- anders lauteten.
    'aenderungen', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'wann', b.wann, 'vorgang', b.vorgang, 'buchung', b.buchung_id,
                  'wer', coalesce(b.wer_email, b.wer, 'unbekannt'),
                  'vorher', b.vorher, 'nachher', b.nachher)
                  ORDER BY b.wann), '[]'::jsonb)
                  FROM public.buchungsprotokoll b
                 WHERE b."tenantId" = v_verein
                   AND (substr(b.vorher->>'date',1,4) = p_jahr::text
                     OR substr(b.nachher->>'date',1,4) = p_jahr::text)),

    -- Die Aufraeumaktion vom 18.09.2026 steht in einer eigenen Tabelle.
    -- Sie gehoert in den Bericht, damit nichts verschwiegen ist.
    'frueher_entfernt', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                  'entfernt_am', ar.entfernt_am, 'grund', ar.grund, 'zeile', ar.zeile)
                  ORDER BY ar.entfernt_am), '[]'::jsonb)
                  FROM public.accounting_journal_archiv ar
                 WHERE ar."tenantId" = v_verein
                   AND substr(ar.zeile->>'date',1,4) = p_jahr::text)
  ) INTO v_ergebnis;

  RETURN v_ergebnis;
END $$;

REVOKE ALL ON FUNCTION public.revisionsbericht(int) FROM public;
GRANT EXECUTE ON FUNCTION public.revisionsbericht(int) TO authenticated;
