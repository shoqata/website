
import React, { useState, useMemo, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Search, Plus, Users, MapPin, ChevronRight, Activity, Globe, Loader2, Database } from 'lucide-react';
import { Neighborhood } from '../types';

// Firebase
import { db } from '../services/firebase';
import { collection, onSnapshot, query, orderBy } from '@/services/supabase-bridge';

const Neighborhoods: React.FC = () => {
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [neighborhoods, setNeighborhoods] = useState<Neighborhood[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Real-time listener for Firestore
    const q = query(collection(db, 'neighborhoods'), orderBy('name'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Neighborhood));
      setNeighborhoods(data);
      setLoading(false);
    }, (error) => {
      console.warn("Firestore error or access denied:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filtered = useMemo(() => {
    return neighborhoods.filter(n => {
      const matchesSearch = n.name.toLowerCase().includes(search.toLowerCase()) || n.location.city.toLowerCase().includes(search.toLowerCase());
      const matchesFilter = filter === 'ALL' || n.status === filter;
      return matchesSearch && matchesFilter;
    });
  }, [search, filter, neighborhoods]);

  return (
    <div className="max-w-7xl mx-auto px-6 py-12">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-12">
        <div>
          <h2 className="text-3xl font-display font-bold mb-2">Neighborhoods</h2>
          <p className="text-stone-500">Discover and join local humanitarian groups.</p>
        </div>
        <button className="bg-rose-500 text-white px-6 py-3 rounded-2xl font-bold flex items-center gap-2 hover:bg-rose-600 transition-all shadow-lg shadow-rose-200">
          <Plus size={20} /> Register Neighborhood
        </button>
      </div>

      <div className="flex flex-col md:flex-row gap-4 mb-10">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" size={20} />
          <input type="text" placeholder="Search by name or city..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full pl-12 pr-4 py-4 bg-white border border-stone-200 rounded-2xl shadow-sm focus:ring-2 focus:ring-rose-500 outline-none transition-all" />
        </div>
        <div className="flex gap-2">
          {(['ALL', 'ACTIVE', 'INACTIVE'] as const).map(f => (
            <button key={f} onClick={() => setFilter(f)} className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${filter === f ? 'bg-rose-500 text-white shadow-md' : 'bg-white border border-stone-200 text-stone-500 hover:bg-stone-50'}`}>{f.charAt(0) + f.slice(1).toLowerCase()}</button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-24 text-stone-400">
          <Loader2 className="animate-spin mb-4" size={48} />
          <p className="font-medium">Syncing with Global Network...</p>
        </div>
      ) : neighborhoods.length === 0 ? (
        <div className="text-center py-24 bg-white rounded-[3rem] border border-dashed border-stone-200">
          <div className="w-20 h-20 bg-stone-50 rounded-full flex items-center justify-center mx-auto mb-6 text-stone-300">
            <Database size={40} />
          </div>
          <h3 className="text-xl font-bold mb-2">No data in database yet</h3>
          <p className="text-stone-400 max-w-xs mx-auto mb-8">Login as admin and use the 'Initialize System' button to seed initial data.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {filtered.map((n, i) => (
            <motion.div key={n.id} initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="bg-white p-8 rounded-[2rem] border border-stone-100 shadow-sm hover:shadow-xl transition-all group relative overflow-hidden">
              <div className="flex justify-between items-start mb-6">
                <div className="p-3 bg-stone-50 rounded-2xl text-rose-500 group-hover:bg-rose-500 group-hover:text-white transition-all duration-500"><MapPin size={24} /></div>
                <span className={`px-3 py-1 rounded-full text-[10px] font-bold ${n.status === 'ACTIVE' ? 'bg-green-100 text-green-600' : 'bg-stone-100 text-stone-400'}`}>{n.status}</span>
              </div>
              <h3 className="text-xl font-bold mb-2 group-hover:text-rose-600 transition-colors">{n.name}</h3>
              <p className="text-stone-500 text-sm mb-6 flex items-center gap-1"><Globe size={14} /> {n.location.city}, {n.location.country}</p>
              <div className="space-y-4 mb-8">
                <div className="flex justify-between text-sm"><span className="text-stone-400 flex items-center gap-2"><Users size={16} /> Members</span><span className="font-bold text-stone-900">{n.memberCount}</span></div>
                <div className="flex justify-between text-sm"><span className="text-stone-400 flex items-center gap-2"><Activity size={16} /> Last Activity</span><span className="font-medium text-stone-600">{new Date(n.lastActivity).toLocaleDateString()}</span></div>
              </div>
              <button className="w-full flex items-center justify-between p-4 bg-stone-50 rounded-2xl font-bold group-hover:bg-rose-500 group-hover:text-white transition-all duration-300">
                View Details <ChevronRight size={18} />
              </button>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Neighborhoods;
