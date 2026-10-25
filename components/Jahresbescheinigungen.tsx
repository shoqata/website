import React, { useMemo, useState } from 'react';
import { CalendarRange, Download, Loader2 } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { jahresbescheinigungenErzeugen, type Jahresspender, type Verein } from '../lib/spendenbescheinigung';

// Jahres-Spendenbescheinigungen: je Spender alle bezahlten Spenden eines
// Jahres auf einem Blatt, so wie die Steuererklaerung sie verlangt.
//
// Wer ist "derselbe Spender"? Zuerst das Mitglied (userId), dann die
// E-Mail, zuletzt Name und Postleitzahl. Anonyme Spenden und solche ohne
// Namen fallen weg -- fuer sie gibt es niemanden, dem man bescheinigt.

type Spende = {
  id: string; betrag: number; waehrung: string; name: string | null; email: string | null;
  strasse: string | null; plz: string | null; ort: string | null; land: string | null;
  anonym: boolean; zweck: string | null; referenz: string | null; status: string;
  eingegangen_am: string | null; userId?: string | null;
};

const schluessel = (s: Spende) =>
  s.userId ? `u:${s.userId}`
  : s.email?.trim() ? `e:${s.email.trim().toLowerCase()}`
  : `n:${(s.name || '').toLowerCase().normalize('NFKD').replace(/[^a-z0-9]/g, '')}:${(s.plz || '').trim()}`;

// Januar bis Maerz wird fuer das Vorjahr bescheinigt -- dann braucht man
// die Bescheinigungen fuer die Steuererklaerung.
const vorgabeJahr = () => { const d = new Date(); return d.getMonth() < 3 ? d.getFullYear() - 1 : d.getFullYear(); };

const Jahresbescheinigungen: React.FC<{ spenden: Spende[]; verein: Verein }> = ({ spenden, verein }) => {
  const { t } = useTranslation();
  const bezahlt = useMemo(() => spenden.filter(s => s.status === 'BEZAHLT' && !s.anonym && s.name?.trim() && s.eingegangen_am), [spenden]);
  const jahre = useMemo(() => {
    const j = new Set(bezahlt.map(s => new Date(s.eingegangen_am!).getFullYear()));
    j.add(vorgabeJahr());
    return [...j].sort((a, b) => b - a);
  }, [bezahlt]);
  const [jahr, setJahr] = useState(vorgabeJahr());
  const [laeuft, setLaeuft] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);

  const spender = useMemo(() => {
    const m = new Map<string, Jahresspender & { schluessel: string }>();
    bezahlt.filter(s => new Date(s.eingegangen_am!).getFullYear() === jahr).forEach(s => {
      const k = schluessel(s);
      // Die Adresse der juengsten Spende gilt -- Leute ziehen um.
      const alt = m.get(k);
      const neuer = !alt || String(s.eingegangen_am) > String(alt.spenden.at(-1)?.eingegangen_am);
      const eintrag = alt ?? { schluessel: k, name: s.name, strasse: s.strasse, plz: s.plz, ort: s.ort, land: s.land, spenden: [] };
      if (neuer) Object.assign(eintrag, { name: s.name, strasse: s.strasse, plz: s.plz, ort: s.ort, land: s.land });
      eintrag.spenden.push({ betrag: Number(s.betrag), waehrung: s.waehrung, eingegangen_am: s.eingegangen_am, referenz: s.referenz, zweck: s.zweck });
      m.set(k, eintrag);
    });
    return [...m.values()].sort((a, b) => String(a.name).localeCompare(String(b.name), 'de'));
  }, [bezahlt, jahr]);

  const summe = (x: Jahresspender) => x.spenden.reduce((n, s) => n + s.betrag, 0);

  const los = async (wer: Jahresspender[], kennung: string) => {
    setLaeuft(kennung); setFehler(null);
    try { await jahresbescheinigungenErzeugen(wer, verein, jahr); }
    catch (e: any) { setFehler(e?.message || t('common.error')); }
    finally { setLaeuft(null); }
  };

  return (
    <section className="bg-white rounded-2xl border border-stone-100 overflow-hidden">
      <div className="p-5 flex flex-wrap items-center gap-3 border-b border-stone-100">
        <CalendarRange size={18} className="text-stone-400" />
        <div className="min-w-0 flex-1">
          <p className="font-bold text-stone-900 text-sm">{t('jbs.titel')}</p>
          <p className="text-xs text-stone-500">{t('jbs.untertitel')}</p>
        </div>
        <select value={jahr} onChange={e => setJahr(Number(e.target.value))}
                className="px-3 py-2 rounded-xl border border-stone-200 bg-white text-sm font-bold tabular-nums">
          {jahre.map(j => <option key={j} value={j}>{j}</option>)}
        </select>
        {spender.length > 1 && (
          <button onClick={() => los(spender, 'alle')} disabled={!!laeuft}
                  className="px-3 py-2 rounded-xl bg-stone-900 text-white text-xs font-bold inline-flex items-center gap-1.5 disabled:opacity-50">
            {laeuft === 'alle' ? <Loader2 size={13} className="animate-spin" /> : <Download size={13} />}
            {t('jbs.alle', { n: spender.length })}
          </button>
        )}
      </div>

      {fehler && <p className="px-5 py-3 text-sm text-red-700 bg-red-50">{fehler}</p>}

      {spender.length === 0 ? (
        <p className="px-5 py-8 text-sm text-stone-500 text-center">{t('jbs.leer', { jahr })}</p>
      ) : (
        <div className="divide-y divide-stone-50 max-h-[28rem] overflow-y-auto">
          {spender.map(x => (
            <div key={(x as any).schluessel} className="px-5 py-3 flex items-center gap-3">
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold text-stone-900 [overflow-wrap:anywhere]">{x.name}</p>
                <p className="text-xs text-stone-500 [overflow-wrap:anywhere]">
                  {[x.plz, x.ort].filter(Boolean).join(' ') || t('jbs.ohne_adresse')} · {t(x.spenden.length === 1 ? 'jbs.eine' : 'jbs.mehrere', { n: x.spenden.length })}
                </p>
              </div>
              <span className="text-sm font-bold text-stone-900 tabular-nums shrink-0">
                {x.spenden[0]?.waehrung} {summe(x).toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </span>
              <button onClick={() => los([x], (x as any).schluessel)} disabled={!!laeuft}
                      title={t('jbs.herunterladen')}
                      className="shrink-0 px-2.5 py-1.5 rounded-lg border border-stone-200 text-stone-600 text-[10px] font-bold uppercase tracking-widest inline-flex items-center gap-1.5 disabled:opacity-50">
                {laeuft === (x as any).schluessel ? <Loader2 size={11} className="animate-spin" /> : <Download size={11} />} PDF
              </button>
            </div>
          ))}
        </div>
      )}
    </section>
  );
};

export default Jahresbescheinigungen;
