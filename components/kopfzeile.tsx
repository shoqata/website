import React, { useEffect, useState } from 'react';
import { Info, Calendar, Newspaper, Zap, Trophy, Film, Heart, BadgeCheck, FileText, History, Mail, MapPinned } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useOeffentlicheModule } from '../lib/useOeffentlicheModule';
import { useSpendenseiteSichtbar } from '../lib/useSpendenseiteSichtbar';

// Die Eintraege der Kopfzeile -- an einer Stelle, fuer die Leiste, das
// Handymenue und die Verwaltung.
//
// Vorher standen sie zweimal von Hand in App.tsx, und die beiden Fassungen
// waren auseinandergelaufen: im Handymenue fehlten Videos und Spenden.
//
// Der Verein bestimmt Reihenfolge und An/Aus (settings.system.navigation).
// Ob ein Eintrag ueberhaupt erscheinen KANN, entscheidet weiterhin das
// gebuchte Modul bzw. die Einstellung der Seite -- ein Verweis auf eine
// Seite, die auf die Startseite umleitet, waere eine Falle.

// ort: wo der Eintrag erscheint -- in der Navigation (oben bzw. in der
// Seitenleiste), in der Fusszeile oder in beiden.
export type NavOrt = 'OBEN' | 'FUSS' | 'BEIDES';
export type NavEinstellung = { schluessel: string; an: boolean; ort?: NavOrt; gruppe?: string | null }[];
export type NavLayout = { computer: 'KOPFZEILE' | 'MEGAMENU' | 'SEITENLEISTE'; handy: 'MENUE' | 'LEISTE' };

// Untermenues: Gruppen, unter denen Eintraege zusammengefasst werden. Mit
// zehn und mehr Eintraegen passt die Kopfzeile nicht mehr auf eine Zeile;
// "Verein", "Aktuell", "Mitmachen" schon. Ohne Gruppen bleibt alles flach.
export type NavGruppe = { id: string; label: any };
export const navGruppen = (w: any): NavGruppe[] =>
  Array.isArray(w) ? w.filter((g: any) => g && typeof g.id === 'string' && g.id) : [];

// Ein Vorschlag fuer den Anfang -- die Verwaltung uebernimmt ihn mit einem
// Klick und passt ihn an.
export const GRUPPEN_VORSCHLAG: { gruppe: NavGruppe; eintraege: string[] }[] = [
  { gruppe: { id: 'verein', label: { de: 'Verein', sq: 'Shoqata', en: 'Association' } }, eintraege: ['about', 'chronik', 'nachbarschaften', 'kontakt'] },
  { gruppe: { id: 'aktuell', label: { de: 'Aktuell', sq: 'Aktuale', en: 'News' } }, eintraege: ['events', 'news', 'live', 'videos'] },
  { gruppe: { id: 'mitmachen', label: { de: 'Mitmachen', sq: 'Merr pjesë', en: 'Get involved' } }, eintraege: ['fussball', 'spenden', 'beitraege'] },
];

// Megamenue ohne eigene Gruppen: dann gilt der Vorschlag. Ein Megamenue
// ohne Untermenues haette nichts aufzuklappen -- genau so sah es im Demo
// aus, nachdem dort "Megamenü" gewaehlt, aber keine Gruppe angelegt war.
export function mitVorschlag(eintraege: NavEintrag[]): { eintraege: NavEintrag[]; gruppen: NavGruppe[] } {
  const zu = new Map<string, string>();
  GRUPPEN_VORSCHLAG.forEach(v => v.eintraege.forEach(k => zu.set(k, v.gruppe.id)));
  return {
    eintraege: eintraege.map(e => ({ ...e, gruppe: e.gruppe || zu.get(e.schluessel) || null })),
    gruppen: GRUPPEN_VORSCHLAG.map(v => v.gruppe),
  };
}

export type NavKnoten =
  | { art: 'eintrag'; eintrag: NavEintrag }
  | { art: 'gruppe'; gruppe: NavGruppe; eintraege: NavEintrag[] };

// Aus der flachen Liste den Baum: eine Gruppe steht dort, wo ihr erster
// Eintrag steht. Leere Gruppen fallen weg, Eintraege mit unbekannter
// Gruppe bleiben einzeln.
export function navBaum(eintraege: NavEintrag[], gruppen: NavGruppe[]): NavKnoten[] {
  const bekannt = new Map(gruppen.map(g => [g.id, g]));
  const knoten: NavKnoten[] = [];
  const offen = new Map<string, NavEintrag[]>();
  for (const e of eintraege) {
    const g = e.gruppe ? bekannt.get(e.gruppe) : undefined;
    if (!g) { knoten.push({ art: 'eintrag', eintrag: e }); continue; }
    const liste = offen.get(g.id);
    if (liste) { liste.push(e); continue; }
    const neu = [e];
    offen.set(g.id, neu);
    knoten.push({ art: 'gruppe', gruppe: g, eintraege: neu });
  }
  return knoten;
}

export const navLayout = (w: any): NavLayout => ({
  computer: w?.computer === 'SEITENLEISTE' ? 'SEITENLEISTE' : w?.computer === 'MEGAMENU' ? 'MEGAMENU' : 'KOPFZEILE',
  handy: w?.handy === 'LEISTE' ? 'LEISTE' : 'MENUE',
});

// Ohne gespeicherte Wahl: wie die Seite bisher war. "Ueber uns", Live und
// Turnier standen oben und in der Fusszeile, der Rest nur oben.
const ORT_BISHER: Record<string, NavOrt> = { about: 'BEIDES', live: 'BEIDES', fussball: 'BEIDES', kontakt: 'BEIDES' };
export const zeigtOben = (e: { ort: NavOrt }) => e.ort !== 'FUSS';
export const zeigtFuss = (e: { ort: NavOrt }) => e.ort !== 'OBEN';

export type NavEintrag = {
  schluessel: string;
  pfad: string;
  label: string;          // Uebersetzungsschluessel oder fertiger Text (eigene Seiten)
  uebersetzen: boolean;
  icon: React.ReactNode;
  iconKlein: React.ReactNode;
  /** Kann der Eintrag gerade erscheinen? Sonst: warum nicht. */
  moeglich: boolean;
  grund?: string;
  an: boolean;
  ort: NavOrt;
  eigeneSeite: boolean;
  /** Eigene Seite mit "Im Menü" -- stand bisher immer in der Fusszeile. */
  imMenue?: boolean;
  /** Untermenue, in dem der Eintrag steht. */
  gruppe?: string | null;
  /** Kurze Beschreibung fuers Megamenue (Uebersetzungsschluessel). */
  beschreibung?: string;
};

type Fest = { schluessel: string; pfad: string; label: string; I: any; farbe: string };
const FEST: Fest[] = [
  { schluessel: 'about',     pfad: '/about',     label: 'nav.about',        I: Info,       farbe: 'text-emerald-600' },
  { schluessel: 'chronik',   pfad: '/chronik',   label: 'nav.chronik',      I: History,    farbe: 'text-amber-700' },
  { schluessel: 'nachbarschaften', pfad: '/nachbarschaften', label: 'nav.nachbarschaften', I: MapPinned, farbe: 'text-teal-600' },
  { schluessel: 'events',    pfad: '/events',    label: 'nav.events.title', I: Calendar,   farbe: 'text-primary' },
  { schluessel: 'news',      pfad: '/news',      label: 'nav.news.title',   I: Newspaper,  farbe: 'text-blue-600' },
  { schluessel: 'live',      pfad: '/live',      label: 'nav.live',         I: Zap,        farbe: 'text-amber-600' },
  { schluessel: 'fussball',  pfad: '/fussball',  label: 'nav.turnier',      I: Trophy,     farbe: 'text-rose-600' },
  { schluessel: 'videos',    pfad: '/videos',    label: 'video.oeff_titel', I: Film,       farbe: 'text-violet-600' },
  { schluessel: 'spenden',   pfad: '/spenden',   label: 'nav.spenden',      I: Heart,      farbe: 'text-primary' },
  { schluessel: 'beitraege', pfad: '/beitraege', label: 'nav.beitraege',    I: BadgeCheck, farbe: 'text-emerald-600' },
  { schluessel: 'kontakt',   pfad: '/kontakt',   label: 'nav.kontakt',      I: Mail,       farbe: 'text-sky-600' },
];

// Eigene Seiten des Vereins, veroeffentlicht. Die Zeilenregel gibt nur die
// des eigenen Vereins heraus.
export function useEigeneSeiten() {
  const [seiten, setSeiten] = useState<{ pfad: string; titel: any; im_menue: boolean }[] | null>(null);
  useEffect(() => {
    let lebt = true;
    supabase.from('seiten').select('pfad,titel,im_menue,reihenfolge').eq('status', 'OEFFENTLICH')
      .order('reihenfolge').limit(30)
      .then(({ data }) => { if (lebt) setSeiten(((data as any[]) ?? [])); }, () => { if (lebt) setSeiten([]); });
    return () => { lebt = false; };
  }, []);
  return seiten;
}

// Gibt es veroeffentlichte Chronik-Eintraege? Ohne sie fuehrte der
// Menueeintrag auf eine leere Seite.
export function useChronikVorhanden() {
  const [da, setDa] = useState<boolean | null>(null);
  useEffect(() => {
    let lebt = true;
    supabase.from('chronik').select('id').eq('status', 'OEFFENTLICH').limit(1)
      .then(({ data }) => { if (lebt) setDa(((data as any[]) ?? []).length > 0); }, () => { if (lebt) setDa(false); });
    return () => { lebt = false; };
  }, []);
  return da;
}

// Gibt es Nachbarschaften mit eingeschalteter Vorstellung?
export function useNachbarschaftenVorhanden() {
  const [da, setDa] = useState<boolean | null>(null);
  useEffect(() => {
    let lebt = true;
    supabase.from('nachbarschaft_profil').select('nachbarschaft').eq('sichtbar', true).limit(1)
      .then(({ data }) => { if (lebt) setDa(((data as any[]) ?? []).length > 0); }, () => { if (lebt) setDa(false); });
    return () => { lebt = false; };
  }, []);
  return da;
}

export function useKopfzeile(opts: {
  einstellung?: NavEinstellung;
  zahlerliste?: { sichtbar?: string };
  angemeldet: boolean;
  /** In der Verwaltung: alle Eintraege, auch ausgeschaltete und unmoegliche. */
  alle?: boolean;
  loc: (v: any) => string;
}): NavEintrag[] | null {
  const module = useOeffentlicheModule();
  const spenden = useSpendenseiteSichtbar();
  const seiten = useEigeneSeiten();
  const chronik = useChronikVorhanden();
  const nachbarschaften = useNachbarschaftenVorhanden();
  if (module === null || seiten === null) return null;

  const zl = (opts.zahlerliste?.sichtbar || 'AUS').toUpperCase();
  // Leere Liste = Abfrage gescheitert (die Kernmodule fehlen nie). Dann
  // bleiben Website, Anlaesse und Neuigkeiten in der Leiste wie bisher.
  const hat = (m: string) => module.size === 0 && ['WEBSITE', 'ANLAESSE', 'NEUIGKEITEN'].includes(m) || module.has(m);
  const moeglich: Record<string, [boolean, string?]> = {
    about: [hat('WEBSITE'), 'Modul Website ist nicht gebucht'],
    kontakt: [hat('WEBSITE'), 'Modul Website ist nicht gebucht'],
    nachbarschaften: [hat('WEBSITE') && !!nachbarschaften, hat('WEBSITE') ? 'Noch keine Nachbarschaft auf der Website eingeschaltet' : 'Modul Website ist nicht gebucht'],
    chronik: [hat('WEBSITE') && !!chronik, hat('WEBSITE') ? 'Noch keine veröffentlichten Einträge (Website → Chronik)' : 'Modul Website ist nicht gebucht'],
    events: [hat('ANLAESSE'), 'Modul Anlässe ist nicht gebucht'],
    news: [hat('NEUIGKEITEN'), 'Modul Neuigkeiten ist nicht gebucht'],
    live: [module.has('DORFLEBEN'), 'Modul Dorfleben ist nicht gebucht'],
    fussball: [module.has('TURNIER'), 'Modul Turnier ist nicht gebucht'],
    videos: [module.has('VIDEOS'), 'Modul Videos ist nicht gebucht'],
    spenden: [!!spenden, 'Spendenseite ist ausgeblendet (Einstellungen → Spenden)'],
    beitraege: [zl === 'OEFFENTLICH' || (zl === 'MITGLIEDER' && (opts.angemeldet || !!opts.alle)),
                zl === 'MITGLIEDER' ? 'nur für angemeldete Mitglieder' : 'Zahlerliste ist ausgeschaltet (Einstellungen)'],
  };

  const kandidaten: NavEintrag[] = [
    ...FEST.map(f => {
      const [m, g] = moeglich[f.schluessel] ?? [true];
      return {
        schluessel: f.schluessel, pfad: f.pfad, label: f.label, uebersetzen: true,
        icon: <f.I size={16} className={f.farbe} />, iconKlein: <f.I size={20} />,
        moeglich: m, grund: m ? undefined : g, an: f.schluessel !== 'nachbarschaften', eigeneSeite: false, beschreibung: `navb.${f.schluessel}`,
        ort: ORT_BISHER[f.schluessel] ?? 'OBEN',
      };
    }),
    ...seiten.map(s => ({
      schluessel: `seite:${s.pfad}`, pfad: `/${s.pfad}`, label: opts.loc(s.titel) || s.pfad, uebersetzen: false,
      icon: <FileText size={16} className="text-stone-500" />, iconKlein: <FileText size={20} />,
      moeglich: hat('WEBSITE'), grund: hat('WEBSITE') ? undefined : 'Modul Website ist nicht gebucht',
      // Bisher: in der Kopfzeile nur, wenn eingeschaltet; in der Fusszeile,
      // wenn die Seite "Im Menü" hat. Ohne Einstellung bleibt das so.
      an: !!s.im_menue, ort: (s.im_menue ? 'FUSS' : 'OBEN') as NavOrt, eigeneSeite: true, imMenue: !!s.im_menue,
    })),
  ];

  // Gespeicherte Reihenfolge zuerst; was neu dazukam, hinten an.
  // Unbekannte Schluessel (geloeschte Seite) fallen weg.
  const nach = new Map(kandidaten.map(k => [k.schluessel, k]));
  const geordnet: NavEintrag[] = [];
  for (const e of opts.einstellung ?? []) {
    const k = nach.get(e.schluessel);
    if (!k) continue;
    if (e.ort === 'OBEN' || e.ort === 'FUSS' || e.ort === 'BEIDES') {
      geordnet.push({ ...k, an: e.an, ort: e.ort, gruppe: e.gruppe ?? null });
    } else if (k.eigeneSeite) {
      // Gespeichert vor der Ortswahl: "an" galt der Kopfzeile, "Im Menü"
      // der Fusszeile. Beides zusammen ergibt den Ort.
      geordnet.push({ ...k, an: e.an || !!k.imMenue, gruppe: e.gruppe ?? null,
        ort: e.an && k.imMenue ? 'BEIDES' : e.an ? 'OBEN' : 'FUSS' });
    } else {
      geordnet.push({ ...k, an: e.an, gruppe: e.gruppe ?? null });
    }
    nach.delete(e.schluessel);
  }
  for (const k of nach.values()) geordnet.push(k);

  return opts.alle ? geordnet : geordnet.filter(e => e.an && e.moeglich);
}
