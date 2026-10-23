import React, { useCallback, useEffect, useState } from 'react';
import { RotateCcw, Save, ExternalLink } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';

// Den Demoverein nach einer Vorfuehrung auf den Ausgangsstand bringen.
//
// Was zurueckgesetzt wird, entscheidet die Datenbank (demo_zuruecksetzen):
// alle Daten des Vereins 'demo' und die Passwoerter seiner Zugaenge. Diese
// Karte zeigt nur an und loest aus. Die Pruefung, dass nur der Betreiber das
// darf, steckt ebenfalls in der Funktion -- nicht darin, dass die Karte nur
// hier erscheint.

type Stand = {
  vorlage_am: string | null;
  vorlage_von: string | null;
  vorlage_zeilen: number | null;
  zurueckgesetzt_am: string | null;
  zurueckgesetzt_von: string | null;
  passwort_gesetzt: boolean;
};

const zeit = (s: string | null) =>
  s ? new Date(s).toLocaleString('de-CH', { dateStyle: 'medium', timeStyle: 'short' }) : '—';

const SuperAdminDemo: React.FC = () => {
  const { showAlert, showConfirm } = useFeedback();
  const [stand, setStand] = useState<Stand | null>(null);
  const [laeuft, setLaeuft] = useState<'RESET' | 'SPEICHERN' | 'PAKET' | null>(null);
  const [paket, setPaket] = useState<'LIGHT' | 'VOLL' | null>(null);

  const laden = useCallback(async () => {
    const [{ data, error }, p] = await Promise.all([
      supabase.rpc('demo_stand_lesen'), supabase.rpc('demo_paket_lesen')]);
    if (!error) setStand((data as Stand[] | null)?.[0] ?? null);
    if (!p.error) setPaket(p.data as 'LIGHT' | 'VOLL');
  }, []);

  // Light: nur die Kernmodule (Mitglieder & Nachbarschaften, Rechnungen,
  // Vorstand). Alles andere erscheint in der Verwaltung ausgegraut.
  // Gesperrt wird ueber die Modulschalter des Demovereins -- dieselben, die
  // auch die Zeilenregeln lesen. Andere Vereine beruehrt der Schalter nicht.
  const paketSetzen = async (p: 'LIGHT' | 'VOLL') => {
    if (p === paket) return;
    setLaeuft('PAKET');
    const { error } = await supabase.rpc('demo_paket_setzen', { p_paket: p });
    setLaeuft(null);
    if (error) { await showAlert({ title: 'Nicht umgestellt', message: error.message, type: 'error' }); return; }
    setPaket(p);
  };

  useEffect(() => { laden(); }, [laden]);

  const zuruecksetzen = async () => {
    const ok = await showConfirm({
      title: 'Demoverein zurücksetzen?',
      message: `Alle Änderungen seit der Vorlage vom ${zeit(stand?.vorlage_am ?? null)} gehen verloren. `
        + 'Alle Demo-Zugänge bekommen wieder das gemeinsame Passwort und werden abgemeldet. Andere Vereine sind nicht betroffen.',
      confirmText: 'Zurücksetzen',
      type: 'danger',
    });
    if (!ok) return;
    setLaeuft('RESET');
    const { data, error } = await supabase.rpc('demo_zuruecksetzen');
    setLaeuft(null);
    if (error) {
      await showAlert({ title: 'Nicht zurückgesetzt', message: error.message, type: 'error' });
      return;
    }
    const e = data as { zeilen: number; konten: number };
    await showAlert({
      title: 'Demoverein zurückgesetzt',
      message: `${e.zeilen} Datensätze wiederhergestellt, ${e.konten} Zugänge auf das gemeinsame Passwort gesetzt.`,
      type: 'success',
    });
    laden();
  };

  const vorlageSpeichern = async () => {
    const ok = await showConfirm({
      title: 'Jetzigen Stand als Vorlage übernehmen?',
      message: 'Künftiges Zurücksetzen führt dann auf den Stand von jetzt zurück. Die bisherige Vorlage wird ersetzt.',
      confirmText: 'Als Vorlage übernehmen',
      type: 'neutral',
    });
    if (!ok) return;
    setLaeuft('SPEICHERN');
    const { data, error } = await supabase.rpc('demo_vorlage_speichern');
    setLaeuft(null);
    if (error) {
      await showAlert({ title: 'Nicht gespeichert', message: error.message, type: 'error' });
      return;
    }
    await showAlert({ title: 'Vorlage gespeichert', message: `${data} Datensätze festgehalten.`, type: 'success' });
    laden();
  };

  return (
    <div className="bg-white/5 border border-white/10 rounded-3xl p-6 mb-8 flex flex-col md:flex-row md:items-center gap-6">
      <div className="flex-1 min-w-0">
        <h3 className="font-bold flex items-center gap-2">
          Demoverein
          <a href="https://demo.unityhub.li" target="_blank" rel="noreferrer"
             className="text-stone-500 hover:text-white" title="demo.unityhub.li öffnen">
            <ExternalLink size={14} />
          </a>
        </h3>
        <p className="text-xs text-stone-400 mt-1 leading-relaxed">
          Vorlage vom {zeit(stand?.vorlage_am ?? null)}
          {stand?.vorlage_zeilen ? ` (${stand.vorlage_zeilen} Datensätze)` : ''}
          {' · '}zuletzt zurückgesetzt {zeit(stand?.zurueckgesetzt_am ?? null)}
        </p>
        <p className="text-xs text-stone-500 mt-1 leading-relaxed">
          Paket {paket === 'LIGHT' ? 'Light: Mitglieder & Nachbarschaften, Rechnungen, Vorstand. Alles andere ist ausgegraut, auch die öffentliche Website.'
                 : paket === 'VOLL' ? 'Voll: alle Funktionen.' : '…'} Das Zurücksetzen behält das gewählte Paket.
        </p>
        {stand && !stand.passwort_gesetzt && (
          <p className="text-xs text-amber-400 mt-1">
            Kein gemeinsames Passwort hinterlegt: Die Zugänge behalten beim Zurücksetzen ihr Passwort.
          </p>
        )}
      </div>
      <div className="flex gap-2 shrink-0 flex-wrap items-center">
        <div className="flex bg-white/10 p-1 rounded-xl" title="Paket des Demovereins">
          {(['LIGHT', 'VOLL'] as const).map(p => (
            <button key={p} onClick={() => paketSetzen(p)} disabled={!!laeuft || paket === null}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold disabled:opacity-50 ${paket === p ? 'bg-white text-stone-900' : 'text-stone-300 hover:text-white'}`}>
              {p === 'LIGHT' ? 'Light' : 'Voll'}
            </button>
          ))}
        </div>
        <button onClick={vorlageSpeichern} disabled={!!laeuft}
                className="bg-white/10 hover:bg-white/20 px-4 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 disabled:opacity-50">
          <Save size={14} /> {laeuft === 'SPEICHERN' ? 'Speichert …' : 'Stand als Vorlage'}
        </button>
        <button onClick={zuruecksetzen} disabled={!!laeuft || !stand?.vorlage_am}
                className="bg-rose-500 hover:bg-rose-600 text-white px-4 py-2.5 rounded-xl text-xs font-bold flex items-center gap-2 disabled:opacity-50">
          <RotateCcw size={14} /> {laeuft === 'RESET' ? 'Setzt zurück …' : 'Demo zurücksetzen'}
        </button>
      </div>
    </div>
  );
};

export default SuperAdminDemo;
