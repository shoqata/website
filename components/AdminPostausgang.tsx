import React, { useEffect, useState } from 'react';
import { Mail, Eye, EyeOff, Check, AlertTriangle, Loader2, Send } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { flushMailQueue } from '../services/mailService';
import { useTranslation } from '../context/LanguageContext';

// Der Postausgang des Vereins.
//
// An dieser Stelle stand bis jetzt ein Hinweis aus der Firebase-Zeit: der
// Versand laufe ueber die Erweiterung "Trigger Email", einzustellen in der
// Firebase-Konsole. Beides trifft seit der Umstellung auf Supabase nicht mehr
// zu -- und einstellen liess sich hier gar nichts.
//
// Das Kennwort kommt nie zurueck. Gelesen wird ueber
// mail_einstellungen_lesen(), das nur meldet, OB eines hinterlegt ist. Ein
// leer abgeschicktes Kennwortfeld laesst das gespeicherte deshalb unberuehrt
// -- sonst wuerde jedes Speichern der uebrigen Felder den Versand stilllegen.

type Stand = {
  host: string; port: number; benutzer: string; absender: string;
  absendername: string; tls: string; aktiv: boolean;
  kennwort_gesetzt: boolean; geaendert_am?: string; geaendert_von?: string;
};

const LEER: Stand = {
  host: '', port: 587, benutzer: '', absender: '', absendername: '',
  tls: 'starttls', aktiv: true, kennwort_gesetzt: false,
};

const AdminPostausgang: React.FC = () => {
  const { t } = useTranslation();
  const [stand, setStand] = useState<Stand>(LEER);
  const [kennwort, setKennwort] = useState('');
  const [zeigeKennwort, setZeigeKennwort] = useState(false);
  const [laedt, setLaedt] = useState(true);
  const [speichert, setSpeichert] = useState(false);
  const [probe, setProbe] = useState<string | null>(null);
  const [meldung, setMeldung] = useState<{ art: 'gut' | 'schlecht'; text: string } | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      try {
        const { data, error } = await supabase.rpc('mail_einstellungen_lesen');
        if (!lebt) return;
        if (error) throw error;
        const z = Array.isArray(data) ? data[0] : data;
        if (z) setStand({ ...LEER, ...z, port: z.port ?? 587 });
      } catch (e: any) {
        if (lebt) setMeldung({ art: 'schlecht', text: e?.message ?? String(e) });
      } finally {
        if (lebt) setLaedt(false);
      }
    })();
    return () => { lebt = false; };
  }, []);

  const speichern = async () => {
    setSpeichert(true); setMeldung(null);
    try {
      const { error } = await supabase.rpc('mail_einstellungen_speichern', {
        p_host: stand.host, p_port: Number(stand.port) || 587,
        p_benutzer: stand.benutzer, p_absender: stand.absender,
        p_absendername: stand.absendername, p_tls: stand.tls,
        p_aktiv: stand.aktiv,
        // Leer heisst "unveraendert", nicht "loeschen".
        p_kennwort: kennwort.trim() === '' ? null : kennwort,
      });
      if (error) throw error;
      if (kennwort.trim() !== '') setStand((s) => ({ ...s, kennwort_gesetzt: true }));
      setKennwort('');
      setMeldung({ art: 'gut', text: t('post.gespeichert') });
    } catch (e: any) {
      setMeldung({ art: 'schlecht', text: e?.message ?? String(e) });
    } finally {
      setSpeichert(false);
    }
  };

  // Die Warteschlange einmal abarbeiten lassen. Das ist der ehrlichste Test:
  // er benutzt genau den Weg, den auch der Zeitplan nimmt.
  const ausprobieren = async () => {
    setProbe('laeuft'); setMeldung(null);
    try {
      const r = await flushMailQueue();
      if (!r.configured) {
        setMeldung({ art: 'schlecht', text: r.hinweis ?? t('post.nicht_eingerichtet') });
      } else {
        setMeldung({ art: 'gut', text: t('post.probe_ergebnis')
          .replace('{gesendet}', String(r.sent ?? 0))
          .replace('{gescheitert}', String(r.failed ?? 0)) });
      }
    } catch (e: any) {
      setMeldung({ art: 'schlecht', text: e?.message ?? String(e) });
    } finally {
      setProbe(null);
    }
  };

  // Verschluesselung und Port gehoeren zusammen. Wer STARTTLS waehlt, meint
  // 587; wer TLS waehlt, meint 465. Beides getrennt einzutragen fuehrt zu
  // Kombinationen, die es nicht gibt -- etwa STARTTLS auf Port 25.
  const PORT_ZU = { starttls: 587, tls: 465, keine: 25 } as const;

  const verschluesselungWechseln = (neuTls: string) => {
    const bisherStandard = Object.values(PORT_ZU).includes(stand.port as any);
    setStand({
      ...stand,
      tls: neuTls,
      // Einen selbst gewaehlten, ungewoehnlichen Port nicht ueberschreiben.
      port: bisherStandard ? PORT_ZU[neuTls as keyof typeof PORT_ZU] : stand.port,
    });
  };

  // Port 25 ist der Weg zwischen Mailservern, nicht der zum Einliefern. Er
  // kennt keine Verschluesselung -- Benutzername und Kennwort gingen im
  // Klartext ueber die Leitung.
  const unsicher = stand.tls === 'keine' || stand.port === 25;

  const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl text-sm text-stone-700 outline-none focus:border-primary/50';
  const schild = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 block';

  if (laedt) {
    return (
      <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
        <Loader2 className="animate-spin" size={18} /> <span className="text-sm">{t('post.laedt')}</span>
      </div>
    );
  }

  const unvollstaendig = !stand.host || !stand.benutzer || !stand.absender || !stand.kennwort_gesetzt;

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <p className="font-bold text-stone-700 text-sm">{t('post.titel')}</p>
          <p className="text-xs text-stone-400 mt-1 max-w-xl">{t('post.erklaerung')}</p>
        </div>
        <label className="flex items-center gap-2 text-xs font-bold text-stone-500 shrink-0">
          <input type="checkbox" checked={stand.aktiv}
                 onChange={(e) => setStand({ ...stand, aktiv: e.target.checked })}
                 className="w-4 h-4 accent-current" style={{ accentColor: 'var(--primary)' }} />
          {t('post.aktiv')}
        </label>
      </div>

      {unsicher && (
        <div className="flex gap-3 items-start p-4 bg-rose-50 rounded-2xl border border-rose-100">
          <AlertTriangle className="text-rose-500 shrink-0 mt-0.5" size={18} />
          <div className="text-xs text-rose-700 leading-relaxed">
            <p className="font-bold mb-1">{t('post.unsicher_titel')}</p>
            <p>{t('post.unsicher')}</p>
            <button type="button" onClick={() => verschluesselungWechseln('starttls')}
                    className="mt-2 underline font-bold hover:no-underline">
              {t('post.unsicher_beheben')}
            </button>
          </div>
        </div>
      )}

      {unvollstaendig && (
        <div className="flex gap-3 items-start p-4 bg-amber-50 rounded-2xl border border-amber-100">
          <AlertTriangle className="text-amber-500 shrink-0 mt-0.5" size={18} />
          <p className="text-xs text-amber-700 leading-relaxed">{t('post.unvollstaendig')}</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="md:col-span-2">
          <label className={schild}>{t('post.host')}</label>
          <input value={stand.host} onChange={(e) => setStand({ ...stand, host: e.target.value })}
                 placeholder="mail.example.ch" className={feld} />
        </div>
        <div>
          <label className={schild}>{t('post.port')}</label>
          <input type="number" value={stand.port}
                 onChange={(e) => setStand({ ...stand, port: Number(e.target.value) })}
                 className={feld} />
          <p className="text-[11px] text-stone-400 mt-1.5">{t('post.port_hinweis')}</p>
        </div>

        <div>
          <label className={schild}>{t('post.benutzer')}</label>
          <input value={stand.benutzer} onChange={(e) => setStand({ ...stand, benutzer: e.target.value })}
                 autoComplete="off" className={feld} />
        </div>
        <div>
          <label className={schild}>
            {t('post.kennwort')}
            {stand.kennwort_gesetzt && (
              <span className="ml-2 normal-case tracking-normal text-emerald-600 font-bold">
                {t('post.kennwort_liegt_vor')}
              </span>
            )}
          </label>
          <div className="relative">
            <input type={zeigeKennwort ? 'text' : 'password'} value={kennwort}
                   onChange={(e) => setKennwort(e.target.value)} autoComplete="new-password"
                   placeholder={stand.kennwort_gesetzt ? t('post.kennwort_platzhalter') : ''}
                   className={feld + ' pr-11'} />
            <button type="button" onClick={() => setZeigeKennwort((z) => !z)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-300 hover:text-stone-500"
                    aria-label={t('post.kennwort')}>
              {zeigeKennwort ? <EyeOff size={16} /> : <Eye size={16} />}
            </button>
          </div>
        </div>
        <div>
          <label className={schild}>{t('post.tls')}</label>
          <select value={stand.tls} onChange={(e) => verschluesselungWechseln(e.target.value)}
                  className={feld}>
            <option value="starttls">STARTTLS (587)</option>
            <option value="tls">TLS / SSL (465)</option>
            <option value="keine">{t('post.tls_keine')}</option>
          </select>
        </div>

        <div>
          <label className={schild}>{t('post.absender')}</label>
          <input type="email" value={stand.absender}
                 onChange={(e) => setStand({ ...stand, absender: e.target.value })}
                 placeholder="info@example.ch" className={feld} />
        </div>
        <div className="md:col-span-2">
          <label className={schild}>{t('post.absendername')}</label>
          <input value={stand.absendername}
                 onChange={(e) => setStand({ ...stand, absendername: e.target.value })}
                 placeholder="Shoqata Humanitare Koretini" className={feld} />
        </div>
      </div>

      {meldung && (
        <div className={`flex gap-3 items-start p-4 rounded-2xl border text-xs leading-relaxed ${
          meldung.art === 'gut'
            ? 'bg-emerald-50 border-emerald-100 text-emerald-700'
            : 'bg-rose-50 border-rose-100 text-rose-700'}`}>
          {meldung.art === 'gut' ? <Check size={16} className="shrink-0 mt-0.5" />
                                 : <AlertTriangle size={16} className="shrink-0 mt-0.5" />}
          <span>{meldung.text}</span>
        </div>
      )}

      <div className="flex items-center gap-3 flex-wrap">
        <button onClick={speichern} disabled={speichert}
                className="knopf-primaer px-6 py-3 text-white rounded-xl text-xs font-bold flex items-center gap-2 disabled:opacity-50">
          {speichert ? <Loader2 className="animate-spin" size={14} /> : <Mail size={14} />}
          {t('post.speichern')}
        </button>
        <button onClick={ausprobieren} disabled={!!probe || unvollstaendig}
                className="px-6 py-3 bg-white border border-stone-200 text-stone-600 rounded-xl text-xs font-bold flex items-center gap-2 hover:bg-stone-50 disabled:opacity-40">
          {probe ? <Loader2 className="animate-spin" size={14} /> : <Send size={14} />}
          {t('post.ausprobieren')}
        </button>
        {stand.geaendert_am && (
          <span className="text-[11px] text-stone-400">
            {t('post.zuletzt')
              .replace('{datum}', new Date(stand.geaendert_am).toLocaleString('de-CH'))
              .replace('{wer}', stand.geaendert_von || '—')}
          </span>
        )}
      </div>
    </div>
  );
};

export default AdminPostausgang;
