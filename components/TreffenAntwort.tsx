import React, { useEffect, useState } from 'react';
import {
  CalendarDays, MapPin, Ticket, Check, X, Plus, Trash2, Loader2, Users, Clock,
} from 'lucide-react';

// Die Antwort auf eine Einladung: zusagen oder absagen, und wer mitkommt.
//
// Ein Formular, zwei Wege hinein -- der Gastverein ueber seinen Link, der
// Verein der Plattform ueber seinen Admin. Zwei Nachbildungen desselben
// Formulars liefen frueher oder spaeter auseinander, und dann hiesse eine
// Spalte beim einen "Rolle" und beim anderen "Funktion".
//
// Die Kopfzahl wird NICHT eingegeben. Sie ergibt sich aus der Liste --
// zwei Zahlen, die dasselbe meinen, laufen auseinander, und am Ende weiss
// die Kueche nicht, fuer wie viele sie kochen soll.

export type Person = { name: string; rolle: 'LEITUNG' | 'TEILNEHMER'; bemerkung?: string };

const tag = (s?: string | null) =>
  s ? new Date(s).toLocaleDateString('de-CH', { day: '2-digit', month: 'long', year: 'numeric' }) : '';
const zeit = (s?: string | null) => (s ? String(s).slice(0, 5) : '');

const TreffenAntwort: React.FC<{
  daten: any;
  speichern: (zugesagt: boolean, bemerkung: string, leute: Person[]) => Promise<void>;
  dunkel?: boolean;
}> = ({ daten, speichern, dunkel }) => {
  const t = daten.treffen;
  const [zugesagt, setZugesagt] = useState<boolean | null>(daten.zugesagt);
  const [bemerkung, setBemerkung] = useState<string>(daten.bemerkung || '');
  const [leute, setLeute] = useState<Person[]>(
    (daten.delegation || []).map((p: any) => ({ name: p.name, rolle: p.rolle, bemerkung: p.bemerkung || '' }))
  );
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState('');
  const [fertig, setFertig] = useState(false);

  useEffect(() => { setFertig(false); }, [zugesagt, leute, bemerkung]);

  const schlussVorbei = t.anmeldeschluss
    ? new Date(t.anmeldeschluss) < new Date(new Date().toDateString()) : false;

  const sichern = async () => {
    if (zugesagt === null) { setFehler('Bitte zuerst zu- oder absagen.'); return; }
    setArbeitet(true); setFehler('');
    try {
      await speichern(zugesagt, bemerkung, leute.filter(p => p.name.trim()));
      setFertig(true);
    } catch (e: any) {
      setFehler(e?.message || 'Konnte nicht gespeichert werden.');
    } finally { setArbeitet(false); }
  };

  const k = dunkel
    ? { karte: 'bg-white/5 border-white/10', text: 'text-white', weich: 'text-stone-400',
        feld: 'bg-white/5 border-white/15 text-white placeholder:text-stone-500' }
    : { karte: 'bg-white border-stone-100', text: 'text-stone-900', weich: 'text-stone-500',
        feld: 'bg-white border-stone-200 text-stone-900' };

  return (
    <div className="space-y-5">
      {/* Worum es geht */}
      <div className={`${k.karte} border rounded-[2rem] p-7`}>
        <h2 className={`text-xl font-bold ${k.text} mb-3`}>{t.titel}</h2>
        <div className={`flex flex-wrap gap-x-6 gap-y-2 text-sm ${k.weich} mb-4`}>
          <span className="flex items-center gap-1.5">
            <CalendarDays size={14} /> {tag(t.datum)}
            {t.ende && t.ende !== t.datum ? ` – ${tag(t.ende)}` : ''}
            {t.beginn ? `, ${zeit(t.beginn)}` : ''}
          </span>
          {t.ort && <span className="flex items-center gap-1.5"><MapPin size={14} /> {t.ort}</span>}
          <span className="flex items-center gap-1.5">
            <Ticket size={14} />
            {t.preis_art === 'KEINE' ? 'Teilnahme kostenlos'
              : `${Number(t.preis_betrag).toLocaleString('de-CH', { minimumFractionDigits: 2 })} ${t.waehrung} `
                + (t.preis_art === 'PRO_KOPF' ? 'pro Person' : 'pro Verein')}
          </span>
          {t.anmeldeschluss && (
            <span className="flex items-center gap-1.5">
              <Clock size={14} /> Anmeldung bis {tag(t.anmeldeschluss)}
            </span>
          )}
        </div>
        {t.beschreibung && <p className={`text-sm ${k.weich} leading-relaxed max-w-2xl`}>{t.beschreibung}</p>}

        {/* Bei Preis pro Kopf steht die Summe direkt dabei -- sonst rechnet
            jemand im Kopf falsch und ist am Tag ueberrascht. */}
        {t.preis_art === 'PRO_KOPF' && zugesagt && leute.filter(p => p.name.trim()).length > 0 && (
          <p className={`text-sm font-bold ${k.text} mt-4`}>
            {leute.filter(p => p.name.trim()).length} × {Number(t.preis_betrag).toFixed(2)} ={' '}
            {(leute.filter(p => p.name.trim()).length * Number(t.preis_betrag)).toLocaleString('de-CH',
              { minimumFractionDigits: 2 })} {t.waehrung}
          </p>
        )}
      </div>

      {schlussVorbei ? (
        <div className="flex gap-3 p-5 rounded-2xl bg-amber-50 border border-amber-100">
          <Clock size={18} className="text-amber-500 shrink-0 mt-0.5" />
          <p className="text-xs text-amber-800 leading-relaxed">
            Der Anmeldeschluss am {tag(t.anmeldeschluss)} ist vorbei. Ihre Angaben lassen sich
            nicht mehr ändern — wenden Sie sich an den Gastgeber, wenn sich etwas verschoben hat.
          </p>
        </div>
      ) : (
        <>
          {/* Zu- oder absagen */}
          <div className={`${k.karte} border rounded-[2rem] p-7 space-y-5`}>
            <p className={`text-[10px] font-bold uppercase tracking-widest ${k.weich}`}>Kommen Sie?</p>
            <div className="flex gap-3 flex-wrap">
              <button type="button" onClick={() => setZugesagt(true)}
                className={`flex items-center gap-2 px-6 py-3 rounded-2xl text-sm font-bold border transition-all ${
                  zugesagt === true ? 'bg-emerald-500 text-white border-emerald-500'
                    : `${k.feld} ${k.weich} hover:border-emerald-400`}`}>
                <Check size={16} /> Wir kommen
              </button>
              <button type="button" onClick={() => { setZugesagt(false); setLeute([]); }}
                className={`flex items-center gap-2 px-6 py-3 rounded-2xl text-sm font-bold border transition-all ${
                  zugesagt === false ? 'bg-stone-700 text-white border-stone-700'
                    : `${k.feld} ${k.weich} hover:border-stone-400`}`}>
                <X size={16} /> Leider nicht
              </button>
            </div>

            <label className="block">
              <span className={`text-[10px] font-bold uppercase tracking-widest ${k.weich} block mb-1.5`}>
                Bemerkung an den Gastgeber
              </span>
              <textarea value={bemerkung} onChange={e => setBemerkung(e.target.value)} rows={2}
                placeholder="z. B. Anreise mit dem Bus, Ankunft gegen 08:30"
                className={`w-full p-3 border rounded-xl text-sm outline-none ${k.feld}`} />
            </label>
          </div>

          {/* Wer mitkommt */}
          {zugesagt && (
            <div className={`${k.karte} border rounded-[2rem] p-7 space-y-4`}>
              <div className="flex items-center justify-between gap-4 flex-wrap">
                <div className="flex items-center gap-2">
                  <Users size={16} className={k.weich} />
                  <p className={`text-[10px] font-bold uppercase tracking-widest ${k.weich}`}>
                    Wer kommt mit · {leute.filter(p => p.name.trim()).length} Personen
                  </p>
                </div>
                <button type="button"
                  onClick={() => setLeute(a => [...a, { name: '', rolle: 'TEILNEHMER', bemerkung: '' }])}
                  className={`flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest ${k.weich} hover:${k.text}`}>
                  <Plus size={13} /> Person
                </button>
              </div>

              {leute.length === 0 ? (
                <p className={`text-xs ${k.weich} leading-relaxed`}>
                  Noch niemand eingetragen. Die Namen brauchen wir für Namensschilder und die Essenszahlen —
                  eine Person davon markieren Sie bitte als Delegationsleitung.
                </p>
              ) : (
                <div className="space-y-2">
                  {leute.map((p, i) => (
                    <div key={i} className="grid grid-cols-1 sm:grid-cols-[1fr_9rem_1fr_2rem] gap-2 items-center">
                      <input value={p.name} placeholder="Name"
                        onChange={e => setLeute(a => a.map((y, j) => j === i ? { ...y, name: e.target.value } : y))}
                        className={`p-2.5 border rounded-xl text-sm outline-none ${k.feld}`} />
                      <select value={p.rolle}
                        onChange={e => setLeute(a => a.map((y, j) => j === i ? { ...y, rolle: e.target.value as any } : y))}
                        className={`p-2.5 border rounded-xl text-sm outline-none ${k.feld}`}>
                        <option value="TEILNEHMER">Teilnehmer</option>
                        <option value="LEITUNG">Delegationsleitung</option>
                      </select>
                      <input value={p.bemerkung || ''} placeholder="Essenswunsch, Hinweis"
                        onChange={e => setLeute(a => a.map((y, j) => j === i ? { ...y, bemerkung: e.target.value } : y))}
                        className={`p-2.5 border rounded-xl text-sm outline-none ${k.feld}`} />
                      <button type="button" onClick={() => setLeute(a => a.filter((_, j) => j !== i))}
                        className={`${k.weich} hover:text-red-500`}><Trash2 size={15} /></button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {fehler && <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">{fehler}</p>}

          <div className="flex items-center gap-4 flex-wrap">
            <button onClick={sichern} disabled={arbeitet || zugesagt === null}
              className="knopf-primaer text-white px-7 py-3 rounded-2xl text-sm font-bold
                         inline-flex items-center gap-2 disabled:opacity-40">
              {arbeitet ? <Loader2 size={16} className="animate-spin" />
                : fertig ? <Check size={16} /> : null}
              {fertig ? 'Gespeichert' : 'Antwort speichern'}
            </button>
            {fertig && (
              <p className={`text-xs ${k.weich}`}>
                Sie können Ihre Angaben bis zum Anmeldeschluss jederzeit ändern.
              </p>
            )}
          </div>
        </>
      )}

      {/* Das freigegebene Programm */}
      {daten.programm?.length > 0 && (
        <div className={`${k.karte} border rounded-[2rem] p-7`}>
          <p className={`text-[10px] font-bold uppercase tracking-widest ${k.weich} mb-4`}>Tagesprogramm</p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm" style={{ minWidth: '28rem' }}>
              <tbody>
                {daten.programm.map((p: any, i: number) => (
                  <tr key={i} className={i ? (dunkel ? 'border-t border-white/10' : 'border-t border-stone-100') : ''}>
                    <td className={`py-2 pr-4 font-mono text-xs whitespace-nowrap align-top ${k.text}`}>
                      {zeit(p.beginn)}
                    </td>
                    <td className="py-2 pr-4 whitespace-nowrap align-top">
                      <span className={`text-[10px] uppercase tracking-wider px-2 py-0.5 rounded border ${k.weich} ${
                        dunkel ? 'border-white/15' : 'border-stone-200'}`}>{p.spur}</span>
                    </td>
                    <td className={`py-2 pr-4 align-top ${k.text}`}>
                      {p.titel}
                      {p.fuer === 'VERTRETER' && <em className={k.weich}> — nur Delegationsleitungen</em>}
                    </td>
                    <td className={`py-2 align-top whitespace-nowrap ${k.weich}`}>
                      {[p.verantwortlich, p.ort].filter(Boolean).join(' · ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default TreffenAntwort;
