-- Likes fuer Neuigkeiten. Keine Kommentare: die muesste jemand lesen und
-- pflegen, und ein Verein hat dafuer niemanden. Ein Like sagt "gesehen,
-- gefreut" -- mehr braucht eine Vereinsnachricht nicht.
--
-- Besucher sind meist nicht angemeldet. Darum zaehlt ein Like je Browser:
-- die Seite erzeugt eine zufaellige Kennung und merkt sie sich. Wer den
-- Speicher loescht, kann noch einmal liken -- fuer eine Freudenanzeige ist
-- das hinnehmbar; eine Anmeldepflicht waere es nicht.
--
-- Kein Lese- und kein Schreibrecht auf die Tabelle: die Kennungen der
-- Besucher bleiben in der Datenbank. Nach aussen gehen nur Zahlen.

CREATE TABLE IF NOT EXISTS public.news_likes (
  "tenantId" text NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  news       text NOT NULL REFERENCES public.news(id) ON DELETE CASCADE,
  besucher   uuid NOT NULL,
  am         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (news, besucher)
);
CREATE INDEX IF NOT EXISTS news_likes_besucher ON public.news_likes (besucher, am);
ALTER TABLE public.news_likes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.news_likes FROM anon, authenticated, public;

-- Der Verein dieses Aufrufs: angemeldet der eigene, sonst der der Domain.
CREATE OR REPLACE FUNCTION public._news_verein()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT coalesce(public.current_tenant(), public.request_tenant());
$$;
REVOKE ALL ON FUNCTION public._news_verein() FROM public, anon, authenticated;

-- Zahlen fuer mehrere Nachrichten auf einmal (Liste) -- und ob dieser
-- Besucher schon geliked hat.
CREATE OR REPLACE FUNCTION public.news_likes_lesen(p_ids text[], p_besucher uuid)
RETURNS TABLE (news text, anzahl int, gelikt boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT n.id,
         (SELECT count(*)::int FROM public.news_likes l WHERE l.news = n.id),
         EXISTS (SELECT 1 FROM public.news_likes l WHERE l.news = n.id AND l.besucher = p_besucher)
    FROM public.news n
   WHERE n.id = ANY (coalesce(p_ids, ARRAY[]::text[]))
     AND n."tenantId" = public._news_verein()
     AND n.status = 'PUBLISHED';
$$;
REVOKE ALL ON FUNCTION public.news_likes_lesen(text[], uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.news_likes_lesen(text[], uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.news_like_umschalten(p_news text, p_besucher uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_verein text := public._news_verein(); v_n int; v_gelikt boolean;
BEGIN
  IF p_besucher IS NULL THEN
    RAISE EXCEPTION 'Ohne Kennung kein Like.' USING ERRCODE = 'check_violation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.news n WHERE n.id = p_news AND n."tenantId" = v_verein
                   AND n.status = 'PUBLISHED' AND (n."publishAt" IS NULL OR n."publishAt" <= now())) THEN
    RAISE EXCEPTION 'Diese Nachricht gibt es nicht.' USING ERRCODE = 'check_violation';
  END IF;

  IF EXISTS (SELECT 1 FROM public.news_likes WHERE news = p_news AND besucher = p_besucher) THEN
    DELETE FROM public.news_likes WHERE news = p_news AND besucher = p_besucher;
    v_gelikt := false;
  ELSE
    -- Eine Bremse gegen Skripte: 60 Likes je Kennung und Stunde reichen
    -- jedem Menschen.
    IF (SELECT count(*) FROM public.news_likes WHERE besucher = p_besucher
          AND am > now() - interval '1 hour') >= 60 THEN
      RAISE EXCEPTION 'Zu viele Likes in kurzer Zeit.' USING ERRCODE = 'check_violation';
    END IF;
    INSERT INTO public.news_likes ("tenantId", news, besucher) VALUES (v_verein, p_news, p_besucher);
    v_gelikt := true;
  END IF;
  SELECT count(*) INTO v_n FROM public.news_likes WHERE news = p_news;
  RETURN jsonb_build_object('anzahl', v_n, 'gelikt', v_gelikt);
END $$;
REVOKE ALL ON FUNCTION public.news_like_umschalten(text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.news_like_umschalten(text, uuid) TO anon, authenticated;

-- Fuer die Verwaltung: Likes je Nachricht, auch fuer Entwuerfe (0).
CREATE OR REPLACE FUNCTION public.news_likes_verwaltung()
RETURNS TABLE (news text, anzahl int)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT l.news, count(*)::int FROM public.news_likes l
   WHERE l."tenantId" = public.current_tenant() AND public.is_staff()
   GROUP BY l.news;
$$;
REVOKE ALL ON FUNCTION public.news_likes_verwaltung() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.news_likes_verwaltung() TO authenticated;

DO $$
BEGIN
  IF has_table_privilege('anon', 'public.news_likes', 'SELECT')
     OR has_table_privilege('authenticated', 'public.news_likes', 'INSERT') THEN
    RAISE EXCEPTION 'Selbsttest: news_likes direkt zugaenglich';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
