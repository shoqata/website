DO $$
DECLARE r record; v_sql text; v_n int; v_ids text[] := ARRAY['IzziI1TF','dIozegHn','w23ECDS4'];
  v_treffer text[]; v_voll text[];
BEGIN
  -- Die vollen ids holen (oben stehen nur die ersten acht Zeichen).
  SELECT array_agg(id) INTO v_voll FROM public.users
   WHERE email IN ('valton.rexha_IzziI@gmail.com','qazim_dIoze@dervishi.ch','ledion_w23EC@dervishi.ch');
  RAISE NOTICE 'Volle ids: %', v_voll;

  RAISE NOTICE '--- Fremdschluessel auf users(id) ---';
  FOR r IN SELECT c.conname, n.nspname||'.'||t.relname AS tab,
                  (SELECT string_agg(a.attname, ',') FROM unnest(c.conkey) k
                    JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=k) AS spalten
             FROM pg_constraint c
             JOIN pg_class t ON t.oid=c.conrelid
             JOIN pg_namespace n ON n.oid=t.relnamespace
            WHERE c.contype='f' AND c.confrelid='public.users'::regclass LOOP
    RAISE NOTICE '  %.% (%)', r.tab, r.conname, r.spalten;
  END LOOP;

  RAISE NOTICE '--- Wo stehen diese ids ueberhaupt (alle Textspalten) ---';
  FOR r IN SELECT c.table_name, c.column_name
             FROM information_schema.columns c
             JOIN information_schema.tables tt
               ON tt.table_schema=c.table_schema AND tt.table_name=c.table_name
            WHERE c.table_schema='public' AND tt.table_type='BASE TABLE'
              AND c.data_type IN ('text','character varying','uuid')
              AND c.table_name <> 'users'
            ORDER BY 1,2 LOOP
    BEGIN
      v_sql := format('SELECT count(*) FROM public.%I WHERE %I::text = ANY($1)',
                      r.table_name, r.column_name);
      EXECUTE v_sql INTO v_n USING v_voll;
      IF v_n > 0 THEN
        RAISE NOTICE '  %.% -> % Zeilen', rpad(r.table_name,24), rpad(r.column_name,20), v_n;
      END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END $$;
