import React, { useEffect, useMemo, useState } from 'react';
import {
  Loader2, TrendingUp, Users, Clock, LogOut, Search, Globe, Smartphone,
  Monitor, Tablet, AlertTriangle, CheckCircle2, Target, MapPin, Languages,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';

// Wie laeuft die Website?
//
// Die Zahlen kommen aus dem eigenen Zaehler, nicht von einem Dienst.
// Was hier steht, beantwortet fuenf Fragen und nicht fuenfzig:
//
//   Wie viele waren da, und wie viele davon verschiedene Menschen?
//   Wie lange sind sie geblieben, und wie viele gingen gleich wieder?
//   Woher kamen sie?
//   Mit welchem Geraet, zu welcher Stunde, aus welchem Land?
//   Wie viele haben am Ende etwas getan?
//
// Bewusst keine Verlaufskurve mit Wochenvergleich und Trendpfeil: bei
// einem Verein mit ein paar Dutzend Besuchern am Tag ist eine
// Prozentzahl gegenueber der Vorwoche Rauschen. Was traegt, sind die
// absoluten Zahlen und die Herkunft.

type Kennzahl = {
  r_pfad: string; r_aufrufe: number; r_besucher: number;
  r_dauer_s: number | null; r_absprung: number;
};
type Herkunft = { r_art: string; r_quelle: string; r_aufrufe: number; r_besucher: number };
type Verteilung = { r_art: string; r_wert: string; r_aufrufe: number };
type Ziel = { r_ziel: string; r_pfad: string; r_anzahl: number; r_besucher: number };

const ZEITRAEUME = [
  { tage: 7, name: '7 Tage' },
  { tage: 30, name: '30 Tage' },
  { tage: 90, name: '90 Tage' },
] as const;

const HERKUNFT_NAME: Record<string, string> = {
  SUCHE: 'Suchmaschine', SOZIAL: 'Soziale Medien',
  DIREKT: 'Direkt eingegeben', VERWEIS: 'Andere Seiten', INTERN: 'Intern',
};

const GERAET_SYMBOL: Record<string, React.ReactNode> = {
  HANDY: <Smartphone size={14} />, TABLET: <Tablet size={14} />,
  RECHNER: <Monitor size={14} />, UNBEKANNT: <Globe size={14} />,
};

const AdminSeo: React.FC<{ fuerBetreiber?: boolean }> = ({ fuerBetreiber }) => {
  const [tage, setTage] = useState<number>(30);
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  const [kennzahlen, setKennzahlen] = useState<Kennzahl[]>([]);
  const [herkunft, setHerkunft] = useState<Herkunft[]>([]);
  const [verteilung, setVerteilung] = useState<Verteilung[]>([]);
  const [ziele, setZiele] = useState<Ziel[]>([]);
  const [vereine, setVereine] = useState<any[]>([]);
  const [seo, setSeo] = useState<{ pfad: string; mangel: string[] }[]>([]);

  const laden = async () => {
    setLaedt(true); setFehler('');
    const von = new Date(Date.now() - tage * 86400000).toISOString().slice(0, 10);
    const bis = new Date().toISOString().slice(0, 10);
    const p = { p_von: von, p_bis: bis };
    const [k, h, v, z, jv] = await Promise.all([
      supabase.rpc('seo_kennzahlen', p),
      supabase.rpc('seo_herkunft', p),
      supabase.rpc('seo_verteilung', p),
      supabase.rpc('seo_ziele', p),
      fuerBetreiber ? supabase.rpc('seo_je_verein', p) : Promise.resolve({ data: [] } as any),
    ]);
    const err = [k, h, v, z, jv].find(x => (x as any).error);
    if (err) setFehler((err as any).error.message);
    setKennzahlen((k.data as Kennzahl[]) ?? []);
    setHerkunft((h.data as Herkunft[]) ?? []);
    setVerteilung((v.data as Verteilung[]) ?? []);
    setZiele((z.data as Ziel[]) ?? []);
    setVereine((jv.data as any[]) ?? []);
    setLaedt(false);
  };

  useEffect(() => { laden(); }, [tage, fuerBetreiber]);

  // Der SEO-Zustand der eigenen Seiten.
  //
  // Geprueft wird, was in den Daten steht -- Titel, Beschreibung,
  // Inhalt. Das ist kein Ersatz fuer die Google Search Console, aber es
  // beantwortet die Frage, die man selbst beantworten kann: fehlt
  // irgendwo das Naheliegende? Eine Seite ohne Titel findet niemand,
  // und das steht in der eigenen Datenbank, nicht bei Google.
  useEffect(() => {
    if (fuerBetreiber) return;
    (async () => {
      const [{ data: s }, { data: t }] = await Promise.all([
        // Die Spalten heissen bloecke und status, nicht blocks und
        // veroeffentlicht. Mit den falschen Namen kam undefined zurueck,
        // und die Pruefung haette bei JEDER Seite "kaum Inhalt" gemeldet
        // -- ein Pruefer, der immer dasselbe sagt, ist schlimmer als
        // keiner, weil man ihm glaubt.
        supabase.from('seiten').select('pfad,titel,bloecke,status'),
        supabase.from('settings').select('branding').eq('id', 'branding').maybeSingle(),
      ]);
      const br = (t as any)?.branding ?? {};
      const liste: { pfad: string; mangel: string[] }[] = [];

      const text = (w: any) => {
        if (!w) return '';
        if (typeof w === 'string') return w.trim();
        return String(w.de ?? w.sq ?? w.en ?? '').trim();
      };

      // Die Startseite kommt aus dem Branding.
      const startMangel: string[] = [];
      if (!text(br.heroTitle)) startMangel.push('Überschrift fehlt');
      if (!text(br.heroSubtitle)) startMangel.push('Beschreibung fehlt');
      if (!text(br.footerText)) startMangel.push('Kurzbeschreibung im Fuss fehlt');
      if (!(br.heroImages?.length)) startMangel.push('kein Bild');
      liste.push({ pfad: '/', mangel: startMangel });

      for (const seite of ((s as any[]) ?? [])) {
        const m: string[] = [];
        if (!text(seite.titel)) m.push('Titel fehlt');
        const inhalt = JSON.stringify(seite.bloecke ?? []);
        if (inhalt.length < 80) m.push('kaum Inhalt');
        if (!/"bild"|"image"/.test(inhalt)) m.push('kein Bild');
        if (seite.status && seite.status !== 'OEFFENTLICH' && seite.status !== 'PUBLIC') {
          m.push('nicht öffentlich');
        }
        liste.push({ pfad: '/' + seite.pfad, mangel: m });
      }
      setSeo(liste);
    })();
  }, [fuerBetreiber]);

  const summe = useMemo(() => ({
    aufrufe: kennzahlen.reduce((s, k) => s + Number(k.r_aufrufe), 0),
    besucher: Math.max(...[0, ...kennzahlen.map(k => Number(k.r_besucher))]),
    dauer: (() => {
      const mit = kennzahlen.filter(k => k.r_dauer_s != null);
      if (!mit.length) return null;
      const gewicht = mit.reduce((s, k) => s + Number(k.r_aufrufe), 0);
      return gewicht ? mit.reduce((s, k) =>
        s + Number(k.r_dauer_s) * Number(k.r_aufrufe), 0) / gewicht : null;
    })(),
    absprung: (() => {
      const g = kennzahlen.reduce((s, k) => s + Number(k.r_aufrufe), 0);
      return g ? kennzahlen.reduce((s, k) =>
        s + Number(k.r_absprung) * Number(k.r_aufrufe), 0) / g : null;
    })(),
  }), [kennzahlen]);

  const teil = (art: string) => verteilung.filter(v => v.r_art === art);
  const grosse = (reihe: Verteilung[]) =>
    Math.max(1, ...reihe.map(r => Number(r.r_aufrufe)));

  if (laedt) return (
    <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 flex items-center gap-3 text-stone-400">
      <Loader2 className="animate-spin" size={18} /> <span className="text-sm">Lädt …</span>
    </div>
  );

  const nichts = summe.aufrufe === 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div>
          <h3 className="font-bold text-lg text-stone-900">
            {fuerBetreiber ? 'Websites aller Vereine' : 'Besuche auf der Website'}
          </h3>
          <p className="text-xs text-stone-500 mt-0.5">
            Eigene Zählung, ohne Cookies und ohne IP-Adressen. Interne Bereiche
            sind nicht mitgezählt.
          </p>
        </div>
        <div className="flex gap-1 bg-stone-100 p-1 rounded-xl shrink-0">
          {ZEITRAEUME.map(z => (
            <button key={z.tage} onClick={() => setTage(z.tage)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                tage === z.tage ? 'bg-stone-900 text-white' : 'text-stone-500 hover:text-stone-800'}`}>
              {z.name}
            </button>
          ))}
        </div>
      </div>

      {fehler && (
        <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 flex gap-2">
          <AlertTriangle size={14} className="shrink-0 mt-0.5" /> {fehler}
        </p>
      )}

      {nichts ? (
        <div className="p-8 bg-stone-50 border border-stone-100 rounded-3xl text-center">
          <Search className="mx-auto text-stone-300 mb-3" size={32} />
          <p className="text-sm text-stone-500 leading-relaxed max-w-md mx-auto">
            Für diesen Zeitraum liegen noch keine Besuche vor. Die Zählung läuft
            seit dem Einbau — ältere Besuche gibt es nicht, weil vorher nichts
            gemessen wurde.
          </p>
        </div>
      ) : (
        <>
          {/* Die vier Zahlen, um die es geht */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { n: 'Aufrufe', w: summe.aufrufe.toLocaleString('de-CH'),
                i: <TrendingUp size={15} />, h: 'jede geöffnete Seite' },
              { n: 'Besucher', w: summe.besucher.toLocaleString('de-CH'),
                i: <Users size={15} />, h: 'verschiedene Menschen, je Tag gezählt' },
              { n: 'Verweildauer', w: summe.dauer == null ? '—'
                  : `${Math.round(summe.dauer)} s`,
                i: <Clock size={15} />, h: 'im Mittel, nur sichtbare Zeit' },
              { n: 'Absprungrate', w: summe.absprung == null ? '—'
                  : `${summe.absprung.toFixed(0)} %`,
                i: <LogOut size={15} />, h: 'nur eine Seite gesehen' },
            ].map(k => (
              <div key={k.n} className="bg-white p-5 rounded-2xl border border-stone-100">
                <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-1.5">
                  {k.i} {k.n}
                </p>
                <p className="text-2xl font-bold text-stone-900 mt-1.5 font-mono">{k.w}</p>
                <p className="text-[10px] text-stone-400 mt-1">{k.h}</p>
              </div>
            ))}
          </div>

          {/* Fuer den Betreiber: je Verein */}
          {fuerBetreiber && vereine.length > 0 && (
            <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
              <div className="p-5 border-b border-stone-100 bg-stone-50">
                <h4 className="font-bold text-sm text-stone-900">Je Verein</h4>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                      <th className="text-left p-4">Verein</th>
                      <th className="text-right p-4">Aufrufe</th>
                      <th className="text-right p-4">Besucher</th>
                      <th className="text-right p-4">Dauer</th>
                      <th className="text-right p-4">Seiten</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-stone-50">
                    {vereine.map(v => (
                      <tr key={v.r_verein} className="hover:bg-stone-50">
                        <td className="p-4 font-bold text-stone-800">{v.r_name}</td>
                        <td className="p-4 text-right font-mono">{v.r_aufrufe}</td>
                        <td className="p-4 text-right font-mono">{v.r_besucher}</td>
                        <td className="p-4 text-right font-mono text-stone-500">
                          {v.r_dauer_s == null ? '—' : `${Math.round(v.r_dauer_s)} s`}
                        </td>
                        <td className="p-4 text-right font-mono text-stone-500">{v.r_seiten}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Seiten */}
          <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
            <div className="p-5 border-b border-stone-100 bg-stone-50">
              <h4 className="font-bold text-sm text-stone-900">Welche Seiten</h4>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-[10px] font-bold text-stone-400 uppercase tracking-widest border-b border-stone-100">
                    <th className="text-left p-4">Pfad</th>
                    <th className="text-right p-4">Aufrufe</th>
                    <th className="text-right p-4">Besucher</th>
                    <th className="text-right p-4">Dauer</th>
                    <th className="text-right p-4">Absprung</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-50">
                  {kennzahlen.map(k => (
                    <tr key={k.r_pfad} className="hover:bg-stone-50">
                      <td className="p-4 font-mono text-xs text-stone-800">{k.r_pfad}</td>
                      <td className="p-4 text-right font-mono font-bold">{k.r_aufrufe}</td>
                      <td className="p-4 text-right font-mono">{k.r_besucher}</td>
                      <td className="p-4 text-right font-mono text-stone-500">
                        {k.r_dauer_s == null ? '—' : `${Math.round(k.r_dauer_s)} s`}
                      </td>
                      <td className={`p-4 text-right font-mono ${
                        Number(k.r_absprung) > 70 ? 'text-amber-700 font-bold' : 'text-stone-500'}`}>
                        {Number(k.r_absprung).toFixed(0)} %
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Herkunft */}
            <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
              <div className="p-5 border-b border-stone-100 bg-stone-50">
                <h4 className="font-bold text-sm text-stone-900">Woher sie kamen</h4>
              </div>
              <div className="p-5 space-y-3">
                {herkunft.map(h => (
                  <div key={h.r_art + h.r_quelle} className="flex items-center justify-between gap-3 text-xs">
                    <div className="min-w-0">
                      <p className="font-bold text-stone-800 truncate">
                        {h.r_quelle === '—' ? HERKUNFT_NAME[h.r_art] ?? h.r_art : h.r_quelle}
                      </p>
                      {h.r_quelle !== '—' && (
                        <p className="text-[10px] text-stone-400">{HERKUNFT_NAME[h.r_art] ?? h.r_art}</p>
                      )}
                    </div>
                    <span className="font-mono font-bold text-stone-900 shrink-0">{h.r_aufrufe}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Geraet, Sprache, Land */}
            <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
              <div className="p-5 border-b border-stone-100 bg-stone-50">
                <h4 className="font-bold text-sm text-stone-900">Womit und woher</h4>
              </div>
              <div className="p-5 space-y-5">
                {([['GERAET', 'Gerät', null],
                   ['SPRACHE', 'Sprache', <Languages size={13} key="s" />],
                   ['LAND', 'Land', <MapPin size={13} key="l" />]] as const).map(([art, name, sym]) => (
                  teil(art).length > 0 && (
                    <div key={art}>
                      <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                        {sym} {name}
                      </p>
                      <div className="space-y-1.5">
                        {teil(art).sort((a, b) => Number(b.r_aufrufe) - Number(a.r_aufrufe))
                          .slice(0, 5).map(v => (
                          <div key={v.r_wert} className="flex items-center gap-2 text-xs">
                            <span className="w-24 shrink-0 flex items-center gap-1.5 text-stone-600">
                              {art === 'GERAET' ? GERAET_SYMBOL[v.r_wert] : null}
                              {v.r_wert}
                            </span>
                            <span className="flex-1 h-2 bg-stone-100 rounded-full overflow-hidden">
                              <span className="block h-full bg-stone-900 rounded-full"
                                style={{ width: `${100 * Number(v.r_aufrufe) / grosse(teil(art))}%` }} />
                            </span>
                            <span className="font-mono text-stone-500 w-8 text-right">{v.r_aufrufe}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )
                ))}
              </div>
            </div>
          </div>

          {/* Uhrzeit */}
          {teil('STUNDE').length > 0 && (
            <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
              <div className="p-5 border-b border-stone-100 bg-stone-50">
                <h4 className="font-bold text-sm text-stone-900">Zu welcher Stunde</h4>
                <p className="text-[10px] text-stone-400 mt-0.5">Zürcher Zeit</p>
              </div>
              <div className="p-5 flex items-end gap-1 h-32">
                {Array.from({ length: 24 }, (_, i) => {
                  const s = teil('STUNDE').find(v => Number(v.r_wert) === i);
                  const n = s ? Number(s.r_aufrufe) : 0;
                  const max = grosse(teil('STUNDE'));
                  return (
                    <div key={i} className="flex-1 flex flex-col items-center gap-1 h-full justify-end"
                      title={`${String(i).padStart(2, '0')} Uhr: ${n}`}>
                      <span className="w-full bg-stone-900 rounded-t transition-all"
                        style={{ height: `${Math.max(2, 100 * n / max)}%` }} />
                      {i % 3 === 0 && (
                        <span className="text-[9px] text-stone-400 font-mono">{String(i).padStart(2, '0')}</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Ziele */}
          {ziele.length > 0 && (
            <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
              <div className="p-5 border-b border-stone-100 bg-stone-50">
                <h4 className="font-bold text-sm text-stone-900 flex items-center gap-2">
                  <Target size={15} className="text-primary" /> Was sie getan haben
                </h4>
              </div>
              <div className="divide-y divide-stone-50">
                {ziele.map(z => (
                  <div key={z.r_ziel + z.r_pfad} className="p-4 flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="font-bold text-sm text-stone-900">{z.r_ziel}</p>
                      <p className="text-[11px] text-stone-400 font-mono">{z.r_pfad}</p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="font-mono font-bold text-stone-900">{z.r_anzahl}</p>
                      <p className="text-[10px] text-stone-400">
                        {summe.besucher > 0
                          ? `${(100 * Number(z.r_besucher) / summe.besucher).toFixed(1)} % der Besucher`
                          : ''}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {/* SEO-Zustand -- unabhaengig von den Besuchszahlen */}
      {!fuerBetreiber && seo.length > 0 && (
        <div className="bg-white rounded-3xl border border-stone-100 overflow-hidden">
          <div className="p-5 border-b border-stone-100 bg-stone-50">
            <h4 className="font-bold text-sm text-stone-900">Zustand der Seiten</h4>
            <p className="text-[11px] text-stone-500 mt-0.5">
              Was sich aus den eigenen Daten prüfen lässt. Für Suchbegriffe und
              Positionen bei Google braucht es die Search Console — das ist eine
              eigene Verknüpfung.
            </p>
          </div>
          <div className="divide-y divide-stone-50">
            {seo.map(s => (
              <div key={s.pfad} className="p-4 flex items-start justify-between gap-3">
                <p className="font-mono text-xs text-stone-700 shrink-0 w-32 truncate">{s.pfad}</p>
                {s.mangel.length === 0 ? (
                  <span className="text-[11px] font-bold text-emerald-700 flex items-center gap-1.5">
                    <CheckCircle2 size={13} /> vollständig
                  </span>
                ) : (
                  <div className="flex flex-wrap gap-1.5 justify-end">
                    {s.mangel.map(m => (
                      <span key={m} className="px-2 py-0.5 bg-amber-50 text-amber-800 border border-amber-200 rounded text-[10px] font-bold">
                        {m}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminSeo;
