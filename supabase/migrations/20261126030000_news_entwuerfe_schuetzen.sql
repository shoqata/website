-- Entwuerfe und geplante Nachrichten waren fuer jeden lesbar.
--
-- news_public_read pruefte nur Verein und Modul, nicht den Status. Die
-- Website filterte im Browser auf PUBLISHED -- wer die Schnittstelle
-- direkt fragte, bekam alles, auch Entwuerfe. Gemessen am 24.10.2026: im
-- Demo-Verein ein Entwurf von Floky mit einem Rechnungstext an ein
-- Mitglied, bei Koretini drei Entwuerfe.
--
-- Jetzt sehen Besucher und Mitglieder nur Veroeffentlichtes, dessen
-- Zeitpunkt erreicht ist. Verwaltung und Vorstand (is_staff: SUPER_ADMIN,
-- ADMIN, BOARD) sehen weiter alles -- ueber news_manage, das unveraendert
-- bleibt und auch das Schreiben regelt.
DROP POLICY IF EXISTS news_public_read ON public.news;
CREATE POLICY news_public_read ON public.news FOR SELECT
  USING ("tenantId" = (SELECT coalesce(public.current_tenant(), public.request_tenant()))
         AND public.modul_aktiv('NEUIGKEITEN')
         AND status = 'PUBLISHED'
         AND ("publishAt" IS NULL OR "publishAt" <= now()));

DO $$
DECLARE v_eigen text := current_user; v_n int;
BEGIN
  PERFORM set_config('request.headers', '{"origin":"https://demo.unityhub.li"}', true);
  EXECUTE 'SET LOCAL ROLE anon';
  SELECT count(*) INTO v_n FROM public.news WHERE status <> 'PUBLISHED';
  EXECUTE format('SET LOCAL ROLE %I', v_eigen);
  IF v_n > 0 THEN RAISE EXCEPTION 'Selbsttest: Besucher sehen % Entwuerfe', v_n; END IF;
END $$;
