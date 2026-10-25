// Das Web-App-Manifest, je Verein.
//
// Jede Vereinsdomain bekommt ihre eigene installierbare App: eigener Name,
// eigene Farbe, eigenes Symbol (aus dem Logo, sonst ein Anfangsbuchstabe).
// Ein festes manifest.json ginge nicht -- alle Vereine teilen sich denselben
// Build.
import { markeFuer } from './_verein.js';  // Endung noetig: das Projekt ist ein ES-Modul, Vercel buendelt nicht

export async function GET(request: Request) {
  const host = request.headers.get('x-forwarded-host') || request.headers.get('host') || new URL(request.url).host;
  const m = await markeFuer(host);
  const symbol = (s: number, zweck?: string) => ({
    src: `/api/pwa-icon?s=${s}${zweck === 'maskable' ? '&m=1' : ''}`,
    sizes: `${s}x${s}`, type: 'image/png', ...(zweck ? { purpose: zweck } : {}),
  });
  const manifest = {
    id: '/',
    name: m.name,
    short_name: m.kurz,
    start_url: '/',
    scope: '/',
    display: 'standalone',
    background_color: m.hintergrund,
    theme_color: m.farbe,
    lang: 'de',
    icons: [symbol(192), symbol(512), symbol(192, 'maskable'), symbol(512, 'maskable')],
  };
  return new Response(JSON.stringify(manifest), {
    headers: {
      'content-type': 'application/manifest+json; charset=utf-8',
      // Kurz zwischenspeichern: ein neues Logo soll nicht tagelang auf sich
      // warten lassen. Je Host getrennt, weil alle Vereine dieselbe URL haben.
      'cache-control': 'public, max-age=300, s-maxage=3600, stale-while-revalidate=86400',
      vary: 'host',
    },
  });
}
