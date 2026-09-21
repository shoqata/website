-- Zugangsdaten sozialer Medien waren oeffentlich lesbar.
--
-- Bewiesen von aussen, mit dem Schluessel aus dem Bundle und der
-- Origin-Kopfzeile, die jeder Browser mitschickt:
--   GET /rest/v1/public_settings?id=eq.social
--   -> {"fbAccessToken":"...","igAccessToken":"..."}
--
-- Ursache: public_settings gibt die Spalte data vollstaendig heraus,
-- gefiltert nur nach Verein. settings/social landet genau dort, weil
-- 'social' nicht zu den benannten Spalten gehoert. Mit diesen Tokens
-- koennte ein Fremder auf der Facebook-Seite und dem Instagram-Konto des
-- Vereins veroeffentlichen.
--
-- Zwei Massnahmen. Erstens hier: die Sicht gibt data nicht mehr blind
-- heraus, sondern nur noch die Schluessel, die eine oeffentliche Seite
-- wirklich braucht. Alles andere faellt weg -- eine Sperrliste einzelner
-- Namen waere beim naechsten neuen Feld wieder offen.
--
-- Zweitens getrennt: die Zugangsdaten gehoeren gar nicht in settings.
-- Dafuer kommt eine eigene Tabelle, wie schon beim Postausgang.

DELETE FROM public.settings WHERE id = 'social';

CREATE OR REPLACE VIEW public.public_settings AS
  SELECT id,
         "tenantId",
         (payment - 'paypalSecret' - 'paypalClientId') AS payment,
         company,
         branding,
         system,
         -- Erlaubnisliste statt Sperrliste: nur diese Schluessel werden
         -- herausgegeben. Was neu dazukommt, ist damit von sich aus
         -- geschlossen und nicht erst nach dem naechsten Vorfall.
         (SELECT jsonb_object_agg(k, v)
            FROM jsonb_each(coalesce(data, '{}'::jsonb)) AS e(k, v)
           WHERE k IN ('qrIban','iban','bic','bankName','accountHolder','twintUrl',
                       'paypalEmail','street','zip','city','country','currency',
                       'fees','annualFeeAmount')) AS data
    FROM settings
   WHERE "tenantId" = COALESCE(current_tenant(), request_tenant());

ALTER VIEW public.public_settings SET (security_invoker = on);
GRANT SELECT ON public.public_settings TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_settings FROM anon, authenticated;
