import React, { useEffect, useState } from 'react';
import {
  Newspaper, Plus, FileEdit, Trash2, X, Loader2, Upload, Clock, Heart, Image as BildIcon, ExternalLink,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { inhaltAlsText, datumLang, type Nachricht } from '../lib/news';
import { bildHochladen } from '../lib/bildHochladen';
import { kategorieName } from './NewsSection';
import { onImageError } from '../lib/imageFallback';

// Neuigkeiten schreiben und verwalten -- fuer die Verwaltung (Admin ->
// Neuigkeiten) und fuer den Vorstand (sein Dashboard).
//
// Der Vorstand durfte laut Datenbank schon immer schreiben (news_manage:
// is_staff, dazu gehoert BOARD) -- nur gab es fuer ihn keine Maske: die
// Verwaltung liegt unter /admin, und den Vorstand leitet die App von dort
// aufs Dashboard. Darum steht die Maske jetzt fuer sich und an beiden
// Orten. Ob der Vorstand gerade schreiben darf (vorstand_schreibt),
// entscheidet weiter die Datenbank; eine Absage erscheint als Meldung.

type Entwurf = Partial<Nachricht> & { id?: string };
const LEER: Entwurf = { title: '', content: '', image: '', category: 'DIASPORA', location: '', status: 'DRAFT', publishAt: null };

const alsLokal = (iso: string | null | undefined) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};

const NachrichtenVerwaltung: React.FC<{ karte?: boolean }> = ({ karte }) => {
  const { t, language } = useTranslation();
  const { showConfirm, showAlert } = useFeedback();
  const [liste, setListe] = useState<Nachricht[] | null>(null);
  const [likes, setLikes] = useState<Record<string, number>>({});
  const [offen, setOffen] = useState<Entwurf | null>(null);
  const [speichert, setSpeichert] = useState(false);
  const [laedtBild, setLaedtBild] = useState(false);

  const laden = async () => {
    const { data, error } = await supabase.from('news')
      .select('id,title,content,image,timestamp,publishAt,author,category,subcategory,location,status')
      .order('timestamp', { ascending: false }).limit(200);
    if (error) { showAlert({ type: 'error', message: error.message }); setListe([]); return; }
    setListe((data as Nachricht[]) ?? []);
    const { data: l } = await supabase.rpc('news_likes_verwaltung');
    const m: Record<string, number> = {};
    for (const z of (l as any[]) ?? []) m[z.news] = z.anzahl;
    setLikes(m);
  };
  useEffect(() => { laden(); }, []);

  const sichern = async () => {
    if (!offen) return;
    if (!String(offen.title || '').trim()) { showAlert({ type: 'error', message: t('news.titel_fehlt') }); return; }
    setSpeichert(true);
    const daten: any = {
      title: String(offen.title).trim(),
      content: inhaltAlsText(offen.content),
      image: offen.image || null,
      category: offen.category || null,
      location: offen.location || null,
      status: offen.status || 'DRAFT',
      publishAt: offen.publishAt ? new Date(offen.publishAt).toISOString() : null,
    };
    const { error } = offen.id
      ? await supabase.from('news').update(daten).eq('id', offen.id).select('id')
      : await supabase.from('news').insert({ ...daten, id: crypto.randomUUID(), timestamp: new Date().toISOString() }).select('id');
    setSpeichert(false);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    setOffen(null);
    showAlert({ type: 'success', message: t('admin.news.saved') });
    laden();
  };

  const loeschen = async (n: Nachricht) => {
    if (!(await showConfirm({ title: t('admin.confirm_delete'), message: `„${n.title}" — ${t('admin.delete_permanent')}`, type: 'danger' }))) return;
    const { error } = await supabase.from('news').delete().eq('id', n.id).select('id');
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  const statusFarbe = (s: string) => s === 'PUBLISHED' ? 'bg-emerald-100 text-emerald-700'
    : s === 'DRAFT' ? 'bg-amber-100 text-amber-700' : 'bg-stone-100 text-stone-500';
  const statusName = (s: string) => s === 'PUBLISHED' ? t('admin.publish.published')
    : s === 'DRAFT' ? t('admin.publish.draft') : t('admin.publish.archived');
  const feld = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1';

  return (
    <div className={karte ? 'bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm' : 'space-y-6'}>
      <div className={`flex justify-between items-center gap-4 flex-wrap ${karte ? 'mb-6' : 'bg-white p-6 rounded-3xl border border-stone-100 shadow-sm'}`}>
        <h3 className="font-bold text-stone-900 text-xl flex items-center gap-2"><Newspaper size={20} className="text-blue-600" /> {t('admin.news.title')}</h3>
        <button onClick={() => setOffen({ ...LEER })}
          className="bg-stone-900 text-white px-5 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 hover:bg-black">
          <Plus size={16} /> {t('admin.news.add')}
        </button>
      </div>

      <div className={karte ? '' : 'bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden'}>
        {liste === null ? (
          <div className="p-10 flex justify-center"><Loader2 className="animate-spin text-stone-300" /></div>
        ) : liste.length === 0 ? (
          <p className="py-10 text-center text-stone-400 italic">{t('admin.news.none')}</p>
        ) : (
          <div className="divide-y divide-stone-50">
            {liste.map(n => (
              <div key={n.id} className={`flex items-center gap-4 ${karte ? 'py-3' : 'px-6 py-4'} ${n.status === 'ARCHIVED' ? 'opacity-50' : ''}`}>
                <div className="w-12 h-12 rounded-xl bg-stone-100 overflow-hidden shrink-0 border border-stone-200 flex items-center justify-center">
                  {n.image ? <img src={n.image} alt="" className="w-full h-full object-cover" onError={onImageError} /> : <BildIcon className="text-stone-300" size={18} />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-stone-900 truncate">{n.title}</p>
                  <p className="text-[11px] text-stone-400 flex items-center gap-2 flex-wrap mt-0.5">
                    <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-widest ${statusFarbe(n.status)}`}>{statusName(n.status)}</span>
                    {n.category && <span>{kategorieName(n.category, t)}</span>}
                    <span>{datumLang(n.timestamp, language)}</span>
                    {n.publishAt && new Date(n.publishAt) > new Date() && (
                      <span className="text-primary font-bold inline-flex items-center gap-1"><Clock size={10} /> {new Date(n.publishAt).toLocaleString()}</span>
                    )}
                    {(likes[n.id] ?? 0) > 0 && <span className="inline-flex items-center gap-1"><Heart size={10} /> {likes[n.id]}</span>}
                  </p>
                </div>
                <div className="flex gap-2 shrink-0">
                  {n.status === 'PUBLISHED' && (
                    <a href={`/#/news/${encodeURIComponent(n.id)}`} target="_blank" rel="noopener noreferrer" title={t('news.ansehen')}
                      className="p-2 text-stone-400 hover:text-stone-900 bg-white border border-stone-200 rounded-lg"><ExternalLink size={14} /></a>
                  )}
                  <button onClick={() => setOffen({ ...n, publishAt: alsLokal(n.publishAt) as any })} title={t('common.edit')}
                    className="p-2 text-stone-400 hover:text-stone-900 bg-white border border-stone-200 rounded-lg"><FileEdit size={14} /></button>
                  <button onClick={() => loeschen(n)} title={t('common.delete')}
                    className="p-2 text-stone-400 hover:text-red-500 bg-white border border-stone-200 rounded-lg"><Trash2 size={14} /></button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {offen && (
        <div className="fixed inset-0 z-[300] flex items-center justify-center p-4 md:p-6 bg-stone-900/60 backdrop-blur-sm">
          <div className="bg-white w-full max-w-2xl rounded-[2.5rem] shadow-2xl overflow-hidden flex flex-col max-h-[92vh]">
            <div className="p-6 border-b border-stone-100 flex justify-between items-center bg-stone-50">
              <h3 className="font-bold text-xl text-stone-900 flex items-center gap-2"><Newspaper className="text-blue-600" /> {t('admin.news.details')}</h3>
              <button onClick={() => setOffen(null)} className="p-2 hover:bg-stone-200 rounded-full text-stone-500"><X size={20} /></button>
            </div>
            <div className="p-6 md:p-8 space-y-4 overflow-y-auto">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className={marke}>{t('field.status')}</label>
                  <select value={offen.status} onChange={e => setOffen({ ...offen, status: e.target.value })} className={`${feld} text-xs font-bold`}>
                    <option value="DRAFT">{t('admin.publish.draft')}</option>
                    <option value="PUBLISHED">{t('admin.publish.published')}</option>
                    <option value="ARCHIVED">{t('admin.publish.archived')}</option>
                  </select>
                </div>
                <div>
                  <label className={marke}>{t('admin.news.schedule')}</label>
                  <input type="datetime-local" value={(offen.publishAt as any) || ''}
                    onChange={e => setOffen({ ...offen, publishAt: e.target.value as any })} className={`${feld} text-xs font-bold`} />
                </div>
              </div>
              <div>
                <label className={marke}>{t('field.title')}</label>
                <input value={offen.title || ''} onChange={e => setOffen({ ...offen, title: e.target.value })} className={`${feld} font-bold`} />
              </div>
              <div>
                <label className={marke}>{t('admin.news.text')}</label>
                <textarea value={inhaltAlsText(offen.content)} onChange={e => setOffen({ ...offen, content: e.target.value })}
                  className={`${feld} h-64 leading-relaxed`} />
                <p className="text-[10px] text-stone-400 mt-1">{t('admin.news.text_hinweis')}</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className={marke}>{t('admin.news.location')}</label>
                  <input value={offen.location || ''} onChange={e => setOffen({ ...offen, location: e.target.value })} className={feld} />
                </div>
                <div>
                  <label className={marke}>{t('field.category')}</label>
                  <select value={offen.category || 'DIASPORA'} onChange={e => setOffen({ ...offen, category: e.target.value })} className={`${feld} text-xs font-bold`}>
                    <option value="DIASPORA">{t('cat.diaspora')}</option>
                    <option value="LOCAL">{t('cat.local')}</option>
                    <option value="PROJECT">{t('cat.project')}</option>
                  </select>
                </div>
              </div>
              <div>
                <label className={marke}>{t('field.image_url')}</label>
                <div className="flex gap-2">
                  <input value={offen.image || ''} onChange={e => setOffen({ ...offen, image: e.target.value })} placeholder="https://…" className={`${feld} flex-1 text-xs font-mono`} />
                  <label className={`shrink-0 px-4 bg-stone-100 hover:bg-stone-200 rounded-xl text-xs font-bold text-stone-600 flex items-center gap-1.5 cursor-pointer ${laedtBild ? 'opacity-50 pointer-events-none' : ''}`}>
                    {laedtBild ? <Loader2 size={13} className="animate-spin" /> : <Upload size={13} />} {t('web.upload')}
                    <input type="file" accept="image/*" hidden onChange={async e => {
                      const d = e.target.files?.[0]; e.target.value = '';
                      if (!d) return;
                      setLaedtBild(true);
                      try { const url = await bildHochladen(d, 'news'); setOffen(o => o ? { ...o, image: url } : o); }
                      catch (err: any) { showAlert({ type: 'error', message: err?.message || t('web.upload_failed') }); }
                      finally { setLaedtBild(false); }
                    }} />
                  </label>
                </div>
                {offen.image && <img src={offen.image} alt="" className="mt-3 w-full h-44 object-cover rounded-xl border border-stone-100" onError={onImageError} />}
              </div>
            </div>
            <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
              <button onClick={() => setOffen(null)} className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold">{t('common.cancel')}</button>
              <button onClick={sichern} disabled={speichert || laedtBild}
                className="flex-[2] py-3 bg-blue-600 text-white rounded-xl font-bold shadow-lg disabled:opacity-60 flex items-center justify-center gap-2">
                {speichert && <Loader2 size={16} className="animate-spin" />} {t('admin.news.save')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default NachrichtenVerwaltung;
