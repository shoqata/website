import React, { useEffect, useState } from 'react';
import { Loader2, Link2, AlertTriangle, Check, UserX, KeyRound } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useFeedback } from '../context/FeedbackContext';

// Wer kommt nicht herein?
//
// Diese Liste ist aus einem Fehler entstanden, der drei Personen
// ausgeschlossen hat, ohne dass es irgendwo sichtbar war. Gemeldet wurde
// "neue Nutzer koennen sich nicht anmelden"; gefunden wurde es erst, als
// ich die Zuordnung in deren Namen aufrief und die Datenbank sagte, was
// sie stoert.
//
// Zwei Faelle stehen hier, und sie brauchen Verschiedenes:
//
//   Bevorrechtigte Rolle -- Vorstand, Verantwortlicher, Administration.
//   Diese Konten duerfen sich NICHT selbst zuordnen, sonst koennte sich
//   jemand mit der Adresse eines Vorstands anmelden und dessen Rechte
//   uebernehmen. Sie brauchen einen Klick von der Administration.
//
//   Konto ohne Mitgliedseintrag. Da hilft kein Verbinden; es gibt nichts
//   zu verbinden. Der Betreiber ist dieser Fall und soll es bleiben.
//
// Verbinden tastet das Passwort NICHT an. Das war vorher nur ueber
// "Passwort zuruecksetzen" moeglich -- wer sein Passwort kennt und nur
// die Verbindung braucht, musste es ohne Grund wechseln.

type Zeile = {
  r_email: string; r_mitglied: string | null; r_name: string; r_rolle: string;
  r_konto_da: boolean; r_konto_bestaetigt: boolean; r_grund: string;
};

const AdminKontoVerbindungen: React.FC = () => {
  const { showAlert } = useFeedback();
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  const [arbeitet, setArbeitet] = useState<string | null>(null);

  const laden = async () => {
    setLaedt(true); setFehler('');
    const { data, error } = await supabase.rpc('konten_ohne_verbindung');
    if (error) setFehler(error.message);
    setZeilen((data as Zeile[]) ?? []);
    setLaedt(false);
  };

  useEffect(() => { laden(); }, []);

  const verbinden = async (z: Zeile) => {
    if (!z.r_mitglied) return;
    setArbeitet(z.r_email);
    try {
      const { data, error } = await supabase.rpc('konto_verbinden', { p_member: z.r_mitglied });
      if (error) throw error;
      const e = data as any;
      if (e?.verbunden) {
        showAlert({ type: 'success',
                    message: `${e.name} kann sich jetzt anmelden. Das Passwort blieb unverändert.` });
      } else {
        // Den Grund zeigen, nicht ein allgemeines "ging nicht". Die
        // Funktion sagt genau, was fehlt.
        showAlert({ type: 'error', message: e?.grund || 'Nicht verbunden.' });
      }
      await laden();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setArbeitet(null); }
  };

  if (laedt) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const verbindbar = zeilen.filter(z => z.r_mitglied && z.r_konto_da);
  const ohne = zeilen.filter(z => !z.r_mitglied);

  return (
    <div className="space-y-4">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
        <div className="p-5 border-b border-stone-100 bg-stone-50">
          <h3 className="font-bold text-sm text-stone-900 flex items-center gap-2">
            <Link2 size={15} className="text-primary" /> Anmeldekonten ohne Verbindung
          </h3>
          <p className="text-[11px] text-stone-500 mt-1 leading-relaxed">
            Wer hier steht, hat ein Anmeldekonto, kommt aber nicht in den Verein.
            Verbinden lässt das Passwort unberührt.
          </p>
        </div>

        {zeilen.length === 0 ? (
          <p className="p-8 text-center text-sm text-emerald-700 font-bold flex items-center justify-center gap-2">
            <Check size={16} /> Alle Konten sind verbunden.
          </p>
        ) : (
          <div className="divide-y divide-stone-50">
            {verbindbar.map(z => (
              <div key={z.r_email} className="p-5 flex items-center justify-between gap-4 flex-wrap hover:bg-stone-50">
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-900 truncate">{z.r_name}</p>
                  <p className="text-[11px] text-stone-500 mt-0.5">
                    {z.r_email} · Rolle {z.r_rolle}
                    {!z.r_konto_bestaetigt && ' · Konto nicht bestätigt'}
                  </p>
                  <p className="text-[11px] text-amber-700 mt-0.5">{z.r_grund}</p>
                </div>
                <button onClick={() => verbinden(z)} disabled={arbeitet === z.r_email}
                  className="px-4 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs hover:bg-stone-800 transition-colors flex items-center gap-2 shrink-0 disabled:opacity-50">
                  {arbeitet === z.r_email
                    ? <Loader2 size={13} className="animate-spin" />
                    : <Link2 size={13} />} Verbinden
                </button>
              </div>
            ))}

            {ohne.map(z => (
              <div key={z.r_email} className="p-5 flex items-center justify-between gap-4">
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-700 truncate">{z.r_email}</p>
                  <p className="text-[11px] text-stone-400 mt-0.5">{z.r_grund}</p>
                </div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-stone-400 flex items-center gap-1.5 shrink-0">
                  <UserX size={12} /> nichts zu verbinden
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {verbindbar.length > 0 && (
        <p className="text-[11px] text-stone-500 leading-relaxed px-1 flex gap-2">
          <KeyRound size={13} className="shrink-0 mt-0.5 text-stone-400" />
          Wer sein Passwort nicht kennt, braucht zusätzlich „Passwort zurücksetzen"
          unter Mitglieder. Verbinden allein stellt nur die Zuordnung her.
        </p>
      )}
    </div>
  );
};

export default AdminKontoVerbindungen;
