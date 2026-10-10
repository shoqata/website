import React, { useEffect, useState } from 'react';
import {
  Loader2, Save, Check, AlertTriangle, Shield, Search, Lock, Info,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import AdminVorstandsrechte from './AdminVorstandsrechte';
import AdminVertreterrechte from './AdminVertreterrechte';

// Rollenverwaltung.
//
// Hier steht an einer Stelle, was vorher an dreien lag: wer welche Rolle
// hat, was eine Rolle darf, und was sie nie darf. Verstreut war es nicht
// falsch, aber unbeantwortbar -- die Frage "was kann ein Vorstandsmitglied
// eigentlich?" liess sich nur durch Suchen klaeren.
//
// Zwei Dinge, die hier sichtbar sein muessen, weil sie sonst ueberraschen:
//
//   Die EIGENE Rolle kann niemand aendern. Wer aufhoeren will, bestimmt
//   zuerst einen Nachfolger; der stuft ihn dann herab.
//
//   Die LETZTE Administration bleibt. Sonst steht der Verein ohne da und
//   nur der Betreiber kommt noch hinein.
//
// Beides prueft die Datenbank. Die Maske sagt es nur vorher, statt es
// hinterher als Fehler zu melden.

type Person = {
  id: string; displayName: string; email: string | null;
  role: string; authUserId: string | null;
};

const ROLLEN = [
  { key: 'MEMBER', name: 'Mitglied',
    darf: 'Eigenes Profil, eigene Beiträge, Anmeldung zu Anlässen.' },
  { key: 'REPRESENTATIVE', name: 'Vertreter',
    darf: 'Wie Mitglied. Die Betreuung einer Nachbarschaft hängt aber nicht an dieser Rolle, sondern an der Nachbarschaft selbst.' },
  { key: 'BOARD', name: 'Vorstand',
    darf: 'Sieht alles im Verein. Ob er ändern darf, stellen Sie unten ein.' },
  { key: 'ADMIN', name: 'Administration',
    darf: 'Verwaltet den Verein vollständig und vergibt Rollen.' },
  { key: 'SUPER_ADMIN', name: 'Administration (voll)',
    darf: 'Wie Administration. Historisch gewachsene zweite Bezeichnung.' },
];

const AdminRollenverwaltung: React.FC = () => {
  const [leute, setLeute] = useState<Person[] | null>(null);
  const [ich, setIch] = useState<string | null>(null);
  const [darf, setDarf] = useState(false);
  const [suche, setSuche] = useState('');
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [gespeichert, setGespeichert] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  const laden = async () => {
    const [{ data: u, error }, { data: wer }, { data: meineId }] = await Promise.all([
      supabase.from('users').select('id,displayName,email,role,authUserId').order('displayName'),
      supabase.rpc('wer_bin_ich'),
      supabase.rpc('current_user_row_id'),
    ]);
    if (error) { setFehler(error.message); setLeute([]); return; }
    setLeute((u as Person[]) ?? []);
    const w = Array.isArray(wer) ? wer[0] : wer;
    setDarf(!!w && (w.ist_betreiber || ['SUPER_ADMIN', 'ADMIN'].includes(w.rolle)));
    setIch((meineId as string) ?? null);
  };
  useEffect(() => { laden(); }, []);

  const setzen = async (p: Person, rolle: string) => {
    setArbeitet(p.id); setFehler(null);
    const { error } = await supabase.rpc('rolle_setzen', { p_user: p.id, p_rolle: rolle });
    setArbeitet(null);
    if (error) { setFehler(error.message); return; }
    setGespeichert(p.id); setTimeout(() => setGespeichert(null), 2000);
    await laden();
  };

  if (leute === null) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest';
  const verwalter = leute.filter(p => ['SUPER_ADMIN', 'ADMIN'].includes(p.role));
  const traeger = leute.filter(p => p.role && p.role !== 'MEMBER');
  const s = suche.trim().toLowerCase();
  const gesucht = s
    ? leute.filter(p => (p.displayName ?? '').toLowerCase().includes(s)
                     || (p.email ?? '').toLowerCase().includes(s)).slice(0, 12)
    : [];

  const zeile = (p: Person) => {
    const selbst = p.id === ich;
    const letzter = verwalter.length <= 1 && ['SUPER_ADMIN', 'ADMIN'].includes(p.role);
    const gesperrt = !darf || selbst || arbeitet === p.id;
    return (
      <div key={p.id} className="flex items-center gap-4 px-4 py-3 border-b border-stone-50 last:border-0">
        <div className="min-w-0 flex-1">
          <p className="text-sm font-bold text-stone-800 truncate">
            {p.displayName || p.id}
            {selbst && <span className="ml-2 text-[10px] font-normal text-stone-400">(Sie)</span>}
          </p>
          <p className="text-[11px] text-stone-400 truncate">
            {p.email || 'keine E-Mail'}
            {!p.authUserId && <span className="ml-2 text-amber-600">kein Zugang</span>}
          </p>
        </div>
        <select value={p.role || 'MEMBER'} disabled={gesperrt}
          onChange={e => setzen(p, e.target.value)}
          className="p-2 bg-white border border-stone-200 rounded-lg text-xs font-bold
                     outline-none disabled:opacity-40 disabled:cursor-not-allowed shrink-0">
          {ROLLEN.map(r => <option key={r.key} value={r.key}>{r.name}</option>)}
        </select>
        <span className="w-5 shrink-0">
          {arbeitet === p.id && <Loader2 size={14} className="animate-spin text-stone-400" />}
          {gespeichert === p.id && <Check size={14} className="text-emerald-600" />}
          {(selbst || letzter) && arbeitet !== p.id && gespeichert !== p.id && (
            <Lock size={13} className="text-stone-300" />
          )}
        </span>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {/* ----------------------------------------- Was eine Rolle darf */}
      <div className="bg-stone-50 rounded-3xl border border-stone-100 p-6 space-y-4">
        <p className={`${marke} flex items-center gap-2`}><Shield size={13} /> Die Rollen</p>
        <div className="bg-white rounded-2xl border border-stone-100 divide-y divide-stone-50">
          {ROLLEN.map(r => {
            const n = leute.filter(p => (p.role || 'MEMBER') === r.key).length;
            return (
              <div key={r.key} className="px-4 py-3 flex items-start gap-4">
                <div className="w-40 shrink-0">
                  <p className="text-sm font-bold text-stone-800">{r.name}</p>
                  <p className="text-[10px] text-stone-400 tabular-nums">
                    {n} {n === 1 ? 'Person' : 'Personen'}
                  </p>
                </div>
                <p className="text-[11px] text-stone-500 leading-relaxed flex-1">{r.darf}</p>
              </div>
            );
          })}
        </div>
        <div className="flex items-start gap-2 text-[11px] text-stone-500 leading-relaxed">
          <Info size={13} className="shrink-0 mt-0.5 text-stone-400" />
          <span>
            Zwei Regeln prüft die Datenbank, nicht diese Maske: die <strong>eigene</strong> Rolle
            kann niemand ändern — bestimmen Sie zuerst einen Nachfolger, der Sie dann herabstuft.
            Und die <strong>letzte Administration</strong> bleibt, sonst kommt niemand mehr in
            die Verwaltung.
          </span>
        </div>
      </div>

      {/* ------------------------------------------- Wer hat was */}
      <div className="bg-stone-50 rounded-3xl border border-stone-100 p-6 space-y-4">
        <p className={marke}>Wer hat eine Rolle</p>
        {traeger.length === 0 ? (
          <p className="text-xs text-stone-400">Niemand ausser Mitgliedern.</p>
        ) : (
          <div className="bg-white rounded-2xl border border-stone-100">
            {traeger.map(zeile)}
          </div>
        )}

        <div>
          <p className={`${marke} mb-2`}>Jemandem eine Rolle geben</p>
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-300" />
            <input value={suche} onChange={e => setSuche(e.target.value)}
              placeholder="Name oder E-Mail …"
              className="w-full pl-9 p-3 bg-white border border-stone-200 rounded-xl
                         text-sm outline-none focus:border-stone-300" />
          </div>
          {gesucht.length > 0 && (
            <div className="bg-white rounded-2xl border border-stone-100 mt-2">
              {gesucht.map(zeile)}
            </div>
          )}
          {s && gesucht.length === 0 && (
            <p className="text-xs text-stone-400 mt-2">Niemand gefunden.</p>
          )}
        </div>
      </div>

      {/* ----------------------------- Was die Rollen im Einzelnen duerfen */}
      <AdminVorstandsrechte />
      <AdminVertreterrechte />
    </div>
  );
};

export default AdminRollenverwaltung;
