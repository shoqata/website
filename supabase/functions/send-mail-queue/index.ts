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

  if (cronToken && tokenHeader && tokenHeader === cronToken) {
    erlaubt = true;
  } else {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (authHeader.startsWith("Bearer ")) {
      const asCaller = createClient(url, anonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data } = await asCaller.auth.getUser();
      const mail = (data?.user?.email ?? "").toLowerCase();
      if (mail) {
        const admin0 = createClient(url, serviceKey, { auth: { persistSession: false } });
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

  // Ohne Postausgang wird nichts versendet -- und nichts angetastet. Die
  // Nachrichten bleiben in der Warteschlange stehen, statt als gescheitert
  // zu gelten.
  if (!host || !benutzer || !kennwort || !absender) {
    return json({
      ok: false,
      configured: false,
      hinweis:
        "Kein Postausgang hinterlegt. Setzen Sie SMTP_HOST, SMTP_PORT, SMTP_USER, " +
        "SMTP_PASS und SMTP_FROM in den Secrets der Funktion. Bis dahin bleibt " +
        "alles in der Warteschlange stehen und geht nicht verloren.",
    }, 200);
  }

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  const { data: offen, error: leseFehler } = await admin
    .from("mail_queue")
    .select("*")
    .eq("status", "PENDING")
    .lte("scheduledFor", new Date().toISOString())
    .order("createdAt", { ascending: true })
    .limit(menge);

  if (leseFehler) return json({ error: leseFehler.message }, 500);
  if (!offen?.length) return json({ ok: true, configured: true, sent: 0, failed: 0 });

  const client = new SMTPClient({
    connection: {
      hostname: host,
      port,
      tls: tlsArt === "tls",
      auth: { username: benutzer, password: kennwort },
    },
  });

  let gesendet = 0;
  let gescheitert = 0;

  for (const m of offen) {
    try {
      await client.send({
        from: absender,
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

  return json({ ok: true, configured: true, sent: gesendet, failed: gescheitert, by: aufrufer });
});
