-- Welche Adressen benutzt der Versand nach aussen?
--
-- Die Frage entsteht, weil Brevo nur das Freigeben einzelner Adressen
-- anbietet. Sie laesst sich aber nicht in einem Aufruf beantworten, und
-- genau dieser Irrtum stand schon in einer Meldung:
--
--   Sechs Messungen in EINEM Aufruf ergaben sechs Mal dieselbe Adresse,
--   und die Meldung schloss daraus "Freigeben ist aussichtsreich".
--   Vier Aufrufe ergaben dann vier verschiedene Adressen, in drei
--   verschiedenen Bereichen (16.62.x, 16.63.x, 51.34.x). Die Adresse
--   ist je Behaelter fest, nicht je Plattform -- und ein Behaelter lebt
--   Minuten.
--
-- Eine Messung, die nur in den eigenen Aufruf sieht, kann das nicht
-- erkennen. Darum wird hier mitgeschrieben: jede Pruefung legt die
-- gesehene Adresse ab, und das Urteil entsteht aus dem Gesammelten.
--
-- Es stehen nur eigene Absenderadressen darin. Keine Empfaengerdaten,
-- kein Schluessel.

CREATE TABLE IF NOT EXISTS public.versand_herkunft (
  ip          text PRIMARY KEY,
  art         text NOT NULL DEFAULT 'ipv4',
  zuerst      timestamptz NOT NULL DEFAULT now(),
  zuletzt     timestamptz NOT NULL DEFAULT now(),
  anzahl      integer NOT NULL DEFAULT 1
);

COMMENT ON TABLE public.versand_herkunft IS
  'Von aussen gesehene Absenderadressen der Edge Functions. Dient der '
  'Frage, ob eine IP-Freigabe beim Versanddienst tragen kann. '
  'Enthaelt keine Empfaengerdaten.';

ALTER TABLE public.versand_herkunft ENABLE ROW LEVEL SECURITY;

-- Nur der Betreiber liest das. Fuer einen Verein ist es belanglos, und
-- eine Tabelle ohne Leseregel waere fuer alle offen, sobald jemand
-- spaeter eine allgemeine Regel hinzufuegt.
DROP POLICY IF EXISTS herkunft_lesen ON public.versand_herkunft;
CREATE POLICY herkunft_lesen ON public.versand_herkunft
  FOR SELECT TO authenticated USING (public.is_platform_admin());

REVOKE ALL ON TABLE public.versand_herkunft FROM anon, authenticated;
GRANT SELECT ON TABLE public.versand_herkunft TO authenticated;


-- Eine Adresse vermerken und das Gesammelte zurueckgeben.
--
-- Nur service_role: das schreibt die Edge Function, und sonst niemand.
-- Waere es fuer angemeldete Konten offen, koennte jeder die Messung mit
-- erfundenen Adressen fuellen -- und die Entscheidung "freigeben oder
-- nicht" haengt daran.
CREATE OR REPLACE FUNCTION public.herkunft_vermerken(p_ip text)
-- Die Ausgabespalten tragen bewusst ein Vorsatzzeichen. RETURNS TABLE
-- legt fuer jeden Namen eine Variable an; hiesse eine davon "ip", waere
-- in INSERT ... ON CONFLICT (ip) nicht mehr entscheidbar, ob die Spalte
-- oder die Variable gemeint ist, und PostgreSQL bricht ab. Der
-- Selbsttest hat genau das gemeldet, bevor die Funktion in Gebrauch war.
RETURNS TABLE (r_ip text, r_anzahl integer, r_zuerst timestamptz, r_zuletzt timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF p_ip IS NULL OR btrim(p_ip) = '' THEN
    RAISE EXCEPTION 'Keine Adresse uebergeben.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.versand_herkunft AS v (ip, art)
       VALUES (btrim(p_ip), CASE WHEN p_ip LIKE '%:%' THEN 'ipv6' ELSE 'ipv4' END)
  ON CONFLICT (ip) DO UPDATE
     SET zuletzt = now(), anzahl = v.anzahl + 1;

  RETURN QUERY
    SELECT v.ip, v.anzahl, v.zuerst, v.zuletzt
      FROM public.versand_herkunft v
     WHERE v.art = (CASE WHEN p_ip LIKE '%:%' THEN 'ipv6' ELSE 'ipv4' END)
     ORDER BY v.zuletzt DESC;
END $$;

REVOKE ALL ON FUNCTION public.herkunft_vermerken(text) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.herkunft_vermerken(text) TO service_role;


-- ---------------------------------------------------------- Selbsttest
--
-- Prueft die eigene Wirkung, nicht den Weltzustand: die Migration lief
-- schon einmal, wenn Adressen drinstehen, und darf dann nicht abbrechen.
-- Vier Migrationen sind an genau diesem Fehler beim Wiederholen
-- gescheitert.
DO $$
DECLARE v_vorher int; v_nachher int; v_zeilen int;
BEGIN
  SELECT count(*) INTO v_vorher FROM public.versand_herkunft;

  PERFORM public.herkunft_vermerken('203.0.113.7');   -- Dokumentationsbereich
  PERFORM public.herkunft_vermerken('203.0.113.7');   -- zweimal: zaehlt hoch
  SELECT anzahl INTO v_zeilen FROM public.versand_herkunft WHERE ip = '203.0.113.7';
  IF v_zeilen < 2 THEN
    RAISE EXCEPTION 'Der zweite Besuch wurde nicht gezaehlt (anzahl=%).', v_zeilen;
  END IF;

  -- Die Unterscheidung v4/v6 muss greifen, sonst mischt das Urteil
  -- zwanzig IPv6-Adressen in die IPv4-Frage und nichts traegt mehr.
  PERFORM public.herkunft_vermerken('2001:db8::1');
  IF (SELECT art FROM public.versand_herkunft WHERE ip = '2001:db8::1') <> 'ipv6' THEN
    RAISE EXCEPTION 'IPv6 wurde nicht als solche erkannt.';
  END IF;

  DELETE FROM public.versand_herkunft WHERE ip IN ('203.0.113.7','2001:db8::1');
  SELECT count(*) INTO v_nachher FROM public.versand_herkunft;
  IF v_nachher <> v_vorher THEN
    RAISE EXCEPTION 'Der Selbsttest hat % Zeile(n) hinterlassen.', v_nachher - v_vorher;
  END IF;

  -- Und die Schranke: angemeldete Konten duerfen nicht schreiben.
  IF has_function_privilege('authenticated',
       'public.herkunft_vermerken(text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'authenticated darf die Messung fuellen -- damit waere sie '
                    'faelschbar, und an ihr haengt die Freigabeentscheidung.';
  END IF;

  RAISE NOTICE 'Herkunftsmessung bereit, Selbsttest ohne Rueckstand.';
END $$;
