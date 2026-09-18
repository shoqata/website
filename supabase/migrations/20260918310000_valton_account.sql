-- Erster Versuch, das Konto unmittelbar in auth.users anzulegen.
--
-- Zweimal gescheitert: pgcrypto liegt im Schema extensions, und danach an
-- einer Spalte vom Typ json. Eine Anmeldezeile von Hand zusammenzusetzen ist
-- heikel -- ein unvollstaendiger Datensatz laesst sich schlechter erkennen als
-- gar keiner. Der Versuch bleibt als Notiz stehen; der gangbare Weg steht in
-- der naechsten Migration.
SELECT 1;
