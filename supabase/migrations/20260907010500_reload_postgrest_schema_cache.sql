-- PostgREST haelt einen eigenen Schemacache. Nach dem Anlegen von
-- fiscal_budgets antwortete die API mit 404, weil der Cache die neue Tabelle
-- noch nicht kannte. Dieses NOTIFY erzwingt das Neuladen.
NOTIFY pgrst, 'reload schema';
