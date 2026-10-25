// Eine Wegwerf-Datenbank fuer Migrationstests.
//
// PGlite ist ein echtes Postgres im Prozess. Darin wird nachgebaut, was die
// Migrationen von Supabase voraussetzen (Rollen, auth.uid, die Tabellen, die
// sie anfassen, pg_net, pg_cron) -- dann laufen die echten Migrationsdateien
// darauf. So faellt ein Fehler in einem Ausloeser auf, bevor er in der
// Vereinsdatenbank eine Rechnung am Speichern hindert.
//
// Nachgebaut wird nur, was die getesteten Migrationen brauchen. Kommt eine
// Spalte dazu, die ein Test braucht, gehoert sie hierher.
import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
import path from 'node:path';

const MIGRATIONEN = path.resolve(__dirname, '../../../supabase/migrations');

const GRUNDGERUEST = `
  CREATE ROLE anon; CREATE ROLE authenticated;
  CREATE SCHEMA auth; CREATE TABLE auth.ich(uid uuid);
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS 'select uid from auth.ich limit 1';
  GRANT USAGE ON SCHEMA auth TO anon, authenticated; GRANT SELECT ON auth.ich TO anon, authenticated;

  CREATE SCHEMA extensions;
  CREATE FUNCTION extensions.gen_random_bytes(n int) RETURNS bytea LANGUAGE sql AS
    $f$ SELECT decode(substr(md5(random()::text) || md5(random()::text), 1, n * 2), 'hex') $f$;
  CREATE SCHEMA net; CREATE TABLE net.aufrufe(url text, headers jsonb, body jsonb);
  CREATE FUNCTION net.http_post(url text, headers jsonb, body jsonb) RETURNS bigint LANGUAGE sql AS
    $f$ INSERT INTO net.aufrufe VALUES (url, headers, body) RETURNING 1::bigint $f$;
  CREATE SCHEMA cron; CREATE TABLE cron.job(jobname text primary key, schedule text, command text);
  CREATE FUNCTION cron.schedule(n text, s text, c text) RETURNS bigint LANGUAGE sql AS
    $f$ INSERT INTO cron.job VALUES (n, s, c) ON CONFLICT (jobname) DO UPDATE SET schedule = s, command = c RETURNING 1::bigint $f$;
  CREATE FUNCTION cron.unschedule(n text) RETURNS boolean LANGUAGE sql AS $f$ DELETE FROM cron.job WHERE jobname = n RETURNING true $f$;

  CREATE TABLE tenants(id text primary key); INSERT INTO tenants VALUES ('koretini'), ('demo');
  CREATE TABLE neighborhoods(id text primary key, name text);
  INSERT INTO neighborhoods VALUES ('nb-zh', 'Zürich'), ('nb-sg', 'St. Gallen');
  CREATE TABLE users(id text primary key, email text, "displayName" text, role text, "membershipStatus" text,
    phone text, street text, zip text, city text, "neighborhoodId" text references neighborhoods(id),
    "tenantId" text references tenants(id), "joinedAt" timestamptz, "billingGroup" text, "customAnnualFee" numeric,
    "isLegacyEmail" boolean, "profileComplete" boolean, "firstName" text, "lastName" text, salutation text,
    "invoiceDeliveryMethod" text, address text, country text, "phoneSecondary" text, currency text,
    "authUserId" text, sprache text);
  CREATE UNIQUE INDEX users_email_je_verein ON users ("tenantId", lower(btrim(email)))
    WHERE email IS NOT NULL AND btrim(email) <> '';
  GRANT SELECT ON users, neighborhoods TO authenticated;
  CREATE TABLE settings(id text, "tenantId" text, payment jsonb);
  CREATE TABLE payments(id text primary key default gen_random_uuid()::text, "tenantId" text, "userId" text,
    amount numeric, currency text default 'CHF', type text default 'FEE', "billingYear" int, method text,
    status text, "deliveryMethod" text, "dueDate" text, "scheduledDate" text, "dunningLevel" int default 0,
    "invoiceNumber" text, description text, timestamp timestamptz default now());
  CREATE TABLE events(id text primary key default gen_random_uuid()::text, "tenantId" text, title text, date text, status text);
  CREATE TABLE news(id text primary key default gen_random_uuid()::text, "tenantId" text, title text, status text, "publishAt" timestamptz);
  CREATE TABLE donations(id uuid primary key default gen_random_uuid(), "tenantId" text, betrag numeric,
    waehrung text default 'CHF', name text, email text, strasse text, plz text, ort text, land text,
    anonym boolean default false, nachricht text, zweck text, referenz text, status text default 'OFFEN',
    weg text, "userId" text, eingegangen_am timestamptz, bescheinigt_am timestamptz, gebucht boolean,
    erfasst_am timestamptz default now(), erfasst_von text, aufruf text);
  CREATE TABLE spendenaufrufe(id text primary key default gen_random_uuid()::text, "tenantId" text, titel text, status text, waehrung text default 'CHF');
  CREATE TABLE platform_secrets(schluessel text primary key, wert text, notiz text);

  CREATE FUNCTION current_user_row_id() RETURNS text LANGUAGE sql STABLE AS
    $f$ SELECT id FROM users WHERE "authUserId" = auth.uid()::text LIMIT 1 $f$;
  CREATE FUNCTION current_tenant() RETURNS text LANGUAGE sql STABLE AS
    $f$ SELECT "tenantId" FROM users WHERE id = current_user_row_id() $f$;
  -- Der Verein der aufgerufenen Domain (in Supabase aus dem Origin-Kopf).
  CREATE TABLE anfrage_herkunft(t text); INSERT INTO anfrage_herkunft VALUES ('koretini');
  GRANT SELECT ON anfrage_herkunft TO anon, authenticated;
  CREATE FUNCTION request_tenant() RETURNS text LANGUAGE sql STABLE AS $f$ SELECT t FROM anfrage_herkunft LIMIT 1 $f$;
  CREATE FUNCTION is_staff() RETURNS boolean LANGUAGE sql STABLE AS
    $f$ SELECT coalesce((SELECT role IN ('SUPER_ADMIN', 'ADMIN', 'BOARD') FROM users WHERE id = current_user_row_id()), false) $f$;
  CREATE FUNCTION modul_aktiv(text) RETURNS boolean LANGUAGE sql AS $f$ SELECT true $f$;
`;

export async function wegwerfdb(migrationen: string[]) {
  const db = new PGlite();
  await db.exec(GRUNDGERUEST);
  for (const m of migrationen) {
    const datei = fs.readdirSync(MIGRATIONEN).find(f => f.startsWith(m));
    if (!datei) throw new Error(`Migration ${m} nicht gefunden`);
    await db.exec(fs.readFileSync(path.join(MIGRATIONEN, datei), 'utf8'));
  }
  return db;
}

// Als wer laeuft die naechste Abfrage? null = ohne Anmeldung (anon).
export async function als(db: PGlite, authUid: string | null) {
  await db.exec('RESET ROLE; DELETE FROM auth.ich;');
  if (authUid) await db.exec(`INSERT INTO auth.ich VALUES ('${authUid}'); SET ROLE authenticated;`);
  else await db.exec('SET ROLE anon;');
}
export const alsSystem = (db: PGlite) => db.exec('RESET ROLE; DELETE FROM auth.ich;');

export const MIGRATIONEN_HEUTE = [
  '20261128100000', // spenden_nur_chf
  '20261128110000', // benachrichtigungen
  '20261128120000', // aufnahmeantraege
  '20261128130000', // push_nachrichten
  '20261128140000', // neuigkeiten_zeitgesteuert
  '20261128150000', // neuigkeiten_halbstuendlich
];
