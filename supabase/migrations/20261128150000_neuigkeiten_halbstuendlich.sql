-- Zeitgesteuerte Neuigkeiten alle 30 statt alle 10 Minuten melden.
-- Eine Neuigkeit kommt damit spaetestens eine halbe Stunde nach ihrem
-- Erscheinen in der Glocke und aufs Handy.
DO $$ BEGIN
  PERFORM cron.unschedule('neuigkeiten_melden') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'neuigkeiten_melden');
  PERFORM cron.schedule('neuigkeiten_melden', '*/30 * * * *', 'SELECT public.neuigkeiten_zeitgesteuert_melden()');
END $$;
