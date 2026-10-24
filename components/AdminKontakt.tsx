import React, { useEffect, useState } from 'react';
import { Loader2, Save, Check, AlertTriangle } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Kontaktformular einstellen: an oder aus, und wohin die Benachrichtigung
// geht. Die Adresse liegt nicht im Branding -- das ist oeffentlich lesbar,
// und eine private Empfaengeradresse gehoert nicht auf die Website.
// Titel, Text und Telefon stehen darueber im Branding (Veroeffentlichen).

const AdminKontakt: React.FC = () => {
  const [stand, setStand] = useState<{ aktiv: boolean; empfaenger: string; vorgabe: string | null } | null>(null);
  const [arbeitet, setArbeitet] = useState(false);
  const [gespeichert, setGespeichert] = useState(false);
  const [fehler, setFehler] = useState('');

  useEffect(() => {
    supabase.rpc('kontakt_einstellung_lesen').then(({ data, error }) => {
      if (error) { setFehler(error.message); return; }
      const d: any = data || {};
      setStand({ aktiv: d.aktiv !== false, empfaenger: d.empfaenger || '', vorgabe: d.vorgabe || null });
    });
  }, []);

  const sichern = async () => {
    if (!stand) return;
    setArbeitet(true); setFehler('');
    const { error } = await supabase.rpc('kontakt_einstellung_setzen', { p_aktiv: stand.aktiv, p_empfaenger: stand.empfaenger });
    setArbeitet(false);
    if (error) { setFehler(error.message); return; }
    setGespeichert(true); setTimeout(() => setGespeichert(false), 2000);
  };

  if (!stand) return fehler
    ? <p className="text-xs text-red-600 bg-red-50 rounded-xl p-3">{fehler}</p>
    : <div className="p-4 text-stone-400 text-sm flex items-center gap-2"><Loader2 size={14} className="animate-spin" /> Lädt …</div>;

  return (
    <div className="bg-stone-50 rounded-3xl border border-stone-200 p-6 space-y-4">
      <p className="text-[10px] font-bold uppercase tracking-widest text-stone-500">Formular</p>
      <label className="flex items-center gap-3 cursor-pointer">
        <input type="checkbox" checked={stand.aktiv} onChange={e => setStand({ ...stand, aktiv: e.target.checked })}
          className="w-4 h-4 accent-stone-900" />
        <span className="text-sm text-stone-800 font-bold">Kontaktformular auf der Website anbieten</span>
      </label>
      <div>
        <label className="text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-1.5">Benachrichtigung an</label>
        <input type="email" value={stand.empfaenger} onChange={e => setStand({ ...stand, empfaenger: e.target.value })}
          placeholder={stand.vorgabe || 'vorstand@verein.ch'}
          className="w-full p-3 bg-white border border-stone-200 rounded-xl text-sm outline-none" />
        <p className="text-[10px] text-stone-400 mt-1.5 leading-relaxed">
          Leer: an die Kontaktadresse des Vereins{stand.vorgabe ? ` (${stand.vorgabe})` : ''}. Diese Adresse wird nicht auf der
          Website angezeigt. Jede Nachricht steht ausserdem unter Kommunikation → Anfragen.
        </p>
      </div>
      {fehler && <p className="text-xs text-red-600 bg-red-50 rounded-xl p-3 flex gap-2"><AlertTriangle size={14} /> {fehler}</p>}
      <button onClick={sichern} disabled={arbeitet}
        className="flex items-center gap-2 bg-stone-900 text-white px-5 py-2.5 rounded-xl text-[10px] font-bold uppercase tracking-widest disabled:opacity-40">
        {arbeitet ? <Loader2 size={12} className="animate-spin" /> : gespeichert ? <Check size={12} /> : <Save size={12} />}
        {gespeichert ? 'Gespeichert' : 'Formular speichern'}
      </button>
    </div>
  );
};

export default AdminKontakt;
