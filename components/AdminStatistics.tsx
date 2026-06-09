
import React, { useMemo, useState } from 'react';
import { 
  Bar, 
  BarChart, 
  CartesianGrid, 
  XAxis, 
  Area, 
  AreaChart, 
} from 'recharts';
import { ChartContainer, ChartTooltip, ChartTooltipContent, ChartLegend, ChartLegendContent } from './ui/Chart';
import { UserProfile, Payment, Neighborhood } from '../types';
import { 
  TrendingUp, 
  Users, 
  AlertCircle, 
  Clock, 
  Search,
} from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';

interface AdminStatisticsProps {
  users: UserProfile[];
  payments: Payment[];
  neighborhoods: Neighborhood[];
  selectedYear?: number;
}

const AdminStatistics: React.FC<AdminStatisticsProps> = ({ users, payments, neighborhoods, selectedYear }) => {
  const { t } = useTranslation();
  const [memberFilter, setMemberFilter] = useState<'ALL' | 'LATE' | 'UNPAID'>('ALL');
  const [searchTerm, setSearchTerm] = useState('');

  // Filter payments by year first if provided
  const yearPayments = useMemo(() => {
      if (!selectedYear) return payments;
      return payments.filter(p => p.timestamp?.toDate().getFullYear() === selectedYear);
  }, [payments, selectedYear]);

  // --- 1. Neighborhood Comparison Data ---
  const neighborhoodData = useMemo(() => {
    return neighborhoods.map(n => {
      const nMembers = users.filter(u => u.neighborhoodId === n.id);
      const memberIds = nMembers.map(u => u.id);
      
      const payingMembers = new Set(
        yearPayments
          .filter(p => memberIds.includes(p.userId) && p.status === 'PAID')
          .map(p => p.userId)
      ).size;

      const participation = nMembers.length > 0 ? Math.round((payingMembers / nMembers.length) * 100) : 0;

      return {
        name: n.name,
        totalMembers: nMembers.length,
        payingMembers: payingMembers,
        participation: participation,
        fill: "var(--color-payingMembers)",
      };
    }).sort((a, b) => b.totalMembers - a.totalMembers);
  }, [neighborhoods, users, yearPayments]);

  const chartConfigNeighborhood = {
    totalMembers: {
      label: t('admin.stats.totalMembers'),
      color: "#e7e5e4", // stone-200
    },
    payingMembers: {
      label: `${t('admin.stats.payers')} ${selectedYear}`,
      color: "#f43f5e", // primary rose
    },
  };

  // --- 2. Historical Revenue Data ---
  const historicalData = useMemo(() => {
    const agg: Record<string, number> = {};
    yearPayments.forEach(p => {
        if (p.status === 'PAID' && p.timestamp) {
            const date = p.timestamp.toDate();
            const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            agg[key] = (agg[key] || 0) + p.amount;
        }
    });

    const result = Object.entries(agg).map(([date, revenue]) => ({ date, revenue }));
    
    if (result.length < 1) {
        return [
            { date: `${selectedYear}-01`, revenue: 0 }
        ];
    }
    return result.sort((a, b) => a.date.localeCompare(b.date));
  }, [yearPayments, selectedYear]);

  const chartConfigHistory = {
    revenue: {
      label: `${t('admin.stats.revenue')} (CHF)`,
      color: "#10b981", // emerald-500
    },
  };

  // --- 3. Member Detailed Payment Analysis ---
  const memberPaymentAnalysis = useMemo(() => {
    return users.map(u => {
      const uPayments = yearPayments.filter(p => p.userId === u.id).sort((a, b) => b.timestamp?.toDate().getTime() - a.timestamp?.toDate().getTime());
      
      const lastPayment = uPayments.find(p => p.status === 'PAID');
      const hasLatePayment = uPayments.some(p => p.status === 'PAID' && p.dueDate && p.timestamp.toDate() > new Date(p.dueDate));
      const hasUnpaid = uPayments.some(p => p.status === 'PENDING' || p.status === 'OVERDUE');
      
      let status: 'GREAT' | 'LATE' | 'UNPAID' | 'NEW' = 'NEW';
      if (uPayments.length > 0) {
          if (hasUnpaid) status = 'UNPAID';
          else if (hasLatePayment) status = 'LATE';
          else status = 'GREAT';
      }

      return {
        id: u.id,
        name: u.displayName,
        neighborhood: neighborhoods.find(n => n.id === u.neighborhoodId)?.name || '-',
        lastPaid: lastPayment ? lastPayment.timestamp?.toDate().toLocaleDateString() : 'Never',
        totalPaid: uPayments.filter(p => p.status === 'PAID').reduce((sum, p) => sum + p.amount, 0),
        status
      };
    });
  }, [users, yearPayments, neighborhoods]);

  const filteredMembers = memberPaymentAnalysis.filter(m => {
      const matchSearch = m.name?.toLowerCase().includes(searchTerm.toLowerCase()) || m.neighborhood.toLowerCase().includes(searchTerm.toLowerCase());
      if (memberFilter === 'ALL') return matchSearch;
      return matchSearch && m.status === memberFilter;
  });

  const totalCollected = yearPayments.filter(p => p.status === 'PAID').reduce((sum, p) => sum + p.amount, 0);
  const latePayersCount = memberPaymentAnalysis.filter(m => m.status === 'LATE').length;
  const unpaidCount = memberPaymentAnalysis.filter(m => m.status === 'UNPAID').length;

  return (
    <div className="space-y-8">
        
        {/* KPI Row */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.stats.revenue')} {selectedYear}</p>
                <div className="flex items-end gap-2">
                    <h3 className="text-3xl font-display font-bold text-stone-900">{totalCollected.toLocaleString()}</h3>
                    <span className="text-sm font-bold text-stone-400 mb-1">CHF</span>
                </div>
            </div>
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.stats.late')}</p>
                <div className="flex items-center gap-2">
                    <h3 className="text-3xl font-display font-bold text-amber-500">{latePayersCount}</h3>
                    <Clock size={20} className="text-amber-500/50" />
                </div>
            </div>
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.stats.unpaid')}</p>
                <div className="flex items-center gap-2">
                    <h3 className="text-3xl font-display font-bold text-rose-500">{unpaidCount}</h3>
                    <AlertCircle size={20} className="text-rose-500/50" />
                </div>
            </div>
            <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-2">{t('admin.stats.participation')}</p>
                <div className="flex items-center gap-2">
                    <h3 className="text-3xl font-display font-bold text-emerald-500">
                        {Math.round(neighborhoodData.reduce((acc, n) => acc + n.participation, 0) / (neighborhoodData.length || 1))}%
                    </h3>
                    <TrendingUp size={20} className="text-emerald-500/50" />
                </div>
            </div>
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Neighborhood Comparison */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                <div className="mb-6">
                    <h3 className="text-xl font-bold text-stone-900">{t('admin.stats.neighborhoodPerf')}</h3>
                    <p className="text-sm text-stone-500">Comparing member base vs. active payers.</p>
                </div>
                <div className="h-[300px] w-full">
                    <ChartContainer config={chartConfigNeighborhood} className="w-full h-full">
                        <BarChart data={neighborhoodData} margin={{ top: 20, right: 0, left: 0, bottom: 0 }}>
                            <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="#f5f5f4" />
                            <XAxis 
                                dataKey="name" 
                                tickLine={false} 
                                tickMargin={10} 
                                axisLine={false} 
                                tick={{ fontSize: 10, fill: '#78716c' }}
                            />
                            <ChartTooltip cursor={false} content={<ChartTooltipContent indicator="dashed" />} />
                            <ChartLegend content={<ChartLegendContent />} />
                            <Bar dataKey="totalMembers" fill="var(--color-totalMembers)" radius={[4, 4, 0, 0]} barSize={20} />
                            <Bar dataKey="payingMembers" fill="var(--color-payingMembers)" radius={[4, 4, 0, 0]} barSize={20} />
                        </BarChart>
                    </ChartContainer>
                </div>
            </div>

            {/* Historical Revenue */}
            <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
                <div className="mb-6">
                    <h3 className="text-xl font-bold text-stone-900">{t('admin.stats.history')} {selectedYear}</h3>
                    <p className="text-sm text-stone-500">Monthly collection over time.</p>
                </div>
                <div className="h-[300px] w-full">
                    <ChartContainer config={chartConfigHistory} className="w-full h-full">
                        <AreaChart data={historicalData} margin={{ top: 20, right: 0, left: 0, bottom: 0 }}>
                            <defs>
                                <linearGradient id="fillRevenue" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="var(--color-revenue)" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="var(--color-revenue)" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="#f5f5f4" />
                            <XAxis 
                                dataKey="date" 
                                tickLine={false} 
                                tickMargin={10} 
                                axisLine={false}
                                tick={{ fontSize: 10, fill: '#78716c' }} 
                            />
                            <ChartTooltip cursor={false} content={<ChartTooltipContent indicator="line" />} />
                            <Area 
                                dataKey="revenue" 
                                type="monotone" 
                                fill="url(#fillRevenue)" 
                                stroke="var(--color-revenue)" 
                                strokeWidth={3}
                            />
                        </AreaChart>
                    </ChartContainer>
                </div>
            </div>
        </div>

        {/* Detailed Member Table */}
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
            <div className="p-8 border-b border-stone-100 flex flex-col md:flex-row justify-between items-center gap-6">
                <div>
                    <h3 className="text-xl font-bold text-stone-900 flex items-center gap-2"><Users size={20} /> {t('admin.stats.memberDetail')}</h3>
                    <p className="text-sm text-stone-500">Detailed breakdown of payment behavior for {selectedYear}.</p>
                </div>
                <div className="flex gap-4 w-full md:w-auto">
                    <div className="relative flex-1 md:w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400" size={16} />
                        <input 
                            type="text" 
                            placeholder={t('common.search')} 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full pl-10 pr-4 py-2 bg-stone-50 border border-stone-200 rounded-xl text-sm outline-none focus:border-primary/30"
                        />
                    </div>
                    <div className="flex bg-stone-50 p-1 rounded-xl border border-stone-200">
                        <button onClick={() => setMemberFilter('ALL')} className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${memberFilter === 'ALL' ? 'bg-white shadow-sm text-stone-900' : 'text-stone-400'}`}>{t('status.all')}</button>
                        <button onClick={() => setMemberFilter('LATE')} className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${memberFilter === 'LATE' ? 'bg-white shadow-sm text-amber-600' : 'text-stone-400'}`}>Late</button>
                        <button onClick={() => setMemberFilter('UNPAID')} className={`px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${memberFilter === 'UNPAID' ? 'bg-white shadow-sm text-rose-600' : 'text-stone-400'}`}>Unpaid</button>
                    </div>
                </div>
            </div>
            
            <div className="max-h-[500px] overflow-y-auto custom-scrollbar">
                <table className="w-full text-left">
                    <thead className="bg-stone-50 sticky top-0 z-10 text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                        <tr>
                            <th className="px-8 py-4">{t('admin.finance.member')}</th>
                            <th className="px-8 py-4">{t('admin.tab.neighborhoods')}</th>
                            <th className="px-8 py-4">Last Payment</th>
                            <th className="px-8 py-4">Total Paid ({selectedYear})</th>
                            <th className="px-8 py-4 text-right">{t('field.status')}</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-stone-50">
                        {filteredMembers.map(m => (
                            <tr key={m.id} className="hover:bg-stone-50/50 transition-colors">
                                <td className="px-8 py-4 font-bold text-stone-900">{m.name}</td>
                                <td className="px-8 py-4 text-sm text-stone-500">{m.neighborhood}</td>
                                <td className="px-8 py-4 text-sm font-mono text-stone-500">{m.lastPaid}</td>
                                <td className="px-8 py-4 font-bold text-stone-900">{m.totalPaid.toFixed(2)}</td>
                                <td className="px-8 py-4 text-right">
                                    <span className={`px-3 py-1 rounded-full text-[10px] font-bold ${
                                        m.status === 'GREAT' ? 'bg-green-100 text-green-600' :
                                        m.status === 'LATE' ? 'bg-amber-100 text-amber-600' :
                                        m.status === 'UNPAID' ? 'bg-rose-100 text-rose-600' :
                                        'bg-stone-100 text-stone-400'
                                    }`}>
                                        {m.status}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {filteredMembers.length === 0 && (
                    <div className="p-12 text-center text-stone-400 italic">No members found matching filter.</div>
                )}
            </div>
        </div>
    </div>
  );
};

export default AdminStatistics;
