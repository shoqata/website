import React, { useState } from 'react';
import { Plus, Loader2, Pencil, Trash2, Check, X } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Konten im Kontenplan anlegen, umbenennen, loeschen.
//
// Die Pruefungen stehen in der Datenbank (konto_anlegen, konto_aendern,
// konto_loeschen): Nummer eindeutig, Art aus der ersten Ziffer, Loeschen
// nur ohne Buchungen. Hier steht nur, was man dafuer eingibt.

export const KLASSEN: [string, string][] = [
  ['ASSET', 'Aktiven'], ['LIABILITY', 'Passiven'], ['REVENUE', 'Ertrag'], ['EXPENSE', 'Aufwand'],
];
const vorschlag = (code: string) => ({ '1': 'ASSET', '2': 'LIABILITY', '3': 'REVENUE', '9': 'LIABILITY' } as any)[code[0]]
  ?? (/^[4-8]/.test(code) ? 'EXPENSE' : '');

export const KontoAnlegen: React.FC<{ vorhandene: string[]; onFertig: () => void }> = ({ vorhandene, onFertig }) => {
  const [offen, setOffen] = useState(false);
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [klasse, setKlasse] = useState('');
  const [gruppe, setGruppe] = useState('');
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState('');

  const art = klasse || vorschlag(code);
  const doppelt = vorhandene.includes(code.trim());

  const anlegen = async () => {
    setArbeitet(true); setFehler('');
    const { error } = await supabase.rpc('konto_anlegen', {
      p_code: code.trim(), p_name: name.trim(), p_klasse: art || null, p_kategorie: gruppe.trim() || null });
    setArbeitet(false);
    if (error) { setFehler(error.message); return; }
    setCode(''); setName(''); setKlasse(''); setGruppe(''); setOffen(false);
    onFertig();
  };

  if (!offen) return (
    <button onClick={() => setOffen(true)}
      className="col-span-full px-5 py-4 border-2 border-dashed border-stone-200 rounded-[2rem] text-sm font-bold text-stone-500 hover:border-stone-400 hover:text-stone-800 flex items-center justify-center gap-2">
      <Plus size={16} /> Neues Konto anlegen
    </button>
  );

  const feld = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none';
  return (
    <div className="col-span-full bg-white border border-stone-200 rounded-[2rem] p-6 space-y-4">
      <div className="flex items-center justify-between">
        <h4 className="font-bold text-stone-900">Neues Konto</h4>
        <button onClick={() => setOffen(false)} className="p-1.5 hover:bg-stone-100 rounded-lg text-stone-400"><X size={16} /></button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
        <div>
          <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Nummer</label>
          <input value={code} onChange={e => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="z. B. 6510" inputMode="numeric" className={`${feld} font-mono`} />
          {doppelt && <p className="text-[11px] text-red-600 mt-1">Gibt es schon.</p>}
        </div>
        <div className="md:col-span-2">
          <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Name</label>
          <input value={name} onChange={e => setName(e.target.value)} placeholder="z. B. Telefon und Internet" className={feld} />
        </div>
        <div>
          <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Art</label>
          <select value={art} onChange={e => setKlasse(e.target.value)} className={feld}>
            <option value="">—</option>
            {KLASSEN.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
          </select>
        </div>
        <div className="md:col-span-2">
          <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Gruppe (freiwillig)</label>
          <input value={gruppe} onChange={e => setGruppe(e.target.value)} placeholder="z. B. Verwaltungsaufwand" className={feld} />
        </div>
        <p className="md:col-span-2 text-[11px] text-stone-500 self-end leading-relaxed">
          Die Art ergibt sich aus der ersten Ziffer: 1 Aktiven, 2 Passiven, 3 Ertrag, 4–8 Aufwand.
          Sie bestimmt, wo das Konto in Bilanz und Erfolgsrechnung steht.
        </p>
      </div>
      {fehler && <p className="text-xs text-red-700 bg-red-50 rounded-xl p-3">{fehler}</p>}
      <button onClick={anlegen} disabled={arbeitet || code.length < 3 || !name.trim() || !art || doppelt}
        className="px-5 py-3 bg-stone-900 text-white rounded-xl font-bold text-sm flex items-center gap-2 disabled:opacity-40">
        {arbeitet ? <Loader2 size={15} className="animate-spin" /> : <Plus size={15} />} Konto anlegen
      </button>
    </div>
  );
};

export const KontoBearbeiten: React.FC<{
  konto: { code: string; name: string; category?: string; systemAccount?: boolean };
  buchungen: number; onFertig: (geloescht: boolean) => void;
}> = ({ konto, buchungen, onFertig }) => {
  const [modus, setModus] = useState<'' | 'NAME' | 'LOESCHEN'>('');
  const [name, setName] = useState(konto.name);
  const [gruppe, setGruppe] = useState(konto.category || '');
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState('');

  const ausfuehren = async (fn: () => PromiseLike<{ error: any }>, geloescht: boolean) => {
    setArbeitet(true); setFehler('');
    const { error } = await fn();
    setArbeitet(false);
    if (error) { setFehler(error.message); return; }
    setModus(''); onFertig(geloescht);
  };
  const loeschbar = buchungen === 0 && !konto.systemAccount && konto.code !== '9100';

  return (
    <div className="flex items-center gap-2 flex-wrap">
      {modus === 'NAME' ? (
        <>
          <input value={name} onChange={e => setName(e.target.value)} className="p-2 border border-stone-200 rounded-lg text-sm w-56" />
          <input value={gruppe} onChange={e => setGruppe(e.target.value)} placeholder="Gruppe" className="p-2 border border-stone-200 rounded-lg text-sm w-40" />
          <button disabled={arbeitet || !name.trim()} onClick={() => ausfuehren(() => supabase.rpc('konto_aendern',
            { p_code: konto.code, p_name: name, p_kategorie: gruppe || null }), false)}
            className="p-2 bg-stone-900 text-white rounded-lg"><Check size={15} /></button>
          <button onClick={() => setModus('')} className="p-2 hover:bg-stone-200 rounded-lg text-stone-500"><X size={15} /></button>
        </>
      ) : modus === 'LOESCHEN' ? (
        <>
          <span className="text-sm font-bold text-red-700">Konto {konto.code} löschen?</span>
          <button disabled={arbeitet} onClick={() => ausfuehren(() => supabase.rpc('konto_loeschen', { p_code: konto.code }), true)}
            className="px-3 py-2 bg-red-600 text-white rounded-lg text-sm font-bold">Löschen</button>
          <button onClick={() => setModus('')} className="px-3 py-2 hover:bg-stone-200 rounded-lg text-sm text-stone-500">Abbrechen</button>
        </>
      ) : (
        <>
          <button onClick={() => setModus('NAME')} className="flex items-center gap-2 px-3 py-2 bg-white border border-stone-200 rounded-lg text-sm font-bold text-stone-600 hover:text-primary">
            <Pencil size={14} /> Umbenennen
          </button>
          <button onClick={() => setModus('LOESCHEN')} disabled={!loeschbar}
            title={loeschbar ? '' : buchungen > 0 ? `${buchungen} Buchungen — nur umbenennen möglich` : 'Systemkonto'}
            className="flex items-center gap-2 px-3 py-2 bg-white border border-stone-200 rounded-lg text-sm font-bold text-stone-600 hover:text-red-600 disabled:opacity-40">
            <Trash2 size={14} /> Löschen
          </button>
        </>
      )}
      {arbeitet && <Loader2 size={15} className="animate-spin text-stone-400" />}
      {fehler && <span className="text-xs text-red-600">{fehler}</span>}
    </div>
  );
};
