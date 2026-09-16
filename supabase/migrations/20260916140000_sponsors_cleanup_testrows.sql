-- Testzeilen des Selbsttests aus der vorigen Migration entfernen.
-- Laeuft als Eigentuemer, ohne Rollenwechsel.
DELETE FROM public.sponsors WHERE email LIKE '%@example.invalid';
DELETE FROM public.sponsors WHERE email = 'pruefung@example.com';
