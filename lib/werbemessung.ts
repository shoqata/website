// Werbemessung: Meta-Pixel und Google-Conversion.
//
// Damit lassen sich Anzeigen auf unityhub.li auswerten -- wie viele
// Besucher kommen, und wer von ihnen das Anfrageformular abschickt.
//
// Vier Regeln entscheiden, ob ueberhaupt etwas geladen wird. Sie stehen
// hier als EINE pruefbare Funktion, nicht verteilt in Komponenten:
//
// 1. NUR AUF DER BETREIBERSEITE. Auf einer Vereinsdomain laedt nichts,
//    auch nicht mit Zustimmung und eingetragenen IDs. Die Mitglieder von
//    koretini.me haben sich bei ihrem Verein angemeldet, nicht bei einer
//    Werbeplattform -- ihr Besuch auf der Vereinsseite gehoert nicht zu
//    unityhubs Reichweite. Das ist keine Einstellung, sondern eine
//    Grenze.
//
// 2. NUR MIT ZUSTIMMUNG. Der Hinweis speichert "accepted" oder
//    "declined". Bisher las die Antwort NIEMAND -- der Hinweis fragte
//    nach Zustimmung zu nichts und zeichnete sie folgenlos auf. Wer
//    ablehnt, bekommt jetzt wirklich nichts geladen.
//
// 3. NUR MIT ID. Ohne Pixel-ID bzw. Conversion-ID gibt es nichts zu
//    melden. Ein Skript ohne Ziel zu laden waere reine Verlangsamung.
//
// 4. NUR EINMAL. Zweimal geladen, zweimal gezaehlt -- und dann stimmt
//    die Auswertung nicht, nach der die Anzeigen ausgesteuert werden.

export type Zustimmung = 'accepted' | 'declined' | null;

export type Lage = {
  istPlattform: boolean | null;
  zustimmung: Zustimmung;
  metaPixel?: string | null;
  googleAds?: string | null;
};

export type Entscheid = {
  meta: boolean;
  google: boolean;
  grund: string;
};

export function darfMessen(l: Lage): Entscheid {
  const nichts = (grund: string): Entscheid => ({ meta: false, google: false, grund });

  // Unbekannt ist nicht "ja". Solange nicht feststeht, wem die Adresse
  // gehoert, wird nichts geladen -- sonst entscheidet der Zufall des
  // ersten Bildes darueber, ob ein Vereinsbesucher gemessen wird.
  if (l.istPlattform !== true) {
    return nichts(l.istPlattform === null
      ? 'Noch nicht bekannt, wem die Adresse gehoert.'
      : 'Vereinsseite — hier wird nicht fuer unityhub gemessen.');
  }
  if (l.zustimmung !== 'accepted') {
    return nichts(l.zustimmung === 'declined'
      ? 'Der Besucher hat abgelehnt.'
      : 'Es liegt keine Zustimmung vor.');
  }

  const meta = !!String(l.metaPixel ?? '').trim();
  const google = !!String(l.googleAds ?? '').trim();
  if (!meta && !google) return nichts('Keine Pixel- oder Conversion-ID eingetragen.');

  return {
    meta, google,
    grund: [meta && 'Meta', google && 'Google'].filter(Boolean).join(' und ') + ' gemessen.',
  };
}

// Der Schluessel, unter dem der Hinweis die Antwort ablegt. Dieselbe
// Schreibweise wie in CookieConsent -- darum hier, damit sie nicht an
// zwei Stellen gepflegt wird und auseinanderlaeuft.
export const zustimmungSchluessel = (istPlattform: boolean): string =>
  istPlattform ? 'cookie-consent-unityhub' : 'cookie-consent-koretini';

// Die Fassung des Hinweises. Erhoehen, sobald sich aendert, WOZU
// zugestimmt wird (ein neuer Dienst, ein neuer Zweck): eine Zustimmung
// gilt nur fuer das, was beim Klick dastand. Danach fragt der Hinweis
// alle erneut.
export const ZUSTIMMUNG_VERSION = 1;

type Stand = { wert: 'accepted' | 'declined'; version: number; zeit: string };

const standSchluessel = (istPlattform: boolean) => zustimmungSchluessel(istPlattform) + '-stand';

export function zustimmungLesen(istPlattform: boolean | null): Zustimmung {
  if (istPlattform === null || typeof localStorage === 'undefined') return null;
  try {
    const w = localStorage.getItem(zustimmungSchluessel(istPlattform));
    if (w !== 'accepted' && w !== 'declined') return null;
    // Antworten von vor der Versionierung haben keinen Stand -- sie
    // stammen aus Fassung 1.
    const roh = localStorage.getItem(standSchluessel(istPlattform));
    const version = roh ? Number((JSON.parse(roh) as Stand).version) : 1;
    return version === ZUSTIMMUNG_VERSION ? w : null;
  } catch {
    return null;
  }
}

// Die Antwort ablegen: der Wert selbst und daneben, wann und zu welcher
// Fassung. Gibt zurueck, ob eine Zustimmung damit zurueckgenommen wurde.
export function zustimmungSpeichern(istPlattform: boolean, wert: 'accepted' | 'declined'): boolean {
  const vorher = zustimmungLesen(istPlattform);
  try {
    localStorage.setItem(zustimmungSchluessel(istPlattform), wert);
    const stand: Stand = { wert, version: ZUSTIMMUNG_VERSION, zeit: new Date().toISOString() };
    localStorage.setItem(standSchluessel(istPlattform), JSON.stringify(stand));
  } catch { /* ohne Speicher gilt die Antwort nur fuer diesen Besuch */ }
  return vorher === 'accepted' && wert === 'declined';
}

// Was die beiden Dienste im Browser hinterlassen. Beim Widerruf wird es
// entfernt -- ein Widerruf, nach dem die Kennung weiterlebt, hiesse nur,
// dass sie beim naechsten Laden wieder auftaucht.
const WERBE_COOKIES = /^(_fbp|_fbc|_gcl_|_ga|_gid|_gat)/;

export function werbeCookiesLoeschen(): void {
  if (typeof document === 'undefined') return;
  const host = location.hostname;
  const bereiche = ['', host, '.' + host, '.' + host.split('.').slice(-2).join('.')];
  for (const teil of document.cookie.split(';')) {
    const name = teil.split('=')[0].trim();
    if (!WERBE_COOKIES.test(name)) continue;
    for (const b of bereiche) {
      document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/${b ? '; domain=' + b : ''}`;
    }
  }
}

// Ist schon ein Skript geladen? Dann hilft beim Widerruf nur ein
// Neuladen: ein geladenes Pixel laesst sich nicht wieder entfernen.
export const messungGeladen = (): boolean => geladen.meta || geladen.google;

// ------------------------------------------------------------ Laden
//
// Die Skripte werden erst nach der Zustimmung eingefuegt, nicht beim
// Seitenaufbau mit einem Schalter davor. Ein geladenes Meta-Skript
// nimmt Verbindung auf, bevor irgendein Schalter greift -- und dann ist
// der Besucher gemessen, unabhaengig davon, was er anschliessend
// anklickt.

let geladen = { meta: false, google: false };

const skript = (src: string, id: string) => {
  if (document.getElementById(id)) return;
  const s = document.createElement('script');
  s.id = id; s.async = true; s.src = src;
  document.head.appendChild(s);
};

function metaLaden(pixel: string) {
  if (geladen.meta) return;
  geladen.meta = true;
  const w = window as any;
  if (!w.fbq) {
    const n: any = (...args: any[]) => { n.callMethod ? n.callMethod(...args) : n.queue.push(args); };
    n.push = n; n.loaded = true; n.version = '2.0'; n.queue = [];
    w.fbq = n; w._fbq = n;
  }
  skript('https://connect.facebook.net/en_US/fbevents.js', 'meta-pixel');
  w.fbq('init', pixel);
  w.fbq('track', 'PageView');
}

function googleLaden(ads: string) {
  if (geladen.google) return;
  geladen.google = true;
  const w = window as any;
  w.dataLayer = w.dataLayer || [];
  w.gtag = w.gtag || function gtag() { w.dataLayer.push(arguments); };
  skript(`https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(ads)}`, 'google-tag');
  w.gtag('js', new Date());
  // anonymize_ip: fuer die Auswertung einer Anzeige braucht es die
  // vollstaendige Adresse des Besuchers nicht.
  w.gtag('config', ads, { anonymize_ip: true });
}

export function messungStarten(l: Lage): Entscheid {
  const e = darfMessen(l);
  if (typeof window === 'undefined' || typeof document === 'undefined') return e;
  if (e.meta) metaLaden(String(l.metaPixel).trim());
  if (e.google) googleLaden(String(l.googleAds).trim());
  return e;
}

// Wie wird eine Anfrage gemeldet?
//
// Die beiden Anbieter verlangen verschiedene Aufrufe, und das ist keine
// Kleinigkeit: der falsche Aufruf laeuft ohne Fehler durch und wird
// nirgends gezaehlt.
//
//   Meta    fbq('track','Lead')  -- ein Standardereignis
//   Google  mit Conversion-Label: gtag('event','conversion',
//             {send_to: 'AW-123/LABEL'})  -- so verlangt es Google Ads
//           ohne Label: gtag('event','generate_lead') -- messbar in
//             GA4, aber KEINE Ads-Conversion
//
// Darum steht der Plan als pruefbare Funktion da und nicht als
// Verzweigung mitten im Formular.
export type Meldung = { ziel: 'meta' | 'google'; name: string; daten?: Record<string, any> };

export function anfragePlan(
  e: Pick<Entscheid, 'meta' | 'google'>, googleLabel?: string | null,
): Meldung[] {
  const plan: Meldung[] = [];
  if (e.meta) plan.push({ ziel: 'meta', name: 'Lead' });
  if (e.google) {
    const label = String(googleLabel ?? '').trim();
    plan.push(label
      ? { ziel: 'google', name: 'conversion', daten: { send_to: label } }
      // Ohne Label ist es keine Ads-Conversion. Es wird trotzdem
      // gemeldet -- messbar ist besser als nichts --, aber der Name
      // sagt, was es ist.
      : { ziel: 'google', name: 'generate_lead' });
  }
  return plan;
}

// Ein Ereignis melden -- etwa eine abgeschickte Anfrage.
//
// Meldet NUR an das, was wirklich geladen ist. Ein Ereignis an ein nicht
// geladenes Ziel zu schicken waere ein stiller Fehlschlag: die Zahl
// fehlte in der Auswertung, und niemand wuesste, warum.
export function ereignis(name: string, daten?: Record<string, any>): string[] {
  const gemeldet: string[] = [];
  const w = window as any;
  if (geladen.meta && w.fbq) { w.fbq('track', name, daten); gemeldet.push('Meta'); }
  if (geladen.google && w.gtag) { w.gtag('event', name, daten); gemeldet.push('Google'); }
  return gemeldet;
}

// Nur fuer Tests: den Ladezustand zuruecksetzen.
export function _zuruecksetzen() { geladen = { meta: false, google: false }; }


// Die Anfrage melden. Fuehrt den Plan aus und gibt zurueck, was
// wirklich gemeldet wurde -- nicht, was gemeldet werden sollte.
export function anfrageMelden(googleLabel?: string | null): string[] {
  const w = window as any;
  const plan = anfragePlan(geladen, googleLabel);
  const getan: string[] = [];
  for (const m of plan) {
    if (m.ziel === 'meta' && w.fbq) { w.fbq('track', m.name, m.daten); getan.push('Meta'); }
    if (m.ziel === 'google' && w.gtag) { w.gtag('event', m.name, m.daten); getan.push('Google'); }
  }
  return getan;
}
