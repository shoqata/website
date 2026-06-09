
import React, { useEffect, useRef, useMemo } from 'react';
import * as d3 from 'd3';
import { Payment, UserProfile, Neighborhood } from '../types';
import { CheckCircle2, Clock, AlertCircle, TrendingUp, MapPin, DollarSign } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';

interface AdminAnalyticsProps {
  payments?: Payment[];
  users?: UserProfile[];
  neighborhoods?: Neighborhood[];
  selectedYear?: number;
}

const AdminAnalytics: React.FC<AdminAnalyticsProps> = ({ payments = [], users = [], neighborhoods = [], selectedYear }) => {
  const { t } = useTranslation();
  const chartRef = useRef<SVGSVGElement>(null);

  // Filter payments by selected year
  const filteredPayments = useMemo(() => {
      if (!selectedYear) return payments;
      return payments.filter(p => p.timestamp?.toDate().getFullYear() === selectedYear);
  }, [payments, selectedYear]);

  // Calculate Financial Stats
  const stats = useMemo(() => {
    const paid = filteredPayments.filter(p => p.status === 'PAID');
    const pending = filteredPayments.filter(p => p.status === 'PENDING');
    const overdue = filteredPayments.filter(p => p.status === 'OVERDUE');

    const totalPaid = paid.reduce((acc, p) => acc + p.amount, 0);
    const totalPending = pending.reduce((acc, p) => acc + p.amount, 0);
    const totalOverdue = overdue.reduce((acc, p) => acc + p.amount, 0);

    return {
      paidCount: paid.length,
      paidAmount: totalPaid,
      pendingCount: pending.length,
      pendingAmount: totalPending,
      overdueCount: overdue.length,
      overdueAmount: totalOverdue
    };
  }, [filteredPayments]);

  // Calculate Neighborhood Performance
  const neighborhoodStats = useMemo(() => {
    return neighborhoods.map(n => {
      const nMembers = users.filter(u => u.neighborhoodId === n.id);
      const memberIds = nMembers.map(u => u.id);
      const nPayments = filteredPayments.filter(p => memberIds.includes(p.userId));
      const paidAmount = nPayments.filter(p => p.status === 'PAID').reduce((acc, p) => acc + p.amount, 0);
      const totalInvoiced = nPayments.reduce((acc, p) => acc + p.amount, 0);
      const health = totalInvoiced > 0 ? (paidAmount / totalInvoiced) * 100 : 0;

      return {
        ...n,
        memberCount: nMembers.length,
        paidAmount,
        health
      };
    }).sort((a, b) => b.health - a.health);
  }, [neighborhoods, users, filteredPayments]);

  // --- Calculate Payment Revenue Over Time ---
  const revenueData = useMemo(() => {
    const dataMap = new Map<string, number>();
    const paidPayments = filteredPayments.filter(p => p.status === 'PAID' && p.timestamp);

    if (paidPayments.length === 0) {
        return [
            { date: new Date(new Date().setMonth(new Date().getMonth() - 1)), value: 0 },
            { date: new Date(), value: 0 }
        ];
    }

    paidPayments.forEach(p => {
        const d = p.timestamp.toDate();
        const key = new Date(d.getFullYear(), d.getMonth(), 1).toISOString();
        const current = dataMap.get(key) || 0;
        dataMap.set(key, current + p.amount);
    });

    return Array.from(dataMap.entries())
        .map(([key, value]) => ({ date: new Date(key), value }))
        .sort((a, b) => a.date.getTime() - b.date.getTime());
  }, [filteredPayments]);

  useEffect(() => {
    if (!chartRef.current || revenueData.length === 0) return;

    const svg = d3.select(chartRef.current);
    svg.selectAll("*").remove();

    const width = chartRef.current.clientWidth;
    const height = 300;
    const margin = { top: 20, right: 30, bottom: 40, left: 60 };

    const x = d3.scaleTime()
      .domain(d3.extent(revenueData, d => d.date) as [Date, Date])
      .range([margin.left, width - margin.right]);

    const maxValue = d3.max(revenueData, d => d.value) || 1000;
    const y = d3.scaleLinear()
      .domain([0, maxValue * 1.1])
      .nice()
      .range([height - margin.bottom, margin.top]);

    const line = d3.line<any>()
      .x(d => x(d.date))
      .y(d => y(d.value))
      .curve(d3.curveMonotoneX);

    const area = d3.area<any>()
        .x(d => x(d.date))
        .y0(height - margin.bottom)
        .y1(d => y(d.value))
        .curve(d3.curveMonotoneX);

    const defs = svg.append("defs");
    
    const lineGradient = defs.append("linearGradient")
      .attr("id", "line-gradient")
      .attr("gradientUnits", "userSpaceOnUse")
      .attr("x1", 0).attr("y1", y(0))
      .attr("x2", 0).attr("y2", y(maxValue));

    lineGradient.append("stop").attr("offset", "0%").attr("stop-color", "#10b981");
    lineGradient.append("stop").attr("offset", "100%").attr("stop-color", "#34d399");

    const areaGradient = defs.append("linearGradient")
      .attr("id", "area-gradient")
      .attr("x1", "0%").attr("y1", "0%")
      .attr("x2", "0%").attr("y2", "100%");
    
    areaGradient.append("stop").attr("offset", "0%").attr("stop-color", "#10b981").attr("stop-opacity", 0.2);
    areaGradient.append("stop").attr("offset", "100%").attr("stop-color", "#10b981").attr("stop-opacity", 0);

    svg.append("path")
        .datum(revenueData)
        .attr("fill", "url(#area-gradient)")
        .attr("d", area);

    svg.append("path")
      .datum(revenueData)
      .attr("fill", "none")
      .attr("stroke", "url(#line-gradient)")
      .attr("stroke-width", 4)
      .attr("stroke-linecap", "round")
      .attr("d", line);

    svg.append("g")
      .attr("transform", `translate(0,${height - margin.bottom})`)
      .call(d3.axisBottom(x).ticks(5).tickSizeOuter(0).tickFormat(d3.timeFormat("%b %Y") as any))
      .attr("color", "#a8a29e")
      .style("font-size", "10px");

    svg.append("g")
      .attr("transform", `translate(${margin.left},0)`)
      .call(d3.axisLeft(y).ticks(5).tickFormat((d) => `${d}`))
      .attr("color", "#a8a29e")
      .style("font-size", "10px")
      .call(g => g.select(".domain").remove())
      .call(g => g.selectAll(".tick line").attr("x2", width - margin.left - margin.right).attr("stroke-opacity", 0.1));

  }, [revenueData]);

  return (
    <div className="space-y-8">
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-emerald-50 p-8 rounded-3xl border border-emerald-100">
          <div className="flex justify-between items-start mb-4">
             <p className="text-emerald-600 font-bold text-xs uppercase tracking-widest">{t('admin.finance.collected')} ({selectedYear})</p>
             <CheckCircle2 className="text-emerald-500" size={20} />
          </div>
          <p className="text-4xl font-display font-bold text-emerald-900">{stats.paidAmount.toFixed(0)} CHF</p>
          <p className="text-emerald-600/70 text-sm mt-2 font-medium">{stats.paidCount} bills settled</p>
        </div>
        <div className="bg-amber-50 p-8 rounded-3xl border border-amber-100">
          <div className="flex justify-between items-start mb-4">
             <p className="text-amber-600 font-bold text-xs uppercase tracking-widest">{t('admin.finance.open')} ({selectedYear})</p>
             <Clock className="text-amber-500" size={20} />
          </div>
          <p className="text-4xl font-display font-bold text-amber-900">{stats.pendingAmount.toFixed(0)} CHF</p>
          <p className="text-amber-600/70 text-sm mt-2 font-medium">{stats.pendingCount} bills pending</p>
        </div>
        <div className="bg-rose-50 p-8 rounded-3xl border border-rose-100">
          <div className="flex justify-between items-start mb-4">
             <p className="text-rose-600 font-bold text-xs uppercase tracking-widest">{t('admin.finance.overdue')} ({selectedYear})</p>
             <AlertCircle className="text-rose-500" size={20} />
          </div>
          <p className="text-4xl font-display font-bold text-rose-900">{stats.overdueAmount.toFixed(0)} CHF</p>
          <p className="text-rose-400 text-sm mt-2 font-medium">{stats.overdueCount} bills late</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Chart */}
          <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm">
            <div className="flex items-center justify-between mb-8">
                <h3 className="text-xl font-bold flex items-center gap-2"><DollarSign size={20} className="text-emerald-500"/> {t('admin.stats.history')} {selectedYear}</h3>
                <span className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('admin.finance.collected')}</span>
            </div>
            <svg ref={chartRef} className="w-full h-[300px] overflow-visible"></svg>
          </div>

          {/* Neighborhood Performance Table */}
          <div className="bg-white p-8 rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden flex flex-col">
             <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><MapPin size={20} className="text-primary"/> {t('admin.stats.neighborhoodPerf')}</h3>
             <div className="overflow-y-auto flex-1 custom-scrollbar">
                <table className="w-full text-left">
                   <thead>
                      <tr className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                         <th className="pb-3">{t('admin.tab.neighborhoods')}</th>
                         <th className="pb-3 text-right">{t('admin.tab.users')}</th>
                         <th className="pb-3 text-right">{t('admin.finance.collected')}</th>
                         <th className="pb-3 text-right">Health</th>
                      </tr>
                   </thead>
                   <tbody className="divide-y divide-stone-50">
                      {neighborhoodStats.map(n => (
                         <tr key={n.id} className="group hover:bg-stone-50 transition-colors">
                            <td className="py-4 font-bold text-stone-900">{n.name}</td>
                            <td className="py-4 text-right text-stone-500 text-sm">{n.memberCount}</td>
                            <td className="py-4 text-right font-mono text-xs">{n.paidAmount.toFixed(0)}</td>
                            <td className="py-4 text-right">
                               <div className="flex items-center justify-end gap-2">
                                  <span className="text-xs font-bold">{n.health.toFixed(0)}%</span>
                                  <div className="w-16 h-1.5 bg-stone-100 rounded-full overflow-hidden">
                                     <div 
                                        className={`h-full rounded-full ${n.health > 80 ? 'bg-green-500' : n.health > 50 ? 'bg-amber-500' : 'bg-rose-500'}`} 
                                        style={{ width: `${n.health}%` }}
                                     />
                                  </div>
                               </div>
                            </td>
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

export default AdminAnalytics;
