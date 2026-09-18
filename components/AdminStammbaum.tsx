import React, { useEffect, useMemo, useState } from 'react';
import { Users2, Search, Loader2, AlertTriangle, X, Trash2, ArrowLeft, Plus } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import Familienbaum, { generationen, type Knoten, type Zone } from './Familienbaum';
import { netzAus, verwandteVon, type Kante } from '../lib/verwandtschaft';

// Stammbaum der Familien.
//
// Zuerst war das nach Adressen aufgebaut: wer zusammenwohnt, wurde als
// Haushalt vorgeschlagen. Vom Betreiber verworfen -- die Adresse ist nicht
// ausschlaggebend. Erwachsene Kinder ziehen aus, Familien verteilen sich
// ueber Ortschaften, und Verwandtschaft endet nicht an der Haustuer.
//
// Jetzt wird frei zusammengestellt: links alle Mitglieder, rechts die Familie,
// dazwischen Ziehen und Ablegen. Gespeichert werden nur Eltern- und
// Partnerbeziehungen; Geschwister, Onkel, Cousins ergeben sich daraus
// (lib/verwandtschaft.ts) und werden nicht zusaetzlich abgelegt -- das waere
// eine zweite Wahrheit, die beim ersten Korrigieren auseinanderlaeuft.

type Person = {
  familie: string; person: string; name: string; nachname: string | null;
  nachbarschaft: string | null; geburtsdatum: string | null;
  eltern: { id: string; name: string }[];
  partner: { id: string; name: string }[];
  kinder: { id: string; name: string }[];
};

const AdminStammbaum: React.FC = () => {
  const { t } = useTranslation();
  const [leute, setLeute] = useState<Person[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [werkbank, setWerkbank] = useState<string[] | null>(null);  // Personennummern
  const [gewaehlt, setGewaehlt] = useState<string | null>(null);
  const [suche, setSuche] = useState('');
  const [arbeitet, setArbeitet] = useState(false);

  const laden = async () => {
    setFehler(null);
    try {
      const { data, error } = await supabase.rpc('familien_uebersicht');
      if (error) throw error;
      setLeute(data ?? []);
      return (data ?? []) as Person[];
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
      return [];
    } finally {
      setLaedt(false);
    }
  };

  useEffect(() => { laden(); }, []);

  const nachId = useMemo(() => new Map(leute.map(l => [l.person, l])), [leute]);
  const namen = useMemo(() => new Map(leute.map(l => [l.person, l.name])), [leute]);

  // Die Kanten aus der Uebersicht zurueckgewinnen -- die Verwandtschafts-
  // rechnung arbeitet auf Kanten, die Anzeige auf zusammengefassten Listen.
  const kanten: Kante[] = useMemo(() => {
    const raus: Kante[] = [];
    const gesehen = new Set<string>();
    for (const p of leute) {
      for (const e of p.eltern) raus.push({ von: e.id, nach: p.person, art: 'ELTERNTEIL' });
      for (const q of p.partner) {
        const k = [p.person, q.id].sort().join('|');
        if (gesehen.has(k)) continue;
        gesehen.add(k);
        raus.push({ von: p.person, nach: q.id, art: 'PARTNER' });
      }
    }
    return raus;
  }, [leute]);

  const netz = useMemo(() => netzAus(kanten), [kanten]);

  const familien = useMemo(() => {
    const m = new Map<string, Person[]>();
    for (const p of leute) {
      if (!m.has(p.familie)) m.set(p.familie, []);
      m.get(p.familie)!.push(p);
    }
    return [...m.entries()].filter(([, g]) => g.length > 1)
      .sort((a, b) => b[1].length - a[1].length);
  }, [leute]);

  const alsKnoten = (ids: string[]): Knoten[] => ids
    .map(id => nachId.get(id))
    .filter((p): p is Person => !!p)
    .map(p => ({
      person: p.person, name: p.name, geburtsdatum: p.geburtsdatum,
      eltern: p.eltern.filter(e => ids.includes(e.id)),
      partner: p.partner.filter(q => ids.includes(q.id)),
      kinder: p.kinder.filter(k => ids.includes(k.id)),
    }));

  // --- Beziehung anlegen ---------------------------------------------------
  const ablegen = async (ziel: string, zone: Zone, quelle: string) => {
    setArbeitet(true); setFehler(null);
    try {
      const zeile =
        zone === 'PARTNER'    ? { von: quelle, nach: ziel, art: 'PARTNER' } :
        zone === 'KIND'       ? { von: ziel, nach: quelle, art: 'ELTERNTEIL' } :
                                { von: quelle, nach: ziel, art: 'ELTERNTEIL' };
      const { error } = await supabase.from('family_links').insert(zeile);
      if (error) throw error;
      const neu = await laden();
      // Die Werkbank um die neue Person erweitern, damit sie sofort im Bild
      // steht statt erst nach einem erneuten Oeffnen.
      setWerkbank(w => (w && !w.includes(quelle)) ? [...w, quelle] : w);
      void neu;
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setArbeitet(false);
    }
  };

  const loesen = async (a: string, b: string, art: 'ELTERNTEIL' | 'PARTNER') => {
    setArbeitet(true); setFehler(null);
    try {
      let q = supabase.from('family_links').delete().eq('art', art);
      q = art === 'PARTNER'
        ? q.or(`and(von.eq.${a},nach.eq.${b}),and(von.eq.${b},nach.eq.${a})`)
        : q.eq('von', a).eq('nach', b);
      const { error } = await q;
      if (error) throw error;
      await laden();
    } catch (e: any) {
      setFehler(e?.message ?? String(e));
    } finally {
      setArbeitet(false);
    }
  };

  const treffer = suche.trim().length < 2 ? [] : leute
    .filter(l => !werkbank?.includes(l.person))
    .filter(l => l.name?.toLowerCase().includes(suche.trim().toLowerCase()))
    .slice(0, 40);

  if (laedt) return (
    <div className="flex items-center gap-3 text-stone-400 p-8">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('stamm.laedt')}</span>
    </div>
  );

  // ======================================================== Werkbank
  if (werkbank) {
    const knoten = alsKnoten(werkbank);
    const person = gewaehlt ? nachId.get(gewaehlt) : null;
    const verwandte = gewaehlt
      ? verwandteVon(netz, gewaehlt, leute.map(l => l.person), namen)
      : [];

    return (
      <div className="space-y-4">
        <div className="flex items-center gap-3 flex-wrap">
          <button onClick={() => { setWerkbank(null); setGewaehlt(null); }}
                  className="flex items-center gap-2 text-xs font-bold text-stone-500 hover:text-stone-900">
            <ArrowLeft size={14} /> {t('stamm.zurueck')}
          </button>
          {arbeitet && <Loader2 className="animate-spin text-stone-300" size={14} />}
          <span className="text-[11px] text-stone-400">{t('stamm.werkbank_hinweis')}</span>
        </div>

        {fehler && (
          <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl border border-rose-100 text-xs text-rose-700">
            <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-4">
          {/* Vorrat */}
          <div className="bg-white rounded-2xl border border-stone-100 p-4 h-fit">
            <div className="relative mb-3">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
              <input value={suche} onChange={(e) => setSuche(e.target.value)}
                     placeholder={t('stamm.mitglied_suchen')}
                     className="w-full pl-9 pr-3 py-2.5 bg-stone-50 border border-stone-200 rounded-xl text-xs outline-none" />
            </div>
            <div className="space-y-1 max-h-[460px] overflow-y-auto">
              {treffer.map(l => (
                <div key={l.person} draggable
                     onDragStart={(e) => e.dataTransfer.setData('text/plain', l.person)}
                     className="px-3 py-2 bg-stone-50 rounded-lg cursor-grab active:cursor-grabbing
                                hover:bg-stone-100 transition-colors">
                  <p className="text-xs font-bold text-stone-700 truncate">{l.name}</p>
                  <p className="text-[10px] text-stone-400 truncate">
                    {l.nachbarschaft || '—'}{l.geburtsdatum ? ` · ${l.geburtsdatum}` : ''}
                  </p>
                </div>
              ))}
              {suche.trim().length >= 2 && !treffer.length && (
                <p className="text-[11px] text-stone-300 px-1 py-3">{t('stamm.nichts_gefunden')}</p>
              )}
              {suche.trim().length < 2 && (
                <p className="text-[11px] text-stone-300 px-1 py-3">{t('stamm.suche_starten')}</p>
              )}
            </div>
          </div>

          {/* Baum */}
          <div className="bg-white rounded-2xl border border-stone-100 p-4 min-h-[300px]"
               onDragOver={(e) => e.preventDefault()}
               onDrop={(e) => {
                 const id = e.dataTransfer.getData('text/plain');
                 if (id && !werkbank.includes(id)) setWerkbank([...werkbank, id]);
               }}>
            {knoten.length ? (
              <Familienbaum leute={knoten} onAblegen={ablegen}
                            onWaehlen={setGewaehlt} gewaehltId={gewaehlt}
                            t3={(s) => t(`stamm.zone_${s.toLowerCase()}`) || s} />
            ) : (
              <div className="h-[260px] flex items-center justify-center text-center px-8">
                <p className="text-xs text-stone-300 max-w-sm leading-relaxed">{t('stamm.canvas_leer')}</p>
              </div>
            )}
          </div>
        </div>

        {/* Verwandtschaft der gewaehlten Person */}
        {person && (
          <div className="bg-white rounded-2xl border border-stone-100 p-5">
            <div className="flex items-start justify-between gap-4 mb-4">
              <div>
                <p className="font-bold text-stone-700">{person.name}</p>
                <p className="text-xs text-stone-400">
                  {person.nachbarschaft || '—'}{person.geburtsdatum ? ` · ${person.geburtsdatum}` : ''}
                </p>
              </div>
              <button onClick={() => setGewaehlt(null)} className="text-stone-300 hover:text-stone-500">
                <X size={18} />
              </button>
            </div>

            {/* Erfasste Beziehungen -- nur diese lassen sich loesen. */}
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">
              {t('stamm.erfasst')}
            </p>
            <div className="flex flex-wrap gap-2 mb-5">
              {[...person.eltern.map(e => ({ ...e, art: 'ELTERNTEIL' as const, wort: t('stamm.rolle_eltern'), a: e.id, b: person.person })),
                ...person.kinder.map(k => ({ ...k, art: 'ELTERNTEIL' as const, wort: t('stamm.rolle_kind'), a: person.person, b: k.id })),
                ...person.partner.map(q => ({ ...q, art: 'PARTNER' as const, wort: t('stamm.zone_partner'), a: person.person, b: q.id }))
              ].map(x => (
                <span key={`${x.art}${x.id}`}
                      className="inline-flex items-center gap-2 pl-3 pr-1.5 py-1.5 bg-stone-50 rounded-lg text-xs">
                  <span className="text-stone-400">{x.wort}</span>
                  <span className="font-bold text-stone-700">{x.name}</span>
                  <button onClick={() => loesen(x.a, x.b, x.art)}
                          className="text-stone-300 hover:text-rose-500" title={t('stamm.loesen')}>
                    <Trash2 size={12} />
                  </button>
                </span>
              ))}
              {!person.eltern.length && !person.kinder.length && !person.partner.length && (
                <span className="text-xs text-stone-300">{t('stamm.noch_nichts')}</span>
              )}
            </div>

            {/* Abgeleitet -- nicht gespeichert, sondern gerechnet. */}
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">
              {t('stamm.abgeleitet')}
            </p>
            {verwandte.length ? (
              <div className="flex flex-wrap gap-2">
                {verwandte.map(v => (
                  <span key={v.id + v.bezeichnung}
                        className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs"
                        style={{
                          background: v.gruppe === 'angeheiratet' ? '#fafaf9' : '#f5f5f4',
                          color: v.gruppe === 'angeheiratet' ? '#a8a29e' : '#57534e',
                        }}>
                    <span className="font-bold">{namen.get(v.id)}</span>
                    <span className="opacity-70">{v.bezeichnung}</span>
                  </span>
                ))}
              </div>
            ) : <p className="text-xs text-stone-300">{t('stamm.keine_abgeleiteten')}</p>}
          </div>
        )}
      </div>
    );
  }

  // ======================================================== Übersicht
  return (
    <div className="space-y-6">
      {fehler && (
        <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl border border-rose-100 text-xs text-rose-700">
          <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
        </div>
      )}

      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-2">
          <Users2 size={18} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">
            {t('stamm.familien')} ({familien.length})
          </h3>
        </div>
        <button onClick={() => { setWerkbank([]); setSuche(''); }}
                className="knopf-primaer px-5 py-2.5 text-white rounded-xl text-xs font-bold flex items-center gap-2">
          <Plus size={14} /> {t('stamm.neue_familie')}
        </button>
      </div>

      {familien.length === 0 ? (
        <div className="p-10 bg-stone-50 rounded-3xl border border-stone-100 text-center">
          <p className="text-sm font-bold text-stone-600 mb-1">{t('stamm.leer_titel')}</p>
          <p className="text-xs text-stone-400 max-w-lg mx-auto leading-relaxed">{t('stamm.leer')}</p>
        </div>
      ) : (
        <div className="space-y-4">
          {familien.map(([schluessel, mitglieder]) => {
            const kopf = [...new Set(mitglieder.map(m => m.nachname).filter(Boolean))];
            return (
              <div key={schluessel} className="bg-white rounded-3xl border border-stone-100 p-5">
                <div className="flex items-baseline justify-between gap-4 mb-4">
                  <div>
                    <p className="font-bold text-stone-700">{kopf.join(' / ') || t('stamm.ohne_namen')}</p>
                    <p className="text-[11px] text-stone-400">
                      {mitglieder.length} {t('stamm.personen')} ·{' '}
                      {new Set(generationen(alsKnoten(mitglieder.map(m => m.person))).values()).size}{' '}
                      {t('stamm.generationen')}
                    </p>
                  </div>
                  <button onClick={() => { setWerkbank(mitglieder.map(m => m.person)); setSuche(''); }}
                          className="text-[10px] font-bold uppercase tracking-widest shrink-0"
                          style={{ color: 'var(--primary)' }}>
                    {t('stamm.bearbeiten')}
                  </button>
                </div>
                <Familienbaum leute={alsKnoten(mitglieder.map(m => m.person))} />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default AdminStammbaum;
