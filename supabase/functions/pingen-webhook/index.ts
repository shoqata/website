import { createClient } from "jsr:@supabase/supabase-js@2";
import { geheimschluessel } from "../_shared/schluessel.ts";

// Statusmeldungen von Pingen annehmen.
//
// Pingen schickt eine POST-Anfrage, sobald sich etwas aendert -- in vier
// Kategorien, die der Verein in der Pingen-WebApp bestellt:
//
//   issues         Probleme, die eine Handlung verlangen: PDF nicht A4,
//                  Inhalte in den Sperrbereichen, Guthaben erschoepft.
//   sent           an die Post uebergeben, Sendungsnummer erhalten.
//   undeliverable  nicht zustellbar. Pingen vernichtet den Brief
//                  ungeoeffnet; die Adresse ist falsch.
//   delivered      zugestellt, bei Einschreiben.
//
// Diese Funktion ist OEFFENTLICH erreichbar -- Pingen kann keinen
// Cron-Token mitschicken. Was sie schuetzt, ist allein die Signatur:
//
//   Signature: <hex HMAC-SHA256 des ROHEN Koerpers, Schluessel = das
//              Webhook-Geheimnis aus der Pingen-WebApp>
//
// Darum zwei Dinge, die hier nicht verhandelbar sind:
//
//   Der Koerper wird GENAU EINMAL als Text gelesen und dann sowohl
//   geprueft als auch ausgewertet. Wer ihn zweimal liest oder vor der
//   Pruefung durch JSON schickt und wieder zusammensetzt, prueft eine
//   andere Zeichenkette als die, die unterschrieben wurde -- und
//   bemerkt es nie, weil es meistens gleich aussieht.
//
//   Der Vergleich laeuft zeitkonstant. Ein frueh abbrechender Vergleich
//   verraet ueber die Laufzeit, wie viele Zeichen stimmen; damit laesst
//   sich eine Signatur Zeichen fuer Zeichen erraten.
//
// Ohne hinterlegtes Geheimnis nimmt diese Funktion NICHTS an. Eine
// offene Statusschnittstelle liesse jeden einen Brief als zugestellt
// melden.

const geheimnis = (Deno.env.get("PINGEN_WEBHOOK_SECRET") ?? "").trim();

const json = (k: unknown, status = 200) =>
  new Response(JSON.stringify(k), { status, headers: { "Content-Type": "application/json" } });

const hexHmac = async (schluessel: string, text: string): Promise<string> => {
  const k = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(schluessel),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(text));
  return [...new Uint8Array(sig)].map(b => b.toString(16).padStart(2, "0")).join("");
};

// Zeitkonstanter Vergleich.
const gleich = (a: string, b: string): boolean => {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
};

// Pingens Ereignisnamen auf unsere Zustaende abbilden.
//
// Die Zuordnung ist absichtlich grob: fuer den Verein zaehlt, ob der
// Brief unterwegs, angekommen oder gescheitert ist. Jede
// Zwischenstufe von Pingen als eigenen Zustand zu fuehren hiesse, unsere
// Tabelle jedem Namenswechsel dort nachzuziehen.
const zustandAus = (kategorie: string, ereignis: string): string | null => {
  const e = `${kategorie} ${ereignis}`.toLowerCase();
  if (/undeliverable|unzustellbar|returned/.test(e)) return "UNZUSTELLBAR";
  if (/delivered|zugestellt/.test(e)) return "ZUGESTELLT";
  if (/sent|versendet|submitted|dispatched/.test(e)) return "VERSENDET";
  if (/issue|problem|error|invalid|insufficient/.test(e)) return "PROBLEM";
  return null;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  if (!geheimnis) {
    // Nicht 200 zurueckgeben: Pingen soll es erneut versuchen, sobald das
    // Geheimnis hinterlegt ist. Ein stilles OK wuerde die Meldung
    // verwerfen und niemandem auffallen.
    return json({ error: "PINGEN_WEBHOOK_SECRET fehlt -- keine Meldung angenommen." }, 503);
  }

  // Genau einmal lesen.
  const roh = await req.text();
  const mitgeschickt = req.headers.get("Signature")
    ?? req.headers.get("signature") ?? "";
  if (!mitgeschickt) return json({ error: "Signatur fehlt." }, 401);

  const erwartet = await hexHmac(geheimnis, roh);
  if (!gleich(erwartet.toLowerCase(), mitgeschickt.trim().toLowerCase())) {
    return json({ error: "Signatur stimmt nicht." }, 401);
  }

  let d: any;
  try { d = JSON.parse(roh); } catch {
    return json({ error: "Kein gueltiges JSON." }, 400);
  }

  // JSON:API. Die Kategorie steht im Umschlag, das betroffene Objekt in
  // den Beziehungen. Beide Formen beruecksichtigen, weil die Doku
  // flachere Beispiele zeigt als das SDK.
  const a = d?.data?.attributes ?? d;
  const kategorie = String(a?.webhook_category ?? a?.category ?? d?.data?.type ?? "");
  const ereignis = String(a?.event ?? a?.name ?? "");
  const briefId = String(
    d?.data?.relationships?.item?.data?.id
    ?? a?.item?.id ?? a?.letter_id ?? a?.id ?? "");
  const meldung = String(a?.message ?? a?.reason ?? a?.error ?? "").slice(0, 400);

  if (!briefId) {
    // Angenommen, aber nicht zuordenbar. 200, damit Pingen nicht endlos
    // wiederholt -- und mit einer Antwort, die es benennt.
    return json({ ok: true, zugeordnet: false,
      hinweis: "Meldung ohne Briefkennung -- nichts zuzuordnen." });
  }

  const zustand = zustandAus(kategorie, ereignis);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    geheimschluessel(),
    { auth: { persistSession: false } },
  );

  const { data: erg, error } = await admin.rpc("post_zustand_melden", {
    p_pingen_id: briefId,
    p_zustand: zustand,
    p_status: ereignis || kategorie || null,
    p_meldung: meldung || null,
  });
  if (error) return json({ error: error.message }, 500);

  const getroffen = Number((erg as any)?.getroffen ?? 0);

  // Eine Meldung zu einem Brief, den wir nicht kennen, ist keine
  // Kleinigkeit: sie heisst, dass Pingen etwas weiss, was bei uns nicht
  // steht. Trotzdem 200 -- Pingen soll nicht endlos wiederholen --, aber
  // mit klarer Antwort im Protokoll.
  return json({
    ok: true, zugeordnet: getroffen > 0,
    brief: briefId, kategorie, ereignis, zustand,
    hinweis: getroffen === 0
      ? "Zu dieser Briefkennung ist bei uns kein Brief erfasst."
      : undefined,
  });
});
