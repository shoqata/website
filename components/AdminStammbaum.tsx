import React, { useEffect, useMemo, useState } from 'react';
import Familienbaum, { generationen, type Knoten } from './Familienbaum';
import { Users2, Home, Plus, X, Loader2, Link2, AlertTriangle, Check } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Stammbaum der Familien.
//
// Vorhanden war nur "familyId", ein freies Textfeld -- gemessen bei 0 von 348
// Mitgliedern gefuellt. Es sagt ausserdem nichts darueber, WER mit wem
// verwandt ist. Die Beziehungen stehen jetzt in family_links, mit zwei Arten:
// ELTERNTEIL (gerichtet) und PARTNER (ungerichtet). Geschwister werden nicht
// gespeichert, sondern ergeben sich aus einem gemeinsamen Elternteil -- eine
// eigene Geschwisterbeziehung waere eine zweite Wahrheit.
//
// Erfasst ist anfangs nichts. Weil sich aber 34 Gruppen eine Adresse teilen,
// stehen diese Haushalte als Ausgangspunkt daneben.

type Person = {
  familie: string; person: string; name: string; nachname: string | null;
  nachbarschaft: string | null; strasse: string | null; plz: string | null;
  ort: string | null; geburtsdatum: string | null;
  eltern: { id: string; name: string }[];
  partner: { id: string; name: string }[];
  kinder: { id: string; name: string }[];
};

type Haushalt = {
  strasse: string; plz: string; ort: string; anzahl: number;
  nachbarschaft: string | null;
  personen: { id: string; name: string; nachname: string | null; geburtsdatum: string | null }[];
  schon_verknuepft: boolean;
};

const AdminStammbaum: React.FC = () => {
  const { t } = useTranslation();
  const [leute, setLeute] = useState<Person[]>([]);
  const [haushalte, setHaushalte] = useState<Haushalt[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [offen, setOffen] = useState<string | null>(null);
  const [verknuepfe, setVerknuepfe] = useState<Haushalt | null>(null);

  const laden = async () => {
    setLaedt(true); setFehler(null);
    try {
      const [a, b] = await Promise.all([
        supabase.rpc('familien_uebersicht'),
        supabase.rpc('haushalt_vorschlaege'),
      ]);
      if (a.error) throw a.error;
      if (b.error) throw b.error;
      setLeute(a.data ?? []);
      setHaushalte(b.data ?? []);
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { laden(); }, []);

  // Nur Gruppen mit mehr als einer Person sind eine Familie. Alle uebrigen
  // stehen als Einzelpersonen in der Mitgliederliste und brauchen hier
  // keinen eigenen Kasten.
  const familien = useMemo(() => {
    const m = new Map<string, Person[]>();
    for (const p of leute) {
      if (!m.has(p.familie)) m.set(p.familie, []);
      m.get(p.familie)!.push(p);
    }
    return [...m.entries()]
      .filter(([, mitglieder]) => mitglieder.length > 1)
      .sort((x, y) => y[1].length - x[1].length);
  }, [leute]);

  if (laedt) {
    return (
      <div className="flex items-center gap-3 text-stone-400 p-8">
        <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('stamm.laedt')}</span>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {fehler && (
        <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl border border-rose-100 text-xs text-rose-700">
          <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
        </div>
      )}

      {/* ------------------------------------------------ Familien */}
      <section>
        <div className="flex items-center gap-2 mb-4">
          <Users2 size={18} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">
            {t('stamm.familien')} ({familien.length})
          </h3>
        </div>

        {familien.length === 0 ? (
          <div className="p-8 bg-stone-50 rounded-3xl border border-stone-100 text-center">
            <p className="text-sm font-bold text-stone-600 mb-1">{t('stamm.leer_titel')}</p>
            <p className="text-xs text-stone-400 max-w-lg mx-auto leading-relaxed">{t('stamm.leer')}</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {familien.map(([schluessel, mitglieder]) => (
              <Familienkasten key={schluessel} mitglieder={mitglieder}
                              offen={offen === schluessel}
                              umschalten={() => setOffen(offen === schluessel ? null : schluessel)}
                              nachAenderung={laden} />
            ))}
          </div>
        )}
      </section>

      {/* ------------------------------------------------ Haushalte */}
      <section>
        <div className="flex items-center gap-2 mb-2">
          <Home size={18} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">
            {t('stamm.haushalte')} ({haushalte.filter(h => !h.schon_verknuepft).length})
          </h3>
        </div>
        <p className="text-xs text-stone-400 mb-4 max-w-2xl leading-relaxed">{t('stamm.haushalte_hinweis')}</p>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {haushalte.filter(h => !h.schon_verknuepft).map((h, i) => (
            <div key={i} className="p-4 bg-white rounded-2xl border border-stone-100">
              <p className="font-bold text-sm text-stone-700">{h.strasse}</p>
              <p className="text-xs text-stone-400 mb-3">
                {h.plz} {h.ort}{h.nachbarschaft ? ` · ${h.nachbarschaft}` : ''}
              </p>
              <ul className="space-y-1 mb-3">
                {h.personen.map(p => (
                  <li key={p.id} className="text-xs text-stone-600 flex items-baseline gap-2">
                    <span className="w-1 h-1 rounded-full bg-stone-300 shrink-0" />
                    <span className="font-medium">{p.name}</span>
                    {p.geburtsdatum && <span className="text-stone-300">{p.geburtsdatum}</span>}
                  </li>
                ))}
              </ul>
              <button onClick={() => setVerknuepfe(h)}
                      className="text-[10px] font-bold uppercase tracking-widest flex items-center gap-1.5"
                      style={{ color: 'var(--primary)' }}>
                <Link2 size={12} /> {t('stamm.verknuepfen')}
              </button>
            </div>
          ))}
        </div>
      </section>

      {verknuepfe && (
        <Familienbauer haushalt={verknuepfe} alle={leute} schliessen={() => setVerknuepfe(null)}
                     fertig={() => { setVerknuepfe(null); laden(); }} />
      )}
    </div>
  );
};

// --- Ein Familienkasten ----------------------------------------------------
// Dargestellt wird nach Generationen: wer keine erfassten Eltern hat, steht
// oben. Das ist keine Annahme ueber das Alter, sondern folgt genau dem, was
// erfasst ist -- ohne Geburtsdaten (328 von 348 fehlen) waere alles andere
// geraten.
const Familienkasten: React.FC<{
  mitglieder: Person[]; offen: boolean; umschalten: () => void; nachAenderung: () => void;
}> = ({ mitglieder, offen, umschalten }) => {
  const { t } = useTranslation();
  // Dieselbe Rechnung, die auch der Baum benutzt -- einmal im Baum, damit
  // Kopfzeile und Darstellung nicht auseinanderlaufen koennen.
  const anzahlGenerationen = new Set(generationen(mitglieder).values()).size;

  const kopf = mitglieder.map(m => m.nachname).filter(Boolean);
  const nachname = kopf.length ? [...new Set(kopf)].join(' / ') : t('stamm.ohne_namen');

  return (
    <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
      <button onClick={umschalten} className="w-full p-5 text-left hover:bg-stone-50 transition-colors">
        <div className="flex items-baseline justify-between gap-3">
          <p className="font-bold text-stone-700">{nachname}</p>
          <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 shrink-0">
            {mitglieder.length} {t('stamm.personen')} · {anzahlGenerationen} {t('stamm.generationen')}
          </span>
        </div>
        {mitglieder[0]?.nachbarschaft && (
          <p className="text-xs text-stone-400 mt-1">{mitglieder[0].nachbarschaft}</p>
        )}
      </button>

      {offen && (
        <div className="px-5 pb-5 border-t border-stone-100 pt-4">
          <Familienbaum leute={mitglieder} />
          <p className="text-[10px] text-stone-300 mt-3">{t('stamm.legende')}</p>
        </div>
      )}
    </div>
  );
};

// --- Eine Familie in einem Durchgang zusammenstellen ----------------------
//
// Zuerst stand hier eine Maske fuer genau eine Beziehung: Person, Art,
// Person. Fuer einen Haushalt mit fuenf Leuten sind das ein Dutzend
// Durchgaenge -- Eltern zu jedem Kind, Partner untereinander. Jetzt wird
// jeder Person eine Rolle gegeben, der Baum daneben zeigt sofort, was daraus
// wird, und ein Knopf legt alles an.
const Familienbauer: React.FC<{
  haushalt: Haushalt; alle: Person[]; schliessen: () => void; fertig: () => void;
}> = ({ haushalt, alle, schliessen, fertig }) => {
  const { t } = useTranslation();
  type Rolle = '' | 'ELTERN' | 'KIND';
  const [dabei, setDabei] = useState<{ id: string; name: string; geburtsdatum: string | null }[]>(
    haushalt.personen.map(p => ({ id: p.id, name: p.name, geburtsdatum: p.geburtsdatum })));
  const [rollen, setRollen] = useState<Record<string, Rolle>>({});
  const [suche, setSuche] = useState('');
  const [laeuft, setLaeuft] = useState(false);
  const [meldung, setMeldung] = useState<{ art: 'gut' | 'schlecht'; text: string } | null>(null);

  const eltern = dabei.filter(p => rollen[p.id] === 'ELTERN');
  const kinder = dabei.filter(p => rollen[p.id] === 'KIND');

  // Was entstuende daraus? Genau das, was gleich gespeichert wird -- die
  // Vorschau ist keine Nachbildung, sondern dieselbe Rechnung.
  const vorschau: Knoten[] = useMemo(() => dabei
    .filter(p => rollen[p.id])
    .map(p => ({
      person: p.id, name: p.name, geburtsdatum: p.geburtsdatum,
      eltern: rollen[p.id] === 'KIND' ? eltern.map(e => ({ id: e.id, name: e.name })) : [],
      kinder: rollen[p.id] === 'ELTERN' ? kinder.map(k => ({ id: k.id, name: k.name })) : [],
      partner: rollen[p.id] === 'ELTERN'
        ? eltern.filter(e => e.id !== p.id).map(e => ({ id: e.id, name: e.name })) : [],
    })), [dabei, rollen, eltern, kinder]);

  const treffer = suche.trim().length < 2 ? [] : alle
    .filter(a => !dabei.some(d => d.id === a.person))
    .filter(a => a.name?.toLowerCase().includes(suche.trim().toLowerCase()))
    .slice(0, 6);

  const anlegen = async () => {
    setLaeuft(true); setMeldung(null);
    try {
      const zeilen: { von: string; nach: string; art: string }[] = [];
      for (const e of eltern) for (const k of kinder)
        zeilen.push({ von: e.id, nach: k.id, art: 'ELTERNTEIL' });
      // Partner nur bei genau zwei Elternteilen. Bei dreien waere unklar, wer
      // mit wem -- das gehoert dann einzeln erfasst, nicht geraten.
      if (eltern.length === 2)
        zeilen.push({ von: eltern[0].id, nach: eltern[1].id, art: 'PARTNER' });

      if (!zeilen.length) { setMeldung({ art: 'schlecht', text: t('stamm.nichts_zu_tun') }); return; }

      const { error } = await supabase.from('family_links').insert(zeilen);
      if (error) throw error;
      setMeldung({ art: 'gut', text: t('stamm.angelegt_n').replace('{n}', String(zeilen.length)) });
      setTimeout(fertig, 900);
    } catch (e: any) {
      setMeldung({ art: 'schlecht', text: e?.message ?? String(e) });
    } finally {
      setLaeuft(false);
    }
  };

  const rollenKnopf = (id: string, wert: Rolle, beschriftung: string) => (
    <button type="button" onClick={() => setRollen({ ...rollen, [id]: rollen[id] === wert ? '' : wert })}
            className="px-3 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-widest transition-colors"
            style={rollen[id] === wert
              ? { background: 'var(--primary)', color: '#fff' }
              : { background: '#f5f5f4', color: '#78716c' }}>
      {beschriftung}
    </button>
  );

  return (
    <div className="fixed inset-0 bg-black/40 z-[900] flex items-start justify-center p-4 overflow-y-auto"
         onClick={schliessen}>
      <div className="bg-white rounded-3xl p-6 w-full max-w-4xl my-8 space-y-5"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="font-bold text-stone-700">{haushalt.strasse}</p>
            <p className="text-xs text-stone-400">
              {haushalt.plz} {haushalt.ort}{haushalt.nachbarschaft ? ` · ${haushalt.nachbarschaft}` : ''}
            </p>
          </div>
          <button onClick={schliessen} className="text-stone-300 hover:text-stone-500"><X size={20} /></button>
        </div>

        <p className="text-xs text-stone-400 leading-relaxed">{t('stamm.bauen_hinweis')}</p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {/* Rollen vergeben */}
          <div className="space-y-2">
            {dabei.map(p => (
              <div key={p.id} className="flex items-center justify-between gap-3 p-3 bg-stone-50 rounded-xl">
                <div className="min-w-0">
                  <p className="text-xs font-bold text-stone-700 truncate">{p.name}</p>
                  <p className="text-[10px] text-stone-400">{p.geburtsdatum || t('stamm.ohne_geburtsdatum')}</p>
                </div>
                <div className="flex gap-1.5 shrink-0">
                  {rollenKnopf(p.id, 'ELTERN', t('stamm.rolle_eltern'))}
                  {rollenKnopf(p.id, 'KIND', t('stamm.rolle_kind'))}
                </div>
              </div>
            ))}

            <div className="pt-1">
              <input value={suche} onChange={(e) => setSuche(e.target.value)}
                     placeholder={t('stamm.weitere_suchen')}
                     className="w-full p-3 bg-white border border-stone-200 rounded-xl text-xs outline-none" />
              {treffer.map(a => (
                <button key={a.person} type="button"
                        onClick={() => { setDabei([...dabei, { id: a.person, name: a.name, geburtsdatum: a.geburtsdatum }]); setSuche(''); }}
                        className="w-full text-left px-3 py-2 text-xs text-stone-600 hover:bg-stone-50 rounded-lg flex items-center gap-2">
                  <Plus size={12} className="text-stone-300" /> {a.name}
                </button>
              ))}
            </div>
          </div>

          {/* Vorschau */}
          <div className="bg-stone-50 rounded-2xl p-4 min-h-[180px] flex items-center justify-center">
            {vorschau.length ? <Familienbaum leute={vorschau} />
              : <p className="text-xs text-stone-300 text-center px-6">{t('stamm.vorschau_leer')}</p>}
          </div>
        </div>

        {meldung && (
          <div className={`flex gap-2 items-start p-3 rounded-xl text-xs ${
            meldung.art === 'gut' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
            {meldung.art === 'gut' ? <Check size={14} className="shrink-0 mt-0.5" />
                                   : <AlertTriangle size={14} className="shrink-0 mt-0.5" />}
            <span>{meldung.text}</span>
          </div>
        )}

        <div className="flex gap-3 items-center">
          <button onClick={anlegen} disabled={laeuft || (!eltern.length && !kinder.length)}
                  className="knopf-primaer px-6 py-3 text-white rounded-xl text-xs font-bold flex items-center gap-2 disabled:opacity-40">
            {laeuft ? <Loader2 className="animate-spin" size={14} /> : <Plus size={14} />}
            {t('stamm.familie_anlegen')}
          </button>
          <button onClick={schliessen}
                  className="px-6 py-3 bg-stone-100 text-stone-600 rounded-xl text-xs font-bold hover:bg-stone-200">
            {t('common.cancel')}
          </button>
          <span className="text-[11px] text-stone-400">
            {t('stamm.ergibt')
              .replace('{eltern}', String(eltern.length))
              .replace('{kinder}', String(kinder.length))
              .replace('{n}', String(eltern.length * kinder.length + (eltern.length === 2 ? 1 : 0)))}
          </span>
        </div>
      </div>
    </div>
  );
};

export default AdminStammbaum;
