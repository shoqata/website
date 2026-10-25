// Ein Bild pruefen, neu erzeugen und ablegen.
//
// Fuer die Bilder der Nachbarschaften und alle Website-Bilder des Vereins
// (Feld "zweck": logo, branding, hero, live, board, news, chronik, seiten).
// Das Logo bleibt PNG (Durchsichtigkeit), alles andere wird JPEG. Ablauf:
//   1. Angemeldet? Darf der Aufrufer fuer diese Nachbarschaft Bilder
//      hinzufuegen? (nachbarschaft_bild_erlaubt, mit seinem eigenen Token)
//   2. Groesse: hoechstens 8 MB.
//   3. Format an den ersten Bytes, nicht an Endung oder Angabe des Browsers:
//      nur JPEG und PNG. SVG ist ausgeschlossen -- es kann Skript enthalten.
//   4. Zerlegen in Pixel und neu als JPEG schreiben, laengste Seite
//      hoechstens 1600 px. Was in der Datei sonst steckte -- Skript,
//      angehaengte Daten, eine zweite Datei im selben Behaelter, Metadaten
//      mit GPS-Ort --, ist danach weg. Schlaegt das Zerlegen fehl, ist es
//      kein Bild und wird abgewiesen.
//   5. Ablage unter geprueft/... -- dorthin darf sonst niemand schreiben
//      (Zeilenregeln auf storage.objects), und die Datenbank nimmt fuer eine
//      Nachbarschaft nur Bilder aus ihrem geprueften Ordner an.
//
// Ein Virenscanner fuer beliebige Dateien ist das nicht. Fuer Bilder ist
// das Neu-Erzeugen die strengere Pruefung: ein Scanner erkennt bekannte
// Muster, das Neu-Erzeugen laesst gar nichts uebrig ausser Pixeln.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import { decode, Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";
import { geheimschluessel } from "../_shared/schluessel.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

const MAX_BYTES = 8 * 1024 * 1024;
const MAX_SEITE = 1600;
const MAX_DATEIEN_JE_ORDNER = 20;

function format(b: Uint8Array): "jpeg" | "png" | null {
  if (b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "jpeg";
  if (b.length > 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47
      && b[4] === 0x0d && b[5] === 0x0a && b[6] === 0x1a && b[7] === 0x0a) return "png";
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ fehler: "Nur POST." }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return json({ fehler: "Nicht angemeldet." }, 401);

  const herkunft = req.headers.get("origin") ?? "";
  const alsAufrufer = createClient(url, anonKey, {
    global: { headers: { Authorization: auth, ...(herkunft ? { origin: herkunft } : {}) } },
    auth: { persistSession: false },
  });
  // Kein auth.getUser(): das fragt den Anmeldedienst nach der Sitzung,
  // und die kann dort schon beendet sein, waehrend das Token noch gilt --
  // dann hiess es "Nicht angemeldet", obwohl die ganze uebrige App (die
  // Datenbank prueft die Signatur des Tokens) weiter funktionierte.
  // Wer der Aufrufer ist und was er darf, entscheidet unten
  // nachbarschaft_bild_erlaubt() mit genau diesem Token.

  let form: FormData;
  try { form = await req.formData(); } catch { return json({ fehler: "Anfrage nicht lesbar." }, 400); }
  const nachbarschaft = String(form.get("nachbarschaft") ?? "").trim();
  const zweck = String(form.get("zweck") ?? "").trim();
  const datei = form.get("bild");
  if ((!nachbarschaft && !zweck) || !(datei instanceof File)) return json({ fehler: "Zweck und Bild fehlen." }, 400);
  if (nachbarschaft && !/^[A-Za-z0-9_-]{1,80}$/.test(nachbarschaft)) return json({ fehler: "Unbekannte Nachbarschaft." }, 400);
  if (!nachbarschaft && !/^[a-z]{1,20}$/.test(zweck)) return json({ fehler: "Unbekannter Zweck." }, 400);

  const { data: verein, error: rechtFehler } = nachbarschaft
    ? await alsAufrufer.rpc("nachbarschaft_bild_erlaubt", { p_nachbarschaft: nachbarschaft })
    : await alsAufrufer.rpc("vereinsbild_erlaubt", { p_zweck: zweck });
  if (rechtFehler || !verein) return json({ fehler: rechtFehler?.message || "Nicht berechtigt." }, 403);
  const alsPng = !nachbarschaft && zweck === "logo";
  const maxSeite = nachbarschaft ? MAX_SEITE : alsPng ? 1024 : 2400;

  if (datei.size > MAX_BYTES) return json({ fehler: "Das Bild ist zu gross (höchstens 8 MB)." }, 413);
  const roh = new Uint8Array(await datei.arrayBuffer());
  const art = format(roh);
  if (!art) return json({ fehler: "Nur JPEG- oder PNG-Bilder sind erlaubt." }, 415);

  let neu: Uint8Array;
  let breite = 0, hoehe = 0;
  try {
    const bild = await decode(roh);
    if (!(bild instanceof Image)) return json({ fehler: "Bewegte Bilder sind nicht erlaubt." }, 415);
    if (bild.width < (alsPng ? 16 : 32) || bild.height < (alsPng ? 16 : 32)) return json({ fehler: "Das Bild ist zu klein." }, 415);
    if (bild.width * bild.height > 60_000_000) return json({ fehler: "Das Bild hat zu viele Pixel." }, 413);
    const laengste = Math.max(bild.width, bild.height);
    if (laengste > maxSeite) {
      if (bild.width >= bild.height) bild.resize(maxSeite, Image.RESIZE_AUTO);
      else bild.resize(Image.RESIZE_AUTO, maxSeite);
    }
    breite = bild.width; hoehe = bild.height;
    neu = alsPng ? await bild.encode(6) : await bild.encodeJPEG(82);
  } catch (_e) {
    return json({ fehler: "Die Datei ist kein lesbares Bild und wurde abgewiesen." }, 415);
  }

  const admin = createClient(url, geheimschluessel(), { auth: { persistSession: false } });
  // Vereinsbilder je Tag in einem Ordner; 100 je Tag und Zweck genuegen.
  const ordner = nachbarschaft
    ? `geprueft/nachbarschaften/${verein}/${nachbarschaft}`
    : `geprueft/verein/${verein}/${zweck}/${new Date().toISOString().slice(0, 10)}`;
  const grenze = nachbarschaft ? MAX_DATEIEN_JE_ORDNER : 100;
  const { data: vorhanden } = await admin.storage.from("uploads").list(ordner, { limit: grenze + 1 });
  if ((vorhanden?.length ?? 0) >= grenze) {
    return json({ fehler: "Zu viele Bilder in kurzer Zeit." }, 429);
  }

  const pfad = `${ordner}/${crypto.randomUUID()}.${alsPng ? "png" : "jpg"}`;
  const { error: abFehler } = await admin.storage.from("uploads")
    .upload(pfad, neu, { contentType: alsPng ? "image/png" : "image/jpeg", upsert: false, cacheControl: "31536000" });
  if (abFehler) return json({ fehler: "Ablegen fehlgeschlagen: " + abFehler.message }, 500);

  const { data: oeff } = admin.storage.from("uploads").getPublicUrl(pfad);
  return json({ url: oeff.publicUrl, breite, hoehe, bytes: neu.length, vorher: roh.length });
});
