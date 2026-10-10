import React, { useEffect, useState } from 'react';
import { useParams, Navigate } from 'react-router-dom';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Eine vom Verein selbst gebaute Seite.
//
// Der Inhalt besteht aus Bausteinen mit festen Arten, nicht aus HTML.
// Das ist der Kern: was im Browser eines Besuchers laeuft, entscheidet
// diese Datei, nicht der eingegebene Text. Ein Freitextfeld fuer HTML
// waere bequemer zu bauen und ein Einfallstor -- wer die Website
// bearbeiten darf, koennte Besuchern Beliebiges unterschieben.
//
// Entwuerfe sind fuer Besucher unsichtbar; das entscheidet die
// Zeilenregel in der Datenbank, nicht diese Maske.

type Mehrsprachig = { de?: string; sq?: string; en?: string } | string;
type Baustein =
  | { art: 'ueberschrift'; text: Mehrsprachig }
  | { art: 'text'; text: Mehrsprachig }
  | { art: 'zitat'; text: Mehrsprachig; wer?: Mehrsprachig }
  | { art: 'bild'; url: string; alt?: Mehrsprachig }
  | { art: 'knopf'; text: Mehrsprachig; ziel: string }
  | { art: 'trenner' };

type Seite = { id: string; pfad: string; titel: Mehrsprachig; bloecke: Baustein[] };

// Ein Ziel darf nur hierhin oder auf eine gewoehnliche Webadresse zeigen.
// Ohne diese Pruefung liesse sich javascript: in einen Knopf schreiben.
const sicheresZiel = (z: string): string | null => {
  const s = String(z ?? '').trim();
  if (!s) return null;
  if (s.startsWith('/') || s.startsWith('#')) return s;
  if (/^https?:\/\//i.test(s)) return s;
  if (/^mailto:|^tel:/i.test(s)) return s;
  return null;
};

export const SeitenInhalt: React.FC<{ bloecke: Baustein[] }> = ({ bloecke }) => {
  const { loc } = useTranslation();
  return (
    <div className="space-y-6">
      {(bloecke ?? []).map((b, i) => {
        switch (b?.art) {
          case 'ueberschrift':
            return (
              <h2 key={i} className="text-2xl md:text-3xl font-display font-bold text-stone-900 pt-4">
                {loc(b.text)}
              </h2>
            );
          case 'text':
            return (
              <div key={i} className="text-stone-700 leading-relaxed space-y-4">
                {loc(b.text).split(/\n{2,}/).map((abs, n) => (
                  <p key={n} className="whitespace-pre-line">{abs}</p>
                ))}
              </div>
            );
          case 'zitat':
            return (
              <blockquote key={i} className="border-l-2 border-[color:var(--primary)] pl-5 py-1">
                <p className="text-lg italic text-stone-700 leading-relaxed">{loc(b.text)}</p>
                {b.wer && <footer className="text-xs text-stone-400 mt-2">{loc(b.wer)}</footer>}
              </blockquote>
            );
          case 'bild':
            return sicheresZiel(b.url) ? (
              <figure key={i}>
                <img src={b.url} alt={loc(b.alt) || ''} loading="lazy"
                     className="w-full rounded-3xl border border-stone-100" />
                {loc(b.alt) && (
                  <figcaption className="text-[11px] text-stone-400 mt-2">{loc(b.alt)}</figcaption>
                )}
              </figure>
            ) : null;
          case 'knopf': {
            const ziel = sicheresZiel(b.ziel);
            if (!ziel) return null;
            const extern = /^https?:\/\//i.test(ziel);
            return (
              <p key={i}>
                <a href={ziel}
                   {...(extern ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
                   className="inline-flex items-center gap-2 bg-stone-900 text-white px-6 py-3
                              rounded-2xl text-xs font-bold uppercase tracking-widest
                              hover:bg-stone-800 transition-colors">
                  {loc(b.text) || ziel}
                </a>
              </p>
            );
          }
          case 'trenner':
            return <hr key={i} className="border-stone-100" />;
          default:
            return null;
        }
      })}
    </div>
  );
};

const EigeneSeite: React.FC = () => {
  const { pfad } = useParams<{ pfad: string }>();
  const { loc } = useTranslation();
  const [seite, setSeite] = useState<Seite | null | undefined>(undefined);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const { data } = await supabase.from('seiten')
        .select('id,pfad,titel,bloecke').eq('pfad', String(pfad ?? '')).maybeSingle();
      if (lebt) setSeite((data as Seite) ?? null);
    })();
    return () => { lebt = false; };
  }, [pfad]);

  // undefined = laedt noch, null = gibt es nicht.
  if (seite === undefined) {
    return <div className="min-h-[60vh] flex items-center justify-center">
      <div className="w-6 h-6 border-2 border-stone-200 border-t-stone-900 rounded-full animate-spin" />
    </div>;
  }
  if (seite === null) return <Navigate to="/" replace />;

  return (
    <article className="max-w-3xl mx-auto px-6 py-16 md:py-24">
      <h1 className="text-4xl md:text-5xl font-display font-bold italic text-stone-900 mb-10">
        {loc(seite.titel)}
      </h1>
      <SeitenInhalt bloecke={seite.bloecke} />
    </article>
  );
};

export default EigeneSeite;
