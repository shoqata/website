-- Bringt die Datenbank auf den Stand von supabase-schema.sql.
-- Rein additiv: legt fehlende Spalten und Tabellen an, aendert und loescht nichts.
-- Ausfuehren im Supabase SQL Editor.

BEGIN;

-- accounting_journal
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "debitCode" TEXT;
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "creditCode" TEXT;
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "referenceId" TEXT;
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE "accounting_journal" ADD COLUMN IF NOT EXISTS "isSystemEntry" BOOLEAN DEFAULT FALSE;

-- board_meetings
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "location" TEXT;
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "attendees" JSONB DEFAULT '[]';
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "agendaItems" JSONB DEFAULT '[]';
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'PLANNED';
ALTER TABLE "board_meetings" ADD COLUMN IF NOT EXISTS "documents" JSONB DEFAULT '[]';

-- board_members
ALTER TABLE "board_members" ADD COLUMN IF NOT EXISTS "quote" TEXT;
ALTER TABLE "board_members" ADD COLUMN IF NOT EXISTS "image" TEXT;
ALTER TABLE "board_members" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();

-- event_registrations
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "eventTitle" TEXT;
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "phone" TEXT;
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "type" TEXT DEFAULT 'MEMBER';
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "registeredAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'PENDING';

-- events
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "time" TEXT;
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "images" JSONB DEFAULT '[]';
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "category" TEXT DEFAULT 'SOCIAL';
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'DRAFT';
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "isFeatured" BOOLEAN DEFAULT FALSE;
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "isRegistrable" BOOLEAN DEFAULT FALSE;

-- expenses
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "vendor" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "description" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "currency" TEXT DEFAULT 'CHF';
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "dueDate" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "categoryAccountCode" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "paymentAccountCode" TEXT;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'PENDING';
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "bookedInJournal" BOOLEAN DEFAULT FALSE;
ALTER TABLE "expenses" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();

-- fiscal_years: Tabelle fehlt komplett
CREATE TABLE IF NOT EXISTS fiscal_years (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "tenantId" TEXT,
  year INT,
  status TEXT DEFAULT 'OPEN',
  "closedAt" TEXT,
  "netProfit" NUMERIC
);

-- inquiries
ALTER TABLE "inquiries" ADD COLUMN IF NOT EXISTS "userId" TEXT;
ALTER TABLE "inquiries" ADD COLUMN IF NOT EXISTS "userName" TEXT;
ALTER TABLE "inquiries" ADD COLUMN IF NOT EXISTS "type" TEXT DEFAULT 'GENERAL';
ALTER TABLE "inquiries" ADD COLUMN IF NOT EXISTS "adminNote" TEXT;
ALTER TABLE "inquiries" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ;

-- neighborhoods
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "location" JSONB;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "managerId" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "memberCount" INT DEFAULT 0;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "contactPerson" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "contactPersonIds" JSONB DEFAULT '[]';
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "contactEmail" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "contactPhone" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "website" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "image" TEXT;
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'ACTIVE';
ALTER TABLE "neighborhoods" ADD COLUMN IF NOT EXISTS "lastActivity" TIMESTAMPTZ DEFAULT NOW();

-- news
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "category" TEXT;
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "subcategory" TEXT;
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "location" TEXT;
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'DRAFT';
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "publishAt" TIMESTAMPTZ;
ALTER TABLE "news" ADD COLUMN IF NOT EXISTS "gradientColors" JSONB DEFAULT '[]';

-- payments
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "reference" TEXT;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "pdfUrl" TEXT;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "bookedInJournal" BOOLEAN DEFAULT FALSE;
ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "collectedBy" TEXT;

-- polls
ALTER TABLE "polls" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "polls" ADD COLUMN IF NOT EXISTS "active" BOOLEAN DEFAULT TRUE;
ALTER TABLE "polls" ADD COLUMN IF NOT EXISTS "allowMultiple" BOOLEAN DEFAULT FALSE;
ALTER TABLE "polls" ADD COLUMN IF NOT EXISTS "createdBy" TEXT;
ALTER TABLE "polls" ADD COLUMN IF NOT EXISTS "userVotes" JSONB DEFAULT '[]';

-- security_logs
ALTER TABLE "security_logs" ADD COLUMN IF NOT EXISTS "userId" TEXT;
ALTER TABLE "security_logs" ADD COLUMN IF NOT EXISTS "action" TEXT;
ALTER TABLE "security_logs" ADD COLUMN IF NOT EXISTS "details" JSONB;
ALTER TABLE "security_logs" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();

-- settings
ALTER TABLE "settings" ADD COLUMN IF NOT EXISTS "data" JSONB NOT NULL DEFAULT '{}';

-- socialMediaPosts
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "platforms" JSONB DEFAULT '[]';
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "scheduledTime" TEXT;
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "aiGenerated" BOOLEAN DEFAULT FALSE;
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "imagePrompt" TEXT;
ALTER TABLE "socialmediaposts" ADD COLUMN IF NOT EXISTS "image" TEXT;

-- tasks
ALTER TABLE "tasks" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE "tasks" ADD COLUMN IF NOT EXISTS "priority" TEXT DEFAULT 'MEDIUM';
ALTER TABLE "tasks" ADD COLUMN IF NOT EXISTS "assignedToName" TEXT;
ALTER TABLE "tasks" ADD COLUMN IF NOT EXISTS "sourceMeetingId" TEXT;

-- tenants
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "logoUrl" TEXT;
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "primaryColor" TEXT;
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "secondaryColor" TEXT;
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "subscriptionPlan" TEXT DEFAULT 'FREE';
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "subscriptionStatus" TEXT DEFAULT 'ACTIVE';
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "stripeCustomerId" TEXT;
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "contactEmail" TEXT;
ALTER TABLE "tenants" ADD COLUMN IF NOT EXISTS "memberCount" INT DEFAULT 0;

-- users
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "isBoardMember" BOOLEAN DEFAULT FALSE;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "firstName" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "lastName" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "salutation" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "membershipCategory" TEXT DEFAULT 'INDIVIDUAL';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "invoiceDeliveryMethod" TEXT DEFAULT 'EMAIL';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "migrationRequired" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "livesInKoretin" BOOLEAN DEFAULT FALSE;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "dataUpdateRequested" BOOLEAN DEFAULT FALSE;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "address" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "country" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "phoneSecondary" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "currency" TEXT DEFAULT 'CHF';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "photoFileName" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "internalNotes" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "reminders" JSONB DEFAULT '[]';

-- socialMediaPosts: der Code fragt "socialMediaPosts" ab (case-sensitive),
-- die echte Tabelle heisst socialmediaposts. Eine einfache SELECT-*-View ist in
-- Postgres automatisch beschreibbar und macht beide Schreibweisen nutzbar,
-- ohne die bestehende Tabelle umzubenennen.
CREATE OR REPLACE VIEW "socialMediaPosts" AS SELECT * FROM socialmediaposts;

COMMIT;
