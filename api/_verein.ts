// Gemeinsames fuer die PWA-Funktionen: welcher Verein gehoert zu dieser
// Adresse, und wie sieht er aus?
//
// Dieselbe Zuordnung wie im Browser (resolveTenantId): erst die Domain in
// public_tenant_domains, dann die oeffentliche Marke aus public_settings.
// Gelesen wird mit dem oeffentlichen Schluessel -- mehr als ein Besucher
// sieht, sieht diese Funktion auch nicht.

const URL_ = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL || '';
const KEY = process.env.VITE_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY || '';

export type Marke = {
  tenantId: string | null;
  name: string;
  kurz: string;
  farbe: string;
  hintergrund: string;
  logoUrl: string | null;
};

// unityhub.li ist die Betreiberseite und hat keinen Verein.
const PLATTFORM: Marke = {
  tenantId: null, name: 'UnityHub', kurz: 'UnityHub',
  farbe: '#1c1917', hintergrund: '#faf9f6', logoUrl: null,
};

const text = (w: any): string =>
  !w ? '' : typeof w === 'string' ? w : (w.de || w.sq || w.en || '');

async function rest(pfad: string, origin: string) {
  const r = await fetch(`${URL_}/rest/v1/${pfad}`, {
    headers: { apikey: KEY, Authorization: `Bearer ${KEY}`, origin },
  });
  if (!r.ok) return null;
  return r.json();
}

export async function markeFuer(host: string): Promise<Marke> {
  const h = (host || '').toLowerCase().split(':')[0];
  if (!URL_ || !KEY || !h) return PLATTFORM;
  const origin = `https://${h}`;
  const kandidaten = [...new Set([h, h.replace(/^www\./, ''), 'www.' + h.replace(/^www\./, '')])];
  let tenantId: string | null = null;
  for (const k of kandidaten) {
    const z = await rest(`public_tenant_domains?select=tenantId&domain=eq.${encodeURIComponent(k)}`, origin);
    if (z?.[0]?.tenantId) { tenantId = z[0].tenantId; break; }
  }
  if (!tenantId) return PLATTFORM;

  const z = await rest(`public_settings?select=branding&id=eq.branding&tenantId=eq.${encodeURIComponent(tenantId)}`, origin);
  const b = z?.[0]?.branding || {};
  const name = text(b.associationName) || tenantId;
  return {
    tenantId,
    name,
    // Unter dem Symbol auf dem Startbildschirm ist Platz fuer etwa
    // zwoelf Zeichen; laengere Namen schneidet das System ab.
    kurz: text(b.appKurzname) || (name.length <= 12 ? name : name.split(/\s+/).pop()!.slice(0, 12)),
    farbe: /^#[0-9a-f]{3,8}$/i.test(b.primary || '') ? b.primary : '#f43f5e',
    hintergrund: '#ffffff',
    logoUrl: b.logoUrl || null,
  };
}
