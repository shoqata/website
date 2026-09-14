-- Korrektur an Stufe 1.
--
-- Auf platform_admins stand FORCE ROW LEVEL SECURITY. FORCE unterwirft auch den
-- Eigentuemer den Regeln -- und damit die SECURITY-DEFINER-Funktion
-- is_platform_admin(), die genau diese Tabelle lesen muss. Da die Tabelle keine
-- einzige Policy hat, haette die Funktion nie jemanden gefunden und immer false
-- geliefert: die Plattformrolle waere tot gewesen, ohne dass es auffaellt.
--
-- Der Schutz haengt ohnehin nicht an FORCE: anon und authenticated haben auf der
-- Tabelle keinerlei Rechte, und ohne Policy kommt kein Client an sie heran.
ALTER TABLE public.platform_admins NO FORCE ROW LEVEL SECURITY;

-- Nachweis, dass die Erkennung jetzt greift. Laeuft in dieser Transaktion und
-- hinterlaesst nichts.
DO $$
DECLARE
  v_hit boolean;
  v_miss boolean;
BEGIN
  PERFORM set_config('request.jwt.claims', '{"email":"email@dervishi.ch"}', true);
  SELECT public.is_platform_admin() INTO v_hit;

  PERFORM set_config('request.jwt.claims', '{"email":"fremde@example.com"}', true);
  SELECT public.is_platform_admin() INTO v_miss;

  PERFORM set_config('request.jwt.claims', '', true);

  IF v_hit AND NOT v_miss THEN
    RAISE NOTICE 'PLATTFORMROLLE: eingetragene Adresse erkannt, fremde abgewiesen -- wirkt.';
  ELSE
    RAISE EXCEPTION 'PLATTFORMROLLE DEFEKT: eingetragen=% fremd=%', v_hit, v_miss;
  END IF;
END $$;
