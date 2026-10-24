import React, { useEffect, useMemo, useState } from 'react';
import { Loader2, Globe2, Wand2, ChevronDown, ChevronUp, AlertTriangle, Check } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { HAEUFIGE_LAENDER, landName } from '../lib/laender';

// Mehrere Vertreter in einer Nachbarschaft: wer betreut wen?
//
// Zugeteilt wird pro Mitglied. Die Laender eines Vertreters sind nur die
// Hilfe dafuer: "Offene nach Land zuteilen" gibt jedem Vertreter die noch
// nicht Zugeteilten aus seinen Laendern. Wer keinem zugeteilt ist, sehen
// alle Vertreter der Nachbarschaft -- darum steht die Zahl der Offenen
// oben, sie ist die Arbeitsliste.
//
// Die Grenze selbst zieht die Datenbank (vertreter_sieht); diese Maske
// stellt sie nur ein.

type Stand = {
  r_nachbarschaft: string; r_name: string; r_person: string; r_person_name: string;
  r_laender: string[]; r_zugeteilt: number; r_offen: number; r_mitglieder: number;
};
type Mitglied = { r_id: string; r_name: string; r_land: string | null; r_ort: string | null; r_betreuer: string | null };

const Nachbarschaft: React.FC<{ zeilen: Stand[]; neuLaden: () => void }> = ({ zeilen, neuLaden }) => {
  const nb = zeilen[0];
  const [offen, setOffen] = useState(false);
  const [mitglieder, setMitglieder] = useState<Mitglied[] | null>(null);
  const [arbeitet, setArbeitet] = useState('');
  const [meldung, setMeldung] = useState('');
  const [fehler, setFehler] = useState('');
  const [filter, setFilter] = useState<'ALLE' | 'OFFEN'>('OFFEN');

  const mitgliederLaden = async () => {
    const { data, error } = await supabase.rpc('zustaendigkeit_mitglieder', { p_nb: nb.r_nachbarschaft });
    if (error) setFehler(error.message);
    setMitglieder((data as Mitglied[]) ?? []);
  };
  useEffect(() => { if (offen && mitglieder === null) mitgliederLaden(); }, [offen]);

  const ausfuehren = async (schluessel: string, fn: () => Promise<any>, text?: (d: any) => string) => {
    setArbeitet(schluessel); setFehler(''); setMeldung('');
    const { data, error } = await fn();
    setArbeitet('');
    if (error) { setFehler(error.message); return; }
    if (text) setMeldung(text(data));
    neuLaden();
    if (mitglieder !== null) mitgliederLaden();
  };

  const landUmschalten = (z: Stand, code: string) => {
    const neu = z.r_laender.includes(code) ? z.r_laender.filter(l => l !== code) : [...z.r_laender, code];
    ausfuehren('land' + z.r_person + code, () => supabase.rpc('vertreter_gebiet_setzen',
      { p_nb: nb.r_nachbarschaft, p_person: z.r_person, p_laender: neu }));
  };

  // Laender, die in der Nachbarschaft vorkommen, gehoeren in die Auswahl,
  // auch wenn sie nicht zu den haeufigen zaehlen.
  const laenderAuswahl = useMemo(() => {
    const vorhanden = new Set<string>(HAEUFIGE_LAENDER.slice(0, 3));
    zeilen.forEach(z => z.r_laender.forEach(l => vorhanden.add(l)));
    (mitglieder ?? []).forEach(m => m.r_land && vorhanden.add(m.r_land));
    return [...vorhanden];
  }, [zeilen, mitglieder]);

  const sichtbar = (mitglieder ?? []).filter(m => filter === 'ALLE' || !m.r_betreuer);

  return (
    <div className="border border-stone-100 rounded-2xl overflow-hidden">
      <div className="p-4 bg-stone-50 flex items-center justify-between gap-3 flex-wrap">
        <div>
          <p className="font-bold text-sm text-stone-900">{nb.r_name}</p>
          <p className="text-[11px] text-stone-500 mt-0.5">
            {zeilen.length} Vertreter · {nb.r_mitglieder} Mitglieder ·{' '}
            {nb.r_offen > 0
              ? <span className="text-amber-700 font-bold">{nb.r_offen} noch niemandem zugeteilt</span>
              : <span className="text-emerald-700 font-bold">alle zugeteilt</span>}
          </p>
        </div>
        <button
          onClick={() => ausfuehren('auto', () => supabase.rpc('nach_land_zuteilen', { p_nb: nb.r_nachbarschaft }),
            (n) => n > 0 ? `${n} Mitglieder nach Land zugeteilt.` : 'Niemand passte zu genau einem Vertreter.')}
          disabled={!!arbeitet || nb.r_offen === 0 || !zeilen.some(z => z.r_laender.length > 0)}
          title={!zeilen.some(z => z.r_laender.length > 0) ? 'Zuerst bei den Vertretern Länder wählen' : ''}
          className="px-3 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs flex items-center gap-2 disabled:opacity-40">
          {arbeitet === 'auto' ? <Loader2 size={13} className="animate-spin" /> : <Wand2 size={13} />}
          Offene nach Land zuteilen
        </button>
      </div>

      <div className="divide-y divide-stone-50">
        {zeilen.map(z => (
          <div key={z.r_person} className="p-4 flex items-start justify-between gap-4 flex-wrap">
            <div className="min-w-0">
              <p className="font-bold text-sm text-stone-900">{z.r_person_name}</p>
              <p className="text-[11px] text-stone-500 mt-0.5">
                {z.r_zugeteilt} zugeteilt
                {z.r_laender.length > 0 && <> · zuständig für {z.r_laender.map(landName).join(', ')}</>}
              </p>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {laenderAuswahl.map(code => {
                const an = z.r_laender.includes(code);
                return (
                  <button key={code} onClick={() => landUmschalten(z, code)} disabled={!!arbeitet}
                    className={`px-2.5 py-1 rounded-full text-[11px] font-bold border transition-colors ${
                      an ? 'bg-primary text-white border-primary' : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400'}`}>
                    {an && <Check size={10} className="inline mr-1 -mt-0.5" />}{landName(code)}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {(meldung || fehler) && (
        <p className={`mx-4 mb-3 text-xs rounded-xl p-3 flex gap-2 ${fehler ? 'text-red-700 bg-red-50' : 'text-emerald-800 bg-emerald-50'}`}>
          {fehler && <AlertTriangle size={14} className="shrink-0 mt-0.5" />} {fehler || meldung}
        </p>
      )}

      <button onClick={() => setOffen(!offen)}
        className="w-full px-4 py-3 border-t border-stone-100 text-xs font-bold text-stone-600 hover:bg-stone-50 flex items-center justify-center gap-2">
        {offen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
        Mitglieder einzeln zuteilen
      </button>

      {offen && (
        <div className="border-t border-stone-100">
          <div className="px-4 pt-3 flex gap-2">
            {(['OFFEN', 'ALLE'] as const).map(f => (
              <button key={f} onClick={() => setFilter(f)}
                className={`px-3 py-1 rounded-lg text-[11px] font-bold ${filter === f ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-500'}`}>
                {f === 'OFFEN' ? 'Nicht zugeteilt' : 'Alle'}
              </button>
            ))}
          </div>
          {mitglieder === null ? (
            <p className="p-4 text-xs text-stone-400 flex items-center gap-2"><Loader2 size={13} className="animate-spin" /> Lädt …</p>
          ) : sichtbar.length === 0 ? (
            <p className="p-4 text-xs text-stone-400 italic">
              {filter === 'OFFEN' ? 'Alle Mitglieder sind zugeteilt.' : 'Keine Mitglieder.'}
            </p>
          ) : (
            <div className="divide-y divide-stone-50 max-h-96 overflow-y-auto">
              {sichtbar.map(m => (
                <div key={m.r_id} className="px-4 py-2.5 flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-sm text-stone-900 truncate">{m.r_name}</p>
                    <p className="text-[11px] text-stone-400">{landName(m.r_land)}{m.r_ort ? ` · ${m.r_ort}` : ''}</p>
                  </div>
                  <select value={m.r_betreuer || ''} disabled={!!arbeitet}
                    onChange={e => ausfuehren('m' + m.r_id, () => supabase.rpc('betreuer_setzen',
                      { p_mitglieder: [m.r_id], p_betreuer: e.target.value || null }))}
                    className="p-2 bg-white border border-stone-200 rounded-lg text-xs font-bold max-w-[12rem]">
                    <option value="">Alle Vertreter</option>
                    {zeilen.map(z => <option key={z.r_person} value={z.r_person}>{z.r_person_name}</option>)}
                  </select>
                </div>
              ))}
            </div>
          )}
          {mitglieder !== null && filter === 'ALLE' && (
            <p className="px-4 py-2 text-[10px] text-stone-400">
              „Alle Vertreter“ heisst: noch niemandem zugeteilt, jeder Vertreter der Nachbarschaft sieht das Mitglied.
            </p>
          )}
        </div>
      )}
    </div>
  );
};

const VertreterZustaendigkeit: React.FC = () => {
  const [stand, setStand] = useState<Stand[] | null>(null);
  const [fehler, setFehler] = useState('');

  const laden = async () => {
    const { data, error } = await supabase.rpc('zustaendigkeit_stand');
    if (error) setFehler(error.message);
    setStand((data as Stand[]) ?? []);
  };
  useEffect(() => { laden(); }, []);

  // Nur Nachbarschaften mit mehr als einem Vertreter: bei einem allein gibt
  // es nichts aufzuteilen.
  const gruppen = useMemo(() => {
    const m = new Map<string, Stand[]>();
    (stand ?? []).forEach(z => m.set(z.r_nachbarschaft, [...(m.get(z.r_nachbarschaft) || []), z]));
    return [...m.values()].filter(g => g.length > 1);
  }, [stand]);

  if (stand === null) return null;

  return (
    <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
      <div className="p-5 border-b border-stone-100 bg-stone-50">
        <h3 className="font-bold text-sm text-stone-900 flex items-center gap-2">
          <Globe2 size={15} className="text-primary" /> Zuständigkeit innerhalb der Nachbarschaft
        </h3>
        <p className="text-[11px] text-stone-500 mt-1 leading-relaxed">
          Hat eine Nachbarschaft mehrere Vertreter, sieht jeder nur die ihm zugeteilten Mitglieder —
          zum Beispiel einer für Kosovo, einer für die Schweiz, einer für Deutschland.
          Wer noch niemandem zugeteilt ist, sehen alle Vertreter dieser Nachbarschaft.
        </p>
      </div>
      {fehler && <p className="m-5 text-xs text-red-600 bg-red-50 rounded-xl p-3">{fehler}</p>}
      <div className="p-5 space-y-4">
        {gruppen.map(g => <Nachbarschaft key={g[0].r_nachbarschaft} zeilen={g} neuLaden={laden} />)}
        {gruppen.length === 0 && (
          <p className="text-sm text-stone-400 italic text-center py-4">
            Keine Nachbarschaft hat mehr als einen Vertreter. Unter Nachbarschaften lassen sich
            weitere Verantwortliche hinterlegen.
          </p>
        )}
      </div>
    </div>
  );
};

export default VertreterZustaendigkeit;
