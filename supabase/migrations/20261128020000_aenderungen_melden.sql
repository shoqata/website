-- Mitglieder melden Aenderungen, der Vorstand uebernimmt sie mit einem Klick.
--
-- Arten:
--   ADRESSE    neue Strasse/PLZ/Ort/Land -- Uebernehmen schreibt sie ins Mitglied
--   FAMILIE    Geburt, Heirat, Verwandte -- Uebernehmen markiert nur erledigt;
--              eingetragen wird im Stammbaum (dort weiss ein Mensch, wer wer ist)
--   SONSTIGES  freier Text
--
-- Gelesen wird ueber Funktionen, nicht direkt: das Mitglied sieht seine
-- eigenen Meldungen, die Verwaltung und der Vorstand alle des Vereins.

CREATE TABLE IF NOT EXISTS public.mitglied_aenderungen (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"    text NOT NULL,
  mitglied      text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  art           text NOT NULL CHECK (art IN ('ADRESSE','FAMILIE','SONSTIGES')),
  daten         jsonb NOT NULL DEFAULT '{}',
  status        text NOT NULL DEFAULT 'OFFEN' CHECK (status IN ('OFFEN','UEBERNOMMEN','ABGELEHNT')),
  erstellt_am   timestamptz NOT NULL DEFAULT now(),
  entschieden_am timestamptz,
  entschieden_von text,
  notiz         text
);
CREATE INDEX IF NOT EXISTS mitglied_aenderungen_verein ON public.mitglied_aenderungen ("tenantId", status, erstellt_am DESC);
ALTER TABLE public.mitglied_aenderungen ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.mitglied_aenderungen FROM anon, authenticated, public;

CREATE OR REPLACE FUNCTION public.aenderung_melden(p_art text, p_daten jsonb)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_ich text := public.current_user_row_id();
  v_verein text := public.current_tenant();
  v_id uuid;
  v_text text;
BEGIN
  IF v_ich IS NULL OR v_verein IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF p_art NOT IN ('ADRESSE','FAMILIE','SONSTIGES') OR jsonb_typeof(coalesce(p_daten,'{}')) <> 'object'
     OR length(p_daten::text) > 4000 THEN
    RAISE EXCEPTION 'Ungueltige Meldung.' USING ERRCODE = 'check_violation';
  END IF;
  IF p_art = 'ADRESSE' AND coalesce(btrim(p_daten->>'street'),'') = '' THEN
    RAISE EXCEPTION 'Bitte die neue Strasse angeben.' USING ERRCODE = 'check_violation';
  END IF;
  v_text := btrim(coalesce(p_daten->>'text',''));
  IF p_art <> 'ADRESSE' AND v_text = '' THEN
    RAISE EXCEPTION 'Bitte kurz beschreiben, was sich geaendert hat.' USING ERRCODE = 'check_violation';
  END IF;
  -- Gegen Fluten: hoechstens 10 offene Meldungen je Mitglied.
  IF (SELECT count(*) FROM public.mitglied_aenderungen WHERE mitglied = v_ich AND status = 'OFFEN') >= 10 THEN
    RAISE EXCEPTION 'Es sind schon viele Meldungen offen. Bitte warten Sie, bis der Vorstand sie bearbeitet hat.' USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.mitglied_aenderungen ("tenantId", mitglied, art, daten)
  VALUES (v_verein, v_ich, p_art, p_daten) RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- Eigene Meldungen (Mitglied) bzw. alle des Vereins (Verwaltung/Vorstand).
CREATE OR REPLACE FUNCTION public.aenderungen_lesen(p_alle boolean DEFAULT false)
RETURNS TABLE (id uuid, mitglied text, name text, art text, daten jsonb, status text,
               erstellt_am timestamptz, entschieden_am timestamptz, notiz text,
               bisher jsonb)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id, a.mitglied, u."displayName", a.art, a.daten, a.status, a.erstellt_am, a.entschieden_am, a.notiz,
         CASE WHEN p_alle THEN jsonb_build_object('street', u.street, 'zip', u.zip, 'city', u.city, 'country', u.country) END
    FROM public.mitglied_aenderungen a
    JOIN public.users u ON u.id = a.mitglied
   WHERE a."tenantId" = public.current_tenant()
     AND CASE WHEN p_alle THEN public.is_member_manager() ELSE a.mitglied = public.current_user_row_id() END
   ORDER BY (a.status = 'OFFEN') DESC, a.erstellt_am DESC
   LIMIT 200;
$$;

CREATE OR REPLACE FUNCTION public.aenderung_entscheiden(p_id uuid, p_uebernehmen boolean, p_notiz text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE a public.mitglied_aenderungen; v_wer text;
BEGIN
  IF NOT public.is_member_manager() OR NOT public.darf_schreiben() THEN
    RAISE EXCEPTION 'Nur Verwaltung und Vorstand.' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT * INTO a FROM public.mitglied_aenderungen
   WHERE id = p_id AND "tenantId" = public.current_tenant() FOR UPDATE;
  IF a.id IS NULL THEN RAISE EXCEPTION 'Meldung nicht gefunden.'; END IF;
  IF a.status <> 'OFFEN' THEN RAISE EXCEPTION 'Diese Meldung ist schon bearbeitet.'; END IF;

  IF p_uebernehmen AND a.art = 'ADRESSE' THEN
    UPDATE public.users SET
      street  = coalesce(nullif(btrim(a.daten->>'street'),''), street),
      zip     = coalesce(nullif(btrim(a.daten->>'zip'),''), zip),
      city    = coalesce(nullif(btrim(a.daten->>'city'),''), city),
      country = coalesce(nullif(btrim(a.daten->>'country'),''), country)
    WHERE id = a.mitglied AND "tenantId" = a."tenantId";
  END IF;

  SELECT u."displayName" INTO v_wer FROM public.users u WHERE u.id = public.current_user_row_id();
  UPDATE public.mitglied_aenderungen SET
    status = CASE WHEN p_uebernehmen THEN 'UEBERNOMMEN' ELSE 'ABGELEHNT' END,
    entschieden_am = now(), entschieden_von = v_wer, notiz = nullif(btrim(coalesce(p_notiz,'')), '')
  WHERE id = a.id;
END $$;

REVOKE ALL ON FUNCTION public.aenderung_melden(text, jsonb) FROM public, anon;
REVOKE ALL ON FUNCTION public.aenderungen_lesen(boolean) FROM public, anon;
REVOKE ALL ON FUNCTION public.aenderung_entscheiden(uuid, boolean, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.aenderung_melden(text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.aenderungen_lesen(boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.aenderung_entscheiden(uuid, boolean, text) TO authenticated;

DO $$
DECLARE v_eigen text := current_user; v_ok boolean;
BEGIN
  SET LOCAL ROLE authenticated;
  BEGIN PERFORM 1 FROM public.mitglied_aenderungen; v_ok := false;
  EXCEPTION WHEN insufficient_privilege THEN v_ok := true; END;
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF NOT v_ok THEN RAISE EXCEPTION 'mitglied_aenderungen direkt lesbar'; END IF;
END $$;

NOTIFY pgrst, 'reload schema';
