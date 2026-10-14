-- Die albanischen Vorlagen, durchgesehen.
--
-- Ein Befund ist ein echter Fehler, die anderen sind Ton und Idiom.
--
-- WILLKOMMEN sagte "kontributin E TIJ vjetor" -- SEINEN Jahresbeitrag.
-- Das deutsche Original sagt "Ihren Jahresbeitrag". Das Mitglied wird
-- also angesprochen und im naechsten Halbsatz zur dritten Person
-- gemacht. Das ist kein Stilfehler: der Satz liest sich, als ginge es um
-- jemand anderen.
--
-- Dazu drei Stellen, die verstanden werden, aber nicht klingen wie von
-- einem Verein geschrieben:
--
--   "si përgjigje e kësaj poste"   klingt nach Briefpost; gemeint ist
--                                  diese Nachricht
--   "paguhet ... aplikacionin bankar"  unpersoenlich, und die Wendung
--                                  heisst "aplikacioni i bankës"
--   "Ai shkon për ..."             umgangssprachlich fuer "wird
--                                  verwendet fuer"
--
-- Und die Mahnungen schlossen mit "Përshëndetje". Das ist ein Gruss zur
-- BEGRUESSUNG, kein Briefschluss. In einer Mahnung ist das die falsche
-- Tonlage -- WILLKOMMEN macht es mit "Me respekt" richtig.
--
-- DANK_SPENDE hatte ueberhaupt keinen Schluss: der Vereinsname stand
-- allein unter dem letzten Satz.
--
-- EINLADUNG_GV bleibt sprachlich, wie sie ist. Ihr Problem ist ein
-- anderes und liegt nicht im Text: {{datum}}, {{ort}} und
-- {{traktanden}} werden von keiner Stelle gefuellt. Dagegen steht jetzt
-- ein Riegel im Rundbrief, nicht eine Textaenderung.
--
-- WAS DIESE MIGRATION NICHT TUT: sie setzt keinen Pruefvermerk. Der
-- gehoert einem Menschen, der die Sprache spricht -- so steht es in
-- 20261010300000, und das bleibt richtig. Eine maschinelle Durchsicht
-- findet "e tij"; sie hoert nicht, ob ein Satz in Koretini so gesagt
-- wird.

DO $$
DECLARE
  v_vorher jsonb;
  v_nachher jsonb;
  v_n int;
BEGIN
  -- Vorher festhalten, welche Platzhalter in welcher Zeile stehen.
  -- Eine Textkorrektur, die versehentlich {{name}} mitnimmt, waere
  -- schlimmer als der Fehler, den sie behebt: der Brief gruesst dann
  -- niemanden.
  SELECT jsonb_object_agg(id::text, p) INTO v_vorher
    FROM (SELECT b.id,
                 coalesce((SELECT jsonb_agg(DISTINCT m[1] ORDER BY m[1])
                             FROM regexp_matches(b.betreff || ' ' || b.text,
                                   '\{\{\s*([A-Za-z0-9_.]+)\s*\}\}', 'g') AS m), '[]'::jsonb) AS p
            FROM public.textbausteine b WHERE b.sprache = 'sq') x;

  -- 1. Der echte Fehler: seinen -> Ihren.
  UPDATE public.textbausteine
     SET text = replace(text, 'kontributin e tij vjetor', 'kontributin tuaj vjetor')
   WHERE sprache = 'sq' AND text LIKE '%kontributin e tij vjetor%';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'WILLKOMMEN: "e tij" -> "tuaj" in % Zeile(n)', v_n;

  -- 2. Briefpost -> diese Nachricht.
  UPDATE public.textbausteine
     SET text = replace(text,
           'Nëse ndonjë e dhënë nuk është e saktë, shkruani thjesht si përgjigje e kësaj poste.',
           'Nëse ndonjë e dhënë nuk është e saktë, thjesht përgjigjuni këtij mesazhi.')
   WHERE sprache = 'sq' AND text LIKE '%si përgjigje e kësaj poste%';

  -- 3. Unpersoenlich -> ansprechend, und die richtige Wendung.
  UPDATE public.textbausteine
     SET text = replace(text,
           'me kodin QR paguhet brenda një minute në aplikacionin bankar',
           'me kodin QR mund të paguani brenda një minute në aplikacionin e bankës')
   WHERE sprache = 'sq' AND text LIKE '%paguhet brenda një minute%';

  -- 4. Gruss -> Briefschluss, in beiden Mahnungen.
  UPDATE public.textbausteine
     SET text = replace(text, E'Përshëndetje\n{{verein}}', E'Me respekt\n{{verein}}')
   WHERE sprache = 'sq' AND schluessel IN ('MAHNUNG_1','MAHNUNG_2')
     AND text LIKE E'%Përshëndetje\n{{verein}}%';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RAISE NOTICE 'Mahnungen: Briefschluss in % Zeile(n)', v_n;

  -- 5. "geht fuer" -> "wird verwendet fuer".
  UPDATE public.textbausteine
     SET text = replace(text, 'Ai shkon për {{zweck}}.', 'Ai do të përdoret për {{zweck}}.')
   WHERE sprache = 'sq' AND text LIKE '%Ai shkon për%';

  -- 6. Der fehlende Schluss beim Spendendank.
  UPDATE public.textbausteine
     SET text = replace(text, E'në fund të vitit.\n\n{{verein}}',
                              E'në fund të vitit.\n\nMe respekt\n{{verein}}')
   WHERE sprache = 'sq' AND schluessel = 'DANK_SPENDE'
     AND text LIKE E'%në fund të vitit.\n\n{{verein}}%'
     AND text NOT LIKE '%Me respekt%';

  -- ------------------------------------------------- Nachweis
  --
  -- a) Kein Platzhalter ist verlorengegangen oder dazugekommen.
  SELECT jsonb_object_agg(id::text, p) INTO v_nachher
    FROM (SELECT b.id,
                 coalesce((SELECT jsonb_agg(DISTINCT m[1] ORDER BY m[1])
                             FROM regexp_matches(b.betreff || ' ' || b.text,
                                   '\{\{\s*([A-Za-z0-9_.]+)\s*\}\}', 'g') AS m), '[]'::jsonb) AS p
            FROM public.textbausteine b WHERE b.sprache = 'sq') x;
  IF v_vorher IS DISTINCT FROM v_nachher THEN
    RAISE EXCEPTION 'Die Korrektur hat Platzhalter veraendert. Vorher % — nachher %',
      v_vorher, v_nachher;
  END IF;

  -- b) Der Fehler ist weg, und zwar ueberall.
  SELECT count(*) INTO v_n FROM public.textbausteine
   WHERE sprache = 'sq' AND (text LIKE '%e tij vjetor%'
                          OR text LIKE '%kësaj poste%'
                          OR text LIKE '%aplikacionin bankar%'
                          OR text LIKE '%Ai shkon për%');
  IF v_n > 0 THEN
    RAISE EXCEPTION '% albanische Vorlage(n) tragen noch eine der alten Wendungen.', v_n;
  END IF;

  -- c) Jede Mahnung hat jetzt einen Briefschluss, keinen Gruss.
  SELECT count(*) INTO v_n FROM public.textbausteine
   WHERE sprache = 'sq' AND schluessel IN ('MAHNUNG_1','MAHNUNG_2')
     AND text NOT LIKE '%Me respekt%';
  IF v_n > 0 THEN
    RAISE EXCEPTION '% albanische Mahnung(en) ohne Briefschluss.', v_n;
  END IF;

  -- d) Und der Pruefvermerk steht NICHT. Wer das hier aus Versehen
  --    setzte, naehme einem Menschen die Entscheidung ab.
  SELECT count(*) INTO v_n FROM public.textbausteine
   WHERE sprache = 'sq' AND geprueft_von IS NOT NULL;
  IF v_n > 0 THEN
    RAISE NOTICE '% albanische Vorlage(n) tragen einen Pruefvermerk — von einem Menschen?', v_n;
  END IF;

  RAISE NOTICE 'Albanische Vorlagen: korrigiert, Platzhalter unveraendert, Vermerk offen.';
END $$;
