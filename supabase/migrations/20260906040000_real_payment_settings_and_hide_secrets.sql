-- Zahlungsangaben richtigstellen und Zugangsdaten aus der oeffentlichen
-- Reichweite nehmen.
--
-- Es gab zwei Zahlungs-Datensaetze. Die App liest settings/payment, dort stand
-- aber PostFinance mit der IBAN CH9300000000000000000 -- die Beispiel-IBAN aus
-- der Dokumentation, kein Konto. Die echten Angaben lagen in settings/global,
-- das nirgends gelesen wird: Valiant Bank, QR-IBAN, TWINT. Vom Eigentuemer
-- bestaetigt: Valiant gilt.
--
-- Ausserdem enthaelt der Datensatz paypalClientId und paypalSecret. settings war
-- fuer anon lesbar, das PayPal-Secret also mit dem Key aus dem Bundle abrufbar.
-- Es wird clientseitig ausschliesslich in einem Eingabefeld der Administration
-- angezeigt, gehoert also gar nicht in die Reichweite von Besuchern oder
-- gewoehnlichen Mitgliedern.

-- --- 1. Valiant-Daten an die gelesene Stelle ------------------------------
-- global gewinnt bei jedem gemeinsamen Feld, die nur in payment vorhandenen
-- Felder (dunningDelayDays, paymentTermsDays) bleiben erhalten.
-- settings/global bleibt unangetastet und dient als Sicherung.
UPDATE public.settings AS target
   SET payment = COALESCE(target.payment, '{}'::jsonb) || COALESCE(source.payment, '{}'::jsonb)
  FROM public.settings AS source
 WHERE target.id = 'payment'
   AND source.id = 'global';

-- --- 2. Oeffentliche Projektion ohne Zugangsdaten -------------------------
CREATE OR REPLACE VIEW public.public_settings AS
  SELECT id,
         (payment - 'paypalSecret' - 'paypalClientId') AS payment,
         company,
         branding,
         system,
         data
    FROM public.settings;

GRANT SELECT ON public.public_settings TO anon, authenticated;

-- --- 3. settings selbst nur noch fuer die Verwaltung ----------------------
REVOKE ALL ON TABLE public.settings FROM anon;

DROP POLICY IF EXISTS settings_public_read ON public.settings;
CREATE POLICY settings_staff_read ON public.settings FOR SELECT TO authenticated
  USING (public.is_staff());
