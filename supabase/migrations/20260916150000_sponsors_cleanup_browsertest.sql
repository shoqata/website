-- Zeilen aus den Durchlaeufen zur Inbetriebnahme entfernen.
DELETE FROM public.sponsors
 WHERE email IN ('browsertest@example.invalid', 'aussentest@example.invalid')
    OR email LIKE '%@example.invalid';
