-- Ausfluege gehoeren ins Heft und auf die oeffentliche Seite -- mit ihrem
-- Ziel. "14:00 Besuch im Dorfmuseum" ohne das Ziel waere auf dem Papier
-- kaum weniger raetselhaft als ohne den Titel.
--
-- Beide Funktionen geben die Programmpunkte bisher ohne art und ziel
-- heraus. Ergaenzt, sonst nichts geaendert.

CREATE OR REPLACE FUNCTION public.treffen_heft_inhalt(p_treffen uuid)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT jsonb_build_object(
    'treffen', (SELECT jsonb_build_object('titel', t.titel, 'beschreibung', t.beschreibung,
                  'datum', t.datum, 'ende', t.ende, 'ort', t.ort, 'adresse', t.adresse)
                  FROM public.treffen t WHERE t.id = p_treffen),
    'vereine', (SELECT coalesce(jsonb_agg(v ORDER BY v->>'name'), '[]'::jsonb) FROM (
        SELECT jsonb_build_object(
          'name', coalesce(te.name, tn.name, te."tenantId"),
          'art', te.art,
          'leute', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                       'name', d.name, 'funktion', d.funktion, 'rolle', d.rolle,
                       'vorstellung', d.vorstellung, 'interessen', d.interessen)
                       ORDER BY d.rolle, d.name), '[]'::jsonb)
                      FROM public.treffen_delegation d
                     WHERE d.teilnehmer_id = te.id AND d.im_heft IS TRUE),
          'stille', (SELECT count(*) FROM public.treffen_delegation d
                      WHERE d.teilnehmer_id = te.id AND coalesce(d.im_heft,false) = false)
        ) AS v
        FROM public.treffen_teilnehmer te
        LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
       WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false)
    ) y),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'titel', p.titel,
                    'ort', p.ort, 'spur', p.spur,
                    'art', p.art, 'ziel', p.ziel, 'rueckkehr', p.rueckkehr)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = p_treffen AND p.freigegeben),
    'stimmen', (SELECT count(*) FROM public.treffen_delegation d
                  JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                 WHERE te.treffen_id = p_treffen AND d.im_heft IS TRUE),
    'gesamt', (SELECT count(*) FROM public.treffen_delegation d
                 JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                WHERE te.treffen_id = p_treffen AND coalesce(te.zugesagt,false))
  );
$$;
REVOKE ALL ON FUNCTION public.treffen_heft_inhalt(uuid) FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.treffen_oeffentlich()
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id', t.id, 'titel', t.titel, 'beschreibung', t.beschreibung,
    'datum', t.datum, 'ende', t.ende, 'beginn', t.beginn,
    'ort', t.ort, 'adresse', t.adresse,
    'anmeldeschluss', t.anmeldeschluss,
    'preis_art', t.preis_art, 'preis_betrag', t.preis_betrag, 'waehrung', t.waehrung,
    'vereine', (SELECT coalesce(jsonb_agg(coalesce(te.name, tn.name) ORDER BY coalesce(te.name, tn.name)), '[]'::jsonb)
                  FROM public.treffen_teilnehmer te
                  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                 WHERE te.treffen_id = t.id AND te.art IN ('VEREIN','GASTVEREIN')
                   AND coalesce(te.zugesagt,false)),
    'programm', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                    'tag', p.tag, 'beginn', p.beginn, 'dauer_min', p.dauer_min,
                    'titel', p.titel, 'ort', p.ort, 'verantwortlich', p.verantwortlich,
                    'spur', p.spur, 'fuer', p.fuer,
                    'art', p.art, 'ziel', p.ziel, 'rueckkehr', p.rueckkehr)
                    ORDER BY p.tag NULLS FIRST, p.beginn, p.reihenfolge), '[]'::jsonb)
                   FROM public.treffen_programm p
                  WHERE p.treffen_id = t.id AND p.freigegeben)
    ) ORDER BY t.datum), '[]'::jsonb)
  FROM public.treffen t
 WHERE t.status = 'OEFFENTLICH' AND coalesce(t.ende, t.datum) >= current_date - 1;
$$;
REVOKE ALL ON FUNCTION public.treffen_oeffentlich() FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_oeffentlich() TO anon, authenticated;
