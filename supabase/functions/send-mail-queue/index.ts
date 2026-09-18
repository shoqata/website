// Die Warteschlange abarbeiten und tatsaechlich versenden.
//
// Seit der Umstellung von Firebase auf Supabase gab es keinen Versandweg mehr:
// sendEmail() schrieb in eine Tabelle, die es nicht gibt, und scheiterte
// still. Diese Funktion ist der fehlende Weg nach draussen.
//
// Die Zugangsdaten des Postausgangs stehen in der Umgebung der Funktion und
// nirgends sonst -- nicht im Bundle, nicht in der Datenbank, nicht im
// Quelltext. Das war die ausdrueckliche Bedingung: "die Eigener SMTP-Server
// muessen sicher sein, da sonst das misbruacht werden kann."
//
// Benoetigte Umgebungsvariablen:
//   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
//   SMTP_TLS        optional, "starttls" (Vorgabe) oder "tls"
//
// Vorrang hat inzwischen die Tabelle mail_settings: dort traegt jeder Verein
// seinen eigenen Postausgang ein, ueber die Verwaltung. Die Secrets bleiben
// als Rueckfall bestehen -- fuer Vereine ohne eigenen Eintrag und damit eine
// bestehende Einrichtung nicht ploetzlich stillsteht.
//   MAIL_BATCH      optional, Hoechstzahl je Lauf (Vorgabe 40)
//   MAIL_CRON_TOKEN optional, Kennwort fuer den Aufruf durch den Zeitplan

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const host = Deno.env.get("SMTP_HOST");
  const port = Number(Deno.env.get("SMTP_PORT") ?? "587");
  const benutzer = Deno.env.get("SMTP_USER");
  const kennwort = Deno.env.get("SMTP_PASS");
  const absender = Deno.env.get("SMTP_FROM");
  const tlsArt = (Deno.env.get("SMTP_TLS") ?? "starttls").toLowerCase();
  const menge = Math.min(Number(Deno.env.get("MAIL_BATCH") ?? "40"), 200);
  const cronToken = Deno.env.get("MAIL_CRON_TOKEN");

  // Zwei Wege herein: der Zeitplan mit einem geteilten Kennwort, oder eine
  // angemeldete Person aus der Geschaeftsfuehrung. Alles andere bleibt aussen.
  const tokenHeader = req.headers.get("x-cron-token");
  let erlaubt = false;
  let aufrufer = "zeitplan";

  const admin0 = createClient(url, serviceKey, { auth: { persistSession: false } });

  if (cronToken && tokenHeader && tokenHeader === cronToken) {
    erlaubt = true;
  } else if (tokenHeader) {
    // Das Zeitplan-Kennwort steht auch in mail_settings -- dort wird es beim
    // Anlegen erzeugt, damit niemand es von Hand in die Secrets eintragen
    // muss. Verglichen wird ueber die Datenbank, nicht in JavaScript, damit
    // der Vergleich nicht ueber die Laufzeit verraet, wie weit er kam.
    const { data: treffer } = await admin0
      .rpc("zeitplan_token_gueltig", { p_token: tokenHeader });
    if (treffer === true) erlaubt = true;
  }
  if (!erlaubt) {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (authHeader.startsWith("Bearer ")) {
      const asCaller = createClient(url, anonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data } = await asCaller.auth.getUser();
      const mail = (data?.user?.email ?? "").toLowerCase();
      if (mail) {
        const { data: rows } = await admin0
          .from("users").select("role").ilike("email", mail).limit(1);
        const rolle = rows?.[0]?.role ?? "";
        if (["ADMIN", "SUPER_ADMIN", "BOARD"].includes(rolle)) {
          erlaubt = true;
          aufrufer = mail;
        }
      }
    }
  }
  if (!erlaubt) return json({ error: "Nicht berechtigt." }, 403);

  const admin = admin0;

  // Offene Nachrichten holen -- vereinsuebergreifend, danach nach Verein
  // getrennt versendet. Jeder Verein hat seinen eigenen Postausgang; ueber
  // den eines anderen zu versenden waere ein Mandantenbruch.
  const { data: offen, error: leseFehler } = await admin
    .from("mail_queue")
    .select("*")
    .eq("status", "PENDING")
    .lte("scheduledFor", new Date().toISOString())
    .order("createdAt", { ascending: true })
    .limit(menge);

  if (leseFehler) return json({ error: leseFehler.message }, 500);
  if (!offen?.length) return json({ ok: true, configured: true, sent: 0, failed: 0 });

  // Zugangsdaten je Verein. Vorrang hat der Eintrag in mail_settings; fehlt
  // er, gelten die Secrets der Funktion -- so steht eine bestehende
  // Einrichtung nicht ploetzlich still.
  const { data: eintraege } = await admin
    .from("mail_settings")
    .select('"tenantId", host, port, benutzer, kennwort, absender, absendername, tls, aktiv');

  const ausSecrets = {
    host, port, benutzer, kennwort, absender, absendername: null as string | null,
    tls: tlsArt, aktiv: true,
  };
  const postausgang = new Map<string, typeof ausSecrets>();
  for (const e of eintraege ?? []) {
    postausgang.set(e.tenantId, {
      host: e.host, port: e.port ?? 587, benutzer: e.benutzer,
      kennwort: e.kennwort, absender: e.absender, absendername: e.absendername,
      tls: (e.tls ?? "starttls").toLowerCase(), aktiv: e.aktiv !== false,
    });
  }

  const vollstaendig = (p: typeof ausSecrets | undefined) =>
    !!(p && p.aktiv && p.host && p.benutzer && p.kennwort && p.absender);

  // Nach Verein gruppieren.
  const nachVerein = new Map<string, any[]>();
  for (const m of offen) {
    const v = m.tenantId ?? "";
    if (!nachVerein.has(v)) nachVerein.set(v, []);
    nachVerein.get(v)!.push(m);
  }

  let gesendet = 0;
  let gescheitert = 0;
  let liegengeblieben = 0;
  const ohnePostausgang: string[] = [];

  for (const [verein, nachrichten] of nachVerein) {
    const p = postausgang.get(verein) ?? ausSecrets;

    // Ohne Postausgang wird nichts versendet -- und nichts angetastet. Die
    // Nachrichten bleiben stehen, statt als gescheitert zu gelten.
    if (!vollstaendig(p)) {
      liegengeblieben += nachrichten.length;
      if (!ohnePostausgang.includes(verein)) ohnePostausgang.push(verein);
      continue;
    }

    const client = new SMTPClient({
      connection: {
        hostname: p.host!,
        port: p.port,
        tls: p.tls === "tls",
        auth: { username: p.benutzer!, password: p.kennwort! },
      },
    });

    for (const m of nachrichten) {
      try {
        await client.send({
          from: p.absendername ? `${p.absendername} <${p.absender}>` : p.absender!,
          to: m.recipient,
          subject: m.subject,
          html: m.html,
          content: m.text ?? undefined,
          attachments: Array.isArray(m.attachments) && m.attachments.length
            ? m.attachments.map((a: any) => ({
                filename: a.filename,
                content: a.content,
                encoding: "base64" as const,
              }))
            : undefined,
        });
        await admin.from("mail_queue")
          .update({ status: "SENT", sentAt: new Date().toISOString(), attempts: (m.attempts ?? 0) + 1 })
          .eq("id", m.id);
        gesendet++;
      } catch (e) {
        const versuche = (m.attempts ?? 0) + 1;
        // Erst nach dem fuenften vergeblichen Versuch endgueltig aufgeben --
        // ein voruebergehend nicht erreichbarer Postausgang soll keine
        // Nachricht verbrennen.
        await admin.from("mail_queue")
          .update({
            status: versuche >= 5 ? "FAILED" : "PENDING",
            attempts: versuche,
            lastError: String((e as any)?.message ?? e).slice(0, 500),
          })
          .eq("id", m.id);
        gescheitert++;
      }
    }

    try { await client.close(); } catch { /* geschlossen ist geschlossen */ }
  }

  if (gesendet === 0 && gescheitert === 0 && liegengeblieben > 0) {
    return json({
      ok: false,
      configured: false,
      sent: 0, failed: 0, pending: liegengeblieben,
      hinweis:
        "Kein Postausgang hinterlegt. Tragen Sie ihn in der Verwaltung unter " +
        "Einstellungen ein. Bis dahin bleibt alles in der Warteschlange " +
        "stehen und geht nicht verloren.",
    }, 200);
  }

  return json({ ok: true, configured: true, sent: gesendet, failed: gescheitert,
                pending: liegengeblieben, by: aufrufer });
});
