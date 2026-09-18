// Voruebergehendes Passwort fuer ein Mitglied setzen.
//
// Warum serverseitig: das Passwort eines anderen Benutzers zu aendern verlangt
// den Administrator-Schluessel von Supabase. Der darf unter keinen Umstaenden
// in die Anwendung im Browser gelangen -- genau so ist in diesem Projekt schon
// einmal ein Schluessel nach aussen geraten. Hier liegt er in der Umgebung der
// Funktion und verlaesst den Server nie.
//
// Was die Funktion prueft, bevor sie irgendetwas tut:
//   1. Ist der Aufrufer ueberhaupt angemeldet?
//   2. Hat er im eigenen Verein die Rolle Administration oder Vorstand?
//   3. Gehoert das Mitglied zum selben Verein?
//   4. Hat das Mitglied eine echte E-Mail-Adresse?
// Erst dann wird das Passwort gesetzt. Jeder Vorgang wird protokolliert --
// wer das Passwort eines anderen setzen kann, muss nachvollziehbar sein.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// Zeichen ohne Verwechslungsgefahr: kein O/0, kein I/l/1.
const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
function temporaryPassword(length = 14): string {
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => ALPHABET[b % ALPHABET.length]).join("");
}

// Jeden Versuch festhalten, nicht nur die gelungenen.
//
// Als beim Zuruecksetzen fuer ein Mitglied nichts ankam, liess sich nicht
// feststellen warum: es gab weder ein Konto noch einen Protokolleintrag, also
// keinerlei Spur davon, ob die Anfrage den Server ueberhaupt erreicht hatte.
// Ein Fehlschlag ohne Spur kostet bei jeder Meldung eine Testrunde.
async function protokolliere(
  admin: any,
  tenantId: string | null,
  action: string,
  details: string,
  userId?: string | null,
  userAgent?: string | null,
) {
  try {
    await admin.from("security_logs").insert({
      id: crypto.randomUUID(),
      tenantId: tenantId ?? "unbekannt",
      type: "PASSWORD_RESET",
      action,
      userId: userId ?? null,
      details: details.slice(0, 1000),
      userAgent: userAgent ?? null,
      timestamp: new Date().toISOString(),
      createdAt: new Date().toISOString(),
    });
  } catch (e) {
    console.error("[reset] Protokolleintrag fehlgeschlagen:", e);
  }
}

const PLACEHOLDER = /(@koretini\.legacy|no-email-)/i;
const LOOKS_LIKE_EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json({ error: "Nicht angemeldet." }, 401);
  }

  // Der Aufrufer wird mit seinem eigenen Token gelesen -- so gelten fuer ihn
  // dieselben Zugriffsregeln wie in der Anwendung.
  const asCaller = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: authData, error: authErr } = await asCaller.auth.getUser();
  if (authErr || !authData?.user) return json({ error: "Nicht angemeldet." }, 401);
  const callerEmail = (authData.user.email ?? "").toLowerCase();

  let memberId = "";
  try {
    memberId = String((await req.json())?.memberId ?? "").trim();
  } catch {
    return json({ error: "Anfrage nicht lesbar." }, 400);
  }
  if (!memberId) return json({ error: "Kein Mitglied angegeben." }, 400);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  // Rolle und Verein des Aufrufers -- serverseitig, nicht aus der Anfrage.
  const { data: callerRows } = await admin
    .from("users")
    .select('id, role, "tenantId", email')
    .ilike("email", callerEmail)
    .limit(1);
  const caller = callerRows?.[0];

  const { data: isPlatform } = await admin
    .from("platform_admins")
    .select("email")
    .ilike("email", callerEmail)
    .limit(1);
  const platformAdmin = (isPlatform?.length ?? 0) > 0;

  if (!caller && !platformAdmin) return json({ error: "Kein Profil gefunden." }, 403);
  const allowedRole = ["ADMIN", "SUPER_ADMIN", "BOARD"].includes(caller?.role ?? "");
  if (!allowedRole && !platformAdmin) {
    return json({ error: "Nur Administration oder Vorstand darf Passwoerter zuruecksetzen." }, 403);
  }

  const { data: memberRows } = await admin
    .from("users")
    .select('id, email, "displayName", "tenantId", "authUserId"')
    .eq("id", memberId)
    .limit(1);
  const member = memberRows?.[0];
  if (!member) return json({ error: "Mitglied nicht gefunden." }, 404);

  // Ein Vorstand darf nur im eigenen Verein zuruecksetzen. Der Betreiber der
  // Plattform ist ausgenommen -- er betreut Vereine bei der Einrichtung.
  if (!platformAdmin && member.tenantId !== caller?.tenantId) {
    return json({ error: "Dieses Mitglied gehoert zu einem anderen Verein." }, 403);
  }

  const email = (member.email ?? "").trim().toLowerCase();
  if (!email || PLACEHOLDER.test(email) || !LOOKS_LIKE_EMAIL.test(email)) {
    return json({
      error:
        "Dieses Mitglied hat keine echte E-Mail-Adresse. Ohne sie gibt es kein Konto, dessen Passwort sich setzen liesse.",
    }, 400);
  }

  const password = temporaryPassword();

  // Konto suchen; existiert keines, wird eines angelegt -- dann bekommt das
  // Mitglied mit diesem Passwort erstmals Zugang.
  let authUserId = member.authUserId as string | null;
  let created = false;

  if (!authUserId) {
    const { data: list } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 });
    authUserId = list?.users?.find((u) => (u.email ?? "").toLowerCase() === email)?.id ?? null;
  }

  const browser = req.headers.get("user-agent");

  if (authUserId) {
    const { error } = await admin.auth.admin.updateUserById(authUserId, { password });
    if (error) {
      await protokolliere(admin, member.tenantId, "FEHLGESCHLAGEN",
        `Passwort setzen fuer ${email} durch ${callerEmail}: ${error.message}`, member.id, browser);
      return json({ error: `Passwort konnte nicht gesetzt werden: ${error.message}` }, 500);
    }
  } else {
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (error || !data?.user) {
      await protokolliere(admin, member.tenantId, "FEHLGESCHLAGEN",
        `Konto anlegen fuer ${email} durch ${callerEmail}: ${error?.message ?? "unbekannt"}`,
        member.id, browser);
      return json({
        error: `Konto konnte nicht angelegt werden: ${error?.message ?? "?"}`,
      }, 500);
    }
    authUserId = data.user.id;
    created = true;
  }

  // Profil mit dem Konto verknuepfen und den Vorgang festhalten.
  await admin.from("users").update({ authUserId }).eq("id", member.id);
  await protokolliere(admin, member.tenantId,
    created ? "ACCOUNT_CREATED" : "PASSWORD_SET",
    `durch ${callerEmail} fuer ${member.displayName ?? email} (${email})`,
    member.id, browser);

  return json({
    ok: true,
    created,
    email,
    displayName: member.displayName,
    password,
  });
});
