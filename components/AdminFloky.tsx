import React, { useEffect, useState } from 'react';
import { Loader2, Sparkles, Save, Check, AlertTriangle } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Was der Verein an Floky einstellen darf.
//
// Zwei Dinge, und bewusst nicht mehr: wie der Helfer heisst und ob er die
// Mitglieder duzt. Das Kontingent steht hier nur als Anzeige -- es setzt
// der Betreiber. Waere es hier aenderbar, waere es keine Schranke.
//
// Ist das Modul nicht gebucht, erscheint statt der Einstellungen ein Satz,
// der das sagt. Ein Formular fuer etwas, das nicht laeuft, waere der
// gleiche Fehler wie ein Schalter ohne Wirkung.

const AdminFloky: React.FC = () => {
  const [darf, setDarf] = useState<boolean | null>(null);
  const [name, setName] = useState('Floky');
  const [du, setDu] = useState(false);
  const [stand, setStand] = useState<{ kontingent: number; verbraucht: number; uebrig: number } | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [fehler, setFehler] = useState<string | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const { data: d, error } = await supabase.rpc('floky_darf');
      if (!lebt) return;
      setDarf(!error && !!d);
      const [{ data: k }, { data: e }] = await Promise.all([
        supabase.rpc('floky_kontingent'),
        supabase.from('floky_einstellungen').select('assistent_name,anrede_du').maybeSingle(),
      ]);
      if (!lebt) return;
      const kk = Array.isArray(k) ? k[0] : k;
      if (kk) {
        setStand({ kontingent: kk.kontingent, verbraucht: kk.verbraucht, uebrig: kk.uebrig });
        setName(kk.assistent_name || 'Floky');
      }
      if (e) { setName(e.assistent_name || 'Floky'); setDu(!!e.anrede_du); }
    })();
    return () => { lebt = false; };
  }, []);

  const sichern = async () => {
    setSpeichert(true); setFehler(null);
    const { data, error } = await supabase.rpc('floky_name_setzen', { p_name: name, p_du: du });
    setSpeichert(false);
    if (error) { setFehler(error.message); return; }
    if (data) setName(data);
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
  };

  if (darf === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  if (!darf) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100">
      <p className="text-sm font-bold text-stone-800 flex items-center gap-2">
        <Sparkles size={15} className="text-stone-300" /> Floky ist nicht gebucht
      </p>
      <p className="text-[11px] text-stone-500 leading-relaxed mt-2 max-w-xl">
        Der Vereinsassistent nimmt Aufträge in Alltagssprache entgegen und bereitet
        Mitgliederpflege, Beitragsläufe, Buchungen und Texte vor. Er schlägt vor —
        gebucht, verschickt oder veröffentlicht wird nichts ohne Bestätigung.
        Zu finden im Marktplatz.
      </p>
    </div>
  );

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm text-stone-700 outline-none focus:border-stone-300';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div className="grid md:grid-cols-2 gap-5">
        <div>
          <label className={`${marke} block mb-2`}>Wie Ihr Helfer heisst</label>
          <input className={feld} value={name} onChange={e => setName(e.target.value)}
                 placeholder="Floky" maxLength={30} />
          <p className="text-[10px] text-stone-400 mt-2 leading-relaxed">
            Steht in der Oberfläche und in seinen Texten. Leer gelassen heisst er wieder Floky.
          </p>
        </div>
        <div>
          <label className={`${marke} block mb-2`}>Anrede gegenüber Mitgliedern</label>
          <div className="flex gap-1 bg-white p-1 rounded-xl border border-stone-200 w-fit">
            {([[false, 'Sie'], [true, 'du']] as const).map(([w, n]) => (
              <button key={String(w)} onClick={() => setDu(w)}
                className={`px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                  du === w ? 'bg-stone-900 text-white' : 'text-stone-400 hover:text-stone-700'}`}>
                {n}
              </button>
            ))}
          </div>
        </div>
      </div>

      {stand && (
        <div className="bg-white rounded-2xl border border-stone-100 p-5 flex flex-wrap gap-x-10 gap-y-3">
          {[['Anfragen diesen Monat', String(stand.verbraucht)],
            ['Kontingent', String(stand.kontingent)],
            ['Übrig', String(stand.uebrig)]].map(([k, v]) => (
            <div key={k}>
              <p className={marke}>{k}</p>
              <p className={`text-sm font-bold tabular-nums ${
                k === 'Übrig' && stand.uebrig === 0 ? 'text-amber-600' : 'text-stone-800'}`}>{v}</p>
            </div>
          ))}
          <p className="text-[10px] text-stone-400 leading-relaxed basis-full">
            Das Kontingent setzt der Plattformbetreiber. Es zählt in der Datenbank —
            nicht im Browser.
          </p>
        </div>
      )}

      <button onClick={sichern} disabled={speichert}
        className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2 rounded-xl
                   text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
        {speichert ? <Loader2 size={12} className="animate-spin" />
          : gespeichert ? <Check size={12} /> : <Save size={12} />}
        {gespeichert ? 'Gespeichert' : 'Speichern'}
      </button>
    </div>
  );
};

export default AdminFloky;
