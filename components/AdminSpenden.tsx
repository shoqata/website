import React, { useEffect, useMemo, useState } from 'react';
import { Heart, Loader2, AlertTriangle, Check, FileText, Search } from 'lucide-react';
import { collection, onSnapshot, query, orderBy, supabase } from '../services/supabase-bridge';
import { db } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Spenden in der Vereinsverwaltung.
//
// Bezahltsetzen und Verbuchen geschehen in einer Handlung -- die Datenbank
// macht beides zusammen. Waere es zweierlei, gaebe es unweigerlich Spenden,
// die als bezahlt gelten und nie im Journal stehen.

type Spende = {
  id: string; betrag: number; waehrung: string; name: string | null;
  email: string | null; strasse: string | null; plz: string | null; ort: string | null;
  anonym: boolean; nachricht: string | null; zweck: string | null;
  referenz: string | null; status: string; weg: string | null;
  eingegangen_am: string | null; bescheinigt_am: string | null; erfasst_am: string;
};

const AdminSpenden: React.FC = () => {
  const { t } = useTranslation();
  const [spenden, setSpenden] = useState<Spende[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState<string | null>(null);
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [suche, setSuche] = useState('');
  const [filter, setFilter] = useState<'ALLE' | 'OFFEN' | 'BEZAHLT'>('OFFEN');

  useEffect(() => {
    const unsub = onSnapshot(query(collection(db, 'donations'), orderBy('erfasst_am', 'desc')), (snap) => {
      setSpenden(snap.docs.map(d => ({ id: d.id, ...d.data() } as Spende)));
      setLaedt(false);
    });
    return () => unsub();
  }, []);

  const handeln = async (s: Spende, was: 'BEZAHLT' | 'BESCHEINIGT', weg?: string) => {
    setArbeitet(s.id); setFehler(null);
    try {
      const { error } = was === 'BEZAHLT'
        ? await supabase.rpc('spende_bezahlt', { p_spende: s.id, p_weg: weg ?? 'QR' })
        : await supabase.rpc('spende_bescheinigt', { p_spende: s.id });
      if (error) throw error;
    } catch (e: any) { setFehler(e?.message ?? String(e)); }
    finally { setArbeitet(null); }
  };

  const gezeigt = useMemo(() => spenden
    .filter(s => filter === 'ALLE' || s.status === filter)
    .filter(s => !suche.trim() ||
      [s.name, s.email, s.referenz, s.zweck].filter(Boolean)
        .some(x => String(x).toLowerCase().includes(suche.trim().toLowerCase()))),
    [spenden, filter, suche]);

  const summe = useMemo(() => spenden
    .filter(s => s.status === 'BEZAHLT')
    .reduce((n, s) => n + Number(s.betrag || 0), 0), [spenden]);
  const offen = spenden.filter(s => s.status === 'OFFEN').length;

  if (laedt) return (
    <div className="flex items-center gap-3 p-8 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('spenden.laedt')}</span>
    </div>
  );

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div className="bg-white p-5 rounded-2xl border border-stone-100">
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1">{t('spenden.eingegangen')}</p>
          <p className="text-2xl font-bold text-stone-900 tabular-nums">{summe.toLocaleString('de-CH')}.—</p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-stone-100">
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1">{t('spenden.offen')}</p>
          <p className="text-2xl font-bold text-stone-900 tabular-nums">{offen}</p>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-stone-100">
          <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-1">{t('spenden.gesamt')}</p>
          <p className="text-2xl font-bold text-stone-900 tabular-nums">{spenden.length}</p>
        </div>
      </div>

      <div className="flex gap-3 flex-wrap items-center">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
          <input value={suche} onChange={e => setSuche(e.target.value)} placeholder={t('spenden.suchen')}
                 className="w-full pl-9 pr-3 py-2.5 bg-white border border-stone-200 rounded-xl text-xs outline-none feld-primaer" />
        </div>
        {(['OFFEN','BEZAHLT','ALLE'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
                  className={`px-4 py-2.5 rounded-xl text-[10px] font-bold uppercase tracking-widest ${
                    filter === f ? 'knopf-primaer text-white' : 'bg-white border border-stone-200 text-stone-500'}`}>
            {t(`spenden.f_${f.toLowerCase()}`)}
          </button>
        ))}
      </div>

      {fehler && (
        <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl text-xs text-rose-700">
          <AlertTriangle size={16} className="shrink-0 mt-0.5" /> <span>{fehler}</span>
        </div>
      )}

      {gezeigt.length === 0 ? (
        <div className="p-10 bg-stone-50 rounded-3xl border border-stone-100 text-center">
          <Heart size={22} className="text-stone-300 mx-auto mb-3" />
          <p className="text-sm text-stone-400">{t('spenden.leer')}</p>
        </div>
      ) : (
        <div className="space-y-2">
          {gezeigt.map(s => (
            <div key={s.id} className="bg-white p-5 rounded-2xl border border-stone-100">
              <div className="flex items-start justify-between gap-4 flex-wrap">
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap mb-1">
                    <span className="font-bold text-stone-900 text-sm">
                      {s.anonym ? t('spenden.anonym') : (s.name || '—')}
                    </span>
                    <span className={`text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded ${
                      s.status === 'BEZAHLT' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>
                      {t(`spenden.s_${s.status.toLowerCase()}`)}
                    </span>
                    {s.bescheinigt_am && (
                      <span className="text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded bg-stone-100 text-stone-500">
                        {t('spenden.bescheinigt')}
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-stone-400">
                    {s.zweck ? `${s.zweck} · ` : ''}{s.email || ''}
                  </p>
                  {s.referenz && (
                    <p className="font-mono text-[10px] text-stone-300 mt-1 break-all">{s.referenz}</p>
                  )}
                  {s.nachricht && (
                    <p className="text-xs text-stone-500 italic mt-2 max-w-lg">»{s.nachricht}«</p>
                  )}
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <span className="text-lg font-bold text-stone-900 tabular-nums">
                    {Number(s.betrag).toLocaleString('de-CH')}.—
                  </span>
                  {s.status === 'OFFEN' ? (
                    <div className="flex gap-1.5">
                      {(['QR','TWINT','BAR'] as const).map(w => (
                        <button key={w} onClick={() => handeln(s, 'BEZAHLT', w)}
                                disabled={arbeitet === s.id}
                                className="px-2.5 py-1.5 rounded-lg text-[9px] font-bold uppercase tracking-widest bg-stone-100 text-stone-600 hover:bg-stone-200 disabled:opacity-50">
                          {arbeitet === s.id ? <Loader2 className="animate-spin" size={9} /> : w}
                        </button>
                      ))}
                    </div>
                  ) : !s.anonym && !s.bescheinigt_am ? (
                    <button onClick={() => handeln(s, 'BESCHEINIGT')} disabled={arbeitet === s.id}
                            className="px-3 py-1.5 rounded-lg text-[9px] font-bold uppercase tracking-widest bg-stone-900 text-white hover:bg-black disabled:opacity-50 inline-flex items-center gap-1.5">
                      <FileText size={10} /> {t('spenden.bescheinigen')}
                    </button>
                  ) : (
                    <Check size={16} className="text-emerald-500" />
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminSpenden;
