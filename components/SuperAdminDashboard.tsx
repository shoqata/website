
import React, { useState, useEffect } from 'react';
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
  Mail
} from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, onSnapshot, addDoc, serverTimestamp, query, orderBy } from '@/services/supabase-bridge';
import { Tenant } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { signOut } from '@/services/supabase-bridge';
import { useNavigate } from 'react-router-dom';

const SuperAdminDashboard: React.FC = () => {
  const { showAlert, showPrompt } = useFeedback();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'OVERVIEW' | 'CRM' | 'FINANCES' | 'CONFIG'>('OVERVIEW');
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'tenants'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setTenants(snap.docs.map(d => ({ id: d.id, ...d.data() } as Tenant)));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleCreateTenant = async () => {
      const name = await showPrompt({
          title: "New Association",
          message: "Enter the name of the new association (e.g. FC Basel):"
      });
      if (!name) return;

      const slug = name.toLowerCase().replace(/[^a-z0-9]/g, '-');
      
      try {
          await addDoc(collection(db, 'tenants'), {
              name,
              slug,
              subscriptionPlan: 'FREE',
              subscriptionStatus: 'ACTIVE',
              createdAt: serverTimestamp(),
              contactEmail: '',
              memberCount: 0
          });
          showAlert({ type: 'success', message: `Tenant "${name}" created. URL: ${slug}.unityhub.li` });
      } catch (e: any) {
          showAlert({ type: 'error', message: e.message });
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
                          <h2 className="text-2xl font-bold">Customer Relationship Management</h2>
                          <button className="bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg text-sm font-bold">+ New Lead</button>
                      </div>
                      <div className="grid grid-cols-3 gap-6">
                          <div className="bg-white/5 p-4 rounded-2xl border border-white/5 h-[500px]">
                              <h3 className="font-bold text-stone-400 text-xs uppercase tracking-widest mb-4">Potential Leads</h3>
                              <div className="space-y-2">
                                  <div className="bg-white/5 p-3 rounded-xl hover:bg-white/10 cursor-pointer transition-colors">
                                      <p className="font-bold text-sm">Verein Albanischer Lehrer</p>
                                      <p className="text-xs text-stone-500 mt-1">Interested in Pro Plan</p>
                                  </div>
                                  <div className="bg-white/5 p-3 rounded-xl hover:bg-white/10 cursor-pointer transition-colors">
                                      <p className="font-bold text-sm">FC Prishtina Zürich</p>
                                      <p className="text-xs text-stone-500 mt-1">Needs Payment Gateway</p>
                                  </div>
                              </div>
                          </div>
                          <div className="bg-white/5 p-4 rounded-2xl border border-white/5 h-[500px]">
                              <h3 className="font-bold text-blue-400 text-xs uppercase tracking-widest mb-4">In Discussion</h3>
                              <div className="space-y-2">
                                  <div className="bg-white/5 p-3 rounded-xl hover:bg-white/10 cursor-pointer transition-colors border-l-2 border-blue-500">
                                      <p className="font-bold text-sm">Moschee Will</p>
                                      <p className="text-xs text-stone-500 mt-1">Waiting for Board Approval</p>
                                  </div>
                              </div>
                          </div>
                          <div className="bg-white/5 p-4 rounded-2xl border border-white/5 h-[500px]">
                              <h3 className="font-bold text-emerald-400 text-xs uppercase tracking-widest mb-4">Onboarding</h3>
                              <div className="space-y-2">
                                  {tenants.slice(0,2).map(t => (
                                      <div key={t.id} className="bg-white/5 p-3 rounded-xl hover:bg-white/10 cursor-pointer transition-colors border-l-2 border-emerald-500">
                                          <p className="font-bold text-sm">{t.name}</p>
                                          <p className="text-xs text-stone-500 mt-1">Setup in progress</p>
                                      </div>
                                  ))}
                              </div>
                          </div>
                      </div>
                  </div>
              );
          case 'FINANCES':
              return (
                  <div className="space-y-8">
                      <h2 className="text-2xl font-bold">Platform Revenue</h2>
                      <div className="grid grid-cols-3 gap-6">
                          <div className="bg-emerald-500/10 border border-emerald-500/20 p-6 rounded-3xl">
                              <p className="text-emerald-400 text-xs font-bold uppercase tracking-widest mb-2">Total MRR</p>
                              <p className="text-4xl font-mono font-bold text-white">CHF 4,250</p>
                          </div>
                          <div className="bg-white/5 border border-white/10 p-6 rounded-3xl">
                              <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">Pending Invoices</p>
                              <p className="text-4xl font-mono font-bold text-white">CHF 850</p>
                          </div>
                          <div className="bg-white/5 border border-white/10 p-6 rounded-3xl">
                              <p className="text-stone-400 text-xs font-bold uppercase tracking-widest mb-2">Active Subscriptions</p>
                              <p className="text-4xl font-mono font-bold text-white">{tenants.filter(t => t.subscriptionStatus === 'ACTIVE').length}</p>
                          </div>
                      </div>
                      
                      <div className="bg-white/5 border border-white/10 rounded-3xl overflow-hidden">
                          <div className="p-6 border-b border-white/10">
                              <h3 className="font-bold">Recent Transactions</h3>
                          </div>
                          <table className="w-full text-left text-sm">
                              <thead className="text-stone-500 font-bold uppercase text-[10px]">
                                  <tr>
                                      <th className="p-6">Tenant</th>
                                      <th className="p-6">Plan</th>
                                      <th className="p-6">Date</th>
                                      <th className="p-6 text-right">Amount</th>
                                  </tr>
                              </thead>
                              <tbody className="divide-y divide-white/5">
                                  {tenants.slice(0,5).map(t => (
                                      <tr key={t.id}>
                                          <td className="p-6 font-bold">{t.name}</td>
                                          <td className="p-6 text-stone-400">{t.subscriptionPlan} Monthly</td>
                                          <td className="p-6 text-stone-500">Today</td>
                                          <td className="p-6 text-right font-mono text-emerald-400">+ CHF 49.00</td>
                                      </tr>
                                  ))}
                              </tbody>
                          </table>
                      </div>
                  </div>
              );
          case 'CONFIG':
              return (
                  <div className="space-y-8">
                      <h2 className="text-2xl font-bold">Global Configuration</h2>
                      <div className="grid grid-cols-2 gap-8">
                          <div className="bg-white/5 border border-white/10 p-8 rounded-3xl space-y-6">
                              <h3 className="font-bold flex items-center gap-2"><Settings size={18}/> Pricing Plans</h3>
                              <div className="space-y-4">
                                  <div>
                                      <label className="text-xs font-bold text-stone-400 block mb-1">Free Plan Limit (Members)</label>
                                      <input type="number" defaultValue="50" className="w-full bg-stone-900 border border-white/10 p-3 rounded-xl text-white outline-none" />
                                  </div>
                                  <div>
                                      <label className="text-xs font-bold text-stone-400 block mb-1">Pro Plan Price (CHF)</label>
                                      <input type="number" defaultValue="49" className="w-full bg-stone-900 border border-white/10 p-3 rounded-xl text-white outline-none" />
                                  </div>
                              </div>
                              <button className="w-full bg-white text-stone-900 py-3 rounded-xl font-bold">Update Pricing</button>
                          </div>

                          <div className="bg-white/5 border border-white/10 p-8 rounded-3xl space-y-6">
                              <h3 className="font-bold flex items-center gap-2"><Server size={18}/> System Status</h3>
                              <div className="space-y-4">
                                  <div className="flex items-center justify-between p-3 bg-stone-900 rounded-xl">
                                      <span className="font-bold text-sm">Maintenance Mode (Global)</span>
                                      <div className="w-10 h-5 bg-stone-700 rounded-full relative cursor-pointer"><div className="absolute left-1 top-1 w-3 h-3 bg-white rounded-full"></div></div>
                                  </div>
                                  <div className="flex items-center justify-between p-3 bg-stone-900 rounded-xl">
                                      <span className="font-bold text-sm">Allow New Signups</span>
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
                            <h2 className="text-2xl font-bold">Tenants Overview</h2>
                            <p className="text-stone-400 text-sm">Manage all associations on UnityHub.</p>
                        </div>
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-500" size={16} />
                            <input 
                                type="text" 
                                placeholder="Search tenant..." 
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
                                    <th className="p-6">Name</th>
                                    <th className="p-6">Subdomain</th>
                                    <th className="p-6">Plan</th>
                                    <th className="p-6">Status</th>
                                    <th className="p-6 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5">
                                {filteredTenants.map(t => (
                                    <tr key={t.id} className="hover:bg-white/5 transition-colors group">
                                        <td className="p-6 font-bold flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-rose-500 to-purple-600 flex items-center justify-center text-xs text-white">
                                                {t.name.charAt(0)}
                                            </div>
                                            {t.name}
                                        </td>
                                        <td className="p-6 font-mono text-stone-400">{t.slug}.unityhub.li</td>
                                        <td className="p-6">
                                            <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${t.subscriptionPlan === 'PRO' ? 'bg-rose-500/20 text-rose-400' : 'bg-stone-700 text-stone-300'}`}>
                                                {t.subscriptionPlan}
                                            </span>
                                        </td>
                                        <td className="p-6">
                                            <span className={`flex items-center gap-2 ${t.subscriptionStatus === 'ACTIVE' ? 'text-emerald-400' : 'text-red-400'}`}>
                                                <div className={`w-2 h-2 rounded-full ${t.subscriptionStatus === 'ACTIVE' ? 'bg-emerald-400' : 'bg-red-400'}`} />
                                                {t.subscriptionStatus}
                                            </span>
                                        </td>
                                        <td className="p-6 text-right">
                                            <button className="text-stone-400 hover:text-white font-bold text-xs flex items-center gap-1 ml-auto opacity-0 group-hover:opacity-100 transition-opacity">
                                                Manage <ChevronRight size={14} />
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
                        <LayoutDashboard size={18} /> Overview
                    </button>
                    <button onClick={() => setActiveTab('CRM')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'CRM' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <Briefcase size={18} /> CRM / Leads
                    </button>
                    <button onClick={() => setActiveTab('FINANCES')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'FINANCES' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <DollarSign size={18} /> Finances
                    </button>
                    <button onClick={() => setActiveTab('CONFIG')} className={`w-full text-left px-4 py-3 rounded-xl text-sm font-bold flex items-center gap-3 transition-all ${activeTab === 'CONFIG' ? 'bg-white/10 text-white' : 'text-stone-400 hover:text-white hover:bg-white/5'}`}>
                        <Settings size={18} /> Configuration
                    </button>
                </div>
            </div>

            <div className="mt-auto p-8 pt-4 border-t border-white/5">
                <div className="flex items-center gap-3 mb-6">
                    <div className="w-10 h-10 rounded-full bg-stone-800 flex items-center justify-center">
                        <span className="font-bold">A</span>
                    </div>
                    <div>
                        <p className="text-sm font-bold">Admin</p>
                        <p className="text-xs text-stone-500">info@unityhub.li</p>
                    </div>
                </div>
                <button onClick={handleLogout} className="w-full text-left px-4 py-2 text-xs font-bold text-stone-500 hover:text-rose-500 flex items-center gap-2 transition-colors">
                    <LogOut size={14} /> Sign Out
                </button>
            </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 ml-64 p-8 lg:p-12">
            <header className="flex justify-between items-center mb-12">
                <div>
                    <h1 className="text-3xl font-bold">Super Admin Dashboard</h1>
                    <p className="text-stone-400 text-sm">Welcome back, Admin.</p>
                </div>
                <div className="flex gap-4">
                    <button className="p-3 bg-white/5 rounded-xl text-stone-400 hover:text-white transition-colors relative">
                        <Bell size={20} />
                        <div className="absolute top-3 right-3 w-2 h-2 bg-rose-500 rounded-full" />
                    </button>
                    <button onClick={handleCreateTenant} className="bg-rose-600 hover:bg-rose-700 px-6 py-3 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-rose-900/20">
                        <Plus size={18} /> New Tenant
                    </button>
                </div>
            </header>

            {renderContent()}
        </main>
    </div>
  );
};

export default SuperAdminDashboard;
