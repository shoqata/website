import React, { useEffect, useState } from 'react';
import { Film, Plus, Trash2, Eye, EyeOff, Loader2, Save } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';

type Video = {
  id: string; titel: string; beschreibung: string | null;
  quelle: string; vorschaubild: string | null;
  status: 'ENTWURF' | 'OEFFENTLICH'; reihenfolge: number;
};

// Die Videoseite des Vereins.
//
// Die Filme entstehen nicht hier. Sie werden ausserhalb geschnitten -- mit
// einem Werkzeug wie hyperframes-student-kit, das Node, FFmpeg und Chrome
// braucht und MP4-Dateien erzeugt -- und dann hier veroeffentlicht. Diese
// Maske verwaltet also Verweise und Reihenfolge, keinen Schnitt.
//
// Entwurf heisst: nur hier sichtbar. Oeffentlich heisst: auf der Website.
// Entschieden wird das in der Zeilenregel videos_public_read, nicht in
// dieser Maske -- sonst holte sich jeder die Entwuerfe ueber die
// Schnittstelle.
const AdminVideos: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [videos, setVideos] = useState<Video[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [speichert, setSpeichert] = useState<string | null>(null);
  const [neu, setNeu] = useState<Partial<Video>>({ titel: '', quelle: '', beschreibung: '' });

  const laden = async () => {
    const { data, error } = await supabase.from('videos').select('*')
      .order('reihenfolge').order('erstellt_am', { ascending: false });
    if (!error) setVideos((data as Video[]) || []);
    setLaedt(false);
  };
  useEffect(() => { laden(); }, []);

  const anlegen = async () => {
    if (!neu.titel?.trim() || !neu.quelle?.trim()) {
      showAlert({ type: 'warning', message: t('video.fehlt') });
      return;
    }
    setSpeichert('neu');
    const { error } = await supabase.from('videos').insert([{
      titel: neu.titel.trim(),
      quelle: neu.quelle.trim(),
      beschreibung: neu.beschreibung?.trim() || null,
      status: 'ENTWURF',
    }]);
    setSpeichert(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setNeu({ titel: '', quelle: '', beschreibung: '' });
    laden();
  };

  const umschalten = async (v: Video) => {
    setSpeichert(v.id);
    const { error } = await supabase.from('videos')
      .update({ status: v.status === 'OEFFENTLICH' ? 'ENTWURF' : 'OEFFENTLICH' })
      .eq('id', v.id);
    setSpeichert(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  const entfernen = async (v: Video) => {
    const ja = await showConfirm({
      title: t('video.entfernen'), message: t('video.entfernen_frage', { titel: v.titel }),
      confirmText: t('video.entfernen'), type: 'danger',
    });
    if (!ja) return;
    const { error } = await supabase.from('videos').delete().eq('id', v.id);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  const feld = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

  return (
    <div className="max-w-5xl mx-auto space-y-8 p-2">
      <div className="flex items-center gap-3">
        <div className="bg-stone-100 text-stone-500 p-3 rounded-2xl"><Film size={22} /></div>
        <div>
          <h2 className="text-xl font-bold text-stone-900">{t('video.titel')}</h2>
          <p className="text-xs text-stone-400">{t('video.untertitel')}</p>
        </div>
      </div>

      <div className="bg-white p-8 rounded-[2rem] border border-stone-100 shadow-sm space-y-4">
        <h3 className="font-bold text-stone-900 text-sm flex items-center gap-2">
          <Plus size={16} className="text-stone-400" /> {t('video.neu')}
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className={marke}>{t('field.name')}</label>
            <input value={neu.titel || ''} onChange={e => setNeu({ ...neu, titel: e.target.value })}
              className={feld} placeholder={t('video.titel_beispiel')} />
          </div>
          <div>
            <label className={marke}>{t('video.quelle')}</label>
            <input value={neu.quelle || ''} onChange={e => setNeu({ ...neu, quelle: e.target.value })}
              className={feld + ' font-mono text-xs'} placeholder="https://…/film.mp4" />
          </div>
        </div>
        <div>
          <label className={marke}>{t('video.beschreibung')}</label>
          <textarea value={neu.beschreibung || ''} onChange={e => setNeu({ ...neu, beschreibung: e.target.value })}
            rows={2} className={feld} />
        </div>
        <button onClick={anlegen} disabled={speichert === 'neu'}
          className="bg-stone-900 text-white px-7 py-3 rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors disabled:opacity-50">
          {speichert === 'neu' ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
          {t('video.anlegen')}
        </button>
      </div>

      {laedt ? (
        <div className="text-center py-16 text-stone-400 text-sm">{t('common.loading')}</div>
      ) : videos.length === 0 ? (
        <div className="text-center py-20 bg-stone-50/60 rounded-3xl border border-dashed border-stone-200">
          <Film size={38} className="mx-auto text-stone-200 mb-4" />
          <p className="text-stone-400 text-sm">{t('video.leer')}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {videos.map(v => (
            <div key={v.id} className="bg-white p-5 rounded-2xl border border-stone-100 shadow-sm flex items-start gap-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <p className="font-bold text-stone-900 text-sm truncate">{v.titel}</p>
                  <span className={`text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded ${
                    v.status === 'OEFFENTLICH'
                      ? 'bg-emerald-50 text-emerald-600' : 'bg-stone-100 text-stone-500'}`}>
                    {v.status === 'OEFFENTLICH' ? t('video.oeffentlich') : t('video.entwurf')}
                  </span>
                </div>
                {v.beschreibung && <p className="text-xs text-stone-500 leading-relaxed mb-1">{v.beschreibung}</p>}
                <p className="text-[10px] text-stone-400 font-mono truncate">{v.quelle}</p>
              </div>
              <div className="flex gap-2 shrink-0">
                <button onClick={() => umschalten(v)} disabled={speichert === v.id}
                  title={v.status === 'OEFFENTLICH' ? t('video.verbergen') : t('video.zeigen')}
                  className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 transition-colors disabled:opacity-40">
                  {speichert === v.id ? <Loader2 size={15} className="animate-spin" />
                    : v.status === 'OEFFENTLICH' ? <Eye size={15} /> : <EyeOff size={15} />}
                </button>
                <button onClick={() => entfernen(v)}
                  className="p-2.5 rounded-xl border border-stone-200 text-stone-400 hover:border-rose-200 hover:text-rose-500 transition-colors">
                  <Trash2 size={15} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminVideos;
