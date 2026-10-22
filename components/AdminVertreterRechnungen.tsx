import React, { useEffect, useState } from 'react';
import { Loader2, Receipt, AlertTriangle, KeyRound } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Rechnungen fuer die Verantwortlichen einer Nachbarschaft -- je Person.
//
// Die Feldrechte daneben gelten fuer alle Verantwortlichen gemeinsam, weil
// es dort um Datenpflege geht. Rechnungen sind Geld und Vertrauen: dem
// einen gibt man sie, dem anderen nicht. Darum hier eine Zeile je Person.
//
// Die Schalter wirken in der Datenbank (payments_read und
// vertreter_rechnung_senden), nicht nur in der Maske. Weitergeleitet wird
// immer an die beim Mitglied hinterlegte Adresse -- der Vertreter kann
// keine andere angeben.
//
// Dazu die Werkzeuge des Vertreters vor Ort: bar kassieren (die Rechnung
// gilt sofort als bezahlt, das Geld liegt in seiner Handkasse), Ausgaben aus
// der Handkasse, Neuerfassung von Mitgliedern und eigene Aufgaben.

type Zeile = {
  person: string; name: string; email: string | null; zugang: boolean;
  nachbarschaften: string[]; sehen: boolean; senden: boolean;
  kassieren: boolean; ausgaben: boolean; erfassen: boolean; aufgaben: boolean;
};

type Recht = 'sehen' | 'senden' | 'kassieren' | 'ausgaben' | 'erfassen' | 'aufgaben';

const SCHALTER: { k: Recht; name: string; was: string }[] = [
  { k: 'sehen', name: 'Sehen', was: 'Rechnungen seiner Nachbarschaft mit Stand und PDF' },
  { k: 'senden', name: 'Weiterleiten', was: 'Rechnung per E-Mail an das Mitglied, an die hinterlegte Adresse' },
  { k: 'kassieren', name: 'Kassieren', was: 'Beitrag bar entgegennehmen; gilt sofort als bezahlt, Geld in seiner Handkasse' },
  { k: 'ausgaben', name: 'Ausgaben', was: 'Ausgaben bar aus der Handkasse, mit Belegfoto; der Vorstand genehmigt' },
  { k: 'erfassen', name: 'Erfassen', was: 'neue Mitglieder in seiner Nachbarschaft aufnehmen, auch ohne E-Mail' },
  { k: 'aufgaben', name: 'Aufgaben', was: 'eigene Aufgaben vor Ort anlegen und abhaken' },
];

const AdminVertreterRechnungen: React.FC<{ darf: boolean }> = ({ darf }) => {
  const [zeilen, setZeilen] = useState<Zeile[] | null>(null);
  const [laeuft, setLaeuft] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  useEffect(() => {
    let lebt = true;
    (async () => {
      const [{ data: stand, error: e1 }, { data: rechte, error: e2 }] = await Promise.all([
        supabase.rpc('verantwortliche_stand'),
        supabase.rpc('vertreter_rechte_stand'),
      ]);
      if (!lebt) return;
      if (e1 || e2) { setFehler((e1 || e2)!.message); setZeilen([]); return; }
      const r = new Map(((rechte as any[]) || []).map(x => [x.person, x]));
      const je = new Map<string, Zeile>();
      for (const s of (stand as any[]) || []) {
        // Platzhalter aus der Erstbefuellung treffen auf keine Person.
        if (!s.r_email && s.r_person_name === s.r_person) continue;
        const z = je.get(s.r_person) ?? {
          person: s.r_person, name: s.r_person_name, email: s.r_email,
          zugang: !!s.r_hat_zugang, nachbarschaften: [],
          sehen: !!r.get(s.r_person)?.sehen, senden: !!r.get(s.r_person)?.senden,
          kassieren: !!r.get(s.r_person)?.kassieren, ausgaben: !!r.get(s.r_person)?.ausgaben,
          erfassen: !!r.get(s.r_person)?.erfassen, aufgaben: !!r.get(s.r_person)?.aufgaben,
        };
        z.nachbarschaften.push(s.r_name);
        je.set(s.r_person, z);
      }
      setZeilen([...je.values()].sort((a, b) => a.name.localeCompare(b.name)));
    })();
    return () => { lebt = false; };
  }, []);

  const setzen = async (z: Zeile, recht: Recht, an: boolean) => {
    const neu = { ...z, [recht]: an };
    // Weiterleiten und Kassieren setzen Sehen voraus. Wer Sehen wegnimmt,
    // nimmt beides mit -- sonst setzte die Datenbank Sehen gleich wieder.
    if (recht === 'sehen' && !an) { neu.senden = false; neu.kassieren = false; }
    setLaeuft(z.person); setFehler(null);
    const { data, error } = await supabase.rpc('vertreter_rechte_setzen', {
      p_person: z.person, p_sehen: neu.sehen, p_senden: neu.senden, p_kassieren: neu.kassieren,
      p_ausgaben: neu.ausgaben, p_erfassen: neu.erfassen, p_aufgaben: neu.aufgaben,
    });
    setLaeuft(null);
    if (error) { setFehler(error.message); return; }
    // Die Datenbank entscheidet, was gilt.
    const d: any = Array.isArray(data) ? data[0] : data;
    setZeilen(zs => zs!.map(x => x.person === z.person
      ? { ...x, sehen: !!d?.sehen, senden: !!d?.senden, kassieren: !!d?.kassieren,
          ausgaben: !!d?.ausgaben, erfassen: !!d?.erfassen, aufgaben: !!d?.aufgaben } : x));
  };

  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';

  return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
      <div>
        <p className={`${marke} flex items-center gap-2`}>
          <Receipt size={13} /> Rechte je Nachbarschaftsvertreter
        </p>
        <ul className="text-[11px] text-stone-500 leading-relaxed mt-2 max-w-2xl space-y-0.5">
          {SCHALTER.map(s => (
            <li key={s.k}><span className="font-bold text-stone-700">{s.name}</span>: {s.was}</li>
          ))}
        </ul>
      </div>

      {fehler && (
        <p className="text-xs text-amber-700 bg-amber-50 border border-amber-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {zeilen === null ? (
        <div className="flex items-center gap-3 text-stone-400 text-sm">
          <Loader2 className="animate-spin" size={16} /> Lädt …
        </div>
      ) : zeilen.length === 0 ? (
        <p className="text-xs text-stone-400 italic">
          Noch niemand ist als verantwortlich für eine Nachbarschaft eingetragen.
        </p>
      ) : (
        <div className="bg-white rounded-2xl border border-stone-100 divide-y divide-stone-100">
          {zeilen.map(z => (
            <div key={z.person} className="p-4 flex flex-wrap items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="text-sm font-bold text-stone-900 truncate">{z.name}</p>
                <p className="text-[11px] text-stone-500 truncate">{z.nachbarschaften.join(' · ')}</p>
                {!z.zugang && (
                  <p className="text-[10px] text-amber-700 flex items-center gap-1 mt-0.5">
                    <KeyRound size={10} /> kann sich noch nicht anmelden — die Freigabe wirkt erst danach
                  </p>
                )}
              </div>
              <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
                {laeuft === z.person && <Loader2 size={14} className="animate-spin text-stone-400" />}
                {SCHALTER.map(s => (
                  <label key={s.k} title={s.was}
                    className={`flex items-center gap-2 text-xs ${darf ? 'cursor-pointer' : 'opacity-60'}`}>
                    <input type="checkbox" className="w-4 h-4 accent-stone-900"
                      disabled={!darf || laeuft === z.person} checked={z[s.k]}
                      onChange={e => setzen(z, s.k, e.target.checked)} />
                    {s.name}
                  </label>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AdminVertreterRechnungen;
