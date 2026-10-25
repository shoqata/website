import React, { useEffect, useState } from 'react';
import { Eye, EyeOff, Globe, Loader2 } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';
import NachbarschaftProfilEditor from './NachbarschaftProfilEditor';

// Auf jeder Nachbarschaftskarte (Verwaltung, Vertreterbereich): ist die
// Nachbarschaft auf der Website zu sehen, und der Weg zur Vorstellung.

const NbWebsiteLeiste: React.FC<{ nb: { id: string; name: string }; darfBilder?: boolean }> = ({ nb, darfBilder }) => {
  const { showAlert } = useFeedback();
  const [sichtbar, setSichtbar] = useState<boolean | null>(null);
  const [arbeitet, setArbeitet] = useState(false);
  const [offen, setOffen] = useState(false);

  const laden = () => supabase.from('nachbarschaft_profil').select('sichtbar').eq('nachbarschaft', nb.id).maybeSingle()
    .then(({ data }) => setSichtbar(!!data?.sichtbar));
  useEffect(() => { laden(); }, [nb.id]);

  const umschalten = async (e: React.MouseEvent) => {
    e.stopPropagation();
    setArbeitet(true);
    const { error } = await supabase.rpc('nachbarschaft_sichtbar_setzen', { p_nachbarschaft: nb.id, p_sichtbar: !sichtbar });
    setArbeitet(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setSichtbar(!sichtbar);
  };

  return (
    <div onClick={e => e.stopPropagation()} className="flex items-center gap-2 mt-3">
      <button onClick={umschalten} disabled={arbeitet || sichtbar === null}
        title={sichtbar ? 'Auf der Website gezeigt — klicken zum Ausblenden' : 'Ausgeblendet — klicken zum Zeigen'}
        className={`flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold border transition-colors ${
          sichtbar ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-stone-50 text-stone-500 border-stone-200'}`}>
        {arbeitet || sichtbar === null ? <Loader2 size={13} className="animate-spin" /> : sichtbar ? <Eye size={13} /> : <EyeOff size={13} />}
        {sichtbar ? 'Auf der Website' : 'Ausgeblendet'}
      </button>
      <button onClick={() => setOffen(true)}
        className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold bg-stone-900 text-white">
        <Globe size={13} /> Vorstellung
      </button>
      {offen && <NachbarschaftProfilEditor nb={nb} darfBilder={darfBilder} onClose={() => setOffen(false)} onGespeichert={laden} />}
    </div>
  );
};

export default NbWebsiteLeiste;
