-- Der Community-Puls fuer gewoehnliche Mitglieder.
--
-- Gemessen: die Zeilenregel auf users gibt einem Mitglied ohne Verantwortung
-- nur die eigene Zeile heraus. Die Ansicht zaehlte genau diese Zeilen -- der
-- Puls stand deshalb auf 1 von 1, obwohl die Nachbarschaft 41 Mitglieder hat.
--
-- Die Regel ist richtig so: wer nicht Vorstand, Verwaltung oder
-- verantwortliche Person ist, hat die Datensaetze seiner Nachbarn nicht zu
-- sehen. Falsch war, eine Gemeinschaftskennzahl aus Datensaetzen zu rechnen,
-- die es gar nicht zu sehen gibt.
--
-- Deshalb rechnet der Server. Herausgegeben werden ausschliesslich Zahlen --
-- wie viele bezahlt haben, wie viele offen sind. Wer bezahlt hat, steht
-- nicht darin; das bleibt der Verwaltung und der verantwortlichen Person
-- vorbehalten, die die Datensaetze ohnehin sehen duerfen.
CREATE OR REPLACE FUNCTION public.nachbarschaft_puls(p_jahr integer DEFAULT NULL)
RETURNS TABLE (
  nachbarschaft text, name text,
  mitglieder bigint, aktiv bigint,
  bezahlt bigint, offen bigint, ohne_rechnung bigint, jahr integer
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id();
        v_lagje text; v_verein text := public.current_tenant(); v_jahr integer;
BEGIN
  IF v_ich IS NULL THEN
    RAISE EXCEPTION 'Nicht angemeldet.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT u."neighborhoodId" INTO v_lagje FROM public.users u WHERE u.id = v_ich;
  IF v_lagje IS NULL THEN RETURN; END IF;   -- ohne Nachbarschaft kein Puls

  v_jahr := coalesce(p_jahr, extract(year FROM current_date)::integer);

  RETURN QUERY
  WITH leute AS (
    SELECT u.id FROM public.users u
     WHERE u."neighborhoodId" = v_lagje
       AND u."tenantId" = v_verein
       AND coalesce(u."membershipStatus",'') <> 'INACTIVE'
  ),
  -- Derselbe Massstab wie in lib/memberQuality.ts: massgeblich ist
  -- billingYear, ersatzweise das Jahr des Zeitstempels. Eine Rechnung gilt
  -- als bezahlt, sobald irgendeine Zahlung des Jahres auf PAID steht.
  stand AS (
    SELECT l.id,
           bool_or(p.status = 'PAID') AS hat_bezahlt,
           count(p.id) AS rechnungen
      FROM leute l
      LEFT JOIN public.payments p
        ON p."userId" = l.id
       AND coalesce(
             nullif(p."billingYear", 0),
             extract(year FROM p."timestamp")::integer
           ) = v_jahr
     GROUP BY l.id
  )
  SELECT v_lagje, n.name,
         (SELECT count(*) FROM leute),
         (SELECT count(*) FROM public.users u
           WHERE u."neighborhoodId" = v_lagje AND u."tenantId" = v_verein
             AND u."membershipStatus" = 'ACTIVE'),
         count(*) FILTER (WHERE s.hat_bezahlt),
         count(*) FILTER (WHERE s.rechnungen > 0 AND NOT s.hat_bezahlt),
         count(*) FILTER (WHERE s.rechnungen = 0),
         v_jahr
    FROM stand s
    LEFT JOIN public.neighborhoods n ON n.id = v_lagje
   GROUP BY n.name;
END $$;

REVOKE ALL ON FUNCTION public.nachbarschaft_puls(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.nachbarschaft_puls(integer) TO authenticated;

DO $$ BEGIN RAISE NOTICE 'nachbarschaft_puls angelegt.'; END $$;
