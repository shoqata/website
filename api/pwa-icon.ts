// Das App-Symbol eines Vereins als PNG in der verlangten Groesse.
//
// Mit Logo: das Logo, zentriert auf weissem Grund. Ohne Logo (bei Koretini
// und dem Demo-Verein heute der Fall): der Anfangsbuchstabe in Weiss auf
// der Vereinsfarbe. "maskable" (m=1) laesst rundum einen Rand, weil Android
// das Symbol in Kreis, Tropfen oder Quadrat schneidet und nur die innere
// Flaeche sicher sichtbar ist.
import sharp from 'sharp';
import opentype from 'opentype.js';
import { markeFuer } from './_verein';

const GROESSEN = new Set([32, 64, 180, 192, 512]);

// Der Buchstabe wird als Pfad gezeichnet, nicht als <text>: auf den
// Servern gibt es keine Systemschriften, ein <text> bliebe dort leer.
// Die Schrift ist dieselbe, die die Website fuer Bescheinigungen ausliefert.
let schriftCache: opentype.Font | null = null;
async function schrift(host: string): Promise<opentype.Font | null> {
  if (schriftCache) return schriftCache;
  try {
    const r = await fetch(`https://${host}/fonts/NotoSans-Bold.ttf`);
    if (!r.ok) return null;
    schriftCache = opentype.parse(await r.arrayBuffer());
    return schriftCache;
  } catch { return null; }
}

async function buchstabe(name: string, farbe: string, s: number, rand: number, host: string) {
  const zeichen = (Array.from(name.trim())[0] || '?').toUpperCase();
  const groesse = s * (1 - 2 * rand) * 0.62;
  let pfad = '';
  const f = await schrift(host);
  if (f) {
    const g = f.getPath(zeichen, 0, 0, groesse);
    const k = g.getBoundingBox();
    // Mittig nach der tatsaechlichen Glyphe, nicht nach der Schriftlinie.
    const dx = (s - (k.x2 - k.x1)) / 2 - k.x1;
    const dy = (s - (k.y2 - k.y1)) / 2 - k.y1;
    pfad = f.getPath(zeichen, dx, dy, groesse).toPathData(2);
  }
  return Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}">` +
    `<rect width="100%" height="100%" fill="${farbe}"/>` +
    (pfad ? `<path d="${pfad}" fill="#fff"/>` : '') + `</svg>`);
}

export async function GET(request: Request) {
  const u = new URL(request.url);
  const s = GROESSEN.has(Number(u.searchParams.get('s'))) ? Number(u.searchParams.get('s')) : 192;
  const maskierbar = u.searchParams.get('m') === '1';
  // Ein Logo bekommt immer etwas Luft; maskierbar deutlich mehr (sichere
  // Zone: innere 80 %).
  const rand = maskierbar ? 0.18 : 0.1;
  const host = request.headers.get('x-forwarded-host') || request.headers.get('host') || u.host;
  const m = await markeFuer(host);

  let png: Buffer;
  try {
    if (!m.logoUrl) throw new Error('kein Logo');
    const r = await fetch(m.logoUrl);
    if (!r.ok) throw new Error(`Logo ${r.status}`);
    const innen = Math.round(s * (1 - 2 * rand));
    const logo = await sharp(Buffer.from(await r.arrayBuffer()), { density: 300 })
      .resize(innen, innen, { fit: 'contain', background: { r: 255, g: 255, b: 255, alpha: 0 } })
      .png().toBuffer();
    png = await sharp({ create: { width: s, height: s, channels: 4, background: '#ffffff' } })
      .composite([{ input: logo, gravity: 'center' }]).png().toBuffer();
  } catch {
    // Ohne (lesbares) Logo: Anfangsbuchstabe auf der Vereinsfarbe.
    png = await sharp(await buchstabe(m.name, m.farbe, s, rand, host)).png().toBuffer();
  }

  return new Response(new Uint8Array(png), {
    headers: {
      'content-type': 'image/png',
      'cache-control': 'public, max-age=3600, s-maxage=86400, stale-while-revalidate=604800',
      vary: 'host',
    },
  });
}
