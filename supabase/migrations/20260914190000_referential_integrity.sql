-- Fremdschluessel und Indizes.
--
-- Bisher gab es im gesamten Schema keinen einzigen Fremdschluessel und drei
-- Indizes. Dass die Daten trotzdem sauber sind -- keine Zahlung zeigt auf ein
-- fehlendes Mitglied, keine Buchung auf ein unbekanntes Konto -- war Glueck,
-- nicht Zusicherung. Genau deshalb laesst es sich jetzt nachholen.
--
-- Jede Beziehung wird zuerst gemessen. Nur was leer ausgeht, bekommt den
-- Schluessel; alles andere wird benannt statt stillschweigend uebergangen.
--
-- ON DELETE RESTRICT statt CASCADE: ein Mitglied mit Zahlungen soll sich nicht
-- loeschen lassen, sondern auf inaktiv gesetzt werden -- und ein Verein nicht,
-- solange Daten an ihm haengen. Loeschen wird damit zur bewussten Handlung.

DO $fk$
DECLARE
  bez record;
  n int;
  gesetzt int := 0;
  offen   int := 0;
BEGIN
  FOR bez IN
    SELECT * FROM (VALUES
      ('users',               'tenantId',            'tenants',            'id'),
      ('payments',            'tenantId',            'tenants',            'id'),
      ('expenses',            'tenantId',            'tenants',            'id'),
      ('accounting_journal',  'tenantId',            'tenants',            'id'),
      ('accounting_accounts', 'tenantId',            'tenants',            'id'),
      ('fiscal_years',        'tenantId',            'tenants',            'id'),
      ('fiscal_budgets',      'tenantId',            'tenants',            'id'),
      ('board_meetings',      'tenantId',            'tenants',            'id'),
      ('board_members',       'tenantId',            'tenants',            'id'),
      ('tasks',               'tenantId',            'tenants',            'id'),
      ('neighborhoods',       'tenantId',            'tenants',            'id'),
      ('events',              'tenantId',            'tenants',            'id'),
      ('news',                'tenantId',            'tenants',            'id'),
      ('polls',               'tenantId',            'tenants',            'id'),
      ('socialmediaposts',    'tenantId',            'tenants',            'id'),
      ('event_registrations', 'tenantId',            'tenants',            'id'),
      ('inquiries',           'tenantId',            'tenants',            'id'),
      ('security_logs',       'tenantId',            'tenants',            'id'),
      ('settings',            'tenantId',            'tenants',            'id'),
      ('payments',            'userId',              'users',              'id'),
      ('board_members',       'userId',              'users',              'id'),
      ('inquiries',           'userId',              'users',              'id'),
      ('event_registrations', 'userId',              'users',              'id'),
      ('event_registrations', 'eventId',             'events',             'id'),
      ('users',               'neighborhoodId',      'neighborhoods',      'id'),
      ('payments',            'neighborhoodId',      'neighborhoods',      'id'),
      ('tasks',               'sourceMeetingId',     'board_meetings',     'id'),
      ('accounting_journal',  'debitCode',           'accounting_accounts','code'),
      ('accounting_journal',  'creditCode',          'accounting_accounts','code'),
      ('expenses',            'categoryAccountCode', 'accounting_accounts','code'),
      ('expenses',            'paymentAccountCode',  'accounting_accounts','code')
    ) AS t(quelle, spalte, ziel, zielspalte)
  LOOP
    -- Spalte vorhanden?
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema='public' AND table_name=bez.quelle AND column_name=bez.spalte) THEN
      RAISE NOTICE '  uebersprungen: %.% gibt es nicht', bez.quelle, bez.spalte;
      CONTINUE;
    END IF;

    EXECUTE format(
      'SELECT count(*) FROM public.%I q WHERE q.%I IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM public.%I z WHERE z.%I = q.%I)',
      bez.quelle, bez.spalte, bez.ziel, bez.zielspalte, bez.spalte) INTO n;

    IF n > 0 THEN
      RAISE NOTICE '  OFFEN: %.% -> %.% : % Verweise ins Leere, kein Schluessel gesetzt',
        bez.quelle, bez.spalte, bez.ziel, bez.zielspalte, n;
      offen := offen + 1;
      CONTINUE;
    END IF;

    EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I',
      bez.quelle, format('%s_%s_fkey', bez.quelle, bez.spalte));
    EXECUTE format(
      'ALTER TABLE public.%I ADD CONSTRAINT %I FOREIGN KEY (%I)
         REFERENCES public.%I(%I) ON UPDATE CASCADE ON DELETE RESTRICT',
      bez.quelle, format('%s_%s_fkey', bez.quelle, bez.spalte), bez.spalte,
      bez.ziel, bez.zielspalte);
    gesetzt := gesetzt + 1;
  END LOOP;

  RAISE NOTICE 'FREMDSCHLUESSEL: % gesetzt, % offen', gesetzt, offen;
END
$fk$;

-- ---------------------------------------------------------------- Indizes
-- Seit der Mandantentrennung filtert praktisch jede Abfrage nach tenantId.
DO $ix$
DECLARE t text; s text; sp text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'users','payments','expenses','accounting_journal','accounting_accounts',
    'fiscal_years','fiscal_budgets','board_meetings','board_members','tasks',
    'neighborhoods','events','news','polls','socialmediaposts',
    'event_registrations','inquiries','security_logs','settings'
  ] LOOP
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I ("tenantId")',
      t || '_tenant_idx', t);
  END LOOP;

  FOR s, sp IN SELECT * FROM (VALUES
      ('payments','userId'), ('payments','status'), ('payments','billingYear'),
      ('accounting_journal','date'), ('accounting_journal','referenceId'),
      ('event_registrations','eventId'), ('event_registrations','userId'),
      ('users','neighborhoodId'), ('users','membershipStatus'),
      ('board_members','userId'), ('inquiries','userId'),
      ('expenses','date'), ('news','publishAt'), ('events','date')
    ) AS v(a,b)
  LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema='public' AND table_name=s AND column_name=sp) THEN
      EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I (%I)',
        s || '_' || lower(sp) || '_idx', s, sp);
    END IF;
  END LOOP;
END
$ix$;
