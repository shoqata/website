import React, { useEffect, useState } from 'react';
import { AlertOctagon } from 'lucide-react';
import { db } from '../services/firebase';
import { collection, addDoc, serverTimestamp } from '@/services/supabase-bridge';

export const AntiScrapeProtection: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [isTriggered, setIsTriggered] = useState(false);
    const [ipAddress, setIpAddress] = useState<string>('Detecting...');
    const [violation, setViolation] = useState<string>('');

    useEffect(() => {
        const triggerWarning = async (reason: string) => {
            if (isTriggered) return;
            setViolation(reason);
            setIsTriggered(true);

            try {
                // Fetch IP address to display in the warning
                const res = await fetch('https://api.ipify.org?format=json');
                const data = await res.json();
                setIpAddress(data.ip);

                // Log the incident to Firestore
                await addDoc(collection(db, 'security_logs'), {
                    event: 'SCRAPING_ATTEMPT',
                    reason,
                    ip: data.ip,
                    userAgent: navigator.userAgent,
                    timestamp: serverTimestamp(),
                    url: window.location.href
                });
            } catch (e) {
                setIpAddress('UNKNOWN (Logged via ISP)');
            }
        };

        // 1. Detect Headless Browsers (Bots)
        if (navigator.webdriver) {
            triggerWarning('Automated Bot/Scraper Detected (WebDriver)');
        }

        // 2. Prevent Keyboard Shortcuts for DevTools/Source
        const handleKeyDown = (e: KeyboardEvent) => {
            // F12
            if (e.key === 'F12') {
                e.preventDefault();
                triggerWarning('Developer Tools Access Attempt (F12)');
            }
            // Ctrl+Shift+I (Windows/Linux) or Cmd+Opt+I (Mac)
            if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === 'I' || e.key === 'i')) {
                e.preventDefault();
                triggerWarning('Developer Tools Access Attempt (Inspect)');
            }
            // Ctrl+Shift+J / Cmd+Opt+J (Console)
            if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === 'J' || e.key === 'j')) {
                e.preventDefault();
                triggerWarning('Developer Console Access Attempt');
            }
            // Ctrl+U / Cmd+U (View Source)
            if ((e.ctrlKey || e.metaKey) && (e.key === 'U' || e.key === 'u')) {
                e.preventDefault();
                triggerWarning('Source Code View Attempt');
            }
        };

        // 3. Prevent Right Click (Context Menu)
        const handleContextMenu = (e: MouseEvent) => {
            e.preventDefault();
            // We just block right-click, but don't trigger the full lockdown 
            // to avoid punishing normal users who accidentally right-click.
        };

        window.addEventListener('keydown', handleKeyDown);
        window.addEventListener('contextmenu', handleContextMenu);

        return () => {
            window.removeEventListener('keydown', handleKeyDown);
            window.removeEventListener('contextmenu', handleContextMenu);
        };
    }, [isTriggered]);

    if (isTriggered) {
        return (
            <div className="fixed inset-0 z-[99999] bg-red-950 flex flex-col items-center justify-center p-6 text-white text-center overflow-y-auto">
                <AlertOctagon size={100} className="text-red-500 mb-8 animate-pulse" />
                <h1 className="text-3xl md:text-5xl font-black mb-6 uppercase tracking-widest text-red-500">
                    Security Violation Detected
                </h1>
                <div className="bg-black/80 p-8 rounded-3xl max-w-3xl border border-red-500/50 shadow-2xl shadow-red-900/50 backdrop-blur-xl">
                    <h2 className="text-2xl font-bold mb-6 text-white">
                        Unauthorized Access / Scraping is Strictly Prohibited
                    </h2>
                    <p className="text-lg mb-8 text-red-200 leading-relaxed">
                        Our security systems have detected an attempt to inspect, scrape, or reverse-engineer this application 
                        (<span className="font-mono text-red-400">{violation}</span>). 
                        This action violates our Terms of Service and intellectual property rights.
                    </p>
                    
                    <div className="bg-red-950/80 p-6 rounded-2xl border border-red-800/50 text-left font-mono text-sm md:text-base mb-8 shadow-inner">
                        <p className="text-red-500 font-bold mb-4 border-b border-red-900/50 pb-2">--- INCIDENT LOGGED ---</p>
                        <div className="space-y-3">
                            <p><span className="text-stone-500 w-32 inline-block">IP Address:</span> <span className="text-white font-bold bg-red-900/50 px-2 py-1 rounded">{ipAddress}</span></p>
                            <p><span className="text-stone-500 w-32 inline-block">User Agent:</span> <span className="text-stone-300">{navigator.userAgent}</span></p>
                            <p><span className="text-stone-500 w-32 inline-block">Timestamp:</span> <span className="text-stone-300">{new Date().toISOString()}</span></p>
                            <p><span className="text-stone-500 w-32 inline-block">Action:</span> <span className="text-red-400">Data extraction attempt blocked</span></p>
                        </div>
                    </div>
                    
                    <div className="bg-red-900/20 p-6 rounded-2xl border border-red-500/30">
                        <p className="font-bold text-red-400 text-lg">
                            WARNING: Your IP address and session data have been recorded. 
                        </p>
                        <p className="text-red-300 mt-2">
                            Any further attempts will result in immediate legal action and permanent blacklisting of your network.
                        </p>
                    </div>
                </div>
            </div>
        );
    }

    return <>{children}</>;
};
