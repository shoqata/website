-- Zeitgesteuerte Neuigkeiten melden sich, wenn sie erscheinen.
--
-- Eine Neuigkeit mit publishAt in der Zukunft wird sichtbar, ohne dass sich
-- ihre Zeile aendert -- der Ausloeser melde_neuigkeit bekam davon nichts mit,
-- die Glocke blieb still. Jetzt schaut alle zehn Minuten ein Auftrag nach,
-- was inzwischen erschienen und noch nicht gemeldet ist.
--
-- benachrichtigt_am haelt fest, dass gemeldet wurde: so meldet sich eine
-- Neuigkeit genau einmal, auch wenn sie zurueckgezogen und wieder
-- veroeffentlicht wird.

ALTER TABLE public.news ADD COLUMN IF NOT EXISTS benachrichtigt_am timestamptz;

-- Was schon sichtbar ist, gilt als gemeldet -- sonst kaemen nach dem
-- Einspielen alle alten Neuigkeiten auf einmal.
UPDATE public.news SET benachrichtigt_am = now()
 WHERE status = 'PUBLISHED' AND ("publishAt" IS NULL OR "publishAt" <= now())
   AND benachrichtigt_am IS NULL;

CREATE OR REPLACE FUNCTION public.melde_neuigkeit() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  BEGIN
    IF NEW.status <> 'PUBLISHED' OR NEW.benachrichtigt_am IS NOT NULL THEN RETURN NEW; END IF;
    IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM 'PUBLISHED' THEN RETURN NEW; END IF;
    -- Zeitgesteuert: das uebernimmt der Auftrag unten, wenn es so weit ist.
    IF NEW."publishAt" IS NOT NULL AND NEW."publishAt"::timestamptz > now() THEN RETURN NEW; END IF;
    PERFORM public.benachrichtigen(NEW."tenantId", public.empfaenger_mitglieder(NEW."tenantId"),
      'NEUIGKEIT', coalesce(NEW.title, 'Neuigkeit'), NULL, '/news/' || NEW.id);
    -- Loest keinen Ausloeser aus: der haengt nur an UPDATE OF status.
    UPDATE public.news SET benachrichtigt_am = now() WHERE id = NEW.id;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Benachrichtigung (%) fehlgeschlagen: %', TG_TABLE_NAME, SQLERRM;
  END;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.neuigkeiten_zeitgesteuert_melden() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE n record; anzahl int := 0;
BEGIN
  FOR n IN
    SELECT id, "tenantId", title FROM public.news
     WHERE status = 'PUBLISHED' AND benachrichtigt_am IS NULL
       AND "publishAt" IS NOT NULL AND "publishAt" <= now()
       -- Nur Frisches: was laenger als einen Tag sichtbar ist, ist keine
       -- Neuigkeit mehr (etwa nach einem Ausfall des Auftrags).
       AND "publishAt" > now() - interval '1 day'
     FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      PERFORM public.benachrichtigen(n."tenantId", public.empfaenger_mitglieder(n."tenantId"),
        'NEUIGKEIT', coalesce(n.title, 'Neuigkeit'), NULL, '/news/' || n.id);
    EXCEPTION WHEN others THEN
      RAISE WARNING 'Neuigkeit % melden fehlgeschlagen: %', n.id, SQLERRM;
    END;
    UPDATE public.news SET benachrichtigt_am = now() WHERE id = n.id;
    anzahl := anzahl + 1;
  END LOOP;
  -- Auch aeltere, nie gemeldete still abhaken, damit sie nicht liegen bleiben.
  UPDATE public.news SET benachrichtigt_am = now()
   WHERE status = 'PUBLISHED' AND benachrichtigt_am IS NULL
     AND "publishAt" IS NOT NULL AND "publishAt" <= now() - interval '1 day';
  RETURN anzahl;
END $$;
REVOKE ALL ON FUNCTION public.neuigkeiten_zeitgesteuert_melden() FROM public, anon, authenticated;

DO $$ BEGIN
  PERFORM cron.unschedule('neuigkeiten_melden') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'neuigkeiten_melden');
  PERFORM cron.schedule('neuigkeiten_melden', '*/10 * * * *', 'SELECT public.neuigkeiten_zeitgesteuert_melden()');
END $$;
