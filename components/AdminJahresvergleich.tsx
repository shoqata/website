import React, { useEffect, useMemo, useState } from 'react';
import { Bar, BarChart, CartesianGrid, XAxis } from 'recharts';
import { ArrowDownRight, ArrowUpRight, Minus } from 'lucide-react';
import { collection, onSnapshot, db } from '../services/supabase-bridge';
import { billingYearOf } from '../lib/memberQuality';
import { ChartContainer, ChartTooltip, ChartTooltipContent, ChartLegend, ChartLegendContent } from './ui/Chart';
import { UserProfile, Payment, Neighborhood } from '../types';
import { useTranslation } from '../context/LanguageContext';

// Die Vereinsjahre nebeneinander.
//
// Bis zum 28.10.2026 zeigte jede Auswertung genau ein Jahr -- gewaehlt oben
// im Admin. Wer wissen wollte, ob die Zahlquote sinkt, musste umstellen,
// sich die Zahl merken und wieder umstellen.
//
// "Mitglieder" heisst hier: wer in dem Jahr eine Beitragsrechnung bekam. Ein
// Austrittsdatum fuehrt die Datenbank nicht; der heutige Bestand rueckwaerts
// auf fruehere Jahre gelegt, haette jeden Ausgetretenen aus der Geschichte
// geloescht. Die Rechnungen dagegen sind je Jahr erhalten.

interface Props {
  users: UserProfile[];
  payments: Payment[];
  neighborhoods: Neighborhood[];
}

type Spende = { status?: string; betrag?: number | string; eingegangen_am?: string | null };

// Zaehlt als gestellt -- Entwuerfe und Stornos nicht.
const GESTELLT = new Set(['SCHEDULED', 'SENT', 'PENDING', 'OVERDUE', 'PAID', 'WRITTEN_OFF']);
const OFFEN = new Set(['SCHEDULED', 'SENT', 'PENDING', 'OVERDUE']);

const chf = (n: number) => n.toLocaleString('de-CH', { maximumFractionDigits: 0 });

type Zeile = {
  schluessel: string;
  wert: (j: Jahr) => number | null;
  format: (n: number) => string;
  // Ob ein Anstieg gut ist. Mehr Offenes ist es nicht.
  aufwaertsGut: boolean;
  // Quoten vergleicht man in Prozentpunkten, nicht in Prozent von Prozent.
  punkte?: boolean;
};

type Jahr = {
  jahr: number;
  mitglieder: number; bezahlt: number; quote: number | null;
  gestellt: number; eingegangen: number; offen: number; abgeschrieben: number;
  eintritte: number; spenden: number; spendenAnzahl: number;
};

const AdminJahresvergleich: React.FC<Props> = ({ users, payments, neighborhoods }) => {
  const { t } = useTranslation();
  const [spenden, setSpenden] = useState<Spende[]>([]);

  // Ohne Spendenmodul ist die Tabelle leer oder gesperrt -- dann fehlt die
  // Zeile eben, der Vergleich der Beitraege bleibt brauchbar.
  useEffect(() => {
    try {
      return onSnapshot(collection(db, 'donations'),
        snap => setSpenden(snap.docs.map(d => d.data() as Spende)),
        () => setSpenden([]));
    } catch { return undefined; }
  }, []);

  const beitraege = useMemo(
    () => payments.filter(p => p.type === 'FEE' && p.userId && p.userId !== 'EXTERNAL'
                            && GESTELLT.has(p.status)),
    [payments]);

  const jahre: Jahr[] = useMemo(() => {
    const menge = new Set<number>();
    beitraege.forEach(p => { const j = billingYearOf(p); if (Number.isFinite(j)) menge.add(j); });
    return [...menge].sort((a, b) => a - b).map(jahr => {
      const eigene = beitraege.filter(p => billingYearOf(p) === jahr);
      const mitglieder = new Set(eigene.map(p => p.userId)).size;
      const bezahlt = new Set(eigene.filter(p => p.status === 'PAID').map(p => p.userId)).size;
      const summe = (f: (p: Payment) => boolean) =>
        eigene.filter(f).reduce((s, p) => s + Number(p.amount || 0), 0);
      const bezahlteSpenden = spenden.filter(s => s.status === 'BEZAHLT' && s.eingegangen_am
        && new Date(s.eingegangen_am).getFullYear() === jahr);
      return {
        jahr, mitglieder, bezahlt,
        // Ungerundet: sonst rechnet der Vorjahrespfeil mit Rundungsresten.
        quote: mitglieder ? (bezahlt / mitglieder) * 100 : null,
        gestellt: summe(() => true),
        eingegangen: summe(p => p.status === 'PAID'),
        offen: summe(p => OFFEN.has(p.status)),
        abgeschrieben: summe(p => p.status === 'WRITTEN_OFF'),
        eintritte: users.filter(u => u.joinedAt && new Date(u.joinedAt).getFullYear() === jahr).length,
        spenden: bezahlteSpenden.reduce((s, x) => s + Number(x.betrag || 0), 0),
        spendenAnzahl: bezahlteSpenden.length,
      };
    });
  }, [beitraege, users, spenden]);

  const hatSpenden = jahre.some(j => j.spendenAnzahl > 0);
  const laufend = new Date().getFullYear();

  const zeilen: Zeile[] = [
    { schluessel: 'jv.mitglieder', wert: j => j.mitglieder, format: String, aufwaertsGut: true },
    { schluessel: 'jv.bezahlt', wert: j => j.bezahlt, format: String, aufwaertsGut: true },
    { schluessel: 'jv.quote', wert: j => j.quote, format: n => `${n.toLocaleString('de-CH', { maximumFractionDigits: 1 })} %`, aufwaertsGut: true, punkte: true },
    { schluessel: 'jv.gestellt', wert: j => j.gestellt, format: chf, aufwaertsGut: true },
    { schluessel: 'jv.eingegangen', wert: j => j.eingegangen, format: chf, aufwaertsGut: true },
    { schluessel: 'jv.offen', wert: j => j.offen, format: chf, aufwaertsGut: false },
    { schluessel: 'jv.abgeschrieben', wert: j => j.abgeschrieben, format: chf, aufwaertsGut: false },
    { schluessel: 'jv.eintritte', wert: j => j.eintritte, format: String, aufwaertsGut: true },
    ...(hatSpenden ? [{ schluessel: 'jv.spenden', wert: (j: Jahr) => j.spenden, format: chf, aufwaertsGut: true }] : []),
  ];

  // Zahlquote je Nachbarschaft und Jahr. Die Nachbarschaft steht auf der
  // Rechnung; fehlt sie, gilt die heutige des Mitglieds.
  const nachNachbarschaft = useMemo(() => {
    const nbVon = new Map(users.map(u => [u.id, u.neighborhoodId]));
    return neighborhoods.map(n => ({
      name: n.name,
      quoten: jahre.map(({ jahr }) => {
        const eigene = beitraege.filter(p => billingYearOf(p) === jahr
          && (p.neighborhoodId ?? nbVon.get(p.userId)) === n.id);
        const alle = new Set(eigene.map(p => p.userId)).size;
        const bez = new Set(eigene.filter(p => p.status === 'PAID').map(p => p.userId)).size;
        return alle ? Math.round((bez / alle) * 100) : null;
      }),
    })).filter(n => n.quoten.some(q => q !== null));
  }, [neighborhoods, users, beitraege, jahre]);

  const diagramm = jahre.map(j => ({ jahr: String(j.jahr), gestellt: j.gestellt, eingegangen: j.eingegangen }));
  const diagrammKonfig = {
    gestellt: { label: t('jv.gestellt'), color: '#d6d3d1' },
    eingegangen: { label: t('jv.eingegangen'), color: '#10b981' },
  };

  const Veraenderung: React.FC<{ z: Zeile; jetzt: number | null; vorher: number | null }> = ({ z, jetzt, vorher }) => {
    if (jetzt === null || vorher === null) return null;
    const d = Math.round((jetzt - vorher) * 10) / 10;
    if (d === 0) return <span className="inline-flex items-center gap-0.5 text-[10px] text-stone-300"><Minus size={10} />0</span>;
    const gut = (d > 0) === z.aufwaertsGut;
    const Pfeil = d > 0 ? ArrowUpRight : ArrowDownRight;
    const text = z.punkte ? `${d > 0 ? '+' : '−'}${Math.abs(d).toLocaleString('de-CH')} Pkt.`
                          : `${d > 0 ? '+' : '−'}${z.format(Math.abs(d))}`;
    return (
      <span className={`inline-flex items-center gap-0.5 text-[10px] font-bold ${gut ? 'text-emerald-600' : 'text-rose-500'}`}>
        <Pfeil size={10} />{text}
      </span>
    );
  };

  if (jahre.length === 0) {
    return <div className="bg-white p-12 rounded-[2.5rem] border border-stone-100 text-center text-stone-400 italic">{t('jv.leer')}</div>;
  }

  return (
    <div className="space-y-8">
      <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
        <div className="p-8 border-b border-stone-100">
          <h3 className="text-xl font-bold text-stone-900">{t('jv.titel')}</h3>
          <p className="text-sm text-stone-500 mt-1 max-w-3xl">{t('jv.erklaerung')}</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left tabular-nums">
            <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
              <tr>
                <th className="px-8 py-4 sticky left-0 bg-stone-50"></th>
                {jahre.map(j => (
                  <th key={j.jahr} className="px-6 py-4 text-right whitespace-nowrap">
                    <span className="text-stone-700 text-xs">{j.jahr}</span>
                    {j.jahr >= laufend && <span className="block font-normal normal-case tracking-normal text-amber-600">{t('jv.laufend')}</span>}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-50">
              {zeilen.map(z => (
                <tr key={z.schluessel} className="hover:bg-stone-50/50">
                  <td className="px-8 py-4 text-sm font-bold text-stone-700 sticky left-0 bg-white whitespace-nowrap">{t(z.schluessel)}</td>
                  {jahre.map((j, i) => {
                    const w = z.wert(j);
                    return (
                      <td key={j.jahr} className="px-6 py-4 text-right whitespace-nowrap">
                        <div className="text-sm font-bold text-stone-900">{w === null ? '–' : z.format(w)}</div>
                        {i > 0 && <Veraenderung z={z} jetzt={w} vorher={z.wert(jahre[i - 1])} />}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
          <h3 className="text-xl font-bold text-stone-900">{t('jv.diagramm')}</h3>
          <p className="text-sm text-stone-500 mb-6">{t('jv.diagramm_sub')}</p>
          <div className="h-[300px] w-full">
            <ChartContainer config={diagrammKonfig} className="w-full h-full">
              <BarChart data={diagramm} margin={{ top: 20, right: 0, left: 0, bottom: 0 }}>
                <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="#f5f5f4" />
                <XAxis dataKey="jahr" tickLine={false} tickMargin={10} axisLine={false} tick={{ fontSize: 11, fill: '#78716c' }} />
                <ChartTooltip cursor={false} content={<ChartTooltipContent indicator="dashed" />} />
                <ChartLegend content={<ChartLegendContent />} />
                <Bar dataKey="gestellt" fill="var(--color-gestellt)" radius={[4, 4, 0, 0]} />
                <Bar dataKey="eingegangen" fill="var(--color-eingegangen)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ChartContainer>
          </div>
        </div>

        <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
          <h3 className="text-xl font-bold text-stone-900">{t('jv.nachbarschaften')}</h3>
          <p className="text-sm text-stone-500 mb-6">{t('jv.nachbarschaften_sub')}</p>
          <div className="overflow-x-auto max-h-[300px] overflow-y-auto">
            <table className="w-full text-left tabular-nums">
              <thead className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                <tr>
                  <th className="py-2 pr-4"></th>
                  {jahre.map(j => <th key={j.jahr} className="py-2 px-3 text-right">{j.jahr}</th>)}
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-50">
                {nachNachbarschaft.map(n => (
                  <tr key={n.name}>
                    <td className="py-2.5 pr-4 text-sm font-bold text-stone-700 whitespace-nowrap">{n.name}</td>
                    {n.quoten.map((q, i) => {
                      const vorher = i > 0 ? n.quoten[i - 1] : null;
                      const farbe = q === null ? 'text-stone-300'
                        : vorher === null || q === vorher ? 'text-stone-900'
                        : q > vorher ? 'text-emerald-600' : 'text-rose-500';
                      return <td key={i} className={`py-2.5 px-3 text-right text-sm font-bold ${farbe}`}>{q === null ? '–' : `${q} %`}</td>;
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminJahresvergleich;
