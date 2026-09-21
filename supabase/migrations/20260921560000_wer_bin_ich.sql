-- Wer ist angemeldet, und wohin gehoert er?
--
-- Der Browser entschied bisher anhand einer fest eingetragenen
-- E-Mail-Liste, ob jemand Plattformbetreiber ist -- und behandelte
-- zusaetzlich jede Vereinsrolle SUPER_ADMIN als Betreiber. Damit landete
-- ein Vereinsadministrator, der sich auf unityhub.li anmeldet, im
-- Betreiberbereich. Die Datenbank hielt ihn korrekt von allem ab, was
-- zaehlt, aber die Maske zeigte ihm eine Welt, die ihm nicht gehoert.
--
-- Massgeblich ist ab jetzt die Datenbank. Eine Liste im Quelltext laeuft
-- frueher oder spaeter mit platform_admins auseinander -- genau das ist in
-- dieser Sitzung schon einmal passiert.
CREATE OR REPLACE FUNCTION public.wer_bin_ich()
RETURNS TABLE (
  ist_betreiber boolean,
  verein text,
  vereinsname text,
  vereinsdomain text,
  rolle text
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_ich text := public.current_user_row_id();
        v_verein text;
BEGIN
  SELECT u."tenantId" INTO v_verein FROM public.users u WHERE u.id = v_ich;

  RETURN QUERY
  SELECT
    public.is_platform_admin(),
    v_verein,
    (SELECT t.name FROM public.tenants t WHERE t.id = v_verein),
    -- Die Adresse, unter der dieser Verein erreichbar ist. Ohne "www.",
    -- weil sie als Verweis angezeigt wird.
    (SELECT d.domain FROM public.tenant_domains d
      WHERE d."tenantId" = v_verein AND d.domain NOT LIKE 'localhost%'
      ORDER BY (d.domain LIKE 'www.%'), length(d.domain) LIMIT 1),
    coalesce((SELECT u.role FROM public.users u WHERE u.id = v_ich), 'MEMBER');
END $$;

REVOKE ALL ON FUNCTION public.wer_bin_ich() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.wer_bin_ich() TO authenticated;

DO $$
DECLARE v_back text := current_user; r record; w record;
BEGIN
  FOR r IN SELECT u."authUserId" AS uid, u.email, coalesce(u.role,'MEMBER') AS rolle
             FROM public.users u WHERE u."authUserId" IS NOT NULL ORDER BY 3,2 LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT * INTO w FROM public.wer_bin_ich();
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
    RAISE NOTICE '  % (%) | Betreiber % | Verein % | %',
      rpad(left(r.email,26),26), rpad(r.rolle,11), w.ist_betreiber,
      rpad(coalesce(w.verein,'-'),10), coalesce(w.vereinsdomain,'-');
  END LOOP;

  -- Und der Betreiber selbst?
  FOR r IN SELECT p.email, a.id::text AS uid FROM public.platform_admins p
             JOIN auth.users a ON lower(a.email)=lower(p.email) LOOP
    PERFORM set_config('request.jwt.claims',
      json_build_object('sub',r.uid,'role','authenticated','email',r.email)::text, false);
    EXECUTE 'SET ROLE authenticated';
    SELECT * INTO w FROM public.wer_bin_ich();
    EXECUTE format('SET ROLE %I', v_back);
    PERFORM set_config('request.jwt.claims', NULL, false);
    RAISE NOTICE '  % (Betreiber) | Betreiber % | Verein %',
      rpad(left(r.email,26),26), w.ist_betreiber, coalesce(w.verein,'-');
  END LOOP;
END $$;
