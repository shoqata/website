import React, { useState } from 'react';
import { Upload, CheckCircle2, AlertTriangle, Loader2, Landmark, HelpCircle } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useFeedback } from '../context/FeedbackContext';
import { camtLesen, zuordnen, type Zuordnung, type Rechnung } from '../lib/camt';

// Bankauszug einlesen (camt.054 / camt.053 aus dem E-Banking) und die
// Gutschriften den offenen Rechnungen zuordnen. Verbucht wird ueber
// zahlung_eingang_erfassen -- dieselbe Stelle wie von Hand, mit
// Buchhaltung und Teilzahlungen. Jede Bankbuchung traegt ihren Schluessel
// in der Notiz; ein zweites Einlesen derselben Datei bucht nichts doppelt.

type Zeile = Zuordnung & { schon: boolean; wahl: string | null; mitglied?: string };

const Bankabgleich: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showConfirm } = useFeedback();
  const [zeilen, setZeilen] = useState<Zeile[] | null>(null);
  const [offene, setOffene] = useState<(Rechnung & { name?: string })[]>([]);
  const [laedt, setLaedt] = useState(false);
  const [bucht, setBucht] = useState(false);
  const [dateiname, setDateiname] = useState('');

  const einlesen = async (datei: File) => {
    setLaedt(true); setDateiname(datei.name);
    try {
      const gutschriften = camtLesen(await datei.text());
      if (!gutschriften.length) throw new Error(t('bank.keine'));
      const [{ data: rech }, { data: eing }, { data: leute }] = await Promise.all([
        supabase.from('payments').select('id, reference, invoiceNumber, amount, status, userId').neq('status', 'CANCELLED'),
        supabase.from('zahlungseingaenge').select('notiz').like('notiz', 'Bank: %'),
        supabase.from('users').select('id, displayName'),
      ]);
      const namen = new Map<string, string>((leute ?? []).map((u: any) => [u.id, u.displayName]));
      const gebucht = new Set((eing ?? []).map((e: any) => e.notiz));
      const alle = (rech ?? []) as Rechnung[];
      setOffene(alle.filter(r => r.status !== 'PAID').map(r => ({ ...r, name: namen.get(r.userId || '') })));
      setZeilen(zuordnen(gutschriften, alle).map(z => ({
        ...z, schon: gebucht.has(`Bank: ${z.g.schluessel}`),
        wahl: z.rechnung && z.rechnung.status !== 'PAID' ? z.rechnung.id : null,
        mitglied: z.rechnung ? namen.get(z.rechnung.userId || '') : undefined,
      })));
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || String(e) });
      setZeilen(null);
    } finally { setLaedt(false); }
  };

  const zuBuchen = (zeilen ?? []).filter(z => !z.schon && z.wahl);

  const verbuchen = async () => {
    if (!zuBuchen.length) return;
    const summe = zuBuchen.reduce((a, z) => a + z.g.betrag, 0);
    if (!(await showConfirm({ title: t('bank.verbuchen'), message: t('bank.frage', { count: zuBuchen.length, summe: summe.toFixed(2) }), type: 'primary', confirmText: t('bank.verbuchen') }))) return;
    setBucht(true);
    let ok = 0; const fehler: string[] = [];
    for (const z of zuBuchen) {
      const { error } = await supabase.rpc('zahlung_eingang_erfassen', {
        p_payment: z.wahl, p_betrag: z.g.betrag, p_weg: 'QR_BILL', p_eingang: z.g.datum || null, p_notiz: `Bank: ${z.g.schluessel}`,
      });
      if (error) fehler.push(`${z.g.betrag.toFixed(2)} (${z.g.datum}): ${error.message}`); else ok++;
    }
    setBucht(false);
    showAlert(fehler.length
      ? { type: 'warning', message: t('bank.teilweise', { ok, fehler: fehler.length }) + '\n' + fehler.slice(0, 5).join('\n') }
      : { type: 'success', message: t('bank.fertig', { count: ok }) });
    setZeilen(z => z ? z.map(x => zuBuchen.includes(x) && !fehler.some(f => f.startsWith(x.g.betrag.toFixed(2))) ? { ...x, schon: true } : x) : z);
  };

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-3xl border border-stone-100 p-6">
        <div className="flex items-start gap-4 flex-wrap">
          <div className="w-11 h-11 rounded-xl bg-stone-100 text-stone-500 flex items-center justify-center"><Landmark size={20} /></div>
          <div className="flex-1 min-w-[240px]">
            <h3 className="font-bold text-stone-900">{t('bank.titel')}</h3>
            <p className="text-xs text-stone-500 leading-relaxed">{t('bank.text')}</p>
          </div>
          <label className="knopf-primaer px-5 py-3 text-white rounded-xl text-sm font-bold flex items-center gap-2 cursor-pointer">
            {laedt ? <Loader2 size={15} className="animate-spin" /> : <Upload size={15} />} {t('bank.datei')}
            <input type="file" accept=".xml,application/xml,text/xml" hidden onChange={e => { const f = e.target.files?.[0]; if (f) einlesen(f); e.target.value = ''; }} />
          </label>
        </div>
      </div>

      {zeilen && (
        <div className="bg-white rounded-3xl border border-stone-100 p-6">
          <div className="flex items-center justify-between gap-4 flex-wrap mb-4">
            <p className="text-sm text-stone-600"><b>{dateiname}</b> · {t('bank.zusammenfassung', {
              count: zeilen.length, zugeordnet: zeilen.filter(z => z.wahl && !z.schon).length,
              schon: zeilen.filter(z => z.schon).length, offen: zeilen.filter(z => !z.wahl && !z.schon).length })}</p>
            <button onClick={verbuchen} disabled={!zuBuchen.length || bucht}
                    className="knopf-primaer px-5 py-3 text-white rounded-xl text-sm font-bold flex items-center gap-2 disabled:opacity-40">
              {bucht && <Loader2 size={15} className="animate-spin" />} {t('bank.knopf', { count: zuBuchen.length })}
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="text-left text-[10px] uppercase tracking-widest text-stone-400">
                <th className="py-2 pr-3">{t('bank.datum')}</th><th className="py-2 pr-3 text-right">{t('field.amount')}</th>
                <th className="py-2 pr-3">{t('bank.von')}</th><th className="py-2 pr-3">{t('bank.rechnung')}</th><th className="py-2">{t('field.status')}</th>
              </tr></thead>
              <tbody>
                {zeilen.map((z, i) => {
                  const r = offene.find(o => o.id === z.wahl) || z.rechnung;
                  const differenz = r && z.wahl ? z.g.betrag - Number(r.amount) : 0;
                  return (
                    <tr key={z.g.schluessel} className="border-t border-stone-100 align-top">
                      <td className="py-2.5 pr-3 whitespace-nowrap text-stone-600">{z.g.datum ? new Date(z.g.datum).toLocaleDateString('de-CH') : '—'}</td>
                      <td className="py-2.5 pr-3 text-right font-mono font-bold tabular-nums whitespace-nowrap">{z.g.betrag.toFixed(2)}</td>
                      <td className="py-2.5 pr-3 text-stone-600 max-w-[220px]"><p className="truncate" title={z.g.auftraggeber || ''}>{z.g.auftraggeber || '—'}</p><p className="text-[11px] text-stone-400 truncate" title={z.g.mitteilung || z.g.referenz || ''}>{z.g.mitteilung || z.g.referenz}</p></td>
                      <td className="py-2.5 pr-3">
                        {z.schon ? <span className="text-stone-400">{z.mitglied || '—'}</span> : (
                          <select value={z.wahl || ''} onChange={e => setZeilen(zs => zs!.map((x, j) => j === i ? { ...x, wahl: e.target.value || null } : x))}
                                  className="w-full max-w-[280px] p-2 bg-stone-50 border border-stone-200 rounded-lg text-xs">
                            <option value="">{t('bank.nicht_zuordnen')}</option>
                            {z.rechnung && z.rechnung.status !== 'PAID' && !offene.some(o => o.id === z.rechnung!.id) && <option value={z.rechnung.id}>{z.mitglied}</option>}
                            {offene.slice().sort((a, b) => (Math.abs(Number(a.amount) - z.g.betrag) - Math.abs(Number(b.amount) - z.g.betrag)) || (a.name || '').localeCompare(b.name || '')).map(o => (
                              <option key={o.id} value={o.id}>{o.name || '—'} · {Number(o.amount).toFixed(2)}{o.invoiceNumber ? ` · ${o.invoiceNumber}` : ''}</option>
                            ))}
                          </select>
                        )}
                      </td>
                      <td className="py-2.5 text-xs whitespace-nowrap">
                        {z.schon ? <span className="text-stone-400 flex items-center gap-1"><CheckCircle2 size={13} /> {t('bank.schon')}</span>
                          : z.wahl ? (Math.abs(differenz) < 0.005
                              ? <span className="text-emerald-700 flex items-center gap-1"><CheckCircle2 size={13} /> {z.wie && z.wahl === z.rechnung?.id ? t(`bank.wie.${z.wie}`) : t('bank.passt')}</span>
                              : <span className="text-amber-700 flex items-center gap-1"><AlertTriangle size={13} /> {differenz < 0 ? t('bank.teil') : t('bank.ueber')} {Math.abs(differenz).toFixed(2)}</span>)
                          : <span className="text-stone-400 flex items-center gap-1"><HelpCircle size={13} /> {t('bank.unbekannt')}</span>}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default Bankabgleich;
