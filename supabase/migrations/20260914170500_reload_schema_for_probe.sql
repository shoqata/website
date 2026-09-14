-- PostgREST kennt neue Funktionen erst nach einem Neuladen seines Schemacaches.
NOTIFY pgrst, 'reload schema';
