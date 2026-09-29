-- Eine Spende einem Aufruf zuordnen.
--
-- Bewusst als eigener kleiner Schritt und nicht als zusaetzlicher Parameter
-- von spende_anlegen: deren lebender Rumpf weicht von der aeltesten
-- Migrationsdatei ab (sie gibt inzwischen auch die Referenzart zurueck), und
-- eine Funktion neu zu schreiben, die Geld und Pruefziffern berechnet, nur um
-- eine Spalte zu fuellen, waere ein schlechter Handel.
--
-- Aufrufbar ist sie auch fuer nicht angemeldete Spender -- sonst koennte die
-- oeffentliche Spendenseite nicht zuordnen. Deshalb eng gefasst:
--   * die Spende muss zum Verein der aufrufenden Adresse gehoeren
--   * sie muss noch offen und frisch sein (10 Minuten)
--   * sie darf noch keinen Aufruf tragen
--   * der Aufruf muss zum selben Verein gehoeren und oeffentlich sein
-- Damit laesst sich hoechstens die eigene, gerade angelegte Spende einordnen.
CREATE OR REPLACE FUNCTION public.spende_aufruf_zuordnen(p_spende uuid, p_aufruf text)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := coalesce(public.current_tenant(), public.request_tenant());
        v_n int;
BEGIN
  IF v_verein IS NULL THEN RETURN false; END IF;

  UPDATE public.donations d
     SET aufruf = p_aufruf
   WHERE d.id = p_spende
     AND d."tenantId" = v_verein
     AND d.status = 'OFFEN'
     AND d.aufruf IS NULL
     AND d.erfasst_am > now() - interval '10 minutes'
     AND EXISTS (SELECT 1 FROM public.spendenaufrufe a
                  WHERE a.id = p_aufruf AND a."tenantId" = v_verein
                    AND a.status = 'OEFFENTLICH');
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END $$;
REVOKE ALL ON FUNCTION public.spende_aufruf_zuordnen(uuid, text) FROM public;
GRANT EXECUTE ON FUNCTION public.spende_aufruf_zuordnen(uuid, text) TO anon, authenticated;

-- Gegenprobe: ein Probeaufruf, eine Spende dazu, und die Versuche, die
-- scheitern muessen.
DO $$
DECLARE v_back text := current_user; r record; v_id uuid; v_ok boolean; v_n int;
BEGIN
  INSERT INTO public.spendenaufrufe (id, "tenantId", titel, text, ziel_betrag, status, erstellt_von)
  VALUES ('probe-aufruf','koretini','Probeaufruf','nur zum Pruefen', 1000, 'OEFFENTLICH','system')
  ON CONFLICT (id) DO UPDATE SET status='OEFFENTLICH';

  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);

  EXECUTE 'SET ROLE anon';
  SELECT * INTO r FROM public.spende_anlegen(
    80,'CHF','Probe Spender','probe2@example.org','Weg 1','8000','Zürich','CH',NULL,NULL,false);
  v_id := r.id;
  v_ok := public.spende_aufruf_zuordnen(v_id, 'probe-aufruf');
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '1. eigene frische Spende zuordnen: %', v_ok;

  EXECUTE 'SET ROLE anon';
  v_ok := public.spende_aufruf_zuordnen(v_id, 'probe-aufruf');
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '2. dieselbe noch einmal: % (erwartet f)', v_ok;

  -- Eine aeltere Spende
  UPDATE public.donations SET erfasst_am = now() - interval '2 hours', aufruf = NULL
   WHERE id = v_id;
  EXECUTE 'SET ROLE anon';
  v_ok := public.spende_aufruf_zuordnen(v_id, 'probe-aufruf');
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '3. zwei Stunden alt: % (erwartet f)', v_ok;

  -- Der Stand des Aufrufs, solange nichts bezahlt ist
  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  FOR r IN SELECT titel, gesammelt, anzahl FROM public.spendenaufrufe_oeffentlich() LOOP
    RAISE NOTICE '4. oeffentlich sichtbar: % | gesammelt % | % Spenden', r.titel, r.gesammelt, r.anzahl;
  END LOOP;
  EXECUTE format('SET ROLE %I', v_back);

  DELETE FROM public.donations WHERE email='probe2@example.org';
  DELETE FROM public.spendenaufrufe WHERE id='probe-aufruf';
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '5. aufgeraeumt.';
END $$;
