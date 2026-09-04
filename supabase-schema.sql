-- ============================================================
-- Supabase DB Schema für Shoqata Koretini Platform
-- Projekt: rabpkwwozkwsnyoivocy
-- Datum: 2026-09-04
-- Führe dieses Script im Supabase SQL Editor aus:
-- https://supabase.com/dashboard/project/rabpkwwozkwsnyoivocy/sql
-- ============================================================

-- =====================
-- TENANTS
-- =====================
CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  "logoUrl" TEXT,
  "primaryColor" TEXT,
  "secondaryColor" TEXT,
  "subscriptionPlan" TEXT DEFAULT 'FREE',
  "subscriptionStatus" TEXT DEFAULT 'ACTIVE',
  "stripeCustomerId" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "contactEmail" TEXT,
  "memberCount" INT DEFAULT 0
);

-- =====================
-- USERS
-- =====================
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  "tenantId" TEXT,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'MEMBER',
  "isBoardMember" BOOLEAN DEFAULT FALSE,
  "displayName" TEXT,
  "firstName" TEXT,
  "lastName" TEXT,
  salutation TEXT,
  birthdate TEXT,
  "membershipCategory" TEXT DEFAULT 'INDIVIDUAL',
  "membershipStatus" TEXT DEFAULT 'PENDING',
  "invoiceDeliveryMethod" TEXT DEFAULT 'EMAIL',
  "billingGroup" TEXT DEFAULT 'STANDARD',
  "customAnnualFee" NUMERIC,
  "neighborhoodId" TEXT,
  "familyId" TEXT,
  "migrationRequired" TEXT,
  "livesInKoretin" BOOLEAN DEFAULT FALSE,
  "joinedAt" TIMESTAMPTZ DEFAULT NOW(),
  "profileComplete" BOOLEAN DEFAULT FALSE,
  "dataUpdateRequested" BOOLEAN DEFAULT FALSE,
  address TEXT,
  street TEXT,
  zip TEXT,
  city TEXT,
  country TEXT,
  phone TEXT,
  "phoneSecondary" TEXT,
  currency TEXT DEFAULT 'CHF',
  "photoFileName" TEXT,
  "internalNotes" TEXT,
  reminders JSONB DEFAULT '[]'
);

-- =====================
-- SETTINGS (branding, system, payment)
-- =====================
CREATE TABLE IF NOT EXISTS settings (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}'
);

-- Seed default settings rows
INSERT INTO settings (id, data) VALUES
  ('branding', '{"primary": "#f43f5e", "secondary": "#1c1917"}'),
  ('system', '{"maintenanceMode": false, "allowRegistration": true, "modules": {"villageLive": true, "events": true, "news": true}, "systemEmail": "info@koretini.org"}'),
  ('payment', '{"iban": "", "bankName": "", "bic": "", "accountHolder": "", "currency": "CHF", "annualFeeAmount": 60}')
ON CONFLICT (id) DO NOTHING;

-- =====================
-- NEIGHBORHOODS
-- =====================
CREATE TABLE IF NOT EXISTS neighborhoods (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  name TEXT NOT NULL,
  description TEXT,
  location JSONB,
  "managerId" TEXT,
  "memberCount" INT DEFAULT 0,
  "contactPerson" TEXT,
  "contactPersonIds" JSONB DEFAULT '[]',
  "contactEmail" TEXT,
  "contactPhone" TEXT,
  website TEXT,
  image TEXT,
  status TEXT DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "lastActivity" TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- PAYMENTS
-- =====================
CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  "userId" TEXT,
  "neighborhoodId" TEXT,
  amount NUMERIC NOT NULL,
  currency TEXT DEFAULT 'CHF',
  type TEXT DEFAULT 'FEE',
  "invoiceType" TEXT DEFAULT 'MEMBERSHIP',
  "billingYear" INT,
  "customRecipient" JSONB,
  method TEXT DEFAULT 'BANK_TRANSFER',
  status TEXT DEFAULT 'DRAFT',
  "deliveryMethod" TEXT DEFAULT 'EMAIL',
  "scheduledDate" TEXT,
  "dunningLevel" INT DEFAULT 0,
  "lastDunningDate" TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  "dueDate" TEXT,
  "paidAt" TEXT,
  "invoiceNumber" TEXT,
  reference TEXT,
  description TEXT,
  "pdfUrl" TEXT,
  "bookedInJournal" BOOLEAN DEFAULT FALSE,
  "collectedBy" TEXT
);

-- =====================
-- EXPENSES
-- =====================
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  vendor TEXT,
  description TEXT,
  amount NUMERIC NOT NULL,
  currency TEXT DEFAULT 'CHF',
  date TEXT,
  "dueDate" TEXT,
  "categoryAccountCode" TEXT,
  "paymentAccountCode" TEXT,
  status TEXT DEFAULT 'PENDING',
  "receiptUrl" TEXT,
  "bookedInJournal" BOOLEAN DEFAULT FALSE,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "createdBy" TEXT
);

-- =====================
-- NEWS
-- =====================
CREATE TABLE IF NOT EXISTS news (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  title TEXT NOT NULL,
  category TEXT,
  subcategory TEXT,
  location TEXT,
  image TEXT,
  content JSONB DEFAULT '[]',
  status TEXT DEFAULT 'DRAFT',
  "publishAt" TIMESTAMPTZ,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  "gradientColors" JSONB DEFAULT '[]'
);

-- =====================
-- EVENTS
-- =====================
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  title TEXT NOT NULL,
  description TEXT,
  date TEXT,
  time TEXT,
  location TEXT,
  image TEXT,
  images JSONB DEFAULT '[]',
  category TEXT DEFAULT 'SOCIAL',
  status TEXT DEFAULT 'DRAFT',
  "isFeatured" BOOLEAN DEFAULT FALSE,
  "isRegistrable" BOOLEAN DEFAULT FALSE,
  "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- EVENT REGISTRATIONS
-- =====================
CREATE TABLE IF NOT EXISTS event_registrations (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "eventId" TEXT,
  "eventTitle" TEXT,
  "userId" TEXT,
  name TEXT,
  email TEXT,
  phone TEXT,
  type TEXT DEFAULT 'MEMBER',
  "registeredAt" TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'PENDING'
);

-- =====================
-- POLLS
-- =====================
CREATE TABLE IF NOT EXISTS polls (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  question TEXT NOT NULL,
  options JSONB DEFAULT '[]',
  active BOOLEAN DEFAULT TRUE,
  "allowMultiple" BOOLEAN DEFAULT FALSE,
  "createdBy" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "expiresAt" TEXT,
  "userVotes" JSONB DEFAULT '[]'
);

-- =====================
-- TASKS
-- =====================
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'TODO',
  priority TEXT DEFAULT 'MEDIUM',
  "assignedTo" JSONB DEFAULT '[]',
  "assignedToName" TEXT,
  "dueDate" TEXT,
  "createdBy" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "sourceMeetingId" TEXT
);

-- =====================
-- BOARD MEETINGS
-- =====================
CREATE TABLE IF NOT EXISTS board_meetings (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  title TEXT NOT NULL,
  date TEXT,
  location TEXT,
  attendees JSONB DEFAULT '[]',
  "agendaItems" JSONB DEFAULT '[]',
  status TEXT DEFAULT 'PLANNED',
  documents JSONB DEFAULT '[]'
);

-- =====================
-- BOARD MEMBERS
-- =====================
CREATE TABLE IF NOT EXISTS board_members (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "userId" TEXT,
  role TEXT,
  quote TEXT,
  image TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- ACCOUNTING JOURNAL
-- =====================
CREATE TABLE IF NOT EXISTS accounting_journal (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  date TEXT,
  description TEXT,
  "debitCode" TEXT,
  "creditCode" TEXT,
  amount NUMERIC,
  "referenceId" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "isSystemEntry" BOOLEAN DEFAULT FALSE
);

-- =====================
-- ACCOUNTING ACCOUNTS (Kontenplan)
-- =====================
CREATE TABLE IF NOT EXISTS accounting_accounts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  code TEXT UNIQUE,
  name TEXT,
  class TEXT,
  category TEXT,
  "systemAccount" BOOLEAN DEFAULT FALSE
);

-- =====================
-- FISCAL YEARS
-- =====================
CREATE TABLE IF NOT EXISTS fiscal_years (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  year INT,
  status TEXT DEFAULT 'OPEN',
  "closedAt" TEXT,
  "netProfit" NUMERIC
);

-- =====================
-- INQUIRIES
-- =====================
CREATE TABLE IF NOT EXISTS inquiries (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "userId" TEXT,
  "userName" TEXT,
  type TEXT DEFAULT 'GENERAL',
  subject TEXT,
  message TEXT,
  status TEXT DEFAULT 'OPEN',
  "adminNote" TEXT,
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ
);

-- =====================
-- SOCIAL MEDIA POSTS
-- =====================
CREATE TABLE IF NOT EXISTS "socialMediaPosts" (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  content TEXT,
  platforms JSONB DEFAULT '[]',
  "scheduledTime" TEXT,
  status TEXT DEFAULT 'DRAFT',
  "aiGenerated" BOOLEAN DEFAULT FALSE,
  "imagePrompt" TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  image TEXT
);

-- =====================
-- SECURITY LOGS
-- =====================
CREATE TABLE IF NOT EXISTS security_logs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "userId" TEXT,
  action TEXT,
  details JSONB,
  "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- ROW LEVEL SECURITY
-- =====================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE neighborhoods ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE news ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounting_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounting_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE fiscal_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE "socialMediaPosts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;

-- PUBLIC READ POLICIES (für öffentliche Seiten)
CREATE POLICY "Public read tenants" ON tenants FOR SELECT USING (true);
CREATE POLICY "Public read settings" ON settings FOR SELECT USING (true);
CREATE POLICY "Public read neighborhoods" ON neighborhoods FOR SELECT USING (true);
CREATE POLICY "Public read news" ON news FOR SELECT USING (status = 'PUBLISHED');
CREATE POLICY "Public read events" ON events FOR SELECT USING (status = 'PUBLISHED');

-- ALL ACCESS FOR AUTHENTICATED USERS (App handles authorization in code)
-- This is a pragmatic approach: RLS allows all CRUD for logged-in users,
-- the app-level code enforces role checks.
CREATE POLICY "Auth users full access users" ON users FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access payments" ON payments FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access expenses" ON expenses FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access news" ON news FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access events" ON events FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access event_reg" ON event_registrations FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access polls" ON polls FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access tasks" ON tasks FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access board_meetings" ON board_meetings FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access board_members" ON board_members FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access accounting_journal" ON accounting_journal FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access accounting_accounts" ON accounting_accounts FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access fiscal_years" ON fiscal_years FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access inquiries" ON inquiries FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access socialMediaPosts" ON "socialMediaPosts" FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access tenants write" ON tenants FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access settings write" ON settings FOR ALL USING (auth.uid() IS NOT NULL);
CREATE POLICY "Auth users full access neighborhoods write" ON neighborhoods FOR ALL USING (auth.uid() IS NOT NULL);

-- Security logs: anyone can insert, only authenticated can read
CREATE POLICY "Anyone can insert security_logs" ON security_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth users read security_logs" ON security_logs FOR SELECT USING (auth.uid() IS NOT NULL);
