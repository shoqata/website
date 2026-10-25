// @vitest-environment node
//
// Migrationen vom 25.10.2026 gegen eine Wegwerf-Datenbank: CHF-Pflicht,
// Benachrichtigungen, Aufnahmeantraege, Push-Ausloeser, zeitgesteuerte
// Neuigkeiten. Siehe wegwerfdb.ts.
import { describe, it, expect, beforeAll } from 'vitest';
import type { PGlite } from '@electric-sql/pglite';
import { wegwerfdb, als, alsSystem, MIGRATIONEN_HEUTE } from './wegwerfdb';

const VORSTAND = '11111111-1111-1111-1111-111111111111';
const MITGLIED = '22222222-2222-2222-2222-222222222222';
const FREMD = '44444444-4444-4444-4444-444444444444';

let db: PGlite;
const zahl = async (sql: string, p: any[] = []) => Number((await db.query<{ n: number }>(sql, p)).rows[0].n);
const meldungen = (empfaenger: string, art?: string) =>
  zahl(`select count(*)::int n from benachrichtigungen where empfaenger = $1 ${art ? 'and art = $2' : ''}`, art ? [empfaenger, art] : [empfaenger]);

beforeAll(async () => {
  db = await wegwerfdb(MIGRATIONEN_HEUTE);
  await db.exec(`
    INSERT INTO settings VALUES ('payment', 'koretini', '{"fees":{"STANDARD":{"amount":120,"currency":"CHF"},"KOSOVO":{"amount":12,"currency":"EUR"}}}');
    INSERT INTO users (id, email, "displayName", role, "membershipStatus", "tenantId", "authUserId", "firstName", "lastName", phone, "neighborhoodId") VALUES
      ('vorstand', 'v@k.ch', 'Vorstand', 'BOARD', 'ACTIVE', 'koretini', '${VORSTAND}', 'Ve', 'Vorstand', null, null),
      ('mitglied', 'm@k.ch', 'Mitglied', 'MEMBER', 'ACTIVE', 'koretini', '${MITGLIED}', 'Mi', 'Glied', null, null),
      ('ohne-login', 'o@k.ch', 'Ohne Login', 'MEMBER', 'ACTIVE', 'koretini', null, 'O', 'L', null, null),
      ('inaktiv', 'i@k.ch', 'Inaktiv', 'MEMBER', 'INACTIVE', 'koretini', '33333333-3333-3333-3333-333333333333', 'I', 'A', null, null),
      ('fremd', 'f@demo.ch', 'Fremd', 'BOARD', 'ACTIVE', 'demo', '${FREMD}', 'F', 'Remd', null, null),
      ('m-arta', 'no-email-1@koretini.legacy', 'Artë Krasniqi', 'MEMBER', 'ACTIVE', 'koretini', null, 'Artë', 'Krasniqi', '+41 79 123 45 67', 'nb-zh'),
      ('m-agron', 'agron@x.ch', 'Agron Krasniqi', 'MEMBER', 'ACTIVE', 'koretini', null, 'Agron', 'Krasniqi', null, 'nb-zh'),
      ('m-besim', 'besim@x.ch', 'Besim Gashi', 'MEMBER', 'INACTIVE', 'koretini', null, 'Besim', 'Gashi', null, 'nb-sg');
    INSERT INTO payments (id, "tenantId", "userId", amount, type, "billingYear", status)
      VALUES ('alt', 'koretini', 'm-besim', 120, 'FEE', extract(year from now())::int, 'PENDING');
  `);
});

describe('Spenden nur in CHF', () => {
  it('weist EUR bei Spenden und Aufrufen ab', async () => {
    await expect(db.exec(`insert into donations("tenantId", betrag, waehrung) values ('koretini', 5, 'EUR')`)).rejects.toThrow();
    await expect(db.exec(`insert into spendenaufrufe("tenantId", titel, status, waehrung) values ('koretini', 'x', 'ENTWURF', 'EUR')`)).rejects.toThrow();
  });
});

describe('Benachrichtigungen', () => {
  beforeAll(async () => {
    await db.exec(`
      insert into donations("tenantId", betrag, name, zweck) values ('koretini', 1250.5, 'Arta', 'Schule');
      insert into payments("userId", "tenantId", amount, status, "dueDate", "invoiceNumber") values ('mitglied', 'koretini', 120, 'PENDING', '2026-12-31', 'INV-1');
      insert into payments("userId", "tenantId", amount, status, "scheduledDate") values ('mitglied', 'koretini', 120, 'PENDING', '2099-01-01');
      insert into payments("userId", "tenantId", amount, status, "dueDate") values ('mitglied', 'koretini', 80, 'PENDING', 'kaputt');
      update payments set "dunningLevel" = 1 where "invoiceNumber" = 'INV-1';
      insert into events("tenantId", title, date, status) values ('koretini', 'Fest', '2099-06-01', 'DRAFT');
      update events set status = 'PUBLISHED' where title = 'Fest';
      update events set title = 'Fest 2' where title = 'Fest';
      insert into events("tenantId", title, date, status) values ('koretini', 'Alt', '2000-01-01', 'PUBLISHED');
      insert into spendenaufrufe("tenantId", titel, status) values ('koretini', 'Schulhaus', 'OEFFENTLICH');
    `);
  });
  it('meldet Spenden nur dem Vorstand', async () => {
    expect(await meldungen('vorstand', 'SPENDE')).toBe(1);
    expect(await meldungen('mitglied', 'SPENDE')).toBe(0);
  });
  it('meldet Rechnungen sofort, geplante nicht zu frueh, und kaputte Daten blockieren nichts', async () => {
    expect(await meldungen('mitglied', 'RECHNUNG')).toBe(2);
    expect(await meldungen('mitglied', 'MAHNUNG')).toBe(1);
  });
  it('meldet eine Veranstaltung einmal, nicht bei spaeteren Aenderungen und nicht Vergangenes', async () => {
    expect(await meldungen('mitglied', 'VERANSTALTUNG')).toBe(1);
  });
  it('erreicht weder Mitglieder ohne Login noch Inaktive noch andere Vereine', async () => {
    expect(await meldungen('ohne-login') + await meldungen('inaktiv') + await meldungen('fremd')).toBe(0);
  });
  it('zeigt jedem nur die eigenen und laesst die App nichts anlegen', async () => {
    await als(db, MITGLIED);
    const eigene = await zahl('select count(*)::int n from benachrichtigungen');
    await alsSystem(db);
    expect(eigene).toBe(await meldungen('mitglied'));
    await als(db, MITGLIED);
    await expect(db.exec(`insert into benachrichtigungen("tenantId", empfaenger, art, titel) values ('koretini', 'vorstand', 'X', 'gefaelscht')`)).rejects.toThrow();
    await expect(db.query(`select benachrichtigen('koretini', array['vorstand'], 'X', 'gefaelscht')`)).rejects.toThrow();
    expect(await zahl('select benachrichtigungen_gelesen() n')).toBe(eigene);
    await alsSystem(db);
    expect(await zahl(`select count(*)::int n from benachrichtigungen where empfaenger = 'vorstand' and gelesen_am is not null`)).toBe(0);
  });
});

describe('Zeitgesteuerte Neuigkeiten', () => {
  it('meldet sofortige gleich, zeitgesteuerte erst wenn sie erscheinen, jede nur einmal', async () => {
    await alsSystem(db);
    await db.exec(`insert into news(id, "tenantId", title, status) values ('n1', 'koretini', 'Sofort', 'PUBLISHED')`);
    await db.exec(`insert into news(id, "tenantId", title, status, "publishAt") values ('n2', 'koretini', 'Spaeter', 'PUBLISHED', now() + interval '1 hour')`);
    const titel = async (t: string) => zahl(`select count(*)::int n from benachrichtigungen where empfaenger = 'mitglied' and titel = $1`, [t]);
    expect(await titel('Sofort')).toBe(1);
    expect(await titel('Spaeter')).toBe(0);
    expect(await zahl('select neuigkeiten_zeitgesteuert_melden() n')).toBe(0);   // noch nicht so weit
    await db.exec(`update news set "publishAt" = now() - interval '5 minutes' where id = 'n2'`);
    expect(await zahl('select neuigkeiten_zeitgesteuert_melden() n')).toBe(1);
    expect(await titel('Spaeter')).toBe(1);
    expect(await zahl('select neuigkeiten_zeitgesteuert_melden() n')).toBe(0);   // nicht doppelt
    // Zurueckziehen und wieder veroeffentlichen meldet nicht erneut.
    await db.exec(`update news set status = 'DRAFT' where id = 'n1'; update news set status = 'PUBLISHED' where id = 'n1'`);
    expect(await titel('Sofort')).toBe(1);
  });
  it('ist als geplanter Auftrag eingetragen', async () => {
    expect(await zahl(`select count(*)::int n from cron.job where jobname = 'neuigkeiten_melden'`)).toBe(1);
  });
});

describe('Push-Ausloeser', () => {
  it('ruft push-senden einmal je Anweisung und nur fuer Empfaenger mit Geraet', async () => {
    await als(db, VORSTAND);
    await db.query(`select push_abo_speichern('https://fcm.googleapis.com/x', 'p', 'a', 'https://www.koretini.me', 'Chrome')`);
    await expect(db.query(`select push_abo_speichern('http://boese', 'p', 'a')`)).rejects.toThrow();
    await alsSystem(db);
    await db.exec('delete from net.aufrufe');
    // Eine Veranstaltung -> eine Anweisung fuer alle aktiven Mitglieder.
    await db.exec(`insert into events("tenantId", title, date, status) values ('koretini', 'Push-Test', '2099-01-01', 'PUBLISHED')`);
    const aufrufe = (await db.query<any>(`select body, headers->>'x-push-token' tok from net.aufrufe`)).rows;
    expect(aufrufe).toHaveLength(1);
    expect(aufrufe[0].tok).toHaveLength(48);
    expect(aufrufe[0].body.ids).toHaveLength(1);   // nur der Vorstand hat ein Geraet
  });
});

describe('Aufnahmeantraege', () => {
  let ids: Record<string, string> = {};
  beforeAll(async () => {
    await als(db, null);
    await db.query(`select aufnahme_beantragen('Arte', 'KRASNIQI ', 'arta.k@mail.ch', '0791234567', p_nachbarschaft => 'nb-zh')`);
    await db.query(`select aufnahme_beantragen('Arte', 'Krasniqi', 'ARTA.K@mail.ch', '0041 79 123 45 67', p_nachbarschaft => 'nb-zh')`);
    await db.query(`select aufnahme_beantragen('Besim', 'Gashi', 'besim@x.ch')`);
    await db.query(`select aufnahme_beantragen('Drita', 'Neu', 'drita@neu.ch', p_land => 'Kosovo')`);
    await alsSystem(db);
    ids = Object.fromEntries((await db.query<any>(`select nachname || ':' || vorname k, id from aufnahmeantraege`)).rows.map(r => [r.k, r.id]));
  });
  it('nimmt Antraege ohne Konto an, fasst doppelte zusammen, prueft die Angaben', async () => {
    expect(Object.keys(ids)).toHaveLength(3);
    await als(db, null);
    await expect(db.query(`select aufnahme_beantragen('X', 'Y', 'keine-mail')`)).rejects.toThrow(/E-Mail/);
    await expect(db.query(`select aufnahme_beantragen('', 'Y', 'a@b.ch')`)).rejects.toThrow(/Vor- und Nachnamen/);
    await expect(db.query('select * from aufnahmeantraege')).rejects.toThrow(/permission denied/);
    await alsSystem(db);
    expect(await meldungen('vorstand', 'AUFNAHME')).toBe(3);
  });
  it('findet bestehende Mitglieder trotz Akzenten, Grossschreibung und Telefonformat', async () => {
    await als(db, VORSTAND);
    const t = (await db.query<any>('select * from aufnahme_treffer($1)', [ids['Krasniqi:Arte']])).rows;
    expect(t[0].mitglied).toBe('m-arta');
    expect(t[0].gruende).toEqual(expect.arrayContaining(['Telefon', 'Name', 'Nachbarschaft']));
    expect(t.find((x: any) => x.mitglied === 'm-agron')?.punkte).toBe(25);
    const b = (await db.query<any>('select * from aufnahme_treffer($1)', [ids['Gashi:Besim']])).rows;
    expect(b[0]).toMatchObject({ mitglied: 'm-besim', status: 'INACTIVE' });
    expect((await db.query('select * from aufnahme_treffer($1)', [ids['Neu:Drita']])).rows).toHaveLength(0);
  });
  it('gibt frei: uebernimmt, erstellt die Jahresrechnung, keine zweite, Kosovo in EUR', async () => {
    await als(db, VORSTAND);
    await expect(db.query(`select aufnahme_freigeben($1)`, [ids['Gashi:Besim']])).rejects.toThrow(/gehoert schon einem Mitglied/);
    const a = (await db.query<any>(`select aufnahme_freigeben($1, 'm-arta') r`, [ids['Krasniqi:Arte']])).rows[0].r;
    expect(a).toMatchObject({ mitglied: 'm-arta', betrag: 120, waehrung: 'CHF', rechnung_bestand_schon: false });
    const b = (await db.query<any>(`select aufnahme_freigeben($1, 'm-besim') r`, [ids['Gashi:Besim']])).rows[0].r;
    expect(b).toMatchObject({ rechnung: 'alt', rechnung_bestand_schon: true });
    const d = (await db.query<any>(`select aufnahme_freigeben($1, null, 'KOSOVO') r`, [ids['Neu:Drita']])).rows[0].r;
    expect(d).toMatchObject({ betrag: 12, waehrung: 'EUR' });
    await expect(db.query(`select aufnahme_freigeben($1, 'm-arta')`, [ids['Krasniqi:Arte']])).rejects.toThrow(/schon erledigt/);
    await alsSystem(db);
    const arta = (await db.query<any>(`select email, "membershipStatus", phone from users where id = 'm-arta'`)).rows[0];
    expect(arta).toEqual({ email: 'arta.k@mail.ch', membershipStatus: 'ACTIVE', phone: '+41 79 123 45 67' });
    const p = (await db.query<any>(`select "invoiceNumber", method from payments where "userId" = 'm-arta'`)).rows[0];
    expect(p.invoiceNumber).toMatch(/^INV-\d{6}-\d{5}$/);
    expect(p.method).toBe('QR_BILL');
  });
  it('laesst einen fremden Vorstand nichts sehen', async () => {
    await als(db, FREMD);
    expect(await zahl('select count(*)::int n from aufnahmeantraege')).toBe(0);
    expect((await db.query('select * from aufnahme_treffer($1)', [ids['Krasniqi:Arte']])).rows).toHaveLength(0);
    await alsSystem(db);
  });
});
