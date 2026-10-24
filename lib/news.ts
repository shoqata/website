import { useEffect, useState } from 'react';
import { supabase } from '@/services/supabase-bridge';

// Neuigkeiten fuer die oeffentliche Website: laden, Text in Absaetze,
// Likes, Teilen.

export type Nachricht = {
  id: string; title: string; content: any; image: string | null;
  timestamp: string | null; publishAt: string | null; author: string | null;
  category: string | null; subcategory: string | null; location: string | null; status: string;
};

// Der Inhalt liegt als Text in der Datenbank. Die Ansicht erwartete eine
// Liste von Absaetzen (content.map) und stuerzte bei jeder Nachricht ab;
// der Editor zeigte nur den ersten Buchstaben (content[0] eines Textes).
// Aeltere Eintraege koennen auch eine Liste oder eine als Text
// gespeicherte Liste sein -- alle drei Formen gelten.
export function absaetze(inhalt: any): string[] {
  if (Array.isArray(inhalt)) return inhalt.map(String).flatMap(absaetze);
  if (typeof inhalt !== 'string') return [];
  const s = inhalt.trim();
  if (s.startsWith('[') && s.endsWith(']')) {
    try { const l = JSON.parse(s); if (Array.isArray(l)) return absaetze(l); } catch { /* Text */ }
  }
  return s.split(/\n\s*\n/).map(a => a.trim()).filter(Boolean);
}
export const inhaltAlsText = (inhalt: any) => absaetze(inhalt).join('\n\n');

export const nachrichtDatum = (n: Pick<Nachricht, 'publishAt' | 'timestamp'>) =>
  n.publishAt || n.timestamp;

export function datumLang(iso: string | null, sprache: string) {
  if (!iso) return '';
  const gebiet = sprache === 'de' ? 'de-CH' : sprache === 'sq' ? 'sq-AL' : 'en-GB';
  try { return new Date(iso).toLocaleDateString(gebiet, { day: 'numeric', month: 'long', year: 'numeric' }); }
  catch { return ''; }
}

// "vor 3 Tagen" -- in der Sprache der Seite statt fest auf Englisch.
export function vorZeit(iso: string | null, sprache: string) {
  if (!iso) return '';
  const s = (new Date(iso).getTime() - Date.now()) / 1000;
  const rtf = new Intl.RelativeTimeFormat(sprache === 'sq' ? 'sq' : sprache === 'en' ? 'en' : 'de', { numeric: 'auto' });
  const stufen: [Intl.RelativeTimeFormatUnit, number][] =
    [['year', 31536000], ['month', 2592000], ['week', 604800], ['day', 86400], ['hour', 3600], ['minute', 60]];
  for (const [e, n] of stufen) if (Math.abs(s) >= n) return rtf.format(Math.round(s / n), e);
  return rtf.format(0, 'minute');
}

export function useNachrichten(): Nachricht[] | null {
  const [liste, setListe] = useState<Nachricht[] | null>(null);
  useEffect(() => {
    let lebt = true;
    supabase.from('news')
      .select('id,title,content,image,timestamp,publishAt,author,category,subcategory,location,status')
      .eq('status', 'PUBLISHED').order('timestamp', { ascending: false }).limit(60)
      .then(({ data }) => {
        if (!lebt) return;
        const jetzt = Date.now();
        setListe(((data as Nachricht[]) ?? [])
          .filter(n => !n.publishAt || new Date(n.publishAt).getTime() <= jetzt)
          .sort((a, b) => new Date(nachrichtDatum(b) || 0).getTime() - new Date(nachrichtDatum(a) || 0).getTime()));
      }, () => { if (lebt) setListe([]); });
    return () => { lebt = false; };
  }, []);
  return liste;
}

// ------------------------------------------------------------- Likes
// Eine zufaellige Kennung je Browser. Ohne Speicher (privater Modus) gilt
// sie nur fuer diesen Besuch.
let fluechtig: string | null = null;
export function besucherKennung(): string {
  try {
    let k = localStorage.getItem('besucher-kennung');
    if (!k) { k = crypto.randomUUID(); localStorage.setItem('besucher-kennung', k); }
    return k;
  } catch {
    return fluechtig ??= crypto.randomUUID();
  }
}

export type LikeStand = Record<string, { anzahl: number; gelikt: boolean }>;

export function useLikes(ids: string[]) {
  const [stand, setStand] = useState<LikeStand>({});
  const schluessel = ids.join(',');
  useEffect(() => {
    if (!ids.length) return;
    let lebt = true;
    supabase.rpc('news_likes_lesen', { p_ids: ids, p_besucher: besucherKennung() })
      .then(({ data }) => {
        if (!lebt || !data) return;
        const neu: LikeStand = {};
        for (const z of data as any[]) neu[z.news] = { anzahl: z.anzahl, gelikt: z.gelikt };
        setStand(s => ({ ...s, ...neu }));
      });
    return () => { lebt = false; };
  }, [schluessel]);

  const umschalten = async (id: string) => {
    const alt = stand[id] ?? { anzahl: 0, gelikt: false };
    // Sofort zeigen, dann bestaetigen lassen.
    setStand(s => ({ ...s, [id]: { anzahl: alt.anzahl + (alt.gelikt ? -1 : 1), gelikt: !alt.gelikt } }));
    const { data, error } = await supabase.rpc('news_like_umschalten', { p_news: id, p_besucher: besucherKennung() });
    setStand(s => ({ ...s, [id]: error || !data ? alt : { anzahl: (data as any).anzahl, gelikt: (data as any).gelikt } }));
  };
  return { stand, umschalten };
}

// ------------------------------------------------------------ Teilen
export const nachrichtLink = (id: string) =>
  `${window.location.origin}/news/${encodeURIComponent(id)}`;
