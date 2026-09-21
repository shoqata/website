-- Probelauf bis an Metas Tuer. Ohne echte App gibt es keinen gueltigen
-- Token -- genau deshalb ist der Lauf aussagekraeftig: es laesst sich
-- pruefen, ob die Absage von Meta sauber am Beitrag landet, statt still zu
-- verschwinden. Die Zeilen werden anschliessend wieder entfernt.
DO $$
BEGIN
  INSERT INTO public.social_connections ("tenantId", plattform, konto_id, konto_name,
                                         zugriffstoken, zustand, verbunden_am)
  VALUES ('koretini','FACEBOOK','999999999999','Probeseite','PROBE-UNGUELTIG','AKTIV', now())
  ON CONFLICT ("tenantId", plattform) DO UPDATE
    SET zugriffstoken='PROBE-UNGUELTIG', zustand='AKTIV', konto_id='999999999999';

  INSERT INTO public.socialmediaposts (id, "tenantId", content, platforms, status, timestamp)
  VALUES ('probe-kette','koretini','Probelauf der Kette -- wird nicht gesendet.',
          '["FACEBOOK"]'::jsonb, 'QUEUED', now())
  ON CONFLICT (id) DO UPDATE SET status='QUEUED', "lastError"=NULL, attempts=0;
  RAISE NOTICE 'Probezeilen gesetzt.';
END $$;
