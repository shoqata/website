import React, { useEffect, useState } from 'react';
import { Download, Share } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';

// "App installieren" im Handy-Menue.
//
// Android und Chrome melden mit beforeinstallprompt, dass die Seite sich
// installieren laesst -- dann ein Knopf, der den Dialog des Systems oeffnet.
// iOS kennt das Ereignis nicht; dort geht es nur ueber Teilen -> Zum Home-
// Bildschirm, also ein kurzer Hinweis. Laeuft die Seite schon als App,
// erscheint nichts.

let gemerkt: any = null;
if (typeof window !== 'undefined') {
  // Frueh abfangen: das Ereignis kommt oft, bevor das Menue je geoeffnet wird.
  window.addEventListener('beforeinstallprompt', (e: any) => { e.preventDefault(); gemerkt = e; });
}

const istApp = () => typeof window !== 'undefined' &&
  (window.matchMedia?.('(display-mode: standalone)').matches || (navigator as any).standalone === true);
const istIos = () => typeof navigator !== 'undefined' &&
  /iphone|ipad|ipod/i.test(navigator.userAgent) && !/crios|fxios/i.test(navigator.userAgent);

const AppInstallieren: React.FC = () => {
  const { t } = useTranslation();
  const [angebot, setAngebot] = useState<any>(gemerkt);
  const [hinweis, setHinweis] = useState(false);

  useEffect(() => {
    const da = (e: any) => { e.preventDefault(); gemerkt = e; setAngebot(e); };
    const fertig = () => { gemerkt = null; setAngebot(null); };
    window.addEventListener('beforeinstallprompt', da);
    window.addEventListener('appinstalled', fertig);
    return () => { window.removeEventListener('beforeinstallprompt', da); window.removeEventListener('appinstalled', fertig); };
  }, []);

  if (istApp() || (!angebot && !istIos())) return null;

  const los = async () => {
    if (angebot) {
      angebot.prompt();
      await angebot.userChoice.catch(() => null);
      gemerkt = null; setAngebot(null);
    } else {
      setHinweis(h => !h);
    }
  };

  return (
    <div className="mt-1">
      <button onClick={los}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl bg-stone-100 text-stone-800 text-sm font-bold">
        {angebot ? <Download size={16} /> : <Share size={16} />} {t('app.installieren')}
      </button>
      {hinweis && <p className="px-4 pt-2 text-xs text-stone-500 leading-relaxed">{t('app.ios_hinweis')}</p>}
    </div>
  );
};

export default AppInstallieren;
