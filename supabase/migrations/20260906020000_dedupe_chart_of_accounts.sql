-- Doppelten Kontenplan bereinigen.
--
-- accounting_accounts enthielt zwei Generationen: ein Schweizer KMU-Schema mit
-- kurzen IDs und einen vereinsspezifischen Plan mit acc-* IDs. Sechs Codes
-- kamen doppelt vor. Die Saldenrechnung in AdminAccounting matcht Journalzeilen
-- ueber den Code und summiert anschliessend ueber alle Konten -- jeder Betrag
-- auf einem doppelten Code wurde damit zweimal gezaehlt und die Bilanz zeigte
-- das Doppelte samt Bilanzdifferenz.
--
-- Entscheidung: bei Kollisionen gewinnt der Vereinsplan. Die eindeutigen Konten
-- beider Generationen bleiben erhalten -- sie ergaenzen sich (Diaspora/Kosovo
-- und Dorfhilfe auf der einen Seite, die vollstaendige 6er-Aufwandsreihe auf
-- der anderen).
--
-- Journalzeilen referenzieren den Code, nicht die id, ebenso expenses ueber
-- categoryAccountCode und paymentAccountCode. Das Loeschen der Dubletten
-- veraendert deshalb keine einzige Buchung.

DELETE FROM public.accounting_accounts
 WHERE id IN ('1000', '1020', '1100', '2000', '3000', '4000');

-- Damit kein dritter Seed-Lauf denselben Schaden anrichtet.
CREATE UNIQUE INDEX IF NOT EXISTS accounting_accounts_code_key
  ON public.accounting_accounts (code);
