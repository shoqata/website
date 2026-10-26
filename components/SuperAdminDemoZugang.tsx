import React, { useCallback, useEffect, useState } from 'react';
import { KeyRound, Loader2, Copy, Check, CalendarPlus, Ban, RefreshCw, Trash2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';

// Testzugang eines Interessenten im Demoverein.
//
// Anlegen, verlaengern, sperren und entfernen entscheidet die Datenbank
// (demo_zugang_*), und nur fuer den Betreiber. Das Passwort kommt genau
// einmal zurueck und wird hier angezeigt, bis der Dialog zugeht -- gespeichert
// wird es nirgends. Verschickt wird es vom Betreiber selbst.

type Zugang = {
  id: string;
  lead_id: string | null;
  email: string;
  name: string | null;
  gueltig_bis: string;
  gesperrt_am: string | null;
  aktiv: boolean;
  zuletzt_angemeldet: string | null;
  floky_anfragen: number;
  floky_grenze: number;
};

const DAUERN = [7, 14, 30];
const ADRESSE = 'https://demo.unityhub.li';

const datum = (s: string | null) =>
  s ? new Date(s).toLocaleDateString('de-CH', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—';
const zeit = (s: string | null) =>
  s ? new Date(s).toLocaleString('de-CH', { dateStyle: 'medium', timeStyle: 'short' }) : 'noch nie';

interface Props {
  leadId: string;
  // Die gespeicherte Adresse -- angelegt wird mit dem, was in der Datenbank steht.
  gespeicherteEmail: string | null;
  // Was gerade im Formular steht, um auf ungespeicherte Aenderungen hinzuweisen.
  formEmail: string | null;
  kontakt: string | null;
}

const SuperAdminDemoZugang: React.FC<Props> = ({ leadId, gespeicherteEmail, formEmail, kontakt }) => {
  const { showAlert, showConfirm } = useFeedback();
  const [zugang, setZugang] = useState<Zugang | null>(null);
  const [geladen, setGeladen] = useState(false);
  const [tage, setTage] = useState(14);
  const [laeuft, setLaeuft] = useState(false);
  const [neu, setNeu] = useState<{ email: string; passwort: string; bis: string } | null>(null);
  const [kopiert, setKopiert] = useState(false);

  const laden = useCallback(async () => {
    const { data, error } = await supabase.rpc('demo_zugaenge_lesen');
    if (!error) setZugang(((data as Zugang[]) ?? []).find((z) => z.lead_id === leadId) ?? null);
    setGeladen(true);
  }, [leadId]);

  useEffect(() => { laden(); }, [laden]);

  const ausfuehren = async (fn: () => Promise<{ error: any }>) => {
    setLaeuft(true);
    const { error } = await fn();
    setLaeuft(false);
    if (error) { await showAlert({ type: 'error', message: error.message }); return false; }
    await laden();
    return true;
  };

  const anlegen = async () => {
    setLaeuft(true);
    const { data, error } = await supabase.rpc('demo_zugang_anlegen', { p_lead: leadId, p_tage: tage });
    setLaeuft(false);
    if (error) { await showAlert({ type: 'error', message: error.message }); return; }
    const r = data as { email: string; passwort: string; gueltig_bis: string };
    setNeu({ email: r.email, passwort: r.passwort, bis: r.gueltig_bis });
    await laden();
  };

  const neuesPasswort = async () => {
    if (!zugang) return;
    const ok = await showConfirm({
      title: 'Neues Passwort?',
      message: 'Das bisherige Passwort gilt danach nicht mehr, offene Sitzungen werden beendet.',
      confirmText: 'Neues Passwort',
    });
    if (!ok) return;
    setLaeuft(true);
    const { data, error } = await supabase.rpc('demo_zugang_neues_passwort', { p_zugang: zugang.id });
    setLaeuft(false);
    if (error) { await showAlert({ type: 'error', message: error.message }); return; }
    setNeu({ email: zugang.email, passwort: data as string, bis: zugang.gueltig_bis });
  };

  const sperren = async () => {
    if (!zugang) return;
    const ok = await showConfirm({
      title: 'Testzugang sperren?',
      message: 'Die Anmeldung ist sofort gesperrt und offene Sitzungen werden beendet. Verlängern hebt die Sperre wieder auf.',
      confirmText: 'Sperren', type: 'danger',
    });
    if (ok) ausfuehren(() => supabase.rpc('demo_zugang_sperren', { p_zugang: zugang.id }));
  };

  const entfernen = async () => {
    if (!zugang) return;
    const ok = await showConfirm({
      title: 'Testzugang entfernen?',
      message: 'Login und Profil im Demoverein werden endgültig gelöscht. Der Interessent bleibt in der Liste.',
      confirmText: 'Entfernen', type: 'danger',
    });
    if (ok && await ausfuehren(() => supabase.rpc('demo_zugang_entfernen', { p_zugang: zugang.id }))) setNeu(null);
  };

  const nachricht = neu ? [
    `Guten Tag${kontakt ? ' ' + kontakt : ''}`,
    '',
    'hier ist Ihr Testzugang zu UnityHub:',
    '',
    `Adresse: ${ADRESSE}`,
    `E-Mail: ${neu.email}`,
    `Passwort: ${neu.passwort}`,
    `Gültig bis: ${datum(neu.bis)}`,
    '',
    'Sie sind als Administration eines erfundenen Demovereins angemeldet und können alles ausprobieren. '
      + 'Der Demoverein wird jede Nacht zurückgesetzt.',
  ].join('\n') : '';

  const kopieren = async () => {
    try {
      await navigator.clipboard.writeText(nachricht);
      setKopiert(true);
      setTimeout(() => setKopiert(false), 2000);
    } catch {
      showAlert({ type: 'error', message: 'Kopieren ging nicht. Markieren Sie den Text von Hand.' });
    }
  };

  const label = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';
  const knopf = 'inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold border transition-colors disabled:opacity-50';
  const dauerWahl = (
    <select value={tage} onChange={(e) => setTage(Number(e.target.value))}
            className="p-2 bg-white border border-stone-200 rounded-xl text-xs font-bold outline-none">
      {DAUERN.map((d) => <option key={d} value={d}>{d} Tage</option>)}
    </select>
  );

  if (!geladen) return null;
  const ungespeichert = (formEmail ?? '').trim().toLowerCase() !== (gespeicherteEmail ?? '').trim().toLowerCase();

  return (
    <div className="rounded-2xl border border-stone-200 bg-stone-50 p-5 space-y-3">
      <label className={label + ' flex items-center gap-1.5'}><KeyRound size={12} /> Testzugang im Demoverein</label>

      {!zugang && (
        <>
          <p className="text-xs text-stone-500 leading-relaxed">
            Ein eigenes Login für {ADRESSE.replace('https://', '')} als Administration, mit Ablaufdatum.
            Danach wird es automatisch gesperrt.
          </p>
          {ungespeichert ? (
            <p className="text-xs font-bold text-amber-700">Speichern Sie zuerst die geänderte E-Mail-Adresse.</p>
          ) : !gespeicherteEmail ? (
            <p className="text-xs font-bold text-amber-700">Dafür braucht der Interessent eine E-Mail-Adresse.</p>
          ) : (
            <div className="flex flex-wrap items-center gap-2">
              {dauerWahl}
              <button onClick={anlegen} disabled={laeuft}
                className={knopf + ' bg-stone-900 text-white border-stone-900 hover:bg-stone-700'}>
                {laeuft ? <Loader2 size={13} className="animate-spin" /> : <KeyRound size={13} />} Testzugang anlegen
              </button>
            </div>
          )}
        </>
      )}

      {zugang && (
        <>
          <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-stone-600">
            <span className="text-stone-400">Login</span><span className="font-bold break-all">{zugang.email}</span>
            <span className="text-stone-400">Status</span>
            <span className={`font-bold ${zugang.aktiv ? 'text-emerald-700' : 'text-red-600'}`}>
              {zugang.aktiv ? `läuft bis ${datum(zugang.gueltig_bis)}`
                : zugang.gesperrt_am && new Date(zugang.gesperrt_am) < new Date(zugang.gueltig_bis) ? 'gesperrt'
                : `abgelaufen am ${datum(zugang.gueltig_bis)}`}
            </span>
            <span className="text-stone-400">Zuletzt angemeldet</span><span>{zeit(zugang.zuletzt_angemeldet)}</span>
            <span className="text-stone-400">Fragen an Floky</span><span>{zugang.floky_anfragen} von {zugang.floky_grenze}</span>
          </div>
          <div className="flex flex-wrap items-center gap-2 pt-1">
            {dauerWahl}
            <button onClick={() => ausfuehren(() => supabase.rpc('demo_zugang_verlaengern', { p_zugang: zugang.id, p_tage: tage }))}
              disabled={laeuft} className={knopf + ' bg-white text-stone-700 border-stone-200 hover:border-stone-400'}>
              <CalendarPlus size={13} /> Verlängern
            </button>
            <button onClick={neuesPasswort} disabled={laeuft}
              className={knopf + ' bg-white text-stone-700 border-stone-200 hover:border-stone-400'}>
              <RefreshCw size={13} /> Neues Passwort
            </button>
            {zugang.aktiv && (
              <button onClick={sperren} disabled={laeuft}
                className={knopf + ' bg-white text-red-600 border-red-200 hover:border-red-400'}>
                <Ban size={13} /> Sperren
              </button>
            )}
            <button onClick={entfernen} disabled={laeuft}
              className={knopf + ' bg-white text-red-600 border-red-200 hover:border-red-400'}>
              <Trash2 size={13} /> Entfernen
            </button>
          </div>
        </>
      )}

      {neu && (
        <div className="rounded-xl border border-emerald-200 bg-white p-4 space-y-2">
          <p className="text-xs font-bold text-emerald-800">
            Das Passwort wird nur jetzt angezeigt. Schicken Sie die Nachricht dem Interessenten.
          </p>
          <pre className="text-xs text-stone-700 whitespace-pre-wrap font-mono bg-stone-50 rounded-lg p-3 select-all">{nachricht}</pre>
          <button onClick={kopieren}
            className={knopf + ' bg-emerald-600 text-white border-emerald-600 hover:bg-emerald-700'}>
            {kopiert ? <Check size={13} /> : <Copy size={13} />} {kopiert ? 'Kopiert' : 'Nachricht kopieren'}
          </button>
        </div>
      )}
    </div>
  );
};

export default SuperAdminDemoZugang;
