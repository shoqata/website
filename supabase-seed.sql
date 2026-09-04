-- =========================================================
-- SUPABASE DATA SEED SCRIPT (MIGRATED FROM FIRESTORE)
-- Generated on: 2026-09-04T20:34:06.504Z
-- =========================================================

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

-- ---------------------------------------------------------
-- Data for Table: tenants
-- ---------------------------------------------------------
INSERT INTO "tenants" ("id", "name", "domain", "logo", "createdAt", "status", "slug") 
VALUES ('b29gMh83LaLB17YvmktX', 'Shoqata Humanitare Koretini', 'shoqata-humanitare-koretini', NULL, '2026-01-09T11:53:54.238Z', 'ACTIVE', 'shoqata-humanitare-koretini') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "domain" = EXCLUDED."domain",
  "logo" = EXCLUDED."logo",
  "createdAt" = EXCLUDED."createdAt",
  "status" = EXCLUDED."status",
  "slug" = EXCLUDED."slug";

-- ---------------------------------------------------------
-- Data for Table: neighborhoods
-- ---------------------------------------------------------
INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('1H8vJXoJkF1iFEZPUgUP', 'Leca-jt', 'Koretin', NULL, NULL, '2026-01-09T09:48:57.447Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('2dfxYzVnwHgXPatyu34F', 'Canaj-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.203Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('5KwI3rPMfthzTamV4Omi', 'Rexha-t, Shaqira-jt', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.867Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('8KGIaCmhzCimjPGxWRnJ', 'Zarbinct', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.104Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('Gw8s5lNhSTd54MqCjczI', 'Selmana-jt, Dervish-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.904Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('IAs5cJR7erHaldgnNsUi', 'Basha-t', 'Koretin', NULL, NULL, '2026-01-09T08:13:05.541Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('Ic9yVntQPNmQgtPadHCJ', 'Ramadan-aj (suharrna)', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.832Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('JQM71uI7qbLu1WoLEgcq', 'Haxhia-jt', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.297Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('N8tL7KMa4gnmGuC0SRqP', 'Klaiq-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.633Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('NMx47Gf7MOqKG7SHurqq', 'Pireva-jt', 'Koretin', NULL, NULL, '2026-01-09T09:42:48.275Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('Onysnf1rqURgy68fA5A5', 'Bugaqk-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.797Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('P1ucCFXXVyHgGsA1hXDV', 'Berish-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.158Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('RJHRQkks4TmQIKfoXf3v', 'Matosh-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.718Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('RMsYofQDTV9zBjVwVQF4', 'Kërçel-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.404Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('RSIEPgUmzLRNEWX0vdHH', 'Sylaj-t', 'Koretin', NULL, NULL, '2026-01-09T08:12:57.479Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('YJ2X9Smwr7YHiTipmEQL', 'Gjyrishevc-t', 'Koretin', NULL, NULL, '2026-01-09T08:12:56.797Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('cyohY3a11AJBcnysXocA', 'Maliqt, Hoda-jt, Maka-jt, Bushi, Ibushi, Korbi, Sylejmani', 'Koretin', NULL, NULL, '2026-01-09T08:13:06.184Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('gg0GE0qz4ZMf35cRtesp', 'Kosum-t', 'Koretin', NULL, NULL, '2026-01-09T08:12:56.993Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('jXooYH3RfXSRcHEodS1y', 'Kovan-t', 'Koretin', NULL, NULL, '2026-01-09T08:13:06.066Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('nluPWLS0NdyzaJtUwsGn', 'Skoverçan-t', 'Koretin', NULL, NULL, '2026-01-09T08:12:57.437Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('qR9T0s2sdVBwYQmVi20d', 'Krasniq-t', 'Koretin', NULL, NULL, '2026-01-09T08:13:06.104Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('wQV3M5IQiReJPGyR0gqN', 'Dem-t', 'Koretin', NULL, NULL, '2026-01-17T17:47:18.243Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "neighborhoods" ("id", "name", "city", "representativeId", "description", "createdAt") 
VALUES ('x7z55SgYcUEMHrnVLhwl', 'Keçmez-t', 'Koretin', NULL, NULL, '2026-01-09T08:12:56.840Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "name" = EXCLUDED."name",
  "city" = EXCLUDED."city",
  "representativeId" = EXCLUDED."representativeId",
  "description" = EXCLUDED."description",
  "createdAt" = EXCLUDED."createdAt";

-- ---------------------------------------------------------
-- Data for Table: users
-- ---------------------------------------------------------
INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('03iU2zILAfwx9bRHG5by', 'feim.haxhiu.no-email-54505274@koretini.legacy', 'Feim Haxhiu', 'MEMBER', 'ACTIVE', '+4915235235165', 'Eshramlichweg12', '36145', 'Hofbieber', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.053Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('0MC93e96mxp9WCxT7w6W', 'info@canaj.ch', 'Arben Canaj', 'MEMBER', 'ACTIVE', '+4179 423 09 06', 'Feldhofstrasse 37', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:50.925Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('0MCyPLaxv7IOysyXU0zZ', 'isen.dervishi@isen-tiefbau.ch', 'Isen Dervishi', 'MEMBER', 'ACTIVE', '+41 79 417 79 66', 'Steigstrasse 20', '5426', 'Lengnau', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.615Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('0UMG0pIQFUWOmWLiTLZz6rP82122', 'valton.rexha@gmail.com', 'Valton Rexha', 'ADMIN', 'ACTIVE', '+41791382816', 'Weidgartenstrasse 8', '8909', 'Zwillikon ZH', '1984-06-25', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-02-16T18:04:43.977Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('0UkDNhlytOBDmfzeECb3', 'mirand.kallaba.no-email-54664560@koretini.legacy', 'Mirand Kallaba', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.645Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('1Tc3sCOCRcwPS4HEhaSG', 'murat.canaj.no-email-55180557@koretini.legacy', 'Murat Canaj', 'MEMBER', 'ACTIVE', '+4176 332 50 88', 'Brisgistrasse 24', '5400', 'Baden', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.805Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('1cood32XyZAcNAFzWNaD', 'vullnet.rexha@outlook.com', 'Vullnet Rexha', 'MEMBER', 'ACTIVE', '+41765711489', 'Seebahnstrasse 185', '8004', 'Zürich', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.091Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('1d7IUQgwIFmsVYiQDLsk', 'jakup..isufi.no-email-55318759@koretini.legacy', 'Jakup  Isufi', 'MEMBER', 'ACTIVE', '+4144 930 74 69', 'Pfäffikerstr. 75', '8623', 'Wetzikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.187Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('1hzlVbVNUMFWLPthetoM', 'abaz.berisha.no-email-5579888@koretini.legacy', 'Abaz Berisha', 'MEMBER', 'ACTIVE', NULL, 'Unterdorfstrasse 31', '8964', 'Rudlofstetten', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:57.988Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('2DAE21s8ojZbyhtoaBl8', 'mevlan.rexha.no-email-5439136@koretini.legacy', 'Mevlan Rexha', 'MEMBER', 'ACTIVE', '+41786558877', 'Glattalstrasse 144', '8153', 'Rümlang', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.913Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('2RumRkBhxkV8DAzYDUEW', 'ali.kovani.no-email-55761023@koretini.legacy', 'Ali Kovani', 'MEMBER', 'ACTIVE', NULL, '9rue de la cavee d auge', '61160', 'Trun', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.610Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('2WC014kNRzoqN7TPJSjZ', 'samir.isufi.no-email-5539404@koretini.legacy', 'Samir Isufi', 'MEMBER', 'ACTIVE', NULL, 'Forchstrasse 270', '8008', 'Zürich', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.940Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('2WULf3QDeUq7EO0fJW4X', 'fati-521@hotmail.com', 'Fatmir Bajrami', 'MEMBER', 'ACTIVE', '+4179 521 11 22', 'Wäsewisenstrasse 67', '8408', 'Winterthur', NULL, '8KGIaCmhzCimjPGxWRnJ', 'koretini', '2026-01-31T11:05:56.808Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('2mVjGUNqllvbXylTy2lp', 'shefki.kovani.no-email-55757137@koretini.legacy', 'Shefki Kovani', 'MEMBER', 'ACTIVE', NULL, 'Steigstrasse 14', '8010', 'Uster', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.571Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('31sZnVOqmioRXVxHCH75', 'artani-26@hotmail.com', 'Artan Berisha', 'MEMBER', 'ACTIVE', NULL, 'Lindenstrasse 13', '5430', 'Wettingen', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:57.811Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('3ecT5TsyiVlr7LXVUFve', 'bejtush.bugaqku.no-email-54705398@koretini.legacy', 'Bejtush Bugaqku', 'MEMBER', 'ACTIVE', '+4915730737211', 'Berlinestrasse 1', NULL, 'Vilisburg', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.053Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('3oIhY0Z1ffyaTlf0n9DS', 'leutrim.isufi.no-email-55375126@koretini.legacy', 'Leutrim Isufi', 'MEMBER', 'ACTIVE', '+4179 213 61 98', 'Dänikerstrasse 18', '8108', 'Dällikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.751Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('3tTHJOdwxqle87zsQVpJ', 'leotrim.selmoni@gmail.com', 'Leotrim Selmoni', 'MEMBER', 'ACTIVE', '+41763301126', 'Wiesentalstrasse 2B', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.689Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('3yWOYpv705XTWg64y5BR', 'armend.keqmezi.no-email-55468915@koretini.legacy', 'Armend Keqmezi', 'MEMBER', 'ACTIVE', '+4177 400 62 44', NULL, NULL, NULL, NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.689Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('42v5LNTU4fYJGixxTHEY', 'sead.haxhiu.no-email-54585722@koretini.legacy', 'Sead Haxhiu', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.857Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('48uF1um6vf27U7K7h7uY', 'sali.haxhiu.no-email-54580179@koretini.legacy', 'Sali Haxhiu', 'MEMBER', 'ACTIVE', '+41765153953', 'Sunnebüelstrasse51', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.801Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('4HZb0IRntqM21sdDLnRW', 'jetmir.haxhiu.no-email-54530795@koretini.legacy', 'Jetmir Haxhiu', 'MEMBER', 'ACTIVE', '+41765190084', 'ImBrisgi20', '5400', 'Baden', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.307Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('4b5kMHESudrLVLfSAj8Z', 'islam.berisha@gmail.com', 'Islam Berisha', 'MEMBER', 'ACTIVE', '+41762714894', 'Käserweg 3', '9444', 'Diepoldsau', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:57.952Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('4cxQwWvZbVarhPEPBNSU', 'avdyl.starmans.no-email-54852734@koretini.legacy', 'Avdyl Starmans', 'MEMBER', 'ACTIVE', '+41767581090', 'Gallusstrasse 1', '79618', 'Rheinfelden', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.527Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('4o5UJA4BHaH2ed6OWqcH', 'adem.rexha.no-email-5434960@koretini.legacy', 'Adem Rexha', 'MEMBER', 'ACTIVE', '+491721867149', 'Olgastrasse 7', '71032', 'Böblingen', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.496Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('4zT9ZMsxmYXlAJJlA9fv', 'bislim.lecaj.no-email-55652880@koretini.legacy', 'Bislim Lecaj', 'MEMBER', 'ACTIVE', '+41792679669', 'Wührestrasse 14', '8610', 'Uster', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.528Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('51cgZtxNAIS11JdXa3MH', 'selami.canaj.no-email-5518441@koretini.legacy', 'Selami Canaj', 'MEMBER', 'ACTIVE', '+4176 332 50 88', 'Brisgistrasse 24', '5400', 'Baden', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.844Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('5E167XjBDdfSZIKlw6px', 'shaban.canaj.no-email-55247580@koretini.legacy', 'Shaban Canaj', 'MEMBER', 'ACTIVE', '+4179 230 56 56', 'Rorschacherstrasse 244', '9016', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.475Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('5S6UJNgWgXmXZ8BtlLR7', 'drilon..canaj.no-email-55275265@koretini.legacy', 'Drilon  Canaj', 'MEMBER', 'ACTIVE', '+4178 828 53 31', 'Eichmattstrasse 8', '4665', 'Oftringen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.752Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('5eHrEc5QUwJ0cZFxRYGv', 'besnik.basha.no-email-54980676@koretini.legacy', 'Besnik Basha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.806Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('5w6hsOtD4QgPBJHiE9YT', 'basricanaj@gmx.ch', 'Basri Canaj', 'MEMBER', 'ACTIVE', '+4178 910 23 17', 'Eschenstrasse 19', '79761', 'Waldshut-Tiengen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.961Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('6C95LfLoTDXyj5EyKKVT', 'romana.dervishi@isen-tiefbau.ch', 'Romana Dervishi', 'MEMBER', 'ACTIVE', '+41797192233', 'Steigstrasse 20', '5426', 'Lengnau', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.651Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('6FXySaqFXmYbfi6AIPMG', 'rifat.maka.no-email-55562792@koretini.legacy', 'Rifat Maka', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.627Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('6Fa76JhLPTdm3unl49Yi', 'selim.rexha@gmail.com', 'Selim Rexha', 'MEMBER', 'ACTIVE', '+41447700026', 'Weidgartenstrasse 8', '8909', 'Zwillikon', '1958-09-28', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.985Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('6aB7Z5j7SsHQeyZ0eZ46', 'ilir.canaj.no-email-55163749@koretini.legacy', 'Ilir Canaj', 'MEMBER', 'ACTIVE', NULL, 'Dorfstrasse 18', '6344', 'Meierskappel', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.637Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('7z3UvImOckQUgJ7p7u0w', 'almir.bushi.no-email-55550995@koretini.legacy', 'Almir Bushi', 'MEMBER', 'ACTIVE', NULL, 'Tdoistrasse 6', '8856', 'Tuggen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.509Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('82ZF7YehBm9ifbMQ0Lx0', 'besmir.canaj.no-email-55126139@koretini.legacy', 'Besmir Canaj', 'MEMBER', 'ACTIVE', '+4143 536 39 93', 'Ifangweg 25', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.261Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8Bwc2W5KmXQDO1mjuAUu', 'sefer.haxhiu.no-email-54589911@koretini.legacy', 'Sefer Haxhiu', 'MEMBER', 'ACTIVE', '+41765660017', 'Binzmattstrasse4', '8957', 'Spreitenbach', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.899Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8LrpZ4k0mLI3fZEmNpeM', 'agron.bugaqku.no-email-54722996@koretini.legacy', 'Agron Bugaqku', 'MEMBER', 'ACTIVE', '+491714241274', 'Zum Mittelfeld 22', '57462', 'Olpe, DE', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.229Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8M0vGBwrrg0c73Ummxx9', 'rrahman.klaiqi.no-email-5571949@koretini.legacy', 'Rrahman Klaiqi', 'MEMBER', 'ACTIVE', '+4179 195 25 50', 'Via Giuseppe Maggi 12', '6963', 'Pregassona', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.194Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8PYheyvBtuvlyDmCImhz', 'zeri.ime@bluewin.ch', 'Besim Rexhiqi', 'MEMBER', 'ACTIVE', '+41765061444', 'Ehrenhaustrasse 24', '8105', 'Regensdorf', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.219Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8Qlms8q6DAfvt151VbW0', 'bekim.canaj.no-email-55201023@koretini.legacy', 'Bekim Canaj', 'MEMBER', 'ACTIVE', '+4178 806 04 31', 'Lerchenweg 3', '9014', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.011Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8V1dESaLZ5yYJmcclB0n', 'arif.maka.no-email-55510651@koretini.legacy', 'Arif Maka', 'MEMBER', 'ACTIVE', '+4155 244 56 83 ', 'Heusserstrasse 11', '8634', 'Hombrechtikon', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.106Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8XjP4qPooH6NWT4Yk3Xo', 'florim.haxhiu.no-email-54509714@koretini.legacy', 'Florim Haxhiu', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.097Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8cFwmUVzLg3VraT34mg7', 'sabedin.kovani.no-email-55773073@koretini.legacy', 'Sabedin Kovani', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.730Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8eUXaZARc8Zkg9YEMWEm', 'd.rexha@bluewin.ch', 'Driton Rexha', 'MEMBER', 'ACTIVE', '+41791743689', 'Ifangstrasse 18', '8153', 'Rümlang', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.687Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8kPpeuV9whAAHYphj91r', 'rinor.maliqi.no-email-55851659@koretini.legacy', 'Rinor Maliqi', 'MEMBER', 'ACTIVE', '+4176 703 47 17', 'Seenerstrasse 184', '8405', 'Winterthur', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.516Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('8u7nUlzjqwDjfJZv6Llb', 'muhamet.haxhiu.no-email-54561643@koretini.legacy', 'Muhamet Haxhiu', 'MEMBER', 'ACTIVE', '+4915208145277', NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.616Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('9663gXA0EWQk37CP0h5e', 'januzi-@hotmail.com', 'Januz Haxhiu', 'MEMBER', 'ACTIVE', '+41786063135', 'ImFeldtal1', '8408', 'Winterthur', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.245Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('9AukwVBpII7WdplD7NG2', 'ardit.haxhiu.no-email-54656043@koretini.legacy', 'Ardit Haxhiu', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.560Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('9WuOUKaRhFreosgTCNcl', 'rinor.canaj.no-email-55284018@koretini.legacy', 'Rinor Canaj', 'MEMBER', 'ACTIVE', NULL, 'Moosaeckerstrasse 12', '5442', 'Fislisbach', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.840Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('9yDh1R5nJIsRiKayTdWh', 'fadil.canaj.no-email-55155312@koretini.legacy', 'Fadil Canaj', 'MEMBER', 'ACTIVE', '+4176 584 12 65', 'Dorfstrasse 18', '6344', 'Meierskappel', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.553Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('9yYLk8J8cuuN0BVJbr6J', 'naim.canaj.no-email-55233996@koretini.legacy', 'Naim Canaj', 'MEMBER', 'ACTIVE', '+4161 761 60 94', 'Brugmattweg 19', '4242', 'Laufen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.339Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('AfDriDW5TAB7uHCxxs14', 'jeton.klaiqi.no-email-55711714@koretini.legacy', 'Jeton Klaiqi', 'MEMBER', 'ACTIVE', '+4179 305 06 85', 'Bachmatt 6', '5630', 'Muri', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.117Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('AhQWaLqTMSC0DoTQuPbo', 'perparim.canaj.no-email-55175967@koretini.legacy', 'Perparim Canaj', 'MEMBER', 'ACTIVE', '+4179 291 85 09', 'Zehntenstrasse 116', '4133', 'Pratteln', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.759Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Al25LEEha1gT4FIsYJRJ', 'a.jusufi@ha-tech.ch', 'Agron Jusufi', 'MEMBER', 'ACTIVE', '+4179 373 36 61', 'Goldbühlstrasse 11', '8620', 'Wetzikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.069Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('BF96GzVIjRxVLx6PCL9R', 'astrit..berisha.no-email-55832634@koretini.legacy', 'Astrit  Berisha', 'MEMBER', 'ACTIVE', NULL, 'Albert-Schweitzerstr. 19D', '54329', 'Konz', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.326Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('BQgNeAb2C3OgL6wMFFnR', 'shpend.basha.no-email-5501687@koretini.legacy', 'Shpend Basha', 'MEMBER', 'ACTIVE', NULL, 'Stettiner Str. 44', '72116', 'Moessingen', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:50.168Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Bey4HIPbdn5UrEjMNIwa', 'ramiz..canaj.no-email-55189152@koretini.legacy', 'Ramiz  Canaj', 'MEMBER', 'ACTIVE', '+4178 806 04 31', 'Lerchenweg 3', '9014', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.891Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Buz0rVrzGNqWQNYvlw9X', 'kushtrim.demi.no-email-55840024@koretini.legacy', 'Kushtrim Demi', 'MEMBER', 'ACTIVE', '+4179 127 97 35', 'Südstrasse 13', '4665', 'Oftringen', NULL, 'wQV3M5IQiReJPGyR0gqN', 'koretini', '2026-01-31T11:05:58.400Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('CdyLM5kDFSoFV2CeO4G3', 'alban.rexha@gmx.ch', 'Alban Rexha', 'MEMBER', 'ACTIVE', '+41762028990', 'Weinberg 2', '5634', 'Merenschwand', '1989-11-13', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.602Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Ci3zzEDZvOdF9QXMrBib', 'ylli..dervishi.no-email-54899169@koretini.legacy', 'Ylli  Dervishi', 'MEMBER', 'ACTIVE', '+41795550697', 'Stampfenbrunnenstrasse 8', '8048', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.991Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Cos5YeyGnLfnWAj2kNd8', 'hevzi.haxhiu.no-email-54513918@koretini.legacy', 'Hevzi Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'Rütiwisstrasse2', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.139Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('D0UIg4bJLMRuXMzeo556', 'valdet.selmani@hotmail.com', 'Valdet Selmani', 'MEMBER', 'ACTIVE', '+41767606172', 'Jonentalstrasse 19', '8910', 'Affoltern am Albis', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.983Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('D7GyjnfLe7gwUEInO4Ry', 'rahim..isufi.no-email-55328719@koretini.legacy', 'Rahim  Isufi', 'MEMBER', 'ACTIVE', '+4176 260 35 32', 'Alte Bettswilerstr. 14', '8344', 'Bäretswil', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.287Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DBsM9FjPdmhQDiouWaD6', 'bashkim.basha.no-email-55006955@koretini.legacy', 'Bashkim Basha', 'MEMBER', 'ACTIVE', NULL, 'Schmitterstrasse 56', '9444', 'Diepoldsau', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:50.069Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DNVIhzRIBnom4WBufd9M', 'faik.axhija.no-email-54626241@koretini.legacy', 'Faik Axhija', 'MEMBER', 'ACTIVE', '+41767133550', 'Rosenstrasse4C', '9430', 'Margrethen', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.262Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DajkkpvkzCNYNYZdviBi', 'besir.canaj.no-email-55118175@koretini.legacy', 'Besir Canaj', 'MEMBER', 'ACTIVE', '+4176 495 44 78', 'Sunnebüelstrasse 19', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.181Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DeBRcyNc17lT3M8F7uQK', 'berat_haxhiu@hotmail.com', 'Berat Haxhiu', 'MEMBER', 'ACTIVE', '+41796778377', 'Klingentakstrasse45', '4057', 'Basel', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.738Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DkZAxHAsZYOATAAxafZC', 'bastri.canaj.no-email-55171948@koretini.legacy', 'Bastri Canaj', 'MEMBER', 'ACTIVE', '+4178 928 90 04', 'Watterstrasse 159', '8105', 'Regensdorf', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.719Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('DxHXWuU6C0XwgoFTAkqn', 'vedat.canaj.no-email-55217240@koretini.legacy', 'Vedat Canaj', 'MEMBER', 'ACTIVE', '+4141 790 47 49', 'Luzernerstrasse 11', '6343', 'Rotkreuz', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.172Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('E3gjfIRq45nTkRhrYHoo', 'bekim.shabani.no-email-54839144@koretini.legacy', 'Bekim Shabani', 'MEMBER', 'ACTIVE', '+41779667034', NULL, NULL, NULL, NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.391Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ET5yJX7gjqUcOgl3omVV', 'selmonilidim@gmail.com', 'Lidim Selmoni', 'MEMBER', 'ACTIVE', '+41763937272', 'Ackerstrasse 21', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.727Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('EkVDBv0JQjrrBbwG9VzP', 'burim..kovani.no-email-55777769@koretini.legacy', 'Burim  Kovani', 'MEMBER', 'ACTIVE', NULL, 'Stanserstrasse 1', '6373', 'Ennetbürgen', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.777Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Em9ZXasYPob39dFjtIcZ', 'kadria66@hotmail.com', 'Kadri Canaj', 'MEMBER', 'ACTIVE', '+4178 859 21 19', 'Tiefenhofstrasse 64', '8820', 'Wädenswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.675Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('EmGI4k0TWgt9e3oMhHAg', 'fazli.rexha.no-email-54377743@koretini.legacy', 'Fazli Rexha', 'MEMBER', 'ACTIVE', NULL, 'Olgastrasse 7', '71032', 'Böblingen', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.777Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('EmnWwWQFxPqU79HJikBN', 'avni.kovani.no-email-55737685@koretini.legacy', 'Avni Kovani', 'MEMBER', 'ACTIVE', NULL, 'Brisgistrasse 22', '5400', 'Baden', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.376Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Ezv32TUnQkZwAXRxApoC', 'sadik.selmani@isen-tiefbau.ch', 'Sadik Selmani', 'MEMBER', 'ACTIVE', '+41792096773', 'Lättenstrasse 4', '8952', 'Schlieren', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.189Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('F9aiJKT5Tv9tgkgXepbt', 'sami.maka.no-email-55554541@koretini.legacy', 'Sami Maka', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.545Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('FH57gJ0zBbysqGKJhEmt', 'mentor.canaj.no-email-55256560@koretini.legacy', 'Mentor Canaj', 'MEMBER', 'ACTIVE', '+4179 230 56 56', 'Rorschacherstrasse 244', '9016', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.565Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('FV9px0kYYFH3PRUOMXqM', 'arlind.ramadani.no-email-55416559@koretini.legacy', 'Arlind Ramadani', 'MEMBER', 'ACTIVE', NULL, 'Kreuzstrasse 6', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.165Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('FfknNzhDjFPVdibRurUJUnRWwAv1', 'kastriot.klaiqi1994@gmail.com', 'Kastriot Klaiqi', 'MEMBER', 'PENDING', '+41794675080', 'Schaffhauserstr 151', '8302', 'Kloten', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-02-02T08:27:08.780Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('FtcZaPSphSgueipvsc0N', 'jeton.canaj.no-email-55251311@koretini.legacy', 'Jeton Canaj', 'MEMBER', 'ACTIVE', '+4179 230 56 56', 'Rorschacherstrasse 244', '9016', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.513Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('GPE0pbHU63sy9JxSv6KX', 'fidan.ramadani.no-email-55423036@koretini.legacy', 'Fidan Ramadani', 'MEMBER', 'ACTIVE', NULL, 'Kreuzstrasse 6', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.230Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('GWThXpt70WV9OjPE2dBW', 'm.haxhiu73@outlook.com', 'Musafer Haxhiu', 'MEMBER', 'ACTIVE', '+41765733748', 'Talweg4', '8610', 'Uster', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.517Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('GhagEi29IvsRrZ0QKAEu', 'adrian.maka.no-email-55520748@koretini.legacy', 'Adrian Maka', 'MEMBER', 'ACTIVE', '+4178 906 79 68', 'Bächeli 6', '3662', 'Seftigen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.207Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Gj9ZzlWhmFUAr88G1b6o', 'besim.keqmezi.no-email-55477333@koretini.legacy', 'Besim Keqmezi', 'MEMBER', 'ACTIVE', '+4176 427 27 90', 'Langäckerstrasse 1', '8957', 'Spreitenbach', NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.773Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('GjfXekIjRbaByyXZ0SCp', 'xhelal.leci.no-email-55657377@koretini.legacy', 'Xhelal Leci', 'MEMBER', 'ACTIVE', '+41793053389', 'umgezogen', '8106', 'Regensdorf', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.573Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('GqqvPyog61G8jcCi6qbT', 'remzi.pireva.no-email-55575627@koretini.legacy', 'Remzi Pireva', 'MEMBER', 'ACTIVE', NULL, 'Bubentalstrasse 7', '8304', 'Wallisellen', NULL, 'NMx47Gf7MOqKG7SHurqq', 'koretini', '2026-01-31T11:05:55.756Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('H0O1jkaV7Y42DfZJ4jT9', 'ariani_083@hotmail.com', 'Arian Maka', 'MEMBER', 'ACTIVE', '+4176 585 69 25', 'Dreikönigstrasse 14', '8180', 'Bülach', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.061Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('HSY5aiZkp975uAnIS8bU', 'rizah.shaqiri.no-email-54434817@koretini.legacy', 'Rizah Shaqiri', 'MEMBER', 'ACTIVE', '+4915253937630', 'Salvador Alleenstrasse 10', '39126', 'Magdeburg', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.348Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('HVcxGA5QUB40Hulq1LUM', 'ejup.vrapcani.no-email-55616243@koretini.legacy', 'Ejup Vrapcani', 'MEMBER', 'ACTIVE', NULL, 'Unterwegli 51', '8404', 'Winterthur', NULL, 'qR9T0s2sdVBwYQmVi20d', 'koretini', '2026-01-31T11:05:56.162Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('He9KHDlUYbSySPekGFJg', 'liridon..canaj.no-email-55265687@koretini.legacy', 'Liridon  Canaj', 'MEMBER', 'ACTIVE', '+41765275305', 'Via Stazione 15', '6593', 'Cadenazzo', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.656Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('HpffhxjQnzWd6JN5p7hA', 'sadulla.kovani.no-email-55765129@koretini.legacy', 'Sadulla Kovani', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.651Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('HwHbZEkIKLupFqJzPUNe', 'lindrim.nuhiu.no-email-55464780@koretini.legacy', 'Lindrim Nuhiu', 'MEMBER', 'ACTIVE', '+4179 133 94 74', 'Schlösslistrasse 26', '8964', 'Rudolfstetten', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.647Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('I4sSQqnkGoXV7rkyL9LO', 'besart.isufi.no-email-55345354@koretini.legacy', 'Besart Isufi', 'MEMBER', 'ACTIVE', '+4176 416 33 97', 'Alte Bettswilerstr. 14', '8344', 'Bäretswil', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.453Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('I8wrqkzTQWgAJmPZ4sPc', 'milot_haxhija@outlook.de', 'Milot Haxhija', 'MEMBER', 'ACTIVE', '+4917686638234', 'AmGraspoint52', '83026', 'Rosenheim', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.345Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IEPGEYkbr3m8hnPE6DnJ', 'astrit.hoda.no-email-55497961@koretini.legacy', 'Astrit Hoda', 'MEMBER', 'ACTIVE', NULL, 'Weissensteinstrasse 3', '2540', 'Grenchen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:54.979Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IExmKTnTcwOHOCfqh35vFD1MMJ03', 'email@trifti.ch', 'FIlan Dest', 'MEMBER', 'PENDING', '56789', 'Ehrenhaustrasse 24', '8105', 'Watt', NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-02-01T08:12:41.694Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IKOrUtLEi7GTTmhOjO8v', 'fetah.ibushi.no-email-55542362@koretini.legacy', 'Fetah Ibushi', 'MEMBER', 'ACTIVE', NULL, 'Nordstrasse 1', '4665', 'Oftringen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.423Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('INNNUaqTMpdvTn0t7P7Y', 'fazli.matoshi.no-email-55088360@koretini.legacy', 'Fazli Matoshi', 'MEMBER', 'ACTIVE', NULL, 'Farbstrasse 5', '8620', 'Wetzikon', NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-01-31T11:05:50.883Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IZK9kqVHJ0K4h5rACeFm', 'memet.canaj.no-email-55204979@koretini.legacy', 'Memet Canaj', 'MEMBER', 'ACTIVE', '+4179 957 54 95', 'Schwarzackerstrasse 53', '4303', 'Kaiseraugst', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.049Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IaVPNs3TVACwEAvNbnFj', 'armer.bugaqku.no-email-54693485@koretini.legacy', 'Armer Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'Liebrütistrasse 23', '4303', 'Kaiseraugst', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.934Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ImrR7ngwv3Of6NTvjN3P', 'shefki.basha.no-email-5500269@koretini.legacy', 'Shefki Basha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:50.026Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IpWg8ndsxT64Y9bEsg9r', 'sadat.canaj.no-email-55221774@koretini.legacy', 'Sadat Canaj', 'MEMBER', 'ACTIVE', '+4141 790 21 26', 'Berchtwilerstrasse 7', '6343', 'Rotkreuz', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.217Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IsCL3vTQeXTSRMyuwWva', 'perparim.haxhiu.no-email-54565926@koretini.legacy', 'Perparim Haxhiu', 'MEMBER', 'ACTIVE', '+41763940584', 'Zelglistrasse17', '8620', 'Wetzikon', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.659Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Ix564uPpVheeTgX6iQsP', 'nexhbedin.thaqi.no-email-55043883@koretini.legacy', 'Nexhbedin Thaqi', 'MEMBER', 'ACTIVE', NULL, 'Feldstrasse 18', '8952', 'Schlieren', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.438Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('IzziI1TFNxohutfElKYK', 'valton.rexha@gmail.com', 'Valton Rexha', 'ADMIN', 'ACTIVE', '+41791382816', 'Weidgartenstrasse 8', '8909', 'Zwillikon', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.028Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('JJao5VpVhUUHfgigDhla', 'ragip.pireva.no-email-55571413@koretini.legacy', 'Ragip Pireva', 'MEMBER', 'ACTIVE', NULL, 'Bubentalstrasse 7', '8304', 'Wallisellen', NULL, 'NMx47Gf7MOqKG7SHurqq', 'koretini', '2026-01-31T11:05:55.714Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('JJlUD5j3f8BrVx9FMa72', 'besim.basha.no-email-54972340@koretini.legacy', 'Besim Basha', 'MEMBER', 'ACTIVE', NULL, 'Balgacherstrasse 226', '9435', 'Heerbrugg', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.723Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('JQRxKs9EH2q7UsTbv2wG', 'ahmethaki.shabani.no-email-54642471@koretini.legacy', 'AhmetHaki Shabani', 'MEMBER', 'ACTIVE', NULL, 'Hilgerskamp4', '30880', 'laatzen', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.424Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('JSFKa8lyfMjFBGDhIeCr', 'alban.maka.no-email-55528856@koretini.legacy', 'Alban Maka', 'MEMBER', 'ACTIVE', '+4179 667 86 70', 'Sunnebühlstrasse 23', '8604', 'Volketswil', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.288Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('JgBNtkKinN1fCIm0oVmg', 'januz.vrapcani.no-email-55621286@koretini.legacy', 'Januz Vrapcani', 'MEMBER', 'ACTIVE', NULL, 'Rosenbrugstrasse 12', '8630', 'Rüti', NULL, 'qR9T0s2sdVBwYQmVi20d', 'koretini', '2026-01-31T11:05:56.212Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('K3ZlGmzELbt7C0u67iV4', 'nuhirexha25@gmail.com', 'Nuhi Rexha', 'MEMBER', 'ACTIVE', '+41766383222', 'Langwiesenstrasse 7', '8108', 'Dàllikon', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.445Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('KeuRSVn5ssZLK4VWS56s', 'mentor.haxhiu@klinikum-bayreuth.de', 'Mentor Haxhiu', 'MEMBER', 'ACTIVE', '+491704375696', 'Lärchenweg1', '95445', 'Bayreuth', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.475Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Kt9OQ4Py6ti8zbrIiXRZ', 'visar.thaqi.no-email-55061316@koretini.legacy', 'Visar Thaqi', 'MEMBER', 'ACTIVE', NULL, 'Winterhollerweg 34', '83071', 'Rosenheim', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.613Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('L1f5N3rrL1Ft9gNjTt3X', 'leurim.selmoni.no-email-54777039@koretini.legacy', 'Leurim Selmoni', 'MEMBER', 'ACTIVE', '+41765441054', 'Südweg 6', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.770Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('L3sCd5TdYp76T5YqGAfb', 'idriz.isufi.no-email-55367256@koretini.legacy', 'Idriz Isufi', 'MEMBER', 'ACTIVE', '+4179 214 50 96', 'Obstgartenstrasse 63', '8105', 'Regensdorf', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.672Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('LJTz8CckCp0ftymtBXsB', 'ilir.ker.eli.no-email-55594931@koretini.legacy', 'Ilir Kerçeli', 'MEMBER', 'ACTIVE', NULL, 'Glanzenbergstrasse 28', '8953', 'Dietikon', NULL, 'RMsYofQDTV9zBjVwVQF4', 'koretini', '2026-01-31T11:05:55.949Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('M7VUmf3sFt8HcGctkjI5', 'naser.l@hotmai.com', 'Naser  Lecaj', 'MEMBER', 'ACTIVE', '+41763696267', 'Schulergasse 4', '8406', 'Winterthur', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.434Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('M9vBO93R5u3KTREM6a3J', 'artrit.keqmezi.no-email-55473377@koretini.legacy', 'Artrit Keqmezi', 'MEMBER', 'ACTIVE', NULL, 'Auguste-Quiguerez. 89', '2800', 'Delemont', NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.733Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('McCZ05EwadK9FflCpTvX', 'durim.kurteshi.no-email-54651320@koretini.legacy', 'Durim Kurteshi', 'MEMBER', 'ACTIVE', NULL, 'Eisenburgstrasse1', '8854', 'Siebnen', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.513Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('MfQA1gr4fHd9PgUiBWEh', 'amir@kerqeli.com', 'Amir Kerçeli', 'MEMBER', 'ACTIVE', '+4176 222 11 10', 'Karl - Heid- Strasse 4', '8953', 'Dietikon', NULL, 'RMsYofQDTV9zBjVwVQF4', 'koretini', '2026-01-31T11:05:55.805Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('MlPrZdR1kyFUd4nzNc9g', 'fadil.haxhiu.no-email-54491545@koretini.legacy', 'Fadil Haxhiu', 'MEMBER', 'ACTIVE', '+436763479506', 'Sauserstrasse7/3/10', '4600', 'Wels', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.915Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('MtyvvSUgUKBWAnZBlbg8', 'bekim.basha.no-email-54976546@koretini.legacy', 'Bekim Basha', 'MEMBER', 'ACTIVE', NULL, 'Grazerstrasse 25', '8670', 'A-Krieglach', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.765Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('MvjLtVaVngwvkAG7cflH', 'urim.haxhiu.no-email-54608359@koretini.legacy', 'Urim Haxhiu', 'MEMBER', 'ACTIVE', '+41764118054', 'Zelglistrasse17', '8620', 'Wetzikon', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.083Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('MwNjfg7aBJO1psLMTBPN', 'dervishi.dibran@bluewin.ch', 'Dibran Dervishi', 'MEMBER', 'ACTIVE', '+41764895277', 'Pilatusstrasse 4', '5610', 'Wohlen', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.730Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('NR9lQzRMwQ3KOeJIePhv', 'lulzim.haxhiu.no-email-54536271@koretini.legacy', 'Lulzim Haxhiu', 'MEMBER', 'ACTIVE', '+491634275692', 'Römerhag22', '86899', 'LandsbergamLech', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.363Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('NVkCW6LCZD7rLfOSSCqm', 'jeton_matoshi@hotmail.com', 'Jeton Matoshi', 'MEMBER', 'ACTIVE', '+4176 309 84 10', 'Aufwiesenstrasse 25', '8305', 'Dietlikon', NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-01-31T11:05:50.699Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('NrfMYLxpQEilURz9TcyH', 'feta.bugaqku.no-email-5468096@koretini.legacy', 'Feta Bugaqku', 'MEMBER', 'ACTIVE', '+41788784112', 'Alte Landstrasse 41', '8810', 'Horgen', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.809Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('OCDmO5OiIb4ZUacvrYER', 'rifat.nuhija.no-email-55429335@koretini.legacy', 'Rifat Nuhija', 'MEMBER', 'ACTIVE', NULL, 'Fischerweg 4', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.293Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('OD5NdSuhFKe7UXPwhT0L', 'ledion@dervishi.ch', 'Ledion Dervishi', 'MEMBER', 'ACTIVE', '0782425090', 'Spitzwiesenstrasse,1', '8957', 'Spreitenbach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T18:22:51.885Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('OJ8aVTDvEP9Av2wteNTT', 'naser.bushi.no-email-5550219@koretini.legacy', 'Naser Bushi', 'MEMBER', 'ACTIVE', '+4176 585 69 25', 'Zelgwasserweg 11', '4460', 'Gelterkinden', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.021Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ONPf3kfHE9hxOs2QAEHUx1T1I733', 'email@dervishi.ch', 'Burim Dervishi', 'SUPER_ADMIN', 'ACTIVE', '+41786314062', 'Spitzwiesenstrasse 1', '8957', 'Spreitenbach', '1982-08-15', 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-02-16T13:59:52.763Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('OSiobnhSHtpWmEM49JA9', 'hamdi.isufi.no-email-55362434@koretini.legacy', 'Hamdi Isufi', 'MEMBER', 'ACTIVE', '+4176 432 34 92', 'Alte Bettswilerstr. 14', '8344', 'Bäretswil', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.624Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('OSlO5H4aYsnXxgkBFYUA', 'flamur.canaj.no-email-55196312@koretini.legacy', 'Flamur Canaj', 'MEMBER', 'ACTIVE', '+4178 806 04 31', 'Lerchenweg 3', '9014', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.963Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('PSvXjLcBxPwoZb4LL7gl', 'valmir.canaj.no-email-55158775@koretini.legacy', 'Valmir Canaj', 'MEMBER', 'ACTIVE', NULL, 'Dorfstrasse 18', '6344', 'Meierskappel', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.587Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('PW9RUVpr14ZQmgEu6INR', 'remzije.selmani.no-email-54814823@koretini.legacy', 'Remzije Selmani', 'MEMBER', 'ACTIVE', NULL, 'Kraftwerkstrasse 24', '4313', 'Möhlin', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.148Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('PecWBJQOnqOgNEzPKvWM', 'hasan.maliqi.no-email-55860478@koretini.legacy', 'Hasan Maliqi', 'MEMBER', 'ACTIVE', NULL, 'Wilikonerstrasse 32', '8618', 'Oetwil am See', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.604Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('PvThVwS5emuTfOBZmTES', 'tahir.maka.no-email-55524753@koretini.legacy', 'Tahir Maka', 'MEMBER', 'ACTIVE', NULL, 'Fuchgasse 16', '9443', 'Widnau SG', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.247Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('QEESN8Jn70gYWKprtIRI', 'blerim.basha.no-email-55021458@koretini.legacy', 'Blerim Basha', 'MEMBER', 'ACTIVE', NULL, 'Schaffhauserstrasse 565', '8052', 'Zürich', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:50.214Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('QcLqwvbRhxfbY8bVpQTa', 'emin.ker.eli.no-email-55590432@koretini.legacy', 'Emin Kerçeli', 'MEMBER', 'ACTIVE', NULL, 'Milchrütistrasse 35', '8304', 'Wallisellen', NULL, 'RMsYofQDTV9zBjVwVQF4', 'koretini', '2026-01-31T11:05:55.904Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Qs7PFWQaZeb4tcm60hqS', 'bekim.rexhiqi.no-email-54418169@koretini.legacy', 'Bekim Rexhiqi', 'MEMBER', 'ACTIVE', '+497317188837', 'Jahnstrasse 6', '89233', 'Neu Ulm', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.181Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('QzCEWq8cIqjYRDT17eph', 'hazbije.maka.no-email-55558418@koretini.legacy', 'Hazbije Maka', 'MEMBER', 'ACTIVE', NULL, 'Klosterfeldstrasse 18', '5630', 'Muri AG', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.584Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('R0FxDqP3Mz2AilTW0YSK', 'lelibaugmbh@hotmail.com', 'Luan Isufi', 'MEMBER', 'ACTIVE', '+4176 543 34 92', 'Mühlestrasse 16', '8344', 'Bäretswil', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.561Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('R9tUIryGuAECry15lGLy', 'denis.berisha.no-email-55819587@koretini.legacy', 'Denis Berisha', 'MEMBER', 'ACTIVE', NULL, 'Hargartenstrasse 10', '8185', 'Winkel', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.195Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('RB9D4MHqhXuWgckxAETw', 'asllan.haxhiu@gmx.ch', 'Asllan Haxhiu', 'MEMBER', 'ACTIVE', '+41764050017', 'Triemlistrasse136', '8047', 'Zürich', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.650Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('RBrmE8kSVarXcTAV418n', 'lorik.selmani.no-email-54834375@koretini.legacy', 'Lorik Selmani', 'MEMBER', 'ACTIVE', '+41795555305', 'Feldstrasse 18', '8952', 'Schlieren', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.343Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Re6x5Yo2wqbPs60i3acB', 'nehat.bugaqku.no-email-5471935@koretini.legacy', 'Nehat Bugaqku', 'MEMBER', 'ACTIVE', '+491714241274', 'Zum Mittelfeld 22', '57462', 'Olpe, DE', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.193Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Rg9wjHdvfYsts3ALmjTq', 'hysen.cakolli.no-email-54639179@koretini.legacy', 'Hysen Cakolli', 'MEMBER', 'ACTIVE', NULL, 'Föhrenstr.3', '9320', 'Arbon', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.391Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('RwFsXYFa4LlLXSs6TgIP', 'bejtulla.haxhiu.no-email-54469412@koretini.legacy', 'Bejtulla Haxhiu', 'MEMBER', 'ACTIVE', '+41767023835', 'Ifangstrasse41b', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.694Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('S1tc04HcrJPhFPpPm1oX', 'habib.rexha@hotmail.com', 'Habib Rexha', 'MEMBER', 'ACTIVE', '+436644643998', 'Friedhofstrasse 60', '4600', 'Wels', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.827Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('S9g8mwSAVsBd75I8rXPB', 'ahmetkosumi@hotmail.com', 'Ahmet Kosumi', 'MEMBER', 'ACTIVE', '+4179 242 31 07', 'Marktstrasse 1', '2540', 'Grenchen', NULL, 'gg0GE0qz4ZMf35cRtesp', 'koretini', '2026-01-31T11:05:56.347Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SLBLQkcMRIrfTnvHTx4S', 'mentor.bugaqku.no-email-54697885@koretini.legacy', 'Mentor Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'Rosenweg 8', '4303', 'Kaiseraugst', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.978Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SMr1gqJIllgETPHCZNK8', 'ramadan.basha.no-email-54942373@koretini.legacy', 'Ramadan Basha', 'MEMBER', 'ACTIVE', '+41615353766', 'Frobenstrasse 57', '4053', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.423Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('STfbHlW0F4Qc6z2PfWeq', 'afrim_rexhiqi@hotmail.com', 'Afrim  Rexhiqi', 'MEMBER', 'ACTIVE', '+41762262503', 'Obere Bahnhofstrasse 17', '8910', 'Affoltern a.A', '1966-06-28', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.553Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SUJQQHdVzN9TpKBfahtX', 'naim.selmani.no-email-54807386@koretini.legacy', 'Naim Selmani', 'MEMBER', 'ACTIVE', '+41791700115', 'Ahornstrasse 3', '4313', 'Möhlin', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.073Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SXhUYmht8hWyEVljQgVu', 'irfan.bugaqku.no-email-54739772@koretini.legacy', 'Irfan Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'Chemin des Planches 3', '1008', 'Prilly', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.397Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SYW0nRBhtusknVuiBCC5', 'vesel.berisha.no-email-55803225@koretini.legacy', 'Vesel Berisha', 'MEMBER', 'ACTIVE', NULL, 'Ignazgasse 19/7', '1120', 'Wien', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.032Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SvmLML71g9Vv8BQlrCyr', 'kastriot.klaiqi.no-email-5573197@koretini.legacy', 'Kastriot Klaiqi', 'MEMBER', 'ACTIVE', NULL, 'Bachfeldstrasse 15', '9403', 'Goldach', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.319Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('SzP7qibmajk0B3opdFw9', 'elita.canaj.no-email-55288361@koretini.legacy', 'Elita Canaj', 'MEMBER', 'ACTIVE', NULL, 'Bruggmattweg 19', '4242', 'Laufen BL', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.883Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('T5F7oUOHiZ7Pw253hHrC', 'arsim.hasani.no-email-55398946@koretini.legacy', 'Arsim Hasani', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.989Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('T9x7H684rNFe1jVAq0qu', 'adrian.dervishi@isen-tiefbau.ch', 'Adrian Dervishi', 'MEMBER', 'ACTIVE', '+41799035733', 'Mülibachstrasse 54', '8107', 'Buchs', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.571Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TDxwEOzt6nEcRJzUmjA2', 'samir.canaj.no-email-55192588@koretini.legacy', 'Samir Canaj', 'MEMBER', 'ACTIVE', '+4178 806 04 31', 'Lerchenweg 3', '9014', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.925Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TUCzJRerBxIz0RTMwOpA', 'enis.berisha.no-email-55787178@koretini.legacy', 'Enis Berisha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:57.871Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TVgGO6sYWKJ1Q8uhO4WA', 'besnik..selmoni.no-email-54780645@koretini.legacy', 'Besnik  Selmoni', 'MEMBER', 'ACTIVE', '+41765251005', 'Im Holzerhurd 43', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.806Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TcuZgeqnmScuIgY65v9R', 'besnik..keqmezi.no-email-55485693@koretini.legacy', 'Besnik  Keqmezi', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.856Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TxpiVYmYGuZiwCekIJ9Y', 'landrrit..sula.no-email-55047855@koretini.legacy', 'Landrrit  Sula', 'MEMBER', 'ACTIVE', NULL, 'Ahornweg 24', '8630', 'Rüti', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.478Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('TzSd8IkvjcZEdTot5ltK', 'arsim.basha.no-email-54984989@koretini.legacy', 'Arsim Basha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.849Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('UBMpvy6wOX0ZvISCuWky', 'bahri.nuhiji.no-email-55444896@koretini.legacy', 'Bahri Nuhiji', 'MEMBER', 'ACTIVE', NULL, 'Bremgartnerstrasse 32', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.448Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('UBn9fR6uWhSw7NpH4Ufv', 'gana_pepi@hotmail.com', 'Perparim Haxhiu', 'MEMBER', 'ACTIVE', '+415712659594', NULL, NULL, 'USA', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.699Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('UKtD0bbMnd3SRXIhclzk', 'sevdai.neziri.no-email-55685553@koretini.legacy', 'Sevdai Neziri', 'MEMBER', 'ACTIVE', NULL, 'Schaffhauserstrasse 2a', '8213', 'Neunkirch', NULL, '8KGIaCmhzCimjPGxWRnJ', 'koretini', '2026-01-31T11:05:56.855Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('UsgJPXQLrYcIBfdy4K5x', 'fejzullah.berisha.no-email-55810195@koretini.legacy', 'Fejzullah Berisha', 'MEMBER', 'ACTIVE', NULL, 'Karolingerweg 7', '69123', 'Heidelberg', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.101Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('V8eKk0xypOOnwKhvmlZG', 'haxhiu-shaban@hotmail.com', 'Shaban Haxhiu', 'MEMBER', 'ACTIVE', '+41793578938', 'Verenastrasse35', '8832', 'Wollerau', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.989Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VCVIUbz3ujd0MxYXHqpk', 'sabri..isufi.no-email-55384855@koretini.legacy', 'Sabri  Isufi', 'MEMBER', 'ACTIVE', '+4176 317 24 63', 'Schöneggstrasse 149', '8953', 'Dietikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.848Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VHJwtc1xigPY7kiAVmVH', 'merita.thaqi.kelmendi.no-email-55065118@koretini.legacy', 'Merita Thaqi/Kelmendi', 'MEMBER', 'ACTIVE', NULL, 'Feldstrasse 18', '8952', 'Schlieren', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.651Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VOVXinWYpiNCNUR845Eb', 'bastri.basha.no-email-54963674@koretini.legacy', 'Bastri Basha', 'MEMBER', 'ACTIVE', NULL, 'Achilles-Bischoffstrasse 2', '4053', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.636Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VZBoXmIJ51OB7s4FqVsh', 'haxhiujeton1@gmail.com', 'Jeton Axhija', 'MEMBER', 'ACTIVE', NULL, 'Römerhang24', '86899', 'LandsbergamLech', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.215Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VbI1JraPZMj5lWU60Jgr', 'arbnor.maka.no-email-55567345@koretini.legacy', 'Arbnor Maka', 'MEMBER', 'ACTIVE', NULL, 'Route de la Plaine 5', '1022', 'Chavannes-près-Renens', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.673Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VcoivfRBX1kh5Pb3BybJ', 'deli.lecaj.no-email-55671129@koretini.legacy', 'Deli Lecaj', 'MEMBER', 'ACTIVE', '+41763376283', 'Wasserwerkstrasse 134', '8037', 'Zürich', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.711Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VlqQjajlzaX3WniMnTLh', 'rexhep.pfenninger.no-email-55040242@koretini.legacy', 'Rexhep Pfenninger', 'MEMBER', 'ACTIVE', NULL, 'Steigstrasse 14', '8610', 'Uster', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.402Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('VpTdJzeSlQ0MoecgfieY', 'berat.canaj.no-email-55113922@koretini.legacy', 'Berat Canaj', 'MEMBER', 'ACTIVE', '+4176 700 91 29', 'Sunnebüelstrasse 19', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.139Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('WJELCXeL6hw7tjG0kJFr', 'xhezide.selmani.no-email-54904738@koretini.legacy', 'Xhezide Selmani', 'MEMBER', 'ACTIVE', NULL, 'Lättenstrasse 4', '8952', 'Schlieren', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:49.047Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('WTZNaEzcIy9F5K3t8bgo', 'remzi.haxhiu.no-email-54575876@koretini.legacy', 'Remzi Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'Ifangstrasse41', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.758Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('WaLVaVyWJamWLir1Wxcj', 'genc.kovani.no-email-55769016@koretini.legacy', 'Genc Kovani', 'MEMBER', 'ACTIVE', NULL, 'Haebelbachstrasse 33', '3027', 'Bern', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.690Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('WmuWNgt09dCvVqPUB43f', 'gazmend.mehmeti@multinetcom.ch', 'Gazmend Mehmeti', 'BOARD', 'ACTIVE', '+41765865656', 'Herbstweg 100', '8050', 'Zürich', '1966-11-25', 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.723Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('X0r7nhiu9mRtCYVIK1Oa', 'florim.dervishi.no-email-54881253@koretini.legacy', 'Florim Dervishi', 'MEMBER', 'ACTIVE', NULL, 'Via san gottardo 114', '6500', 'Bellinzona', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.812Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('X64uwaxbbcRxO5iy3zfY', 'gani..isufi.no-email-55349883@koretini.legacy', 'Gani  Isufi', 'MEMBER', 'ACTIVE', '+4176 602 61 94', 'Mühlestrasse 16', '8344', 'Bäretswil', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.498Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('X766pg56mh12wTY3nz9P', 'isuf.berisha.no-email-55815160@koretini.legacy', 'Isuf Berisha', 'MEMBER', 'ACTIVE', NULL, 'Gelbhofstrasse 24', '81375', 'München', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.151Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('XHmkQS1qxTYrWbodABIT', 'naser.basha.no-email-54998099@koretini.legacy', 'Naser Basha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.980Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('XbquKjw3hQfsXKzDicJd', 'fatlum.kovani.no-email-5575314@koretini.legacy', 'Fatlum Kovani', 'MEMBER', 'ACTIVE', NULL, 'Risistrasse 2', '5737', 'Menziken', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.531Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('XcYpU7rlpC8b1ZnTupJN', 'xhevdet.durak.berisha.no-email-55835648@koretini.legacy', 'Xhevdet Durak Berisha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.356Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Xu5CYGe8qcEveQrPAQPT', 'ramadan.canaj.no-email-55110081@koretini.legacy', 'Ramadan Canaj', 'MEMBER', 'ACTIVE', '+4176 435 44 78', 'Sunnebüelstrasse 19', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.100Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Y1rdpnxCKXGRQZSVAkV0', 'arjanis.kovani.no-email-55742698@koretini.legacy', 'Arjanis Kovani', 'MEMBER', 'ACTIVE', NULL, 'Bachmatten 7', '5631', 'Muri AG', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.426Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Y3zDRDVjHilAvTLtf3z5', 'burim@dervishi.ch', 'Burim Dervishi', 'MEMBER', 'ACTIVE', '+41786314062', 'Spitzwiesenstrasse 1', '8957', 'Spreitenbach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.775Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('YEHY8aXyxc3S1xKZXSxf', 'arton.basha.no-email-55012923@koretini.legacy', 'Arton Basha', 'MEMBER', 'ACTIVE', NULL, 'Wagrainstrasse 140', '70378', 'Stuttgart', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:50.129Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('YdSde2UMgRFMv9DTE6BN', 'faton.rexha@gmail.com', 'Faton Rexha', 'MEMBER', 'ACTIVE', '+41763103923', 'Fahrweidstrasse 49', '5630', 'Muri', '1982-10-04', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.726Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('YgZpBcMrodXDoP4Ao7Jb', 'selmani.ilber@hotmail.com', 'Ilber Selmani', 'MEMBER', 'ACTIVE', '+41799421019', 'Solibodenstrasse 16', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.598Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Z56zAITbJQxHxcW74kjz', 'artan.dervishi.no-email-54890874@koretini.legacy', 'Artan Dervishi', 'MEMBER', 'ACTIVE', '+41765003011', 'Im Park 10', '8953', 'Dietikon', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.908Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('Zv3kXoAi4XF6WtQtpztQ', 'dibraui82@hotmail.com', 'Dibran Haxhiu', 'MEMBER', 'ACTIVE', '+41768047899', 'Oberwilerstrasse37', '8964', 'Berikon', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.878Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('aDt4Sct3j771f0IRLk0P', 'fetije.maka.no-email-55533346@koretini.legacy', 'Fetije Maka', 'MEMBER', 'ACTIVE', '+4176 237 41 43', 'Haberweidstrasse 36', '8610', 'Uster', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.333Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('aKUag7RrWhyAtRacHXjf', 'edon.basha.no-email-54947323@koretini.legacy', 'Edon Basha', 'MEMBER', 'ACTIVE', '+41786563135', 'Achilles-Bischoffstrasse 2', '4053', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.473Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('aSnlTg8BoVRshmxIRTFa0O7H7Ov1', 'qazim@dervishi.ch', 'Qazim Dervishi', 'REPRESENTATIVE', 'ACTIVE', '0791390058', 'Spitzwiesenstrasse 1', '8957', 'Spreitenbach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:57:37.263Z', 'KOSOVO', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('aYzZOk2xpBoMWEdG4kPJ', 'axhija.sokol@gmail.com', 'Sokol Axhija', 'BOARD', 'ACTIVE', '+41798017051', 'Hätschenstrasse6', '8953', 'Dietikon', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.304Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('aqlvECv18d2owx5byMAQ', 'ergin.berisha.no-email-55790674@koretini.legacy', 'Ergin Berisha', 'MEMBER', 'ACTIVE', NULL, 'Karl-Völkerstrasse 8', '9435', 'Heerbrugg', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:57.906Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('azPf8pg2mPotVeDPFDc3', 'jasmina.maliqi.no-email-55864535@koretini.legacy', 'Jasmina Maliqi', 'MEMBER', 'ACTIVE', NULL, 'Bildfeldstrasse 17', '9552', 'Bronschofen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.645Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('baloZdBUihYwNiYFJBOZ', 'armend..canaj.no-email-55292358@koretini.legacy', 'Armend  Canaj', 'MEMBER', 'ACTIVE', '+4178 312 88 00 ', 'Boisternstrasse 38', '8483', 'Kollbrunn', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.923Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('bmpEV6A1SBSNmamgZE6V', 'basri.bugaqku.no-email-54711696@koretini.legacy', 'Basri Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'Ludwigstrasse 156', '63067', 'Offtenbach', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.116Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('bmtzfPJotNKUPAG3f8mZ', 'brahim.sula.no-email-55052737@koretini.legacy', 'Brahim Sula', 'MEMBER', 'ACTIVE', '41762353037', 'Ahornweg 24', '8630', 'Rüti', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.527Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('c5fPYIzTEJV9QyqXmyTJ', 'alban.basha.no-email-54951771@koretini.legacy', 'Alban Basha', 'MEMBER', 'ACTIVE', '+41786563135', 'Achilles-Bischoffstrasse 2', '4053', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.517Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('cAOLJ37MpqmIjPLbh4LS', 'ibrahim.canaj.no-email-55242990@koretini.legacy', 'Ibrahim Canaj', 'MEMBER', 'ACTIVE', '+4141 810 17 09', 'Badstrasse 2', '6423', 'Seewen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.429Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('cFmdcJsduMmhq6Q94ACE', 'fisnik.syla.no-email-55035763@koretini.legacy', 'Fisnik Syla', 'MEMBER', 'ACTIVE', '+41762481722', 'Walderstrasse 78', '8630', 'Rüti', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.357Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('cVRzr60NBf5NEx3IXdd8', 'selver.haxhiu@multinetcom.ch', 'Selver Haxhiu', 'MEMBER', 'ACTIVE', '+41764531185', 'Feldhofstrasse35', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.945Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('cz54R9Wye2MZbrlUDO8j', 'isa.krasniqi.no-email-55603436@koretini.legacy', 'Isa Krasniqi', 'MEMBER', 'ACTIVE', '+49 125 32 10', 'Gartenstrasse 8', '78224', 'Singen (DE)', NULL, 'qR9T0s2sdVBwYQmVi20d', 'koretini', '2026-01-31T11:05:56.034Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dB84LtekYpVvo5Y8q7ip', 'musa.krasniqi.no-email-55612090@koretini.legacy', 'Musa Krasniqi', 'MEMBER', 'ACTIVE', NULL, 'Steinstrasse 58', '8106', 'Adlikon b. Regensdorf', NULL, 'qR9T0s2sdVBwYQmVi20d', 'koretini', '2026-01-31T11:05:56.120Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dH9ChvriRcPvIHWN0Ez0', 'fitim.haxhiu.no-email-54500795@koretini.legacy', 'Fitim Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'NeueRommerlshauserStr.20', '71332', 'Waiblingen', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.007Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dIozegHnUNYDeR8njnnT', 'qazim@dervishi.ch', 'Qazim Dervishi', 'REPRESENTATIVE', 'ACTIVE', '0791390058', 'Spitzwiesenstrasse 1', '8957', 'Spreitenbach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:57:37.263Z', 'KOSOVO', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dZT2D2UHna4cZLkf0oNO', 'ruzhdi.canaj.no-email-55122195@koretini.legacy', 'Ruzhdi Canaj', 'MEMBER', 'ACTIVE', '+4179 775 85 51', 'Ifangweg 25', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.221Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dgPH59PmTyWYAWSYT50U', 'reshat.bugaqku.no-email-54715524@koretini.legacy', 'Reshat Bugaqku', 'MEMBER', 'ACTIVE', '+491714241274', 'Zum Mittelfeld 22', '57462', 'Olpe, DE', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.155Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('dtAzGSYEJUkYg77anjsg', 'lulzim.basha.no-email-54989556@koretini.legacy', 'Lulzim Basha', 'MEMBER', 'ACTIVE', '+41762776458', NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.895Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('e2U4h7YIXPoZG3y6D10u', 'elvedin.gagica.no-email-55481576@koretini.legacy', 'Elvedin Gagica', 'MEMBER', 'ACTIVE', NULL, 'Kortrijksebaan 98D', '3220', 'Holsbeek (Belgien)', NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.815Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('eGJWf0hHGvql9CvwgpQf', 'besart.kosumi@outlook.com', 'Besart  Kosumi', 'MEMBER', 'ACTIVE', '+4179 210 91 22', 'Fadacherstrasse 21', '8340', 'Hinwil', NULL, 'gg0GE0qz4ZMf35cRtesp', 'koretini', '2026-01-31T11:05:56.306Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ePuogryKItgLRk9bbyLd', 'tahir.klaiqi@gmail.com', 'Tahir Klaiqi', 'MEMBER', 'ACTIVE', '+4176 546 54 85', 'Riedenstrasse 41', '6370', 'Oberdorf', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:56.998Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('enVWNehAbTTSHTFZHGQt', 'fragment.selmani.no-email-54825257@koretini.legacy', 'Fragment Selmani', 'MEMBER', 'ACTIVE', '+41788912668', 'Lättenstrasse 4', '8952', 'Schlieren', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.252Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ez0srtZX40JQPXlxPQs7', 'agim..masurica.no-email-54967817@koretini.legacy', 'Agim  Masurica', 'MEMBER', 'ACTIVE', NULL, 'Martinsbruggstrasse 54', '9016', 'St.Gallen', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.678Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fFy6tZpTGthwwuyOd95f', 'avdullah.matoshi.no-email-55074121@koretini.legacy', 'Avdullah Matoshi', 'MEMBER', 'ACTIVE', NULL, 'Rosinlistrasse 13', '8620', 'Wetzikon', NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-01-31T11:05:50.741Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fLGVrdn4ksY6q9CCwKML', 'a.klaiqi@jakconsulting.ch', 'Alban Klaiqi', 'MEMBER', 'ACTIVE', '+4179 500 50 05', 'Hirtenhofstrasse 25a', '6005', 'Luzern', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.037Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fPQv4e2RShLC3KSx58IC', 'flamur.maliqi.no-email-55855631@koretini.legacy', 'Flamur Maliqi', 'MEMBER', 'ACTIVE', '+4176 804 28 92', 'Pfändwiesenstrasse 15', '8152', 'Opfikon', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.556Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fiB48X9bMu0WPwp22hRX', 'selami.selmani@isen-tiefbau.ch', 'Selami Selmani', 'MEMBER', 'ACTIVE', '+41792096777', 'Solibadenstrasse 16', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.437Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fk2N7zCXnsoq4mZYbVHZ', 'muhamed.leci.no-email-55676053@koretini.legacy', 'Muhamed Leci', 'MEMBER', 'ACTIVE', '+41762026128', 'Mülibachstrasse 56', '8107', 'Buchs ZH', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.760Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('fnZHUKTvcVQVRGk8Vziz', 'laurenttii@hotmail.com', 'Lauret Canaj', 'MEMBER', 'ACTIVE', '+4176 568 01 36', 'Unter Weidstrasse 12', '6343', 'Rotkreuz', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.507Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('g8l2DK6izNJcyPMsQjuW', 'sinan..isufi.no-email-55379814@koretini.legacy', 'Sinan  Isufi', 'MEMBER', 'ACTIVE', '+4179 626 60 89', 'Meierwiesenstrasse 45', '8107', 'Buchs', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.798Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('gNjAnUTHONc7x6lUfvLI', 'fatmir.canaj.no-email-55225360@koretini.legacy', 'Fatmir Canaj', 'MEMBER', 'ACTIVE', '+4144 862 57 04', 'Zürichstrasse 70', '8180', 'Bülach', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.253Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('gXfkKqKwGOVJ9bhLZGcm', 'fatos.selmani@hotmail.com', 'Fatos Selmani', 'MEMBER', 'ACTIVE', '+41796426768', 'Weidmannstrasse11', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.938Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('gcRJWkK4JO725Zl7w8I4', 'genc.hoda.no-email-55493524@koretini.legacy', 'Genc Hoda', 'MEMBER', 'ACTIVE', '+41765690710', 'Kantonstrasse 20', '6046', 'Luzern', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:54.935Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('gspmPUc1vajf1yBmhIdV', 'bujar.rexhiqi@gmail.com', 'Bujar Rexha', 'MEMBER', 'ACTIVE', '+41765683989', 'Meiliplatz 2', '6032', 'Emmen', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.262Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('h1M4FBpjtYNNQ6qttVHQ', 'feim.bugaqku.no-email-54701419@koretini.legacy', 'Feim Bugaqku', 'MEMBER', 'ACTIVE', '+41766113379', 'Haldenstrasse 33', '4600', 'Olten', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.014Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('h1WJwMVgwX3rnT6wEDpS', 'ardian.rexha@outlook.com', 'Ardian Rexha', 'MEMBER', 'ACTIVE', '+4178301472', 'Weinberg 2', '5634', 'Merenschwand', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.646Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('hKC5mjsLlFjE466UA4DL', 'afrimhaxhiu@hotmail.com', 'Afrim Haxhiu', 'MEMBER', 'ACTIVE', '+41794676420', 'UntereDorfstrasse20', '8964', 'Rudolfstetten', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.485Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('hSXl68mMxzERBwe8xild', 'bejtulla.matoshi.no-email-55084258@koretini.legacy', 'Bejtulla Matoshi', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-01-31T11:05:50.842Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('hhHDHaialMGjgQ7ISBBY', 'burim.basha.no-email-5499405@koretini.legacy', 'Burim Basha', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.940Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('hq52JcQuzWyE7ojuBQB3', 'ilir.haxhiu.no-email-54520338@koretini.legacy', 'Ilir Haxhiu', 'MEMBER', 'ACTIVE', '+''41762203595', 'Gerenstrasse25', '8105', 'Regensdorf', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.203Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('i0vSb3mQ1MVAQonoA1ol', 'suad.canaj.no-email-55102238@koretini.legacy', 'Suad Canaj', 'MEMBER', 'ACTIVE', '+4176 303 44 84', 'Sunnebüelstrasse 94', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.022Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('i6wSfJ5ImDENSKbiDIjO', 'selmani.besart@hotmail.com', 'Besart Selmani', 'MEMBER', 'ACTIVE', '+41799173609', 'Hammerweg 4', '8304', 'Wallisellen', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.483Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('iPw85igZazPqFOckeffr', 'sami.bugaqku.no-email-54685095@koretini.legacy', 'Sami Bugaqku', 'MEMBER', 'ACTIVE', '+41786362129', 'Rue de Lausanne 57', '1020', 'Renens', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.850Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('iQsvhGyiLWuCuCqJnHZr', 'zijadin.isufi.no-email-55389719@koretini.legacy', 'Zijadin Isufi', 'MEMBER', 'ACTIVE', '+41762227263', 'Dammstrasse 29', '8152', 'Glattbrugg', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.898Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('iUYnOvuzRHve9tBEFI4M', 'ramiz.selmani@hotmail.com', 'Ramiz Selmani', 'MEMBER', 'ACTIVE', '+41796533781', 'Feldstrasse 18', '8952', 'Schlieren', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.292Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ijJ9SKJC6QVc3mfyLFqF', 'egzon.mehmeti.no-email-54676579@koretini.legacy', 'Egzon Mehmeti', 'MEMBER', 'ACTIVE', NULL, 'Herbstweg 100', '8050', 'Zürich', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.765Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('j6Mr6fz3gwS2s0QbDVOk', 'h.isufi@ha-tech.ch', 'Hasan  Isufi', 'MEMBER', 'ACTIVE', '+4179 303 88 80', 'Pfäffikerstr. 75', '8623', 'Wetzikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.237Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('jAimYGm4Ss4jz0gJ1m6r', 'meriton.haxhiu.no-email-54542421@koretini.legacy', 'Meriton Haxhiu', 'MEMBER', 'ACTIVE', '+41799441339', 'Bachstrasse11', '6048', 'Horw', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.424Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('jJPGwhAqG1uRJPTkEEtD', 'fadil.bushi.no-email-55537543@koretini.legacy', 'Fadil Bushi', 'MEMBER', 'ACTIVE', NULL, 'Zelgwasserweg 11', '4460', 'Gelterkinden', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.375Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('jienwWO87wzW4lJGeEzu', 'rilind_selmani@hotmail.com', 'Rilind Selmani', 'MEMBER', 'ACTIVE', '+41798172017', 'Kraftwerkstr. 24a', '4313', 'Möhlin', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.112Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('jpSwqs33Bc8DMVJZk6le', 'nazim.lecaj.no-email-55667130@koretini.legacy', 'Nazim Lecaj', 'MEMBER', 'ACTIVE', '+41767369643', 'Ernastrasse 18', '8004', 'Zürich', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.671Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('juH7HwbvCL5sLPsfh6yq', 'fatmir.axhija@online.de', 'Fatmir Axhija', 'MEMBER', 'ACTIVE', '+491634275692', 'AmKrautgarten2', '86869', 'Oberostendorf', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.173Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('k4JRXOFJ9QMl2fgTASSc', 'ilirikselmani_@hotmail.com', 'Ilirik Selmani', 'MEMBER', 'ACTIVE', '+41799248046', 'Dora-Staudinger-Strasse 6, 8046 Zürich', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:49.166Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('k5VRYvXfsZHTqNXxhxUj', 'agim.berisha.no-email-55823594@koretini.legacy', 'Agim Berisha', 'MEMBER', 'ACTIVE', NULL, 'Oberdorfstrasse 34', '8750', 'Glarus', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.235Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('kO1pXlZGJBSeiMgcM7zr', 'kamenica@gmx.ch', 'Sami Basha', 'MEMBER', 'ACTIVE', '+41792052997', 'Lehenmattstrasse 189', '4052', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.209Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('kPbNNHuXzEHktCPnUXZV', 'alban.haxhiu.no-email-54456940@koretini.legacy', 'Alban Haxhiu', 'MEMBER', 'ACTIVE', '+416111663816', 'BOULEVARDDELAROCADE 14', '74000', 'Annecy', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.569Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('kgBwCHzlHrPhYeJOohAy', 'kadrush.bugaqku.no-email-54689230@koretini.legacy', 'Kadrush Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'Rosenweg 8', '4303', 'Kaiseraugst', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:46.892Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('knczUTfu7mlhifNrGzp0', 'arsim.canaj.no-email-55229076@koretini.legacy', 'Arsim Canaj', 'MEMBER', 'ACTIVE', '+4144 862 57 04', 'Zürichstrasse 70', '8180', 'Bülach', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.290Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lStD3izI9J5DSb8yeMvP', 'amir.canaj.no-email-55260846@koretini.legacy', 'Amir Canaj', 'MEMBER', 'ACTIVE', '+4179 230 56 56', 'Rorschacherstrasse 244', '9016', 'St. Gallen', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.608Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lV6jIXhu1ELAwXshLzSp', 'niki`s fahrschule', 'Besnik Syla', 'MEMBER', 'ACTIVE', NULL, 'Faegwilerstrasse 10', '8630', 'Rüti', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.570Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lVJfQnyl4dsjc1yrwMIm', 'shillovabajram@gmail.com', 'Bajram Shillova', 'MEMBER', 'ACTIVE', '+41791390056', 'Holzmattstrasse 36', '8953', 'Dietikon', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.273Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lVLNuA0s86E4Rdyq9Um1', 'valdrin.basha.no-email-54959788@koretini.legacy', 'Valdrin Basha', 'MEMBER', 'ACTIVE', '+41919682943', 'via Generale Guisan 25A', '6900', 'Massagno TI', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.597Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lWLtZBHgVVXTNZrWOfHe', 'skender.haxhiu.no-email-54603589@koretini.legacy', 'Skender Haxhiu', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.035Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ldDq8WrXjGKqPU80ZPEA', 'quni3@hotmail.com', 'Amir Kosumi', 'MEMBER', 'ACTIVE', '+4178 907 27 64', 'Hüssenbüelstrasse 2', '8340', 'Hinwil', NULL, 'gg0GE0qz4ZMf35cRtesp', 'koretini', '2026-01-31T11:05:56.259Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lwILNbCkR1nzybOpEhiv', 'remzi.klaiqi.no-email-5572446@koretini.legacy', 'Remzi Klaiqi', 'MEMBER', 'ACTIVE', NULL, 'Klausen 4', '8754', 'Netstal', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.244Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lwVAUKKcefK2yrwGLQX6', 'idriz.kosumi.no-email-55638575@koretini.legacy', 'Idriz Kosumi', 'MEMBER', 'ACTIVE', NULL, 'Steinmürlistrasse 5', '8953', 'Dietikon', NULL, 'gg0GE0qz4ZMf35cRtesp', 'koretini', '2026-01-31T11:05:56.385Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lzKhkxTRWCaV3syqrAwZ', 'fazli.haxhiu.no-email-54496557@koretini.legacy', 'Fazli Haxhiu', 'MEMBER', 'ACTIVE', '+''41765345371', 'Ifangstrasse14', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.965Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('lzKkQIrVSE5NtjReGqwz', 'sefer.korbi.no-email-55546777@koretini.legacy', 'Sefer Korbi', 'MEMBER', 'ACTIVE', NULL, 'Alte Lenzburgerstr. 13c', '5702', 'Niederlenz', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.467Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('mB6wGvCik9UBrzPBeHzK', 'faik..canaj.no-email-55213141@koretini.legacy', 'Faik  Canaj', 'MEMBER', 'ACTIVE', NULL, 'Mythenweg 25', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.131Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('mRyJKgPKKH6MXzc3xW1k', 'qerim..canaj.no-email-55237994@koretini.legacy', 'Qerim  Canaj', 'MEMBER', 'ACTIVE', '+4155 610 42 16', 'Fronalpstrasse 6', '8752', 'Näfels', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.379Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ma0uCs5NNwkyAq86gD3K', 'albert-klaiqi@hotmail.com', 'Albert Klaiqi', 'MEMBER', 'ACTIVE', '+4179 174 87 61', 'Chemin d''Eysins 43', '1260', 'Nyon', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.154Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('mpMLyr31WUyGhCldf7tV', 'sevdair.neziri.no-email-55694381@koretini.legacy', 'Sevdair Neziri', 'MEMBER', 'ACTIVE', NULL, 'Lerchenstrasse 5', '8212', 'Neuhausen', NULL, '8KGIaCmhzCimjPGxWRnJ', 'koretini', '2026-01-31T11:05:56.943Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('nBTFUdCcCzIPexcB3InQ', 'valon.maka.no-email-55516152@koretini.legacy', 'Valon Maka', 'MEMBER', 'ACTIVE', '+4176 226 00 20', 'Stuhlenstrasse 3 ', '8123', 'Ebmatingen', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:55.161Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('nObnJ43ITh0dte8wYwXy', 'aziz.skover.ani.no-email-55872588@koretini.legacy', 'Aziz Skoverçani', 'MEMBER', 'ACTIVE', '+4144 870 32 40', 'Affolternstrasse 50', '8105', 'Regensdorf', NULL, 'nluPWLS0NdyzaJtUwsGn', 'koretini', '2026-01-31T11:05:58.725Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('o5XUtMQL1BjrPzEPqkvC', 'sylejman.canaj.no-email-55301255@koretini.legacy', 'Sylejman Canaj', 'MEMBER', 'ACTIVE', NULL, 'Calendariaweg 3', '6405', 'Immensee', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:53.012Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('oBTo1dc9kxwuQ9FMqdr8', 'arktim.selmoni.no-email-54789099@koretini.legacy', 'Arktim Selmoni', 'MEMBER', 'ACTIVE', '+41763885423', 'Im Holzerhurd 43', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.890Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ogFvzASUQir5j2YoE1EU', 'isa.shaqiri.no-email-5444000@koretini.legacy', 'Isa Shaqiri', 'MEMBER', 'ACTIVE', '+4917623364841', NULL, NULL, NULL, NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.400Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('oqjryv7UmwaDVrbiRkvE', 'zulfi.krasniqi.no-email-55608176@koretini.legacy', 'Zulfi Krasniqi', 'MEMBER', 'ACTIVE', NULL, 'Sonnenbergstrasse 57', '8800', 'Thalwil', NULL, 'qR9T0s2sdVBwYQmVi20d', 'koretini', '2026-01-31T11:05:56.081Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('pCiCcSL9H2uVhNV4Afja', 'afrim.ramadani.no-email-55460447@koretini.legacy', 'Afrim Ramadani', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.604Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('pFHjA9maRDL8fqOh8tnR', 'adem.selmoni.no-email-54764046@koretini.legacy', 'Adem Selmoni', 'MEMBER', 'ACTIVE', '+41768164252', 'Südweg 6', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.640Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('pJQidcz8v959HhBcLNgQ', 'driton.matoshi.no-email-55079559@koretini.legacy', 'Driton Matoshi', 'MEMBER', 'ACTIVE', NULL, 'Leimgrubstrasse 3', '8340', 'Hinwil', NULL, 'RJHRQkks4TmQIKfoXf3v', 'koretini', '2026-01-31T11:05:50.795Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('pyhNZ9mpxdHkXe5V4olA', 'ismet.klaiqi.no-email-55708337@koretini.legacy', 'Ismet Klaiqi', 'MEMBER', 'ACTIVE', '+4176 232 10 67', 'Hohrainlistrasse 8', '8302', 'Kloten', NULL, 'N8tL7KMa4gnmGuC0SRqP', 'koretini', '2026-01-31T11:05:57.083Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('q05tDX12NXQSPDF1f9LM', 'basha@sunrise.ch', 'Enver Basha', 'MEMBER', 'ACTIVE', '+41765447885', 'Feldbergstrasse 140', '4057', 'Basel', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.297Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qB5Ss9IexEa7uvbqzvsU', 'jakup.dervishi.no-email-54886311@koretini.legacy', 'Jakup Dervishi', 'MEMBER', 'ACTIVE', '+41793581413', 'Im Park 18', '8953', 'Dietikon', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.863Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qDWbPzoEyFWnA98VObJT', 'ideal_selmani@hotmail.com', 'Ideal Selmani', 'MEMBER', 'ACTIVE', '+41795395884', 'Dora-Staudinger-Strasse 6', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:49.123Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qX5Fri1BqW5NccgitwQW', 'besart.bugaqku.no-email-54730681@koretini.legacy', 'Besart Bugaqku', 'MEMBER', 'ACTIVE', NULL, 'An der Plantage 36', '55120', 'Mainz', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.306Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qcc5XAFs1vhXTmKWD74O', 'arsim.ramadani.no-email-5543738@koretini.legacy', 'Arsim Ramadani', 'MEMBER', 'ACTIVE', NULL, 'Fischerweg 4', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.373Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qh4qhnEenvXX9U3z17Xi', 'fatos.selmani.no-email-5490881@koretini.legacy', 'Fatos Selmani', 'MEMBER', 'ACTIVE', '+41796426768', 'Weidmannstrasse 11', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:49.088Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('qkOjbzA3UUasQ1OWicZj', 'mustaf.neziri.no-email-55689994@koretini.legacy', 'Mustaf Neziri', 'MEMBER', 'ACTIVE', NULL, 'Hauentalstrasse 153', '8200', 'Schaffhausen', NULL, '8KGIaCmhzCimjPGxWRnJ', 'koretini', '2026-01-31T11:05:56.899Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('roPmUmC83iYMQWBIqAs0gFevqi43', 'burim@dervishi.ch', 'Burim Dervishi', 'MEMBER', 'ACTIVE', '+41786314062', 'Spitzwiesenstrasse 1', '8957', 'Spreitenbach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.775Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('roR6qlrgu2mA2M6EFjjT', 'ardianit.canaj.no-email-55270820@koretini.legacy', 'Ardianit Canaj', 'MEMBER', 'ACTIVE', NULL, 'Rue des andains 14', '2800', 'Delemont', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.708Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('rqFXoHunBYmqQHEm3HFM', 'hyda_20@hotmail.com', 'Hydajet Maliqi', 'MEMBER', 'ACTIVE', '+4176 586 95 62', 'Langenmattstrasse 16', '8617', 'Mönchaltorf', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.471Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sFfOYgEDZoGCbNfmWUr3', 'agon.haxhiu.no-email-54660372@koretini.legacy', 'Agon Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'Amziegelanger42', '86899', 'Landsberg', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.603Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sJKHokGb0uhPgKMaFHRd', 'sebehat.ramadani.no-email-55407667@koretini.legacy', 'Sebehat Ramadani', 'MEMBER', 'ACTIVE', NULL, 'Kreuzstrasse 6', '8953', 'Dietikon', NULL, 'Ic9yVntQPNmQgtPadHCJ', 'koretini', '2026-01-31T11:05:54.076Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sJd2d4sF9cLF2RRK3K8v', 'agim..sadiku.no-email-55403157@koretini.legacy', 'Agim  Sadiku', 'MEMBER', 'ACTIVE', '+4176 239 68 14', 'Alfred Strebelweg 16', '8047', 'Zürich', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:54.031Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sRT6MkRE1iQXTsdGXJdx', 'ajete.haxhiu.no-email-54646311@koretini.legacy', 'Ajete Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'Gerenstrasse25', '8105', 'Regensdorf', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.463Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sXgf34RabSiCRf35MHF4', 'burhan.basha.no-email-54925167@koretini.legacy', 'Burhan Basha', 'MEMBER', 'ACTIVE', '+41764486635', 'Bata-Park 19', '4313', 'Möhlin', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.251Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sbKbyfjUakRBYpMnXiJv', 's.canaj@canaj.ch', 'Shkelzen Canaj', 'MEMBER', 'ACTIVE', '+4179 634 65 22', 'Sunnebüelstrasse 94', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:50.974Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sp7BvH0YSeJwyctr1SLS', 'sabri..ker.eli.no-email-55585614@koretini.legacy', 'Sabri  Kerçeli', 'MEMBER', 'ACTIVE', NULL, 'Heckenweg 1', '8353', 'Elgg ZH', NULL, 'RMsYofQDTV9zBjVwVQF4', 'koretini', '2026-01-31T11:05:55.856Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('sxdy5VdFc7ZkpRS7itqn', 'elbonit.bugaqku.no-email-54734965@koretini.legacy', 'Elbonit Bugaqku', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.349Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('t3N4ybGWXVmnoEmTccrQ', 'kushtrim.selmani.no-email-54802732@koretini.legacy', 'Kushtrim Selmani', 'MEMBER', 'ACTIVE', '+41765744332', 'Altwinkelstrasse 17', '9015', 'St.Gallen', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.027Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('tCzSwzNW24VCnq6PsoND', 'jakup.canaj.no-email-55209132@koretini.legacy', 'Jakup Canaj', 'MEMBER', 'ACTIVE', '+4176 264 18 74', NULL, NULL, 'Basel', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.091Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('tVHGe9fBvoAYX45J3PO8', 'kcanah@yahpp.com', 'Kujtim Canaj', 'MEMBER', 'ACTIVE', NULL, 'Adawy Ave Se Ada', NULL, NULL, NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:52.800Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('u3BcWiCtbSjtWDtnqh8v', 'herolind.selmani@isen-tiefbau.ch', 'Herolind Selmani', 'MEMBER', 'ACTIVE', '+41765102822', 'Kaffeestrasse 20', '8180', 'Bülach', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.547Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('u3MtMamZG5KJ5r9bk88c', 'arianit.selmoni.no-email-54784699@koretini.legacy', 'Arianit Selmoni', 'MEMBER', 'ACTIVE', '+41765950388', 'Im Holzerhurd 43', '8046', 'Zürich', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:47.846Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('u9O3sJ4748EPhxFx2tdX', 'sami_shabani8@hotmail.com', 'Sami Shabani', 'MEMBER', 'ACTIVE', '+41792068329', 'Altwiesenstrasse 29', '5436', 'Würenlos', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.462Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('ueiikuVtrAEbHyyQX6x5', 'faton.maliqi.no-email-55868030@koretini.legacy', 'Faton Maliqi', 'MEMBER', 'ACTIVE', '+4176 428 89 33', 'Altwiesenstrasse 146', '8051', 'Zürich', NULL, 'cyohY3a11AJBcnysXocA', 'koretini', '2026-01-31T11:05:58.680Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('utBQFVLPbkwkZWSz5lzh', 'albert.dervishi.no-email-54894851@koretini.legacy', 'Albert Dervishi', 'MEMBER', 'ACTIVE', NULL, NULL, '76829', 'Landau in der Pfalz', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.948Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('uwerd76arUMGZKKhrttA', 'rinor.kallaba.no-email-54668324@koretini.legacy', 'Rinor Kallaba', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.683Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('uxb6SxyF0hYxEmeAvAc4', 'valmir.basha.no-email-5495557@koretini.legacy', 'Valmir Basha', 'MEMBER', 'ACTIVE', '+41919682943', 'via Generale Guisan 25A', '6900', 'Massagno TI', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.555Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('v4TpRsZyxdUrYL9y5eO5', 'ruempel-blitz@gmx.at', 'Enver Hasani', 'MEMBER', 'ACTIVE', '+41769406288', 'Röthelsteinweg455', '8911', 'Admont', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:46.131Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('vCUr6Zp24roLp4DtgNzh', 'ismajl.syla.no-email-55031595@koretini.legacy', 'Ismajl Syla', 'MEMBER', 'ACTIVE', NULL, 'Fronalpstrasse 14', '8752', 'Näfels( GL)', NULL, 'RSIEPgUmzLRNEWX0vdHH', 'koretini', '2026-01-31T11:05:50.315Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('vDYmsQ6f7WKjbLr3aeVw', 'blerim.kovani.no-email-55746837@koretini.legacy', 'Blerim Kovani', 'MEMBER', 'ACTIVE', NULL, 'Steinackerstrasse 2', '9445', 'Rebstein', NULL, 'jXooYH3RfXSRcHEodS1y', 'koretini', '2026-01-31T11:05:57.468Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('voX1pHUBMEY8rCGRfD3S', 'shaqir.kamberi.no-email-55489053@koretini.legacy', 'Shaqir Kamberi', 'MEMBER', 'ACTIVE', NULL, NULL, NULL, NULL, NULL, 'x7z55SgYcUEMHrnVLhwl', 'koretini', '2026-01-31T11:05:54.890Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('w23ECDS4EWXcBxg4O73nT11pKLm1', 'ledion@dervishi.ch', 'Ledion Dervishi', 'NEIGHBORHOOD_MANAGER', 'ACTIVE', '0782425090', 'Spitzwiesenstrasse,1', '8957', 'Spreitenbach', '2008-11-18', 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T18:22:51.885Z', 'STANDARD', NULL, NULL, false, true) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('wFz7lCDO1bwkGpDuNvWd', 'imran.basha.no-email-54933295@koretini.legacy', 'Imran Basha', 'MEMBER', 'ACTIVE', '+41765096701', 'Oberemattstrasse 20', '4133', 'Pratteln', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.332Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('wLQaT8bHRyyUuX6SFvn1', 'musli.haxhiu.no-email-54556440@koretini.legacy', 'Musli Haxhiu', 'MEMBER', 'ACTIVE', '+41765173444', 'Säntisweg1', '8604', 'Volketswil', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:45.564Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('weI3AYPAX3PS5Yi6PyAl', 'arsim.demi.no-email-55843488@koretini.legacy', 'Arsim Demi', 'MEMBER', 'ACTIVE', NULL, 'Bergackerweg 12', '3054', 'Schüpfen', NULL, 'wQV3M5IQiReJPGyR0gqN', 'koretini', '2026-01-31T11:05:58.434Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('wnuNMO8sItnL4rOvgL60', 'kanaj@windowslive.com', 'Ibrahim Canaj', 'MEMBER', 'ACTIVE', '+4176 433 01 36', 'Unter Weidstrasse 12', '6343', 'Rotkreuz', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.302Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('wpNcpXsvDpHmnTDBz8BZ', 'ismet.canaj.no-email-5510643@koretini.legacy', 'Ismet Canaj', 'MEMBER', 'ACTIVE', NULL, 'Sunnebüelstrasse 94 ', '8604', 'Volketswil', NULL, '2dfxYzVnwHgXPatyu34F', 'koretini', '2026-01-31T11:05:51.064Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('wzqSKKX3aWUWsq7jKnNx', 'blerim.lecaj.no-email-55648098@koretini.legacy', 'Blerim Lecaj', 'MEMBER', 'ACTIVE', '+41798995258', 'Winterthurerstrasse 81', '8610', 'Uster', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.480Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('xD5hwucB5OGt1Zkonmh2', 'nderim.berisha.no-email-55827961@koretini.legacy', 'Nderim Berisha', 'MEMBER', 'ACTIVE', NULL, 'Blasius-erler-weg 5', '88427', 'Bad Schusenried', NULL, 'P1ucCFXXVyHgGsA1hXDV', 'koretini', '2026-01-31T11:05:58.279Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('xFW64fTcGAs3WM9eBCBg', 'family.bash@hotmail.com', 'Bajram Basha', 'MEMBER', 'ACTIVE', '+41788730903', 'Dänikenstrasse 8', '8105', 'Dällikon', NULL, 'IAs5cJR7erHaldgnNsUi', 'koretini', '2026-01-31T11:05:49.385Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('xTqfkN32928h3M681DaR', 'dardan.haxhiu@hotmail.com', 'Dardan Haxhiu', 'MEMBER', 'ACTIVE', '+41794441100', 'Kesslernmattstrasse108964Berikon', '8964', 'Rudolfstetten', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.787Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('y7FJhBiM9fwZXIva1Fsf', 'toni_009@hotmail.com', 'Arton Shaqiri', 'MEMBER', 'ACTIVE', '+41763057085', 'Ettenhauserstrasse 68', '8620', 'Wetzikon', NULL, '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:44.307Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('yVXS6QeI6uNKZS3bJPKm', 'ludi_pa@hotmail.com', 'Mevlud Dervishi', 'MEMBER', 'ACTIVE', '+37744503593', 'Steigstrasse 20', '5426', 'Lengnau', NULL, 'Gw8s5lNhSTd54MqCjczI', 'koretini', '2026-01-31T11:05:48.697Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('yf5QwnkaMHR39wYpCEPC', 'sheshivar.leci.no-email-55662353@koretini.legacy', 'Sheshivar Leci', 'MEMBER', 'ACTIVE', '+41765825845', 'Hummelackerstrasse 27', '8106', 'Regensdorf', NULL, '1H8vJXoJkF1iFEZPUgUP', 'koretini', '2026-01-31T11:05:56.623Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('yoZcFlXGoygiWBJ6fSk3', 'enver.haxhiu.no-email-54483290@koretini.legacy', 'Enver Haxhiu', 'MEMBER', 'ACTIVE', NULL, 'Triemlistrasse136', '8047', 'Zürich', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.832Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('z1TxKlv4OUiJJQR42tLo', 'qendrim.jusufi.no-email-5531407@koretini.legacy', 'Qendrim Jusufi', 'MEMBER', 'ACTIVE', '+4177 255 75 80', 'Goldbühlstrasse 11', '8620', 'Wetzikon', NULL, 'YJ2X9Smwr7YHiTipmEQL', 'koretini', '2026-01-31T11:05:53.140Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('z8cGQZrks4lnzYyHDcji', 'visar.bugaqku.no-email-54726269@koretini.legacy', 'Visar Bugaqku', 'MEMBER', 'ACTIVE', '+491714241274', 'Zum Mittelfeld 22', '57462', 'Olpe, DE', NULL, 'Onysnf1rqURgy68fA5A5', 'koretini', '2026-01-31T11:05:47.262Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('zEwGIgKUKe3irn5RPy95', 'halim.rexha@gmx.ch', 'Halim Rexha', 'MEMBER', 'ACTIVE', '+41796379109', 'Weinberg 2', '5634', 'Merenschwand', '1964-04-28', '5KwI3rPMfthzTamV4Omi', 'koretini', '2026-01-31T11:05:43.869Z', 'STANDARD', NULL, NULL, false, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('zMVnrJVPArB5vqwMVMSI', 'besmir.ker.eli.no-email-5559909@koretini.legacy', 'Besmir Kerçeli', 'MEMBER', 'ACTIVE', NULL, 'Rütistrasse 1B', '8952', 'Schlieren', NULL, 'RMsYofQDTV9zBjVwVQF4', 'koretini', '2026-01-31T11:05:55.990Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

INSERT INTO "users" ("id", "email", "displayName", "role", "membershipStatus", "phone", "street", "zip", "city", "birthdate", "neighborhoodId", "tenantId", "joinedAt", "billingGroup", "customAnnualFee", "familyId", "isLegacyEmail", "profileComplete") 
VALUES ('zYO57Q2THaRKV7ysgpXd', 'antizan.haxhiu.no-email-5446132@koretini.legacy', 'Antizan Haxhiu', 'MEMBER', 'ACTIVE', '+41767341583', 'Orenbergstr.17', '8475', 'Ossingen', NULL, 'JQM71uI7qbLu1WoLEgcq', 'koretini', '2026-01-31T11:05:44.613Z', 'STANDARD', NULL, NULL, true, false) 
ON CONFLICT ("id") DO UPDATE SET 
  "email" = EXCLUDED."email",
  "displayName" = EXCLUDED."displayName",
  "role" = EXCLUDED."role",
  "membershipStatus" = EXCLUDED."membershipStatus",
  "phone" = EXCLUDED."phone",
  "street" = EXCLUDED."street",
  "zip" = EXCLUDED."zip",
  "city" = EXCLUDED."city",
  "birthdate" = EXCLUDED."birthdate",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "tenantId" = EXCLUDED."tenantId",
  "joinedAt" = EXCLUDED."joinedAt",
  "billingGroup" = EXCLUDED."billingGroup",
  "customAnnualFee" = EXCLUDED."customAnnualFee",
  "familyId" = EXCLUDED."familyId",
  "isLegacyEmail" = EXCLUDED."isLegacyEmail",
  "profileComplete" = EXCLUDED."profileComplete";

-- ---------------------------------------------------------
-- Data for Table: payments
-- ---------------------------------------------------------
INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('085sBYDwdv2fkrpoI0PW', 'F9aiJKT5Tv9tgkgXepbt', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026286', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('0PqX5NrPnbN18lO79tev', 'lVLNuA0s86E4Rdyq9Um1', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027317', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('0Rkv8A198cXXl80KeLwx', 'DeBRcyNc17lT3M8F7uQK', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802377', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('0aWnoGaCGoWTk2VgmayP', 'iQsvhGyiLWuCuCqJnHZr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027332', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('0rrOZWq3fq4MEEjPMuDT', 'R9tUIryGuAECry15lGLy', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024106', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('0z9vjFDqm3ehBrCSAIQV', '9AukwVBpII7WdplD7NG2', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802234', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1AINpMwQS3Tuobu92rQz', 'aKUag7RrWhyAtRacHXjf', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024113', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1Cebwhlz0iRyEx3hHcFy', 'zMVnrJVPArB5vqwMVMSI', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802387', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1Eoi4O2VqrUZut5QfLqI', 'AfDriDW5TAB7uHCxxs14', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025199', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1VyKiW6Wc4Ea8sfyr1g8', 'S1tc04HcrJPhFPpPm1oX', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024160', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1b4DQmpHkHRNpqo1eYCI', 'Qs7PFWQaZeb4tcm60hqS', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802374', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('1bdHWvTCp9iSU8t6oVz5', 'lWLtZBHgVVXTNZrWOfHe', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026309', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('25nefdUJTIw6xEmT3C8I', 'bmpEV6A1SBSNmamgZE6V', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:52:20.182Z', 'INV-1802265', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('2Ft8alNHgWodXan86XnR', 'lV6jIXhu1ELAwXshLzSp', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802391', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('2H2i6mWqtRY9WtTtnvHs', 'hhHDHaialMGjgQ7ISBBY', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18023100', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('2KTsc4BaaWKMKoTradLT', '0UMG0pIQFUWOmWLiTLZz6rP82122', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027321', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('3Au7uE2BJJz5TIZrpgcs', 'K3ZlGmzELbt7C0u67iV4', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026248', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('3Dvg9Gj7qgNeM1LysG1v', 'V8eKk0xypOOnwKhvmlZG', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026301', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('3VmS9NUW2Wo1vNPRfLsA', 'UKtD0bbMnd3SRXIhclzk', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026298', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('3f7ait6Ncg8HaaoY0Tfw', 'OSiobnhSHtpWmEM49JA9', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024162', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('3kL7yDbLGmJB6BprHgAY', 'qX5Fri1BqW5NccgitwQW', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802379', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('45aec6I8EDRzhpAr0RzM', 'aYzZOk2xpBoMWEdG4kPJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:43:45.204Z', 'INV-18026310', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('46Ob2dxlb2nnMs4WyWwo', 'jienwWO87wzW4lJGeEzu', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:44:10.195Z', 'INV-18026269', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('477Pl08k7llAgwxQlFud', 'ma0uCs5NNwkyAq86gD3K', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802223', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('47memC6zHgmYGtZvbnKu', 'PecWBJQOnqOgNEzPKvWM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024164', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('49UWgXdl9VlyRd4VJP6T', 'SMr1gqJIllgETPHCZNK8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026257', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('4Ad9HVuZ4VOgohWAJ3Bg', 'JJao5VpVhUUHfgigDhla', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:58:20.953Z', 'INV-18026255', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('4IodwXRsjoUmiPryjoQd', '5E167XjBDdfSZIKlw6px', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026300', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('4jOwBj77y2KuwiGcvJph', 'He9KHDlUYbSySPekGFJg', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025217', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('4tbw7OFE44jPybpfHRkK', 'IsCL3vTQeXTSRMyuwWva', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026250', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('5bY4kdiEzjWshxPZXFwJ', 'gXfkKqKwGOVJ9bhLZGcm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:44:25.288Z', 'INV-18024137', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('5qy7kk21NHYNl2n9ktAv', 'hq52JcQuzWyE7ojuBQB3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024177', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('5vylXC4HGtTLjOkVI4yv', 'GqqvPyog61G8jcCi6qbT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026263', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('6PMcKvmUlYGrcMOJpxh1', 'STfbHlW0F4Qc6z2PfWeq', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180215', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('6kY7JgWUD6BZ48X4eB0w', 'Ci3zzEDZvOdF9QXMrBib', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027331', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('6xqQvif0o9MgJiBo3tx0', 'L3sCd5TdYp76T5YqGAfb', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024173', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('7M8lkDNYW2r0vsIn2tMf', 'dB84LtekYpVvo5Y8q7ip', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026235', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('7O5L7zBPuIc6hwaR3Mig', 'fFy6tZpTGthwwuyOd95f', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802257', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('7jPhcAoFvfPlgSAJLLrK', 'MfQA1gr4fHd9PgUiBWEh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802227', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('7mt8E1SJTldnBloMh7wW', 'jJPGwhAqG1uRJPTkEEtD', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024126', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('86JrAAlcZ4nub7sP7OhW', 'McCZ05EwadK9FflCpTvX', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024112', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('8r1Aul7R65GvIz2phIzG', 'gspmPUc1vajf1yBmhIdV', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802397', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('915SDYzAp56cnGcsnFsY', 'D0UIg4bJLMRuXMzeo556', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027316', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('939heTi5885ainhpoudn', 'WJELCXeL6hw7tjG0kJFr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027330', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('9NFYpGlAtJGbSj1yTEm0', 'XcYpU7rlpC8b1ZnTupJN', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027329', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('9mlLB3T8ixjJ7xCm50nH', '1hzlVbVNUMFWLPthetoM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180210', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('9u9csq5WMUOTWmOOcgpR', '9WuOUKaRhFreosgTCNcl', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026270', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('A0GDc36ZxhfRFExEVUlr', 'qh4qhnEenvXX9U3z17Xi', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024138', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('A7VEMXHO0FsW1mMPx8Nc', 'qcc5XAFs1vhXTmKWD74O', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802248', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('A9NpXNxWSaQlOQRYULSA', 'nBTFUdCcCzIPexcB3InQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027320', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('AFscD1dQFaDX2xLnEKD1', 'IZK9kqVHJ0K4h5rACeFm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025222', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('AT89Pnqav9khHBArBIsa', 'e2U4h7YIXPoZG3y6D10u', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024118', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('B5N2yV62uzNTkTu5sNzs', 'VpTdJzeSlQ0MoecgfieY', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:53:05.338Z', 'INV-1802376', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('BBSqXvE4WSPHuBU3VEOx', 'DkZAxHAsZYOATAAxafZC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802368', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('BdZt19TizSlEczeU9plI', 'xD5hwucB5OGt1Zkonmh2', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026245', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Bj3hZatKIi9HVsfal2FV', 'VZBoXmIJ51OB7s4FqVsh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:57:14.487Z', 'INV-18025197', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('BkFLS7YPnS2adt8xF52r', 'sXgf34RabSiCRf35MHF4', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802398', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('BqPLUF0GwmT5X91MU9W5', 'L1f5N3rrL1Ft9gNjTt3X', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025213', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('C5PEBQnb5VZCSEjoHbW5', 'q05tDX12NXQSPDF1f9LM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024121', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('C8JX2hdaJDSasXVKfon5', 'DxHXWuU6C0XwgoFTAkqn', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027323', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('CFTgLLu1VDcwBGhsyYVB', 'M7VUmf3sFt8HcGctkjI5', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026241', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('D2eRxmGlKpxwTWsU1h5K', 'kPbNNHuXzEHktCPnUXZV', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802118', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('DS1IoOg5Q4rkoQmepVPQ', '9yYLk8J8cuuN0BVJbr6J', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026239', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('E67YVtevVG0UiNKShlex', 'IEPGEYkbr3m8hnPE6DnJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802256', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ESpvknUvIb52vGL33UU0', 'juH7HwbvCL5sLPsfh6yq', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:57:07.561Z', 'INV-18024132', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('EWREiiR2bYIRHIX53XQh', 'Kt9OQ4Py6ti8zbrIiXRZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:46:52.044Z', 'INV-18027326', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('EqKQk7JhzwwSPnsBJTYL', 'VcoivfRBX1kh5Pb3BybJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024105', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('FEH86hs04fKKjqEp0GDl', '2DAE21s8ojZbyhtoaBl8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026228', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('FFFnbtRx0400OgCiNbRw', 'yf5QwnkaMHR39wYpCEPC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026305', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('FTigzVwI9YWOlO314Q3Q', 'ONPf3kfHE9hxOs2QAEHUx1T1I733', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024101', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Fh25MgSxwhkFV3JhGLfM', 'VHJwtc1xigPY7kiAVmVH', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026226', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('FpxvohWtw9dpEjoKpczg', 'xFW64fTcGAs3WM9eBCBg', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:30.093Z', 'INV-1802262', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('GN4a3MhRTIRohKIO1DoL', '48uF1um6vf27U7K7h7uY', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026283', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('GNhCLVZku8InEW7SxJ6s', 'VCVIUbz3ujd0MxYXHqpk', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026278', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('GSY0W0g4mXfURkZRmJZ2', '8Bwc2W5KmXQDO1mjuAUu', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026292', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('GU2YGwhZnV6SoMMXX2Xt', 'hKC5mjsLlFjE466UA4DL', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180216', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('GYA7hqI3ZlXX0bv3qoGC', 'aDt4Sct3j771f0IRLk0P', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024147', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Guc2XzFtEHd3oZpEyPMG', 'MlPrZdR1kyFUd4nzNc9g', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024128', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('HWLv0852qyTpqnna8Mfj', '8Qlms8q6DAfvt151VbW0', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802373', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('HZCNkRMmIFRTPIcaK96Y', 'mpMLyr31WUyGhCldf7tV', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026299', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Hb0gobohQnecPDucGqIC', 'y7FJhBiM9fwZXIva1Fsf', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802252', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Hb745hNBKwWwSuz9CYNU', 'ueiikuVtrAEbHyyQX6x5', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024135', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('HfClaoJ2ToNmAMiyyuUT', 'wpNcpXsvDpHmnTDBz8BZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025187', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Hugsp87brDHo0G2ijAn6', '3yWOYpv705XTWg64y5BR', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802242', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('HyMxtXzUCeLPn4iPXkm8', '3oIhY0Z1ffyaTlf0n9DS', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:45.516Z', 'INV-18025214', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('IJvbFw4G01eNM06kn0wU', 'ldDq8WrXjGKqPU80ZPEA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802228', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('IMd8BSCFiYlNI8Vv7677', 'LJTz8CckCp0ftymtBXsB', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024178', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('IRAukqM5EiLvszhRVwyb', 'azPf8pg2mPotVeDPFDc3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025195', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('IUphgdhPeiOuTvb1Mke7', 'STfbHlW0F4Qc6z2PfWeq', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', NULL, NULL, 'BANK_TRANSFER', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-07-06T08:22:23.183Z', '2026-08-06', NULL, 'INV-43171', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Ii8c7JIpyfcJw211zoDO', 'u3BcWiCtbSjtWDtnqh8v', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024166', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('InBCl0KOcbQjh00PoF0g', 'fLGVrdn4ksY6q9CCwKML', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802119', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('JG4f0lHqdkEsOESbmyHd', '1Tc3sCOCRcwPS4HEhaSG', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026234', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('JIlfimrQW4zgbCcfGBeX', 'BQgNeAb2C3OgL6wMFFnR', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026307', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('JhxWWTE4F2wkKmKxXm2u', 'wFz7lCDO1bwkGpDuNvWd', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024180', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('JsZwRW4DsubRo3D9Hhqa', 'FV9px0kYYFH3PRUOMXqM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802240', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KEgKa5XsR1fpTLQ02Qj8', '31sZnVOqmioRXVxHCH75', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802249', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KMX5DjunDXujJQVPJSHv', 'bmtzfPJotNKUPAG3f8mZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802396', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KNVGTJkgUbS5zLrfaGxn', 'dtAzGSYEJUkYg77anjsg', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025220', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KNuw52KZEKO96QhGdZdM', '2RumRkBhxkV8DAzYDUEW', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802224', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KVMU1VUDWfBMrThlR96d', 'o5XUtMQL1BjrPzEPqkvC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026312', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KjQNoXGOIvQkbFeHuaHr', '1cood32XyZAcNAFzWNaD', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:57:26.020Z', 'INV-18027327', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('KmmURlx3xIFKNFik9zqL', 'Cos5YeyGnLfnWAj2kNd8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024167', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('L4s01hiDXOnIpe9aZRwb', 'kO1pXlZGJBSeiMgcM7zr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026284', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('L7amwCWVvjm8QgQ9YlRs', 'c5fPYIzTEJV9QyqXmyTJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802117', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LBhroli0Zgfdl5zyKbFX', 'vCUr6Zp24roLp4DtgNzh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:47:41.548Z', 'INV-18025186', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LIThe2FMZRlNK8k6sQew', 'lVJfQnyl4dsjc1yrwMIm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:31:39.170Z', 'INV-1802263', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LRpDIx3Q3HDr3Hj7E5Ty', 'IaVPNs3TVACwEAvNbnFj', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802243', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LWgbnBKbJDLlIJSftzW1', 'HSY5aiZkp975uAnIS8bU', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026273', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LiRHSPE1cN27l4e7hf0T', 'PW9RUVpr14ZQmgEu6INR', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026264', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('LqSE6PElj9mdiAa14dnk', 'i0vSb3mQ1MVAQonoA1ol', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026311', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('MCTvms2mGkKbyrcjmZNZ', 'baloZdBUihYwNiYFJBOZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802241', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('MLQn9jmi3EgzG83fKiGw', 'TUCzJRerBxIz0RTMwOpA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024120', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Mda97WikqZ3LhlotSbPd', 'ET5yJX7gjqUcOgl3omVV', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025215', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('MjwYINAprjR0n4hyxj8Q', 'kgBwCHzlHrPhYeJOohAy', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025202', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('N5gtaukMhSTfLswQw8Y0', 'SzP7qibmajk0B3opdFw9', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024117', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('NyRqzqcgQlOeb12qrJpu', 'M9vBO93R5u3KTREM6a3J', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802253', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('O9MTBgAqGjoqnfyn0ev4', '0MC93e96mxp9WCxT7w6W', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802230', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('OGUEvaIkIvrpGfthbbJU', 'PvThVwS5emuTfOBZmTES', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027314', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('OTG62jRYMa9MiNW4dxvt', 'cz54R9Wye2MZbrlUDO8j', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024182', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('OZdYguGPL9tdKvBWcZ5R', 'RB9D4MHqhXuWgckxAETw', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802254', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Ooahw65YqNj4vpVyRFQu', 'I4sSQqnkGoXV7rkyL9LO', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802380', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('OphnyWzjmmu7Nbf5fDmt', 'enVWNehAbTTSHTFZHGQt', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:05.380Z', 'INV-18024155', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('PCmuxveyV7nDWlR3NzFK', 'tCzSwzNW24VCnq6PsoND', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025191', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('PlumoUD9cdgscsSSocm9', 'g8l2DK6izNJcyPMsQjuW', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026308', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('QLieR0gPpAuJCDyo1kea', 'QEESN8Jn70gYWKprtIRI', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:15.696Z', 'INV-1802393', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('QafNnYvDR2LN7KIqiv6g', 'JSFKa8lyfMjFBGDhIeCr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802120', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Qc5TAQCP12g9NjgQ72Xx', 'QcLqwvbRhxfbY8bVpQTa', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:14.553Z', 'INV-18024119', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('QhR2e8tYZtwMzGbrOaHx', 'k5VRYvXfsZHTqNXxhxUj', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802110', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('QxSFmkGCNKUhcWrqZNkc', '2WULf3QDeUq7EO0fJW4X', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024133', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('RAJiEL8qWghnKocv4izt', 'sJKHokGb0uhPgKMaFHRd', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026291', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('RBycl5vKwsaomdm4TTu8', 'voX1pHUBMEY8rCGRfD3S', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026302', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('RCFOX3Y0zGtQs5q9r5up', 'Em9ZXasYPob39dFjtIcZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025201', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('RRy0lory1EapwhfBCEQo', 'sJd2d4sF9cLF2RRK3K8v', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180219', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('RwWTfTWqiLSrtR7zKTYa', 'qDWbPzoEyFWnA98VObJT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024172', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('S5lMZs7VP2BIvD5XDhgq', 'knczUTfu7mlhifNrGzp0', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802245', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('SBUMvNATrrmuMoRK89Fd', 'UBMpvy6wOX0ZvISCuWky', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802261', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('SJ9pQnxq1FOzP6HXh2fe', 'k4JRXOFJ9QMl2fgTASSc', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024179', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('SRWjszWeFAB49l43Gy26', 'Ezv32TUnQkZwAXRxApoC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:48:59.230Z', 'INV-18026281', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('StMvZCPxSjsMPJ9GRYQY', '51cgZtxNAIS11JdXa3MH', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026294', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('SzAeMYuOUzappga8m7hf', 'weI3AYPAX3PS5Yi6PyAl', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802246', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('T0tyHbZsVHLcue4tgnvq', 'MwNjfg7aBJO1psLMTBPN', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:27:23.731Z', 'INV-18024107', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('T809UZseFbtJdtYV5NcP', 'lStD3izI9J5DSb8yeMvP', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802226', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('T9n4y3bT175jA9CkGGtS', 'sFfOYgEDZoGCbNfmWUr3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802111', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('TWw4DdBKRBzwmc3ilcsn', 'Zv3kXoAi4XF6WtQtpztQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:27:29.365Z', 'INV-18024108', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('TbRhlIDT0DunN39l48ss', 'nObnJ43ITh0dte8wYwXy', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802260', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('TsWWWeM2u6DYpg7m2LR1', 'VbI1JraPZMj5lWU60Jgr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802231', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('TwFLkpwjD0xJQGtEL3Sj', 'fiB48X9bMu0WPwp22hRX', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026295', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('U2HIjZQ04MH74QlMPfGQ', 'oBTo1dc9kxwuQ9FMqdr8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802239', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('U8D9mxRpe9meiUYoKZN4', 'TVgGO6sYWKJ1Q8uhO4WA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:05.204Z', 'INV-1802389', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('UIEtFKT8QcjVI1RDEqXz', 'NR9lQzRMwQ3KOeJIePhv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025221', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('UQM1iUfILWgrgrtOqbMo', 'WTZNaEzcIy9F5K3t8bgo', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026261', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('UarLSbOV4F25YoVvC9lz', 'OSlO5H4aYsnXxgkBFYUA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024151', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Ul78QP4sBFMd99Szbyoi', 'NrfMYLxpQEilURz9TcyH', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:47:00.869Z', 'INV-18024145', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('UlKfoHnnLpQYJxLxJJ3L', 'Xu5CYGe8qcEveQrPAQPT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:25.419Z', 'INV-18026258', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Us3dq5qpjEkhL1Ykxwkk', '3ecT5TsyiVlr7LXVUFve', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802371', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('UtKu9ehd15rVnv96rVgd', '1d7IUQgwIFmsVYiQDLsk', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025190', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VHvvsKSddChcjMx3vxP8', '4cxQwWvZbVarhPEPBNSU', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802258', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VTLACgEEgPjyccOqWQAL', '9yDh1R5nJIsRiKayTdWh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:55:30.071Z', 'INV-18024127', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VYvruYaHfDhGRCQ84vgp', 'S9g8mwSAVsBd75I8rXPB', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802114', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VhTKnr8qOUIxFNuyATUW', 'z8cGQZrks4lnzYyHDcji', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027325', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Vpn2zPLjWF160tYTtzZn', 'pJQidcz8v959HhBcLNgQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024110', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VtCDZ91KLmXq1YCl1D9U', 'fnZHUKTvcVQVRGk8Vziz', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025209', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VtCgPPnTlFTi13HRFk0t', 'CdyLM5kDFSoFV2CeO4G3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:57:32.610Z', 'INV-1802121', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('VuZbY3I2bMkdYKueHGnY', 'v4TpRsZyxdUrYL9y5eO5', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024122', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('WFFvKtcUOwkjA1syOimF', 'OCDmO5OiIb4ZUacvrYER', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026268', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('WJy9zqyoVHQLyIrFj13f', 'iUYnOvuzRHve9tBEFI4M', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026260', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('WKMVQE5qh4iNAbK1nENv', 'qkOjbzA3UUasQ1OWicZj', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026238', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('WuFYlRy94KO3lWkbKt5Q', 'wLQaT8bHRyyUuX6SFvn1', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026237', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('X7ohLu0ebPVtxzUXTuBv', '4b5kMHESudrLVLfSAj8Z', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024185', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XWVauYwLVWC2IX8sm1Xv', 'PSvXjLcBxPwoZb4LL7gl', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027319', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XdS4cLyiKf2Mt0V9NeRB', 'tVHGe9fBvoAYX45J3PO8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025205', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XdhlFsmoQW28CiNDMPQh', 't3N4ybGWXVmnoEmTccrQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025207', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XnbHlkVWLnQhkAQKdui1', '4o5UJA4BHaH2ed6OWqcH', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180211', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XqJw6CDZBweOaVwyfBb2', 'xTqfkN32928h3M681DaR', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024104', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XsyZaRMZ2TavAdwqmxBb', 'mB6wGvCik9UBrzPBeHzK', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024129', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Xw9suNgfRpHmyiqZlu6F', 'KeuRSVn5ssZLK4VWS56s', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025225', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('XwfqS5WZNiLMoJBu8213', 'IpWg8ndsxT64Y9bEsg9r', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026280', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('Y9UVp1ylS5b4JYZnNn3c', 'X0r7nhiu9mRtCYVIK1Oa', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024153', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('YIjezHyKLvCPNnYUZfb2', 'TxpiVYmYGuZiwCekIJ9Y', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025208', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('YwAm4TYd1wjbCe1Z0Hfz', 'cFmdcJsduMmhq6Q94ACE', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024149', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('YyeVCbRbU7CD2eY6pumE', 'X766pg56mh12wTY3nz9P', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025189', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ZFGhmilY4fVmb4LztIo6', 'Z56zAITbJQxHxcW74kjz', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802250', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ZZKec7kXssaHVztZeJ56', 'cAOLJ37MpqmIjPLbh4LS', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024170', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ZmkqlwXmzxTy8dU5iADZ', '7z3UvImOckQUgJ7p7u0w', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802225', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('aSx9FATrQcd5NRKYFqEC', 'pyhNZ9mpxdHkXe5V4olA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:20.136Z', 'INV-18025188', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('aevwpWLkUpdhLRoAB7Ri', 'lzKhkxTRWCaV3syqrAwZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024139', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('afjwxv1FaFiaNaWLbAEJ', 'lwILNbCkR1nzybOpEhiv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026262', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('atObJklHRK0t8S7L0gqN', 'E3gjfIRq45nTkRhrYHoo', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802375', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('b6yLUQCfi4zL6OkkjdNL', '8eUXaZARc8Zkg9YEMWEm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024111', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('b9nCdpEjmf043da0GUqt', '0UkDNhlytOBDmfzeECb3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026231', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('bFOFXBXlRXUnAhnGAOh8', 'wzqSKKX3aWUWsq7jKnNx', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802395', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('bGPmD484TsRVVX1Y4FWW', 'zYO57Q2THaRKV7ysgpXd', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802229', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('bUloh7RIkUqNYFkBSvyR', 'SLBLQkcMRIrfTnvHTx4S', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:52:34.238Z', 'INV-18025223', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('bcswO0PyXUnPnfJXHHSG', 'iPw85igZazPqFOckeffr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026285', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('betUgv5XMtUx1H8nGGkX', 'Al25LEEha1gT4FIsYJRJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:45:38.470Z', 'INV-1802113', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('bfEnSO4iCEnoe8cj5fXj', '8V1dESaLZ5yYJmcclB0n', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802237', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('biVqvLqyQwAqXVD4jgLC', 'gNjAnUTHONc7x6lUfvLI', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024134', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('by2xzYZcmbi2t1SHlqFE', 'u9O3sJ4748EPhxFx2tdX', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:52:51.638Z', 'INV-18026287', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('c3KWPpjqIq3S025cBWhE', 'TcuZgeqnmScuIgY65v9R', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802388', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('cd96RMxYJuWm1lAJGblg', 'DBsM9FjPdmhQDiouWaD6', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:47:22.671Z', 'INV-1802264', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('cdEieV7QI62PcbD9uAhv', 'MtyvvSUgUKBWAnZBlbg8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802372', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('cdrZkm9ozHQNxRtOKRT3', '03iU2zILAfwx9bRHG5by', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024143', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ck52pmPJgK4TQauvvf2r', '2mVjGUNqllvbXylTy2lp', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026304', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('csRoHOWJ9N3cfpIAoJkU', 'ImrR7ngwv3Of6NTvjN3P', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026303', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dF00ObIsSnFNWQhnelK4', 'oqjryv7UmwaDVrbiRkvE', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027333', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dL4RwXgxXP0Ymz5pXTEi', 'EmGI4k0TWgt9e3oMhHAg', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024141', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dMLQXM2devbjWJsJngAU', '8cFwmUVzLg3VraT34mg7', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026277', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dQRi4SCiunPklEMVqrzf', 'zEwGIgKUKe3irn5RPy95', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024161', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dYcl4ExnRLoiWX3Pmtlp', 'dH9ChvriRcPvIHWN0Ez0', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024150', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('dwYOD2e22UlZshFwticQ', 'Buz0rVrzGNqWQNYvlw9X', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025206', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('e0UgXPq5ufjrGbwNSH0e', '8M0vGBwrrg0c73Ummxx9', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:32.695Z', 'INV-18026275', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('e2l5CtdoXaHHae9yh9Ys', 'z1TxKlv4OUiJJQR42tLo', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026253', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('eIwBr2szUBmoLMR6c96W', 'DNVIhzRIBnom4WBufd9M', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024130', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('eQmfYOH5IIy59H9kr4M1', '8u7nUlzjqwDjfJZv6Llb', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026233', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ej2FsfZympPuY2ryzFxw', 'aSnlTg8BoVRshmxIRTFa0O7H7Ov1', 'koretini', NULL, 12, 'EUR', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026252', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ekVLT3EMSuegvOUBACTM', 'sRT6MkRE1iQXTsdGXJdx', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802116', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('eveUiNP1PjeVlaDxc8mR', 'roPmUmC83iYMQWBIqAs0gFevqi43', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024103', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('f6fW7EPiNASqfifR65xP', 'SvmLML71g9Vv8BQlrCyr', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025204', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('fFeKinlaD96P2pHIIrMt', 'rqFXoHunBYmqQHEm3HFM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024168', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('fQFuXgjKqEMYMdTXwwy0', 'WaLVaVyWJamWLir1Wxcj', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024159', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('fXfCqrrxosknX7iiKWBp', 'YgZpBcMrodXDoP4Ao7Jb', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024175', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('faoNxN5Sosq8oA8oOsaT', 'sbKbyfjUakRBYpMnXiJv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026306', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('fvbcKwFJPfYYJnEyciR8', 'AhQWaLqTMSC0DoTQuPbo', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:52:58.122Z', 'INV-18026249', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('fxV6jsdpCCEA71LGx1id', 'ijJ9SKJC6QVc3mfyLFqF', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024114', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('g2vg8z5fwoSO7yWd9j15', '82ZF7YehBm9ifbMQ0Lx0', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802386', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gA2W3ahW3CSiUXVCUg1k', 'UsgJPXQLrYcIBfdy4K5x', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024144', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gDI8wJyq63HJQgZYWijE', 'GhagEi29IvsRrZ0QKAEu', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:44:55.435Z', 'INV-180214', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gSddonJvKITXBQ2kpYDz', '6C95LfLoTDXyj5EyKKVT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:30:21.075Z', 'INV-18026274', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gcHxbKA9cyOpp2vuC3oA', '6aB7Z5j7SsHQeyZ0eZ46', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024176', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gmwOgwpGN2xwmiDb5FLf', 'FfknNzhDjFPVdibRurUJUnRWwAv1', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025203', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('gtfY8LqlfK7IfmT3muss', 'VlqQjajlzaX3WniMnTLh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:47:30.031Z', 'INV-18026266', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hH8lAuh9ZxrLb2b9jcKK', 'UBn9fR6uWhSw7NpH4Ufv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026251', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hHT45Kc3wzVJn4YcysN5', 'GjfXekIjRbaByyXZ0SCp', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027328', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hIcz2MMTOjNJOPHDQdlu', 'ez0srtZX40JQPXlxPQs7', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180218', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hK3s1EwUjjlmE7tRa1VT', 'jpSwqs33Bc8DMVJZk6le', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026244', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hZkwLZoM13QrPggKiRJq', '42v5LNTU4fYJGixxTHEY', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026290', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('hh77HaRSDnglZAHNGJmU', 'vDYmsQ6f7WKjbLr3aeVw', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802394', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('huaRbsHDJoZQLb3cuEd7', 'Rg9wjHdvfYsts3ALmjTq', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:56:48.912Z', 'INV-18024169', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('iAPJfVZBBmyapCudAGpd', 'fPQv4e2RShLC3KSx58IC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024152', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('iD2IWUDgxrjQPfBCGQOX', 'JgBNtkKinN1fCIm0oVmg', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025194', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('iIuTHXRCkn0IAlmdxGzk', '5eHrEc5QUwJ0cZFxRYGv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802390', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('iMwhB6VqAjc1QqP7sn0o', 'Re6x5Yo2wqbPs60i3acB', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026246', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('iNY7Fd6QjJ1zR6YEozie', 'DajkkpvkzCNYNYZdviBi', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802385', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ipdAPaPFvQzVb80hYCaR', 'X64uwaxbbcRxO5iy3zfY', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024156', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('is3NTZVqCd2p7M0rECsM', 'YEHY8aXyxc3S1xKZXSxf', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802251', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jD8DDU0OALTVm4vZICVk', 'VOVXinWYpiNCNUR845Eb', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802367', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jMqI81QxJ0ygebruNpql', 'yVXS6QeI6uNKZS3bJPKm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026229', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jghrTZungwL3mBTiFlBI', 'R0FxDqP3Mz2AilTW0YSK', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025219', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jhysAZZvbicmtFqbZmbb', '8XjP4qPooH6NWT4Yk3Xo', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024154', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jl0Lo9o5RheWWN36HnUN', 'wnuNMO8sItnL4rOvgL60', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:50:01.895Z', 'INV-18024171', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('jyVD1ruZwyU1taSFbmv6', 'Ix564uPpVheeTgX6iQsP', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026247', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('kTj4aY2KRmdLV1mAXe4K', 'utBQFVLPbkwkZWSz5lzh', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802122', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('kVBTG4X6c87ARz6Yo6Fr', 'SYW0nRBhtusknVuiBCC5', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027324', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('kaNOhniFhHO65pgG4sAm', 'Y1rdpnxCKXGRQZSVAkV0', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802238', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('kfa3GYGyPdJPkIn7KpUI', 'fk2N7zCXnsoq4mZYbVHZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026232', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('kxLqWvqiuERKQAQDK267', 'NVkCW6LCZD7rLfOSSCqm', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025200', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('lI32L5Kqg6TN9bnvOJI4', 'TDxwEOzt6nEcRJzUmjA2', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026288', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('lX2wUkqrs3svHfs9YflM', 'TzSd8IkvjcZEdTot5ltK', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802244', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('liLfRRhDBDiJo6fSjsUb', 'IzziI1TFNxohutfElKYK', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027322', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mDM4wRPV70LCj5aHNGTV', 'roR6qlrgu2mA2M6EFjjT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802233', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mKz9PdKQ613wPllgdVXK', 'I8wrqkzTQWgAJmPZ4sPc', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026230', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mPriDvntRdy1BR7QUI5N', 'BF96GzVIjRxVLx6PCL9R', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802255', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mTTRU3XyplrU2dFdq79Y', 'j6Mr6fz3gwS2s0QbDVOk', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:50:16.155Z', 'INV-18024163', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mWJhXLgHKMX5oaALbIRm', 'JQRxKs9EH2q7UsTbv2wG', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802115', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('md6ofowjWAdKi0QW1QnL', 'ogFvzASUQir5j2YoE1EU', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024183', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mm5dnBXUSgsfaPmd9Ucr', '2WC014kNRzoqN7TPJSjZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026289', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('mxFJ464dA0vdoDjubxNT', 'T9x7H684rNFe1jVAq0qu', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:30:07.809Z', 'INV-180213', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('myAeuJJHW9uZmcouJHav', 'u3MtMamZG5KJ5r9bk88c', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802236', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nCAMKxrehqrJ8RD9CriQ', 'OJ8aVTDvEP9Av2wteNTT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:23.188Z', 'INV-18026243', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nQ2Y5qCrOAEgGP5MLATj', 'HwHbZEkIKLupFqJzPUNe', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025216', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nTfX1PaQZuZ99g7cnuHe', 'uxb6SxyF0hYxEmeAvAc4', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027318', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nUc6pgonObDsI8FZmUjR', 'jAimYGm4Ss4jz0gJ1m6r', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026227', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nb5yDR4UHLQKheZMmy2k', '4HZb0IRntqM21sdDLnRW', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025196', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('nko1P4MhwYnOL4VC21bk', 'INNNUaqTMpdvTn0t7P7Y', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024140', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('o9KKOZNq8Yiq88wFxqP0', 'lzKkQIrVSE5NtjReGqwz', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026293', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('oUC4gjBfoOsBVj4TLWmN', 'D7GyjnfLe7gwUEInO4Ry', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026256', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('oWiztFHL5UioqwiOuKtC', 'yoZcFlXGoygiWBJ6fSk3', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024123', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ofmIGCJCwMNwjrJjOpTE', 'Gj9ZzlWhmFUAr88G1b6o', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802383', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('okuk5AbMEE1Lu7VymytN', 'cVRzr60NBf5NEx3IXdd8', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026297', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('p0QW6NPKi4fwYuO4Oz9r', 'h1WJwMVgwX3rnT6wEDpS', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802232', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('p5bpfz168HGhkbElnzl6', 'hSXl68mMxzERBwe8xild', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802370', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('pR7NXMQoeJUYGyCZdL0F', 'eGJWf0hHGvql9CvwgpQf', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802378', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('pRQZN72ENNWQ58SsHp5E', 'FtcZaPSphSgueipvsc0N', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025198', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('pZHE6a2GpY4bQYmrqilp', 'Y3zDRDVjHilAvTLtf3z5', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:27:18.165Z', 'INV-18024102', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('pqavAHFT1RPkzUsm53Io', '4zT9ZMsxmYXlAJJlA9fv', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802392', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('pvV0Bet3TPzKpA3whnqN', 'ePuogryKItgLRk9bbyLd', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027313', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('q647Vdsz6FDd7xQthlTC', 'h1M4FBpjtYNNQ6qttVHQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024142', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('rBukypjTo6jOqo8broS2', 'dgPH59PmTyWYAWSYT50U', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026265', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('rRONit47ggL6TLpsKEDX', 'EmnWwWQFxPqU79HJikBN', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802259', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('rhd6e13KnMPElubnI620', 'qB5Ss9IexEa7uvbqzvsU', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025192', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('row61gVvlToR7j5bUrjt', 'T5F7oUOHiZ7Pw253hHrC', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802247', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('sGnCWRdVMQdxTQ9ZVcZB', 'QzCEWq8cIqjYRDT17eph', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024165', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('sJgGX2Dk6z5F5Y0okYdB', 'HpffhxjQnzWd6JN5p7hA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026282', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('sOYGfgGEcYSHpiAbXPtO', '9663gXA0EWQk37CP0h5e', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025193', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('sUi2tqDgEDXiNZHGqnYU', '6FXySaqFXmYbfi6AIPMG', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026267', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('sWrKppXczGjjsgFwTzBs', 'WmuWNgt09dCvVqPUB43f', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024157', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('scTEkKgizxxfP44D3Ngi', 'aqlvECv18d2owx5byMAQ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024124', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('tFK36WY0CaNsVVn6spZ3', 'FH57gJ0zBbysqGKJhEmt', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025224', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('tI5CwWi0EvebFmyZBa4Y', 'SUJQQHdVzN9TpKBfahtX', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026240', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('tbdumzvKOxzPZLkQp37M', 'Bey4HIPbdn5UrEjMNIwa', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026259', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('tvLi2TGC8jFyyQCCWZsR', 'mRyJKgPKKH6MXzc3xW1k', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:46:19.753Z', 'INV-18026254', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('u5KIlDvhi6aiad9QtSmZ', 'XHmkQS1qxTYrWbodABIT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026242', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('u6jvPE4SrCvBduJFOd7W', 'IKOrUtLEi7GTTmhOjO8v', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:51.593Z', 'INV-18024146', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('ucNaKvVPyZQ92ePolvmK', 'H0O1jkaV7Y42DfZJ4jT9', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802235', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('udH7seUcgHBW3ZuQg8ez', 'GWThXpt70WV9OjPE2dBW', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026236', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('um3XwhXlrP1ME9EHFHpZ', 'SXhUYmht8hWyEVljQgVu', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024181', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('vHyP19l7dosZT5glCxBJ', 'IExmKTnTcwOHOCfqh35vFD1MMJ03', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'BOTH', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024125', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('vOCiSvjVe5Ojz2Ei9Zj5', '8PYheyvBtuvlyDmCImhz', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802384', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('vZTwUqDON4Ift4CU5oxH', 'XbquKjw3hQfsXKzDicJd', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:54:31.638Z', 'INV-18024131', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('vaajHt9dRhSw0KY0SmyR', 'YdSde2UMgRFMv9DTE6BN', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024136', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('vqbiyGZAbLYCprazv3qV', '0MCyPLaxv7IOysyXU0zZ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:30:00.642Z', 'INV-18024184', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('w6KO6cHXsbcKttSCImwO', 'MvjLtVaVngwvkAG7cflH', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18027315', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('wSQYhJw3BuUIqVtpk7xt', 'HVcxGA5QUB40Hulq1LUM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024115', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('wheb0l1lxOz4rQIThHMt', 'JJlUD5j3f8BrVx9FMa72', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802382', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('wl4SQJoRjmLxWveJBXZb', 'RBrmE8kSVarXcTAV418n', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025218', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('wntp8WIR4cEoHAFMIFAh', 'lwVAUKKcefK2yrwGLQX6', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:47:18.419Z', 'INV-18024174', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('woySJTeAnQXbckiBiFBB', '8kPpeuV9whAAHYphj91r', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026272', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('wqrSvaFjjZbahpGFS4bd', 'pCiCcSL9H2uVhNV4Afja', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'PAYPAL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180217', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('x1N7dxWursFEwVATkAsX', '6Fa76JhLPTdm3unl49Yi', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026296', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xAq1kX4tppXUArY44H4F', 'sxdy5VdFc7ZkpRS7itqn', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024116', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xJ6d8epqp0oyGhegl0v2', 'RwFsXYFa4LlLXSs6TgIP', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802369', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xdSlPJ1hVayQ4eIS2pn1', '3tTHJOdwxqle87zsQVpJ', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18025212', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xuAdjr3qFcdFiQRKt4R4', 'pFHjA9maRDL8fqOh8tnR', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-180212', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xvktNcqlYxmlm3wjG2hs', 'gcRJWkK4JO725Zl7w8I4', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024158', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('xww9eqZr3sIECvHGSRB1', 'uwerd76arUMGZKKhrttA', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026271', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('yKByVE6lMGy4fipXovYj', '5S6UJNgWgXmXZ8BtlLR7', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18024109', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('yeSlmnQJeu4TwC3Od2Ij', 'EkVDBv0JQjrrBbwG9VzP', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802399', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('yhddRCSAkVwfJ4IqLp4q', 'i6wSfJ5ImDENSKbiDIjO', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PAID', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', '2026-07-05T07:49:39.070Z', 'INV-1802381', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('zIP8X0MAjX0vUn6uB6Vv', 'dZT2D2UHna4cZLkf0oNO', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026276', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('zPk0Sl6nuJqLHGUHDLdA', '8LrpZ4k0mLI3fZEmNpeM', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802112', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('zYSmmPwTYRxkEXGenikv', 'sp7BvH0YSeJwyctr1SLS', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'QR_BILL', 'PENDING', 'POST', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-18026279', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

INSERT INTO "payments" ("id", "userId", "tenantId", "neighborhoodId", "amount", "currency", "type", "invoiceType", "billingYear", "customRecipient", "method", "status", "deliveryMethod", "scheduledDate", "dunningLevel", "lastDunningDate", "timestamp", "dueDate", "paidAt", "invoiceNumber", "description") 
VALUES ('zh0bNLzWPYHE9MN1O42P', '5w6hsOtD4QgPBJHiE9YT', 'koretini', NULL, 120, 'CHF', 'FEE', 'MEMBERSHIP', 2026, NULL, 'GIRO_CODE', 'PENDING', 'EMAIL', NULL, 0, NULL, '2026-06-13T18:36:58.575Z', '2026-06-30', NULL, 'INV-1802266', 'Mitgliederbeitrag 2026') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "tenantId" = EXCLUDED."tenantId",
  "neighborhoodId" = EXCLUDED."neighborhoodId",
  "amount" = EXCLUDED."amount",
  "currency" = EXCLUDED."currency",
  "type" = EXCLUDED."type",
  "invoiceType" = EXCLUDED."invoiceType",
  "billingYear" = EXCLUDED."billingYear",
  "customRecipient" = EXCLUDED."customRecipient",
  "method" = EXCLUDED."method",
  "status" = EXCLUDED."status",
  "deliveryMethod" = EXCLUDED."deliveryMethod",
  "scheduledDate" = EXCLUDED."scheduledDate",
  "dunningLevel" = EXCLUDED."dunningLevel",
  "lastDunningDate" = EXCLUDED."lastDunningDate",
  "timestamp" = EXCLUDED."timestamp",
  "dueDate" = EXCLUDED."dueDate",
  "paidAt" = EXCLUDED."paidAt",
  "invoiceNumber" = EXCLUDED."invoiceNumber",
  "description" = EXCLUDED."description";

-- ---------------------------------------------------------
-- Data for Table: accounting_accounts
-- ---------------------------------------------------------
INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('1000', '1000', 'Kasse', 'ASSET', 'Flüssige Mittel', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('1001', '1001', 'Kasse EUR', 'ASSET', 'Flüssige Mittel', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('1020', '1020', 'Bank (ZKB)', 'ASSET', 'Flüssige Mittel', true) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('1021', '1021', 'PayPal', 'ASSET', 'Flüssige Mittel', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('1100', '1100', 'Forderungen (Mitglieder)', 'ASSET', 'Forderungen', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('2000', '2000', 'Verbindlichkeiten (Kreditoren)', 'LIABILITY', 'Kurzfr. Fremdkapital', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('2900', '2900', 'Vereinsvermögen (Eigenkapital)', 'LIABILITY', 'Eigenkapital', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('3000', '3000', 'Mitgliederbeiträge', 'REVENUE', 'Betrieblicher Ertrag', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('3400', '3400', 'Spenden', 'REVENUE', 'Betrieblicher Ertrag', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('3600', '3600', 'Erträge aus Veranstaltungen', 'REVENUE', 'Betrieblicher Ertrag', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('4000', '4000', 'Materialaufwand Events', 'EXPENSE', 'Materialaufwand', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('6000', '6000', 'Raumaufwand', 'EXPENSE', 'Betriebsaufwand', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('6200', '6200', 'Fahrzeuge / Transport', 'EXPENSE', 'Betriebsaufwand', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('6500', '6500', 'Verwaltungsaufwand (IT, Porti)', 'EXPENSE', 'Verwaltungsaufwand', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('6700', '6700', 'Werbeaufwand', 'EXPENSE', 'Werbeaufwand', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

INSERT INTO "accounting_accounts" ("id", "code", "name", "class", "category", "systemAccount") 
VALUES ('6900', '6900', 'Finanzaufwand (Bankspesen)', 'EXPENSE', 'Finanzerfolg', false) 
ON CONFLICT ("id") DO UPDATE SET 
  "code" = EXCLUDED."code",
  "name" = EXCLUDED."name",
  "class" = EXCLUDED."class",
  "category" = EXCLUDED."category",
  "systemAccount" = EXCLUDED."systemAccount";

-- ---------------------------------------------------------
-- Data for Table: accounting_journal
-- ---------------------------------------------------------
INSERT INTO "accounting_journal" ("id", "date", "description", "debit", "credit", "amount", "timestamp") 
VALUES ('FYF8sKvetrjnJmqGZ1px', '2026-01-31T18:25:15.052Z', 'Zahlungseingang: Mitgliederbeitrag 2026 (INV-905237)', '1020', '3000', 120, '2026-01-31T18:26:58.667Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "date" = EXCLUDED."date",
  "description" = EXCLUDED."description",
  "debit" = EXCLUDED."debit",
  "credit" = EXCLUDED."credit",
  "amount" = EXCLUDED."amount",
  "timestamp" = EXCLUDED."timestamp";

-- No data found in Firestore collection: "expenses"

-- ---------------------------------------------------------
-- Data for Table: events
-- ---------------------------------------------------------
INSERT INTO "events" ("id", "title", "description", "date", "location", "image", "createdAt", "limit") 
VALUES ('lPMc5hncKWlf5pmIbMH1', 'Dita e Diasporës 2025', 'Një takim i madh për të gjithë bashkatdhetarët në sheshin e Koretinit. Muzikë, ushqim dhe shumë surpriza.', '2026-02-28', 'Sheshi Skënderbeu, Koretin', 'https://firebasestorage.googleapis.com/v0/b/shoqatawebsite.firebasestorage.app/o/events%2F1769857431425_logokoretini.png?alt=media&token=f6852e40-8f5a-432e-b298-81a1ded0b8d7', '2026-01-07T20:37:03.539Z', NULL) 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "date" = EXCLUDED."date",
  "location" = EXCLUDED."location",
  "image" = EXCLUDED."image",
  "createdAt" = EXCLUDED."createdAt",
  "limit" = EXCLUDED."limit";

-- No data found in Firestore collection: "event_registrations"

-- ---------------------------------------------------------
-- Data for Table: news
-- ---------------------------------------------------------
INSERT INTO "news" ("id", "title", "content", "image", "timestamp", "author") 
VALUES ('2AjbBmBLXIoMz3Q8Qm5S', 'Përfundon renovimi i shkollës', 'Renovimi i shkollës fillore ka përfunduar me sukses falë donacioneve të diasporës.

Nxënësit tani kanë kushte më të mira mësimi dhe salla të reja kompjuterike.', 'https://firebasestorage.googleapis.com/v0/b/shoqatawebsite.firebasestorage.app/o/news%2F1769860577258_logo-koretini.jpeg?alt=media&token=098f2068-c7fb-4c9e-a123-c72739109180', '2026-01-07T20:37:03.711Z', NULL) 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "content" = EXCLUDED."content",
  "image" = EXCLUDED."image",
  "timestamp" = EXCLUDED."timestamp",
  "author" = EXCLUDED."author";

-- No data found in Firestore collection: "security_logs"

-- No data found in Firestore collection: "polls"

-- ---------------------------------------------------------
-- Data for Table: inquiries
-- ---------------------------------------------------------
INSERT INTO "inquiries" ("id", "subject", "message", "email", "status", "createdAt") 
VALUES ('jxjTWXdu33ocKyLdocyt', 'fdasfafff', 'afsdasfdadsf', 'Burim Dervishi', 'REJECTED', '2026-01-14T08:38:53.038Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "subject" = EXCLUDED."subject",
  "message" = EXCLUDED."message",
  "email" = EXCLUDED."email",
  "status" = EXCLUDED."status",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "inquiries" ("id", "subject", "message", "email", "status", "createdAt") 
VALUES ('ke1YSHEp91gBnb99TPST', 'fdasfasf', 'safasfasfasf
adf
as
f
asfas', 'Ledion Dervishi', 'OPEN', '2026-01-14T15:34:51.954Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "subject" = EXCLUDED."subject",
  "message" = EXCLUDED."message",
  "email" = EXCLUDED."email",
  "status" = EXCLUDED."status",
  "createdAt" = EXCLUDED."createdAt";

-- No data found in Firestore collection: "tasks"

-- ---------------------------------------------------------
-- Data for Table: board_members
-- ---------------------------------------------------------
INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('5hEQYTP3NBt8jWr7zt8X', 'WmuWNgt09dCvVqPUB43f', 'Koordinator', '2026-01-31T11:07:50.073Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('6QXRW9anLsnJSukNVA2z', 'pyhNZ9mpxdHkXe5V4olA', 'Koordinator', '2026-01-31T11:08:54.681Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('DBLg7bAVRNjQu396SJW5', 'lVJfQnyl4dsjc1yrwMIm', 'Koordinator', '2026-01-31T11:07:38.445Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('OjEcBBOA0G158C0WnJ1y', 'IzziI1TFNxohutfElKYK', 'Präseident', '2026-01-31T11:07:25.529Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('gKcbXJ9OUcTqNJx8PbJE', 'Y3zDRDVjHilAvTLtf3z5', 'IT', '2026-01-31T11:09:59.183Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('jKE7M36F37kFYj9z6m5f', 'uwerd76arUMGZKKhrttA', 'Koordinator', '2026-01-31T11:11:23.249Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

INSERT INTO "board_members" ("id", "userId", "role", "joinedAt") 
VALUES ('uwZrRwjLZkBnyjS1ivDv', 'aYzZOk2xpBoMWEdG4kPJ', 'Finanzen', '2026-01-31T11:07:02.719Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "userId" = EXCLUDED."userId",
  "role" = EXCLUDED."role",
  "joinedAt" = EXCLUDED."joinedAt";

-- ---------------------------------------------------------
-- Data for Table: board_meetings
-- ---------------------------------------------------------
INSERT INTO "board_meetings" ("id", "title", "date", "boardMembers", "decisions", "createdAt") 
VALUES ('BAY8RPzSn3j0YmzVu1vG', 'Mbledhja e Kryesisë', '2026-02-01', '[{"userId":"IzziI1TFNxohutfElKYK","name":"Valton Rexha","role":"Präseident","present":true},{"userId":"WmuWNgt09dCvVqPUB43f","name":"Gazmend Mehmeti","role":"Koordinator","present":true},{"userId":"Y3zDRDVjHilAvTLtf3z5","name":"Burim Dervishi","role":"IT","present":true},{"userId":"aYzZOk2xpBoMWEdG4kPJ","name":"Sokol Axhija","role":"Finanzen","present":true},{"userId":"lVJfQnyl4dsjc1yrwMIm","name":"Bajram Shillova","role":"Koordinator","present":true},{"userId":"pyhNZ9mpxdHkXe5V4olA","name":"Ismet Klaiqi","role":"Koordinator","present":true},{"userId":"uwerd76arUMGZKKhrttA","name":"Rinor Kallaba","role":"Koordinator","present":true}]', '[{"id":"ghq90jyco","title":"Mirëardhja","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"pbf8to8qi","title":"Përcaktimi i detyrave të anëtarve se kryesisë","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"oxknzfilw","title":"Gjendja aktuale e llogarisë bankare","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"2ypdhe39e","title":"Të dhënat e reja bankare","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"sfq83bf3x","title":"Shkresa për pagesën e anëtarësisë 2026 (digjitale dhe analoge përmes postës)","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"yr8m043az","title":"Aktualizimi i adresave – detyrë për çdo kryesues / përfaqësues të lagjeve","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"ri2j0gdhr","title":"Hapat e mëtejmë","responsible":"","dueDate":"","content":"","linkedTaskIds":[]},{"id":"cjal5kxiv","title":"Përmbledhje rreth turneut të futbollit 2025","responsible":"","dueDate":"","content":"","linkedTaskIds":[]}]', '2026-09-04T20:34:14.238Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "date" = EXCLUDED."date",
  "boardMembers" = EXCLUDED."boardMembers",
  "decisions" = EXCLUDED."decisions",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "board_meetings" ("id", "title", "date", "boardMembers", "decisions", "createdAt") 
VALUES ('Kd3NedPorvyvqnCQKDWa', 'Mbledhja e Kryesisë', '2026-02-16', '[{"userId":"WmuWNgt09dCvVqPUB43f","name":"Gazmend Mehmeti","role":"Koordinator","present":false},{"userId":"pyhNZ9mpxdHkXe5V4olA","name":"Ismet Klaiqi","role":"Koordinator","present":false},{"userId":"lVJfQnyl4dsjc1yrwMIm","name":"Bajram Shillova","role":"Koordinator","present":false},{"userId":"IzziI1TFNxohutfElKYK","name":"Valton Rexha","role":"Präseident","present":false},{"userId":"Y3zDRDVjHilAvTLtf3z5","name":"Burim Dervishi","role":"IT","present":false},{"userId":"uwerd76arUMGZKKhrttA","name":"Rinor Kallaba","role":"Koordinator","present":false},{"userId":"aYzZOk2xpBoMWEdG4kPJ","name":"Sokol Axhija","role":"Finanzen","present":false}]', '[]', '2026-09-04T20:34:14.238Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "date" = EXCLUDED."date",
  "boardMembers" = EXCLUDED."boardMembers",
  "decisions" = EXCLUDED."decisions",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "board_meetings" ("id", "title", "date", "boardMembers", "decisions", "createdAt") 
VALUES ('UKquc9JXrEx1wB0KAWz3', 'Mbledhja e Kryesisë', '2026-07-05', '[{"userId":"WmuWNgt09dCvVqPUB43f","name":"Gazmend Mehmeti","role":"Koordinator","present":false},{"userId":"pyhNZ9mpxdHkXe5V4olA","name":"Ismet Klaiqi","role":"Koordinator","present":false},{"userId":"lVJfQnyl4dsjc1yrwMIm","name":"Bajram Shillova","role":"Koordinator","present":false},{"userId":"IzziI1TFNxohutfElKYK","name":"Valton Rexha","role":"Präseident","present":false},{"userId":"Y3zDRDVjHilAvTLtf3z5","name":"Burim Dervishi","role":"IT","present":false},{"userId":"uwerd76arUMGZKKhrttA","name":"Rinor Kallaba","role":"Koordinator","present":false},{"userId":"aYzZOk2xpBoMWEdG4kPJ","name":"Sokol Axhija","role":"Finanzen","present":false}]', '[]', '2026-09-04T20:34:14.238Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "date" = EXCLUDED."date",
  "boardMembers" = EXCLUDED."boardMembers",
  "decisions" = EXCLUDED."decisions",
  "createdAt" = EXCLUDED."createdAt";

INSERT INTO "board_meetings" ("id", "title", "date", "boardMembers", "decisions", "createdAt") 
VALUES ('mxCYaUl8wiONPsEQIhT5', 'Mbledhja e Kryesisë', '2026-03-29', '[{"userId":"WmuWNgt09dCvVqPUB43f","name":"Gazmend Mehmeti","role":"Koordinator","present":false},{"userId":"pyhNZ9mpxdHkXe5V4olA","name":"Ismet Klaiqi","role":"Koordinator","present":false},{"userId":"lVJfQnyl4dsjc1yrwMIm","name":"Bajram Shillova","role":"Koordinator","present":false},{"userId":"IzziI1TFNxohutfElKYK","name":"Valton Rexha","role":"Präseident","present":false},{"userId":"Y3zDRDVjHilAvTLtf3z5","name":"Burim Dervishi","role":"IT","present":false},{"userId":"uwerd76arUMGZKKhrttA","name":"Rinor Kallaba","role":"Koordinator","present":false},{"userId":"aYzZOk2xpBoMWEdG4kPJ","name":"Sokol Axhija","role":"Finanzen","present":false}]', '[]', '2026-09-04T20:34:14.238Z') 
ON CONFLICT ("id") DO UPDATE SET 
  "title" = EXCLUDED."title",
  "date" = EXCLUDED."date",
  "boardMembers" = EXCLUDED."boardMembers",
  "decisions" = EXCLUDED."decisions",
  "createdAt" = EXCLUDED."createdAt";

-- ---------------------------------------------------------
-- Data for Table: socialmediaposts
-- ---------------------------------------------------------
INSERT INTO "socialmediaposts" ("id", "content", "timestamp", "platform", "status") 
VALUES ('QSa33FhpraU36J4mEyCK', 'Koretini po ndryshon! Bashkohuni me ne për një të ardhme më të mirë. #Koretini #Diaspora #Bashke', '2026-01-07T20:37:03.623Z', 'FACEBOOK, INSTAGRAM', 'SCHEDULED') 
ON CONFLICT ("id") DO UPDATE SET 
  "content" = EXCLUDED."content",
  "timestamp" = EXCLUDED."timestamp",
  "platform" = EXCLUDED."platform",
  "status" = EXCLUDED."status";

-- ---------------------------------------------------------
-- Data for Table: settings
-- ---------------------------------------------------------
INSERT INTO "settings" ("id", "payment", "system") 
VALUES ('global', '{"qrIban":"CH13 0630 0508 6189 1750 0","twintUrl":"https://go.twint.ch/1/e/tw?tw=acq.heLTE_9DR0mrnhtPooMhRpa0rkjD3baQnpKB75AbzJeRUvgKYMA5Jj6L_30fz0GJ.","paypalSecret":"EIjfAtmp5wwZVUo_MoxmLEJHdndrF90fb7c_dRp-Sqjqz77qRmkoNGDF3urAZiSSHdxu4clbsI59Zdl_","accountHolder":"Shoqata Humanitare Koretini","zip":"8909","bic":"KBAGCH22","bankName":"Valiant Bank AG","paypalEmail":"info@koretini.me","city":"Zwillikon","paypalClientId":"AdAtIVe2kp27J-5Sm8zDsxCtjVNIs0tZ7J7-FCib2dd6sh3BA7VXYsVVy1UtB1a2niMqOb6TenXNHrFj","currency":"CHF","street":"Weidgartenstrasse 8","country":"CH","iban":"CH13 0630 0508 6189 1750 0","fees":{"STANDARD":{"label":"Standard","currency":"CHF","amount":120},"KOSOVO":{"label":"Resident","currency":"EUR","amount":12},"REDUCED":{"currency":"EUR","label":"Reduced","amount":100}},"annualFeeAmount":120}', '{"updatedAt":"2026-02-16T22:25:24.829Z","systemEmail":"info@koretini.me","maintenanceMode":false,"allowRegistration":true,"modules":{"news":true,"villageLive":false,"events":true}}') 
ON CONFLICT ("id") DO UPDATE SET 
  "payment" = EXCLUDED."payment",
  "system" = EXCLUDED."system";

COMMIT;
