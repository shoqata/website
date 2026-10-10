-- Welcher Weg fuer welche Empfaengerdomain?
--
-- Microsoft nimmt von Contabo-Adressen keine Post an, und genau dort
-- steht der Postal-Server (62.84.182.168, netname TT-20240627, Contabo
-- GmbH). Fuer Microsoft-Empfaenger geht es deshalb ueber Brevo, fuer
-- alle uebrigen weiter ueber Postal.
--
-- ERKANNT WIRD AM MX, NICHT AN EINER LISTE. Gemessen an den Mitgliedern
-- von Koretini: 44 haben eine Adresse bei hotmail, outlook, live oder
-- msn -- die faende auch eine Liste. Aber isen-tiefbau.ch, dervishi.ch,
-- ha-tech.ch, multinetcom.ch und direct.ch liegen ebenfalls bei
-- Microsoft 365, und das sieht man nur am MX-Eintrag
-- (*.mail.protection.outlook.com). Eine Liste haette sie uebersehen,
-- und niemand haette gemerkt, warum deren Post nicht ankommt.
--
-- Das Ergebnis wird gemerkt: eine DNS-Abfrage je Nachricht waere bei
-- einem Beitragslauf ueber 340 Mitglieder 340 Abfragen fuer rund 60
-- verschiedene Domains.

CREATE TABLE IF NOT EXISTS public.mail_domain_weg (
  domain      text PRIMARY KEY,
  weg         text NOT NULL CHECK (weg IN ('postal','brevo')),
  grund       text,
  geprueft_am timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.mail_domain_weg IS
  'Gemerkte Zuordnung Empfaengerdomain -> Versandweg, ermittelt am '
  'MX-Eintrag. Aelter als 30 Tage wird neu geprueft: eine Domain kann '
  'den Anbieter wechseln.';

ALTER TABLE public.mail_domain_weg ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mail_domain_weg_lesen ON public.mail_domain_weg;
-- Nur Betreiber und Verwaltung. Welche Domains ein Verein anschreibt,
-- ist nichts, was ein Besucher abfragen koennen muss.
CREATE POLICY mail_domain_weg_lesen ON public.mail_domain_weg FOR SELECT TO authenticated
  USING (public.is_platform_admin() OR public.is_member_manager());
REVOKE ALL ON public.mail_domain_weg FROM anon, public;
GRANT SELECT ON public.mail_domain_weg TO authenticated;


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname='public' AND tablename='mail_domain_weg' AND cmd <> 'SELECT';
  IF v_n > 0 THEN RAISE EXCEPTION '% Schreibregel(n) auf mail_domain_weg.', v_n; END IF;

  SELECT count(*) INTO v_n FROM information_schema.role_table_grants
   WHERE table_schema='public' AND grantee='anon' AND table_name='mail_domain_weg';
  IF v_n > 0 THEN RAISE EXCEPTION 'anon hat Rechte auf mail_domain_weg.'; END IF;

  RAISE NOTICE 'Wegetabelle bereit.';
END $$;
