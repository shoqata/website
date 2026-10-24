-- Ein Zugang fuer ein bestimmtes Geschaeftsjahr liefert dieses Jahr, statt
-- eine Anfrage fuer ein anderes abzuweisen. Sonst stuende beim Oeffnen
-- jedes solchen Links zuerst ein abgewiesener Versuch im Protokoll -- die
-- Seite fragt beim Laden das laufende Jahr ab.
CREATE OR REPLACE FUNCTION public.revisionsdaten(p_token text, p_jahr integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  z public.revisionszugaenge%ROWTYPE;
  v_kopf jsonb := coalesce(nullif(current_setting('request.headers', true), '')::jsonb, '{}'::jsonb);
  v_ip text := nullif(btrim(split_part(coalesce(v_kopf ->> 'x-forwarded-for', v_kopf ->> 'x-real-ip', ''), ',', 1)), '');
  v_browser text := left(v_kopf ->> 'user-agent', 200);
  v_ergebnis text := 'OK';
  v_jahr int;
BEGIN
  SELECT * INTO z FROM public.revisionszugaenge
   WHERE token_hash = encode(digest(coalesce(p_token,''), 'sha256'), 'hex');

  -- Unbekannt: dieselbe Meldung wie abgelaufen oder widerrufen.
  IF z.id IS NULL THEN
    RETURN jsonb_build_object('fehler', 'Dieser Zugang ist nicht (mehr) gueltig.');
  END IF;

  v_jahr := coalesce(z.jahr, p_jahr);
  IF z.widerrufen_am IS NOT NULL THEN v_ergebnis := 'WIDERRUFEN';
  ELSIF z.gueltig_bis < current_date THEN v_ergebnis := 'ABGELAUFEN';
  END IF;

  INSERT INTO public.revisionszugriffe ("tenantId", zugang, jahr, ergebnis, ip, browser)
  VALUES (z."tenantId", z.id, v_jahr, v_ergebnis, v_ip, v_browser);

  IF v_ergebnis <> 'OK' THEN
    RETURN jsonb_build_object('fehler', 'Dieser Zugang ist nicht (mehr) gueltig.');
  END IF;

  UPDATE public.revisionszugaenge
     SET zuletzt_gesehen = now(), zugriffe = zugriffe + 1
   WHERE id = z.id;

  RETURN public.revisionsbericht_fuer(z."tenantId", v_jahr)
         || jsonb_build_object('zugang', jsonb_build_object(
              'fuer', z.bezeichnung, 'gueltig_bis', z.gueltig_bis, 'jahr', z.jahr));
END $function$;
