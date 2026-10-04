import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { Loader2, AlertTriangle, Download, BookOpen } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { treffenheftHtml } from '../lib/treffenheft';

// Der digitale Ort, an dem das Heft liegt.
//
// Derselbe Link, mit dem sich jemand vorgestellt hat, führt ab dem Tag
// des Treffens hierher. Kein zweiter Zugang, kein Konto, nichts zu
// merken — wer die Einladung noch im Postfach hat, kommt hinein.
//
// Gezeigt wird genau das Dokument, das man auch herunterlädt. Eine
// Bildschirmfassung daneben liefe der gedruckten früher oder später
// davon, und ausgerechnet bei einem Andenken wäre das ärgerlich.

const HeftSeite: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const [html, setHtml] = useState<string | null>(null);
  const [titel, setTitel] = useState('');
  const [fehler, setFehler] = useState('');
  const [laedt, setLaedt] = useState(true);

  useEffect(() => {
    let lebt = true;
    supabase.rpc('heft_fuer_teilnehmer', { p_token: token }).then(({ data, error }) => {
      if (!lebt) return;
      if (error) { setFehler(error.message || 'Nicht verfügbar.'); setLaedt(false); return; }
      setHtml(treffenheftHtml(data));
      setTitel((data as any)?.treffen?.titel || '');
      setLaedt(false);
    });
    return () => { lebt = false; };
  }, [token]);

  const herunterladen = () => {
    if (!html) return;
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${(titel || 'Treffen').replace(/[^A-Za-zÄÖÜäöü0-9]+/g, '_')}_Heft.html`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="min-h-screen" style={{ background: '#f0ede8' }}>
      <header className="bg-white border-b border-stone-200 sticky top-0 z-10">
        <div className="max-w-3xl mx-auto px-5 py-4 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 min-w-0">
            <BookOpen size={18} className="text-stone-400 shrink-0" />
            <p className="font-bold text-sm text-stone-900 truncate">{titel || 'Das Heft'}</p>
          </div>
          <button onClick={herunterladen} disabled={!html}
            className="flex items-center gap-2 bg-stone-900 text-white px-4 py-2 rounded-lg
                       text-xs font-bold uppercase tracking-widest disabled:opacity-40 shrink-0">
            <Download size={14} /> Behalten
          </button>
        </div>
      </header>

      <main className="max-w-3xl mx-auto px-5 py-6">
        {laedt && (
          <div className="flex items-center gap-2 text-stone-400 py-24 justify-center">
            <Loader2 className="animate-spin" size={18} /> Das Heft wird geholt …
          </div>
        )}

        {fehler && (
          <div className="bg-white border border-amber-200 rounded-2xl p-8 text-center mt-12 max-w-md mx-auto">
            <AlertTriangle size={26} className="text-amber-500 mx-auto mb-4" />
            <p className="font-bold text-stone-900 mb-2">Noch nicht da</p>
            <p className="text-sm text-stone-500 leading-relaxed">{fehler}</p>
          </div>
        )}

        {html && !fehler && (
          // Im Rahmen, weil das Heft ein vollständiges Dokument mit eigenem
          // Stylesheet ist. In die Seite hineinkopiert färbten sich beide
          // gegenseitig um.
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden border border-stone-200">
            <iframe srcDoc={html} title="Heft" className="w-full border-0"
                    style={{ height: '82vh', minHeight: 600 }} />
          </div>
        )}

        {html && !fehler && (
          <p className="text-[11px] text-stone-400 text-center mt-4 leading-relaxed max-w-md mx-auto">
            Mit „Behalten“ laden Sie das Heft als einzelne Datei herunter — sie funktioniert
            ohne Internet und lässt sich ausdrucken.
          </p>
        )}
      </main>
    </div>
  );
};

export default HeftSeite;
