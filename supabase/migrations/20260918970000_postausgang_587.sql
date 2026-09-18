-- Vom Betreiber bestaetigt: versendet wird ueber mail.helvico.ch.
-- Eingetragen war Port 25 ohne Verschluesselung -- Benutzername und Kennwort
-- waeren im Klartext ueber die Leitung gegangen. Port 25 ist ausserdem der
-- Weg zwischen Mailservern, nicht der zum Einliefern eigener Nachrichten.
--
-- Das Kennwort wird nicht angefasst.
UPDATE public.mail_settings
   SET port = 587, tls = 'starttls', geaendert_am = now()
 WHERE "tenantId" = 'koretini' AND host = 'mail.helvico.ch';

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT "tenantId", host, port, tls, benutzer, absender,
                  coalesce(btrim(kennwort),'') <> '' AS kw, aktiv
             FROM public.mail_settings ORDER BY 1 LOOP
    RAISE NOTICE 'Mandant %: % : % / % | Benutzer % | Absender % | Kennwort % | aktiv %',
      r."tenantId", r.host, r.port, r.tls, r.benutzer, r.absender, r.kw, r.aktiv;
  END LOOP;
END $$;
