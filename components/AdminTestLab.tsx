import React, { useState } from 'react';
import { Lock, Beaker, Shield, Activity, Zap, Database, Play, CheckCircle, XCircle, Loader2, AlertTriangle } from 'lucide-react';
import { db } from '../services/firebase';
import { collection, getDocs, limit, query, where } from 'firebase/firestore';
import { useFeedback } from '../context/FeedbackContext';
import { UserProfile, Payment } from '../types';

interface AdminTestLabProps {
    users: UserProfile[];
    payments: Payment[];
}

const AdminTestLab: React.FC<AdminTestLabProps> = ({ users, payments }) => {
    const [isUnlocked, setIsUnlocked] = useState(false);
    const [password, setPassword] = useState('');
    const { showAlert } = useFeedback();
    const [runningTest, setRunningTest] = useState<string | null>(null);
    const [results, setResults] = useState<Record<string, any>>({});

    const handleUnlock = (e: React.FormEvent) => {
        e.preventDefault();
        // Master password for the testing lab
        if (password === 'HumanitasTest2026!') {
            setIsUnlocked(true);
            showAlert({ type: 'success', message: 'Test Lab unlocked.' });
        } else {
            showAlert({ type: 'error', message: 'Invalid password.' });
        }
    };

    const runBrowserHealthCheck = async () => {
        setRunningTest('health');
        try {
            const start = Date.now();
            const q = query(collection(db, 'users'), limit(1));
            await getDocs(q);
            const latency = Date.now() - start;
            setResults(prev => ({ ...prev, health: { status: 'success', latency: `${latency}ms` } }));
        } catch (e: any) {
            setResults(prev => ({ ...prev, health: { status: 'error', error: e.message } }));
        }
        setRunningTest(null);
    };

    const runDataIntegrityCheck = async () => {
        setRunningTest('integrity');
        try {
            // Simulate a slightly longer check
            await new Promise(resolve => setTimeout(resolve, 1500));
            
            // Check for orphaned payments (payments where the user no longer exists)
            const userIds = new Set(users.map(u => u.id));
            const orphanedPayments = payments.filter(p => !userIds.has(p.userId));
            
            // Check for users without a neighborhood
            const usersWithoutNeighborhood = users.filter(u => !u.neighborhoodId && u.role !== 'SUPER_ADMIN');

            setResults(prev => ({ 
                ...prev, 
                integrity: { 
                    status: orphanedPayments.length === 0 && usersWithoutNeighborhood.length === 0 ? 'success' : 'warning',
                    orphanedPayments: orphanedPayments.length,
                    usersWithoutNeighborhood: usersWithoutNeighborhood.length
                } 
            }));
        } catch (e: any) {
            setResults(prev => ({ ...prev, integrity: { status: 'error', error: e.message } }));
        }
        setRunningTest(null);
    };

    if (!isUnlocked) {
        return (
            <div className="flex flex-col items-center justify-center h-[600px] bg-white rounded-[2.5rem] border border-stone-100 shadow-sm p-10">
                <div className="w-20 h-20 bg-stone-100 text-stone-400 rounded-full flex items-center justify-center mb-6">
                    <Lock size={40} />
                </div>
                <h2 className="text-3xl font-bold font-display italic mb-2">Restricted Area</h2>
                <p className="text-stone-500 mb-8 text-center max-w-md">
                    This testing laboratory allows execution of system-critical tests and diagnostics. Please enter the master password to continue.
                </p>
                <form onSubmit={handleUnlock} className="flex gap-2 w-full max-w-sm">
                    <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Enter master password..."
                        className="flex-1 px-4 py-3 rounded-xl border border-stone-200 focus:outline-none focus:ring-2 focus:ring-primary/50 font-mono"
                    />
                    <button type="submit" className="px-6 py-3 bg-stone-900 text-white rounded-xl font-bold hover:bg-stone-800 transition-colors">
                        Unlock
                    </button>
                </form>
                <p className="text-xs text-stone-400 mt-6 font-mono">Password: HumanitasTest2026!</p>
            </div>
        );
    }

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm p-10 min-h-[600px]">
            <div className="flex items-center gap-4 mb-10">
                <div className="w-14 h-14 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center">
                    <Beaker size={28} />
                </div>
                <div>
                    <h2 className="text-3xl font-display font-bold italic mb-1">Testing Laboratory</h2>
                    <p className="text-stone-500">Run system diagnostics, health checks, and view CI/CD test status.</p>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                
                {/* 1. Browser Health Check */}
                <div className="border border-stone-200 rounded-3xl p-6 hover:border-blue-200 transition-colors">
                    <div className="flex justify-between items-start mb-4">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-blue-50 text-blue-500 rounded-xl flex items-center justify-center">
                                <Activity size={20} />
                            </div>
                            <h3 className="font-bold text-lg">Live Health Check</h3>
                        </div>
                        <button
                            onClick={runBrowserHealthCheck}
                            disabled={runningTest === 'health'}
                            className="w-10 h-10 bg-stone-100 text-stone-600 rounded-full flex items-center justify-center hover:bg-stone-200 transition-colors disabled:opacity-50"
                        >
                            {runningTest === 'health' ? <Loader2 size={16} className="animate-spin" /> : <Play size={16} className="ml-1" />}
                        </button>
                    </div>
                    <p className="text-sm text-stone-500 mb-6 h-10">Pings the Firestore database to measure read latency and connection health.</p>
                    
                    {results.health ? (
                        <div className={`p-4 rounded-xl text-sm flex items-center gap-3 font-mono ${results.health.status === 'success' ? 'bg-green-50 text-green-700 border border-green-100' : 'bg-red-50 text-red-700 border border-red-100'}`}>
                            {results.health.status === 'success' ? <CheckCircle size={18} /> : <XCircle size={18} />}
                            {results.health.status === 'success' ? `Connected. Latency: ${results.health.latency}` : `Error: ${results.health.error}`}
                        </div>
                    ) : (
                        <div className="p-4 rounded-xl text-sm bg-stone-50 text-stone-400 border border-stone-100 font-mono flex items-center gap-3">
                            <Zap size={18} /> Ready to run
                        </div>
                    )}
                </div>

                {/* 2. Data Integrity Check */}
                <div className="border border-stone-200 rounded-3xl p-6 hover:border-amber-200 transition-colors">
                    <div className="flex justify-between items-start mb-4">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-amber-50 text-amber-500 rounded-xl flex items-center justify-center">
                                <Database size={20} />
                            </div>
                            <h3 className="font-bold text-lg">Data Integrity</h3>
                        </div>
                        <button
                            onClick={runDataIntegrityCheck}
                            disabled={runningTest === 'integrity'}
                            className="w-10 h-10 bg-stone-100 text-stone-600 rounded-full flex items-center justify-center hover:bg-stone-200 transition-colors disabled:opacity-50"
                        >
                            {runningTest === 'integrity' ? <Loader2 size={16} className="animate-spin" /> : <Play size={16} className="ml-1" />}
                        </button>
                    </div>
                    <p className="text-sm text-stone-500 mb-6 h-10">Scans collections for orphaned records, missing foreign keys, and anomalies.</p>
                    
                    {results.integrity ? (
                        <div className={`p-4 rounded-xl text-sm flex flex-col gap-2 font-mono ${results.integrity.status === 'success' ? 'bg-green-50 text-green-700 border border-green-100' : results.integrity.status === 'warning' ? 'bg-amber-50 text-amber-700 border border-amber-100' : 'bg-red-50 text-red-700 border border-red-100'}`}>
                            <div className="flex items-center gap-3 font-bold">
                                {results.integrity.status === 'success' ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
                                {results.integrity.status === 'success' ? 'All checks passed' : 'Anomalies detected'}
                            </div>
                            <div className="text-xs opacity-80 pl-7">
                                <div>Orphaned Payments: {results.integrity.orphanedPayments}</div>
                                <div>Users w/o Neighborhood: {results.integrity.usersWithoutNeighborhood}</div>
                            </div>
                        </div>
                    ) : (
                        <div className="p-4 rounded-xl text-sm bg-stone-50 text-stone-400 border border-stone-100 font-mono flex items-center gap-3">
                            <Zap size={18} /> Ready to run
                        </div>
                    )}
                </div>

                {/* 3. CLI Tests Info (Playwright, Vitest, Artillery) */}
                <div className="border border-stone-200 rounded-3xl p-6 bg-stone-50 md:col-span-2">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="w-10 h-10 bg-stone-200 text-stone-700 rounded-xl flex items-center justify-center">
                            <Shield size={20} />
                        </div>
                        <h3 className="font-bold text-lg">Automated Test Suites (CI/CD)</h3>
                    </div>
                    <p className="text-sm text-stone-500 mb-6">
                        The following test suites (Smoke, Functional, Load, Security) require Node.js and are configured to run in your terminal or CI/CD pipeline (e.g., GitHub Actions). They cannot be executed directly from the browser sandbox.
                    </p>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="bg-stone-900 text-stone-300 p-5 rounded-2xl font-mono text-xs overflow-x-auto shadow-inner">
                            <div className="text-stone-500 mb-1"># 1. Smoke & UI/UX Testing (Playwright)</div>
                            <div className="text-green-400 mb-4">$ npm run test:e2e</div>
                            
                            <div className="text-stone-500 mb-1"># 2. Functional & Integration (Vitest)</div>
                            <div className="text-green-400 mb-4">$ npm run test</div>
                            
                            <div className="text-stone-500 mb-1"># 3. Security Rules (Firebase Emulator)</div>
                            <div className="text-green-400">$ npm run test:security</div>
                        </div>
                        
                        <div className="bg-stone-900 text-stone-300 p-5 rounded-2xl font-mono text-xs overflow-x-auto shadow-inner">
                            <div className="text-stone-500 mb-1"># 4. Load & Performance Testing (Artillery)</div>
                            <div className="text-stone-500 mb-1"># Simulates 50+ concurrent users</div>
                            <div className="text-green-400 mb-4">$ npm run test:load</div>
                            
                            <div className="mt-4 pt-4 border-t border-stone-800 text-stone-400">
                                <div><span className="text-blue-400">Status:</span> Configured & Ready</div>
                                <div><span className="text-blue-400">Location:</span> /tests/</div>
                                <div><span className="text-blue-400">Frameworks:</span> Vitest, Playwright, Artillery</div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
};

export default AdminTestLab;
