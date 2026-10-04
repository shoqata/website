import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { collection, doc, getDoc, getDocs, onSnapshot, query, supabase } from '@/services/supabase-bridge';
import { db } from '../services/datenzugriff';
import { useTranslation } from '../context/LanguageContext';
import { onImageError } from '../lib/imageFallback';

// Die erzaehlende Startseite -- das Modul "Startseite Premium".
//
// Gesteuert wird sie vom Kern unter public/scrollcraft (MIT, Herkunft siehe
// dort). Der Kern erzeugt kein Markup: er liest data-sc-*-Attribute an dem
// HTML, das hier steht, und treibt sie aus einem einzigen Scrollwert. Das
// Markup gehoert also uns, die Bewegung ihm.
//
// Zwei Dinge bestimmen den Aufbau:
//
// 1. Diese Seite wird an Vereine verkauft, nicht an Koretini. Sie darf
//    deshalb keine Bildersammlung voraussetzen -- gemessen am 27.09.2026:
//    0 von 340 Mitgliedern haben ein Foto, und settings/branding war fuer
//    Koretini gar nicht angelegt. Die Wirkung kommt aus Schrift, Bewegung
//    und den eigenen Zahlen des Vereins; Bilder werden benutzt, wo welche
//    da sind, und fehlen sonst ohne Luecke.
//
// 2. Der Kern laedt erst hier und nicht im Bundle. Vereine ohne das Modul
//    zahlen die 1211 Zeilen nicht mit.

type Marke = {
  heroTitle?: any; heroSubtitle?: any; heroBadge?: any;
  heroImages?: string[]; missions?: any[]; whyJoinText?: any; logoUrl?: string;
};

const textVon = (wert: any, sprache: string): string => {
  if (!wert) return '';
  if (typeof wert === 'string') return wert;
  return wert[sprache] || wert.de || wert.sq || wert.en || '';
};

const KERN_JS = '/scrollcraft/scrollcraft.js';
const KERN_CSS = '/scrollcraft/scrollcraft.css';

// Das Stylesheet des Kerns setzt body global: Hintergrund, Textfarbe,
// Schriftart, Schriftgroesse. Fuer ein Dokument mit einer Seite richtig, hier
// nicht -- einmal geladen faerbte es auch Veranstaltungen, Nachrichten und die
// Verwaltung um, sobald jemand einmal auf der Startseite war. Es wird deshalb
// beim Betreten eingehaengt und beim Verlassen wieder entfernt.
function stilEinhaengen(): HTMLLinkElement {
  let l = document.querySelector(`link[href="${KERN_CSS}"]`) as HTMLLinkElement | null;
  if (!l) {
    l = document.createElement('link');
    l.rel = 'stylesheet'; l.href = KERN_CSS;
    document.head.appendChild(l);
  }
  return l;
}

// Das Skript darf bleiben: es tut von sich aus nichts, solange niemand
// ScrollCraft.mount() ruft. Ein zweites Laden waere nur Verkehr.
function kernLaden(): Promise<void> {
  return new Promise((fertig, scheitern) => {
    if ((window as any).ScrollCraft) return fertig();
    let s = document.querySelector(`script[src="${KERN_JS}"]`) as HTMLScriptElement | null;
    if (s) { s.addEventListener('load', () => fertig()); return; }
    s = document.createElement('script');
    s.src = KERN_JS; s.async = true;
    s.onload = () => fertig();
    s.onerror = () => scheitern(new Error('scrollcraft konnte nicht geladen werden'));
    document.head.appendChild(s);
  });
}

const StartseitePremium: React.FC = () => {
  const { t, language } = useTranslation() as any;
  const sprache = language || 'de';
  const wurzel = useRef<HTMLDivElement>(null);

  const [marke, setMarke] = useState<Marke>({});
  const [mitglieder, setMitglieder] = useState(0);
  const [diaspora, setDiaspora] = useState(0);
  const [beitraege, setBeitraege] = useState<any>(null);
  const [anlaesse, setAnlaesse] = useState<any[]>([]);
  const [zahlung, setZahlung] = useState<any>(null);
  const [bereit, setBereit] = useState(false);

  useEffect(() => {
    (async () => {
      const [b, z, s] = await Promise.all([
        getDoc(doc(db, 'public_settings', 'branding')).catch(() => null),
        getDoc(doc(db, 'public_settings', 'payment')).catch(() => null),
        supabase.rpc('beitragsstand_oeffentlich'),
      ]);
      if (b?.exists()) setMarke(b.data() as Marke);
      if (z?.exists()) setZahlung(z.data());
      if (!s.error) setBeitraege(s.data);
    })();

    const ab = onSnapshot(collection(db, 'public_members'), (snap) => {
      const alle = snap.docs.map((d: any) => d.data());
      const aktiv = alle.filter((m: any) => m.membershipStatus === 'ACTIVE');
      setMitglieder(aktiv.length);
      setDiaspora(aktiv.filter((m: any) => !m.livesInKoretin).length);
    });

    (async () => {
      const e = await getDocs(query(collection(db, 'events')));
      const kommend = e.docs.map((d: any) => ({ id: d.id, ...d.data() }))
        .filter((x: any) => x.date && new Date(x.date) >= new Date(Date.now() - 864e5))
        .sort((a: any, b: any) => new Date(a.date).getTime() - new Date(b.date).getTime());
      setAnlaesse(kommend.slice(0, 3));
    })().catch(() => { /* ohne Anlaesse entfaellt der Akt */ });

    setBereit(true);
    return () => ab();
  }, []);

  // Der Kern wird erst eingehaengt, wenn das Markup wirklich steht -- er
  // misst Zeilenhoehen und Positionen, und auf halb gefuelltem Markup
  // misst er falsch.
  useEffect(() => {
    if (!bereit || !wurzel.current) return;
    let instanz: any = null;
    let abgebrochen = false;
    const stil = stilEinhaengen();
    // Die Navigationsleiste liegt ausserhalb dieser Seite und ist fuer hellen
    // Grund gemacht. Hier kennzeichnen statt dort umbauen: so bleibt sie
    // ueberall sonst unveraendert.
    document.documentElement.dataset.startseite = 'premium';

    kernLaden().then(() => {
      if (abgebrochen || !wurzel.current) return;
      const SC = (window as any).ScrollCraft;
      if (!SC) return;
      instanz = SC.mount(wurzel.current);
    }).catch(() => { /* ohne Kern bleibt die Seite lesbar, nur ohne Bewegung */ });

    return () => {
      abgebrochen = true;
      // destroy() ist ein Zusatz dieser Anwendung; ohne ihn liefe die
      // Bildschleife auf abgehaengtem Markup weiter. Siehe
      // public/scrollcraft/HERKUNFT.md.
      if (instanz && typeof instanz.destroy === 'function') instanz.destroy();
      stil.remove();
      delete document.documentElement.dataset.startseite;
    };
  }, [bereit, mitglieder, anlaesse.length, beitraege]);

  const titel = textVon(marke.heroTitle, sprache);
  const unter = textVon(marke.heroSubtitle, sprache);
  const abzeichen = textVon(marke.heroBadge, sprache);
  const warum = textVon(marke.whyJoinText, sprache);
  const bilder = (marke.heroImages || []).filter(Boolean);
  const missionen = (marke.missions || []).slice(0, 4);

  return (
    <div ref={wurzel} className="sc-seite">
      {/* Die Farben der Bewegung leiten sich aus der Vereinsfarbe ab. Ein
          zweites Farbschema waere ein zweiter Ort, an dem eine Umfaerbung
          vergessen wird. */}
      <style>{`
        .sc-seite {
          --sc-canvas: #0b0c10;
          --sc-surface: #14161d;
          --sc-ink: #f6f5f3;
          --sc-ink-soft: #9b9ca4;
          --sc-accent: var(--primary, #f43f5e);
          --sc-accent-ink: #0b0c10;
          background: var(--sc-canvas);
          color: var(--sc-ink);
          min-height: 100vh;
        }
        /* Die Leiste steht ausserhalb dieser Seite, deshalb ueber das
           Kennzeichen am Wurzelelement statt ueber .sc-seite. */
        html[data-startseite="premium"] nav > div {
          background: rgba(11,12,16,.62) !important;
          border: 1px solid rgba(255,255,255,.12);
          box-shadow: 0 10px 30px -18px rgba(0,0,0,.9);
        }
        html[data-startseite="premium"] nav a,
        html[data-startseite="premium"] nav button { color: #f6f5f3; }
        html[data-startseite="premium"] nav a:hover { color: var(--primary, #f43f5e); }

        .sc-seite .zahl { font-variant-numeric: tabular-nums; }
        .sc-seite .marke-zeile {
          display: flex; align-items: baseline; gap: 14px; flex-wrap: wrap;
        }
        .sc-seite .knopf {
          display: inline-flex; align-items: center; gap: 10px;
          padding: 14px 26px; border-radius: 999px; font-weight: 600;
          background: var(--sc-accent); color: var(--sc-accent-ink);
          text-decoration: none;
        }
        .sc-seite .knopf--leise {
          background: transparent; color: var(--sc-ink);
          border: 1px solid rgba(255,255,255,.22);
        }
        .sc-seite .schluss { padding-block: 22vh; }
        .sc-seite .gitter {
          display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
          gap: 40px; width: min(1100px, 92vw);
        }
        .sc-seite .karte {
          border-top: 1px solid rgba(255,255,255,.14); padding-top: 18px;
        }
        .sc-seite .karte h3 { font-size: 1.05rem; margin: 0 0 8px; font-weight: 600; }
        .sc-seite .karte p { margin: 0; color: var(--sc-ink-soft); line-height: 1.6; font-size: .95rem; }
        .sc-seite .band {
          display: flex; gap: 28px; align-items: center;
          position: absolute; top: 0; bottom: 0; left: 6vw;
          padding-right: 12vw;
        }
        .sc-seite .band figure {
          margin: 0; width: min(62vw, 460px); flex: none;
          border-radius: 18px; overflow: hidden; background: var(--sc-surface);
          /* Ohne Bild blieben nur zwei Zeilen uebrig, und die Karte wirkte
             verloren in einer 900 Pixel hohen Buehne. */
          min-height: 340px; display: flex; flex-direction: column;
          justify-content: flex-end;
          border: 1px solid rgba(255,255,255,.07);
        }
        .sc-seite .band img { width: 100%; height: 240px; object-fit: cover; display: block; }
        .sc-seite .band figcaption { padding: 26px 28px; }
        .sc-seite .hintergrundbild {
          position: absolute; inset: 0; width: 100%; height: 100%;
          object-fit: cover; opacity: .45;
        }
      `}</style>

      <span data-sc-progress aria-hidden="true"></span>
      <div className="sc-grain" aria-hidden="true"></div>

      {/* Die Akte wechseln das Mittel und wiederholen keines zweimal
          hintereinander: pin, flow, pan, pin, flow. Ein vierter Typ -- scrub --
          braucht Filmmaterial; das hat ein Verein in aller Regel nicht, und
          eine erfundene Zutat waere schlechter als drei ehrliche. */}

      {/* 1 · Ankunft. Gepinnt, damit die Schrift das ganze Bild bekommt.
          Liegt ein Bild vor, traegt es den Akt; sonst traegt ihn die Schrift. */}
      <section data-sc-act="pin" data-sc-span="1.8" data-sc-drift="#0b0c10">
        <div data-sc-stage>
          {bilder[0] && (
            <img className="hintergrundbild" src={bilder[0]} alt="" onError={onImageError} />
          )}
          <div className="sc-scrim sc-scrim--lead" aria-hidden="true"></div>
          <div className="sc-copy sc-copy--lead" data-sc-cue="0 0.75 0">
            {abzeichen && <p className="sc-label">{abzeichen}</p>}
            <h1 className="sc-display sc-display--xl" data-sc-kinetic="lines">
              {titel || t('hero.title')}
            </h1>
            {unter && <p className="sc-lede">{unter}</p>}
          </div>
        </div>
      </section>

      {/* 2 · Wer dahintersteht. Im Fluss, nicht gepinnt: eine Bühne haette hier
          nur 0 px Hoehe -- der Kern macht aus [data-sc-stage] nur bei
          gepinnten Akten eine Buehne, und .sc-copy ist absolut gesetzt.
          Genau daran war der erste Entwurf unsichtbar. */}
      <section data-sc-act="flow" className="sc-section">
        <div className="sc-wrap">
          <p className="sc-label" data-sc-cue="0 0.35">{t('prem.wer_titel')}</p>
          <div className="gitter" style={{ marginTop: 34 }}>
            <div data-sc-cue="0.05 0.5">
              <p className="sc-display sc-display--lg zahl" data-sc-count={`0 ${mitglieder}`}>0</p>
              <p className="sc-body">{t('prem.mitglieder')}</p>
            </div>
            <div data-sc-cue="0.15 0.6">
              <p className="sc-display sc-display--lg zahl" data-sc-count={`0 ${diaspora}`}>0</p>
              <p className="sc-body">{t('prem.diaspora')}</p>
            </div>
            {beitraege && beitraege.stellung !== 'AUS' && Number(beitraege.anzahl) > 0 && (
              <div data-sc-cue="0.25 0.7">
                <p className="sc-display sc-display--lg zahl"
                   data-sc-count={`0 ${beitraege.stellung === 'NAMEN' ? (beitraege.namen || []).length : beitraege.anzahl}`}>0</p>
                <p className="sc-body">{t('prem.beitraege', { jahr: beitraege.jahr })}</p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* 3 · Wofuer. Quer laufend. */}
      {missionen.length > 0 && (
        <section data-sc-act="pan" data-sc-span="2.2">
          <div data-sc-stage>
            <div className="sc-copy sc-copy--lead" style={{ top: '14vh' }}>
              <p className="sc-label">{t('prem.wofuer')}</p>
            </div>
            <div className="band" data-sc-pan="0.66">
              {missionen.map((m: any, i: number) => (
                <figure key={i}>
                  {m.image && <img src={m.image} alt="" onError={onImageError} />}
                  <figcaption>
                    <h3>{textVon(m.title, sprache)}</h3>
                    <p className="sc-body">{textVon(m.description, sprache)}</p>
                  </figcaption>
                </figure>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* 4 · Was als naechstes ansteht. Entfaellt ohne Anlaesse -- ein leerer
          Akt waere schlimmer als keiner. */}
      {anlaesse.length > 0 && (
        <section data-sc-act="pin" data-sc-span="2.2" data-sc-drift="#0b0c10">
          <div data-sc-stage>
            <div className="sc-copy sc-copy--center">
              <p className="sc-label" data-sc-cue="0 0.35">{t('prem.naechstes')}</p>
              <div className="gitter" style={{ marginTop: 30 }}>
                {anlaesse.map((a: any, i: number) => (
                  <div className="karte" key={a.id} data-sc-cue={`${0.08 + i * 0.12} ${0.55 + i * 0.12}`}>
                    <p className="sc-label" style={{ marginBottom: 8 }}>
                      {new Date(a.date).toLocaleDateString(sprache === 'sq' ? 'sq-AL' : 'de-CH',
                        { day: '2-digit', month: 'long' })}
                    </p>
                    <h3>{a.title}</h3>
                    {a.location && <p>{a.location}</p>}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      )}

      {/* 5 · Der Schluss, als letztes Element der Seite -- so erwartet es der
          Kern, und inhaltlich gehoert die Bitte ans Ende. */}
      <section data-sc-act="flow" className="sc-section schluss">
        <div className="sc-wrap" style={{ textAlign: 'center' }}>
          <h2 className="sc-display sc-display--lg" data-sc-cue="0 0.6" data-sc-kinetic="words">
            {warum || t('prem.schluss_titel')}
          </h2>
          <div className="marke-zeile" data-sc-cue="0.2 0.8"
               style={{ justifyContent: 'center', marginTop: 30 }}>
            <Link to="/register" className="knopf">{t('hero.cta.register')}</Link>
            <Link to="/spenden" className="knopf knopf--leise">{t('nav.spenden')}</Link>
            {zahlung?.twintUrl && (
              <a href={zahlung.twintUrl} className="knopf knopf--leise"
                 target="_blank" rel="noopener noreferrer">TWINT</a>
            )}
          </div>
        </div>
      </section>
    </div>
  );
};

export default StartseitePremium;
