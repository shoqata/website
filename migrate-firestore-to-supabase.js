/**
 * Firebase (Firestore) to Supabase (PostgreSQL) Migration Engine
 * 
 * Full robust migration with automatic OAuth token refresh, retries,
 * row-by-row fallback, and auto-handling of constraint conflicts.
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { OAuth2Client } from 'google-auth-library';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize OAuth2 client for auto-refreshing access tokens
let oauth2Client = null;
const firebaseToolsPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');

if (fs.existsSync(firebaseToolsPath)) {
  try {
    const config = JSON.parse(fs.readFileSync(firebaseToolsPath, 'utf8'));
    const tokens = config.tokens || {};
    if (tokens.refresh_token) {
      oauth2Client = new OAuth2Client(
        '563584335869-fgrhgmd47bqnkijo5i8b5pr03ho849e6.apps.googleusercontent.com',
        'V8QU2xGKlGQMJrgWVGIvg'
      );
      oauth2Client.setCredentials({
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expiry_date: tokens.expires_at
      });
    }
  } catch (e) {}
}

async function getAccessToken() {
  if (oauth2Client) {
    try {
      const res = await oauth2Client.getAccessToken();
      if (res.token) return res.token;
    } catch (e) {
      console.warn('⚠️ Token refresh notice:', e.message);
    }
  }
  if (fs.existsSync(firebaseToolsPath)) {
    const config = JSON.parse(fs.readFileSync(firebaseToolsPath, 'utf8'));
    return config.tokens?.access_token || '';
  }
  return '';
}

async function fetchWithRetry(url, options = {}, retries = 5, backoff = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const token = await getAccessToken();
      const headers = { ...options.headers, Authorization: `Bearer ${token}` };
      const res = await fetch(url, { ...options, headers });
      if (res.ok) return res;
      if (res.status === 429 || res.status >= 500) {
        console.warn(`  ⚠️ HTTP ${res.status}, retrying (${i + 1}/${retries})...`);
        await new Promise(r => setTimeout(r, backoff * (i + 1)));
        continue;
      }
      return res;
    } catch (err) {
      console.warn(`  ⚠️ Fetch error: ${err.message}, retrying (${i + 1}/${retries})...`);
      await new Promise(r => setTimeout(r, backoff * (i + 1)));
    }
  }
  throw new Error(`Failed to fetch ${url} after ${retries} attempts.`);
}

function parseFirestoreValue(val) {
  if (!val) return null;
  if (val.stringValue !== undefined) return val.stringValue;
  if (val.integerValue !== undefined) return Number(val.integerValue);
  if (val.doubleValue !== undefined) return Number(val.doubleValue);
  if (val.booleanValue !== undefined) return val.booleanValue;
  if (val.timestampValue !== undefined) return val.timestampValue;
  if (val.nullValue !== undefined) return null;
  if (val.arrayValue !== undefined) {
    return (val.arrayValue.values || []).map(parseFirestoreValue);
  }
  if (val.mapValue !== undefined) {
    const obj = {};
    for (const [k, v] of Object.entries(val.mapValue.fields || {})) {
      obj[k] = parseFirestoreValue(v);
    }
    return obj;
  }
  return null;
}

function parseFirestoreDoc(doc) {
  const id = doc.name.split('/').pop();
  const fields = doc.fields || {};
  const data = {};
  for (const [k, v] of Object.entries(fields)) {
    data[k] = parseFirestoreValue(v);
  }
  return { id, data };
}

async function run() {
  console.log('===================================================');
  console.log('🔥 FIREBASE TO SUPABASE DATA MIGRATION ENGINE 🔥');
  console.log('===================================================');

  // 1. Verify Access Token
  const token = await getAccessToken();
  if (!token) {
    console.error('❌ Error: No valid Firebase access token found.');
    process.exit(1);
  }
  console.log('🔑 Authenticated via Firebase OAuth session.');

  // 2. Initialize Supabase Client
  const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://rabpkwwozkwsnyoivocy.supabase.co';
  const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;
  let supabase = null;

  if (supabaseUrl && supabaseKey) {
    console.log(`⚡ Connected to Supabase: ${supabaseUrl}`);
    supabase = createClient(supabaseUrl, supabaseKey);
  } else {
    console.log('⚠️ Supabase credentials missing in .env.');
  }

  let sqlOutput = '';
  sqlOutput += `-- =========================================================\n`;
  sqlOutput += `-- SUPABASE DATA SEED SCRIPT (MIGRATED FROM FIRESTORE)\n`;
  sqlOutput += `-- Generated on: ${new Date().toISOString()}\n`;
  sqlOutput += `-- =========================================================\n\n`;
  sqlOutput += `BEGIN;\n\n`;
  sqlOutput += `SET CONSTRAINTS ALL DEFERRED;\n\n`;

  const esc = (val) => {
    if (val === undefined || val === null) return 'NULL';
    if (typeof val === 'boolean') return val ? 'true' : 'false';
    if (typeof val === 'number') return val.toString();
    let str = typeof val === 'string' ? val : val.toString();
    str = str.replace(/'/g, "''");
    return `'${str}'`;
  };

  const parseTS = (val) => {
    if (!val) return 'NULL';
    if (typeof val === 'string' && !isNaN(Date.parse(val))) return esc(val);
    if (val instanceof Date) return esc(val.toISOString());
    return 'NULL';
  };

  const parseTSRaw = (val) => {
    if (!val) return new Date().toISOString();
    if (typeof val === 'string' && !isNaN(Date.parse(val))) return val;
    if (val instanceof Date) return val.toISOString();
    return new Date().toISOString();
  };

  const escJSON = (val) => {
    if (!val) return 'NULL';
    try {
      return esc(JSON.stringify(val));
    } catch (e) {
      return 'NULL';
    }
  };

  // Helper to fetch collection with REST API and migrate
  const migrateCollection = async (firestoreColName, postgresTableName, mapper, rawMapper) => {
    console.log(`\n📡 Fetching documents from Firestore: "${firestoreColName}"...`);
    let rawDocs = [];
    let pageToken = '';

    try {
      do {
        const url = `https://firestore.googleapis.com/v1/projects/shoqatawebsite/databases/(default)/documents/${firestoreColName}?pageSize=300${pageToken ? '&pageToken=' + pageToken : ''}`;
        const res = await fetchWithRetry(url);
        const json = await res.json();
        if (json.documents) {
          rawDocs.push(...json.documents);
        }
        pageToken = json.nextPageToken || '';
      } while (pageToken);

      console.log(`✅ Retrieved ${rawDocs.length} records from "${firestoreColName}".`);

      if (rawDocs.length === 0) {
        sqlOutput += `-- No data found in Firestore collection: "${firestoreColName}"\n\n`;
        return;
      }

      sqlOutput += `-- ---------------------------------------------------------\n`;
      sqlOutput += `-- Data for Table: ${postgresTableName}\n`;
      sqlOutput += `-- ---------------------------------------------------------\n`;

      const rawRows = [];

      rawDocs.forEach(rawDoc => {
        const { id, data } = parseFirestoreDoc(rawDoc);
        const mapped = mapper(id, data);
        
        const keys = Object.keys(mapped);
        const values = Object.values(mapped);

        sqlOutput += `INSERT INTO "${postgresTableName}" (${keys.map(k => `"${k}"`).join(', ')}) \n`;
        sqlOutput += `VALUES (${values.join(', ')}) \n`;
        sqlOutput += `ON CONFLICT ("id") DO UPDATE SET \n`;
        sqlOutput += `  ${keys.filter(k => k !== 'id').map(k => `"${k}" = EXCLUDED."${k}"`).join(',\n  ')};\n\n`;

        if (rawMapper) {
          rawRows.push(rawMapper(id, data));
        }
      });

      if (supabase && rawRows.length > 0) {
        let insertedCount = 0;
        const batchSize = 50;
        for (let i = 0; i < rawRows.length; i += batchSize) {
          const batch = rawRows.slice(i, i + batchSize);
          const { error } = await supabase.from(postgresTableName).upsert(batch);
          if (error) {
            console.warn(`  ⚠️ Batch upsert notice for "${postgresTableName}" (${error.message}). Falling back to row-by-row...`);
            for (const row of batch) {
              const { error: singleErr } = await supabase.from(postgresTableName).upsert([row]);
              if (singleErr) {
                if (singleErr.message.includes('users_email_key') && row.email) {
                  const parts = row.email.split('@');
                  const fallbackRow = { ...row, email: `${parts[0]}_${row.id.slice(0,5)}@${parts[1] || 'legacy'}` };
                  const { error: retryErr } = await supabase.from(postgresTableName).upsert([fallbackRow]);
                  if (!retryErr) insertedCount++;
                  else console.error(`    ❌ Single row error for user ${row.id}:`, retryErr.message);
                } else if (singleErr.message.includes('tenants_slug_idx')) {
                  const fallbackRow = { ...row, slug: `${row.slug}_${row.id.slice(0,4)}` };
                  const { error: retryErr } = await supabase.from(postgresTableName).upsert([fallbackRow]);
                  if (!retryErr) insertedCount++;
                } else {
                  console.error(`    ❌ Single row error for "${postgresTableName}" id ${row.id}:`, singleErr.message);
                }
              } else {
                insertedCount++;
              }
            }
          } else {
            insertedCount += batch.length;
          }
        }
        console.log(`  🚀 Successfully imported ${insertedCount}/${rawRows.length} records into Supabase "${postgresTableName}".`);
      }

    } catch (err) {
      console.error(`❌ Error migrating collection "${firestoreColName}":`, err.message);
      sqlOutput += `-- Error fetching collection "${firestoreColName}": ${err.message}\n\n`;
    }
  };

  // Track unique emails for users mapping
  const seenEmails = new Set();

  // 1. Tenants
  await migrateCollection(
    'tenants', 'tenants',
    (id, d) => ({
      id: esc(id),
      name: esc(d.name || 'Humanitas Network'),
      domain: esc(d.slug || d.id || null),
      logo: esc(d.logoUrl || null),
      createdAt: parseTS(d.createdAt || new Date()),
      status: esc(d.subscriptionStatus || 'ACTIVE'),
      slug: esc(d.slug || d.id || 'koretini')
    }),
    (id, d) => ({
      id,
      name: d.name || 'Humanitas Network',
      domain: d.slug || d.id || null,
      logo: d.logoUrl || null,
      createdAt: parseTSRaw(d.createdAt),
      status: d.subscriptionStatus || 'ACTIVE',
      slug: d.slug || d.id || 'koretini'
    })
  );

  // 2. Neighborhoods
  await migrateCollection(
    'neighborhoods', 'neighborhoods',
    (id, d) => ({
      id: esc(id),
      name: esc(d.name || 'Unnamed'),
      city: esc(d.location?.city || d.city || 'Koretin'),
      representativeId: esc(d.managerId || null),
      description: esc(d.description || null),
      createdAt: parseTS(d.createdAt || new Date())
    }),
    (id, d) => ({
      id,
      name: d.name || 'Unnamed',
      city: d.location?.city || d.city || 'Koretin',
      representativeId: d.managerId || null,
      description: d.description || null,
      createdAt: parseTSRaw(d.createdAt)
    })
  );

  // 3. Users
  await migrateCollection(
    'users', 'users',
    (id, d) => {
      const isLegacy = d.email && d.email.endsWith('@koretini.legacy');
      const profileComplete = d.profileComplete !== undefined ? d.profileComplete : !isLegacy;
      let emailVal = d.email || null;
      if (!emailVal || emailVal.trim() === '') emailVal = null;
      return {
        id: esc(id),
        email: esc(emailVal),
        displayName: esc(d.displayName || `${d.firstName || ''} ${d.lastName || ''}`.trim() || 'User'),
        role: esc(d.role || 'MEMBER'),
        membershipStatus: esc(d.membershipStatus || 'ACTIVE'),
        phone: esc(d.phone || null),
        street: esc(d.street || null),
        zip: esc(d.zip || null),
        city: esc(d.city || null),
        birthdate: esc(d.birthdate || null),
        neighborhoodId: esc(d.neighborhoodId || null),
        tenantId: esc(d.tenantId || 'koretini'),
        joinedAt: parseTS(d.joinedAt || new Date()),
        billingGroup: esc(d.billingGroup || 'STANDARD'),
        customAnnualFee: esc(d.customAnnualFee || null),
        familyId: esc(d.familyId || null),
        isLegacyEmail: esc(isLegacy),
        profileComplete: esc(profileComplete)
      };
    },
    (id, d) => {
      const isLegacy = d.email && d.email.endsWith('@koretini.legacy');
      const profileComplete = d.profileComplete !== undefined ? d.profileComplete : !isLegacy;
      let emailVal = d.email ? d.email.trim() : null;
      if (emailVal === '') emailVal = null;
      if (emailVal && seenEmails.has(emailVal.toLowerCase())) {
        const parts = emailVal.split('@');
        emailVal = `${parts[0]}_${id.slice(0, 5)}@${parts[1] || 'legacy'}`;
      }
      if (emailVal) seenEmails.add(emailVal.toLowerCase());

      return {
        id,
        email: emailVal,
        displayName: d.displayName || `${d.firstName || ''} ${d.lastName || ''}`.trim() || 'User',
        role: d.role || 'MEMBER',
        membershipStatus: d.membershipStatus || 'ACTIVE',
        phone: d.phone || null,
        street: d.street || null,
        zip: d.zip || null,
        city: d.city || null,
        birthdate: d.birthdate || null,
        neighborhoodId: d.neighborhoodId || null,
        tenantId: d.tenantId || 'koretini',
        joinedAt: parseTSRaw(d.joinedAt),
        billingGroup: d.billingGroup || 'STANDARD',
        customAnnualFee: d.customAnnualFee || null,
        familyId: d.familyId || null,
        isLegacyEmail: Boolean(isLegacy),
        profileComplete: Boolean(profileComplete)
      };
    }
  );

  // 4. Payments
  await migrateCollection(
    'payments', 'payments',
    (id, d) => ({
      id: esc(id),
      userId: esc(d.userId || null),
      tenantId: esc(d.tenantId || 'koretini'),
      neighborhoodId: esc(d.neighborhoodId || null),
      amount: esc(d.amount || 0),
      currency: esc(d.currency || 'CHF'),
      type: esc(d.type || 'FEE'),
      invoiceType: esc(d.invoiceType || 'MEMBERSHIP'),
      billingYear: esc(d.billingYear || null),
      customRecipient: escJSON(d.customRecipient || null),
      method: esc(d.method || 'BANK_TRANSFER'),
      status: esc(d.status || 'PAID'),
      deliveryMethod: esc(d.deliveryMethod || 'EMAIL'),
      scheduledDate: esc(d.scheduledDate || null),
      dunningLevel: esc(d.dunningLevel || 0),
      lastDunningDate: esc(d.lastDunningDate || null),
      timestamp: parseTS(d.timestamp || new Date()),
      dueDate: esc(d.dueDate || null),
      paidAt: esc(d.paidAt || null),
      invoiceNumber: esc(d.invoiceNumber || null),
      description: esc(d.description || null)
    }),
    (id, d) => ({
      id,
      userId: d.userId || null,
      tenantId: d.tenantId || 'koretini',
      neighborhoodId: d.neighborhoodId || null,
      amount: d.amount || 0,
      currency: d.currency || 'CHF',
      type: d.type || 'FEE',
      invoiceType: d.invoiceType || 'MEMBERSHIP',
      billingYear: d.billingYear || null,
      customRecipient: d.customRecipient || null,
      method: d.method || 'BANK_TRANSFER',
      status: d.status || 'PAID',
      deliveryMethod: d.deliveryMethod || 'EMAIL',
      scheduledDate: d.scheduledDate || null,
      dunningLevel: d.dunningLevel || 0,
      lastDunningDate: d.lastDunningDate || null,
      timestamp: parseTSRaw(d.timestamp),
      dueDate: d.dueDate || null,
      paidAt: d.paidAt || null,
      invoiceNumber: d.invoiceNumber || null,
      description: d.description || null
    })
  );

  // 5. Accounting Accounts
  await migrateCollection(
    'accounting_accounts', 'accounting_accounts',
    (id, d) => ({
      id: esc(id),
      code: esc(d.code || '1000'),
      name: esc(d.name || 'Account'),
      class: esc(d.class || 'ASSET'),
      category: esc(d.category || null),
      systemAccount: esc(d.systemAccount || false)
    }),
    (id, d) => ({
      id,
      code: d.code || '1000',
      name: d.name || 'Account',
      class: d.class || 'ASSET',
      category: d.category || null,
      systemAccount: Boolean(d.systemAccount)
    })
  );

  // 6. Accounting Journal
  await migrateCollection(
    'accounting_journal', 'accounting_journal',
    (id, d) => ({
      id: esc(id),
      date: esc(d.date || new Date().toISOString().split('T')[0]),
      description: esc(d.description || 'Entry'),
      debit: esc(d.debitCode || d.debit || null),
      credit: esc(d.creditCode || d.credit || null),
      amount: esc(d.amount || 0),
      timestamp: parseTS(d.createdAt || d.timestamp || new Date())
    }),
    (id, d) => ({
      id,
      date: d.date || new Date().toISOString().split('T')[0],
      description: d.description || 'Entry',
      debit: d.debitCode || d.debit || null,
      credit: d.creditCode || d.credit || null,
      amount: d.amount || 0,
      timestamp: parseTSRaw(d.createdAt || d.timestamp)
    })
  );

  // 7. Expenses
  await migrateCollection(
    'expenses', 'expenses',
    (id, d) => {
      const isApproved = d.status === 'APPROVED' || d.status === 'PAID';
      const isPaid = d.status === 'PAID';
      return {
        id: esc(id),
        title: esc(d.vendor || d.description || 'Expense'),
        amount: esc(d.amount || 0),
        category: esc(d.categoryAccountCode || d.category || null),
        date: esc(d.date || new Date().toISOString().split('T')[0]),
        approved: esc(isApproved),
        paid: esc(isPaid),
        receiptUrl: esc(d.receiptUrl || null),
        approvedBy: esc(d.approvedBy || null),
        createdBy: esc(d.createdBy || null),
        timestamp: parseTS(d.createdAt || d.timestamp || new Date())
      };
    },
    (id, d) => {
      const isApproved = d.status === 'APPROVED' || d.status === 'PAID';
      const isPaid = d.status === 'PAID';
      return {
        id,
        title: d.vendor || d.description || 'Expense',
        amount: d.amount || 0,
        category: d.categoryAccountCode || d.category || null,
        date: d.date || new Date().toISOString().split('T')[0],
        approved: Boolean(isApproved),
        paid: Boolean(isPaid),
        receiptUrl: d.receiptUrl || null,
        approvedBy: d.approvedBy || null,
        createdBy: d.createdBy || null,
        timestamp: parseTSRaw(d.createdAt || d.timestamp)
      };
    }
  );

  // 8. Events
  await migrateCollection(
    'events', 'events',
    (id, d) => ({
      id: esc(id),
      title: esc(d.title || 'Event'),
      description: esc(d.description || null),
      date: esc(d.date || new Date().toISOString().split('T')[0]),
      location: esc(d.location || 'Koretin'),
      image: esc(d.image || null),
      createdAt: parseTS(d.createdAt || new Date()),
      limit: esc(d.limit || null)
    }),
    (id, d) => ({
      id,
      title: d.title || 'Event',
      description: d.description || null,
      date: d.date || new Date().toISOString().split('T')[0],
      location: d.location || 'Koretin',
      image: d.image || null,
      createdAt: parseTSRaw(d.createdAt),
      limit: d.limit || null
    })
  );

  // 9. Event Registrations
  await migrateCollection(
    'event_registrations', 'event_registrations',
    (id, d) => ({
      id: esc(id),
      eventId: esc(d.eventId || null),
      userId: esc(d.userId || null),
      timestamp: parseTS(d.registeredAt || d.timestamp || new Date()),
      tickets: esc(d.tickets || 1),
      name: esc(d.name || null),
      email: esc(d.email || null)
    }),
    (id, d) => ({
      id,
      eventId: d.eventId || null,
      userId: d.userId || null,
      timestamp: parseTSRaw(d.registeredAt || d.timestamp),
      tickets: d.tickets || 1,
      name: d.name || null,
      email: d.email || null
    })
  );

  // 10. News Articles
  await migrateCollection(
    'news', 'news',
    (id, d) => {
      const formattedContent = Array.isArray(d.content) ? d.content.join('\n\n') : (d.content || '');
      return {
        id: esc(id),
        title: esc(d.title || 'Untitled News'),
        content: esc(formattedContent),
        image: esc(d.image || null),
        timestamp: parseTS(d.timestamp || new Date()),
        author: esc(d.author || null)
      };
    },
    (id, d) => {
      const formattedContent = Array.isArray(d.content) ? d.content.join('\n\n') : (d.content || '');
      return {
        id,
        title: d.title || 'Untitled News',
        content: formattedContent,
        image: d.image || null,
        timestamp: parseTSRaw(d.timestamp),
        author: d.author || null
      };
    }
  );

  // 11. Security Logs
  await migrateCollection(
    'security_logs', 'security_logs',
    (id, d) => ({
      id: esc(id),
      ipAddress: esc(d.ipAddress || null),
      userAgent: esc(d.userAgent || null),
      type: esc(d.type || 'INFO'),
      violation: esc(d.violation || null),
      timestamp: parseTS(d.timestamp || new Date())
    }),
    (id, d) => ({
      id,
      ipAddress: d.ipAddress || null,
      userAgent: d.userAgent || null,
      type: d.type || 'INFO',
      violation: d.violation || null,
      timestamp: parseTSRaw(d.timestamp)
    })
  );

  // 12. Polls
  await migrateCollection(
    'polls', 'polls',
    (id, d) => ({
      id: esc(id),
      question: esc(d.question || 'Question'),
      options: escJSON(d.options || []),
      expiresAt: esc(d.expiresAt || null),
      status: esc(d.active ? 'ACTIVE' : 'INACTIVE'),
      createdAt: parseTS(d.createdAt || new Date())
    }),
    (id, d) => ({
      id,
      question: d.question || 'Question',
      options: d.options || [],
      expiresAt: d.expiresAt || null,
      status: d.active ? 'ACTIVE' : 'INACTIVE',
      createdAt: parseTSRaw(d.createdAt)
    })
  );

  // 13. Inquiries
  await migrateCollection(
    'inquiries', 'inquiries',
    (id, d) => ({
      id: esc(id),
      subject: esc(d.subject || 'Inquiry'),
      message: esc(d.message || ''),
      email: esc(d.email || d.userName || ''),
      status: esc(d.status || 'OPEN'),
      createdAt: parseTS(d.createdAt || new Date())
    }),
    (id, d) => ({
      id,
      subject: d.subject || 'Inquiry',
      message: d.message || '',
      email: d.email || d.userName || '',
      status: d.status || 'OPEN',
      createdAt: parseTSRaw(d.createdAt)
    })
  );

  // 14. Tasks
  await migrateCollection(
    'tasks', 'tasks',
    (id, d) => ({
      id: esc(id),
      title: esc(d.title || 'Task'),
      description: esc(d.description || null),
      status: esc(d.status || 'TODO'),
      dueDate: esc(d.dueDate || null),
      assignedTo: escJSON(d.assignedTo || []),
      createdBy: esc(d.createdBy || null),
      createdAt: parseTS(d.createdAt || new Date())
    }),
    (id, d) => ({
      id,
      title: d.title || 'Task',
      description: d.description || null,
      status: d.status || 'TODO',
      dueDate: d.dueDate || null,
      assignedTo: d.assignedTo || [],
      createdBy: d.createdBy || null,
      createdAt: parseTSRaw(d.createdAt)
    })
  );

  // 15. Board Members
  await migrateCollection(
    'board_members', 'board_members',
    (id, d) => ({
      id: esc(id),
      userId: esc(d.userId || ''),
      role: esc(d.role || 'Member'),
      joinedAt: parseTS(d.createdAt || d.joinedAt || new Date())
    }),
    (id, d) => ({
      id,
      userId: d.userId || '',
      role: d.role || 'Member',
      joinedAt: parseTSRaw(d.createdAt || d.joinedAt)
    })
  );

  // 16. Board Meetings
  await migrateCollection(
    'board_meetings', 'board_meetings',
    (id, d) => ({
      id: esc(id),
      title: esc(d.title || 'Meeting'),
      date: esc(d.date || new Date().toISOString().split('T')[0]),
      boardMembers: escJSON(d.attendees || null),
      decisions: escJSON(d.agendaItems || null),
      createdAt: parseTS(d.createdAt || new Date())
    }),
    (id, d) => ({
      id,
      title: d.title || 'Meeting',
      date: d.date || new Date().toISOString().split('T')[0],
      boardMembers: d.attendees || null,
      decisions: d.agendaItems || null,
      createdAt: parseTSRaw(d.createdAt)
    })
  );

  // 17. Social Media Posts
  await migrateCollection(
    'socialMediaPosts', 'socialmediaposts',
    (id, d) => {
      const platforms = Array.isArray(d.platforms) ? d.platforms.join(', ') : (d.platform || 'FACEBOOK');
      return {
        id: esc(id),
        content: esc(d.content || ''),
        timestamp: parseTS(d.timestamp || d.scheduledTime || new Date()),
        platform: esc(platforms),
        status: esc(d.status || 'DRAFT')
      };
    },
    (id, d) => {
      const platforms = Array.isArray(d.platforms) ? d.platforms.join(', ') : (d.platform || 'FACEBOOK');
      return {
        id,
        content: d.content || '',
        timestamp: parseTSRaw(d.timestamp || d.scheduledTime),
        platform: platforms,
        status: d.status || 'DRAFT'
      };
    }
  );

  // 18. Settings
  console.log('\n📡 Migrating global settings from multiple documents...');
  try {
    const resSys = await fetchWithRetry('https://firestore.googleapis.com/v1/projects/shoqatawebsite/databases/(default)/documents/settings/system');
    const resPay = await fetchWithRetry('https://firestore.googleapis.com/v1/projects/shoqatawebsite/databases/(default)/documents/settings/payment');

    const sysDoc = resSys.ok ? await resSys.json() : null;
    const payDoc = resPay.ok ? await resPay.json() : null;

    const systemData = sysDoc ? parseFirestoreDoc(sysDoc).data : {};
    const paymentData = payDoc ? parseFirestoreDoc(payDoc).data : {};

    sqlOutput += `-- ---------------------------------------------------------\n`;
    sqlOutput += `-- Data for Table: settings\n`;
    sqlOutput += `-- ---------------------------------------------------------\n`;
    
    const settingsId = 'global';
    sqlOutput += `INSERT INTO "settings" ("id", "payment", "system") \n`;
    sqlOutput += `VALUES (${esc(settingsId)}, ${escJSON(paymentData)}, ${escJSON(systemData)}) \n`;
    sqlOutput += `ON CONFLICT ("id") DO UPDATE SET \n`;
    sqlOutput += `  "payment" = EXCLUDED."payment",\n`;
    sqlOutput += `  "system" = EXCLUDED."system";\n\n`;

    if (supabase) {
      const { error } = await supabase.from('settings').upsert([{
        id: settingsId,
        payment: paymentData,
        system: systemData
      }]);
      if (error) {
        console.error('  ❌ Supabase direct upsert error for "settings":', error.message);
      } else {
        console.log('  🚀 Directly imported global settings into Supabase.');
      }
    }

    console.log('✅ Global settings successfully mapped.');
  } catch (err) {
    console.error('❌ Error migrating global settings:', err.message);
  }

  // Final Commit
  sqlOutput += `COMMIT;\n`;

  // Write to Output SQL File
  const outputPath = path.join(__dirname, 'supabase-seed.sql');
  fs.writeFileSync(outputPath, sqlOutput, 'utf8');

  console.log('\n===================================================');
  console.log('🎉 MIGRATION ENGINE COMPLETED SUCCESSFULLY! 🎉');
  console.log('===================================================');
  console.log(`💾 SQL File generated: ${outputPath}`);
  console.log(`📝 Total Size: ${(fs.statSync(outputPath).size / 1024).toFixed(2)} KB`);
  console.log('===================================================');
}

run().catch(err => {
  console.error('Fatal migration error:', err);
});
