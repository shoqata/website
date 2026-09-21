-- Ein neuer Verein wird vollstaendig eingerichtet.
--
-- Gemessen an einem Probeverein: create_tenant legte Verein, Domain und
-- eine Administratorzeile an -- und sonst nichts. Es fehlten Kontenplan,
-- Einstellungen und Geschaeftsjahr. Jede Buchung waere gescheitert
-- (spende_bezahlt bucht auf 3200), und ohne Zahlungsangaben gibt es weder
-- QR-Rechnung noch Beitragssaetze.
--
-- Der Kontenplan ist bewusst neutral benannt. Koretinis eigener traegt
-- "Kasse (Koretin)" und "Ertrag Mitgliederbeitraege STANDARD (Diaspora)" --
-- Bezeichnungen aus dessen Geschichte, die einem anderen Verein nichts
-- sagen.

CREATE OR REPLACE FUNCTION public.verein_einrichten(p_verein text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_n int := 0; v_jahr int := extract(year FROM current_date)::int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_verein) THEN
    RAISE EXCEPTION 'Unbekannter Verein: %', p_verein;
  END IF;

  -- --- Kontenplan -------------------------------------------------------
  INSERT INTO public.accounting_accounts (id, "tenantId", code, name, class, category, "systemAccount")
  SELECT gen_random_uuid()::text, p_verein, k.code, k.name, k.klasse, k.kategorie, true
    FROM (VALUES
      ('1000','Kasse','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1020','Bankguthaben','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1021','Zahlungsdienst (PayPal, TWINT)','AKTIVEN','UMLAUFVERMOEGEN'),
      ('1100','Forderungen Mitgliederbeitraege','AKTIVEN','UMLAUFVERMOEGEN'),
      ('2000','Verbindlichkeiten','PASSIVEN','FREMDKAPITAL'),
      ('2900','Vereinsvermoegen','PASSIVEN','EIGENKAPITAL'),
      ('3000','Ertrag Mitgliederbeitraege','ERTRAG','BETRIEBSERTRAG'),
      ('3200','Ertrag Spenden','ERTRAG','BETRIEBSERTRAG'),
      ('3600','Ertrag Veranstaltungen','ERTRAG','BETRIEBSERTRAG'),
      ('4200','Aufwand Projekte','AUFWAND','BETRIEBSAUFWAND'),
      ('4400','Aufwand Veranstaltungen','AUFWAND','BETRIEBSAUFWAND'),
      ('6000','Raumaufwand','AUFWAND','BETRIEBSAUFWAND'),
      ('6500','Verwaltungsaufwand','AUFWAND','BETRIEBSAUFWAND'),
      ('6700','Werbeaufwand','AUFWAND','BETRIEBSAUFWAND')
    ) AS k(code, name, klasse, kategorie)
   WHERE NOT EXISTS (SELECT 1 FROM public.accounting_accounts a
                      WHERE a."tenantId" = p_verein AND a.code = k.code);
  GET DIAGNOSTICS v_n = ROW_COUNT;

  -- --- Einstellungen ----------------------------------------------------
  -- Leere Geruste, keine erfundenen Werte: eine falsche IBAN waere
  -- schlimmer als gar keine, weil der Verein sie nicht bemerkt.
  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'payment', p_verein,
         jsonb_build_object('currency','CHF','fees',
           jsonb_build_object('STANDARD', jsonb_build_object('label','Standard','amount',0,'currency','CHF'))),
         '{}'::jsonb, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='payment');

  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'system', p_verein, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
         jsonb_build_object('allowRegistration', true, 'maintenanceMode', false),
         '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='system');

  INSERT INTO public.settings (id, "tenantId", payment, company, branding, system, data)
  SELECT 'company', p_verein, '{}'::jsonb,
         jsonb_build_object('name', (SELECT name FROM public.tenants WHERE id=p_verein)),
         '{}'::jsonb, '{}'::jsonb, '{}'::jsonb
   WHERE NOT EXISTS (SELECT 1 FROM public.settings WHERE "tenantId"=p_verein AND id='company');

  -- --- Geschaeftsjahr ---------------------------------------------------
  INSERT INTO public.fiscal_years (id, "tenantId", year, status)
  SELECT gen_random_uuid()::text, p_verein, v_jahr, 'OPEN'
   WHERE NOT EXISTS (SELECT 1 FROM public.fiscal_years
                      WHERE "tenantId"=p_verein AND year=v_jahr);

  RETURN p_verein || ': ' || v_n || ' Konten, Einstellungen und Geschaeftsjahr ' || v_jahr;
END $$;

REVOKE ALL ON FUNCTION public.verein_einrichten(text) FROM public, anon, authenticated;

-- create_tenant richtet den Verein jetzt gleich mit ein. Ein Verein, der
-- angelegt ist aber nicht arbeiten kann, ist ein halber Zustand -- und
-- halbe Zustaende raecht sich diese Anwendung erfahrungsgemaess spaeter.
CREATE OR REPLACE FUNCTION public.create_tenant(
  p_name text, p_slug text DEFAULT NULL, p_domain text DEFAULT NULL,
  p_admin_email text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id     text;
  v_domain text := lower(btrim(p_domain));
  v_email  text := lower(btrim(coalesce(p_admin_email, '')));
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Nur der Betreiber der Plattform darf Vereine anlegen.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF coalesce(btrim(p_name), '') = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_domain = '' THEN
    RAISE EXCEPTION 'Domain fehlt -- ohne sie ist die Website des Vereins nicht auffindbar.'
      USING ERRCODE = 'check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tenant_domains WHERE domain = v_domain) THEN
    RAISE EXCEPTION 'Die Domain % ist bereits einem Verein zugeordnet.', v_domain
      USING ERRCODE = 'unique_violation';
  END IF;

  IF v_email <> '' THEN
    IF position('@' in v_email) = 0 THEN
      RAISE EXCEPTION 'E-Mail des Administrators ist unvollstaendig.' USING ERRCODE='check_violation';
    END IF;
    IF EXISTS (SELECT 1 FROM public.users WHERE lower(email) = v_email) THEN
      RAISE EXCEPTION 'Die Adresse % ist bereits vergeben. Lassen Sie das Feld leer, wenn Sie den Verein zunaechst selbst einrichten wollen.', v_email
        USING ERRCODE='unique_violation';
    END IF;
  END IF;

  v_id := coalesce(nullif(btrim(p_slug), ''), regexp_replace(lower(p_name), '[^a-z0-9]+', '-', 'g'));
  v_id := btrim(regexp_replace(lower(v_id), '[^a-z0-9-]+', '-', 'g'), '-');
  IF v_id = '' THEN
    RAISE EXCEPTION 'Aus Name und Kurzform laesst sich keine Kennung bilden.'
      USING ERRCODE='check_violation';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tenants WHERE id = v_id) THEN
    v_id := v_id || '-' || substr(md5(random()::text), 1, 4);
  END IF;

  INSERT INTO public.tenants (id, name, slug, "subscriptionPlan", "subscriptionStatus", "createdAt")
  VALUES (v_id, btrim(p_name), v_id, 'FREE', 'ACTIVE', now());

  INSERT INTO public.tenant_domains ("tenantId", domain) VALUES (v_id, v_domain);

  IF v_email <> '' THEN
    INSERT INTO public.users (id, "tenantId", email, role, "membershipStatus", "displayName", "joinedAt")
    VALUES (gen_random_uuid()::text, v_id, v_email, 'ADMIN', 'ACTIVE', v_email, now());
  END IF;

  PERFORM public.verein_einrichten(v_id);

  RETURN v_id;
END $$;

GRANT EXECUTE ON FUNCTION public.create_tenant(text,text,text,text) TO authenticated;

DO $$ BEGIN RAISE NOTICE 'Einrichtung eingebaut.'; END $$;
