import React, { useEffect, useRef, useState } from 'react';
import { Film, Plus, Trash2, Eye, EyeOff, Loader2, Save, Upload, Pencil, X, ArrowUp, ArrowDown } from 'lucide-react';
import { supabase, resolveTenantId } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { onImageError } from '../lib/imageFallback';

type Video = {
  id: string; titel: string; beschreibung: string | null;
  quelle: string; vorschaubild: string | null; dauer_s: number | null;
  status: 'ENTWURF' | 'OEFFENTLICH'; reihenfolge: number;
};

const LEER = { titel: '', beschreibung: '', quelle: '', vorschaubild: '', dauer_s: null as number | null };

// Die Videoseite des Vereins.
//
// Die Filme entstehen nicht hier -- geschnitten wird ausserhalb, mit einem
// Werkzeug wie hyperframes-student-kit, das Node, FFmpeg und Chrome braucht.
// Was hier passiert: hochladen, beschreiben, ordnen, freigeben.
//
// Die erste Fassung dieser Maske nahm nur eine fertige Adresse entgegen und
// liess nichts mehr aendern. Beides war eine Sackgasse: eine Vereinsleitung
// hat keine Adresse einer Videodatei, sie hat eine Datei -- und ein Tippfehler
// im Titel war nicht mehr zu beheben.
const AdminVideos: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();

  const [videos, setVideos] = useState<Video[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [verein, setVerein] = useState<string | null>(null);
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [laedtHoch, setLaedtHoch] = useState<string | null>(null);

  // Ein Formular fuer beides: neu und bearbeiten. Zwei fast gleiche Masken
  // laufen auseinander, sobald jemand nur eine davon anfasst.
  const [form, setForm] = useState<typeof LEER>({ ...LEER });
  const [bearbeitet, setBearbeitet] = useState<string | null>(null);
  const dateiRef = useRef<HTMLInputElement>(null);

  const laden = async () => {
    const { data, error } = await supabase.from('videos').select('*')
      .order('reihenfolge').order('erstellt_am', { ascending: false });
    if (!error) setVideos((data as Video[]) || []);
    setLaedt(false);
  };
  useEffect(() => {
    laden();
    resolveTenantId().then(id => setVerein(id ?? null)).catch(() => setVerein(null));
  }, []);

  // --- Hochladen --------------------------------------------------------
  // Aus der Datei wird gleich mitgelesen, was sich mitlesen laesst: die
  // Laufzeit und ein Vorschaubild. Wer beides von Hand nachtragen muesste,
  // laesst es weg, und dann steht auf der Website ein schwarzes Rechteck.
  const vorschauAusVideo = (datei: File): Promise<{ bild: Blob | null; dauer: number | null }> =>
    new Promise((fertig) => {
      const v = document.createElement('video');
      v.preload = 'metadata'; v.muted = true; v.playsInline = true;
      v.src = URL.createObjectURL(datei);
      const aufgeben = () => { URL.revokeObjectURL(v.src); fertig({ bild: null, dauer: null }); };
      v.onerror = aufgeben;
      v.onloadedmetadata = () => {
        const dauer = Number.isFinite(v.duration) ? Math.round(v.duration) : null;
        // Nicht das allererste Bild: das ist bei einer Ueberblendung oft
        // schwarz. Ein Stueck hinein ist fast immer aussagekraeftig.
        v.currentTime = Math.min(Math.max((v.duration || 0) * 0.15, 0.5), 5);
        v.onseeked = () => {
          try {
            const c = document.createElement('canvas');
            const breite = Math.min(v.videoWidth || 1280, 1280);
            c.width = breite;
            c.height = Math.round(breite * ((v.videoHeight || 720) / (v.videoWidth || 1280)));
            c.getContext('2d')!.drawImage(v, 0, 0, c.width, c.height);
            c.toBlob((b) => { URL.revokeObjectURL(v.src); fertig({ bild: b, dauer }); }, 'image/jpeg', 0.85);
          } catch { URL.revokeObjectURL(v.src); fertig({ bild: null, dauer }); }
        };
      };
    });

  const hochladen = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const datei = e.target.files?.[0];
    e.target.value = '';
    if (!datei) return;
    if (!verein) { showAlert({ type: 'error', message: t('video.kein_verein') }); return; }
    // 50 MB, nicht 300. Gemessen am 28.09.2026: 44 MB gehen durch, 57 MB
    // werden mit 413 abgewiesen. Die Grenze kommt aus den
    // Projekteinstellungen von Supabase, nicht aus der Ablage -- eine
    // Ablage kann die globale Vorgabe nicht ueberschreiten. Hier zu pruefen
    // erspart dem Verein einen langen Upload, der am Ende abbricht.
    if (datei.size > 50 * 1024 * 1024) {
      showAlert({ type: 'error', message: t('video.zu_gross') });
      return;
    }

    setLaedtHoch('video');
    try {
      const stamm = `${verein}/${Date.now()}-${datei.name.replace(/[^A-Za-z0-9._-]/g, '_')}`;
      const { error } = await supabase.storage.from('videos')
        .upload(stamm, datei, { upsert: true, contentType: datei.type || 'video/mp4' });
      if (error) throw error;
      const { data } = supabase.storage.from('videos').getPublicUrl(stamm);

      setLaedtHoch('vorschau');
      const { bild, dauer } = await vorschauAusVideo(datei);
      let bildAdresse = '';
      if (bild) {
        const bildPfad = stamm.replace(/\.[^.]+$/, '') + '.jpg';
        const { error: f2 } = await supabase.storage.from('videos')
          .upload(bildPfad, bild, { upsert: true, contentType: 'image/jpeg' });
        if (!f2) bildAdresse = supabase.storage.from('videos').getPublicUrl(bildPfad).data.publicUrl;
      }

      setForm(f => ({
        ...f,
        quelle: data.publicUrl,
        vorschaubild: bildAdresse || f.vorschaubild,
        dauer_s: dauer ?? f.dauer_s,
        titel: f.titel || datei.name.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' '),
      }));
      showAlert({ type: 'success', message: t('video.hochgeladen') });
    } catch (err: any) {
      showAlert({ type: 'error', message: err?.message || t('video.upload_fehler') });
    } finally {
      setLaedtHoch(null);
    }
  };

  // --- Anlegen und Aendern ---------------------------------------------
  const sichern = async () => {
    if (!form.titel.trim() || !form.quelle.trim()) {
      showAlert({ type: 'warning', message: t('video.fehlt') });
      return;
    }
    setArbeitet(bearbeitet || 'neu');
    const inhalt = {
      titel: form.titel.trim(),
      beschreibung: form.beschreibung?.trim() || null,
      quelle: form.quelle.trim(),
      vorschaubild: form.vorschaubild?.trim() || null,
      dauer_s: form.dauer_s,
    };
    const { error } = bearbeitet
      ? await supabase.from('videos').update(inhalt).eq('id', bearbeitet)
      : await supabase.from('videos').insert([{ ...inhalt, status: 'ENTWURF' }]);
    setArbeitet(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    abbrechen();
    laden();
  };

  const bearbeiten = (v: Video) => {
    setBearbeitet(v.id);
    setForm({
      titel: v.titel, beschreibung: v.beschreibung || '', quelle: v.quelle,
      vorschaubild: v.vorschaubild || '', dauer_s: v.dauer_s,
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };
  const abbrechen = () => { setBearbeitet(null); setForm({ ...LEER }); };

  const umschalten = async (v: Video) => {
    setArbeitet(v.id);
    const { error } = await supabase.from('videos')
      .update({ status: v.status === 'OEFFENTLICH' ? 'ENTWURF' : 'OEFFENTLICH' }).eq('id', v.id);
    setArbeitet(null);
    if (error) { showAlert({ type: 'error', message: error.message }); return; }
    laden();
  };

  // Reihenfolge: zwei Nachbarn tauschen ihre Zahl. Das ist die einfachste
  // Fassung, die auch dann stimmt, wenn zwei Zeilen dieselbe Zahl tragen.
  const schieben = async (v: Video, richtung: -1 | 1) => {
    const i = videos.findIndex(x => x.id === v.id);
    const j = i + richtung;
    if (j < 0 || j >= videos.length) return;
    setArbeitet(v.id);
    const a = videos[i], b = videos[j];
    await supabase.from('videos').update({ reihenfolge: b.reihenfolge }).eq('id', a.id);
    await supabase.from('videos').update({ reihenfolge: a.reihenfolge }).eq('id', b.id);
    setArbeitet(null);
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
    if (bearbeitet === v.id) abbrechen();
    laden();
  };

  const feld = 'w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]';
  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';
  const dauerText = (s: number | null) => s == null ? '' : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

  return (
    <div className="max-w-5xl mx-auto space-y-8 p-2">
      <div className="flex items-center gap-3">
        <div className="bg-stone-100 text-stone-500 p-3 rounded-2xl"><Film size={22} /></div>
        <div>
          <h2 className="text-xl font-bold text-stone-900">{t('video.titel')}</h2>
          <p className="text-xs text-stone-400">{t('video.untertitel')}</p>
        </div>
      </div>

      <div className={`bg-white p-8 rounded-[2rem] border shadow-sm space-y-5 ${
        bearbeitet ? 'border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]' : 'border-stone-100'}`}>
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-stone-900 text-sm flex items-center gap-2">
            {bearbeitet ? <Pencil size={16} className="text-primary" /> : <Plus size={16} className="text-stone-400" />}
            {bearbeitet ? t('video.bearbeiten') : t('video.neu')}
          </h3>
          {bearbeitet && (
            <button onClick={abbrechen} className="text-xs font-bold text-stone-400 hover:text-stone-600 flex items-center gap-1">
              <X size={13} /> {t('common.cancel')}
            </button>
          )}
        </div>

        {/* Datei statt Adresse. Wer eine Adresse hat, kann sie weiter unten
            trotzdem eintragen -- etwa fuer ein Video, das anderswo liegt. */}
        <div className="flex flex-wrap items-center gap-3">
          <input ref={dateiRef} type="file" hidden accept="video/mp4,video/webm,video/quicktime" onChange={hochladen} />
          <button onClick={() => dateiRef.current?.click()} disabled={!!laedtHoch}
            className="bg-stone-900 text-white px-6 py-3 rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-black transition-colors disabled:opacity-50">
            {laedtHoch ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
            {laedtHoch === 'video' ? t('video.laedt_hoch')
              : laedtHoch === 'vorschau' ? t('video.macht_vorschau')
              : t('video.datei_waehlen')}
          </button>
          <span className="text-[11px] text-stone-400">{t('video.grenze')}</span>
        </div>

        {form.vorschaubild && (
          <div className="flex items-center gap-4 p-3 bg-stone-50 rounded-2xl border border-stone-100">
            <img src={form.vorschaubild} alt="" onError={onImageError}
                 className="w-28 h-16 object-cover rounded-lg border border-stone-200" />
            <p className="text-[11px] text-stone-500 leading-relaxed">
              {t('video.vorschau_erzeugt')}{form.dauer_s ? ` · ${dauerText(form.dauer_s)}` : ''}
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className={marke}>{t('field.name')}</label>
            <input value={form.titel} onChange={e => setForm({ ...form, titel: e.target.value })}
              className={feld} placeholder={t('video.titel_beispiel')} />
          </div>
          <div>
            <label className={marke}>{t('video.quelle')}</label>
            <input value={form.quelle} onChange={e => setForm({ ...form, quelle: e.target.value })}
              className={feld + ' font-mono text-xs'} placeholder="https://…/film.mp4" />
          </div>
        </div>
        <div>
          <label className={marke}>{t('video.beschreibung')}</label>
          <textarea value={form.beschreibung} onChange={e => setForm({ ...form, beschreibung: e.target.value })}
            rows={2} className={feld} />
        </div>

        <button onClick={sichern} disabled={!!arbeitet || !!laedtHoch}
          className="bg-primary text-white px-7 py-3 rounded-xl text-xs font-bold flex items-center gap-2 hover:opacity-90 transition-opacity disabled:opacity-50">
          {arbeitet ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
          {bearbeitet ? t('common.save_changes') : t('video.anlegen')}
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
          {videos.map((v, i) => (
            <div key={v.id} className={`bg-white p-4 rounded-2xl border shadow-sm flex items-center gap-4 ${
              bearbeitet === v.id ? 'border-[color:color-mix(in_srgb,var(--primary)_40%,transparent)]' : 'border-stone-100'}`}>
              <div className="w-24 h-14 rounded-lg bg-stone-900 shrink-0 overflow-hidden border border-stone-200">
                {v.vorschaubild
                  ? <img src={v.vorschaubild} alt="" onError={onImageError} className="w-full h-full object-cover" />
                  : <div className="w-full h-full flex items-center justify-center"><Film size={16} className="text-stone-600" /></div>}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-0.5 flex-wrap">
                  <p className="font-bold text-stone-900 text-sm truncate">{v.titel}</p>
                  <span className={`text-[9px] font-bold uppercase tracking-widest px-2 py-0.5 rounded ${
                    v.status === 'OEFFENTLICH' ? 'bg-emerald-50 text-emerald-600' : 'bg-stone-100 text-stone-500'}`}>
                    {v.status === 'OEFFENTLICH' ? t('video.oeffentlich') : t('video.entwurf')}
                  </span>
                  {v.dauer_s != null && <span className="text-[10px] text-stone-400 font-mono">{dauerText(v.dauer_s)}</span>}
                </div>
                {v.beschreibung && <p className="text-xs text-stone-500 leading-relaxed line-clamp-1">{v.beschreibung}</p>}
              </div>

              <div className="flex gap-1.5 shrink-0">
                <div className="flex flex-col">
                  <button onClick={() => schieben(v, -1)} disabled={i === 0 || !!arbeitet}
                    className="px-1.5 text-stone-300 hover:text-stone-600 disabled:opacity-30" title={t('video.hoch')}>
                    <ArrowUp size={13} />
                  </button>
                  <button onClick={() => schieben(v, 1)} disabled={i === videos.length - 1 || !!arbeitet}
                    className="px-1.5 text-stone-300 hover:text-stone-600 disabled:opacity-30" title={t('video.runter')}>
                    <ArrowDown size={13} />
                  </button>
                </div>
                <button onClick={() => bearbeiten(v)} title={t('video.bearbeiten')}
                  className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 transition-colors">
                  <Pencil size={15} />
                </button>
                <button onClick={() => umschalten(v)} disabled={arbeitet === v.id}
                  title={v.status === 'OEFFENTLICH' ? t('video.verbergen') : t('video.zeigen')}
                  className="p-2.5 rounded-xl border border-stone-200 text-stone-500 hover:border-stone-300 transition-colors disabled:opacity-40">
                  {arbeitet === v.id ? <Loader2 size={15} className="animate-spin" />
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

      {/* Wo der Schnitt herkommt. Ein Verein, der hier steht und nicht weiss,
          wie ein Film entsteht, soll wenigstens lesen, dass er nicht hier
          entsteht. */}
      <p className="text-[11px] text-stone-400 leading-relaxed max-w-2xl pt-2">
        {t('video.schnitt_hinweis')}
      </p>
    </div>
  );
};

export default AdminVideos;
