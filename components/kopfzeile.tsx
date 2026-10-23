import React, { useEffect, useState } from 'react';
import { Info, Calendar, Newspaper, Zap, Trophy, Film, Heart, BadgeCheck, FileText } from 'lucide-react';
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

export type NavEinstellung = { schluessel: string; an: boolean }[];

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
  eigeneSeite: boolean;
};

type Fest = { schluessel: string; pfad: string; label: string; I: any; farbe: string };
const FEST: Fest[] = [
  { schluessel: 'about',     pfad: '/about',     label: 'nav.about',        I: Info,       farbe: 'text-emerald-600' },
  { schluessel: 'events',    pfad: '/events',    label: 'nav.events.title', I: Calendar,   farbe: 'text-primary' },
  { schluessel: 'news',      pfad: '/news',      label: 'nav.news.title',   I: Newspaper,  farbe: 'text-blue-600' },
  { schluessel: 'live',      pfad: '/live',      label: 'nav.live',         I: Zap,        farbe: 'text-amber-600' },
  { schluessel: 'fussball',  pfad: '/fussball',  label: 'nav.turnier',      I: Trophy,     farbe: 'text-rose-600' },
  { schluessel: 'videos',    pfad: '/videos',    label: 'video.oeff_titel', I: Film,       farbe: 'text-violet-600' },
  { schluessel: 'spenden',   pfad: '/spenden',   label: 'nav.spenden',      I: Heart,      farbe: 'text-primary' },
  { schluessel: 'beitraege', pfad: '/beitraege', label: 'nav.beitraege',    I: BadgeCheck, farbe: 'text-emerald-600' },
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
  if (module === null || seiten === null) return null;

  const zl = (opts.zahlerliste?.sichtbar || 'AUS').toUpperCase();
  // Leere Liste = Abfrage gescheitert (die Kernmodule fehlen nie). Dann
  // bleiben Website, Anlaesse und Neuigkeiten in der Leiste wie bisher.
  const hat = (m: string) => module.size === 0 && ['WEBSITE', 'ANLAESSE', 'NEUIGKEITEN'].includes(m) || module.has(m);
  const moeglich: Record<string, [boolean, string?]> = {
    about: [hat('WEBSITE'), 'Modul Website ist nicht gebucht'],
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
        moeglich: m, grund: m ? undefined : g, an: true, eigeneSeite: false,
      };
    }),
    ...seiten.map(s => ({
      schluessel: `seite:${s.pfad}`, pfad: `/${s.pfad}`, label: opts.loc(s.titel) || s.pfad, uebersetzen: false,
      icon: <FileText size={16} className="text-stone-500" />, iconKlein: <FileText size={20} />,
      moeglich: hat('WEBSITE'), grund: hat('WEBSITE') ? undefined : 'Modul Website ist nicht gebucht',
      an: false, eigeneSeite: true,
    })),
  ];

  // Gespeicherte Reihenfolge zuerst; was neu dazukam, hinten an.
  // Unbekannte Schluessel (geloeschte Seite) fallen weg.
  const nach = new Map(kandidaten.map(k => [k.schluessel, k]));
  const geordnet: NavEintrag[] = [];
  for (const e of opts.einstellung ?? []) {
    const k = nach.get(e.schluessel);
    if (!k) continue;
    geordnet.push({ ...k, an: e.an });
    nach.delete(e.schluessel);
  }
  for (const k of nach.values()) geordnet.push(k);

  return opts.alle ? geordnet : geordnet.filter(e => e.an && e.moeglich);
}
