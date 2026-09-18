-- Benachrichtigung, wenn eine Anfrage eingeht.
--
-- Der Eintrag im Bereich des Betreibers ist das Bleibende -- dort bekommt die
-- Anfrage eine Stufe und laesst sich ueber Wochen begleiten. Die Nachricht ist
-- nur der Anstoss, damit niemand regelmaessig nachsehen muss.
--
-- Sie geht in dieselbe Warteschlange wie alles andere. Solange kein
-- Postausgang hinterlegt ist, bleibt sie dort sichtbar stehen, statt still
-- verlorenzugehen. Die Anfrage selbst ist davon unabhaengig gespeichert.
CREATE OR REPLACE FUNCTION public.submit_platform_lead(
  p_name    text,
  p_contact text,
  p_email   text,
  p_phone   text DEFAULT NULL,
  p_city    text DEFAULT NULL,
  p_members int  DEFAULT NULL,
  p_note    text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_name    text := btrim(coalesce(p_name, ''));
  v_kontakt text := btrim(coalesce(p_contact, ''));
  v_mail    text := lower(btrim(coalesce(p_email, '')));
  v_ort     text := btrim(coalesce(p_city, ''));
  v_tel     text := btrim(coalesce(p_phone, ''));
  v_notiz   text := btrim(coalesce(p_note, ''));
  v_empfaenger text := 'email@trifti.ch';
  v_zuletzt int;
  v_html    text;
BEGIN
  IF v_name = '' THEN
    RAISE EXCEPTION 'Name des Vereins fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_kontakt = '' THEN
    RAISE EXCEPTION 'Ansprechperson fehlt.' USING ERRCODE = 'check_violation';
  END IF;
  IF v_mail !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'E-Mail-Adresse ist unvollstaendig.' USING ERRCODE = 'check_violation';
  END IF;

  SELECT count(*) INTO v_zuletzt FROM public.platform_leads
   WHERE lower(coalesce(email, '')) = v_mail
     AND "createdAt" > now() - interval '5 minutes';
  IF v_zuletzt > 0 THEN
    RETURN true;
  END IF;

  INSERT INTO public.platform_leads
    (name, "contactName", email, phone, city, "expectedMembers", note, stage, "createdAt")
  VALUES (
    left(v_name, 200), left(v_kontakt, 200), left(v_mail, 200),
    left(v_tel, 60), left(v_ort, 120),
    CASE WHEN p_members IS NULL THEN NULL ELSE greatest(0, least(p_members, 100000)) END,
    left(v_notiz, 2000), 'LEAD', now()
  );

  -- Der Text enthaelt nur, was der Absender selbst angegeben hat.
  v_html :=
       '<div style="font-family:Georgia,serif;max-width:560px;margin:0 auto;padding:28px;color:#1c1917">'
    || '<p style="font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#78716c;margin:0 0 6px">'
    || 'Neue Anfrage</p>'
    || '<p style="font-size:24px;font-weight:bold;margin:0 0 20px">' || v_name || '</p>'
    || '<table style="font-size:14px;line-height:1.7;border-collapse:collapse">'
    || '<tr><td style="color:#78716c;padding-right:16px">Ansprechperson</td><td><b>' || v_kontakt || '</b></td></tr>'
    || '<tr><td style="color:#78716c;padding-right:16px">E-Mail</td><td><a href="mailto:' || v_mail || '">' || v_mail || '</a></td></tr>'
    || CASE WHEN v_tel <> '' THEN '<tr><td style="color:#78716c;padding-right:16px">Telefon</td><td>' || v_tel || '</td></tr>' ELSE '' END
    || CASE WHEN v_ort <> '' THEN '<tr><td style="color:#78716c;padding-right:16px">Ort</td><td>' || v_ort || '</td></tr>' ELSE '' END
    || CASE WHEN p_members IS NOT NULL THEN '<tr><td style="color:#78716c;padding-right:16px">Mitglieder</td><td>' || p_members || '</td></tr>' ELSE '' END
    || '</table>'
    || CASE WHEN v_notiz <> '' THEN
         '<p style="font-size:14px;line-height:1.7;margin:20px 0 0;padding:16px;background:#faf9f6;border-radius:12px">'
         || replace(left(v_notiz, 2000), E'\n', '<br>') || '</p>'
       ELSE '' END
    || '<p style="font-size:12px;color:#a8a29e;margin:28px 0 0">'
    || 'Die Anfrage steht im Betreiberbereich unter Interessenten.</p></div>';

  BEGIN
    INSERT INTO public.mail_queue ("tenantId", recipient, subject, html, kind)
    VALUES ('plattform', v_empfaenger,
            'Neue Anfrage: ' || left(v_name, 120), v_html, 'LEAD');
  EXCEPTION WHEN others THEN
    -- Die Anfrage ist gespeichert. Sollte die Benachrichtigung scheitern, darf
    -- das nicht dazu fuehren, dass der Absender eine Fehlermeldung sieht und
    -- es noch einmal versucht.
    NULL;
  END;

  RETURN true;
END $$;

REVOKE ALL ON FUNCTION public.submit_platform_lead(text, text, text, text, text, int, text) FROM public;
GRANT EXECUTE ON FUNCTION public.submit_platform_lead(text, text, text, text, text, int, text)
  TO anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ------------------------------------------------------------- Gegenprobe
DO $$
DECLARE v_back text := current_user; v_leads int; v_post int;
BEGIN
  SELECT count(*) INTO v_leads FROM public.platform_leads;
  SELECT count(*) INTO v_post  FROM public.mail_queue;

  EXECUTE 'SET ROLE anon';
  PERFORM public.submit_platform_lead('Pruefverein Zwei', 'Eine Person',
                                      'pruef2@example.invalid', NULL, 'Bern', 80, 'Selbsttest');
  EXECUTE format('SET ROLE %I', v_back);

  RAISE NOTICE '1 Interessenten: % -> %', v_leads, (SELECT count(*) FROM public.platform_leads);
  RAISE NOTICE '2 Warteschlange: % -> %', v_post, (SELECT count(*) FROM public.mail_queue);
  RAISE NOTICE '3 Empfaenger der Benachrichtigung: %',
    (SELECT recipient FROM public.mail_queue WHERE kind = 'LEAD' ORDER BY "createdAt" DESC LIMIT 1);
  RAISE NOTICE '4 Betreff: %',
    (SELECT subject FROM public.mail_queue WHERE kind = 'LEAD' ORDER BY "createdAt" DESC LIMIT 1);

  DELETE FROM public.mail_queue WHERE kind = 'LEAD' AND recipient = 'email@trifti.ch'
     AND subject LIKE '%Pruefverein Zwei%';
  DELETE FROM public.platform_leads WHERE email = 'pruef2@example.invalid';
  RAISE NOTICE 'Testanfrage entfernt: % Interessenten, % in der Warteschlange',
    (SELECT count(*) FROM public.platform_leads), (SELECT count(*) FROM public.mail_queue);
END $$;
