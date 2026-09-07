-- Konto 9100 fehlt, obwohl der Jahresabschluss dagegen bucht.
--
-- performYearClosing schreibt die Eroeffnungsbilanz als Gegenbuchung auf 9100.
-- Das Konto steht weder in der Datenbank noch in DEFAULT_ACCOUNTS -- die
-- Saldenrechnung laeuft ueber die vorhandenen Konten, die Gegenseite jeder
-- Vortragsbuchung fiel damit unter den Tisch und war nirgends nachvollziehbar.
--
-- Bei einer aufgehenden Bilanz saldiert das Konto auf null: es wird fuer jedes
-- Aktivkonto erkannt und fuer jedes Passivkonto belastet, und Aktiven gleich
-- Passiven plus Ergebnis ist genau die Bedingung, die die Bilanzprobe prueft.
-- Weicht es von null ab, zeigt es die Differenz -- das ist erwuenscht.
INSERT INTO public.accounting_accounts (id, code, name, class, category)
VALUES ('acc-9100', '9100', 'Eröffnungsbilanz (Vortragskonto)', 'LIABILITY', 'Abschluss')
ON CONFLICT (code) DO NOTHING;
