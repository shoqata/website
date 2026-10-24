import React, { useEffect, useState } from 'react';
import { Download, Mail, Loader2, X, Send, CheckCircle2 } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { protokollPdf, protokollKurztext } from '../lib/protokollPdf';
import { alsHtml } from '../lib/textbaustein';
import type { UserProfile } from '../types';

// PDF, WhatsApp, E-Mail -- die drei Wege, ein Protokoll weiterzugeben.
//
// WhatsApp: wo das Geraet Dateien teilen kann (Handy), geht das PDF selbst
// hinaus -- man waehlt im Teilen-Menue WhatsApp. Am Rechner kann der Browser
// keine Datei an WhatsApp geben; dann wird das PDF heruntergeladen und
// WhatsApp mit einer Kurzfassung geoeffnet, das PDF haengt man selbst an.
// Bewusst KEIN oeffentlicher Link auf das PDF: ein Link laesst sich
// weiterleiten, und ein Vorstandsprotokoll gehoert nicht ins Netz.
//
// E-Mail: ueber den Postausgang des Vorstands, mit dem PDF im Anhang.

const WaSymbol = () => (
  <svg viewBox="0 0 24 24" width="15" height="15" fill="currentColor" aria-hidden="true">
    <path d="M17.5 14.4c-.3-.1-1.7-.8-2-.9-.3-.1-.5-.1-.7.1-.2.3-.8.9-.9 1.1-.2.2-.3.2-.6.1-.3-.1-1.2-.5-2.3-1.4-.9-.8-1.4-1.7-1.6-2-.2-.3 0-.5.1-.6l.4-.5c.1-.2.2-.3.3-.5.1-.2 0-.4 0-.5l-.9-2.2c-.2-.6-.5-.5-.7-.5h-.6c-.2 0-.5.1-.8.4-.3.3-1 1-1 2.4s1 2.8 1.2 3c.1.2 2 3.1 4.9 4.3.7.3 1.2.5 1.6.6.7.2 1.3.2 1.8.1.6-.1 1.7-.7 1.9-1.4.2-.7.2-1.2.2-1.4-.1-.1-.3-.2-.6-.3zM12 21.8c-1.8 0-3.5-.5-5-1.4l-.4-.2-3.7 1 1-3.6-.2-.4C2.7 15.6 2.2 13.8 2.2 12 2.2 6.6 6.6 2.2 12 2.2S21.8 6.6 21.8 12 17.4 21.8 12 21.8zM12 0C5.4 0 0 5.4 0 12c0 2.1.6 4.2 1.6 6L0 24l6.2-1.6c1.8 1 3.8 1.5 5.8 1.5 6.6 0 12-5.4 12-12S18.6 0 12 0z"/>
  </svg>
);

const ProtokollTeilen: React.FC<{ meeting: any; boardUsers: UserProfile[] }> = ({ meeting, boardUsers }) => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [laeuft, setLaeuft] = useState<'' | 'PDF' | 'WA'>('');
  const [mailOffen, setMailOffen] = useState(false);

  const herunterladen = (blob: Blob, name: string) => {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = name; document.body.appendChild(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 5000);
  };

  const pdf = async () => {
    setLaeuft('PDF');
    try { const p = await protokollPdf(meeting, t); herunterladen(p.blob, p.dateiname); }
    catch (e: any) { showAlert({ type: 'error', message: t('minutes.pdf_failed', { reason: e?.message || '?' }) }); }
    finally { setLaeuft(''); }
  };

  const whatsapp = async () => {
    setLaeuft('WA');
    try {
      const p = await protokollPdf(meeting, t);
      const datei = new File([p.blob], p.dateiname, { type: 'application/pdf' });
      const nav: any = navigator;
      if (nav.canShare?.({ files: [datei] })) {
        await nav.share({ files: [datei], title: meeting.title, text: meeting.title });
      } else {
        herunterladen(p.blob, p.dateiname);
        window.open(`https://wa.me/?text=${encodeURIComponent(protokollKurztext(meeting, t) + '\n\n' + t('minutes.wa_attach'))}`, '_blank', 'noopener');
      }
    } catch (e: any) {
      // Abbrechen im Teilen-Menue ist kein Fehler.
      if (e?.name !== 'AbortError') showAlert({ type: 'error', message: e?.message || t('common.error') });
    } finally { setLaeuft(''); }
  };

  const knopf = 'px-3.5 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 disabled:opacity-50 transition-colors';
  return (
    <>
      <div className="flex flex-wrap gap-2">
        <button onClick={pdf} disabled={!!laeuft} className={`${knopf} bg-white border border-stone-200 text-stone-700 hover:border-stone-400`}>
          {laeuft === 'PDF' ? <Loader2 size={14} className="animate-spin" /> : <Download size={14} />} PDF
        </button>
        <button onClick={whatsapp} disabled={!!laeuft} className={`${knopf} bg-[#25D366] text-white hover:bg-[#1ebe5b]`}>
          {laeuft === 'WA' ? <Loader2 size={14} className="animate-spin" /> : <WaSymbol />} WhatsApp
        </button>
        <button onClick={() => setMailOffen(true)} disabled={!!laeuft} className={`${knopf} bg-stone-900 text-white hover:bg-stone-700`}>
          <Mail size={14} /> {t('field.email')}
        </button>
      </div>
      {mailOffen && <MailDialog meeting={meeting} boardUsers={boardUsers} onClose={() => setMailOffen(false)} />}
    </>
  );
};

const MailDialog: React.FC<{ meeting: any; boardUsers: UserProfile[]; onClose: () => void }> = ({ meeting, boardUsers, onClose }) => {
  const { t } = useTranslation();
  const [gaeste, setGaeste] = useState<{ id: string; vorname: string; nachname: string; email: string | null }[]>([]);
  const [gewaehlt, setGewaehlt] = useState<Set<string>>(new Set());
  const [weitere, setWeitere] = useState('');
  const [betreff, setBetreff] = useState(`${t('minutes.heading')}: ${meeting.title} – ${meeting.date ? new Date(meeting.date).toLocaleDateString('de-CH') : ''}`);
  const [text, setText] = useState(t('minutes.mail_text'));
  const [sendet, setSendet] = useState(false);
  const [fehler, setFehler] = useState('');
  const [fertig, setFertig] = useState<number | null>(null);

  // Vorschlag: wer anwesend war, und die Gaeste.
  const vorstand = boardUsers.filter(u => (u.email || '').includes('@'));
  useEffect(() => {
    const anwesend = new Set((meeting.attendees || []).filter((a: any) => a.present && a.userId).map((a: any) => a.userId));
    const start = new Set<string>(vorstand.filter(u => anwesend.has(u.id)).map(u => String(u.email).toLowerCase()));
    supabase.from('board_meeting_guests').select('id,vorname,nachname,email').eq('meetingId', meeting.id)
      .then(({ data }) => {
        const g = ((data as any[]) || []);
        setGaeste(g);
        g.filter(x => x.email).forEach(x => start.add(String(x.email).toLowerCase()));
        setGewaehlt(new Set(start));
      });
  }, [meeting.id]);

  const umschalten = (mail: string) => {
    const n = new Set(gewaehlt); const k = mail.toLowerCase();
    n.has(k) ? n.delete(k) : n.add(k); setGewaehlt(n);
  };
  const zusatz = weitere.split(/[\s,;]+/).map(s => s.trim().toLowerCase()).filter(Boolean);
  const alle = [...new Set([...gewaehlt, ...zusatz])];

  const senden = async () => {
    setSendet(true); setFehler('');
    try {
      const p = await protokollPdf(meeting, t);
      const { data, error } = await supabase.rpc('protokoll_mail_einreihen', {
        p_meeting: meeting.id, p_an: alle, p_betreff: betreff, p_html: alsHtml(text),
        p_pdf: p.base64, p_dateiname: p.dateiname,
      });
      if (error) throw error;
      setFertig((data as any)?.eingereiht ?? alle.length);
    } catch (e: any) { setFehler(e?.message || '?'); }
    finally { setSendet(false); }
  };

  const zeile = (key: string, name: string, mail: string, zusatzText?: string) => (
    <label key={key} className="flex items-center gap-3 px-4 py-2 hover:bg-stone-50 cursor-pointer">
      <input type="checkbox" checked={gewaehlt.has(mail.toLowerCase())} onChange={() => umschalten(mail)} className="accent-primary" />
      <span className="text-sm flex-1 truncate">{name}{zusatzText && <span className="text-[10px] font-bold text-violet-600 ml-2">{zusatzText}</span>}</span>
      <span className="text-xs text-stone-400 truncate max-w-[12rem]">{mail}</span>
    </label>
  );

  return (
    <div className="fixed inset-0 z-[450] flex items-end sm:items-center justify-center sm:p-6 bg-stone-900/60 backdrop-blur-sm" onClick={onClose}>
      <div onClick={e => e.stopPropagation()} className="bg-white w-full sm:max-w-lg rounded-t-[2rem] sm:rounded-[2rem] shadow-2xl p-6 space-y-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-start justify-between">
          <h3 className="font-bold text-lg text-stone-900 flex items-center gap-2"><Mail size={18} /> {t('minutes.send_mail')}</h3>
          <button onClick={onClose} className="p-2 rounded-full hover:bg-stone-100"><X size={18} /></button>
        </div>
        {fertig !== null ? (
          <div className="py-6 text-center space-y-3">
            <CheckCircle2 className="mx-auto text-emerald-600" size={36} />
            <p className="font-bold text-stone-900">{t('minutes.mail_done', { count: fertig })}</p>
            <button onClick={onClose} className="px-6 py-2.5 rounded-xl bg-stone-900 text-white text-sm font-bold">OK</button>
          </div>
        ) : (
          <>
            <div className="border border-stone-200 rounded-xl divide-y divide-stone-50 max-h-56 overflow-y-auto">
              {vorstand.map(u => zeile(u.id, u.displayName || '', String(u.email)))}
              {gaeste.filter(g => g.email).map(g => zeile(g.id, `${g.vorname} ${g.nachname}`.trim(), String(g.email), t('minutes.guest')))}
            </div>
            <input value={weitere} onChange={e => setWeitere(e.target.value)} placeholder={t('minutes.more_addresses')}
              className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm" />
            <input value={betreff} onChange={e => setBetreff(e.target.value)} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm font-bold" />
            <textarea value={text} onChange={e => setText(e.target.value)} rows={4} className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-sm" />
            <p className="text-[11px] text-stone-400">{t('minutes.mail_hint')}</p>
            {fehler && <p className="text-sm text-rose-700">{fehler}</p>}
            <div className="flex justify-end gap-2">
              <button onClick={onClose} className="px-5 py-3 rounded-xl text-sm font-bold text-stone-500 hover:bg-stone-100">{t('common.cancel')}</button>
              <button onClick={senden} disabled={sendet || alle.length === 0 || !betreff.trim()}
                className="px-6 py-3 rounded-xl bg-primary text-white text-sm font-bold flex items-center gap-2 disabled:opacity-40">
                {sendet ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />} {t('minutes.send_to', { count: alle.length })}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default ProtokollTeilen;
