-- Geburtstagsgruesse.
--
-- Gemessen, bevor das gebaut wurde: von 350 Mitgliedern haben 17 ein
-- Geburtsdatum hinterlegt, und alle 17 haben auch eine brauchbare Adresse.
-- Mehr als 17 Gratulationen im Jahr sind also nicht moeglich -- etwa eine je
-- Monat. Das ist kein Grund, es nicht zu bauen, aber der Ertrag steigt erst
-- mit den Geburtsdaten.
--
-- Der Gruss wird in die Warteschlange gestellt, nicht unmittelbar verschickt.
-- So ist nachvollziehbar, was hinausging, und ein ausgefallener Versand holt
-- nach, statt den Tag zu verlieren.

CREATE OR REPLACE FUNCTION public.queue_birthday_greetings(p_day date DEFAULT NULL)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_tag   date := COALESCE(p_day, current_date);
  v_jahr  int  := EXTRACT(YEAR FROM v_tag)::int;
  v_n     int  := 0;
  r       record;
  v_anrede text;
  v_html  text;
BEGIN
  FOR r IN
    SELECT u.id, u."tenantId", u.email,
           COALESCE(NULLIF(btrim(u."firstName"), ''), u."displayName") AS name,
           t.name AS verein
      FROM public.users u
      LEFT JOIN public.tenants t ON t.id = u."tenantId"
     WHERE u.birthdate IS NOT NULL
       AND btrim(u.birthdate::text) <> ''
       AND EXTRACT(MONTH FROM u.birthdate::date) = EXTRACT(MONTH FROM v_tag)
       AND EXTRACT(DAY   FROM u.birthdate::date) = EXTRACT(DAY   FROM v_tag)
       -- Dieselbe Pruefung wie in der Anwendung: Platzhalter aus dem
       -- Altbestand gelten nicht als Adresse.
       AND u.email IS NOT NULL
       AND btrim(u.email) <> ''
       AND u.email NOT ILIKE '%@koretini.legacy'
       AND u.email NOT ILIKE '%no-email-%'
       AND u.email LIKE '%@%.%'
       AND COALESCE(u."membershipStatus", 'ACTIVE') <> 'INACTIVE'
  LOOP
    v_anrede := COALESCE(NULLIF(btrim(r.name), ''), 'mik i dashur');

    -- Zweisprachig, weil an den Mitgliedern keine Sprachwahl hinterlegt ist.
    -- Albanisch zuerst -- das ist die Sprache des Vereins.
    v_html :=
      '<div style="font-family:Georgia,serif;max-width:520px;margin:0 auto;padding:32px;color:#1c1917">'
      || '<p style="font-size:26px;font-weight:bold;margin:0 0 20px">Gëzuar ditëlindjen, ' || v_anrede || '!</p>'
      || '<p style="font-size:15px;line-height:1.7;margin:0 0 24px">'
      || 'Të urojmë shëndet, gëzim dhe shumë ditë të bukura. Faleminderit që je pjesë e '
      || COALESCE(r.verein, 'shoqatës sonë') || '.</p>'
      || '<hr style="border:none;border-top:1px solid #e7e5e4;margin:28px 0">'
      || '<p style="font-size:22px;font-weight:bold;margin:0 0 16px">Herzlichen Glückwunsch zum Geburtstag, ' || v_anrede || '!</p>'
      || '<p style="font-size:14px;line-height:1.7;color:#57534e;margin:0 0 24px">'
      || 'Wir wünschen dir Gesundheit, Freude und viele schöne Tage. Danke, dass du Teil von '
      || COALESCE(r.verein, 'unserem Verein') || ' bist.</p>'
      || '<p style="font-size:12px;color:#a8a29e;margin:32px 0 0">' || COALESCE(r.verein, '') || '</p>'
      || '</div>';

    BEGIN
      INSERT INTO public.mail_queue
        ("tenantId", recipient, subject, html, kind, "memberId", "refYear")
      VALUES (
        r."tenantId", r.email,
        'Gëzuar ditëlindjen, ' || v_anrede || '! · Alles Gute zum Geburtstag!',
        v_html, 'BIRTHDAY', r.id, v_jahr
      );
      v_n := v_n + 1;
    EXCEPTION WHEN unique_violation THEN
      -- Fuer dieses Jahr steht der Gruss schon in der Warteschlange.
      NULL;
    END;
  END LOOP;

  RETURN v_n;
END $$;

REVOKE ALL ON FUNCTION public.queue_birthday_greetings(date) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.queue_birthday_greetings(date) TO authenticated;

NOTIFY pgrst, 'reload schema';
