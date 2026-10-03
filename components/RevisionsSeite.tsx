import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Loader2, Download, ShieldCheck, AlertTriangle } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { revisionsberichtHtml } from '../lib/revisionsbericht';

// Die Seite für die Revisionsstelle.
//
// Kein Konto, kein Passwort: der Verweis trägt ein Token, und daraus
// leitet die Datenbank ab, welchen Verein und welches Jahr sie zeigen
// darf. Lesen und herunterladen -- mehr geht hier nicht, und zwar nicht
// weil die Oberfläche nichts anderes anbietet, sondern weil es keine
// andere Funktion gibt, die mit diesem Token etwas tun könnte.
//
// Angezeigt wird genau das Dokument, das auch der Vorstand herunterlädt --
// dieselbe Zeichnung, nicht eine zweite Nachbildung. Zwei Fassungen
// desselben Berichts liefen früher oder später auseinander, und
// ausgerechnet bei einer Revision wäre das fatal.

const RevisionsSeite: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const jetzt = new Date().getFullYear();
  const [jahr, setJahr] = useState(jetzt);
  const [html, setHtml] = useState<string | null>(null);
  const [fehler, setFehler] = useState('');
  const [laedt, setLaedt] = useState(true);
  const [daten, setDaten] = useState<any>(null);

  useEffect(() => {
    let lebt = true;
    setLaedt(true); setFehler(''); setHtml(null);
    supabase.rpc('revisionsdaten', { p_token: token, p_jahr: jahr }).then(({ data, error }) => {
      if (!lebt) return;
      if (error) { setFehler(error.message || 'Zugang nicht gültig.'); setLaedt(false); return; }
      setDaten(data);
      setHtml(revisionsberichtHtml(data));
      setLaedt(false);
    });
    return () => { lebt = false; };
  }, [token, jahr]);

  const herunterladen = () => {
    if (!html) return;
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `Revisionsbericht_${jahr}.html`; a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="min-h-screen bg-stone-100">
      <header className="bg-white border-b border-stone-200 sticky top-0 z-10">
        <div className="max-w-5xl mx-auto px-5 py-4 flex items-center justify-between gap-4 flex-wrap">
          <div className="flex items-center gap-3 min-w-0">
            <ShieldCheck size={20} className="text-stone-400 shrink-0" />
            <div className="min-w-0">
              <p className="font-bold text-sm text-stone-900 truncate">
                {daten?.verein?.name || 'Revisionsunterlagen'}
              </p>
              {daten?.zugang && (
                <p className="text-[11px] text-stone-400 truncate">
                  Zugang für {daten.zugang.fuer} · gültig bis{' '}
                  {new Date(daten.zugang.gueltig_bis).toLocaleDateString('de-CH')}
                </p>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            {/* Jahr nur anbieten, wenn der Zugang nicht ohnehin auf eines
                festgelegt ist -- sonst wählt man und bekommt eine Absage. */}
            <select value={jahr} onChange={e => setJahr(Number(e.target.value))}
              className="bg-stone-100 border border-stone-200 rounded-lg px-3 py-2 text-sm font-bold outline-none">
              {Array.from({ length: 6 }, (_, i) => jetzt - i).map(j =>
                <option key={j} value={j}>{j}</option>)}
            </select>
            <button onClick={herunterladen} disabled={!html}
              className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2 rounded-lg
                         text-xs font-bold uppercase tracking-widest disabled:opacity-40">
              <Download size={14} /> Herunterladen
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-5 py-6">
        {laedt && (
          <div className="flex items-center gap-2 text-stone-400 py-20 justify-center">
            <Loader2 className="animate-spin" size={18} /> Unterlagen werden geladen …
          </div>
        )}

        {fehler && (
          <div className="bg-white border border-amber-200 rounded-2xl p-8 text-center max-w-xl mx-auto mt-12">
            <AlertTriangle size={28} className="text-amber-500 mx-auto mb-4" />
            <p className="font-bold text-stone-900 mb-2">Zugang nicht verfügbar</p>
            <p className="text-sm text-stone-500 leading-relaxed">{fehler}</p>
            <p className="text-xs text-stone-400 mt-5 leading-relaxed">
              Zugänge sind befristet und können vom Verein jederzeit zurückgezogen werden.
              Wenden Sie sich an den Vorstand, wenn Sie einen neuen benötigen.
            </p>
          </div>
        )}

        {html && !fehler && (
          // In einem Rahmen: der Bericht ist ein vollstaendiges Dokument mit
          // eigenem Stylesheet. In die Seite hineinkopiert faerbten sich
          // beide gegenseitig um.
          <div className="bg-white rounded-2xl border border-stone-200 overflow-hidden shadow-sm">
            <iframe srcDoc={html} title="Revisionsbericht"
                    className="w-full border-0" style={{ height: '82vh', minHeight: 600 }} />
          </div>
        )}
      </main>
    </div>
  );
};

export default RevisionsSeite;
