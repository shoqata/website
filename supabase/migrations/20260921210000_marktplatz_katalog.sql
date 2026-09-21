-- Der Katalog. Preise bewusst noch leer: sie sind eine Verkaufsentscheidung
-- und stehen noch aus. NULL heisst "im Grundpreis enthalten" -- solange
-- nichts Gegenteiliges eingetragen ist, kostet kein Modul extra.
INSERT INTO public.modules
  (schluessel, name_de, name_sq, name_en, beschreibung_de, beschreibung_sq, beschreibung_en,
   ist_kern, status, braucht_einrichtung, reihenfolge)
VALUES
  ('MITGLIEDER','Mitglieder & Nachbarschaften','Anëtarët & lagjet','Members & neighbourhoods',
   'Mitgliederverzeichnis, Nachbarschaften und verantwortliche Personen.',
   'Regjistri i anëtarëve, lagjet dhe personat përgjegjës.',
   'Member register, neighbourhoods and responsible persons.',
   true,'VERFUEGBAR',false,10),

  ('FINANZEN','Finanzen & QR-Rechnung','Financat & fatura QR','Finance & QR invoice',
   'Mitgliederbeiträge, Swiss-QR-Rechnungen, Mahnwesen.',
   'Kuotat e anëtarësisë, faturat Swiss QR, kujtesat.',
   'Membership fees, Swiss QR invoices, reminders.',
   true,'VERFUEGBAR',false,20),

  ('VORSTAND','Vorstand & Protokolle','Bordi & procesverbalet','Board & minutes',
   'Vorstandsansicht, Protokolle mit Versionen, Freigabe an Mitglieder.',
   'Pamja e bordit, procesverbalet me versione, publikimi për anëtarët.',
   'Board view, minutes with versions, release to members.',
   true,'VERFUEGBAR',false,30),

  ('BUCHHALTUNG','Buchhaltung','Kontabiliteti','Accounting',
   'Journal, Kontenplan, Geschäftsjahre und Budgets.',
   'Ditari, plani i llogarive, vitet fiskale dhe buxhetet.',
   'Journal, chart of accounts, fiscal years and budgets.',
   false,'VERFUEGBAR',false,40),

  ('STAMMBAUM','Stammbaum','Pema familjare','Family tree',
   'Familien erfassen; Cousins, Onkel und Grosseltern ergeben sich daraus.',
   'Regjistrimi i familjeve; kushërinjtë dhe gjyshërit dalin vetvetiu.',
   'Record families; cousins, uncles and grandparents follow by themselves.',
   false,'VERFUEGBAR',false,50),

  ('ANLAESSE','Anlässe','Ngjarjet','Events',
   'Veranstaltungen ankündigen, Anmeldungen entgegennehmen.',
   'Njoftimi i ngjarjeve, pranimi i regjistrimeve.',
   'Announce events, take registrations.',
   false,'VERFUEGBAR',false,60),

  ('NEUIGKEITEN','Neuigkeiten','Lajmet','News',
   'Beiträge auf der Vereinswebsite veröffentlichen.',
   'Publikimi i artikujve në faqen e shoqatës.',
   'Publish articles on the association website.',
   false,'VERFUEGBAR',false,70),

  ('DORFLEBEN','Dorfleben','Jeta e fshatit','Village life',
   'Was im Dorf läuft, nach Bereichen: Gesundheit, Wasser, Energie, Bildung.',
   'Çfarë ndodh në fshat, sipas fushave: shëndetësia, uji, energjia, arsimi.',
   'What is happening in the village, by area: health, water, energy, education.',
   false,'VERFUEGBAR',false,80),

  ('TURNIER','Turnier & Sponsoring','Turneu & sponsorizimi','Tournament & sponsoring',
   'Turnierseite, Anmeldung und Sponsorenpakete.',
   'Faqja e turneut, regjistrimi dhe paketat e sponsorizimit.',
   'Tournament page, registration and sponsor packages.',
   false,'VERFUEGBAR',false,90),

  ('SOCIAL','Soziale Medien','Rrjetet sociale','Social media',
   'Beiträge vorbereiten und planen. Das Veröffentlichen auf Facebook und Instagram ist noch nicht angebunden.',
   'Përgatitja dhe planifikimi i postimeve. Publikimi në Facebook dhe Instagram ende nuk është i lidhur.',
   'Prepare and schedule posts. Publishing to Facebook and Instagram is not connected yet.',
   false,'BETA',true,100),

  ('SPENDEN','Spenden','Donacionet','Donations',
   'Öffentliche Spendenseite, QR-Zahlung und Spendenbescheinigung.',
   'Faqe publike donacionesh, pagesë me QR dhe vërtetim donacioni.',
   'Public donation page, QR payment and donation receipt.',
   false,'EINGESTELLT',false,110)
ON CONFLICT (schluessel) DO UPDATE SET
  name_de = excluded.name_de, name_sq = excluded.name_sq, name_en = excluded.name_en,
  beschreibung_de = excluded.beschreibung_de, beschreibung_sq = excluded.beschreibung_sq,
  beschreibung_en = excluded.beschreibung_en,
  ist_kern = excluded.ist_kern, status = excluded.status,
  braucht_einrichtung = excluded.braucht_einrichtung, reihenfolge = excluded.reihenfolge;

DO $$
DECLARE r record; v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM public.modules;
  RAISE NOTICE 'Katalog: % Module', v_n;
  FOR r IN SELECT schluessel, name_de, ist_kern, status FROM public.modules ORDER BY reihenfolge LOOP
    RAISE NOTICE '  % | % | %', rpad(r.schluessel,13),
      rpad(r.name_de,30), CASE WHEN r.ist_kern THEN 'Kern' ELSE r.status END;
  END LOOP;
END $$;
