import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  Loader2, AlertTriangle, ArrowRight, ArrowLeft, Check, Sparkles, Bus, MapPin,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// „Wer kommt da eigentlich?“ — die Selbstvorstellung.
//
// Eine Frage je Bild statt ein Formular mit acht Feldern. Wer am Telefon
// steht und drei Minuten Zeit hat, füllt eine Frage aus; eine Wand aus
// Feldern legt er weg.
//
// Die Fragen sind offen gestellt und nirgends Pflicht ausser dem Namen.
// Wer nur „Ich bin Schreiner“ schreibt, hat genug geschrieben — ein
// Pflichtfeld erzwingt keine Offenheit, es erzeugt Blabla.
//
// Der letzte Schritt ist die Einwilligung, und er steht bewusst allein:
// wer seine Vorstellung in ein Heft gibt, das alle Teilnehmer bekommen,
// soll das entscheiden und nicht übersehen. Nichts ist vorangekreuzt.

const ESSEN = [
  { w: 'ALLES',        t: 'Ich esse alles' },
  { w: 'VEGETARISCH',  t: 'Vegetarisch' },
  { w: 'VEGAN',        t: 'Vegan' },
  { w: 'HALAL',        t: 'Halal' },
  { w: 'GLUTENFREI',   t: 'Glutenfrei' },
  { w: 'LAKTOSEFREI',  t: 'Laktosefrei' },
];

const tag = (s?: string | null) =>
  s ? new Date(s).toLocaleDateString('de-CH', { day: '2-digit', month: 'long', year: 'numeric' }) : '';

const VorstellungWizard: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const [d, setD] = useState<any>(null);
  const [fehler, setFehler] = useState('');
  const [laedt, setLaedt] = useState(true);
  const [schritt, setSchritt] = useState(0);
  const [arbeitet, setArbeitet] = useState(false);
  const [fertig, setFertig] = useState(false);

  const [name, setName] = useState('');
  const [funktion, setFunktion] = useState('');
  const [vorstellung, setVorstellung] = useState('');
  const [interessen, setInteressen] = useState('');
  const [essen, setEssen] = useState('KEINE_ANGABE');
  const [hinweis, setHinweis] = useState('');
  const [imHeft, setImHeft] = useState<boolean | null>(null);
  // Ausfluege gibt es nicht bei jedem Treffen. Ein leerer Schritt "keine
  // Ausfluege vorhanden" waere eine Station, die nichts tut -- darum
  // erscheint er nur, wenn welche da sind.
  const [ausfluege, setAusfluege] = useState<any[]>([]);
  const [ausflugLaeuft, setAusflugLaeuft] = useState('');
  const [ausflugFehler, setAusflugFehler] = useState('');

  useEffect(() => {
    let lebt = true;
    supabase.rpc('vorstellung_lesen', { p_token: token }).then(({ data, error }) => {
      if (!lebt) return;
      if (error) { setFehler(error.message || 'Zugang nicht gültig.'); setLaedt(false); return; }
      const b: any = data;
      setD(b);
      setName(b.name || ''); setFunktion(b.funktion || '');
      setVorstellung(b.vorstellung || ''); setInteressen(b.interessen || '');
      setEssen(b.essen || 'KEINE_ANGABE'); setHinweis(b.essen_hinweis || '');
      setImHeft(b.im_heft);
      setLaedt(false);
      supabase.rpc('ausfluege_fuer', { p_token: token }).then(({ data: a, error: f }) => {
        if (lebt && !f) setAusfluege((a as any[]) || []);
      });
    });
    return () => { lebt = false; };
  }, [token]);

  // Die Anmeldung gilt sofort, nicht erst beim Abschluss des Assistenten.
  // Plaetze sind begrenzt; wer sich eintraegt und dann noch drei Schritte
  // weiterklickt, koennte den Platz in der Zwischenzeit verlieren.
  const anmelden = async (a: any, dabei: boolean) => {
    setAusflugLaeuft(a.id); setAusflugFehler('');
    try {
      const { error } = await supabase.rpc('ausflug_anmelden', {
        p_token: token, p_programm: a.id, p_dabei: dabei });
      if (error) throw error;
      const { data } = await supabase.rpc('ausfluege_fuer', { p_token: token });
      setAusfluege((data as any[]) || []);
    } catch (e: any) {
      setAusflugFehler(e?.message || 'Konnte nicht gespeichert werden.');
      const { data } = await supabase.rpc('ausfluege_fuer', { p_token: token });
      setAusfluege((data as any[]) || []);
    } finally { setAusflugLaeuft(''); }
  };

  const speichern = async () => {
    setArbeitet(true); setFehler('');
    try {
      const { error } = await supabase.rpc('vorstellung_speichern', {
        p_token: token, p_name: name, p_funktion: funktion,
        p_vorstellung: vorstellung, p_interessen: interessen,
        p_essen: essen, p_essen_hinweis: hinweis, p_im_heft: imHeft === true,
      });
      if (error) throw error;
      setFertig(true);
    } catch (e: any) {
      setFehler(e?.message || 'Konnte nicht gespeichert werden.');
    } finally { setArbeitet(false); }
  };

  if (laedt) return (
    <div className="min-h-screen flex items-center justify-center" style={{ background: '#faf8f5' }}>
      <Loader2 className="animate-spin text-stone-300" size={24} />
    </div>
  );

  if (fehler && !d) return (
    <div className="min-h-screen flex items-center justify-center px-6" style={{ background: '#faf8f5' }}>
      <div className="max-w-md text-center">
        <AlertTriangle size={28} className="text-amber-500 mx-auto mb-5" />
        <h1 className="font-display text-2xl mb-3 text-stone-900">Dieser Zugang gilt nicht mehr</h1>
        <p className="text-sm text-stone-500 leading-relaxed">{fehler}</p>
        <p className="text-xs text-stone-400 mt-6 leading-relaxed">
          Melden Sie sich bei der Person, die Sie angemeldet hat — sie kann einen neuen Link ausstellen.
        </p>
      </div>
    </div>
  );

  const t = d.treffen;

  const SCHRITTE = [
    {
      frage: 'Wie heissen Sie?',
      unter: `Ihr Name steht später auf dem Namensschild — so, wie Sie ihn hier schreiben.`,
      inhalt: (
        <div className="space-y-5">
          <input autoFocus value={name} onChange={e => setName(e.target.value)}
            placeholder="Vor- und Nachname" className="eingabe-gross" />
          <div>
            <label className="beschriftung">Ihre Rolle im Verein <span className="text-stone-400">(wenn Sie eine haben)</span></label>
            <input value={funktion} onChange={e => setFunktion(e.target.value)}
              placeholder="z. B. Präsidentin, Kassier, Mitglied" className="eingabe" />
          </div>
        </div>
      ),
      weiter: name.trim().length > 1,
    },
    {
      frage: 'Erzählen Sie kurz von sich.',
      unter: 'Zwei, drei Sätze genügen. Was Sie beruflich machen, wie lange Sie dabei sind — was Sie möchten.',
      inhalt: (
        <textarea autoFocus value={vorstellung} onChange={e => setVorstellung(e.target.value)} rows={5}
          placeholder="Ich bin Schreiner und seit der Gründung dabei …" className="eingabe" />
      ),
      weiter: true,
    },
    {
      frage: 'Woran sind Sie interessiert?',
      unter: 'Damit andere wissen, worüber sie mit Ihnen reden können. Ein paar Stichworte reichen.',
      inhalt: (
        <textarea autoFocus value={interessen} onChange={e => setInteressen(e.target.value)} rows={4}
          placeholder="Jugendarbeit, Bauprojekte im Dorf, Austausch mit anderen Vereinen …" className="eingabe" />
      ),
      weiter: true,
    },
    {
      frage: 'Was essen Sie?',
      unter: 'Damit die Küche weiss, womit sie rechnen muss.',
      inhalt: (
        <div className="space-y-5">
          <div className="grid grid-cols-2 gap-2">
            {ESSEN.map(o => (
              <button key={o.w} type="button" onClick={() => setEssen(o.w)}
                className={`text-left px-4 py-3 rounded-2xl border transition-all text-sm ${
                  essen === o.w ? 'border-stone-900 bg-stone-900 text-white'
                               : 'border-stone-200 bg-white hover:border-stone-400'}`}>
                {o.t}
              </button>
            ))}
          </div>
          <div>
            <label className="beschriftung">Allergien oder Hinweise</label>
            <input value={hinweis} onChange={e => setHinweis(e.target.value)}
              placeholder="z. B. Erdnussallergie" className="eingabe" />
            <p className="text-[11px] text-stone-400 mt-2 leading-relaxed">
              Was in keine Liste passt, schreiben Sie hier hin — das liest jemand.
            </p>
          </div>
        </div>
      ),
      weiter: true,
    },
    ...(ausfluege.length ? [{
      frage: ausfluege.length === 1 ? 'Kommen Sie mit auf den Ausflug?' : 'Welche Ausflüge möchten Sie mitmachen?',
      unter: 'Die Plätze sind begrenzt — wer sich zuerst einträgt, ist dabei. Sie können sich bis zum Treffen wieder abmelden.',
      inhalt: (
        <div className="space-y-3">
          {ausfluege.map(a => {
            const voll = a.frei === 0 && !a.dabei;
            return (
              <button key={a.id} type="button" disabled={voll || ausflugLaeuft === a.id}
                onClick={() => anmelden(a, !a.dabei)}
                className={`w-full text-left p-5 rounded-2xl border transition-all ${
                  a.dabei ? 'border-stone-900 bg-white shadow-sm'
                    : voll ? 'border-stone-200 bg-stone-50 opacity-60 cursor-not-allowed'
                    : 'border-stone-200 bg-white/60 hover:border-stone-400'}`}>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-bold text-sm mb-1 flex items-center gap-2">
                      {a.dabei && <Check size={15} />}{a.titel}
                    </p>
                    <p className="text-[12px] text-stone-500 leading-relaxed flex items-start gap-1.5">
                      <MapPin size={12} className="shrink-0 mt-0.5" />{a.ziel}
                    </p>
                    <p className="text-[12px] text-stone-500 leading-relaxed mt-1">
                      {String(a.beginn).slice(0,5)}{a.rueckkehr ? `–${String(a.rueckkehr).slice(0,5)}` : ''}
                      {a.treffpunkt ? ` · ab ${a.treffpunkt}` : ''}
                      {a.anreise ? ` · ${a.anreise}` : ''}
                      {Number(a.kosten) > 0 ? ` · ${Number(a.kosten).toFixed(2)} CHF` : ''}
                    </p>
                  </div>
                  <span className="text-[10px] font-bold uppercase tracking-widest shrink-0 text-stone-400">
                    {ausflugLaeuft === a.id ? '…'
                      : a.plaetze == null ? 'offen'
                      : voll ? 'ausgebucht'
                      : `${a.frei} frei`}
                  </span>
                </div>
              </button>
            );
          })}
          {ausflugFehler && <p className="text-xs text-amber-700">{ausflugFehler}</p>}
          <p className="text-[11px] text-stone-400 leading-relaxed">
            Ihre Anmeldung gilt sofort — Sie müssen dafür nicht bis zum Schluss klicken.
          </p>
        </div>
      ),
      weiter: true,
    }] : []),
    {
      frage: 'Dürfen wir Sie ins Heft aufnehmen?',
      unter: `Nach dem Treffen bekommen alle Teilnehmenden ein kleines Heft: wer dabei war, von welchem Verein, und was die Leute geschrieben haben. Sie entscheiden, ob Sie darin stehen.`,
      inhalt: (
        <div className="space-y-4">
          {([
            { w: true,  t: 'Ja, gerne',
              u: 'Ihr Name, Ihr Verein und was Sie oben geschrieben haben erscheinen im Heft.' },
            { w: false, t: 'Lieber nicht',
              u: 'Sie nehmen ganz normal teil, erscheinen aber nicht im Heft. Das Heft zählt Sie nur mit — ohne Namen.' },
          ] as const).map(o => (
            <button key={String(o.w)} type="button" onClick={() => setImHeft(o.w)}
              className={`w-full text-left p-5 rounded-2xl border transition-all ${
                imHeft === o.w ? 'border-stone-900 bg-white shadow-sm' : 'border-stone-200 bg-white/60 hover:border-stone-400'}`}>
              <p className="font-bold text-sm mb-1 flex items-center gap-2">
                {imHeft === o.w && <Check size={15} />} {o.t}
              </p>
              <p className="text-[12px] text-stone-500 leading-relaxed">{o.u}</p>
            </button>
          ))}
          <p className="text-[11px] text-stone-400 leading-relaxed">
            Essenswunsch und Allergien stehen nie im Heft — die gehen nur an die Küche.
          </p>
        </div>
      ),
      weiter: imHeft !== null,
    },
  ];

  const s = SCHRITTE[schritt];
  const letzter = schritt === SCHRITTE.length - 1;

  if (fertig) return (
    <div className="min-h-screen flex items-center justify-center px-6" style={{ background: '#faf8f5' }}>
      <div className="max-w-md text-center">
        <Sparkles size={26} className="text-stone-400 mx-auto mb-5" />
        <h1 className="font-display text-3xl mb-4 text-stone-900">Danke, {name.split(' ')[0]}.</h1>
        <p className="text-sm text-stone-500 leading-relaxed mb-2">
          Wir sehen uns am {tag(t.datum)}{t.ort ? ` in ${t.ort}` : ''}.
        </p>
        <p className="text-sm text-stone-500 leading-relaxed">
          {imHeft
            ? 'Nach dem Treffen bekommen Sie hier das Heft mit allen, die dabei waren.'
            : 'Sie erscheinen nicht im Heft — Sie können es nach dem Treffen trotzdem hier ansehen.'}
        </p>
        <button onClick={() => { setFertig(false); setSchritt(0); }}
          className="mt-8 text-[11px] font-bold uppercase tracking-widest text-stone-400 hover:text-stone-900">
          Angaben nochmals ändern
        </button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex flex-col" style={{ background: '#faf8f5' }}>
      <style>{`
        .eingabe, .eingabe-gross {
          width: 100%; background: #fff; border: 1px solid #e7e5e4; border-radius: 1rem;
          padding: .9rem 1.1rem; outline: none; color: #1c1917; line-height: 1.5;
        }
        .eingabe { font-size: 15px; }
        .eingabe-gross { font-size: 22px; padding: 1.1rem 1.2rem; }
        .eingabe:focus, .eingabe-gross:focus { border-color: #1c1917; }
        .eingabe::placeholder, .eingabe-gross::placeholder { color: #a8a29e; }
        .beschriftung {
          display: block; font-size: 10px; font-weight: 700; text-transform: uppercase;
          letter-spacing: .12em; color: #a8a29e; margin-bottom: .5rem;
        }
      `}</style>

      <header className="px-6 pt-8 pb-2">
        <div className="max-w-xl mx-auto">
          <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-stone-400">{t.titel}</p>
          <p className="text-[11px] text-stone-400 mt-0.5">
            {tag(t.datum)}{t.ort ? ` · ${t.ort}` : ''} · für {d.verein}
          </p>
        </div>
      </header>

      <main className="flex-1 flex items-center px-6 py-6">
        <div className="max-w-xl mx-auto w-full">
          <h1 className="font-display text-stone-900 mb-3"
              style={{ fontSize: 'clamp(1.8rem, 5vw, 2.5rem)', lineHeight: 1.15, letterSpacing: '-0.02em' }}>
            {s.frage}
          </h1>
          <p className="text-sm text-stone-500 leading-relaxed mb-8 max-w-lg">{s.unter}</p>
          {s.inhalt}
          {fehler && <p className="text-xs text-red-600 mt-5">{fehler}</p>}
        </div>
      </main>

      <footer className="px-6 pb-10">
        <div className="max-w-xl mx-auto flex items-center justify-between gap-4">
          <button onClick={() => setSchritt(x => Math.max(0, x - 1))}
            className={`flex items-center gap-2 text-[11px] font-bold uppercase tracking-widest
                        ${schritt === 0 ? 'opacity-0 pointer-events-none' : 'text-stone-400 hover:text-stone-900'}`}>
            <ArrowLeft size={14} /> Zurück
          </button>

          {/* Der Fortschritt als Punkte: wer sieht, dass noch zwei kommen,
              hört nicht nach dem dritten auf. */}
          <div className="flex items-center gap-1.5">
            {SCHRITTE.map((_, i) => (
              <span key={i} className={`rounded-full transition-all ${
                i === schritt ? 'w-5 h-1.5 bg-stone-900' : i < schritt ? 'w-1.5 h-1.5 bg-stone-400' : 'w-1.5 h-1.5 bg-stone-200'}`} />
            ))}
          </div>

          <button onClick={() => letzter ? speichern() : setSchritt(x => x + 1)}
            disabled={!s.weiter || arbeitet}
            className="flex items-center gap-2 bg-stone-900 text-white px-6 py-3 rounded-2xl
                       text-sm font-bold disabled:opacity-30 hover:bg-black transition-colors">
            {arbeitet ? <Loader2 size={16} className="animate-spin" />
              : letzter ? <Check size={16} /> : null}
            {letzter ? 'Fertig' : 'Weiter'}
            {!letzter && <ArrowRight size={16} />}
          </button>
        </div>
      </footer>
    </div>
  );
};

export default VorstellungWizard;
