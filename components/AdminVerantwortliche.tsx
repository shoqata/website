import React, { useEffect, useState } from 'react';
import {
  Loader2, MapPin, KeyRound, ShieldAlert, Check, UserX, AlertTriangle, Users,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import AdminPasswordReset from './AdminPasswordReset';

// Wer betreut welche Nachbarschaft -- und kommt diese Person herein?
//
// Diese Maske entstand aus einer Messung, nicht aus einem Wunsch. Gemeldet
// war, dass ein Verantwortlicher keine Mitgliederdaten anpassen kann. Beim
// Nachsehen ergab sich etwas Groesseres:
//
//   Nachbarschaften                   27
//   mit Verantwortlichen hinterlegt    6
//   hinterlegte Personen               8
//   davon mit Anmeldung                2
//
// Sechs Verantwortliche standen auf dem Papier und konnten den Verein nicht
// betreten -- darunter Canaj-t mit 45 Mitgliedern, die groesste
// Nachbarschaft des Vereins. Niemandem aufgefallen, weil es keine Stelle
// gab, an der man es sehen konnte: die Nachbarschaftsmaske zeigt, WER
// hinterlegt ist, nicht ob diese Person sich anmelden kann.
//
// Die Faehigkeit, ein Konto anzulegen, gab es schon. Sie hiess nur
// "Passwort zuruecksetzen" -- und dort sucht niemand nach "gib diesem
// Verantwortlichen einen Zugang". Darum steht sie hier unter dem Namen,
// unter dem man sie braucht.

type Zeile = {
  r_nachbarschaft: string; r_name: string; r_person: string;
  r_person_name: string; r_email: string | null;
  r_hat_zugang: boolean; r_rolle: string; r_mitglieder: number;
};
type Ohne = { r_id: string; r_name: string; r_mitglieder: number };

const AdminVerantwortliche: React.FC = () => {
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  const [ohne, setOhne] = useState<Ohne[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  // Fuer wen gerade ein Zugang angelegt wird. AdminPasswordReset legt
  // das Konto an, wenn keines besteht, und zeigt das Passwort genau
  // einmal -- hier wird dieselbe Maske verwendet statt einer zweiten,
  // die dasselbe anders macht.
  const [zugangFuer, setZugangFuer] = useState<any>(null);

  const laden = async () => {
    setLaedt(true); setFehler('');
    const [a, b] = await Promise.all([
      supabase.rpc('verantwortliche_stand'),
      supabase.rpc('nachbarschaften_ohne_verantwortlichen'),
    ]);
    if (a.error || b.error) setFehler(a.error?.message || b.error?.message || '?');
    setZeilen((a.data as Zeile[]) ?? []);
    setOhne((b.data as Ohne[]) ?? []);
    setLaedt(false);
  };

  useEffect(() => { laden(); }, []);

  if (laedt) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const ohneZugang = zeilen.filter(z => !z.r_hat_zugang);
  // Eine Kennung, zu der es keine Person gibt. In den echten Daten steckt
  // "rep-user-2" -- eine Testkennung, die in der Nachbarschaft Lagjja e
  // Lumit hinterlegt ist. Sie als "ohne Zugang" zu fuehren waere
  // irrefuehrend: da ist niemand, dem man einen geben koennte.
  const verwaist = zeilen.filter(z => z.r_rolle === '—');
  const betroffene = ohneZugang.filter(z => z.r_rolle !== '—')
    .reduce((s, z) => s + z.r_mitglieder, 0);

  return (
    <div className="space-y-6">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {/* Die Zahl zuerst. Eine Liste von acht Zeilen laesst offen, wie
          schlimm es ist; "sechs von acht, und daran haengen 91
          Mitglieder" nicht. */}
      {ohneZugang.length > 0 && (
        <div className="p-5 bg-amber-50 border border-amber-200 rounded-2xl">
          <p className="text-sm font-bold text-amber-900 flex items-center gap-2">
            <ShieldAlert size={16} />
            {ohneZugang.length} von {zeilen.length} Verantwortlichen können sich nicht anmelden
          </p>
          <p className="text-xs text-amber-800 leading-relaxed mt-2">
            Sie sind in ihrer Nachbarschaft hinterlegt, haben aber kein Anmeldekonto —
            sie können die Mitgliederliste also weder sehen noch pflegen.
            {betroffene > 0 && <> Betroffen sind <strong>{betroffene} Mitglieder</strong>.</>}
          </p>
        </div>
      )}

      {/* Die Liste. Ohne Zugang zuerst -- das ist die Arbeitsliste. */}
      <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
        <div className="p-5 border-b border-stone-100 bg-stone-50">
          <h3 className="font-bold text-sm text-stone-900 flex items-center gap-2">
            <MapPin size={15} className="text-primary" /> Verantwortliche der Nachbarschaften
          </h3>
        </div>
        <div className="divide-y divide-stone-50">
          {[...zeilen].sort((a, b) =>
            Number(a.r_hat_zugang) - Number(b.r_hat_zugang)
            || b.r_mitglieder - a.r_mitglieder).map(z => (
            <div key={z.r_nachbarschaft + z.r_person}
              className="p-5 flex items-center justify-between gap-4 flex-wrap hover:bg-stone-50">
              <div className="min-w-0">
                <p className="font-bold text-sm text-stone-900 truncate">{z.r_person_name}</p>
                <p className="text-[11px] text-stone-500 mt-0.5">
                  {z.r_name} · {z.r_mitglieder} Mitglieder
                  {z.r_email ? ` · ${z.r_email}` : ' · keine E-Mail hinterlegt'}
                </p>
              </div>

              {z.r_rolle === '—' ? (
                // Kein Mitgliedsdatensatz dahinter. Hier hilft kein
                // Zugang, hier muss die Hinterlegung berichtigt werden.
                <div className="flex items-center gap-2 shrink-0">
                  <span className="px-2.5 py-1 bg-red-100 text-red-800 rounded-full text-[10px] font-bold uppercase tracking-wider flex items-center gap-1">
                    <UserX size={11} /> Person existiert nicht
                  </span>
                </div>
              ) : z.r_hat_zugang ? (
                <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded-full text-[10px] font-bold uppercase tracking-wider flex items-center gap-1 shrink-0">
                  <Check size={11} /> kann sich anmelden
                </span>
              ) : (
                <button
                  onClick={() => setZugangFuer({
                    id: z.r_person, displayName: z.r_person_name, email: z.r_email,
                  })}
                  className="px-4 py-2 bg-stone-900 text-white rounded-xl font-bold text-xs hover:bg-stone-800 transition-colors flex items-center gap-2 shrink-0">
                  <KeyRound size={13} /> Zugang anlegen
                </button>
              )}
            </div>
          ))}
          {zeilen.length === 0 && (
            <p className="p-8 text-center text-sm text-stone-400 italic">
              In keiner Nachbarschaft ist jemand hinterlegt.
            </p>
          )}
        </div>
      </div>

      {verwaist.length > 0 && (
        <div className="p-5 bg-red-50 border border-red-200 rounded-2xl">
          <p className="text-sm font-bold text-red-900 flex items-center gap-2">
            <UserX size={16} /> {verwaist.length} Hinterlegung zeigt auf niemanden
          </p>
          <p className="text-xs text-red-800 leading-relaxed mt-2">
            {verwaist.map(v => `„${v.r_person}" in ${v.r_name}`).join(', ')} — zu dieser
            Kennung gibt es keinen Mitgliedsdatensatz. Solange sie dort steht, hat die
            Nachbarschaft faktisch niemanden. Bitte unter Nachbarschaften berichtigen.
          </p>
        </div>
      )}

      {/* Was fehlt, ist so wichtig wie was da ist. Eine Uebersicht, die
          nur die sechs hinterlegten Nachbarschaften zeigt, verschweigt
          die 21 ohne jeden Verantwortlichen. */}
      {ohne.length > 0 && (
        <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
          <div className="p-5 border-b border-stone-100 bg-stone-50">
            <h3 className="font-bold text-sm text-stone-900 flex items-center gap-2">
              <Users size={15} className="text-stone-400" />
              {ohne.length} Nachbarschaften ohne Verantwortlichen
            </h3>
            <p className="text-[11px] text-stone-500 mt-1">
              Unter Nachbarschaften lässt sich dort jemand hinterlegen; den Zugang
              gibt es danach hier.
            </p>
          </div>
          <div className="p-5 flex flex-wrap gap-2">
            {ohne.map(o => (
              <span key={o.r_id}
                className="px-3 py-1.5 bg-stone-100 text-stone-600 rounded-lg text-xs font-bold">
                {o.r_name}
                {o.r_mitglieder > 0 && (
                  <span className="text-stone-400 font-normal"> · {o.r_mitglieder}</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}

      {zugangFuer && (
        <AdminPasswordReset
          member={zugangFuer}
          onClose={() => { setZugangFuer(null); laden(); }}
        />
      )}
    </div>
  );
};

export default AdminVerantwortliche;
