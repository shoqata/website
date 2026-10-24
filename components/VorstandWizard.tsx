import React, { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  X, UserPlus, Receipt, ArrowRight, ArrowLeft, Loader2, Check, AlertTriangle,
  Mail, Home, Search,
} from 'lucide-react';
import {
  mitgliedErfassen, rechnungErfassen, mitgliedPruefen, rechnungPruefen,
  zustellweg, zahlungsart, mitgliedMitAdresse,
} from '../lib/erfassen';
import { useFeedback } from '../context/FeedbackContext';
import type { UserProfile, Neighborhood } from '../types';

// Mitglied erfassen und Rechnung stellen -- fuer den Vorstand.
//
// Warum eigens und nicht ueber den Adminbereich: dorthin kommt ein
// Vorstandsmitglied nicht. Gemessen in App.tsx:
//
//   isAdmin = role === ADMIN || role === SUPER_ADMIN || email in ADMIN_EMAILS
//   /admin  = <ProtectedRoute adminOnly>  ->  BOARD wird aufs Dashboard
//             zurueckgeschickt
//
// Die Datenbank sieht es umgekehrt: is_member_manager() schliesst BOARD
// ausdruecklich ein, und ein Schreibversuch im Namen eines
// Vorstandsmitglieds legt Mitglied und Rechnung anstandslos an. Der
// Server erlaubt es also seit immer, nur das UI liess niemanden hin.
//
// Dem Vorstand deshalb den ganzen Adminbereich zu oeffnen waere falsch:
// dort stehen Domain, Module, Jahresgebuehr und die Rollenvergabe. Zwei
// Aufgaben brauchen zwei Formulare, nicht dreissig Reiter.
//
// Schrittweise, weil es selten gemacht wird. Wer dreimal im Jahr ein
// Mitglied erfasst, kennt kein Formular mit vierzehn Feldern -- er
// braucht eine Frage nach der anderen und am Ende die Gelegenheit,
// alles noch einmal zu lesen.

type Props = {
  mitglieder: UserProfile[];
  nachbarschaften: Neighborhood[];
  onClose: () => void;
  onFertig?: () => void;
};

const feld = 'w-full p-3 bg-white border border-stone-200 rounded-xl outline-none text-sm focus:border-stone-400 transition-colors';
const marke = 'text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1.5';

const VorstandWizard: React.FC<Props> = ({ mitglieder, nachbarschaften, onClose, onFertig }) => {
  const { showAlert } = useFeedback();
  const [weg, setWeg] = useState<'WAHL' | 'MITGLIED' | 'RECHNUNG'>('WAHL');
  const [schritt, setSchritt] = useState(1);
  const [arbeitet, setArbeitet] = useState(false);

  const jahr = new Date().getFullYear();

  // ------------------------------------------------------- Mitglied
  const [m, setM] = useState({
    firstName: '', lastName: '', neighborhoodId: '',
    email: '', phone: '', street: '', zip: '', city: '',
    country: 'Switzerland', birthdate: '',
    membershipCategory: '', billingGroup: '',
    invoiceDeliveryMethod: '' as '' | 'EMAIL' | 'POST' | 'BOTH',
  });

  // Kategorien und Beitragsgruppen aus den Daten, nicht erfunden --
  // gemessen bei Koretini: STANDARD 329, KOSOVO 3. Eine feste Liste
  // haette dem neuen Mitglied eine Gruppe gegeben, die der Verein nicht
  // benutzt, und damit einen falschen Beitrag.
  const gruppen = useMemo(() => [...new Set(
    mitglieder.map(x => String((x as any).billingGroup ?? '').trim()).filter(Boolean))].sort(),
    [mitglieder]);
  const kategorien = useMemo(() => [...new Set(
    mitglieder.map(x => String((x as any).membershipCategory ?? '').trim()).filter(Boolean))].sort(),
    [mitglieder]);

  // ------------------------------------------------------- Rechnung
  // Willkommensnachricht. Vorgabe AN -- das ist der haeufige Fall bei
  // einem neuen Mitglied. Wer einen Altbestand nachtraegt, schaltet es
  // aus; darum ein sichtbarer Schalter und keine stille Vorgabe.
  const [willkommen, setWillkommen] = useState(true);
  // Wer die eingegebene Adresse schon hat. users.email ist global
  // eindeutig -- ohne diesen Hinweis bekam der Erfasser erst beim
  // Speichern "duplicate key value violates unique constraint
  // users_email_key" und wusste nicht, wen er gerade doppelt anlegt.
  const [belegtVon, setBelegtVon] =
    useState<{ id: string; displayName: string } | null>(null);
  const [pruefeAdresse, setPruefeAdresse] = useState(false);

  const [suche, setSuche] = useState('');
  const [fuer, setFuer] = useState<UserProfile | null>(null);
  const [r, setR] = useState({
    amount: '', description: `Mitgliederbeitrag ${jahr}`,
    dueDate: new Date(new Date().setMonth(new Date().getMonth() + 1))
      .toISOString().slice(0, 10),
    billingYear: jahr,
  });

  const treffer = useMemo(() => {
    const s = suche.toLowerCase().trim();
    if (!s) return [];
    return mitglieder
      .filter(x => (x.displayName || '').toLowerCase().includes(s)
                || (x.email || '').toLowerCase().includes(s))
      .slice(0, 8);
  }, [suche, mitglieder]);

  const nbName = (id?: string) =>
    nachbarschaften.find(n => n.id === id)?.name || id || '—';

  // ------------------------------------------------------- Speichern
  const mitgliedSpeichern = async (dannRechnung: boolean) => {
    const fehlt = mitgliedPruefen(m as any);
    if (fehlt) { showAlert({ type: 'error', message: hinweis(fehlt) }); return; }
    setArbeitet(true);
    try {
      const id = await mitgliedErfassen({
        ...m,
        invoiceDeliveryMethod: m.invoiceDeliveryMethod || undefined,
        // Ohne brauchbare Adresse geht ohnehin nichts hinaus; die
        // Funktion in der Datenbank prueft das ebenfalls. Hier gar nicht
        // erst zu fragen waere besser als eine Zusage, die nicht haelt.
        willkommen: willkommen && !!m.email.trim(),
      } as any);
      showAlert({ type: 'success', message: `${m.firstName} ${m.lastName} ist erfasst.` });
      onFertig?.();
      if (dannRechnung) {
        // Der natuerliche naechste Schritt: wer ein Mitglied erfasst,
        // will ihm meist gleich den Beitrag verrechnen. Es dafuer erst
        // suchen zu muessen, waere unnoetige Arbeit -- und das neue
        // Mitglied steht in der uebergebenen Liste noch nicht drin.
        setFuer({ id, ...(m as any), displayName: `${m.firstName} ${m.lastName}` } as any);
        setWeg('RECHNUNG'); setSchritt(2);
      } else {
        onClose();
      }
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setArbeitet(false); }
  };

  const rechnungSpeichern = async () => {
    const eingabe = {
      mitglied: fuer as any,
      amount: Number(String(r.amount).replace(',', '.')),
      description: r.description,
      dueDate: r.dueDate,
      billingYear: Number(r.billingYear),
    };
    const fehlt = rechnungPruefen(eingabe as any);
    if (fehlt) { showAlert({ type: 'error', message: hinweis(fehlt) }); return; }
    setArbeitet(true);
    try {
      const { invoiceNumber, deliveryMethod } = await rechnungErfassen(eingabe as any);
      // Die Meldung sagt den Zustellweg mit. Er ergibt sich aus dem
      // Mitglied und nicht aus einer Vorgabe -- wer das nicht sieht,
      // wartet auf eine Mail, die per Post geht.
      showAlert({
        type: 'success',
        message: deliveryMethod === 'POST'
          ? `${invoiceNumber} erstellt. Sie geht per Post — es liegt keine brauchbare E-Mail-Adresse vor oder das Mitglied möchte Post.`
          : deliveryMethod === 'BOTH'
            ? `${invoiceNumber} erstellt, Zustellung per E-Mail und per Post (Wunsch des Mitglieds).`
            : `${invoiceNumber} erstellt, Zustellung per E-Mail. Verschickt wird erst im Postausgang.`,
      });
      onFertig?.();
      onClose();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || '?' });
    } finally { setArbeitet(false); }
  };

  const hinweis = (schluessel: string) => ({
    name: 'Vor- und Nachname werden gebraucht.',
    neighborhood: 'Bitte eine Nachbarschaft wählen — ohne sie erscheint das Mitglied in keiner Betreuungsliste.',
    email: 'Die E-Mail-Adresse sieht nicht nach einer Adresse aus. Sie darf auch leer bleiben.',
    member: 'Bitte ein Mitglied wählen.',
    amount: 'Bitte einen Betrag über null eintragen.',
    description: 'Die Bezeichnung steht auf der Rechnung und im Journal — ohne sie weiss niemand, wofür gezahlt wurde.',
    due: 'Bitte ein Fälligkeitsdatum wählen.',
    year: 'Bitte ein Beitragsjahr angeben.',
  } as Record<string, string>)[schluessel] ?? schluessel;

  // ------------------------------------------------------- Darstellung
  const Kopf = ({ titel, unter }: { titel: string; unter?: string }) => (
    <div className="p-6 border-b border-stone-100 bg-stone-50 flex justify-between items-start gap-4">
      <div>
        <h3 className="font-bold text-lg text-stone-900">{titel}</h3>
        {unter && <p className="text-xs text-stone-500 mt-0.5">{unter}</p>}
      </div>
      <button onClick={onClose} className="p-2 hover:bg-stone-200 rounded-full text-stone-500 shrink-0">
        <X size={18} />
      </button>
    </div>
  );

  const Fuss = ({ zurueck, weiter, weiterText, sperre }: {
    zurueck?: () => void; weiter: () => void; weiterText: string; sperre?: boolean;
  }) => (
    <div className="p-6 border-t border-stone-100 bg-stone-50 flex gap-3">
      <button onClick={zurueck ?? onClose}
        className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold text-sm flex items-center justify-center gap-2">
        {zurueck ? <><ArrowLeft size={15} /> Zurück</> : 'Abbrechen'}
      </button>
      <button onClick={weiter} disabled={arbeitet || sperre}
        className="flex-[2] py-3 bg-stone-900 text-white rounded-xl font-bold text-sm shadow-lg flex items-center justify-center gap-2 disabled:opacity-40">
        {arbeitet ? <Loader2 size={15} className="animate-spin" /> : null}
        {weiterText}
      </button>
    </div>
  );

  return (
    <div className="fixed inset-0 z-[500] flex items-center justify-center p-6 bg-stone-900/70 backdrop-blur-sm">
      <motion.div initial={{ scale: 0.96, opacity: 0 }} animate={{ scale: 1, opacity: 1 }}
        className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">

        {/* ------------------------------------------------------ Wahl */}
        {weg === 'WAHL' && (
          <>
            <Kopf titel="Was möchten Sie erfassen?" />
            <div className="p-8 space-y-3">
              <button onClick={() => { setWeg('MITGLIED'); setSchritt(1); }}
                className="w-full p-5 text-left bg-white border border-stone-200 rounded-2xl hover:border-stone-400 hover:bg-stone-50 transition-colors flex items-center gap-4">
                <div className="w-10 h-10 rounded-xl bg-stone-900 text-white flex items-center justify-center shrink-0">
                  <UserPlus size={18} />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-900">Neues Mitglied erfassen</p>
                  <p className="text-[11px] text-stone-500 mt-0.5">
                    Name, Nachbarschaft, Erreichbarkeit — der Beitrag kann direkt danach folgen.
                  </p>
                </div>
                <ArrowRight size={16} className="text-stone-300 ml-auto shrink-0" />
              </button>

              <button onClick={() => { setWeg('RECHNUNG'); setSchritt(1); }}
                className="w-full p-5 text-left bg-white border border-stone-200 rounded-2xl hover:border-stone-400 hover:bg-stone-50 transition-colors flex items-center gap-4">
                <div className="w-10 h-10 rounded-xl bg-stone-900 text-white flex items-center justify-center shrink-0">
                  <Receipt size={18} />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-sm text-stone-900">Neue Rechnung erstellen</p>
                  <p className="text-[11px] text-stone-500 mt-0.5">
                    Für ein bestehendes Mitglied. Verschickt wird nichts — das geschieht im Postausgang.
                  </p>
                </div>
                <ArrowRight size={16} className="text-stone-300 ml-auto shrink-0" />
              </button>
            </div>
          </>
        )}

        {/* -------------------------------------------------- Mitglied */}
        {weg === 'MITGLIED' && schritt === 1 && (
          <>
            <Kopf titel="Wer ist es?" unter="Schritt 1 von 3" />
            <div className="p-8 space-y-4 overflow-y-auto">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={marke}>Vorname</label>
                  <input value={m.firstName} autoFocus
                    onChange={e => setM({ ...m, firstName: e.target.value })} className={feld} />
                </div>
                <div>
                  <label className={marke}>Nachname</label>
                  <input value={m.lastName}
                    onChange={e => setM({ ...m, lastName: e.target.value })} className={feld} />
                </div>
              </div>
              <div>
                <label className={marke}>Nachbarschaft</label>
                <select value={m.neighborhoodId}
                  onChange={e => setM({ ...m, neighborhoodId: e.target.value })} className={feld}>
                  <option value="">bitte wählen</option>
                  {[...nachbarschaften].sort((a, b) => (a.name || '').localeCompare(b.name || ''))
                    .map(n => <option key={n.id} value={n.id}>{n.name}</option>)}
                </select>
                <p className="text-[10px] text-stone-400 mt-1">
                  Ohne Nachbarschaft erscheint das Mitglied in keiner Betreuungsliste.
                </p>
              </div>
              <div>
                <label className={marke}>Geburtsdatum (wenn bekannt)</label>
                <input type="date" value={m.birthdate}
                  onChange={e => setM({ ...m, birthdate: e.target.value })} className={feld} />
              </div>
            </div>
            <Fuss weiter={() => setSchritt(2)} weiterText="Weiter"
              sperre={!m.firstName.trim() || !m.lastName.trim() || !m.neighborhoodId} />
          </>
        )}

        {weg === 'MITGLIED' && schritt === 2 && (
          <>
            <Kopf titel="Wie ist er erreichbar?" unter="Schritt 2 von 3 — alles freiwillig" />
            <div className="p-8 space-y-4 overflow-y-auto">
              <div>
                <label className={marke}>E-Mail</label>
                <input value={m.email}
                  onChange={e => { setM({ ...m, email: e.target.value }); setBelegtVon(null); }}
                  className={feld} placeholder="kann leer bleiben" />
                <p className="text-[10px] text-stone-400 mt-1">
                  Ohne Adresse gehen Rechnungen automatisch per Post.
                </p>
                {belegtVon && (
                  <div className="mt-2 p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900 leading-relaxed">
                    <strong>{belegtVon.displayName}</strong> hat diese Adresse bereits.
                    Jede Adresse darf nur einmal vorkommen. Bitte die bestehende
                    Person bearbeiten oder eine andere Adresse eintragen — leer
                    lassen geht auch, dann läuft alles über Post.
                  </div>
                )}
              </div>
              <div>
                <label className={marke}>Telefon</label>
                <input value={m.phone} onChange={e => setM({ ...m, phone: e.target.value })} className={feld} />
              </div>
              <div>
                <label className={marke}>Strasse</label>
                <input value={m.street} onChange={e => setM({ ...m, street: e.target.value })} className={feld} />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className={marke}>PLZ</label>
                  <input value={m.zip} onChange={e => setM({ ...m, zip: e.target.value })} className={feld} />
                </div>
                <div className="col-span-2">
                  <label className={marke}>Ort</label>
                  <input value={m.city} onChange={e => setM({ ...m, city: e.target.value })} className={feld} />
                </div>
              </div>
            </div>
            <Fuss zurueck={() => setSchritt(1)} weiter={async () => {
              // Vor dem naechsten Schritt nachsehen, nicht erst beim
              // Speichern. Wer zwei Schritte weiter eine Meldung ueber
              // eine Nebenbedingung bekommt, hat die Eingabe schon
              // vergessen.
              setBelegtVon(null);
              const adresse = m.email.trim();
              if (adresse) {
                setPruefeAdresse(true);
                try {
                  const da = await mitgliedMitAdresse(adresse);
                  if (da) { setBelegtVon(da); setPruefeAdresse(false); return; }
                } catch { /* dann traegt die Meldung beim Speichern */ }
                setPruefeAdresse(false);
              }
              setSchritt(3);
            }} weiterText={pruefeAdresse ? 'Prüft …' : 'Weiter'} sperre={pruefeAdresse} />
          </>
        )}

        {weg === 'MITGLIED' && schritt === 3 && (
          <>
            <Kopf titel="Beitrag und Zustellung" unter="Schritt 3 von 3" />
            <div className="p-8 space-y-4 overflow-y-auto">
              {gruppen.length > 0 && (
                <div>
                  <label className={marke}>Beitragsgruppe</label>
                  <select value={m.billingGroup}
                    onChange={e => setM({ ...m, billingGroup: e.target.value })} className={feld}>
                    <option value="">keine Angabe</option>
                    {gruppen.map(g => <option key={g} value={g}>{g}</option>)}
                  </select>
                  <p className="text-[10px] text-stone-400 mt-1">Bestimmt, was dieses Mitglied zahlt.</p>
                </div>
              )}
              {kategorien.length > 0 && (
                <div>
                  <label className={marke}>Kategorie</label>
                  <select value={m.membershipCategory}
                    onChange={e => setM({ ...m, membershipCategory: e.target.value })} className={feld}>
                    <option value="">keine Angabe</option>
                    {kategorien.map(k => <option key={k} value={k}>{k}</option>)}
                  </select>
                </div>
              )}
              <div>
                <label className={marke}>Rechnungsweg</label>
                <div className="flex gap-1 bg-stone-100 p-1 rounded-xl">
                  {([['', 'automatisch'], ['EMAIL', 'E-Mail'], ['POST', 'Post']] as const).map(([w, n]) => (
                    <button key={w || 'auto'} type="button"
                      onClick={() => setM({ ...m, invoiceDeliveryMethod: w as any })}
                      className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${
                        m.invoiceDeliveryMethod === w ? 'bg-stone-900 text-white' : 'text-stone-500'}`}>
                      {n}
                    </button>
                  ))}
                </div>
                <p className="text-[10px] text-stone-400 mt-1">
                  „Automatisch" heisst: E-Mail, wenn eine brauchbare Adresse vorliegt, sonst Post.
                </p>
              </div>

              {/* Die Begruessung. Steht sichtbar hier und nicht still im
                  Hintergrund: eine Nachricht an ein Mitglied ist nichts,
                  was ohne Wissen des Erfassers hinausgehen soll. */}
              <label className={`flex items-start gap-3 p-4 rounded-xl border transition-colors ${
                m.email.trim() ? 'bg-white border-stone-200 cursor-pointer hover:border-stone-400'
                               : 'bg-stone-50 border-stone-100'}`}>
                <input type="checkbox" checked={willkommen && !!m.email.trim()}
                  disabled={!m.email.trim()}
                  onChange={e => setWillkommen(e.target.checked)}
                  className="mt-0.5 w-4 h-4 accent-stone-900 shrink-0" />
                <span className="text-xs leading-relaxed">
                  <span className="font-bold text-stone-900 block">Willkommensnachricht senden</span>
                  <span className="text-stone-500">
                    {m.email.trim()
                      ? 'Zweisprachig, Albanisch zuerst. Sie wird in den Postausgang gelegt und von dort verschickt.'
                      : 'Ohne E-Mail-Adresse nicht möglich — die Aufnahme geht trotzdem durch.'}
                  </span>
                </span>
              </label>

              {/* Noch einmal lesen, bevor es steht. */}
              <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl space-y-1 text-xs">
                <p className="font-bold text-stone-900">{m.firstName} {m.lastName}</p>
                <p className="text-stone-500 flex items-center gap-1.5">
                  <Home size={11} /> {nbName(m.neighborhoodId)}
                </p>
                <p className="text-stone-500 flex items-center gap-1.5">
                  <Mail size={11} /> {zustellweg(m as any) === 'POST'
                    ? 'Rechnungen gehen per Post' : 'Rechnungen gehen per E-Mail'}
                  {' · '}{zahlungsart(m as any) === 'QR_BILL' ? 'QR-Rechnung' : 'Überweisung'}
                </p>
              </div>
            </div>
            <div className="p-6 border-t border-stone-100 bg-stone-50 flex flex-col gap-2">
              <div className="flex gap-3">
                <button onClick={() => setSchritt(2)}
                  className="flex-1 py-3 bg-stone-200 text-stone-600 rounded-xl font-bold text-sm flex items-center justify-center gap-2">
                  <ArrowLeft size={15} /> Zurück
                </button>
                <button onClick={() => mitgliedSpeichern(true)} disabled={arbeitet}
                  className="flex-[2] py-3 bg-stone-900 text-white rounded-xl font-bold text-sm shadow-lg flex items-center justify-center gap-2 disabled:opacity-40">
                  {arbeitet ? <Loader2 size={15} className="animate-spin" />
                            : <Check size={15} />} Erfassen und Beitrag verrechnen
                </button>
              </div>
              <button onClick={() => mitgliedSpeichern(false)} disabled={arbeitet}
                className="py-2 text-xs font-bold text-stone-400 hover:text-stone-700 transition-colors disabled:opacity-40">
                Nur erfassen, keine Rechnung
              </button>
            </div>
          </>
        )}

        {/* -------------------------------------------------- Rechnung */}
        {weg === 'RECHNUNG' && schritt === 1 && (
          <>
            <Kopf titel="Für wen?" unter="Schritt 1 von 2" />
            <div className="p-8 space-y-3 overflow-y-auto">
              <div className="relative">
                <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" />
                <input value={suche} autoFocus onChange={e => setSuche(e.target.value)}
                  placeholder="Name oder E-Mail" className={feld + ' pl-9'} />
              </div>
              {treffer.map(x => (
                <button key={x.id} onClick={() => { setFuer(x); setSchritt(2); }}
                  className="w-full p-4 text-left bg-white border border-stone-200 rounded-xl hover:border-stone-400 transition-colors flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-bold text-sm text-stone-900 truncate">{x.displayName}</p>
                    <p className="text-[11px] text-stone-500 truncate">
                      {nbName(x.neighborhoodId)}
                      {' · '}{zustellweg(x) === 'POST' ? 'Post' : 'E-Mail'}
                    </p>
                  </div>
                  <ArrowRight size={15} className="text-stone-300 shrink-0" />
                </button>
              ))}
              {suche.trim() && treffer.length === 0 && (
                <p className="text-sm text-stone-400 italic p-4 text-center">Niemand gefunden.</p>
              )}
              {!suche.trim() && (
                <p className="text-xs text-stone-400 p-2">
                  Bei {mitglieder.length} Mitgliedern wäre eine ganze Liste unübersichtlich — bitte suchen.
                </p>
              )}
            </div>
            <Fuss weiter={() => { /* ohne Auswahl kein Weiter */ }} weiterText="Weiter" sperre />
          </>
        )}

        {weg === 'RECHNUNG' && schritt === 2 && fuer && (
          <>
            <Kopf titel="Was wird verrechnet?" unter={`Schritt 2 von 2 · ${fuer.displayName}`} />
            <div className="p-8 space-y-4 overflow-y-auto">
              <div>
                <label className={marke}>Bezeichnung</label>
                <input value={r.description}
                  onChange={e => setR({ ...r, description: e.target.value })} className={feld} />
                <p className="text-[10px] text-stone-400 mt-1">
                  Steht auf der Rechnung und im Journal.
                </p>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={marke}>Betrag</label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-bold text-stone-400">CHF</span>
                    <input type="text" inputMode="decimal" value={r.amount} autoFocus
                      onChange={e => setR({ ...r, amount: e.target.value })}
                      className={feld + ' pl-12 font-mono font-bold'} />
                  </div>
                </div>
                <div>
                  <label className={marke}>Beitragsjahr</label>
                  <input type="number" value={r.billingYear}
                    onChange={e => setR({ ...r, billingYear: Number(e.target.value) })}
                    className={feld + ' font-mono'} />
                </div>
              </div>
              <div>
                <label className={marke}>Fällig am</label>
                <input type="date" value={r.dueDate}
                  onChange={e => setR({ ...r, dueDate: e.target.value })} className={feld} />
              </div>

              <div className="p-4 bg-stone-50 border border-stone-200 rounded-xl text-xs space-y-1">
                <p className="text-stone-500 flex items-center gap-1.5">
                  <Mail size={11} />
                  {zustellweg(fuer) === 'POST'
                    ? 'Geht per Post — keine brauchbare E-Mail-Adresse oder so gewünscht'
                    : `Geht per E-Mail an ${fuer.email}`}
                </p>
                <p className="text-stone-500">
                  {zahlungsart(fuer) === 'QR_BILL' ? 'Mit QR-Rechnung' : 'Mit Überweisungsangaben'}
                </p>
                <p className="text-stone-400 flex items-start gap-1.5 pt-1">
                  <AlertTriangle size={11} className="mt-0.5 shrink-0" />
                  Erstellen verschickt nichts. Der Versand geschieht im Postausgang.
                </p>
              </div>
            </div>
            <Fuss zurueck={() => { setFuer(null); setSchritt(1); }}
              weiter={rechnungSpeichern} weiterText="Rechnung erstellen" />
          </>
        )}
      </motion.div>
    </div>
  );
};

export default VorstandWizard;
