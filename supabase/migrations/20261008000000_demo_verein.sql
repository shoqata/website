-- Ein Demo-Verein zum Vorfuehren.
--
-- Gedacht fuer demo.unityhub.li: dort soll ein Verein zu sehen sein, der
-- aussieht wie ein echter -- Mitglieder, Beitraege, Buchhaltung, Anlaesse
-- -- ohne dass dabei die Daten von Koretini auf einem Beamer landen.
--
-- Alle Namen, Adressen und Betraege sind erfunden. Das ist keine
-- Floskel, sondern der Grund fuer diese Migration: die Alternative waere
-- gewesen, Koretini vorzufuehren, und damit haette jede Vorfuehrung
-- offengelegt, wer dort Mitglied ist und wer seinen Beitrag schuldet.
--
-- Der Verein traegt alle_module_frei, damit in der Vorfuehrung jedes
-- Modul sichtbar ist -- sonst muesste man erklaeren, warum die Haelfte
-- fehlt.

-- ------------------------------------------------------------- Verein
INSERT INTO public.tenants
  (id, name, slug, domain, status, "primaryColor", "contactEmail",
   currency, "annualFee", alle_module_frei)
VALUES ('demo', 'Shoqata Demo — Musterverein', 'demo', 'demo.unityhub.li',
        'ACTIVE', '#0428CB', 'demo@unityhub.li', 'CHF', 0, true)
ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name, domain = EXCLUDED.domain,
      alle_module_frei = true, status = 'ACTIVE';

INSERT INTO public.tenant_domains (domain, "tenantId", "isPrimary")
VALUES ('demo.unityhub.li', 'demo', true)
ON CONFLICT (domain) DO UPDATE SET "tenantId" = 'demo', "isPrimary" = true;

-- ---------------------------------------------------------- Mitglieder
-- 24 Personen: eine Verwaltung, drei im Vorstand, zwanzig Mitglieder.
-- Genug, dass eine Liste nach Arbeit aussieht, wenig genug, dass sie
-- auf einen Bildschirm passt.
DELETE FROM public.accounting_journal  WHERE "tenantId" = 'demo';
DELETE FROM public.payments            WHERE "tenantId" = 'demo';
DELETE FROM public.users               WHERE "tenantId" = 'demo';
DELETE FROM public.accounting_accounts WHERE "tenantId" = 'demo';

INSERT INTO public.users
  (id, email, "displayName", "firstName", "lastName", role, "membershipStatus",
   "tenantId", "joinedAt", street, zip, city, country, "membershipCategory")
SELECT
  'demo-u' || lpad(i::text, 2, '0'),
  'person' || i || '@demo.unityhub.li',
  v.vorname || ' ' || v.nachname, v.vorname, v.nachname,
  CASE WHEN i = 1 THEN 'SUPER_ADMIN'
       WHEN i <= 4 THEN 'BOARD'
       ELSE 'MEMBER' END,
  'ACTIVE', 'demo',
  (DATE '2019-01-01' + (i * 37))::timestamptz,
  v.strasse, v.plz, v.ort, 'Schweiz',
  CASE WHEN i % 7 = 0 THEN 'PASSIV' ELSE 'AKTIV' END
FROM (VALUES
  (1,'Arben','Krasniqi','Dorfstrasse 4','8910','Affoltern am Albis'),
  (2,'Leonora','Berisha','Seeweg 21','8820','Wädenswil'),
  (3,'Ilir','Morina','Bahnhofstrasse 9','8800','Thalwil'),
  (4,'Valbona','Shala','Im Grund 7','8915','Hausen am Albis'),
  (5,'Besnik','Hoxha','Lindenweg 12','8903','Birmensdorf'),
  (6,'Fatime','Gashi','Rebbergstrasse 3','8942','Oberrieden'),
  (7,'Driton','Zeqiri','Alte Landstrasse 55','8802','Kilchberg'),
  (8,'Mirlinda','Dervishi','Schulhausweg 2','8907','Wettswil'),
  (9,'Agim','Rexhepi','Feldstrasse 18','8909','Zwillikon'),
  (10,'Teuta','Bytyqi','Kirchgasse 6','8912','Obfelden'),
  (11,'Shpend','Aliu','Mühlebachweg 14','8934','Knonau'),
  (12,'Blerta','Kelmendi','Zürichstrasse 40','8805','Richterswil'),
  (13,'Fisnik','Haliti','Oberdorfstrasse 8','8926','Kappel am Albis'),
  (14,'Donika','Sadiku','Waldeggweg 5','8143','Stallikon'),
  (15,'Burim','Osmani','Rainstrasse 29','8906','Bonstetten'),
  (16,'Shqipe','Luzha','Höhenweg 11','8046','Zürich'),
  (17,'Granit','Maloku','Brunnenstrasse 17','8143','Uitikon'),
  (18,'Vjosa','Thaqi','Sonnenbergstrasse 23','8832','Wollerau'),
  (19,'Lirim','Selimi','Gartenweg 1','8833','Samstagern'),
  (20,'Elona','Ismaili','Buchenweg 33','8810','Horgen'),
  (21,'Astrit','Nuhiu','Weinbergstrasse 2','8700','Küsnacht'),
  (22,'Nora','Kastrati','Seestrasse 101','8706','Meilen'),
  (23,'Jeton','Mustafa','Quellenstrasse 9','8604','Volketswil'),
  (24,'Albana','Vokshi','Hauptstrasse 44','8623','Wetzikon')
) AS v(i, vorname, nachname, strasse, plz, ort);

-- ---------------------------------------------------------- Kontenplan
-- Muss VOR den Beitraegen stehen: ein Trigger (book_payment_entries)
-- verbucht jede Zahlung sofort auf 1100/3000, und ohne diese Konten
-- bricht schon der erste Insert ab. Beim ersten Anlauf genau das
-- passiert -- die Reihenfolge ist hier keine Geschmacksfrage.
INSERT INTO public.accounting_accounts (id, code, name, class, category, "systemAccount", "tenantId")
VALUES
 ('demo-1020','1020','Bankguthaben PostFinance','AKTIVEN','UMLAUFVERMOEGEN',true,'demo'),
 ('demo-1100','1100','Forderungen Mitgliederbeiträge','AKTIVEN','UMLAUFVERMOEGEN',true,'demo'),
 ('demo-2000','2000','Verbindlichkeiten','PASSIVEN','FREMDKAPITAL',true,'demo'),
 ('demo-2900','2900','Vereinsvermögen','PASSIVEN','EIGENKAPITAL',true,'demo'),
 ('demo-3000','3000','Ertrag Mitgliederbeiträge','ERTRAG','BETRIEBSERTRAG',true,'demo'),
 ('demo-3200','3200','Ertrag Spenden','ERTRAG','BETRIEBSERTRAG',false,'demo'),
 ('demo-3600','3600','Erträge aus Veranstaltungen','ERTRAG','BETRIEBSERTRAG',false,'demo'),
 ('demo-4000','4000','Verwaltungsaufwand','AUFWAND','BETRIEBSAUFWAND',false,'demo'),
 ('demo-4400','4400','Aufwand Kultur & Anlässe','AUFWAND','BETRIEBSAUFWAND',false,'demo'),
 ('demo-6000','6000','Raumaufwand','AUFWAND','BETRIEBSAUFWAND',false,'demo');
-- Kein ON CONFLICT: auf (tenantId, code) liegt kein eindeutiger Index,
-- und die Demo-Konten werden oben ohnehin geloescht. Eine Klausel, die
-- nur dann traegt, wenn ein Index existiert, waere hier eine Annahme.

-- ------------------------------------------------------------ Beitraege
-- Zwei Drittel bezahlt, ein Drittel offen, drei davon gemahnt. Ein
-- Beitragsjahr, in dem alles bezahlt ist, zeigt nichts.
INSERT INTO public.payments
  (id, "userId", "tenantId", amount, currency, type, "billingYear", method,
   status, "dueDate", "paidAt", "invoiceNumber", description, "dunningLevel")
SELECT
  'demo-p' || lpad(i::text, 2, '0'),
  'demo-u' || lpad(i::text, 2, '0'),
  'demo',
  CASE WHEN i % 7 = 0 THEN 60 ELSE 120 END,
  'CHF', 'MEMBERSHIP_FEE', 2026, 'QR_BILL',
  CASE WHEN i % 3 = 0 THEN 'PENDING' ELSE 'PAID' END,
  DATE '2026-03-31',
  CASE WHEN i % 3 = 0 THEN NULL ELSE (DATE '2026-02-01' + i)::timestamptz END,
  'R-2026-' || lpad(i::text, 4, '0'),
  'Mitgliederbeitrag 2026',
  CASE WHEN i % 3 = 0 AND i % 2 = 0 THEN 1 ELSE 0 END
FROM generate_series(1, 24) AS i;

-- ------------------------------------------------- Einstellungen & Marke
-- Die Zahlungsangaben sind nachgebaut, aber formal gueltig: die IBAN
-- stammt aus dem Testbereich von PostFinance, damit die QR-Rechnung in
-- der Vorfuehrung echt aussieht und trotzdem auf kein Konto zeigt.
INSERT INTO public.settings (id, "tenantId", payment, company, branding, system)
VALUES ('demo-settings', 'demo',
  jsonb_build_object(
    'iban','CH4431999123000889012', 'qrIban','CH4431999123000889012',
    'bankName','PostFinance AG (Testkonto)', 'accountHolder','Shoqata Demo — Musterverein',
    'street','Musterstrasse 1', 'zip','8909', 'city','Zwillikon', 'country','Schweiz',
    'bic','POFICHBEXXX', 'paypalEmail','kasse@demo.unityhub.li',
    'twintNumber','079 000 00 00', 'currency','CHF', 'annualFeeAmount',120),
  jsonb_build_object('name','Shoqata Demo — Musterverein','email','demo@unityhub.li'),
  jsonb_build_object('associationName', jsonb_build_object(
      'de','Shoqata Demo — Musterverein','sq','Shoqata Demo','en','Demo Association')),
  '{}'::jsonb)
ON CONFLICT ("tenantId", id) DO UPDATE SET payment = EXCLUDED.payment,
  company = EXCLUDED.company, branding = EXCLUDED.branding;

-- ---------------------------------------------------------- Anlaesse
DELETE FROM public.events WHERE "tenantId" = 'demo';
INSERT INTO public.events (id, title, description, date, time, location, "tenantId", status, "isRegistrable")
VALUES
 ('demo-e1','Generalversammlung 2026','Jahresbericht, Rechnung, Wahlen. Anschliessend Abendessen.',
  DATE '2026-11-21','18:30','Gemeindesaal Zwillikon','demo','PUBLISHED',true),
 ('demo-e2','Familientag','Spiele für Kinder, Grill, Musik. Für Mitglieder und Gäste.',
  DATE '2026-06-13','11:00','Waldhütte Hausen','demo','PUBLISHED',true);

DELETE FROM public.news WHERE "tenantId" = 'demo';
INSERT INTO public.news (id, title, content, "timestamp", author, "tenantId", status)
VALUES
 ('demo-n1','Beiträge 2026 sind verschickt',
  'Alle Mitglieder haben ihre Rechnung mit QR-Code erhalten. Wer sie nicht findet, meldet sich beim Kassier.',
  now() - interval '20 days','Vorstand','demo','PUBLISHED'),
 ('demo-n2','Neue Vereinsstatuten angenommen',
  'Die ausserordentliche Versammlung hat die überarbeiteten Statuten einstimmig angenommen.',
  now() - interval '60 days','Vorstand','demo','PUBLISHED');


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE m int; b int; z int; o int; d text;
BEGIN
  SELECT count(*) INTO m FROM public.users WHERE "tenantId"='demo';
  SELECT count(*) INTO b FROM public.payments WHERE "tenantId"='demo';
  SELECT count(*) INTO z FROM public.payments WHERE "tenantId"='demo' AND status='PAID';
  SELECT count(*) INTO o FROM public.payments WHERE "tenantId"='demo' AND status='PENDING';
  SELECT "tenantId" INTO d FROM public.tenant_domains WHERE domain='demo.unityhub.li';

  IF m <> 24 THEN RAISE EXCEPTION 'Erwartet 24 Mitglieder, gefunden %.', m; END IF;
  IF b <> 24 THEN RAISE EXCEPTION 'Erwartet 24 Beitraege, gefunden %.', b; END IF;
  IF d IS DISTINCT FROM 'demo' THEN RAISE EXCEPTION 'Domain zeigt nicht auf demo: %', d; END IF;

  -- Der Kern: kein einziger Datensatz von Koretini darf mitgekommen sein,
  -- und umgekehrt darf die Demo nichts von Koretini tragen.
  IF EXISTS (SELECT 1 FROM public.users WHERE "tenantId"='demo'
              AND email IN (SELECT email FROM public.users WHERE "tenantId"='koretini')) THEN
    RAISE EXCEPTION 'Eine Demo-Adresse stimmt mit einer echten ueberein.';
  END IF;

  RAISE NOTICE 'Demo-Verein: % Mitglieder, % Beitraege (% bezahlt, % offen), Domain demo.unityhub.li',
    m, b, z, o;
END $$;
