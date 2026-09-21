// Beitraege tatsaechlich an Facebook und Instagram senden.
//
// Aufgerufen wird ausschliesslich vom Server: vom Zeitplan alle fuenf
// Minuten und von social_jetzt_senden() ueber pg_net. Der Browser ruft diese
// Adresse nie an -- /functions/v1/ ist im September zweimal spurlos
// blockiert worden, und ein Versand, der still ausfaellt, ist schlimmer als
// gar keiner.
//
// Benoetigte Umgebungsvariablen:
//   SOCIAL_CRON_TOKEN   derselbe Wert wie platform_secrets.social_cron_token
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY   (setzt Supabase selbst)
//   SOCIAL_BATCH        optional, Hoechstzahl je Lauf (Vorgabe 10)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const GRAPH = "https://graph.facebook.com/v21.0";
const ABLAGE = "uploads";

const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

// Instagram laedt kein Bild hoch, es holt sich eines von einer Adresse. Ein
// Bild, das als data: in der Datenbank liegt, ist fuer Instagram unsichtbar
// -- es muss vorher in die Ablage und eine oeffentliche Adresse bekommen.
async function bildAdresse(sb: any, beitrag: any): Promise<string | null> {
  const bild: string = beitrag.image ?? "";
  if (!bild) return null;
  if (bild.startsWith("http://") || bild.startsWith("https://")) return bild;
  if (!bild.startsWith("data:")) return null;

  const komma = bild.indexOf(",");
  const kopf = bild.slice(5, komma);            // z.B. image/jpeg;base64
  const typ = kopf.split(";")[0] || "image/jpeg";
  const endung = typ.split("/")[1]?.split("+")[0] || "jpg";
  const roh = Uint8Array.from(atob(bild.slice(komma + 1)), (c) => c.charCodeAt(0));

  const pfad = `social/${beitrag.tenantId}/${beitrag.id}.${endung}`;
  const { error } = await sb.storage.from(ABLAGE)
    .upload(pfad, roh, { contentType: typ, upsert: true });
  if (error) throw new Error(`Bild konnte nicht abgelegt werden: ${error.message}`);

  const { data } = sb.storage.from(ABLAGE).getPublicUrl(pfad);
  return data.publicUrl;
}

async function graph(pfad: string, koerper: Record<string, string>) {
  const antwort = await fetch(`${GRAPH}/${pfad}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(koerper).toString(),
  });
  const d = await antwort.json();
  if (d.error) {
    const f = new Error(d.error.message) as Error & { code?: number };
    f.code = d.error.code;
    throw f;
  }
  return d;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  const erwartet = Deno.env.get("SOCIAL_CRON_TOKEN") ?? "";
  if (!erwartet || req.headers.get("x-cron-token") !== erwartet) {
    return json({ error: "Nicht berechtigt." }, 401);
  }

  const sb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  let nurDieser: string | null = null;
  try { nurDieser = (await req.json())?.beitrag ?? null; } catch { /* leerer Koerper ist erlaubt */ }

  const menge = Number(Deno.env.get("SOCIAL_BATCH") ?? "10");
  let abfrage = sb.from("socialmediaposts")
    .select("*")
    .in("status", ["QUEUED", "SCHEDULED"])
    .lt("attempts", 5)
    .limit(menge);
  if (nurDieser) abfrage = abfrage.eq("id", nurDieser);

  const { data: beitraege, error } = await abfrage;
  if (error) return json({ error: error.message }, 500);

  const jetzt = Date.now();
  const faellig = (beitraege ?? []).filter((p: any) =>
    p.status === "QUEUED" ||
    (p.scheduledTime && new Date(p.scheduledTime).getTime() <= jetzt));

  const bericht: any[] = [];

  for (const p of faellig) {
    // Erst sperren, dann arbeiten: sonst greift der naechste Lauf denselben
    // Beitrag, wenn dieser hier noch laeuft, und es wird doppelt gepostet.
    const { data: gesperrt } = await sb.from("socialmediaposts")
      .update({ status: "PUBLISHING", attempts: (p.attempts ?? 0) + 1 })
      .eq("id", p.id).in("status", ["QUEUED", "SCHEDULED"]).select("id");
    if (!gesperrt || gesperrt.length === 0) continue;

    try {
      const { data: verb } = await sb.from("social_connections")
        .select("*").eq("tenantId", p.tenantId).eq("zustand", "AKTIV");
      const fb = (verb ?? []).find((v: any) => v.plattform === "FACEBOOK");
      const ig = (verb ?? []).find((v: any) => v.plattform === "INSTAGRAM");

      const will: string[] = Array.isArray(p.platforms) && p.platforms.length
        ? p.platforms : ["FACEBOOK"];
      const bild = await bildAdresse(sb, p);
      const ids: Record<string, string> = {};
      const uebersprungen: string[] = [];

      if (will.includes("FACEBOOK")) {
        if (!fb) uebersprungen.push("Facebook ist nicht verbunden");
        else if (bild) {
          const r = await graph(`${fb.konto_id}/photos`,
            { url: bild, caption: p.content ?? "", access_token: fb.zugriffstoken });
          ids.FACEBOOK = r.post_id ?? r.id;
        } else {
          const r = await graph(`${fb.konto_id}/feed`,
            { message: p.content ?? "", access_token: fb.zugriffstoken });
          ids.FACEBOOK = r.id;
        }
      }

      if (will.includes("INSTAGRAM")) {
        if (!ig) uebersprungen.push("Instagram ist nicht verbunden");
        else if (!bild) uebersprungen.push("Instagram nimmt keinen Beitrag ohne Bild");
        else {
          // Zwei Schritte: erst den Behaelter anlegen, dann veroeffentlichen.
          const behaelter = await graph(`${ig.konto_id}/media`,
            { image_url: bild, caption: p.content ?? "", access_token: ig.zugriffstoken });
          const r = await graph(`${ig.konto_id}/media_publish`,
            { creation_id: behaelter.id, access_token: ig.zugriffstoken });
          ids.INSTAGRAM = r.id;
        }
      }

      if (Object.keys(ids).length === 0) {
        throw new Error(uebersprungen.join("; ") || "Kein Kanal ausgewaehlt.");
      }

      await sb.from("socialmediaposts").update({
        status: "PUBLISHED",
        publishedAt: new Date().toISOString(),
        externalIds: ids,
        autoPosted: true,
        lastError: uebersprungen.length ? uebersprungen.join("; ") : null,
      }).eq("id", p.id);

      bericht.push({ id: p.id, gesendet: Object.keys(ids), uebersprungen });
    } catch (e) {
      const f = e as Error & { code?: number };
      await sb.from("socialmediaposts").update({
        status: "FAILED", lastError: f.message,
      }).eq("id", p.id);

      // Code 190 heisst: das Token gilt nicht mehr. Dann hilft kein weiterer
      // Versuch, sondern nur neu verbinden -- und das soll die Oberflaeche
      // sagen koennen.
      if (f.code === 190) {
        await sb.from("social_connections")
          .update({ zustand: "ABGELAUFEN", letzter_fehler: f.message })
          .eq("tenantId", p.tenantId);
      }
      bericht.push({ id: p.id, fehler: f.message });
    }
  }

  return json({ geprueft: (beitraege ?? []).length, bearbeitet: bericht.length, bericht });
});
