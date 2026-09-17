
import React, { useState, useEffect } from 'react';
import { AnimatePresence } from 'framer-motion';
import { useTranslation } from '../context/LanguageContext';
import { 
  Users, 
  CreditCard, 
  Globe, 
  Plus, 
  Search, 
  ShieldCheck, 
  TrendingUp,
  Server,
  LayoutDashboard,
  Briefcase,
  Settings,
  DollarSign,
  ChevronRight,
  LogOut,
  Bell,
  Mail,
  Trash2,
  ArrowRight
} from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, onSnapshot, addDoc, updateDoc, deleteDoc, doc, serverTimestamp, query, orderBy, createTenant } from '@/services/supabase-bridge';
import { Tenant } from '../types';
import SuperAdminTenantDialog from './SuperAdminTenantDialog';
import { useFeedback } from '../context/FeedbackContext';
import { signOut } from '@/services/supabase-bridge';
import { useNavigate } from 'react-router-dom';

const SuperAdminDashboard: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert, showPrompt } = useFeedback();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'OVERVIEW' | 'CRM' | 'FINANCES' | 'CONFIG'>('OVERVIEW');
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [leads, setLeads] = useState<any[]>([]);
  const [invoices, setInvoices] = useState<any[]>([]);
  const [domainsByTenant, setDomainsByTenant] = useState<Record<string, string[]>>({});
  const [memberCounts, setMemberCounts] = useState<Record<string, number>>({});
  const [manageTenant, setManageTenant] = useState<any | null>(null);

  useEffect(() => {
    const q = query(collection(db, 'tenants'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setTenants(snap.docs.map(d => ({ id: d.id, ...d.data() } as Tenant)));
      setLoading(false);
    });

    const unsubLeads = onSnapshot(query(collection(db, 'platform_leads'), orderBy('createdAt', 'desc')), (snap) => {
      setLeads(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (e) => console.error('[SuperAdmin] Interessenten laden fehlgeschlagen:', e));

    const unsubInvoices = onSnapshot(query(collection(db, 'platform_invoices'), orderBy('issuedAt', 'desc')), (snap) => {
      setInvoices(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (e) => console.error('[SuperAdmin] Rechnungen laden fehlgeschlagen:', e));

    const unsubDomains = onSnapshot(collection(db, 'tenant_domains'), (snap) => {
      const map: Record<string, string[]> = {};
      snap.docs.forEach(d => {
        const row: any = d.data();
        (map[row.tenantId] ||= []).push(row.domain);
      });
      setDomainsByTenant(map);
    }, () => {});

    // Mitgliederzahl je Verein: der Betreiber sieht die Vereinsdaten nicht,
    // deshalb kommt sie aus der oeffentlichen Projektion.
    const unsubMembers = onSnapshot(collection(db, 'public_members'), (snap) => {
      const map: Record<string, number> = {};
      snap.docs.forEach(d => { const r: any = d.data(); map[r.tenantId] = (map[r.tenantId] || 0) + 1; });
      setMemberCounts(map);
    }, () => {});

    return () => { unsub(); unsubLeads(); unsubInvoices(); unsubDomains(); unsubMembers(); };
  }, []);

  // --- Interessenten ---
  const addLead = async () => {
    const name = await showPrompt({ title: t('sa.lead_new'), message: t('sa.lead_name') });
    if (!name) return;
    try {
      await addDoc(collection(db, 'platform_leads'), { name, stage: 'LEAD', createdAt: new Date().toISOString() });
      showAlert({ type: 'success', message: t('sa.lead_created') });
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const moveLead = async (lead: any, stage: string) => {
    try {
      await updateDoc(doc(db, 'platform_leads', lead.id), { stage, updatedAt: new Date().toISOString() } as any);
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const removeLead = async (lead: any) => {
    try {
      await deleteDoc(doc(db, 'platform_leads', lead.id));
      showAlert({ type: 'success', message: t('sa.lead_deleted') });
    } catch (e: any) {
      showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
    }
  };

  const editLeadNote = async (lead: any) => {
    const note = await showPrompt({ title: lead.name, message: t('sa.billing_note'), defaultValue: lead.note || '' } as any);
    if (note === null || note === undefined) return;
    await updateDoc(doc(db, 'platform_leads', lead.id), { note } as any);
    showAlert({ type: 'success', message: t('sa.lead_saved') });
  };

  // --- Zahlen der Plattform, aus den hinterlegten Gebuehren statt fest im Code ---
  const money = (n: number) => n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const recurringPerYear = tenants.reduce((sum, tn: any) =>
    sum + (tn.subscriptionStatus === 'ACTIVE' ? Number(tn.annualFee) || 0 : 0), 0);
  const invoicedTotal = invoices.filter(i => i.status !== 'CANCELLED').reduce((s, i) => s + (Number(i.amount) || 0), 0);
  const paidTotal = invoices.filter(i => i.status === 'PAID').reduce((s, i) => s + (Number(i.amount) || 0), 0);
  const openTotal = invoices.filter(i => i.status === 'SENT' || i.status === 'DRAFT').reduce((s, i) => s + (Number(i.amount) || 0), 0);
  const tenantName = (id: string) => tenants.find(tn => tn.id === id)?.name || id;

  const cycleInvoiceStatus = async (inv: any) => {
    const next = inv.status === 'DRAFT' ? 'SENT' : inv.status === 'SENT' ? 'PAID' : 'DRAFT';
    await updateDoc(doc(db, 'platform_invoices', inv.id), {
      status: next,
      paidAt: next === 'PAID' ? new Date().toISOString().slice(0, 10) : null,
    } as any);
  };

  const handleCreateTenant = async () => {
      const name = await showPrompt({
          title: t('sa.new_tenant'),
          message: t('sa.new_tenant_prompt')
      });
      if (!name) return;

      // Ohne Domain ist die Website des Vereins nicht auffindbar, ohne
      // Administrator ist er nicht verwaltbar. Beides wird deshalb gleich hier
      // abgefragt, statt einen Verein anzulegen, den niemand erreichen kann.
      const domain = await showPrompt({
          title: t('sa.domain'),
          message: `Unter welcher Adresse ist ${name} erreichbar? (z.B. fcbasel.ch)`
      });
      if (!domain) return;

      const adminEmail = await showPrompt({
          title: t('sa.administrator'),
          message: t('sa.admin_prompt')
      });
      if (!adminEmail) return;

      const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

      try {
          const id = await createTenant(name, slug, domain.trim(), adminEmail.trim());
          showAlert({
              type: 'success',
              message: `Verein "${name}" angelegt (${id}). Erreichbar über ${domain.trim()}, sobald die Domain auf die Anwendung zeigt. ${adminEmail.trim()} kann sich jetzt registrieren und übernimmt ihn.`
          });
      } catch (e: any) {
          console.error('[SuperAdmin] Verein anlegen fehlgeschlagen:', e);
          showAlert({ type: 'error', message: `Anlegen fehlgeschlagen: ${e?.message || e?.code || 'unbekannter Fehler'}` });
      }
  };

  const handleLogout = async () => {
      await signOut(auth);
      navigate('/');
  };

  const filteredTenants = tenants.filter(t => t.name.toLowerCase().includes(searchTerm.toLowerCase()));

  // Render Sub-Views
  const renderContent = () => {
      switch(activeTab) {
          case 'CRM':
              return (
                  <div className="space-y-6">
                      <div className="flex justify-between items-center">
                          <h2 className="text-2xl font-bold">{t('sa.crm')}</h2>
                          <button onClick={addLead} className="bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg text-sm font-bold flex items-center gap-2">
                              <Plus size={14}/> {t('sa.lead_new')}
                          </button>
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                          {(['LEAD','TALKS','ONBOARDING'] as const).map((stage, idx) => (
                              <div key={stage} className="bg-white/5 p-4 rounded-2xl border border-white/5 min-h-[500px]">
                                  <h3 className={`font-bold text-xs uppercase tracking-widest mb-4 ${idx === 0 ? 'text-stone-400' : idx === 1 ? 'text-blue-400' : 'text-emerald-400'}`}>
                                      {t('sa.stage.' + stage)}
                                      <span className="ml-2 opacity-60">{leads.filter(l => l.stage === stage).length}</span>
                                  </h3>
                                  <div className="space-y-2">
                                      {leads.filter(l => l.stage === stage).length === 0 && (
                                          <p className="text-xs text-stone-600 italic px-1">{t('sa.lead_none')}</p>
                                      )}
                                      {leads.filter(l => l.stage === stage).map(l => (
                                          <div key={l.id} className="bg-white/5 p-3 rounded-xl border border-white/5 group">
                                              <div className="flex justify-between items-start gap-2">
                                                  <button onClick={() => editLeadNote(l)} className="text-left min-w-0 flex-1">
                                                      <p className="font-bold text-sm truncate">{l.name}</p>
                                                      <p className="text-xs text-stone-500 mt-1 line-clamp-2">
                                                          {l.note || (l.expectedMembers ? `${l.expectedMembers} ${t('sa.expected_members')}` : '—')}
                                                      </p>
                                                  </button>
                                                  <button onClick={() => removeLead(l)} title={t('common.delete')}
                                                          className="p-1 text-stone-600 hover:text-rose-400 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                                                      <Trash2 size={13}/>
                                                  </button>
                                              </div>
                                              <div className="flex gap-1 mt-3 opacity-0 group-hover:opacity-100 transition-opacity">
                                                  {(['LEAD','TALKS','ONBOARDING','WON','LOST'] as const).filter(x => x !== l.stage).map(x => (
                                                      <button key={x} onClick={() => moveLead(l, x)} title={`${t('sa.move_to')}: ${t('sa.stage.' + x)}`}
                                                              className="px-1.5 py-0.5 rounded bg-white/10 hover:bg-white/20 text-[9px] font-bold uppercase tracking-wider">
                                                          {t('sa.stage.' + x).split(' ')[0]}
                                                      </button>
                                                  ))}
                                              </div>
                                          </div>
                                      ))}
                                  </div>
                              </div>
                          ))}
                      </div>
                  </div>
              );
          case 'FINANCES':
              return (
                  <div className="space-y-8">
                      <h2 className="text-2xl font-bold">{t('sa.revenue')}</h2>
                      <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
                          <div className="bg-emerald-500/10 border border-emerald-500/20 p-6 rounded-3xl">
                              <p className="text-emerald-400 text-xs font-bold uppercase tracking-widest mb-2">{t('sa.recurring')}</p>
                              <p className="text-3xl font-mono font-bold text-white">CHF {money(recurringPerYear)}</p>
                          </div>
                          <div className="bg-white/5 border border-white/10 p-6 rounded-3xl">
                              <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">{t('sa.invoiced_total')}</p>
                              <p className="text-3xl font-mono font-bold text-white">CHF {money(invoicedTotal)}</p>
                          </div>
                          <div className="bg-white/5 border border-white/10 p-6 rounded-3xl">
                              <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">{t('sa.paid_total')}</p>
                              <p className="text-3xl font-mono font-bold text-emerald-400">CHF {money(paidTotal)}</p>
                          </div>
                          <div className="bg-white/5 border border-white/10 p-6 rounded-3xl">
                              <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">{t('sa.open_total')}</p>
                              <p className="text-3xl font-mono font-bold text-amber-400">CHF {money(openTotal)}</p>
                          </div>
                      </div>

                      <div className="bg-white/5 border border-white/10 rounded-3xl overflow-hidden">
                          <div className="p-6 border-b border-white/10">
                              <h3 className="font-bold">{t('sa.invoices')}</h3>
                          </div>
                          {invoices.length === 0 ? (
                              <p className="p-8 text-sm text-stone-500 italic">{t('sa.invoices_none')}</p>
                          ) : (
                          <table className="w-full text-left text-sm">
                              <thead className="text-stone-500 font-bold uppercase text-[10px]">
                                  <tr>
                                      <th className="p-6">{t('sa.tenant')}</th>
                                      <th className="p-6">{t('admin.finance.invoiceNum')}</th>
                                      <th className="p-6">{t('field.date')}</th>
                                      <th className="p-6 text-right">{t('field.amount')}</th>
                                      <th className="p-6 text-right">{t('field.status')}</th>
                                  </tr>
                              </thead>
                              <tbody className="divide-y divide-white/5">
                                  {invoices.map(inv => (
                                      <tr key={inv.id}>
                                          <td className="p-6 font-bold">{tenantName(inv.tenantId)}</td>
                                          <td className="p-6 text-stone-400 font-mono text-xs">
                                              {inv.invoiceNumber} · {t('sa.kind.' + inv.kind)}{inv.year ? ` ${inv.year}` : ''}
                                          </td>
                                          <td className="p-6 text-stone-500">{inv.issuedAt}</td>
                                          <td className="p-6 text-right font-mono text-white">{money(Number(inv.amount) || 0)} {inv.currency}</td>
                                          <td className="p-6 text-right">
                                              <button onClick={() => cycleInvoiceStatus(inv)}
                                                  title={t('sa.move_to')}
                                                  className={`px-2.5 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-colors ${
                                                      inv.status === 'PAID' ? 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30'
                                                      : inv.status === 'SENT' ? 'bg-amber-500/20 text-amber-400 hover:bg-amber-500/30'
                                                      : 'bg-white/10 text-stone-300 hover:bg-white/20'}`}>
                                                  {t('sa.istatus.' + inv.status)}
                                              </button>
                                          </td>
                                      </tr>
                                  ))}
                              </tbody>
                          </table>
                          )}
                      </div>
                  </div>
              );
          case 'CONFIG':
              return (
                  <div className="space-y-8">
                      <h2 className="text-2xl font-bold">{t('sa.global_config')}</h2>
                      <div className="grid grid-cols-2 gap-8">
                          <div className="bg-white/5 border border-white/10 p-8 rounded-3xl space-y-6">
                              <h3 className="font-bold flex items-center gap-2"><Settings size={18}/> {t('sa.pricing')}</h3>
                              <div className="space-y-4">
                                  <div>
                                      <label className="text-xs font-bold text-stone-400 block mb-1">{t('sa.free_limit')}</label>
                                      <input type="number" defaultValue="50" className="w-full bg-stone-900 border border-white/10 p-3 rounded-xl text-white outline-none" />
                                  </div>
                                  <div>
                                      <label className="text-xs font-bold text-stone-400 block mb-1">{t('sa.pro_price')}</label>
                                      <input type="number" defaultValue="49" className="w-full bg-stone-900 border border-white/10 p-3 rounded-xl text-white outline-none" />
                                  </div>
                              </div>
                              <button className="w-full bg-white text-stone-900 py-3 rounded-xl font-bold">{t('sa.update_pricing')}</button>
                          </div>

                          <div className="bg-white/5 border border-white/10 p-8 rounded-3xl space-y-6">
                              <h3 className="font-bold flex items-center gap-2"><Server size={18}/> {t('set.status')}</h3>
                              <div className="space-y-4">
                                  <div className="flex items-center justify-between p-3 bg-stone-900 rounded-xl">
                                      <span className="font-bold text-sm">{t('sa.maintenance_global')}</span>
                                      <div className="w-10 h-5 bg-stone-700 rounded-full relative cursor-pointer"><div className="absolute left-1 top-1 w-3 h-3 bg-white rounded-full"></div></div>
                                  </div>
                                  <div className="flex items-center justify-between p-3 bg-stone-900 rounded-xl">
                                      <span className="font-bold text-sm">{t('sa.allow_signups')}</span>
                                      <div className="w-10 h-5 bg-green-500 rounded-full relative cursor-pointer"><div className="absolute right-1 top-1 w-3 h-3 bg-white rounded-full"></div></div>
                                  </div>
                              </div>
                          </div>
                      </div>
                  </div>
              );
          default: // OVERVIEW
              return (
                  <>
                    <div className="flex justify-between items-center mb-8">
                        <div>
                            <h2 className="text-2xl font-bold">{t('sa.tenants')}</h2>
                            <p className="text-stone-400 text-sm">{t('sa.tenants_desc')}</p>
                        </div>
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-500" size={16} />
                            <input 
                                type="text" 
                                placeholder={t('sa.search_tenant')} 
                                value={searchTerm}
                                onChange={e => setSearchTerm(e.target.value)}
                                className="bg-stone-800 border border-white/10 rounded-xl pl-10 pr-4 py-2 text-sm text-white focus:border-rose-500 outline-none w-64"
                            />
                        </div>
                    </div>

                    {/* Tenant List */}
                    <div className="bg-white/5 border border-white/10 rounded-3xl overflow-hidden">
                        <table className="w-full text-left text-sm">
                            <thead className="bg-white/5 text-stone-400 font-bold uppercase text-xs">
                                <tr>
                                    <th className="p-6">{t('field.name')}</th>
                                    <th className="p-6">{t('sa.subdomain')}</th>
                                    <th className="p-6">{t('sa.plan')}</th>
                                    <th className="p-6">{t('field.status')}</th>
                                    <th className="p-6 text-right">{t('common.actions')}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5">
                                {filteredTenants.map(tn => (
                                    <tr key={tn.id} className="hover:bg-white/5 transition-colors group">
                                        <td className="p-6 font-bold flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-rose-500 to-purple-600 flex items-center justify-center text-xs text-white">
                                                {tn.name.charAt(0)}
                                            </div>
                                            {tn.name}
                                        </td>
                                        <td className="p-6 font-mono text-stone-400">{tn.slug}.unityhub.li</td>
                                        <td className="p-6">
                                            <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${tn.subscriptionPlan === 'PRO' ? 'bg-rose-500/20 text-rose-400' : 'bg-stone-700 text-stone-300'}`}>
                                                {tn.subscriptionPlan}
                                            </span>
                                        </td>
                                        <td className="p-6">
                                            <span className={`flex items-center gap-2 ${tn.subscriptionStatus === 'ACTIVE' ? 'text-emerald-400' : 'text-red-400'}`}>
                                                <div className={`w-2 h-2 rounded-full ${tn.subscriptionStatus === 'ACTIVE' ? 'bg-emerald-400' : 'bg-red-400'}`} />
                                                {tn.subscriptionStatus}
                                            </span>
                                        </td>
                                        <td className="p-6 text-right">
                                            <button onClick={() => setManageTenant(tn)} className="text-stone-400 hover:text-white font-bold text-xs flex items-center gap-1 ml-auto transition-colors">
                                                {t('sa.manage')} <ChevronRight size={14} />
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                  </>
              );
      }
  };

  return (
    <>
    <div className="min-h-screen bg-stone-950 text-white flex">
        {/* Sidebar */}
        <aside className="w-64 border-r border-white/5 flex flex-col fixed h-full bg-stone-950 z-20">
            <div className="p-8 pb-4">
                <div className="flex items-center gap-3 text-rose-500 mb-8">
                    <ShieldCheck size={28} />
                    <span className="font-display font-bold text-xl italic text-white">UnityHub</span>
                </div>
                
                <div className="space-y-1">
                    <button onClick={() => setActiveTab('OVERVIEW')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'OVERVIEW' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <LayoutDashboard size={18} /> {t('sa.overview')}
                    </button>
                    <button onClick={() => setActiveTab('CRM')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'CRM' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <Briefcase size={18} /> {t('sa.crm_nav')}
                    </button>
                    <button onClick={() => setActiveTab('FINANCES')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'FINANCES' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <DollarSign size={18} /> {t('sa.finances')}
                    </button>
                    <button onClick={() => setActiveTab('CONFIG')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'CONFIG' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <Settings size={18} /> {t('sa.configuration')}
                    </button>
                </div>
            </div>

            <div className="mt-auto p-8 pt-4 border-t border-white/5">
                <div className="flex items-center gap-3 mb-6">
                    <div className="w-10 h-10 rounded-full bg-stone-800 flex items-center justify-center">
                        <span className="font-bold">A</span>
                    </div>
                    <div>
                        <p className="text-sm font-bold">{t('sa.administrator')}</p>
                        <p className="text-xs text-stone-500">info@unityhub.li</p>
                    </div>
                </div>
                <button onClick={handleLogout} className="w-full text-left px-4 py-2 text-xs font-bold text-stone-500 hover:text-rose-500 flex items-center gap-2 transition-colors">
                    <LogOut size={14} /> {t('sa.sign_out')}
                </button>
            </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 ml-64 p-8 lg:p-12">
            <header className="flex justify-between items-center mb-12">
                <div>
                    <h1 className="text-3xl font-bold">{t('sa.title')}</h1>
                    <p className="text-stone-400 text-sm">{t('sa.welcome')}</p>
                </div>
                <div className="flex gap-4">
                    <button className="p-3 bg-white/5 rounded-xl text-stone-400 hover:text-white transition-colors relative">
                        <Bell size={20} />
                        <div className="absolute top-3 right-3 w-2 h-2 bg-rose-500 rounded-full" />
                    </button>
                    <button onClick={handleCreateTenant} className="bg-rose-600 hover:bg-rose-700 px-6 py-3 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-rose-900/20">
                        <Plus size={18} /> {t('sa.new_tenant')}
                    </button>
                </div>
            </header>

            {renderContent()}
        </main>
    </div>

    <AnimatePresence>
      <SuperAdminTenantDialog
        tenant={manageTenant}
        domains={manageTenant ? (domainsByTenant[manageTenant.id] || []) : []}
        memberCount={manageTenant ? (memberCounts[manageTenant.id] || 0) : 0}
        invoices={invoices}
        onClose={() => setManageTenant(null)}
      />
    </AnimatePresence>
    </>
  );
};

export default SuperAdminDashboard;
