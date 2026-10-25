import React, { useCallback, useEffect, useId, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Bell, CalendarDays, CheckCheck, FileText, HandHeart, Megaphone, Newspaper, AlertCircle } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { EASE_OUT } from '../lib/bewegung';

// Das Benachrichtigungscenter: die Glocke in der Leiste.
//
// Angelegt werden Benachrichtigungen nur von der Datenbank (Ausloeser auf
// Spenden, Rechnungen, Veranstaltungen, Neuigkeiten, Spendenaufrufen --
// Migration benachrichtigungen). Hier wird gelesen, live nachgeladen und
// als gelesen markiert.

type Eintrag = {
  id: string; art: string; titel: string; text: string | null;
  link: string | null; erstellt_am: string; gelesen_am: string | null;
};

const SYMBOL: Record<string, React.ReactNode> = {
  SPENDE: <HandHeart size={16} />,
  RECHNUNG: <FileText size={16} />,
  MAHNUNG: <AlertCircle size={16} />,
  VERANSTALTUNG: <CalendarDays size={16} />,
  NEUIGKEIT: <Newspaper size={16} />,
  AUFRUF: <Megaphone size={16} />,
};

const vorWann = (iso: string, sprache: string) => {
  const s = Math.round((new Date(iso).getTime() - Date.now()) / 1000);
  const rtf = new Intl.RelativeTimeFormat(sprache, { numeric: 'auto' });
  const a = Math.abs(s);
  if (a < 60) return rtf.format(0, 'second');
  if (a < 3600) return rtf.format(Math.round(s / 60), 'minute');
  if (a < 86400) return rtf.format(Math.round(s / 3600), 'hour');
  if (a < 86400 * 7) return rtf.format(Math.round(s / 86400), 'day');
  return new Date(iso).toLocaleDateString(sprache === 'sq' ? 'sq-AL' : 'de-CH', { day: '2-digit', month: '2-digit', year: 'numeric' });
};

const Benachrichtigungen: React.FC = () => {
  const { t, language } = useTranslation() as any;
  const navigate = useNavigate();
  const [eintraege, setEintraege] = useState<Eintrag[]>([]);
  const [offen, setOffen] = useState(false);
  const huelle = useRef<HTMLDivElement>(null);
  // Eigener Kanalname je Glocke: im Seitenleisten-Layout haengen zwei
  // (eine per CSS verborgen), und gleichnamige Kanaele raeumten sich ab.
  const kanalId = useId();

  const laden = useCallback(async () => {
    if (!supabase) return;
    const { data, error } = await supabase.from('benachrichtigungen')
      .select('id, art, titel, text, link, erstellt_am, gelesen_am')
      .order('erstellt_am', { ascending: false }).limit(40);
    // Fehlt die Tabelle noch (Migration nicht eingespielt), bleibt die
    // Glocke einfach leer statt die Leiste zu stoeren.
    if (!error) setEintraege((data as Eintrag[]) || []);
  }, []);

  useEffect(() => {
    laden();
    if (!supabase) return;
    // Neue Zeilen live. Die Regel in der Datenbank laesst nur die eigenen
    // durch, ein Filter hier ist nicht noetig.
    const kanal = supabase.channel(`benachrichtigungen-${kanalId}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'benachrichtigungen' },
          (p: any) => setEintraege(e => [p.new as Eintrag, ...e.filter(x => x.id !== p.new.id)].slice(0, 40)))
      .subscribe();
    // Zurueck in den Tab: nachladen, falls Realtime unterwegs abgerissen ist.
    const sichtbar = () => { if (document.visibilityState === 'visible') laden(); };
    document.addEventListener('visibilitychange', sichtbar);
    return () => { supabase.removeChannel(kanal); document.removeEventListener('visibilitychange', sichtbar); };
  }, [laden, kanalId]);

  // Schliessen bei Klick daneben und mit Escape.
  useEffect(() => {
    if (!offen) return;
    const daneben = (e: PointerEvent) => { if (!huelle.current?.contains(e.target as Node)) setOffen(false); };
    const taste = (e: KeyboardEvent) => { if (e.key === 'Escape') setOffen(false); };
    document.addEventListener('pointerdown', daneben);
    document.addEventListener('keydown', taste);
    return () => { document.removeEventListener('pointerdown', daneben); document.removeEventListener('keydown', taste); };
  }, [offen]);

  const ungelesen = eintraege.filter(e => !e.gelesen_am).length;

  const gelesen = async (ids?: string[]) => {
    const jetzt = new Date().toISOString();
    setEintraege(e => e.map(x => (!ids || ids.includes(x.id)) && !x.gelesen_am ? { ...x, gelesen_am: jetzt } : x));
    await supabase?.rpc('benachrichtigungen_gelesen', { p_ids: ids ?? null });
  };

  const oeffnen = (e: Eintrag) => {
    if (!e.gelesen_am) gelesen([e.id]);
    setOffen(false);
    if (e.link) navigate(e.link);
  };

  return (
    <div ref={huelle} className="relative">
      <button onClick={() => setOffen(o => !o)}
              aria-label={ungelesen ? t('benach.oeffnen_n', { n: ungelesen }) : t('benach.titel')}
              aria-expanded={offen}
              className="relative w-10 h-10 rounded-xl flex items-center justify-center text-stone-500 hover:text-stone-900 hover:bg-white/50 transition-colors">
        <Bell size={19} />
        {ungelesen > 0 && (
          <span className="absolute top-1 right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-primary text-white text-[10px] font-bold leading-[18px] text-center tabular-nums">
            {ungelesen > 99 ? '99+' : ungelesen}
          </span>
        )}
      </button>

      <AnimatePresence>
        {offen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.97, y: -4 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, transition: { duration: 0.1 } }}
            transition={{ duration: 0.16, ease: EASE_OUT }}
            style={{ transformOrigin: 'top right' }}
            className="fixed inset-x-3 top-[calc(env(safe-area-inset-top)+5.5rem)] md:absolute md:inset-x-auto md:top-full md:right-0 md:mt-3 md:w-96
                       bg-white/95 backdrop-blur-xl rounded-2xl shadow-2xl border border-stone-100 overflow-hidden z-50 text-stone-900">
            <div className="flex items-center justify-between gap-3 px-4 py-3 border-b border-stone-100">
              <p className="font-bold text-sm">{t('benach.titel')}</p>
              {ungelesen > 0 && (
                <button onClick={() => gelesen()}
                        className="text-[11px] font-bold text-stone-500 hover:text-stone-900 inline-flex items-center gap-1.5">
                  <CheckCheck size={13} /> {t('benach.alle_gelesen')}
                </button>
              )}
            </div>

            <div className="max-h-[min(30rem,calc(100dvh-10rem))] overflow-y-auto overscroll-contain">
              {eintraege.length === 0 ? (
                <div className="px-6 py-12 text-center">
                  <Bell size={22} className="mx-auto mb-3 text-stone-300" />
                  <p className="text-sm text-stone-500">{t('benach.leer')}</p>
                </div>
              ) : eintraege.map(e => (
                <button key={e.id} onClick={() => oeffnen(e)}
                        className={`w-full text-left flex gap-3 px-4 py-3 border-b border-stone-50 last:border-0 transition-colors hover:bg-stone-50
                                    ${e.gelesen_am ? '' : 'bg-[color:color-mix(in_srgb,var(--primary)_5%,transparent)]'}`}>
                  <span className={`mt-0.5 w-8 h-8 shrink-0 rounded-lg flex items-center justify-center
                                    ${e.art === 'MAHNUNG' ? 'bg-amber-50 text-amber-600' : 'bg-stone-100 text-stone-500'}`}>
                    {SYMBOL[e.art] ?? <Bell size={16} />}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="flex items-baseline justify-between gap-2">
                      <span className={`text-sm leading-snug [overflow-wrap:anywhere] ${e.gelesen_am ? 'font-medium text-stone-600' : 'font-bold text-stone-900'}`}>{e.titel}</span>
                      <span className="text-[10px] text-stone-400 shrink-0 tabular-nums">{vorWann(e.erstellt_am, language || 'de')}</span>
                    </span>
                    {e.text && <span className="block text-xs text-stone-500 mt-0.5 leading-relaxed [overflow-wrap:anywhere]">{e.text}</span>}
                  </span>
                  {!e.gelesen_am && <span className="mt-2 w-2 h-2 shrink-0 rounded-full bg-primary" aria-hidden />}
                </button>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Benachrichtigungen;
