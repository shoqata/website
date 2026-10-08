-- Modul "Floky" im Marktplatz.
--
-- Der Preis ist einstellbar, ohne dass jemand Code anfasst: der Betreiber
-- aendert preis_monat in der Modulverwaltung
-- (SuperAdminModule -> modul_katalog_speichern). Die 9.00 hier sind ein
-- Startwert, keine Festlegung.
--
-- Status BETA, nicht VERFUEGBAR -- und das ist Absicht. Der Assistent ist
-- noch nicht gebaut. Ein Modul, das sich buchen laesst und nichts tut,
-- waere genau der Fehler, den DORFLEBEN und TURNIER heute schon machen:
-- ein Schalter ohne Wirkung. Sobald Floky laeuft, wird der Status
-- umgestellt -- auch das geht in der Modulverwaltung, ohne Migration.

INSERT INTO public.modules (schluessel, name_de, name_sq, name_en,
                            beschreibung_de, beschreibung_sq, beschreibung_en,
                            ist_kern, status, braucht_einrichtung,
                            preis_monat, reihenfolge)
SELECT 'FLOKY',
  'Floky — Vereinsassistent', 'Floky — ndihmësi i shoqatës', 'Floky — association assistant',
  'Ein Helfer, der Auftraege in Alltagssprache entgegennimmt — deutsch, albanisch oder englisch — und Mitgliederpflege, Beitragslaeufe, Buchungen, Einladungen und Texte vorbereitet. Er schlaegt vor, der Vorstand entscheidet: nichts wird gebucht, verschickt oder veroeffentlicht ohne Bestaetigung. Mitglieder fragen ihn selbst, was sie noch schulden, statt den Kassier am Abend anzuschreiben.',
  'Një ndihmës që i merr detyrat në gjuhë të përditshme — shqip, gjermanisht ose anglisht — dhe përgatit mirëmbajtjen e anëtarëve, kuotat, regjistrimet, ftesat dhe tekstet. Ai propozon, kryesia vendos: asgjë nuk regjistrohet, dërgohet ose publikohet pa konfirmim. Anëtarët e pyesin vetë sa kanë mbetur për të paguar.',
  'An assistant that takes instructions in plain language — German, Albanian or English — and prepares member records, fee runs, bookings, invitations and texts. It proposes, the board decides: nothing is booked, sent or published without confirmation. Members ask it themselves what they still owe, instead of messaging the treasurer in the evening.',
  false, 'BETA', false, 9.00, 45
 WHERE NOT EXISTS (SELECT 1 FROM public.modules WHERE schluessel='FLOKY');


-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE r RECORD; gebucht int;
BEGIN
  SELECT schluessel, name_de, status, preis_monat, ist_kern INTO r
    FROM public.modules WHERE schluessel='FLOKY';
  IF r.schluessel IS NULL THEN RAISE EXCEPTION 'Modul FLOKY steht nicht im Katalog.'; END IF;
  IF r.ist_kern THEN RAISE EXCEPTION 'FLOKY darf kein Kernmodul sein -- es muss abschaltbar bleiben.'; END IF;
  IF coalesce(r.preis_monat,0) <= 0 THEN
    RAISE EXCEPTION 'Ohne Monatspreis wird FLOKY in der Jahresrechnung nicht mitgerechnet.';
  END IF;

  -- Solange es BETA ist, darf es kein Verein gebucht haben: sonst zahlte
  -- jemand fuer etwas, das es noch nicht gibt.
  SELECT count(*) INTO gebucht FROM public.tenant_modules
   WHERE modul='FLOKY' AND zustand IN ('AN','TESTPHASE');
  IF r.status = 'BETA' AND gebucht > 0 THEN
    RAISE EXCEPTION '% Verein(e) haben FLOKY gebucht, obwohl es noch BETA ist.', gebucht;
  END IF;

  RAISE NOTICE 'Modul % angelegt: % · % · CHF %/Monat (in der Modulverwaltung aenderbar)',
    r.schluessel, r.name_de, r.status, r.preis_monat;
END $$;
