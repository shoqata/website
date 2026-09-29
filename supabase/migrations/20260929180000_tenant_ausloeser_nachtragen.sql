-- "new row violates row-level security policy for table spendenaufrufe"
--
-- Die Ursache ist nicht die Regel, sondern eine fehlende Zeile davor: die
-- Tabelle fuellt "tenantId" nicht selbst. Die Oberflaeche schreibt den Wert
-- nicht mit -- sie soll es auch nicht, sonst koennte sie ihn faelschen --
-- also steht dort NULL, und die Bedingung "tenantId = current_tenant()"
-- schlaegt fehl. 18 aeltere Tabellen haben dafuer einen Ausloeser; die zwei
-- neuen hatte ich vergessen.
--
-- videos hat denselben Fehler: dort waere es beim naechsten Video passiert.
CREATE TRIGGER spendenaufrufe_tenant
  BEFORE INSERT ON public.spendenaufrufe
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_on_insert();

CREATE TRIGGER videos_tenant
  BEFORE INSERT ON public.videos
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_on_insert();

-- Gegenprobe aus der Sicht eines Vereinsadministrators: anlegen,
-- veroeffentlichen, und sehen, ob ein Besucher es danach bekommt.
DO $$
DECLARE v_back text := current_user; v_uid text; v_mail text; v_id text; v_n int; r record;
BEGIN
  SELECT u."authUserId", u.email INTO v_uid, v_mail FROM public.users u
   WHERE u.role IN ('ADMIN','SUPER_ADMIN') AND u."authUserId" IS NOT NULL LIMIT 1;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_uid,'role','authenticated','email',v_mail)::text, false);
  EXECUTE 'SET ROLE authenticated';

  -- genau so, wie es die Maske tut: ohne tenantId
  INSERT INTO public.spendenaufrufe (titel, text, ziel_betrag, waehrung)
  VALUES ('Probe nach der Behebung','nur zum Pruefen', 500, 'CHF')
  RETURNING id INTO v_id;
  RAISE NOTICE '1. Anlegen ohne tenantId: gelungen';

  UPDATE public.spendenaufrufe SET status='OEFFENTLICH' WHERE id=v_id;
  RAISE NOTICE '2. Veroeffentlichen: gelungen';

  INSERT INTO public.videos (titel, quelle)
  VALUES ('Probe Video', 'https://example.org/x.mp4');
  RAISE NOTICE '3. Video anlegen ohne tenantId: gelungen';

  EXECUTE format('SET ROLE %I', v_back);
  PERFORM set_config('request.jwt.claims', NULL, false);

  SELECT "tenantId" INTO v_mail FROM public.spendenaufrufe WHERE id=v_id;
  RAISE NOTICE '4. gelandeter Verein: %', v_mail;

  PERFORM set_config('request.headers',
    json_build_object('origin','https://www.koretini.me')::text, false);
  EXECUTE 'SET ROLE anon';
  SELECT count(*) INTO v_n FROM public.spendenaufrufe_oeffentlich();
  EXECUTE format('SET ROLE %I', v_back);
  RAISE NOTICE '5. Besucher sieht % Aufruf(e)', v_n;

  DELETE FROM public.spendenaufrufe WHERE id=v_id;
  DELETE FROM public.videos WHERE titel='Probe Video';
  PERFORM set_config('request.headers', NULL, false);
  RAISE NOTICE '6. aufgeraeumt.';
END $$;
