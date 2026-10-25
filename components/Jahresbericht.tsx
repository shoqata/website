import React, { useState } from 'react';
import { BarChart3, Loader2, Printer } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useTenant } from '../context/TenantContext';
import { billingYearOf } from '../lib/memberQuality';

// Zahlen fuer den Jahresbericht der Generalversammlung, als druckbare Seite
// (Drucken -> als PDF sichern): Mitglieder, Beitraege, Nachbarschaften,
// Anlaesse. Gerechnet aus den Daten, nichts von Hand.

const esc = (s: string) => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]!));
const chf = (n: number) => `CHF ${n.toLocaleString('de-CH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const Jahresbericht: React.FC = () => {
  const { t } = useTranslation();
  const { tenant } = useTenant() as any;
  const [jahr, setJahr] = useState(new Date().getFullYear());
  const [laedt, setLaedt] = useState(false);

  const erstellen = async () => {
    setLaedt(true);
    try {
      const [{ data: u }, { data: p }, { data: n }, { data: e }] = await Promise.all([
        supabase.from('users').select('id, membershipStatus, joinedAt, neighborhoodId'),
        supabase.from('payments').select('userId, amount, status, billingYear, timestamp'),
        supabase.from('neighborhoods').select('id, name'),
        supabase.from('events').select('id, title, date, status'),
      ]);
      const leute = (u ?? []) as any[];
      const aktiv = leute.filter(x => x.membershipStatus !== 'INACTIVE');
      const neu = aktiv.filter(x => x.joinedAt && new Date(x.joinedAt).getFullYear() === jahr).length;
      const vorher = aktiv.filter(x => x.joinedAt && new Date(x.joinedAt).getFullYear() < jahr).length;
      const rechn = ((p ?? []) as any[]).filter(x => billingYearOf(x) === jahr && x.status !== 'CANCELLED');
      const gestellt = rechn.reduce((a, x) => a + Number(x.amount || 0), 0);
      const bezahlt = rechn.filter(x => x.status === 'PAID').reduce((a, x) => a + Number(x.amount || 0), 0);
      const zahlerIds = new Set(rechn.filter(x => x.status === 'PAID').map(x => x.userId));
      const nb = ((n ?? []) as any[]).map(x => {
        const m = aktiv.filter(a => a.neighborhoodId === x.id);
        const z = m.filter(a => zahlerIds.has(a.id)).length;
        return { name: x.name, mitglieder: m.length, quote: m.length ? Math.round(z / m.length * 100) : 0 };
      }).filter(x => x.mitglieder > 0).sort((a, b) => b.mitglieder - a.mitglieder);
      const anlaesse = ((e ?? []) as any[]).filter(x => x.status === 'PUBLISHED' && (x.date || '').startsWith(String(jahr)));
      const max = Math.max(1, ...nb.map(x => x.mitglieder));
      const quote = rechn.length ? Math.round(rechn.filter(x => x.status === 'PAID').length / rechn.length * 100) : 0;

      const html = `<!doctype html><html><head><meta charset="utf-8"><title>Jahresbericht ${jahr}</title><style>
        body{font:14px/1.5 system-ui,sans-serif;color:#1c1917;max-width:820px;margin:40px auto;padding:0 24px}
        h1{font-size:28px;margin:0}h2{font-size:16px;margin:32px 0 12px;text-transform:uppercase;letter-spacing:.08em;color:#78716c}
        .k{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}.k div{border:1px solid #e7e5e4;border-radius:12px;padding:14px}
        .k b{display:block;font-size:26px}.k span{font-size:12px;color:#78716c}
        table{width:100%;border-collapse:collapse}td{padding:6px 4px;border-bottom:1px solid #f5f5f4}
        .bar{height:10px;background:#e11d48;border-radius:5px}.q{color:#78716c;font-size:12px}
        @media print{body{margin:0}}</style></head><body>
        <p class="q">${esc(tenant?.name || '')}</p><h1>Zahlen zum Vereinsjahr ${jahr}</h1>
        <h2>Mitglieder</h2><div class="k">
          <div><b>${aktiv.length}</b><span>aktive Mitglieder</span></div>
          <div><b>${neu}</b><span>neu im ${jahr}</span></div>
          <div><b>${vorher}</b><span>Mitglied seit vor ${jahr}</span></div>
          <div><b>${nb.length}</b><span>Nachbarschaften</span></div></div>
        <h2>Beiträge ${jahr}</h2><div class="k">
          <div><b>${rechn.length}</b><span>Rechnungen</span></div>
          <div><b>${quote}%</b><span>bezahlt (Anzahl)</span></div>
          <div><b>${esc(chf(bezahlt))}</b><span>eingegangen</span></div>
          <div><b>${esc(chf(gestellt - bezahlt))}</b><span>noch offen</span></div></div>
        <h2>Nachbarschaften</h2><table>${nb.map(x => `<tr><td style="width:32%">${esc(x.name)}</td><td style="width:44%"><div class="bar" style="width:${Math.round(x.mitglieder / max * 100)}%"></div></td><td>${x.mitglieder} Mitglieder</td><td class="q">${x.quote}% bezahlt</td></tr>`).join('')}</table>
        <h2>Anlässe ${jahr} (${anlaesse.length})</h2><table>${anlaesse.sort((a, b) => a.date.localeCompare(b.date)).map(x => `<tr><td style="width:20%">${esc(new Date(x.date).toLocaleDateString('de-CH'))}</td><td>${esc(x.title)}</td></tr>`).join('') || '<tr><td class="q">keine</td></tr>'}</table>
        <p class="q" style="margin-top:40px">Erstellt am ${new Date().toLocaleDateString('de-CH')} aus den Daten der Plattform.</p>
        </body></html>`;
      const w = window.open('', '_blank');
      if (w) { w.document.write(html); w.document.close(); w.focus(); setTimeout(() => w.print(), 300); }
    } finally { setLaedt(false); }
  };

  return (
    <div className="flex flex-wrap items-center gap-3 p-4 bg-stone-50 rounded-2xl">
      <BarChart3 size={18} className="text-stone-500" />
      <p className="text-sm font-bold text-stone-800 flex-1 min-w-[200px]">{t('jb.titel')}</p>
      <select value={jahr} onChange={e => setJahr(Number(e.target.value))} className="p-2 bg-white border border-stone-200 rounded-lg text-sm">
        {[0, 1, 2, 3].map(i => new Date().getFullYear() - i).map(j => <option key={j} value={j}>{j}</option>)}
      </select>
      <button onClick={erstellen} disabled={laedt} className="px-4 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center gap-2">
        {laedt ? <Loader2 size={13} className="animate-spin" /> : <Printer size={13} />} {t('jb.knopf')}
      </button>
    </div>
  );
};

export default Jahresbericht;
