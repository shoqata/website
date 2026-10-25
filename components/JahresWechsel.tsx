import React, { useEffect, useMemo, useState } from 'react';
import { X, Check, Loader2, CalendarPlus, Users, Receipt, AlertTriangle, ArrowRight } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { UserProfile, Payment } from '../types';
import { hasUsableEmail } from '../lib/memberEmail';
import { useVereinsjahre, vereinsjahreNeuLaden } from '../lib/useVereinsjahre';
import { usePaket } from '../lib/usePaket';

// Der Jahreswechsel in drei Schritten:
//   1. das neue Jahr eroeffnen (mit Buchhaltung geschieht das beim
//      Jahresabschluss, ohne hier)
//   2. die Mitglieder auf den Stand bringen: Austritte, Neuanmeldungen,
//      Beitragsgruppe, Zustellweg -- bevor daraus Rechnungen werden
//   3. die Rechnungen erstellen und senden: der Rechnungsassistent, mit
//      dem neuen Jahr vorbelegt
//
// Gespeichert wird in Schritt 2 sofort je Aenderung. Ein Abbruch mitten im
// Assistenten verliert damit nichts, und die Rechnungen in Schritt 3 sehen
// den neuen Stand.

type Schritt = 'JAHR' | 'MITGLIEDER' | 'RECHNUNGEN';

const STATUS: [string, string][] = [['ACTIVE', 'Aktiv'], ['PENDING', 'Neu angemeldet'], ['INACTIVE', 'Ausgetreten']];
const STATUS_LEER: [string, string] = ['', 'Ohne Status'];
const GRUPPEN: [string, string][] = [['STANDARD', 'Standard'], ['KOSOVO', 'Kosovo'], ['REDUCED', 'Reduziert']];
const WEGE: [string, string][] = [['EMAIL', 'E-Mail'], ['POST', 'Post'], ['BOTH', 'Beides']];

const hinweise = (u: UserProfile): string[] => {
  const h: string[] = [];
  const weg = (u as any).invoiceDeliveryMethod || 'EMAIL';
  if (weg !== 'POST' && !hasUsableEmail(u)) h.push('E-Mail fehlt');
  if (weg !== 'EMAIL' && !(u.street && u.city)) h.push('Adresse fehlt');
  if (!u.neighborhoodId) h.push('ohne Nachbarschaft');
  return h;
};

const JahresWechsel: React.FC<{
  jahr: number; users: UserProfile[]; payments: Payment[];
  onRechnungen: (jahr: number) => void; onClose: () => void;
}> = ({ jahr, users, payments, onRechnungen, onClose }) => {
  const vj = useVereinsjahre();
  const paket = usePaket();
  const eroeffnet = vj.offen.includes(jahr) || vj.geschlossen.includes(jahr) || vj.aktuell >= jahr;
  const [schritt, setSchritt] = useState<Schritt>(eroeffnet ? 'MITGLIEDER' : 'JAHR');
  const [arbeitet, setArbeitet] = useState('');
  const [fehler, setFehler] = useState('');
  const [filter, setFilter] = useState<'HINWEIS' | 'NEU' | 'ALLE'>('HINWEIS');
  const [suche, setSuche] = useState('');
  // Eigene Aenderungen sofort zeigen, bis die Liste von oben nachkommt.
  const [lokal, setLokal] = useState<Record<string, Partial<UserProfile>>>({});
  const [nbNamen, setNbNamen] = useState<Record<string, string>>({});
  useEffect(() => {
    supabase.from('neighborhoods').select('id,name').then(({ data }) =>
      setNbNamen(Object.fromEntries(((data as any[]) ?? []).map(n => [n.id, n.name]))));
  }, []);
  const nachbarschaftName = (id?: string | null) => (id && nbNamen[id]) || 'ohne Nachbarschaft';

  const mitglieder = useMemo(() => users
    .map(u => ({ ...u, ...(lokal[u.id!] || {}) } as UserProfile)), [users, lokal]);

  // Wie der Rechnungsassistent: nur ACTIVE wird berechnet. Ein leerer
  // Status heisst also nicht "aktiv".
  const status = (u: UserProfile) => (u as any).membershipStatus || '';
  const aktive = mitglieder.filter(u => status(u) === 'ACTIVE');
  const schonBerechnet = new Set(payments.filter(p => p.type === 'FEE' && (p as any).billingYear === jahr).map(p => p.userId));

  const zahlen = {
    aktiv: aktive.length,
    neu: mitglieder.filter(u => status(u) === 'PENDING').length,
    hinweis: aktive.filter(u => hinweise(u).length > 0).length,
    ohneRechnung: aktive.filter(u => !schonBerechnet.has(u.id)).length,
  };

  const sichtbar = mitglieder.filter(u => {
    if (suche && !`${u.displayName || ''} ${u.firstName || ''} ${u.lastName || ''}`.toLowerCase().includes(suche.toLowerCase())) return false;
    if (filter === 'NEU') return status(u) === 'PENDING';
    if (filter === 'HINWEIS') return status(u) !== 'INACTIVE' && (hinweise(u).length > 0 || status(u) !== 'ACTIVE');
    return true;
  });

  const eroeffnen = async () => {
    setArbeitet('jahr'); setFehler('');
    const { error } = await supabase.rpc('vereinsjahr_eroeffnen', { p_jahr: jahr });
    if (error) { setArbeitet(''); setFehler(error.message); return; }
    await vereinsjahreNeuLaden();
    setArbeitet(''); setSchritt('MITGLIEDER');
  };

  const aendern = async (u: UserProfile, feld: string, wert: string) => {
    setArbeitet(u.id! + feld); setFehler('');
    const { data, error } = await supabase.from('users').update({ [feld]: wert }).eq('id', u.id!).select('id');
    setArbeitet('');
    if (error || !data?.length) { setFehler(error?.message || 'Nicht gespeichert — fehlende Berechtigung?'); return; }
    setLokal(l => ({ ...l, [u.id!]: { ...(l[u.id!] || {}), [feld]: wert } }));
  };

  const SCHRITTE: [Schritt, string, any][] = [
    ['JAHR', `${jahr} eröffnen`, CalendarPlus], ['MITGLIEDER', 'Mitglieder aktualisieren', Users],
    ['RECHNUNGEN', 'Rechnungen erstellen und senden', Receipt],
  ];
  const auswahl = 'p-1.5 bg-white border border-stone-200 rounded-lg text-xs font-bold';

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4 bg-stone-900/80 backdrop-blur-md">
      <div className="bg-white w-full max-w-5xl rounded-[2rem] shadow-2xl flex flex-col max-h-[92dvh] overflow-hidden">
        <div className="p-6 border-b border-stone-100 flex justify-between items-start gap-4">
          <div>
            <p className="text-[10px] font-bold uppercase tracking-widest text-primary">Jahreswechsel</p>
            <h3 className="text-xl font-bold text-stone-900">Ins Vereinsjahr {jahr}</h3>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-stone-100 rounded-full"><X size={20} /></button>
        </div>

        <div className="px-6 pt-4 flex gap-2 flex-wrap">
          {SCHRITTE.map(([k, l, I], i) => {
            const fertig = (k === 'JAHR' && eroeffnet) || (k === 'MITGLIEDER' && schritt === 'RECHNUNGEN');
            return (
              <button key={k} onClick={() => (k !== 'JAHR' ? eroeffnet : true) && setSchritt(k)}
                className={`flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-bold ${
                  schritt === k ? 'bg-stone-900 text-white' : fertig ? 'bg-emerald-50 text-emerald-800' : 'bg-stone-100 text-stone-500'}`}>
                {fertig ? <Check size={13} /> : <I size={13} />} {i + 1}. {l}
              </button>
            );
          })}
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          {fehler && (
            <p className="text-xs text-red-700 bg-red-50 rounded-xl p-3 flex gap-2"><AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}</p>
          )}

          {schritt === 'JAHR' && (
            <div className="space-y-4 max-w-xl">
              {eroeffnet ? (
                <p className="text-sm text-emerald-800 bg-emerald-50 rounded-xl p-4 flex gap-2"><Check size={16} /> {jahr} ist eröffnet und überall auswählbar.</p>
              ) : (
                <>
                  <p className="text-sm text-stone-600 leading-relaxed">
                    Nach dem Eröffnen ist {jahr} in der ganzen Verwaltung, im Vorstand und bei den Vertretern das
                    laufende Jahr. Frühere Jahre bleiben auswählbar.
                    {paket !== 'LIGHT' && ' Mit Buchhaltung eröffnet der Jahresabschluss das neue Jahr; ohne Abschluss geht es hier.'}
                  </p>
                  <button onClick={eroeffnen} disabled={!!arbeitet}
                    className="px-5 py-3 bg-primary text-white rounded-xl font-bold text-sm flex items-center gap-2 disabled:opacity-50">
                    {arbeitet === 'jahr' ? <Loader2 size={15} className="animate-spin" /> : <CalendarPlus size={15} />} Vereinsjahr {jahr} eröffnen
                  </button>
                </>
              )}
            </div>
          )}

          {schritt === 'MITGLIEDER' && (
            <>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {[['Aktiv', zahlen.aktiv, 'text-stone-900'], ['Neu angemeldet', zahlen.neu, 'text-blue-700'],
                  ['Aktiv mit Hinweis', zahlen.hinweis, 'text-amber-700'], [`Noch ohne Rechnung ${jahr}`, zahlen.ohneRechnung, 'text-stone-900']]
                  .map(([l, n, f]) => (
                  <div key={l as string} className="bg-stone-50 rounded-2xl p-4">
                    <p className={`text-2xl font-bold ${f}`}>{n as number}</p>
                    <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mt-1">{l as string}</p>
                  </div>
                ))}
              </div>
              <p className="text-xs text-stone-500 leading-relaxed">
                Wer ausgetreten ist, auf „Ausgetreten“ stellen — er bekommt keine Rechnung {jahr}. Neuanmeldungen auf
                „Aktiv“ setzen, dann sind sie dabei. Jede Änderung wird sofort gespeichert.
              </p>
              <div className="flex gap-2 flex-wrap items-center">
                {([['HINWEIS', 'Zu prüfen'], ['NEU', 'Neuanmeldungen'], ['ALLE', 'Alle']] as const).map(([k, l]) => (
                  <button key={k} onClick={() => setFilter(k)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold ${filter === k ? 'bg-stone-900 text-white' : 'bg-stone-100 text-stone-500'}`}>{l}</button>
                ))}
                <input value={suche} onChange={e => setSuche(e.target.value)} placeholder="Suchen …"
                  className="ml-auto p-2 border border-stone-200 rounded-lg text-xs w-48" />
              </div>
              <div className="border border-stone-100 rounded-2xl divide-y divide-stone-50">
                {sichtbar.slice(0, 300).map(u => {
                  const h = hinweise(u);
                  return (
                    <div key={u.id} className={`p-3 flex items-center gap-3 flex-wrap ${status(u) === 'INACTIVE' ? 'opacity-50' : ''}`}>
                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-bold text-stone-900 truncate">{u.displayName || `${u.firstName || ''} ${u.lastName || ''}`}</p>
                        <p className="text-[11px] text-stone-400 truncate">
                          {nachbarschaftName(u.neighborhoodId)}
                          {h.length > 0 && <span className="text-amber-700 font-bold"> · {h.join(' · ')}</span>}
                        </p>
                      </div>
                      <select value={status(u)} onChange={e => aendern(u, 'membershipStatus', e.target.value)} disabled={!!arbeitet} className={auswahl}>
                        {(status(u) ? STATUS : [STATUS_LEER, ...STATUS]).map(([k, l]) => <option key={k} value={k}>{l}</option>)}
                      </select>
                      <select value={(u as any).billingGroup || 'STANDARD'} onChange={e => aendern(u, 'billingGroup', e.target.value)} disabled={!!arbeitet} className={auswahl}>
                        {GRUPPEN.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
                      </select>
                      <select value={(u as any).invoiceDeliveryMethod || 'EMAIL'} onChange={e => aendern(u, 'invoiceDeliveryMethod', e.target.value)} disabled={!!arbeitet} className={auswahl}>
                        {WEGE.map(([k, l]) => <option key={k} value={k}>{l}</option>)}
                      </select>
                      {arbeitet.startsWith(u.id!) && <Loader2 size={14} className="animate-spin text-stone-400" />}
                    </div>
                  );
                })}
                {sichtbar.length === 0 && (
                  <p className="p-6 text-center text-sm text-stone-400 italic">
                    {filter === 'HINWEIS' ? 'Nichts zu prüfen — alle Angaben für den Versand sind da.' : 'Keine Mitglieder.'}
                  </p>
                )}
                {sichtbar.length > 300 && <p className="p-3 text-xs text-stone-400">Die ersten 300 — mit der Suche eingrenzen.</p>}
              </div>
              <p className="text-[11px] text-stone-400">Adressen und E-Mails ergänzen Sie im Mitgliederprofil (Mitglieder).</p>
            </>
          )}

          {schritt === 'RECHNUNGEN' && (
            <div className="space-y-4 max-w-xl">
              <p className="text-sm text-stone-600 leading-relaxed">
                {zahlen.ohneRechnung > 0
                  ? <><strong>{zahlen.ohneRechnung}</strong> aktive Mitglieder haben noch keine Beitragsrechnung {jahr}. </>
                  : <>Alle aktiven Mitglieder haben schon eine Rechnung {jahr}. </>}
                Der Rechnungsassistent erstellt sie, zeigt vor dem Senden die Übersicht und verschickt sie je nach
                Zustellweg per E-Mail, per Post oder beides.
              </p>
              {zahlen.hinweis > 0 && (
                <p className="text-xs text-amber-800 bg-amber-50 rounded-xl p-3">
                  {zahlen.hinweis} aktive Mitglieder haben noch einen Hinweis (E-Mail oder Adresse fehlt). Sie lassen sich
                  trotzdem berechnen; der Versand an sie scheitert, bis die Angabe da ist.
                </p>
              )}
              <button onClick={() => onRechnungen(jahr)}
                className="px-5 py-3 bg-primary text-white rounded-xl font-bold text-sm flex items-center gap-2">
                <Receipt size={15} /> Rechnungsassistent {jahr} öffnen
              </button>
            </div>
          )}
        </div>

        <div className="p-5 border-t border-stone-100 flex justify-between">
          <button onClick={onClose} className="px-5 py-2.5 rounded-xl font-bold text-sm text-stone-500 hover:bg-stone-100">Später weiter</button>
          {schritt === 'MITGLIEDER' && (
            <button onClick={() => setSchritt('RECHNUNGEN')}
              className="px-5 py-2.5 bg-stone-900 text-white rounded-xl font-bold text-sm flex items-center gap-2">
              Weiter zu den Rechnungen <ArrowRight size={15} />
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default JahresWechsel;
