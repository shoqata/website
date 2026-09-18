-- Welches Feld fehlt? Die Funktion verlangt Host, Benutzer, Kennwort und
-- Absender -- fehlt eines, meldet sie "Kein Postausgang hinterlegt".
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT "tenantId", host, port, benutzer, absender, absendername, tls, aktiv,
                  coalesce(btrim(kennwort),'') <> '' AS kw
             FROM public.mail_settings LOOP
    RAISE NOTICE 'Host      : %', coalesce(nullif(btrim(r.host),''), '>>> FEHLT <<<');
    RAISE NOTICE 'Benutzer  : %', coalesce(nullif(btrim(r.benutzer),''), '>>> FEHLT <<<');
    RAISE NOTICE 'Kennwort  : %', CASE WHEN r.kw THEN 'hinterlegt' ELSE '>>> FEHLT <<<' END;
    RAISE NOTICE 'Absender  : %', coalesce(nullif(btrim(r.absender),''), '>>> FEHLT <<<');
    RAISE NOTICE 'Name      : %', coalesce(nullif(btrim(r.absendername),''), '(leer, unkritisch)');
    RAISE NOTICE 'Port/TLS  : % / %', r.port, r.tls;
    RAISE NOTICE 'aktiv     : %', r.aktiv;
  END LOOP;
END $$;
