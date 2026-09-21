DO $$
DECLARE r record; v_ids text[]; v_sql text; v_n int;
BEGIN
  SELECT array_agg(u.id) INTO v_ids FROM public.users u
   WHERE u."tenantId"='koretini'
     AND lower(u."firstName")||' '||lower(u."lastName") IN
         ('shpend basha','ibrahim canaj','perparim haxhiu','kastriot klaiqi','fatos selmani');
  RAISE NOTICE 'Betroffene Zeilen: %', array_length(v_ids,1);

  FOR r IN SELECT c.table_name, c.column_name
             FROM information_schema.columns c
             JOIN information_schema.tables tt
               ON tt.table_schema=c.table_schema AND tt.table_name=c.table_name
            WHERE c.table_schema='public' AND tt.table_type='BASE TABLE'
              AND c.data_type IN ('text','character varying','uuid') AND c.table_name<>'users'
            ORDER BY 1,2 LOOP
    BEGIN
      v_sql := format('SELECT count(*) FROM public.%I WHERE %I::text = ANY($1)', r.table_name, r.column_name);
      EXECUTE v_sql INTO v_n USING v_ids;
      IF v_n > 0 THEN RAISE NOTICE '  %.% -> %', rpad(r.table_name,22), rpad(r.column_name,18), v_n; END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END $$;
