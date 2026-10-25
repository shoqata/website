// Push-Nachrichten verschicken.
//
// Aufgerufen von der Datenbank (Ausloeser push_nach_benachrichtigung), sobald
// neue Benachrichtigungen entstehen -- mit deren IDs. Die Funktion holt Titel
// und Text, sucht die angemeldeten Geraete der Empfaenger und schickt jedem
// eine Web-Push-Nachricht. Abgelaufene Geraete (404/410) werden geloescht.
//
// Umgebung:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY / SUPABASE_SECRET_KEY  (setzt Supabase)
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT              (selbst zu setzen,
//     aus supabase/.env.push.local)
//
// Geprueft wird der Aufruf mit x-push-token gegen platform_secrets.push_token.
// Ohne passenden Schluessel tut die Funktion nichts.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import webpush from "npm:web-push@3.6.7";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  const sb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    (Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"))!,
    { auth: { persistSession: false } },
  );

  const { data: s } = await sb.from("platform_secrets").select("wert").eq("schluessel", "push_token").maybeSingle();
  if (!s?.wert || req.headers.get("x-push-token") !== s.wert) return json({ error: "Nicht berechtigt." }, 401);

  const pub = Deno.env.get("VAPID_PUBLIC_KEY"), priv = Deno.env.get("VAPID_PRIVATE_KEY");
  if (!pub || !priv) return json({ error: "VAPID-Schluessel fehlen." }, 500);
  webpush.setVapidDetails(Deno.env.get("VAPID_SUBJECT") || "mailto:info@unityhub.li", pub, priv);

  const { ids } = await req.json().catch(() => ({ ids: [] }));
  if (!Array.isArray(ids) || ids.length === 0) return json({ gesendet: 0 });

  const { data: nachrichten } = await sb.from("benachrichtigungen")
    .select("id, empfaenger, titel, text, link").in("id", ids.slice(0, 2000));
  if (!nachrichten?.length) return json({ gesendet: 0 });

  const empfaenger = [...new Set(nachrichten.map((n) => n.empfaenger))];
  const { data: abos } = await sb.from("push_abos")
    .select("id, empfaenger, endpoint, p256dh, auth, herkunft").in("empfaenger", empfaenger);
  const jeEmpfaenger = new Map<string, any[]>();
  for (const a of abos ?? []) jeEmpfaenger.set(a.empfaenger, [...(jeEmpfaenger.get(a.empfaenger) ?? []), a]);

  let gesendet = 0;
  const weg: string[] = [], gut: string[] = [];
  const auftraege: Promise<void>[] = [];
  for (const n of nachrichten) {
    for (const a of jeEmpfaenger.get(n.empfaenger) ?? []) {
      // HashRouter: der Pfad steht hinter #. Ohne Herkunft die Startseite.
      const url = a.herkunft ? `${a.herkunft}/#${n.link || "/"}` : "/";
      const nutzlast = JSON.stringify({ titel: n.titel, text: n.text ?? "", url, tag: n.id });
      auftraege.push(
        webpush.sendNotification({ endpoint: a.endpoint, keys: { p256dh: a.p256dh, auth: a.auth } }, nutzlast,
          { TTL: 60 * 60 * 24, urgency: "normal" })
          .then(() => { gesendet++; gut.push(a.id); })
          .catch((e: any) => {
            // 404/410: das Geraet hat das Abo aufgegeben (App geloescht,
            // Erlaubnis entzogen). Aufraeumen, sonst wird es ewig versucht.
            if (e?.statusCode === 404 || e?.statusCode === 410) weg.push(a.id);
            else console.error("push", e?.statusCode, e?.body ?? e?.message);
          }),
      );
    }
  }
  await Promise.all(auftraege);
  if (weg.length) await sb.from("push_abos").delete().in("id", weg);
  if (gut.length) await sb.from("push_abos").update({ zuletzt_ok: new Date().toISOString() }).in("id", [...new Set(gut)]);
  return json({ gesendet, entfernt: weg.length });
});
