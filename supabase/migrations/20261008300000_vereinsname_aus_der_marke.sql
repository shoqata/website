-- "Koretini" stand an fuenf Stellen fest im Quelltext.
--
-- Gefunden, weil im Fuss der DEMO-Seite Koretini stand: der Fuss zeigt
-- die Wortmarke, und wo kein Logobild hinterlegt ist, stand dort
-- woertlich <h3>Koretini</h3>. Dieselbe Altlast steckt im Kopf
-- (`loc(branding.associationName) || 'Koretini'`), im Mitglieder-
-- Dashboard und in der Website-Verwaltung.
--
-- Das ist kein Demo-Problem, sondern ein Mehrmandanten-Problem: JEDER
-- weitere Verein haette so geheissen. Verschoben wird hier nichts --
-- der Quelltext liest den Namen kuenftig aus der Marke.
--
-- Damit das ohne sichtbare Aenderung fuer Koretini geht, braucht
-- Koretini selbst einen Namen in seinem branding-Dokument. Er fehlte
-- bisher, und genau deshalb griff der Rueckfall.

UPDATE public.settings
   SET branding = coalesce(branding, '{}'::jsonb)
       || jsonb_build_object('associationName',
            jsonb_build_object('de','Koretini','sq','Koretini','en','Koretini'))
 WHERE "tenantId" = 'koretini' AND id = 'branding'
   AND (branding -> 'associationName') IS NULL;

-- ---------------------------------------------------------- Selbsttest
DO $$
DECLARE k text; d text; fehlend int;
BEGIN
  SELECT branding->'associationName'->>'de' INTO k
    FROM public.settings WHERE "tenantId"='koretini' AND id='branding';
  SELECT branding->'associationName'->>'de' INTO d
    FROM public.settings WHERE "tenantId"='demo' AND id='branding';

  IF k IS NULL THEN
    RAISE EXCEPTION 'Koretini hat weiterhin keinen Namen in der Marke -- '
                    'der Rueckfall im Quelltext wuerde nach dessen Entfernung greifen.';
  END IF;
  IF d IS NULL THEN
    RAISE EXCEPTION 'Die Demo hat keinen Namen in der Marke.';
  END IF;
  IF k = d THEN
    RAISE EXCEPTION 'Beide Vereine tragen denselben Namen (%) -- dann ist nichts gewonnen.', k;
  END IF;

  -- Jeder Verein mit einem branding-Dokument braucht den Namen, sonst
  -- steht nach dem Entfernen des Rueckfalls dort nichts.
  SELECT count(*) INTO fehlend FROM public.settings
   WHERE id='branding' AND (branding -> 'associationName') IS NULL;
  IF fehlend > 0 THEN
    RAISE EXCEPTION '% Verein(e) haben ein branding-Dokument ohne associationName.', fehlend;
  END IF;

  RAISE NOTICE 'Namen gesetzt: koretini = "%", demo = "%"', k, d;
END $$;
