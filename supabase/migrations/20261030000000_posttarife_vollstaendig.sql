-- Wer auf einen Briefpreis wartet, soll beim Betreiber auftauchen.
--
-- post_tarife() las aus post_preise. Diese Tabelle bekommt aber erst
-- dann eine Zeile, wenn der Betreiber einen Preis setzt. Ein Verein, der
-- das Modul Briefversand gerade freigeschaltet hat, stand also nirgends:
--
--   der Verein liest    "Der Plattformbetreiber legt den Preis fest"
--   der Betreiber sieht  nichts
--
-- Beide warten auf den anderen, und niemand erfaehrt es. Darum beginnt
-- die Sicht jetzt bei den freigeschalteten Modulen und nicht bei den
-- Preisen -- ein Verein ohne Preiszeile erscheint mit leeren Preisen und
-- der Angabe, dass das Modul laeuft.
--
-- Die Gegenrichtung bleibt ebenfalls sichtbar: ein Verein mit Preis,
-- dessen Modul abgeschaltet wurde, verschwindet nicht. Sonst waere ein
-- gekauftes Kontingent plus Preis aus der Sicht des Betreibers weg,
-- obwohl der Verein es noch hat.

-- Die Rueckgabe bekommt eine Spalte. Das verlangt DROP; CREATE OR
-- REPLACE kann den Rueckgabetyp nicht aendern.
DROP FUNCTION IF EXISTS public.post_tarife();

CREATE OR REPLACE FUNCTION public.post_tarife()
RETURNS TABLE (
  r_verein text, r_name text, r_einkauf numeric, r_aufpreis numeric,
  r_fest numeric, r_verkauf numeric, r_waehrung text,
  r_abgefragt timestamptz, r_grundlage text, r_modul text
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  WITH beteiligte AS (
    -- Freigeschaltet, mit oder ohne Preis.
    SELECT tm."tenantId" AS id, tm.zustand AS modul
      FROM public.tenant_modules tm
     WHERE tm.modul = 'POSTVERSAND' AND tm.zustand IN ('AN','TESTPHASE')
    UNION
    -- Hat einen Preis, auch wenn das Modul inzwischen aus ist.
    SELECT p."tenantId", NULL
      FROM public.post_preise p
  ), zusammen AS (
    SELECT b.id,
           -- Bei zwei Zeilen je Verein (beide Zweige) gewinnt der
           -- Modulzustand; max() nimmt ihn, weil NULL dabei verliert.
           max(b.modul) AS modul
      FROM beteiligte b GROUP BY b.id
  )
  SELECT z.id,
         coalesce(t.name, z.id),
         p.einkauf_je_brief, p.aufpreis_prozent, p.preis_fest,
         p.preis_je_brief, coalesce(p.waehrung, 'CHF'),
         p.tarif_abgefragt_am, p.tarif_grundlage,
         coalesce(z.modul, 'AUS')
    FROM zusammen z
    LEFT JOIN public.tenants t ON t.id = z.id
    LEFT JOIN public.post_preise p ON p."tenantId" = z.id
   WHERE public.is_platform_admin()
   ORDER BY 2;
$$;

REVOKE ALL ON FUNCTION public.post_tarife() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.post_tarife() TO authenticated;


-- ------------------------------------------------- Nachweis
--
-- Geprueft wird die Luecke selbst: ein freigeschalteter Verein ohne
-- Preiszeile MUSS erscheinen. Ein Test, der nur zaehlt, ob ueberhaupt
-- Zeilen kommen, haette den alten Stand auch bestanden.
--
-- Der Test laeuft durch das echte Tor. post_tarife() steht hinter
-- is_platform_admin(), und das ist fuer die Migrationsrolle falsch --
-- auth.jwt() ist dort leer. Ein Test ohne Anspruch haette also NULL
-- Zeilen gesehen und "Verein fehlt" gemeldet, bei richtiger wie bei
-- falscher Funktion. Darum wird der Anspruch fuer die Dauer der
-- Transaktion gesetzt. Die Adresse endet auf .invalid: selbst wenn die
-- Zeile je stehenblieb, kann sich damit niemand anmelden.
DO $$
DECLARE
  v_verein text := '_tarifprobe_' || substr(replace(gen_random_uuid()::text,'-',''),1,8);
  v_mail   text := '_probe_' || substr(replace(gen_random_uuid()::text,'-',''),1,8) || '@probe.invalid';
  v_da boolean;
  v_modul text;
  v_verkauf numeric;
  v_n int;
BEGIN
  INSERT INTO public.tenants (id, name) VALUES (v_verein, 'Tarifprobe')
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
    VALUES (v_verein, 'POSTVERSAND', 'AN')
    ON CONFLICT DO NOTHING;

  -- 0. Das Tor haelt. Ohne Anspruch keine Zeile -- sonst waere jeder
  --    angemeldete Nutzer in den Einkaufspreisen aller Vereine.
  SELECT count(*) INTO v_n FROM public.post_tarife();
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post_tarife() gibt ohne Betreiberanspruch % Zeilen heraus.', v_n;
  END IF;

  INSERT INTO public.platform_admins (email, note)
    VALUES (v_mail, 'nur fuer den Selbsttest der Migration')
    ON CONFLICT (email) DO NOTHING;
  PERFORM set_config('request.jwt.claims',
                     json_build_object('email', v_mail)::text, true);

  -- Und der Anspruch greift wirklich.
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'Der gesetzte Betreiberanspruch wirkt nicht; der Test kann nichts pruefen.';
  END IF;

  -- 1. Ohne Preiszeile sichtbar, mit leerem Preis.
  SELECT true, t.r_modul, t.r_verkauf INTO v_da, v_modul, v_verkauf
    FROM public.post_tarife() t WHERE t.r_verein = v_verein;
  IF NOT coalesce(v_da, false) THEN
    RAISE EXCEPTION 'Ein freigeschalteter Verein ohne Preis fehlt in post_tarife().';
  END IF;
  IF v_modul <> 'AN' THEN
    RAISE EXCEPTION 'Der Modulzustand kommt falsch zurueck: %', v_modul;
  END IF;
  IF v_verkauf IS NOT NULL THEN
    RAISE EXCEPTION 'Ohne Preiszeile darf kein Verkaufspreis dastehen: %', v_verkauf;
  END IF;

  -- 2. Mit Preiszeile genau einmal, und der Verkaufspreis rechnet.
  INSERT INTO public.post_preise ("tenantId", einkauf_je_brief, aufpreis_prozent)
    VALUES (v_verein, 1.50, 10);
  SELECT count(*) INTO v_n FROM public.post_tarife() t WHERE t.r_verein = v_verein;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'Der Verein erscheint % mal, sobald er einen Preis hat.', v_n;
  END IF;
  SELECT t.r_verkauf INTO v_verkauf
    FROM public.post_tarife() t WHERE t.r_verein = v_verein;
  IF v_verkauf <> 1.65 THEN
    RAISE EXCEPTION 'Einkauf 1.50 + 10%% muessten 1.65 ergeben, nicht %', v_verkauf;
  END IF;

  -- 3. Modul aus, Preis bleibt -> weiter sichtbar.
  UPDATE public.tenant_modules SET zustand = 'AUS'
   WHERE "tenantId" = v_verein AND modul = 'POSTVERSAND';
  SELECT t.r_modul INTO v_modul
    FROM public.post_tarife() t WHERE t.r_verein = v_verein;
  IF v_modul IS DISTINCT FROM 'AUS' THEN
    RAISE EXCEPTION 'Ein abgeschalteter Verein mit Preis verschwindet oder meldet %', v_modul;
  END IF;

  DELETE FROM public.post_preise WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_modules WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;
  DELETE FROM public.platform_admins WHERE email = v_mail;
  PERFORM set_config('request.jwt.claims', '', true);
  RAISE NOTICE 'post_tarife(): Tor haelt, Wartende sichtbar, Preis rechnet, Abschaltung bleibt sichtbar.';
EXCEPTION WHEN OTHERS THEN
  DELETE FROM public.post_preise WHERE "tenantId" = v_verein;
  DELETE FROM public.tenant_modules WHERE "tenantId" = v_verein;
  DELETE FROM public.tenants WHERE id = v_verein;
  DELETE FROM public.platform_admins WHERE email = v_mail;
  PERFORM set_config('request.jwt.claims', '', true);
  RAISE;
END $$;
