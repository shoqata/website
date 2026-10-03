import { useEffect, useState } from 'react';
import { db } from '../services/firebase';
import {
  collection, doc, getDoc, getDocs, onSnapshot, query, where, supabase,
} from '@/services/supabase-bridge';
import type { SolidarityEvent, UserProfile, GlobalPaymentSettings } from '../types';

// Was jede Startseiten-Vorlage ueber den Verein wissen muss.
//
// Hero.tsx und StartseitePremium.tsx holten das bisher jede fuer sich --
// dieselben sechs Abfragen, zweimal getippt. Bei sechs Vorlagen waere das
// sechsmal: jede Aenderung an einer Abfrage muesste man sechsmal
// nachziehen, und die fuenfte vergisst man.
//
// Hier steht es einmal. Eine Vorlage entscheidet nur noch, wie es aussieht,
// nicht woher es kommt.

export type Vereinsinhalt = {
  marke: any;
  bilder: string[];
  mitglieder: UserProfile[];
  mitgliederZahl: number;
  diaspora: number;
  anlaesse: SolidarityEvent[];
  beitragsstand: any | null;
  aufrufe: any[];
  zahlung: GlobalPaymentSettings | null;
  bereit: boolean;
};

// Wenn der Verein keine eigenen Bilder hinterlegt hat. Eine Startseite ohne
// Bild sieht nach Fehler aus, nicht nach Zurueckhaltung.
export const ERSATZBILDER = [
  'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&q=80&w=1600',
  'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=1600',
  'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80&w=2000',
];

export function useVereinsinhalt(): Vereinsinhalt {
  const [marke, setMarke] = useState<any>({});
  const [bilder, setBilder] = useState<string[]>(ERSATZBILDER);
  const [mitglieder, setMitglieder] = useState<UserProfile[]>([]);
  const [mitgliederZahl, setMitgliederZahl] = useState(0);
  const [diaspora, setDiaspora] = useState(0);
  const [anlaesse, setAnlaesse] = useState<SolidarityEvent[]>([]);
  const [beitragsstand, setBeitragsstand] = useState<any>(null);
  const [aufrufe, setAufrufe] = useState<any[]>([]);
  const [zahlung, setZahlung] = useState<GlobalPaymentSettings | null>(null);
  const [bereit, setBereit] = useState(false);

  // Marke und Bilder laufend -- der Admin aendert sie im Nebenfenster und
  // will das Ergebnis sehen, ohne neu zu laden.
  useEffect(() => {
    const ab = onSnapshot(doc(db, 'public_settings', 'branding'), (d: any) => {
      if (!d.exists()) return;
      const daten = d.data();
      setMarke(daten);
      if (daten.heroImages?.length) setBilder(daten.heroImages);
    });
    return () => ab();
  }, []);

  useEffect(() => {
    const abA = onSnapshot(
      query(collection(db, 'events'), where('status', '==', 'UPCOMING')),
      (snap: any) => {
        const alle = snap.docs.map((d: any) => ({ id: d.id, ...d.data() } as SolidarityEvent));
        setAnlaesse(alle.sort((a, b) =>
          new Date(a.date).getTime() - new Date(b.date).getTime()));
      });

    const abM = onSnapshot(collection(db, 'public_members'), (snap: any) => {
      const aktive = snap.docs
        .map((d: any) => ({ id: d.id, ...d.data() } as UserProfile))
        .filter((m: UserProfile) => m.membershipStatus === 'ACTIVE');
      setMitgliederZahl(aktive.length);
      setDiaspora(aktive.filter((m: any) => !m.livesInKoretin).length);
      // Mehr als 30 Gesichter zeigt keine Vorlage; der Rest waere nur Last.
      setMitglieder(aktive.slice(0, 30));
    });

    return () => { abA(); abM(); };
  }, []);

  // Der Rest einmal. Alle vier zusammen, damit "bereit" etwas bedeutet:
  // eine Vorlage, die bei jeder Antwort einzeln nachwaechst, ruckelt.
  useEffect(() => {
    let lebt = true;
    (async () => {
      const [zahl, stand, auf] = await Promise.all([
        getDoc(doc(db, 'public_settings', 'payment')).catch(() => null),
        supabase.rpc('beitragsstand_oeffentlich').then(r => r.data).catch(() => null),
        supabase.rpc('spendenaufrufe_oeffentlich').then(r => r.error ? [] : (r.data as any[]) || [])
          .catch(() => []),
      ]);
      if (!lebt) return;
      if (zahl?.exists()) setZahlung(zahl.data() as GlobalPaymentSettings);
      setBeitragsstand(stand ?? null);
      setAufrufe(auf ?? []);
      setBereit(true);
    })();
    return () => { lebt = false; };
  }, []);

  return { marke, bilder, mitglieder, mitgliederZahl, diaspora, anlaesse,
           beitragsstand, aufrufe, zahlung, bereit };
}

// Marken-Texte liegen je nach Alter des Eintrags als Zeichenkette oder als
// Sprachobjekt vor. Beides muss gehen, sonst zeigt ein alter Verein nichts.
export function text(wert: any, sprache: string): string {
  if (!wert) return '';
  if (typeof wert === 'string') return wert;
  return wert[sprache] || wert['de'] || '';
}
