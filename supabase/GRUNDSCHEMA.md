# Grundschema

`grundschema.sql` ist das vollständige Schema der laufenden Datenbank:
73 Tabellen, 188 Funktionen, 189 Regeln, 37 Trigger, 89 Indizes, 4 Sichten.
Nur Struktur, keine Daten — und keine Geheimnisse.

## Warum die Datei existiert

Der Ordner `migrations/` enthält **kein** Grundschema. Keine einzige
Migration legt `users`, `payments`, `neighborhoods`, `tenants` oder
`events` an. Sie sind beim Wechsel von Firebase ausserhalb der
Migrationen entstanden; alles unter `migrations/` sind Nachbesserungen
auf einem Schema, das schon da war.

Das fiel nicht auf, weil die Migrationen gegen die bestehende Datenbank
immer funktionieren. Es fällt erst auf, wenn man sie von null laufen
lässt — dann scheitert die erste Datei:

    Applying 20260905232000_rls_role_helper_and_fiscal_years.sql...
    ERROR: relation "public.users" does not exist

Damit war aus dem Repo **keine** neue Umgebung aufzubauen: kein
`supabase db reset`, keine zweite Instanz zum Entwickeln, kein
Wiederaufbau nach einem Verlust, und `supabase db diff` kann nicht
prüfen, ob die Datenbank noch dem entspricht, was im Repo steht. Diese
Datei schliesst die Lücke.

## Eine neue Umgebung aufbauen

    psql "$DATENBANK" -f supabase/grundschema.sql

Voraussetzung: ein Supabase-Projekt, in dem das `auth`-Schema steht.
Regeln und Funktionen rufen `auth.uid()` und `auth.jwt()`; die legt
GoTrue an, nicht diese Datei. Auf einer nackten Postgres-Instanz
scheitert genau eine Anweisung — die Leseregel `users_select`.

Die Migrationen unter `migrations/` **nicht** zusätzlich einspielen:
ihre Wirkung steckt schon darin, und sie würden an „already exists"
scheitern.

### Nachgewiesen, nicht angenommen

Die Datei wurde in einen frischen Container
(`supabase/postgres:17.11.0.003`) eingespielt und das Ergebnis mit der
laufenden Datenbank verglichen — mit derselben Abfrage auf beiden
Seiten:

| | lebend | Container |
|---|---|---|
| Tabellen | 72 | 72 |
| Funktionen | 188 | 188 |
| Regeln | 189 | **188** |
| Trigger | 37 | 37 |
| Indizes | 168 | 168 |
| Sichten | 4 | 4 |

Ein einziger Unterschied, und er ist erklärt: die Regel `users_select`
ruft `auth.jwt()`, die im nackten Image fehlt. Von 12 690 Zeilen war das
der einzige Fehler.

## Die Datei aktuell halten

Nach jeder angewendeten Migration:

    npx supabase db dump --linked -f supabase/grundschema.sql

Eine veraltete Datei ist schlimmer als keine, weil man ihr glaubt.

## Noch offen

Der saubere Zustand wäre ein Grundschema **als** erste Migration, mit
den 422 Nachbesserungen darauf oder zu einer zusammengefasst
(`supabase migration squash`). Das ist ein Eingriff in den
Migrationsordner und wartet auf eine Entscheidung — die Dateien dort
sind ausführlich kommentiert und erklären, *warum* etwas so ist. Dieses
Wissen darf ein Squash nicht wegräumen.
