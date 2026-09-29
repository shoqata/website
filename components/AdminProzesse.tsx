import React, { useState } from 'react';
import { Map, Maximize2, ExternalLink } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { useModule } from '../lib/useModule';

// Die Prozesslandkarte des Vereins.
//
// Die Karten sind mit archify erzeugt und liegen als eigenständige
// HTML-Dateien unter public/prozesse. Jede trägt alles in sich: kein Server,
// keine Abhängigkeit.
//
// Erzeugt werden sie nicht hier. archify ist ein Node-Werkzeug und läuft
// weder im Browser noch in der Datenbank -- je Verein zur Laufzeit zu
// zeichnen ginge also nicht. Das ist kein Verlust: wie ein Beitrag zur
// Buchung wird, ist bei jedem Verein gleich. Was sich unterscheidet, ist
// nur, welche Karten ein Verein überhaupt sieht -- das richtet sich nach
// seinen gebuchten Modulen.
type Karte = {
  schluessel: string;
  datei: string;
  titel: string;
  zeile: string;
  modul?: string;   // ohne Angabe: gehört zum Kern, jeder Verein sieht sie
};

const KARTEN: Karte[] = [
  {
    schluessel: 'beitrag',
    datei: '/prozesse/beitrag.html',
    titel: 'Der Mitgliederbeitrag',
    zeile: 'Von der Rechnung über die Zahlung bis zur Buchung — mit Mahnung und Barzahlung.',
  },
  {
    schluessel: 'spende',
    datei: '/prozesse/spende.html',
    titel: 'Die Spende',
    zeile: 'Von der Spendenseite bis zur Bescheinigung — und was bei einer anonymen Spende anders ist.',
    modul: 'SPENDEN',
  },
];

const AdminProzesse: React.FC = () => {
  const { t } = useTranslation();
  const { aktiv: modulAktiv } = useModule();
  const sichtbar = KARTEN.filter(k => !k.modul || modulAktiv(k.modul));
  const [offen, setOffen] = useState<Karte | null>(sichtbar[0] ?? null);

  return (
    <div className="max-w-6xl mx-auto space-y-8 p-2">
      <div className="flex items-center gap-3">
        <div className="bg-stone-100 text-stone-500 p-3 rounded-2xl"><Map size={22} /></div>
        <div>
          <h2 className="text-xl font-bold text-stone-900">{t('proz.titel')}</h2>
          <p className="text-xs text-stone-400">{t('proz.untertitel')}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {sichtbar.map(k => {
          const gewaehlt = offen?.schluessel === k.schluessel;
          return (
            <button key={k.schluessel} onClick={() => setOffen(k)}
              className={`text-left p-5 rounded-2xl border transition-all ${gewaehlt
                ? 'bg-white border-primary shadow-sm'
                : 'bg-white/60 border-stone-200 hover:border-stone-300'}`}>
              <p className={`font-bold text-sm mb-1 ${gewaehlt ? 'text-primary' : 'text-stone-900'}`}>{k.titel}</p>
              <p className="text-[11px] text-stone-500 leading-relaxed">{k.zeile}</p>
            </button>
          );
        })}
      </div>

      {offen && (
        <div className="bg-white rounded-[2rem] border border-stone-100 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-stone-100 flex items-center justify-between gap-3">
            <p className="text-xs font-bold text-stone-500 uppercase tracking-widest">{offen.titel}</p>
            <a href={offen.datei} target="_blank" rel="noopener noreferrer"
               className="text-[11px] font-bold text-stone-400 hover:text-stone-700 flex items-center gap-1.5 transition-colors">
              <Maximize2 size={12} /> {t('proz.gross')}
            </a>
          </div>
          {/* In einem Rahmen, weil jede Karte ihr eigenes vollständiges
              Dokument ist -- mit eigenem Stylesheet, eigenem Skript und
              eigenem Hell/Dunkel-Schalter. In die Seite hineinkopiert
              würden sich beide Welten gegenseitig umfärben. */}
          <iframe key={offen.schluessel} src={offen.datei} title={offen.titel}
                  className="w-full border-0" style={{ height: '78vh', minHeight: 560 }} />
        </div>
      )}

      <p className="text-[11px] text-stone-400 leading-relaxed max-w-3xl">
        {t('proz.hinweis')}{' '}
        <a href="https://github.com/tt-a1i/archify" target="_blank" rel="noopener noreferrer"
           className="underline hover:text-stone-600 inline-flex items-center gap-1">
          archify <ExternalLink size={10} />
        </a>
      </p>
    </div>
  );
};

export default AdminProzesse;
