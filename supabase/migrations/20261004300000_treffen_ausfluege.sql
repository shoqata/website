-- Ausfluege im Programm.
--
-- Ein Ausflug ist kein gewoehnlicher Programmpunkt. Er hat ein Ziel, das
-- nicht der Veranstaltungsort ist, einen Treffpunkt, eine Anreise -- und
-- vor allem: nicht alle gehen mit. Das heisst Anmeldung, und wenn der
-- Bus vierzig Plaetze hat, muss bei vierzig Schluss sein.
--
-- Die Platzgrenze steht deshalb HIER und nicht in der Oberflaeche. Eine
-- Maske laesst sich umgehen, und zwei Leute, die gleichzeitig auf den
-- letzten Platz klicken, bekommen ihn sonst beide.

ALTER TABLE public.treffen_programm
  ADD COLUMN IF NOT EXISTS art        text NOT NULL DEFAULT 'PUNKT'
    CHECK (art IN ('PUNKT','AUSFLUG')),
  ADD COLUMN IF NOT EXISTS ziel       text,     -- wohin es geht
  ADD COLUMN IF NOT EXISTS treffpunkt text,     -- wo man sich sammelt
  ADD COLUMN IF NOT EXISTS anreise    text,     -- Bus, zu Fuss, eigene Anreise
  ADD COLUMN IF NOT EXISTS rueckkehr  time,     -- wann man zurueck ist
  ADD COLUMN IF NOT EXISTS plaetze    int CHECK (plaetze IS NULL OR plaetze > 0),
  ADD COLUMN IF NOT EXISTS kosten     numeric(10,2) DEFAULT 0 CHECK (kosten >= 0);

-- Ein Punkt ohne Ziel ist kein Ausflug.
ALTER TABLE public.treffen_programm DROP CONSTRAINT IF EXISTS treffen_programm_ausflug_hat_ziel;
ALTER TABLE public.treffen_programm ADD CONSTRAINT treffen_programm_ausflug_hat_ziel
  CHECK (art <> 'AUSFLUG' OR coalesce(btrim(ziel),'') <> '');


CREATE TABLE IF NOT EXISTS public.treffen_ausflug_anmeldung (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  programm_id   uuid NOT NULL REFERENCES public.treffen_programm(id) ON DELETE CASCADE,
  delegation_id uuid NOT NULL REFERENCES public.treffen_delegation(id) ON DELETE CASCADE,
  angemeldet_am timestamptz NOT NULL DEFAULT now(),
  -- Dieselbe Person nicht zweimal auf denselben Ausflug.
  CONSTRAINT ausflug_person_einmal UNIQUE (programm_id, delegation_id)
);
CREATE INDEX IF NOT EXISTS ausflug_anmeldung_programm
  ON public.treffen_ausflug_anmeldung (programm_id);

ALTER TABLE public.treffen_ausflug_anmeldung ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ausflug_betreiber ON public.treffen_ausflug_anmeldung;
CREATE POLICY ausflug_betreiber ON public.treffen_ausflug_anmeldung FOR ALL TO authenticated
  USING (public.is_platform_admin()) WITH CHECK (public.is_platform_admin());

-- Ein Verein sieht die Anmeldungen seiner EIGENEN Leute.
DROP POLICY IF EXISTS ausflug_eigene ON public.treffen_ausflug_anmeldung;
CREATE POLICY ausflug_eigene ON public.treffen_ausflug_anmeldung FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.treffen_delegation d
                   JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                  WHERE d.id = delegation_id AND te.art = 'VEREIN'
                    AND te."tenantId" = public.current_tenant() AND public.is_staff()));

GRANT SELECT ON public.treffen_ausflug_anmeldung TO authenticated;


-- Die freien Plaetze. Eine Zahl, die an EINER Stelle entsteht -- sonst
-- steht in der Anmeldung etwas anderes als auf der Busliste.
CREATE OR REPLACE FUNCTION public.ausflug_plaetze_frei(p_programm uuid)
RETURNS int
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT CASE WHEN p.plaetze IS NULL THEN NULL
              ELSE greatest(0, p.plaetze -
                   (SELECT count(*) FROM public.treffen_ausflug_anmeldung a
                     WHERE a.programm_id = p.id)) END
    FROM public.treffen_programm p WHERE p.id = p_programm;
$$;
REVOKE ALL ON FUNCTION public.ausflug_plaetze_frei(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.ausflug_plaetze_frei(uuid) TO anon, authenticated;


-- An- und abmelden, ueber den persoenlichen Link.
--
-- Die Platzpruefung sperrt die Zeile des Ausflugs, bevor sie zaehlt.
-- Ohne das bekaemen zwei Leute, die gleichzeitig auf den letzten Platz
-- klicken, ihn beide -- und am Morgen stehen einundvierzig vor einem Bus
-- mit vierzig Sitzen.
CREATE OR REPLACE FUNCTION public.ausflug_anmelden(
  p_token text, p_programm uuid, p_dabei boolean)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE
  v_person uuid; v_bis date; v_treffen uuid;
  v_plaetze int; v_belegt int; v_art text;
BEGIN
  SELECT id, gueltig_bis INTO v_person, v_bis FROM public.treffen_delegation
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_person IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  -- Zeile sperren, dann zaehlen.
  SELECT art, plaetze, treffen_id INTO v_art, v_plaetze, v_treffen
    FROM public.treffen_programm WHERE id = p_programm FOR UPDATE;
  IF v_art IS NULL THEN RAISE EXCEPTION 'Programmpunkt nicht gefunden.'; END IF;
  IF v_art <> 'AUSFLUG' THEN RAISE EXCEPTION 'Dafuer gibt es keine Anmeldung.'; END IF;

  -- Der Ausflug muss zum selben Treffen gehoeren wie die Person. Ohne
  -- diese Pruefung koennte sich jemand mit seinem Link auf den Ausflug
  -- eines fremden Treffens setzen.
  IF NOT EXISTS (SELECT 1 FROM public.treffen_delegation d
                   JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                  WHERE d.id = v_person AND te.treffen_id = v_treffen) THEN
    RAISE EXCEPTION 'Dieser Ausflug gehoert zu einem anderen Treffen.'
      USING ERRCODE='insufficient_privilege';
  END IF;

  IF NOT p_dabei THEN
    DELETE FROM public.treffen_ausflug_anmeldung
     WHERE programm_id = p_programm AND delegation_id = v_person;
    RETURN jsonb_build_object('dabei', false,
      'frei', public.ausflug_plaetze_frei(p_programm));
  END IF;

  IF v_plaetze IS NOT NULL THEN
    SELECT count(*) INTO v_belegt FROM public.treffen_ausflug_anmeldung
     WHERE programm_id = p_programm AND delegation_id <> v_person;
    IF v_belegt >= v_plaetze THEN
      RAISE EXCEPTION 'Dieser Ausflug ist ausgebucht (% Plaetze).', v_plaetze;
    END IF;
  END IF;

  INSERT INTO public.treffen_ausflug_anmeldung (programm_id, delegation_id)
  VALUES (p_programm, v_person)
  ON CONFLICT (programm_id, delegation_id) DO NOTHING;

  RETURN jsonb_build_object('dabei', true, 'frei', public.ausflug_plaetze_frei(p_programm));
END $$;
REVOKE ALL ON FUNCTION public.ausflug_anmelden(text,uuid,boolean) FROM public;
GRANT EXECUTE ON FUNCTION public.ausflug_anmelden(text,uuid,boolean) TO anon, authenticated;


-- Welche Ausfluege es gibt und wo diese Person schon dabei ist.
CREATE OR REPLACE FUNCTION public.ausfluege_fuer(p_token text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_person uuid; v_treffen uuid; v_bis date;
BEGIN
  SELECT d.id, te.treffen_id, d.gueltig_bis INTO v_person, v_treffen, v_bis
    FROM public.treffen_delegation d
    JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
   WHERE d.token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');
  IF v_person IS NULL OR v_bis IS NULL OR v_bis < current_date THEN
    RAISE EXCEPTION 'Dieser Zugang ist nicht (mehr) gueltig.' USING ERRCODE='insufficient_privilege';
  END IF;

  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id, 'titel', p.titel, 'ziel', p.ziel, 'treffpunkt', p.treffpunkt,
      'anreise', p.anreise, 'beginn', p.beginn, 'rueckkehr', p.rueckkehr,
      'plaetze', p.plaetze, 'kosten', p.kosten,
      'frei', public.ausflug_plaetze_frei(p.id),
      'dabei', EXISTS (SELECT 1 FROM public.treffen_ausflug_anmeldung a
                        WHERE a.programm_id = p.id AND a.delegation_id = v_person))
      ORDER BY p.tag NULLS FIRST, p.beginn), '[]'::jsonb)
    FROM public.treffen_programm p
   WHERE p.treffen_id = v_treffen AND p.art = 'AUSFLUG' AND p.freigegeben);
END $$;
REVOKE ALL ON FUNCTION public.ausfluege_fuer(text) FROM public;
GRANT EXECUTE ON FUNCTION public.ausfluege_fuer(text) TO anon, authenticated;


-- Die Busliste fuer den Gastgeber: wer faehrt wohin mit.
CREATE OR REPLACE FUNCTION public.treffen_ausflugslisten(p_treffen uuid)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Gastgeber.' USING ERRCODE='insufficient_privilege';
  END IF;
  RETURN (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id, 'titel', p.titel, 'ziel', p.ziel, 'treffpunkt', p.treffpunkt,
      'anreise', p.anreise, 'beginn', p.beginn, 'rueckkehr', p.rueckkehr,
      'plaetze', p.plaetze, 'kosten', p.kosten,
      'angemeldet', (SELECT count(*) FROM public.treffen_ausflug_anmeldung a
                      WHERE a.programm_id = p.id),
      'frei', public.ausflug_plaetze_frei(p.id),
      'leute', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                   'name', d.name,
                   'verein', coalesce(te.name, tn.name, te."tenantId"))
                   ORDER BY coalesce(te.name, tn.name, te."tenantId"), d.name), '[]'::jsonb)
                  FROM public.treffen_ausflug_anmeldung a
                  JOIN public.treffen_delegation d ON d.id = a.delegation_id
                  JOIN public.treffen_teilnehmer te ON te.id = d.teilnehmer_id
                  LEFT JOIN public.tenants tn ON tn.id = te."tenantId"
                 WHERE a.programm_id = p.id))
      ORDER BY p.tag NULLS FIRST, p.beginn), '[]'::jsonb)
    FROM public.treffen_programm p
   WHERE p.treffen_id = p_treffen AND p.art = 'AUSFLUG');
END $$;
REVOKE ALL ON FUNCTION public.treffen_ausflugslisten(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.treffen_ausflugslisten(uuid) TO authenticated;
