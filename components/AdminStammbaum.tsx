import React, { useEffect, useMemo, useState } from 'react';
import { Users2, Search, Loader2, AlertTriangle, X, ArrowLeft, Plus, Pencil } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import Familienbaum, { generationen, type Zone } from './Familienbaum';
import StammbaumPerson from './StammbaumPerson';
import { useStammbaum, type Person } from '../lib/stammbaum';

// Stammbaum der Familien.
//
// Zuerst war das nach Adressen aufgebaut: wer zusammenwohnt, wurde als
// Haushalt vorgeschlagen. Vom Betreiber verworfen -- die Adresse ist nicht
// ausschlaggebend. Erwachsene Kinder ziehen aus, Familien verteilen sich
// ueber Ortschaften, und Verwandtschaft endet nicht an der Haustuer.
//
// Zusammengestellt wird frei: Person anklicken und Verwandte per Suche
// hinzufuegen, oder ziehen und ablegen. Gespeichert werden nur Eltern-,
// Partner- und Geschwisterbeziehungen; Onkel, Cousins usw. ergeben sich
// daraus (lib/verwandtschaft.ts) und werden nicht zusaetzlich abgelegt.
//
// Herausnehmen: das Kreuz am Kasten. Wer noch nicht verbunden ist, faellt
// nur aus dem Bild; wer verbunden ist, verliert nach einer Rueckfrage alle
// Beziehungen auf einmal (stammbaum_person_loesen).

const AdminStammbaum: React.FC = () => {
  const { t } = useTranslation();
  const { showConfirm } = useFeedback();
  const sb = useStammbaum();
  const { leute, nachId, alsKnoten } = sb;
  const [werkbank, setWerkbank] = useState<string[] | null>(null);  // Personennummern
  const [gewaehlt, setGewaehlt] = useState<string | null>(null);
  const [suche, setSuche] = useState('');
  const [filter, setFilter] = useState('');
  const [benennt, setBenennt] = useState<{ anker: string; name: string; id: string | null } | null>(null);

  const familien = useMemo(() => {
    const m = new Map<string, Person[]>();
    for (const p of leute) {
      if (!m.has(p.familie)) m.set(p.familie, []);
      m.get(p.familie)!.push(p);
    }
    return [...m.entries()].filter(([, g]) => g.length > 1)
      .sort((a, b) => b[1].length - a[1].length);
  }, [leute]);

  // Die Werkbank zeigt immer ganze Familien: wird jemand mit einer anderen
  // Familie verbunden, kommt diese nach dem Laden vollstaendig dazu.
  useEffect(() => {
    if (!werkbank) return;
    const gruppen = new Set(werkbank.map(id => nachId.get(id)?.familie).filter(Boolean));
    const dazu = leute.filter(l => gruppen.has(l.familie) && !werkbank.includes(l.person)
                                   && (l.eltern.length || l.kinder.length || l.partner.length || l.geschwister?.length));
    if (dazu.length) setWerkbank([...werkbank, ...dazu.map(l => l.person)]);
  }, [leute]);

  const oeffnen = (ids: string[], person: string | null = null) => {
    setWerkbank(ids); setGewaehlt(person); setSuche('');
  };

  const ablegen = async (ziel: string, zone: Zone, quelle: string) => {
    // Die Zone sagt, was die gezogene Person fuer die Zielperson ist.
    const ok = await sb.verbinden(ziel, zone, quelle);
    if (ok) setWerkbank(w => (w && !w.includes(quelle)) ? [...w, quelle] : w);
  };

  const entfernen = async (id: string) => {
    const p = nachId.get(id);
    const verbunden = !!p && (p.eltern.length + p.kinder.length + p.partner.length + (p.geschwister?.length ?? 0)) > 0;
    if (verbunden) {
      const ja = await showConfirm({
        title: t('stamm.herausnehmen'),
        message: t('stamm.herausnehmen_frage').replace('{name}', p!.name)
          .replace('{n}', String(p!.eltern.length + p!.kinder.length + p!.partner.length + (p!.geschwister?.length ?? 0))),
        confirmText: t('stamm.herausnehmen'), type: 'danger',
      });
      if (!ja || !(await sb.herausnehmen(id))) return;
    }
    setWerkbank(w => w ? w.filter(x => x !== id) : w);
    if (gewaehlt === id) setGewaehlt(null);
  };

  const benennen = async () => {
    if (!benennt || !benennt.name.trim()) return;
    if (await sb.benennen(benennt.anker, benennt.name, benennt.id)) setBenennt(null);
  };

  const treffer = suche.trim().length < 2 ? [] : leute
    .filter(l => !werkbank?.includes(l.person))
    .filter(l => l.name?.toLowerCase().includes(suche.trim().toLowerCase()))
    .slice(0, 40);

  const Fehler = () => sb.fehler ? (
    <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl border border-rose-100 text-xs text-rose-700">
      <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span className="flex-1">{sb.fehler}</span>
      <button onClick={() => sb.setFehler(null)}><X size={14} /></button>
    </div>
  ) : null;

  if (sb.laedt) return (
    <div className="flex items-center gap-3 text-stone-400 p-8">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('stamm.laedt')}</span>
    </div>
  );

  // ======================================================== Werkbank
  if (werkbank) {
    const knoten = alsKnoten(werkbank);
    const person = gewaehlt ? nachId.get(gewaehlt) : null;

    return (
      <div className="space-y-4">
        <div className="flex items-center gap-3 flex-wrap">
          <button onClick={() => { setWerkbank(null); setGewaehlt(null); }}
                  className="flex items-center gap-2 text-xs font-bold text-stone-500 hover:text-stone-900">
            <ArrowLeft size={14} /> {t('stamm.zurueck')}
          </button>
          {sb.arbeitet && <Loader2 className="animate-spin text-stone-300" size={14} />}
          <span className="text-[11px] text-stone-400">{t('stamm.werkbank_hinweis2')}</span>
        </div>

        <Fehler />

        <div className="grid grid-cols-1 lg:grid-cols-[260px_1fr] gap-4">
          {/* Vorrat */}
          <div className="bg-white rounded-2xl border border-stone-100 p-4 h-fit">
            <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{t('stamm.ins_bild')}</p>
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
                     className="group px-3 py-2 bg-stone-50 rounded-lg cursor-grab active:cursor-grabbing
                                hover:bg-stone-100 transition-colors flex items-center gap-2">
                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-bold text-stone-700 truncate">{l.name}</p>
                    <p className="text-[10px] text-stone-400 truncate">
                      {l.nachbarschaft || '—'}{l.geburtsdatum ? ` · ${l.geburtsdatum}` : ''}
                    </p>
                  </div>
                  {/* Ohne Ziehen: ins Bild holen und gleich auswaehlen. */}
                  <button onClick={() => { setWerkbank([...werkbank, l.person]); setGewaehlt(l.person); setSuche(''); }}
                          title={t('stamm.ins_bild')}
                          className="w-7 h-7 rounded-lg bg-white border border-stone-200 text-stone-500 hover:text-stone-900 flex items-center justify-center shrink-0">
                    <Plus size={13} />
                  </button>
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
                            onEntfernen={entfernen} entfernenText={t('stamm.herausnehmen')}
                            t3={(wort) => t(`stamm.zone_${wort.toLowerCase()}`)} />
            ) : (
              <div className="h-[260px] flex items-center justify-center text-center px-8">
                <p className="text-xs text-stone-300 max-w-sm leading-relaxed">{t('stamm.canvas_leer2')}</p>
              </div>
            )}
          </div>
        </div>

        {person ? (
          <div className="bg-white rounded-2xl border border-stone-100 p-5">
            <div className="flex items-start justify-between gap-4 mb-4">
              <div>
                <p className="font-bold text-stone-800 text-lg">{person.name}</p>
                <p className="text-xs text-stone-400">
                  {person.nachbarschaft || '—'}{person.geburtsdatum ? ` · ${person.geburtsdatum}` : ''}
                </p>
              </div>
              <button onClick={() => setGewaehlt(null)} className="text-stone-300 hover:text-stone-500">
                <X size={18} />
              </button>
            </div>
            <StammbaumPerson sb={sb} person={person.person}
              onOeffnen={(id) => { if (!werkbank.includes(id)) setWerkbank([...werkbank, id]); setGewaehlt(id); }}
              onHinzugefuegt={(id) => setWerkbank(w => w && !w.includes(id) ? [...w, id] : w)}
              onHerausgenommen={() => { setWerkbank(w => w ? w.filter(x => x !== person.person) : w); setGewaehlt(null); }} />
          </div>
        ) : knoten.length > 0 && (
          <p className="text-xs text-stone-400 px-1">{t('stamm.person_anklicken')}</p>
        )}
      </div>
    );
  }

  // ======================================================== Übersicht
  const f = filter.trim().toLowerCase();
  const gezeigt = !f ? familien : familien.filter(([, g]) =>
    g.some(m => m.name?.toLowerCase().includes(f) || m.familienname?.toLowerCase().includes(f)));

  return (
    <div className="space-y-6">
      <Fehler />

      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-2">
          <Users2 size={18} className="text-stone-400" />
          <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">
            {t('stamm.familien')} ({familien.length})
          </h3>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {familien.length > 0 && (
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
              <input value={filter} onChange={e => setFilter(e.target.value)} placeholder={t('stamm.familie_suchen')}
                     className="pl-9 pr-3 py-2.5 bg-white border border-stone-200 rounded-xl text-xs outline-none w-56" />
            </div>
          )}
          <button onClick={() => oeffnen([])}
                  className="knopf-primaer px-5 py-2.5 text-white rounded-xl text-xs font-bold flex items-center gap-2">
            <Plus size={14} /> {t('stamm.neue_familie')}
          </button>
        </div>
      </div>

      {familien.length === 0 ? (
        <div className="p-10 bg-stone-50 rounded-3xl border border-stone-100 text-center">
          <p className="text-sm font-bold text-stone-600 mb-1">{t('stamm.leer_titel')}</p>
          <p className="text-xs text-stone-400 max-w-lg mx-auto leading-relaxed">{t('stamm.leer2')}</p>
        </div>
      ) : (
        <div className="space-y-4">
          {gezeigt.map(([schluessel, mitglieder]) => {
            const kopf = [...new Set(mitglieder.map(m => m.nachname).filter(Boolean))];
            const ids = mitglieder.map(m => m.person);
            return (
              <div key={schluessel} className="bg-white rounded-3xl border border-stone-100 p-5">
                <div className="flex items-baseline justify-between gap-4 mb-4">
                  <div className="min-w-0">
                    {benennt?.anker === mitglieder[0].person ? (
                      <div className="flex items-center gap-2">
                        <input autoFocus value={benennt.name}
                               onChange={(e) => setBenennt({ ...benennt, name: e.target.value })}
                               onKeyDown={(e) => { if (e.key === 'Enter') benennen();
                                                   if (e.key === 'Escape') setBenennt(null); }}
                               placeholder={t('stamm.name_platzhalter')}
                               className="px-3 py-1.5 bg-stone-50 border border-stone-200 rounded-lg text-sm font-bold outline-none" />
                        <button onClick={benennen} disabled={sb.arbeitet}
                                className="text-[10px] font-bold uppercase tracking-widest"
                                style={{ color: 'var(--primary)' }}>{t('common.save')}</button>
                        <button onClick={() => setBenennt(null)}
                                className="text-stone-300 hover:text-stone-500"><X size={14} /></button>
                      </div>
                    ) : (
                      <button onClick={() => setBenennt({
                                anker: mitglieder[0].person,
                                name: mitglieder[0].familienname ?? (kopf.join(' / ') || ''),
                                id: mitglieder[0].familie_id })}
                              className="text-left group">
                        <p className="font-bold text-stone-700 group-hover:opacity-60 transition-opacity">
                          {mitglieder[0].familienname || kopf.join(' / ') || t('stamm.ohne_namen')}
                          <Pencil size={12} className="inline ml-2 mb-0.5 text-stone-300" />
                        </p>
                        {!mitglieder[0].familienname && (
                          <p className="text-[10px] text-stone-300">{t('stamm.name_fehlt')}</p>
                        )}
                      </button>
                    )}
                    <p className="text-[11px] text-stone-400">
                      {mitglieder.length} {t('stamm.personen')} ·{' '}
                      {new Set(generationen(alsKnoten(ids)).values()).size} {t('stamm.generationen')}
                    </p>
                  </div>
                  <button onClick={() => oeffnen(ids)}
                          className="text-[10px] font-bold uppercase tracking-widest shrink-0"
                          style={{ color: 'var(--primary)' }}>
                    {t('stamm.bearbeiten')}
                  </button>
                </div>
                {/* Person anklicken: gleich in der Werkbank bei ihr. */}
                <Familienbaum leute={alsKnoten(ids)} onWaehlen={(id) => id && oeffnen(ids, id)} />
              </div>
            );
          })}
          {f && !gezeigt.length && <p className="text-xs text-stone-400">{t('stamm.nichts_gefunden')}</p>}
        </div>
      )}
    </div>
  );
};

export default AdminStammbaum;
