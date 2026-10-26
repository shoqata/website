// @vitest-environment node
//
// Testzugaenge fuer Interessenten im Demoverein (20261128160000) gegen eine
// Wegwerf-Datenbank: Anlegen, Unsichtbarkeit, Sperren, Ablauf, naechtliches
// Zuruecksetzen, Floky-Kontingent -- und die geschlossene Luecke in
// reset_member_password. Siehe wegwerfdb.ts.
import { describe, it, expect, beforeAll } from 'vitest';
import type { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
import path from 'node:path';
import { wegwerfdb, alsSystem, MIGRATIONEN_HEUTE } from './wegwerfdb';

const BETREIBER = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const DEMO_ADMIN = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const KORETINI = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
const LEAD_A = '0000000a-0000-0000-0000-000000000000';
const LEAD_B = '0000000b-0000-0000-0000-000000000000';

// Was die Migration ausserhalb der bisherigen Wegwerf-Datenbank voraussetzt.
const DAZU = `
  ALTER TABLE auth.ich ADD COLUMN email text;
  CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS
    $f$ SELECT jsonb_build_object('email', email) FROM auth.ich LIMIT 1 $f$;
  CREATE TABLE auth.users(instance_id uuid, id uuid primary key, aud text, role text, email text,
    encrypted_password text, email_confirmed_at timestamptz, created_at timestamptz, updated_at timestamptz,
    raw_app_meta_data jsonb, raw_user_meta_data jsonb, is_sso_user boolean, is_anonymous boolean,
    confirmation_token text, recovery_token text, email_change_token_new text, email_change text,
    banned_until timestamptz, last_sign_in_at timestamptz);
  CREATE TABLE auth.identities(id uuid, user_id uuid references auth.users(id) on delete cascade,
    provider_id text, identity_data jsonb, provider text, created_at timestamptz, updated_at timestamptz);
  CREATE TABLE auth.sessions(id uuid default gen_random_uuid(), user_id uuid);
  CREATE TABLE auth.refresh_tokens(id serial, user_id varchar);
  CREATE FUNCTION extensions.gen_salt(text) RETURNS text LANGUAGE sql AS $f$ SELECT 'salz' $f$;
  CREATE FUNCTION extensions.crypt(p text, s text) RETURNS text LANGUAGE sql AS $f$ SELECT s || ':' || md5(p) $f$;

  CREATE TABLE platform_admins(email text);
  CREATE TABLE admin_emails(email text);
  CREATE FUNCTION is_platform_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS
    $f$ SELECT auth.jwt() ->> 'email' IS NOT NULL AND EXISTS (SELECT 1 FROM platform_admins
          WHERE lower(email) = lower(auth.jwt() ->> 'email')) $f$;
  CREATE FUNCTION app_role() RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS
    $f$ SELECT coalesce((SELECT role FROM users WHERE id = current_user_row_id()), 'GUEST') $f$;
  CREATE FUNCTION is_member_manager() RETURNS boolean LANGUAGE sql STABLE AS
    $f$ SELECT app_role() IN ('SUPER_ADMIN','ADMIN','BOARD') $f$;
  CREATE FUNCTION rollen_rang(text) RETURNS int LANGUAGE sql IMMUTABLE AS
    $f$ SELECT CASE coalesce($1,'MEMBER') WHEN 'SUPER_ADMIN' THEN 5 WHEN 'ADMIN' THEN 4 WHEN 'BOARD' THEN 3
                 WHEN 'REPRESENTATIVE' THEN 2 ELSE 1 END $f$;

  CREATE TABLE platform_leads(id uuid primary key default gen_random_uuid(), name text, "contactName" text, email text);
  CREATE TABLE security_logs(id uuid, "tenantId" text, type text, action text, "userId" text, details jsonb,
    "timestamp" timestamptz, "createdAt" timestamptz);
  ALTER TABLE users ADD COLUMN nicht_oeffentlich boolean DEFAULT false;
  ALTER TABLE tenants ADD COLUMN alle_module_frei boolean, ADD COLUMN vorstand_schreibt boolean;
  CREATE TABLE tenant_domains("tenantId" text, domain text);
  CREATE TABLE zahlungsgeheimnisse("tenantId" text);
  CREATE TABLE mail_settings("tenantId" text);
  CREATE TABLE social_connections("tenantId" text);
  CREATE TABLE revisionszugaenge("tenantId" text);
  CREATE TABLE floky_einstellungen("tenantId" text primary key, kontingent_monat int);
  CREATE TABLE floky_verbrauch("tenantId" text, monat date, anfragen int, primary key ("tenantId", monat));
  CREATE FUNCTION floky_darf() RETURNS boolean LANGUAGE sql AS $f$ SELECT true $f$;
  CREATE TABLE modules(schluessel text, ist_kern boolean, status text);
  CREATE TABLE tenant_modules("tenantId" text, modul text, zustand text, testet_bis date, primary key ("tenantId", modul));
  CREATE TABLE demo_vorlage(tabelle text, zeile jsonb);
  CREATE TABLE demo_stand(id int primary key, passwort_hash text, paket text,
    zurueckgesetzt_am timestamptz, zurueckgesetzt_von text);
  INSERT INTO demo_stand VALUES (1, 'gemeinsames-passwort', 'VOLL');
  CREATE FUNCTION _demo_tabellen() RETURNS text[] LANGUAGE sql AS $f$ SELECT ARRAY['users','payments'] $f$;

  ALTER TABLE users ENABLE ROW LEVEL SECURITY;
  CREATE POLICY alle ON users FOR ALL TO authenticated USING (true) WITH CHECK (true);
  GRANT ALL ON users, tenant_domains, tenants TO authenticated;
`;

let db: PGlite;
const zahl = async (sql: string, p: any[] = []) => Number((await db.query<{ n: number }>(sql, p)).rows[0].n);
const wert = async <T = any>(sql: string, p: any[] = []) => Object.values((await db.query<any>(sql, p)).rows[0] ?? {})[0] as T;

async function als(uid: string, email: string) {
  await db.exec('RESET ROLE; DELETE FROM auth.ich;');
  await db.query('INSERT INTO auth.ich VALUES ($1, $2)', [uid, email]);
  await db.exec('SET ROLE authenticated;');
}
const alsBetreiber = () => als(BETREIBER, 'betreiber@unityhub.li');

let gastA: { email: string; passwort: string };
let uidA = '';
let uidB = '';

beforeAll(async () => {
  db = await wegwerfdb(MIGRATIONEN_HEUTE);
  await db.exec(DAZU);
  const datei = fs.readdirSync(path.resolve(__dirname, '../../../supabase/migrations'))
    .find(f => f.startsWith('20261128160000'))!;
  await db.exec(fs.readFileSync(path.resolve(__dirname, '../../../supabase/migrations', datei), 'utf8'));

  await db.exec(`
    INSERT INTO platform_admins VALUES ('betreiber@unityhub.li');
    INSERT INTO auth.users (id, email, encrypted_password) VALUES
      ('${DEMO_ADMIN}', 'admin@demo.ch', 'alt'),
      ('${KORETINI}', 'arta@koretini.ch', 'geheim-von-arta');
    INSERT INTO users (id, email, "displayName", role, "membershipStatus", "tenantId", "authUserId") VALUES
      ('demo-admin', 'admin@demo.ch', 'Demo Admin', 'ADMIN', 'ACTIVE', 'demo', '${DEMO_ADMIN}'),
      ('demo-mitglied', 'mitglied@demo.ch', 'Demo Mitglied', 'MEMBER', 'ACTIVE', 'demo', null),
      ('arta', 'arta@koretini.ch', 'Arta', 'MEMBER', 'ACTIVE', 'koretini', '${KORETINI}');
    INSERT INTO platform_leads (id, name, "contactName", email) VALUES
      ('${LEAD_A}', 'Verein A', 'Agim Berisha', 'Agim@Verein-a.ch'),
      ('${LEAD_B}', 'Verein B', 'Blerta Hoxha', 'blerta@verein-b.ch');
  `);
  // Vorlage: der Demoverein ohne Gaeste.
  await db.exec(`INSERT INTO demo_vorlage SELECT 'users', to_jsonb(u) FROM users u WHERE "tenantId" = 'demo'`);
});

describe('Testzugang anlegen', () => {
  it('nur der Betreiber darf', async () => {
    await als(DEMO_ADMIN, 'admin@demo.ch');
    await expect(db.query('select demo_zugang_anlegen($1, 7)', [LEAD_A])).rejects.toThrow(/betreiber/i);
  });

  it('legt Konto, Zeile und Zugang an und gibt das Passwort einmal heraus', async () => {
    await alsBetreiber();
    gastA = await wert('select demo_zugang_anlegen($1, 7)', [LEAD_A]);
    expect(gastA.email).toBe('agim@verein-a.ch');
    expect(gastA.passwort).toMatch(/^[A-Za-z2-9]{14}$/);
    await alsSystem(db);
    uidA = await wert(`select id::text from auth.users where email = 'agim@verein-a.ch'`);
    const zeile = (await db.query<any>(`select role, "tenantId", "firstName", "lastName" from users where "authUserId" = $1`, [uidA])).rows[0];
    expect(zeile).toEqual({ role: 'ADMIN', tenantId: 'demo', firstName: 'Agim', lastName: 'Berisha' });
    expect(await zahl(`select count(*)::int n from demo_zugaenge where gueltig_bis between now() + interval '6 days' and now() + interval '8 days'`)).toBe(1);

    await alsBetreiber();
    await wert('select demo_zugang_anlegen($1, 14)', [LEAD_B]);
    await alsSystem(db);
    uidB = await wert(`select id::text from auth.users where email = 'blerta@verein-b.ch'`);
  });

  it('kein zweiter Zugang und kein bestehendes Login', async () => {
    await alsBetreiber();
    await expect(db.query('select demo_zugang_anlegen($1, 7)', [LEAD_A])).rejects.toThrow(/schon einen Testzugang/);
    await alsSystem(db);
    await db.exec(`INSERT INTO platform_leads (id, name, email) VALUES ('0000000c-0000-0000-0000-000000000000', 'X', 'arta@koretini.ch')`);
    await alsBetreiber();
    await expect(db.query(`select demo_zugang_anlegen('0000000c-0000-0000-0000-000000000000', 7)`)).rejects.toThrow(/schon ein Login/);
  });
});

describe('Gaeste untereinander', () => {
  it('ein Gast sieht sich und den Demoverein, aber nicht den anderen Gast', async () => {
    await als(uidA, 'agim@verein-a.ch');
    const ids = (await db.query<{ id: string }>(`select id from users where "tenantId" = 'demo' order by id`)).rows.map(r => r.id);
    expect(ids).toContain(uidA);
    expect(ids).toContain('demo-mitglied');
    expect(ids).not.toContain(uidB);
    await alsBetreiber();
    expect(await zahl(`select count(*)::int n from users where id = $1`, [uidB])).toBe(1);
  });

  it('Rollen und Logins anderer bleiben unberuehrt, gewoehnliche Mitglieder nicht', async () => {
    await als(uidA, 'agim@verein-a.ch');
    await expect(db.exec(`update users set role = 'MEMBER' where id = 'demo-admin'`)).rejects.toThrow(/Rollen/);
    await expect(db.exec(`delete from users where id = 'demo-admin'`)).rejects.toThrow(/loeschen/);
    await expect(db.exec(`update users set "authUserId" = '${KORETINI}' where id = 'demo-mitglied'`)).rejects.toThrow(/verknuepfen/);
    await db.exec(`update users set phone = '+41 79 000 00 00', role = 'BOARD' where id = 'demo-mitglied'`);
    await expect(db.exec(`insert into tenant_domains values ('demo', 'fremd.ch')`)).rejects.toThrow(/gesperrt/);
    await expect(db.exec(`update tenants set alle_module_frei = false where id = 'demo'`)).rejects.toThrow(/gesperrt/);
  });

  it('ein Gast setzt keine Passwoerter', async () => {
    await als(uidA, 'agim@verein-a.ch');
    await expect(db.query(`select reset_member_password('demo-mitglied')`)).rejects.toThrow(/Testzugang/);
  });
});

describe('reset_member_password', () => {
  it('uebernimmt kein Konto aus einem anderen Verein ueber die E-Mail-Adresse', async () => {
    await als(DEMO_ADMIN, 'admin@demo.ch');
    await db.exec(`update users set email = 'arta@koretini.ch', role = 'MEMBER' where id = 'demo-mitglied'`);
    await expect(db.query(`select reset_member_password('demo-mitglied')`)).rejects.toThrow(/ausserhalb Ihres Vereins/);
    await alsSystem(db);
    expect(await wert(`select encrypted_password from auth.users where id = '${KORETINI}'`)).toBe('geheim-von-arta');
  });

  it('auch nicht das eines Testzugangs', async () => {
    // Selbst verknuepfen kann die Administration die Zeile nicht -- die
    // Unsichtbarkeitsregel weist das ab. Fuer den Fall, dass die Verknuepfung
    // schon besteht, stellt das System sie her.
    await als(DEMO_ADMIN, 'admin@demo.ch');
    await expect(db.exec(`update users set "authUserId" = '${uidB}' where id = 'demo-mitglied'`)).rejects.toThrow(/demogaeste_unsichtbar/);
    await alsSystem(db);
    await db.exec(`update users set email = 'x@demo.ch', "authUserId" = '${uidB}' where id = 'demo-mitglied'`);
    await als(DEMO_ADMIN, 'admin@demo.ch');
    await expect(db.query(`select reset_member_password('demo-mitglied')`)).rejects.toThrow(/ausserhalb Ihres Vereins/);
  });

  it('legt fuer ein eigenes Mitglied mit neuer Adresse weiterhin ein Konto an', async () => {
    await alsSystem(db);
    await db.exec(`update users set email = 'neu@demo.ch', "authUserId" = null where id = 'demo-mitglied'`);
    await als(DEMO_ADMIN, 'admin@demo.ch');
    const r = await wert<any>(`select reset_member_password('demo-mitglied')`);
    expect(r.created).toBe(true);
  });
});

describe('Floky je Zugang', () => {
  it('weist nach der Grenze ab', async () => {
    await alsSystem(db);
    await db.exec(`update demo_zugaenge set floky_grenze = 2 where auth_user_id = '${uidA}'`);
    await als(uidA, 'agim@verein-a.ch');
    await db.query('select floky_anfrage_zaehlen()');
    await db.query('select floky_anfrage_zaehlen()');
    await expect(db.query('select floky_anfrage_zaehlen()')).rejects.toThrow(/aufgebraucht/);
    expect((await db.query<any>('select * from mein_demozugang()')).rows[0].floky_uebrig).toBe(0);
  });
});

describe('Ablauf', () => {
  it('sperrt abgelaufene Zugaenge und verweigert sofort das Schreiben', async () => {
    await alsSystem(db);
    await db.exec(`update demo_zugaenge set gueltig_bis = now() - interval '1 minute' where auth_user_id = '${uidB}'`);
    await db.exec(`insert into auth.sessions (user_id) values ('${uidB}'); insert into auth.refresh_tokens (user_id) values ('${uidB}')`);
    await als(uidB, 'blerta@verein-b.ch');
    expect(await wert('select darf_schreiben()')).toBe(false);
    await alsSystem(db);
    expect(await wert('select _demo_zugaenge_ablaufen()')).toBe(1);
    expect(await zahl(`select count(*)::int n from auth.users where id = '${uidB}' and banned_until > now()`)).toBe(1);
    expect(await zahl(`select count(*)::int n from auth.sessions where user_id = '${uidB}'`)).toBe(0);
    expect(await wert('select _demo_zugaenge_ablaufen()')).toBe(0);
  });
});

describe('Zuruecksetzen', () => {
  it('behaelt die Gaeste mit ihrem Passwort und ihrer Sperre', async () => {
    await alsSystem(db);
    const pwA = await wert(`select encrypted_password from auth.users where id = '${uidA}'`);
    const r = await wert<any>(`select _demo_zuruecksetzen_intern('Zeitplan')`);
    expect(r.testzugaenge).toBe(2);
    expect(await zahl(`select count(*)::int n from users where "authUserId" in ('${uidA}', '${uidB}')`)).toBe(2);
    expect(await wert(`select encrypted_password from auth.users where id = '${uidA}'`)).toBe(pwA);
    expect(await wert(`select encrypted_password from auth.users where id = '${DEMO_ADMIN}'`)).toBe('gemeinsames-passwort');
    expect(await zahl(`select count(*)::int n from auth.users where id = '${uidB}' and banned_until > now()`)).toBe(1);
    // Die Aenderungen aus den Tests oben sind weg.
    expect(await wert(`select email from users where id = 'demo-mitglied'`)).toBe('mitglied@demo.ch');
  });

  it('der Knopf bleibt dem Betreiber vorbehalten', async () => {
    await als(uidA, 'agim@verein-a.ch');
    await expect(db.query('select demo_zuruecksetzen()')).rejects.toThrow(/betreiber/i);
  });
});

describe('Verwalten', () => {
  it('verlaengern entsperrt, sperren sperrt, entfernen raeumt auf', async () => {
    await alsBetreiber();
    const liste = (await db.query<any>('select * from demo_zugaenge_lesen()')).rows;
    const b = liste.find(z => z.email === 'blerta@verein-b.ch');
    const a = liste.find(z => z.email === 'agim@verein-a.ch');
    expect(b.aktiv).toBe(false);

    await db.query('select demo_zugang_verlaengern($1, 7)', [b.id]);
    await alsSystem(db);
    expect(await wert(`select banned_until from auth.users where id = '${uidB}'`)).toBeNull();

    await alsBetreiber();
    await db.query('select demo_zugang_sperren($1)', [a.id]);
    expect(await zahl(`select count(*)::int n from demo_zugaenge_lesen() where aktiv`)).toBe(1);

    const neu = await wert<string>('select demo_zugang_neues_passwort($1)', [b.id]);
    expect(neu).toMatch(/^[A-Za-z2-9]{14}$/);

    await db.query('select demo_zugang_entfernen($1)', [a.id]);
    await alsSystem(db);
    expect(await zahl(`select count(*)::int n from auth.users where id = '${uidA}'`)).toBe(0);
    expect(await zahl(`select count(*)::int n from users where "authUserId" = '${uidA}'`)).toBe(0);
    expect(await zahl(`select count(*)::int n from demo_zugaenge`)).toBe(1);
  });
});
