import React, { useEffect, useState } from 'react';
import { AlertOctagon } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';

export const AntiScrapeProtection: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { t } = useTranslation();
    const [isTriggered, setIsTriggered] = useState(false);
    const [violation, setViolation] = useState<string>('');

    useEffect(() => {
        // Frueher stand hier ein Eintrag in security_logs und ein Abruf
        // der Besucher-IP bei api.ipify.org. Beides ist weg:
        //
        // Der Eintrag konnte nie gelingen. Die Sperre greift beim
        // Seitenaufruf, also vor jeder Anmeldung, und anon darf in
        // security_logs nichts schreiben -- die Regel gilt nur fuer
        // authenticated. Jeder Aufruf endete mit 400. Ein Protokoll,
        // das genau im gemeinten Fall versagt, ist keines; und ein
        // anonymer Schreibweg nur dafuer waere ein Einfallstor fuer
        // Flutung.
        //
        // Die IP kam von einem Fremddienst, nur um sie dem Besucher
        // wieder anzuzeigen. Das gab seine Adresse an Dritte weiter
        // und brachte uns nichts.
        const triggerWarning = (reason: string) => {
            if (isTriggered) return;
            setViolation(reason);
            setIsTriggered(true);
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
                    {t('guard.title')}
                </h1>
                <div className="bg-black/80 p-8 rounded-3xl max-w-3xl border border-red-500/50 shadow-2xl shadow-red-900/50 backdrop-blur-xl">
                    <h2 className="text-2xl font-bold mb-6 text-white">
                        {t('guard.subtitle')}
                    </h2>
                    <p className="text-lg mb-8 text-red-200 leading-relaxed">
                        {t('guard.text', { reason: violation })}
                    </p>
                    
                    <div className="bg-red-950/80 p-6 rounded-2xl border border-red-800/50 text-left font-mono text-sm md:text-base mb-8 shadow-inner">
                        <div className="space-y-3">
                            <p><span className="text-stone-500 w-32 inline-block">{t('guard.agent')}</span> <span className="text-stone-300">{navigator.userAgent}</span></p>
                            <p><span className="text-stone-500 w-32 inline-block">{t('guard.time')}</span> <span className="text-stone-300">{new Date().toISOString()}</span></p>
                            <p><span className="text-stone-500 w-32 inline-block">{t('guard.action')}</span> <span className="text-red-400">{t('guard.blocked')}</span></p>
                        </div>
                    </div>
                    
                    <div className="bg-red-900/20 p-6 rounded-2xl border border-red-500/30">
                        <p className="font-bold text-red-400 text-lg">
                            {t('guard.warning')}
                        </p>
                        <p className="text-red-300 mt-2">
                            {t('guard.warning_more')}
                        </p>
                    </div>
                </div>
            </div>
        );
    }

    return <>{children}</>;
};
