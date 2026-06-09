
import { useEffect } from 'react';

export const useSecurity = () => {
  useEffect(() => {
    // 1. Disable Right Click
    const handleContextMenu = (e: MouseEvent) => {
      e.preventDefault();
    };

    // 2. Disable Common Developer Shortcuts
    const handleKeyDown = (e: KeyboardEvent) => {
      // F12
      if (e.key === 'F12') {
        e.preventDefault();
      }
      // Ctrl+Shift+I (Inspect), Ctrl+Shift+J (Console), Ctrl+Shift+C (Element), Ctrl+U (Source)
      if (
        (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'J' || e.key === 'C')) ||
        (e.ctrlKey && e.key === 'u')
      ) {
        e.preventDefault();
      }
    };

    // 3. Advanced Console Warning
    const showConsoleWarning = () => {
      const styleTitle = 'color: #f43f5e; font-size: 40px; font-weight: bold; text-shadow: 2px 2px black;';
      const styleBody = 'color: #1c1917; font-size: 16px; font-weight: bold;';
      const styleInfo = 'color: #666; font-size: 12px;';

      console.clear();
      console.log('%cSTOP!', styleTitle);
      console.log(
        '%cHier gibt es nichts zu sehen. Der Versuch, diesen Code zu stehlen oder Reverse-Engineering zu betreiben, verstößt gegen die Nutzungsbedingungen.',
        styleBody
      );
      console.log(
        '%cAlle Aktionen auf dieser Plattform werden überwacht. IP-Adresse und Zeitstempel wurden protokolliert.',
        styleInfo
      );
    };

    document.addEventListener('contextmenu', handleContextMenu);
    document.addEventListener('keydown', handleKeyDown);
    
    // Show warning initially and on window resize (often happens when opening dev tools)
    showConsoleWarning();
    window.addEventListener('resize', showConsoleWarning);

    return () => {
      document.removeEventListener('contextmenu', handleContextMenu);
      document.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('resize', showConsoleWarning);
    };
  }, []);
};
