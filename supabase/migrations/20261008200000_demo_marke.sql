-- Die Demo trug Koretinis Namen.
--
-- Gemessen auf demo.unityhub.li: die Zuordnung stimmte (data-domain
-- "verein", Verein "demo"), die DATEN stimmten auch -- 26 Mitglieder,
-- alle erfunden, keine Zeile von Koretini. Aber im Kopf stand
-- "Koretini", und der Startseitentext war seiner.
--
-- Zwei Ursachen, beide hier behoben:
--
--   1. Die App fragt Einstellungen nach ZWECK ab: ein Dokument mit der
--      Kennung 'branding', eines mit 'payment'. Koretini hat genau das.
--      Meine erste Migration legte stattdessen einen einzigen Klumpen
--      namens 'demo-settings' an -- den liest die App nie. Sie fand
--      also gar keine Marke.
--
--   2. Ohne gefundene Marke greift in App.tsx
--      `loc(branding.associationName) || 'Koretini'` -- ein fest
--      eingetragener Rueckfall. Koretinis eigenes branding traegt kein
--      associationName, deshalb steht er dort. Fuer jeden weiteren
--      Verein ohne Markenangabe heisst die Seite damit "Koretini".
--      Das ist eine Altlast; sie wird hier nicht angefasst, weil ein
--      geaenderter Rueckfall sofort koretini.me betraefe. Die Demo
--      bekommt stattdessen einen eigenen Namen, dann greift er nicht.

DELETE FROM public.settings WHERE "tenantId" = 'demo';

-- --------------------------------------------------------------- Marke
INSERT INTO public.settings (id, "tenantId", branding)
VALUES ('branding', 'demo', jsonb_build_object(
  'associationName', jsonb_build_object(
      'de','Shoqata Demo','sq','Shoqata Demo','en','Shoqata Demo'),
  'primary',   '#0428CB',
  'secondary', '#00052E',
  'logoUrl',   '',
  'logoHeight','3rem',
  -- Eigener Startseitentext. Ohne ihn zeigt die App ihre Vorgabe, und
  -- die ist fuer Koretini geschrieben -- in einer Vorfuehrung genau das
  -- Falsche.
  'heroBadge', jsonb_build_object(
      'de','Musterverein','sq','Shoqatë model','en','Sample association'),
  'heroTitle', jsonb_build_object(
      'de','So sieht Ihr Verein aus.',
      'sq','Kështu duket shoqata juaj.',
      'en','This is what your association looks like.'),
  'heroSubtitle', jsonb_build_object(
      'de','Mitglieder, Beiträge und Buchhaltung an einem Ort. Diese Seite ist ein Beispiel — alle Namen und Beträge sind erfunden.',
      'sq','Anëtarët, kuotat dhe kontabiliteti në një vend. Kjo faqe është shembull — të gjithë emrat dhe shumat janë të trilluar.',
      'en','Members, fees and bookkeeping in one place. This page is a sample — every name and amount is invented.'),
  'footerText', jsonb_build_object(
      'de','Demo-Verein von unityhub. Alle Daten sind erfunden.',
      'sq','Shoqatë demo e unityhub. Të gjitha të dhënat janë të trilluara.',
      'en','unityhub demo association. All data is invented.'),
  'footerEmail', 'demo@unityhub.li',
  'footerAddress', 'Musterstrasse 1, 8909 Zwillikon',
  'missions', '[]'::jsonb, 'roadmap', '[]'::jsonb, 'heroImages', '[]'::jsonb,
  'liveSelectors', '[]'::jsonb,
  'updatedAt', now()
));

-- ------------------------------------------------------------ Zahlungen
-- Dieselben Schluessel wie bei Koretini, damit die QR-Rechnung in der
-- Vorfuehrung vollstaendig ist. Die IBAN ist ein PostFinance-Testkonto.
INSERT INTO public.settings (id, "tenantId", payment)
VALUES ('payment', 'demo', jsonb_build_object(
  'iban','CH4431999123000889012', 'qrIban','CH4431999123000889012',
  'bankName','PostFinance AG (Testkonto)',
  'accountHolder','Shoqata Demo — Musterverein',
  'street','Musterstrasse 1', 'zip','8909', 'city','Zwillikon',
  'country','Schweiz', 'bic','POFICHBEXXX',
  'paypalEmail','kasse@demo.unityhub.li',
  'twintUrl','', 'currency','CHF',
  'annualFeeAmount', 120, 'paymentTermsDays', 30, 'dunningDelayDays', 14,
  'fees', '[]'::jsonb
));

-- ------------------------------------------------------------- System
INSERT INTO public.settings (id, "tenantId", system)
VALUES ('system', 'demo', jsonb_build_object(
  'systemEmail','demo@unityhub.li',
  'allowRegistration', false,     -- niemand soll sich in der Demo anmelden
  'maintenanceMode', false,
  'spendenseite','AN',
  'modules', jsonb_build_object('news', true, 'events', true, 'villageLive', false),
  'updatedAt', now()
));


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE n int; name text;
BEGIN
  SELECT count(*) INTO n FROM public.settings WHERE "tenantId"='demo';
  IF n <> 3 THEN RAISE EXCEPTION 'Erwartet 3 Einstellungszeilen, gefunden %.', n; END IF;

  -- Die Zeile muss unter GENAU der Kennung liegen, die die App abfragt --
  -- das war der ganze Fehler.
  SELECT branding->'associationName'->>'de' INTO name
    FROM public.settings WHERE "tenantId"='demo' AND id='branding';
  IF name IS NULL THEN
    RAISE EXCEPTION 'Kein branding-Dokument mit associationName -- die App faellt wieder auf "Koretini" zurueck.';
  END IF;

  -- Und Koretini darf davon nichts abbekommen haben.
  IF (SELECT count(*) FROM public.settings WHERE "tenantId"='koretini') <> 4 THEN
    RAISE EXCEPTION 'Koretinis Einstellungen wurden veraendert.';
  END IF;

  RAISE NOTICE 'Demo-Marke gesetzt: %', name;
END $$;
