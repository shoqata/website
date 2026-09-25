-- Ob Beitragszahler oeffentlich erscheinen -- entschieden je Verein, mit
-- Widerspruchsrecht je Mitglied.
--
-- Zwei Dinge sind hier absichtlich so und nicht anders:
--
-- 1. Der Schalter wirkt in dieser Funktion, nicht im React-Bauteil. Eine
--    Pruefung in der Oberflaeche umgeht jeder, der die Sicht direkt
--    abfragt -- genau auf diesem Weg lagen im September die
--    Facebook-Token offen. Steht der Schalter auf AUS, gibt es hier
--    nichts zu holen, auch nicht fuer den, der die Schnittstelle kennt.
--
-- 2. Der Widerspruch eines Mitglieds gewinnt immer, auch gegen den
--    Vereinsschalter. Er wirkt zugleich auf den Mitgliederlauf der
--    Startseite: bisher standen dort Name, Foto und Wohnort von 337 der
--    340 Mitglieder, ohne dass jemand haette widersprechen koennen.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS nicht_oeffentlich boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.users.nicht_oeffentlich IS
  'Mitglied moechte auf der oeffentlichen Website nicht erscheinen -- weder im Mitgliederlauf noch in einer Zahlerliste.';

-- Die bestehende Sicht kennt den Widerspruch jetzt.
CREATE OR REPLACE VIEW public.public_members AS
  SELECT id, "tenantId", "displayName", "photoFileName", city, country,
         "membershipStatus", "livesInKoretin"
    FROM public.users
   WHERE "membershipStatus" IS DISTINCT FROM 'INACTIVE'
     AND coalesce(nicht_oeffentlich, false) = false
     AND "tenantId" = coalesce(public.current_tenant(), public.request_tenant());


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
BEGIN
  IF v_verein IS NULL THEN
    RETURN jsonb_build_object('stellung','AUS');
  END IF;

  SELECT upper(coalesce(s.system ->> 'beitraegeOeffentlich','AUS'))
    INTO v_stellung
    FROM public.settings s
   WHERE s."tenantId" = v_verein AND s.id = 'system';

  IF coalesce(v_stellung,'AUS') NOT IN ('ZAHL','NAMEN') THEN
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

  -- Namen nur von denen, die nicht widersprochen haben.
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
END $$;

REVOKE ALL ON FUNCTION public.beitragsstand_oeffentlich(int) FROM public;
GRANT EXECUTE ON FUNCTION public.beitragsstand_oeffentlich(int) TO anon, authenticated;

-- Wie viele haben widersprochen? Das braucht die Vorschau im Admin, und es
-- ist keine oeffentliche Angabe.
CREATE OR REPLACE FUNCTION public.widersprueche_zaehlen()
RETURNS int
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*)::int FROM public.users u
   WHERE u."tenantId" = public.current_tenant()
     AND coalesce(u.nicht_oeffentlich,false)
     AND public.is_staff();
$$;
REVOKE ALL ON FUNCTION public.widersprueche_zaehlen() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.widersprueche_zaehlen() TO authenticated;

DO $$ BEGIN RAISE NOTICE 'Spalte, Sicht und Funktionen stehen.'; END $$;
