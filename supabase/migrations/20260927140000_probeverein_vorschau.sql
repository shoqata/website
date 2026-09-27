-- Ein Probeverein fuer die oertliche Vorschau.
--
-- Koretini wird dafuer ausdruecklich NICHT umgeschaltet: das ist eine
-- oeffentliche Website, und ein Probelauf gehoert nicht darauf. Der
-- Probeverein bekommt die Domain localhost, damit der Entwicklungsserver
-- ueber denselben Weg aufloest wie jeder echte Verein -- ueber den
-- Origin-Kopf und tenant_domains, ohne Sonderpfad im Code.
DO $$
DECLARE v_id text := 'probe-premium';
BEGIN
  INSERT INTO public.tenants (id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt", "annualFee")
  VALUES (v_id, 'Shoqata Probe', v_id, 'PRO', 'ACTIVE', now(), 480)
  ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name;

  INSERT INTO public.tenant_domains ("tenantId", domain) VALUES (v_id, 'localhost')
  ON CONFLICT (domain) DO UPDATE SET "tenantId" = v_id;

  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES (v_id, 'LANDINGPAGE', 'AN')
  ON CONFLICT ("tenantId", modul) DO UPDATE SET zustand='AN';

  INSERT INTO public.settings (id, "tenantId", system, branding, payment, company, data)
  VALUES ('system', v_id, '{"startseiteVariante":"PREMIUM","beitraegeOeffentlich":"ZAHL"}'::jsonb,
          '{}'::jsonb,'{}'::jsonb,'{}'::jsonb,'{}'::jsonb)
  ON CONFLICT ("tenantId", id) DO UPDATE SET system = EXCLUDED.system;

  INSERT INTO public.settings (id, "tenantId", system, branding, payment, company, data)
  VALUES ('branding', v_id, '{}'::jsonb, jsonb_build_object(
            'heroBadge',    jsonb_build_object('de','Für unser Dorf','sq','Për fshatin tonë'),
            'heroTitle',    jsonb_build_object('de','Ein Verein ist das, was seine Mitglieder tun.','sq','Një shoqatë është ajo që bëjnë anëtarët e saj.'),
            'heroSubtitle', jsonb_build_object('de','Seit 1998 verbindet uns dieselbe Herkunft — und dieselbe Absicht.','sq','Që nga viti 1998 na lidh e njëjta prejardhje.'),
            'whyJoinText',  jsonb_build_object('de','Seien Sie dabei.','sq','Bëhuni pjesë.'),
            'heroImages',   '[]'::jsonb,
            'missions', jsonb_build_array(
              jsonb_build_object('title', jsonb_build_object('de','Wasser'),   'description', jsonb_build_object('de','Die Leitung ins Oberdorf ist seit dem Frühjahr in Betrieb.')),
              jsonb_build_object('title', jsonb_build_object('de','Schule'),   'description', jsonb_build_object('de','Zwei Klassenzimmer neu ausgestattet, Bücher für 140 Kinder.')),
              jsonb_build_object('title', jsonb_build_object('de','Gesundheit'),'description', jsonb_build_object('de','Der Arzt kommt seit Januar jeden zweiten Dienstag.')))),
          '{}'::jsonb,'{}'::jsonb,'{}'::jsonb)
  ON CONFLICT ("tenantId", id) DO UPDATE SET branding = EXCLUDED.branding;

  -- Ein paar Mitglieder und ein Anlass, damit die Akte nicht leer sind.
  INSERT INTO public.users (id,"tenantId",email,role,"membershipStatus","displayName","joinedAt","livesInKoretin")
  SELECT 'probe-m-'||g, v_id, 'probe'||g||'@example.org','MEMBER','ACTIVE','Probe Mitglied '||g, now(), (g % 3 = 0)
    FROM generate_series(1,24) g
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.events (id,"tenantId",title,description,date,location,status)
  VALUES ('probe-e-1', v_id,'Jahresversammlung','Rückblick und Wahlen.', (current_date + 21)::text,'Gemeindesaal Affoltern','PUBLISHED'),
         ('probe-e-2', v_id,'Sommerfest','Mit Musik und Küche aus dem Dorf.', (current_date + 74)::text,'Sportplatz','PUBLISHED')
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Probeverein steht. localhost -> %', v_id;
END $$;

DO $$
DECLARE v_back text := current_user;
BEGIN
  PERFORM set_config('request.headers', json_build_object('origin','http://localhost:3001')::text, false);
  EXECUTE 'SET ROLE anon';
  RAISE NOTICE 'localhost bekommt: %', public.startseite_variante();
  RAISE NOTICE 'Mitglieder sichtbar: %', (SELECT count(*) FROM public.public_members);
  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.headers', NULL, false);
END $$;
