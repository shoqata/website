-- Kommunikation und Vereinsadressen als eigenes Modul (Paket Voll).
--
-- Wie bei WEBSITE: jeder bestehende und jeder kuenftige Verein hat es AN,
-- damit sich fuer niemanden etwas aendert. Ausgeschaltet wird es nur ueber
-- ein Paket (heute: Demoverein auf Light).
--
-- Gesperrt wird in der Verwaltung (Reiter ausgegraut). Die Daten dahinter
-- (Umfragen, Sponsoren, Vereinsadressen) haengen nicht an diesem Modul --
-- die Anfragen und der Postausgang gehoeren zum Vorstand und bleiben im Kern.

INSERT INTO public.modules (schluessel, name_de, name_sq, name_en,
                            beschreibung_de, beschreibung_sq, beschreibung_en,
                            ist_kern, status, braucht_einrichtung, reihenfolge)
VALUES ('KOMMUNIKATION', 'Kommunikation & Vereinsadressen', 'Komunikimi & adresat e shoqatës', 'Communication & club addresses',
        'Umfragen, Sponsorenverwaltung, E-Mail-Versand und eigene Vereinsadressen (vorname@verein) mit Weiterleitung.',
        'Sondazhe, sponsorët, dërgimi i e-maileve dhe adresa vetjake të shoqatës (emri@shoqata) me përcjellje.',
        'Polls, sponsor management, e-mail sending and own club addresses (name@club) with forwarding.',
        false, 'VERFUEGBAR', false, 36)
ON CONFLICT (schluessel) DO NOTHING;

INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
SELECT t.id, 'KOMMUNIKATION', 'AN' FROM public.tenants t
ON CONFLICT ("tenantId", modul) DO NOTHING;

CREATE OR REPLACE FUNCTION public.website_modul_fuer_neuen_verein()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.tenant_modules ("tenantId", modul, zustand)
  VALUES (NEW.id, 'WEBSITE', 'AN'), (NEW.id, 'KOMMUNIKATION', 'AN')
  ON CONFLICT ("tenantId", modul) DO NOTHING;
  RETURN NEW;
END $$;

-- Steht der Demoverein gerade auf Light, gilt das neue Modul dort sofort als aus.
SELECT public._demo_paket_anwenden(paket) FROM public.demo_stand WHERE id = 1 AND paket = 'LIGHT';
