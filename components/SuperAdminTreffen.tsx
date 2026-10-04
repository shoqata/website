import React, { useEffect, useState } from 'react';
import {
  Loader2, Plus, ChevronRight, ChevronLeft, Check, Users, CalendarDays,
  Banknote, ListOrdered, Eye, Trash2, Link2, Copy,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import TreffenWerkzeuge from './TreffenWerkzeuge';

// Vereinstreffen anlegen -- als Assistent, nicht als Formular.
//
// Ein Treffen hat fuenf Dinge, die nacheinander entschieden werden:
// was und wann, was es kostet, wer kommt, was am Tag passiert, und erst
// dann ob es oeffentlich wird. In ein einziges Formular gegossen waere das
// eine Wand aus dreissig Feldern, von denen zwanzig erst spaeter wichtig
// werden -- und die Preisfrage ginge unter, obwohl sie den Rest praegt.
//
// Gastgeber ist ausschliesslich der Betreiber. Vereine sind Teilnehmer.
// Das steht nicht nur hier so, sondern in den Zeilenregeln: eine
// Oberflaeche kann man umgehen.

type Preisart = 'KEINE' | 'PRO_VEREIN' | 'PRO_KOPF';

type Entwurf = {
  titel: string; beschreibung: string; datum: string; ende: string;
  beginn: string; ort: string; adresse: string; anmeldeschluss: string;
  preis_art: Preisart; preis_betrag: string; waehrung: string;
};

type Gast = { art: 'GASTVEREIN' | 'GAST'; name: string; kontakt_name: string; kontakt_email: string };
type Punkt = { beginn: string; dauer_min: string; titel: string; ort: string;
               verantwortlich: string; spur: string; fuer: 'ALLE' | 'VERTRETER';
               // Ein Ausflug ist kein gewoehnlicher Punkt: er hat ein Ziel,
               // einen Treffpunkt und begrenzte Plaetze.
               art: 'PUNKT' | 'AUSFLUG'; ziel: string; treffpunkt: string;
               anreise: string; rueckkehr: string; plaetze: string; kosten: string };

const LEERER_PUNKT: Punkt = { beginn:'', dauer_min:'', titel:'', ort:'', verantwortlich:'',
  spur:'Alle', fuer:'ALLE', art:'PUNKT', ziel:'', treffpunkt:'', anreise:'',
  rueckkehr:'', plaetze:'', kosten:'' };

const LEER: Entwurf = {
  titel: '', beschreibung: '', datum: '', ende: '', beginn: '09:00',
  ort: '', adresse: '', anmeldeschluss: '',
  preis_art: 'KEINE', preis_betrag: '', waehrung: 'CHF',
};

const SCHRITTE = [
  { nr: 1, titel: 'Was und wann',  symbol: CalendarDays },
  { nr: 2, titel: 'Was es kostet', symbol: Banknote },
  { nr: 3, titel: 'Wer kommt',     symbol: Users },
  { nr: 4, titel: 'Tagesprogramm', symbol: ListOrdered },
  { nr: 5, titel: 'Prüfen',        symbol: Eye },
];

const geld = (w: any) => Number(w || 0).toLocaleString('de-CH', { minimumFractionDigits: 2 });

const SuperAdminTreffen: React.FC = () => {
  const [liste, setListe] = useState<any[] | null>(null);
  const [vereine, setVereine] = useState<any[]>([]);
  const [offen, setOffen] = useState(false);
  const [schritt, setSchritt] = useState(1);
  const [e, setE] = useState<Entwurf>(LEER);
  const [gewaehlteVereine, setGewaehlteVereine] = useState<string[]>([]);
  const [gaeste, setGaeste] = useState<Gast[]>([]);
  const [programm, setProgramm] = useState<Punkt[]>([]);
  const [arbeitet, setArbeitet] = useState(false);
  const [fehler, setFehler] = useState('');
  // Die Teilnehmer eines Treffens -- erst auf Klick geladen. Die Liste der
  // Treffen soll nicht auf zwanzig Unterabfragen warten.
  const [detail, setDetail] = useState<string | null>(null);
  const [teilnehmer, setTeilnehmer] = useState<any[]>([]);
  const [kosten, setKosten] = useState<any>(null);
  const [frischerLink, setFrischerLink] = useState<{ id: string; url: string } | null>(null);
  const [kopiert, setKopiert] = useState(false);

  const detailLaden = async (id: string) => {
    if (detail === id) { setDetail(null); return; }
    setDetail(id); setFrischerLink(null);
    const { data } = await supabase.from('treffen_teilnehmer')
      .select('*').eq('treffen_id', id).order('art');
    setTeilnehmer(data || []);
    const { data: k } = await supabase.rpc('treffen_kosten', { p_treffen: id });
    setKosten(k);
  };

  const linkAusstellen = async (t: any) => {
    setArbeitet(true); setFehler('');
    try {
      const { data, error } = await supabase.rpc('treffen_zugang_erstellen', { p_teilnehmer: t.id });
      if (error) throw error;
      setFrischerLink({ id: t.id, url: `${window.location.origin}/#/treffen/${(data as any).token}` });
      await detailLaden(detail!); setDetail(detail);
    } catch (e: any) { setFehler(e?.message || 'Konnte nicht ausgestellt werden.'); }
    finally { setArbeitet(false); }
  };

  const linkWiderrufen = async (t: any) => {
    setArbeitet(true); setFehler('');
    try {
      const { error } = await supabase.rpc('treffen_zugang_widerrufen', { p_teilnehmer: t.id });
      if (error) throw error;
      setFrischerLink(null);
      const { data } = await supabase.from('treffen_teilnehmer')
        .select('*').eq('treffen_id', detail!).order('art');
      setTeilnehmer(data || []);
    } catch (e: any) { setFehler(e?.message || 'Konnte nicht widerrufen werden.'); }
    finally { setArbeitet(false); }
  };

  const laden = async () => {
    const { data } = await supabase.from('treffen').select('*').order('datum', { ascending: false });
    setListe(data || []);
    const { data: v } = await supabase.from('tenants').select('id,name').order('name');
    setVereine(v || []);
  };
  useEffect(() => { laden(); }, []);

  const setzen = (teil: Partial<Entwurf>) => setE(a => ({ ...a, ...teil }));

  // Was in diesem Schritt noch fehlt. Zurueck darf man immer, weiter nur,
  // wenn das Noetige dasteht -- aber der Assistent sagt, was fehlt, statt
  // den Knopf stumm zu sperren.
  const fehltImSchritt = (): string | null => {
    if (schritt === 1) {
      if (!e.titel.trim()) return 'Das Treffen braucht einen Titel.';
      if (!e.datum) return 'Wann findet es statt?';
      if (e.ende && e.ende < e.datum) return 'Das Ende liegt vor dem Beginn.';
    }
    if (schritt === 2 && e.preis_art !== 'KEINE' && !(Number(e.preis_betrag) > 0))
      return 'Bei einem Beitrag muss auch ein Betrag dastehen.';
    return null;
  };

  const anlegen = async (status: 'ENTWURF' | 'OEFFENTLICH') => {
    setArbeitet(true); setFehler('');
    try {
      const { data: t, error } = await supabase.from('treffen').insert([{
        titel: e.titel.trim(), beschreibung: e.beschreibung.trim() || null,
        datum: e.datum, ende: e.ende || null, beginn: e.beginn || null,
        ort: e.ort.trim() || null, adresse: e.adresse.trim() || null,
        anmeldeschluss: e.anmeldeschluss || null,
        preis_art: e.preis_art,
        preis_betrag: e.preis_art === 'KEINE' ? 0 : Number(e.preis_betrag),
        waehrung: e.waehrung, status,
      }]).select('id').single();
      if (error) throw error;
      const id = (t as any).id;

      const teilnehmer = [
        ...gewaehlteVereine.map(v => ({ treffen_id: id, art: 'VEREIN', tenantId: v })),
        ...gaeste.filter(g => g.name.trim()).map(g => ({
          treffen_id: id, art: g.art, name: g.name.trim(),
          kontakt_name: g.kontakt_name.trim() || null,
          kontakt_email: g.kontakt_email.trim() || null,
        })),
      ];
      if (teilnehmer.length) {
        const { error: f1 } = await supabase.from('treffen_teilnehmer').insert(teilnehmer);
        if (f1) throw f1;
      }
      const punkte = programm
        // Ein Ausflug ohne Ziel wird von der Datenbank abgewiesen. Ihn hier
        // schon wegzulassen ist freundlicher als eine Fehlermeldung nach
        // fuenf Schritten.
        .filter(p => p.titel.trim() && p.beginn && (p.art !== 'AUSFLUG' || p.ziel.trim()))
        .map((p, i) => ({
        treffen_id: id, beginn: p.beginn, dauer_min: p.dauer_min ? Number(p.dauer_min) : null,
        titel: p.titel.trim(), ort: p.ort.trim() || null,
        verantwortlich: p.verantwortlich.trim() || null,
        spur: p.spur.trim() || 'Alle', fuer: p.fuer,
        art: p.art,
        ziel: p.art === 'AUSFLUG' ? (p.ziel.trim() || null) : null,
        treffpunkt: p.treffpunkt.trim() || null,
        anreise: p.anreise.trim() || null,
        rueckkehr: p.rueckkehr || null,
        plaetze: p.plaetze ? Number(p.plaetze) : null,
        kosten: p.kosten ? Number(p.kosten) : 0,
        // Beim Anlegen noch nicht freigegeben: erst planen, dann zeigen.
        freigegeben: false, reihenfolge: i + 1,
      }));
      if (punkte.length) {
        const { error: f2 } = await supabase.from('treffen_programm').insert(punkte);
        if (f2) throw f2;
      }

      setOffen(false); setSchritt(1); setE(LEER);
      setGewaehlteVereine([]); setGaeste([]); setProgramm([]);
      await laden();
    } catch (err: any) {
      setFehler(err?.message || 'Konnte nicht angelegt werden.');
    } finally { setArbeitet(false); }
  };

  const feld = (bez: string, kind: React.ReactNode, breit = false) => (
    <label className={`block ${breit ? 'md:col-span-2' : ''}`}>
      <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-1.5">{bez}</span>
      {kind}
    </label>
  );
  // text-stone-900 ausdruecklich: der Betreiberbereich setzt text-white auf
  // den ganzen Rahmen (bg-stone-950 text-white), und ein weisses Feld erbt
  // das -- weisse Schrift auf weissem Grund. Eine Farbe, die nur dort
  // stimmt, wo sie gesetzt wurde, ist keine.
  const eingabe = "w-full p-2.5 bg-white border border-stone-200 rounded-xl text-sm text-stone-900 placeholder:text-stone-400 outline-none focus:border-stone-400";

  // ---------------------------------------------------------------- Liste
  if (!offen) return (
    <div className="space-y-5">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h3 className="text-xl font-bold text-white">Vereinstreffen</h3>
          <p className="text-xs text-stone-400 mt-0.5">
            Anlässe mit mehreren Vereinen, Gastvereinen und Gästen. Gastgeber sind Sie.
          </p>
        </div>
        <button onClick={() => setOffen(true)}
          className="flex items-center gap-2 bg-white text-stone-900 px-5 py-2.5 rounded-xl
                     text-[11px] font-bold uppercase tracking-widest">
          <Plus size={14} /> Treffen anlegen
        </button>
      </div>

      {liste === null ? (
        <div className="flex items-center gap-2 text-stone-400 text-sm py-8">
          <Loader2 className="animate-spin" size={15} /> …
        </div>
      ) : liste.length === 0 ? (
        <p className="text-sm text-stone-400 py-8">Noch kein Treffen angelegt.</p>
      ) : (
        <div className="space-y-2">
          {liste.map(t => (
            <div key={t.id} className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
            <button onClick={() => detailLaden(t.id)}
              className="w-full text-left p-5 flex items-center justify-between gap-4 flex-wrap hover:bg-white/5">
              <div className="min-w-0">
                <p className="font-bold text-white truncate">{t.titel}</p>
                <p className="text-[11px] text-stone-400 mt-0.5">
                  {new Date(t.datum).toLocaleDateString('de-CH')}
                  {t.ende && t.ende !== t.datum ? ` – ${new Date(t.ende).toLocaleDateString('de-CH')}` : ''}
                  {t.ort ? ` · ${t.ort}` : ''}
                  {' · '}
                  {t.preis_art === 'KEINE' ? 'kostenlos'
                    : `${geld(t.preis_betrag)} ${t.waehrung} ${t.preis_art === 'PRO_KOPF' ? 'pro Person' : 'pro Verein'}`}
                </p>
              </div>
              <span className={`text-[10px] font-bold uppercase tracking-widest shrink-0 ${
                t.status === 'OEFFENTLICH' ? 'text-emerald-400'
                : t.status === 'BEENDET' ? 'text-stone-500' : 'text-amber-400'}`}>
                {t.status === 'OEFFENTLICH' ? 'öffentlich' : t.status === 'BEENDET' ? 'beendet' : 'Entwurf'}
              </span>
            </button>

            {detail === t.id && (
              <div className="px-5 pb-5 space-y-3 border-t border-white/10 pt-4">
                {kosten && kosten.art !== 'KEINE' && (
                  <p className="text-[11px] text-stone-400">
                    {kosten.vereine} zugesagte Vereine · {kosten.personen} Personen ·
                    {' '}<span className="text-white font-bold">
                      {Number(kosten.summe).toLocaleString('de-CH', { minimumFractionDigits: 2 })} {kosten.waehrung}
                    </span>
                  </p>
                )}
                {teilnehmer.length === 0 && (
                  <p className="text-[11px] text-stone-500">Noch keine Teilnehmer eingetragen.</p>
                )}
                {teilnehmer.map(te => (
                  <div key={te.id} className="flex items-center justify-between gap-3 flex-wrap
                                              py-2 border-b border-white/5 last:border-0">
                    <div className="min-w-0">
                      <p className="text-sm text-white truncate">
                        {te.name || te.tenantId}
                        <span className="text-[10px] uppercase tracking-widest text-stone-500 ml-2">
                          {te.art === 'VEREIN' ? 'Verein' : te.art === 'GASTVEREIN' ? 'Gastverein' : 'Gast'}
                        </span>
                      </p>
                      <p className="text-[11px] text-stone-500">
                        {te.zugesagt === true ? `zugesagt · ${te.personen} Personen`
                          : te.zugesagt === false ? 'abgesagt' : 'noch keine Antwort'}
                        {te.bemerkung ? ` · ${te.bemerkung}` : ''}
                      </p>
                    </div>
                    {te.art === 'GASTVEREIN' && (
                      <div className="flex items-center gap-3 shrink-0">
                        {te.token_hash ? (
                          <button onClick={() => linkWiderrufen(te)} disabled={arbeitet}
                            className="text-[10px] font-bold uppercase tracking-widest text-stone-400 hover:text-red-400">
                            Link widerrufen
                          </button>
                        ) : (
                          <button onClick={() => linkAusstellen(te)} disabled={arbeitet}
                            className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest
                                       text-stone-300 hover:text-white">
                            <Link2 size={12} /> Link ausstellen
                          </button>
                        )}
                      </div>
                    )}
                  </div>
                ))}

                {/* Was am Tag und danach gebraucht wird: Essenszahlen,
                    Namensschilder, Verschieben, Abrechnen, Vorstellungs-Links. */}
                <div className="pt-4 border-t border-white/10">
                  <TreffenWerkzeuge treffenId={t.id} teilnehmer={teilnehmer}
                    neuLaden={() => detailLaden(t.id)} />
                </div>

                {/* Der Link genau einmal. In der Datenbank liegt nur sein
                    Hash -- wer ihn jetzt nicht kopiert, stellt einen neuen aus. */}
                {frischerLink && (
                  <div className="bg-black/40 rounded-xl p-4 space-y-2">
                    <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                      Dieser Link wird nur jetzt angezeigt
                    </p>
                    <p className="font-mono text-[11px] text-stone-200 break-all">{frischerLink.url}</p>
                    <button onClick={() => {
                        navigator.clipboard?.writeText(frischerLink.url);
                        setKopiert(true); setTimeout(() => setKopiert(false), 2500);
                      }}
                      className="flex items-center gap-1.5 bg-white text-stone-900 px-3 py-1.5 rounded-lg
                                 text-[10px] font-bold uppercase tracking-widest">
                      {kopiert ? <Check size={12} /> : <Copy size={12} />} {kopiert ? 'Kopiert' : 'Kopieren'}
                    </button>
                  </div>
                )}
              </div>
            )}
            </div>
          ))}
        </div>
      )}
    </div>
  );

  // -------------------------------------------------------------- Assistent
  const mangel = fehltImSchritt();
  return (
    <div className="space-y-6">
      {/* Der Weg, sichtbar. Wer im dritten Schritt steht, soll sehen, dass
          zwei hinter ihm liegen und zwei vor ihm. */}
      <div className="flex items-center gap-1 flex-wrap">
        {SCHRITTE.map((s, i) => {
          const Symbol = s.symbol;
          const aktiv = s.nr === schritt, erledigt = s.nr < schritt;
          return (
            <React.Fragment key={s.nr}>
              <button onClick={() => s.nr < schritt && setSchritt(s.nr)}
                className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[11px] font-bold
                  ${aktiv ? 'bg-white text-stone-900'
                    : erledigt ? 'text-emerald-400 hover:bg-white/10' : 'text-stone-500'}`}>
                {erledigt ? <Check size={13} /> : <Symbol size={13} />} {s.titel}
              </button>
              {i < SCHRITTE.length - 1 && <ChevronRight size={13} className="text-stone-600 shrink-0" />}
            </React.Fragment>
          );
        })}
      </div>

      <div className="bg-white text-stone-900 rounded-[2rem] p-7 space-y-5">
        {schritt === 1 && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {feld('Titel', <input className={eingabe} value={e.titel}
              onChange={x => setzen({ titel: x.target.value })}
              placeholder="z. B. Turniertag der Diasporavereine" />, true)}
            {feld('Beschreibung', <textarea className={eingabe} rows={3} value={e.beschreibung}
              onChange={x => setzen({ beschreibung: x.target.value })} />, true)}
            {feld('Datum', <input type="date" className={eingabe} value={e.datum}
              onChange={x => setzen({ datum: x.target.value })} />)}
            {feld('Ende (wenn mehrtägig)', <input type="date" className={eingabe} value={e.ende}
              onChange={x => setzen({ ende: x.target.value })} />)}
            {feld('Beginn', <input type="time" className={eingabe} value={e.beginn}
              onChange={x => setzen({ beginn: x.target.value })} />)}
            {feld('Ort', <input className={eingabe} value={e.ort}
              onChange={x => setzen({ ort: x.target.value })} placeholder="Zwillikon" />)}
            {feld('Adresse', <input className={eingabe} value={e.adresse}
              onChange={x => setzen({ adresse: x.target.value })} />, true)}
          </div>
        )}

        {schritt === 2 && (
          <div className="space-y-5">
            <p className="text-sm text-stone-500 leading-relaxed max-w-2xl">
              „50 Franken“ beantwortet die Frage nicht, solange unklar ist, ob sie je Verein
              oder je Person gelten. Darum beides.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {([
                { w: 'KEINE', t: 'Kostenlos', u: 'Niemand zahlt etwas.' },
                { w: 'PRO_VEREIN', t: 'Pro Verein', u: 'Ein Beitrag je teilnehmendem Verein, unabhängig von der Anzahl Personen.' },
                { w: 'PRO_KOPF', t: 'Pro Person', u: 'Ein Beitrag je angemeldeter Person.' },
              ] as const).map(o => (
                <button key={o.w} type="button" onClick={() => setzen({ preis_art: o.w })}
                  className={`text-left p-4 rounded-2xl border transition-all ${
                    e.preis_art === o.w ? 'bg-stone-50 border-stone-900' : 'border-stone-200 hover:border-stone-400'}`}>
                  <p className="font-bold text-sm mb-1">{o.t}</p>
                  <p className="text-[11px] text-stone-500 leading-relaxed">{o.u}</p>
                </button>
              ))}
            </div>
            {e.preis_art !== 'KEINE' && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {feld('Betrag', <input type="number" step="0.05" min="0" className={eingabe}
                  value={e.preis_betrag} onChange={x => setzen({ preis_betrag: x.target.value })} />)}
                {feld('Währung', <select className={eingabe} value={e.waehrung}
                  onChange={x => setzen({ waehrung: x.target.value })}>
                  <option>CHF</option><option>EUR</option></select>)}
                {feld('Anmeldeschluss', <input type="date" className={eingabe}
                  value={e.anmeldeschluss} onChange={x => setzen({ anmeldeschluss: x.target.value })} />)}
              </div>
            )}
          </div>
        )}

        {schritt === 3 && (
          <div className="space-y-6">
            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">
                Vereine der Plattform
              </p>
              {vereine.length === 0 ? (
                <p className="text-sm text-stone-400">Keine Vereine vorhanden.</p>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {vereine.map(v => (
                    <label key={v.id}
                      className="flex items-center gap-3 p-3 rounded-xl border border-stone-200 cursor-pointer hover:border-stone-400">
                      <input type="checkbox" checked={gewaehlteVereine.includes(v.id)}
                        onChange={() => setGewaehlteVereine(a =>
                          a.includes(v.id) ? a.filter(x => x !== v.id) : [...a, v.id])} />
                      <span className="text-sm">{v.name || v.id}</span>
                    </label>
                  ))}
                </div>
              )}
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                  Gastvereine und Gäste
                </p>
                <div className="flex gap-2">
                  <button type="button" onClick={() => setGaeste(a => [...a,
                    { art: 'GASTVEREIN', name: '', kontakt_name: '', kontakt_email: '' }])}
                    className="text-[10px] font-bold uppercase tracking-widest text-stone-500 hover:text-stone-900">
                    + Gastverein
                  </button>
                  <button type="button" onClick={() => setGaeste(a => [...a,
                    { art: 'GAST', name: '', kontakt_name: '', kontakt_email: '' }])}
                    className="text-[10px] font-bold uppercase tracking-widest text-stone-500 hover:text-stone-900">
                    + Gast
                  </button>
                </div>
              </div>
              {gaeste.length === 0 ? (
                <p className="text-[11px] text-stone-400">
                  Gastvereine sind Vereine ohne Zugang zur Plattform; sie bekommen später einen Link.
                  Gäste sind einzelne Personen — Redner, Behörden, Sponsoren.
                </p>
              ) : (
                <div className="space-y-2">
                  {gaeste.map((g, i) => (
                    <div key={i} className="grid grid-cols-1 md:grid-cols-[7rem_1fr_1fr_1fr_2rem] gap-2 items-center">
                      <span className="text-[10px] font-bold uppercase tracking-widest text-stone-400">
                        {g.art === 'GASTVEREIN' ? 'Gastverein' : 'Gast'}
                      </span>
                      <input className={eingabe} placeholder="Name" value={g.name}
                        onChange={x => setGaeste(a => a.map((y, j) => j === i ? { ...y, name: x.target.value } : y))} />
                      <input className={eingabe} placeholder="Ansprechperson" value={g.kontakt_name}
                        onChange={x => setGaeste(a => a.map((y, j) => j === i ? { ...y, kontakt_name: x.target.value } : y))} />
                      <input className={eingabe} placeholder="E-Mail" value={g.kontakt_email}
                        onChange={x => setGaeste(a => a.map((y, j) => j === i ? { ...y, kontakt_email: x.target.value } : y))} />
                      <button type="button" onClick={() => setGaeste(a => a.filter((_, j) => j !== i))}
                        className="text-stone-300 hover:text-red-500"><Trash2 size={15} /></button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {schritt === 4 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <p className="text-sm text-stone-500 max-w-2xl leading-relaxed">
                Parallele Spuren bekommen verschiedene Namen — „Feld A“ und „Saal“, nicht 1 und 2.
                Veröffentlicht wird das Programm erst, wenn Sie es später freigeben.
              </p>
              <button type="button" onClick={() => setProgramm(a => [...a,
                LEERER_PUNKT])}
                className="shrink-0 text-[10px] font-bold uppercase tracking-widest text-stone-500 hover:text-stone-900">
                + Punkt
              </button>
              <button type="button" onClick={() => setProgramm(a => [...a,
                { ...LEERER_PUNKT, art: 'AUSFLUG', spur: 'Ausflug', anreise: 'Bus' }])}
                className="shrink-0 text-[10px] font-bold uppercase tracking-widest text-stone-500 hover:text-stone-900">
                + Ausflug
              </button>
            </div>
            {programm.length === 0 ? (
              <p className="text-[11px] text-stone-400">Noch kein Programmpunkt. Das lässt sich auch später ergänzen.</p>
            ) : (
              <div className="space-y-2">
                {programm.map((p, i) => (
                  <div key={i} className="grid grid-cols-2 md:grid-cols-[5rem_4rem_1fr_1fr_6rem_6rem_2rem] gap-2 items-center">
                    <input type="time" className={eingabe} value={p.beginn}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, beginn: x.target.value } : y))} />
                    <input type="number" className={eingabe} placeholder="Min" value={p.dauer_min}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, dauer_min: x.target.value } : y))} />
                    <input className={eingabe} placeholder="Was" value={p.titel}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, titel: x.target.value } : y))} />
                    <input className={eingabe} placeholder="Wo" value={p.ort}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, ort: x.target.value } : y))} />
                    <input className={eingabe} placeholder="Spur" value={p.spur}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, spur: x.target.value } : y))} />
                    <select className={eingabe} value={p.fuer}
                      onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, fuer: x.target.value as any } : y))}>
                      <option value="ALLE">Alle</option><option value="VERTRETER">Vertreter</option>
                    </select>
                    <button type="button" onClick={() => setProgramm(a => a.filter((_, j) => j !== i))}
                      className="text-stone-300 hover:text-red-500"><Trash2 size={15} /></button>

                    {/* Nur bei Ausfluegen: Ziel, Treffpunkt, Anreise, Rueckkehr,
                        Plaetze, Kosten. Ein gewoehnlicher Punkt braucht davon
                        nichts, und leere Felder sind kein Angebot. */}
                    {p.art === 'AUSFLUG' && (
                      <div className="col-span-2 md:col-span-7 grid grid-cols-2 md:grid-cols-6 gap-2 -mt-1 mb-1">
                        <input className={eingabe} placeholder="Ziel" value={p.ziel}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, ziel: x.target.value } : y))} />
                        <input className={eingabe} placeholder="Treffpunkt" value={p.treffpunkt}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, treffpunkt: x.target.value } : y))} />
                        <input className={eingabe} placeholder="Anreise" value={p.anreise}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, anreise: x.target.value } : y))} />
                        <input type="time" className={eingabe} value={p.rueckkehr}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, rueckkehr: x.target.value } : y))} />
                        <input type="number" className={eingabe} placeholder="Plätze" value={p.plaetze}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, plaetze: x.target.value } : y))} />
                        <input type="number" step="0.05" className={eingabe} placeholder="CHF" value={p.kosten}
                          onChange={x => setProgramm(a => a.map((y, j) => j === i ? { ...y, kosten: x.target.value } : y))} />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {schritt === 5 && (
          <div className="space-y-4">
            <h4 className="font-bold text-lg">{e.titel || '(ohne Titel)'}</h4>
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2 text-sm">
              <div className="flex justify-between border-b border-stone-100 py-1">
                <dt className="text-stone-400">Wann</dt>
                <dd>{e.datum ? new Date(e.datum).toLocaleDateString('de-CH') : '—'}
                  {e.ende && e.ende !== e.datum ? ` – ${new Date(e.ende).toLocaleDateString('de-CH')}` : ''}
                  {e.beginn ? `, ${e.beginn}` : ''}</dd>
              </div>
              <div className="flex justify-between border-b border-stone-100 py-1">
                <dt className="text-stone-400">Wo</dt><dd>{e.ort || '—'}</dd>
              </div>
              <div className="flex justify-between border-b border-stone-100 py-1">
                <dt className="text-stone-400">Beitrag</dt>
                <dd>{e.preis_art === 'KEINE' ? 'kostenlos'
                  : `${geld(e.preis_betrag)} ${e.waehrung} ${e.preis_art === 'PRO_KOPF' ? 'pro Person' : 'pro Verein'}`}</dd>
              </div>
              <div className="flex justify-between border-b border-stone-100 py-1">
                <dt className="text-stone-400">Teilnehmer</dt>
                <dd>{gewaehlteVereine.length} Vereine
                  {gaeste.filter(g => g.name.trim()).length ? `, ${gaeste.filter(g => g.name.trim()).length} weitere` : ''}</dd>
              </div>
              <div className="flex justify-between border-b border-stone-100 py-1">
                <dt className="text-stone-400">Programm</dt>
                <dd>{programm.filter(p => p.titel.trim()).length} Punkte</dd>
              </div>
            </dl>
            <p className="text-[11px] text-stone-400 leading-relaxed max-w-2xl">
              Als Entwurf sieht es niemand ausser Ihnen. Öffentlich erscheint es auf unityhub.li —
              das Programm allerdings erst, wenn Sie die einzelnen Punkte freigeben.
            </p>
          </div>
        )}

        {fehler && <p className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl p-3">{fehler}</p>}
        {mangel && <p className="text-xs text-amber-700">{mangel}</p>}
      </div>

      <div className="flex items-center justify-between gap-3">
        <button onClick={() => schritt === 1 ? (setOffen(false), setSchritt(1)) : setSchritt(s => s - 1)}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-[11px] font-bold
                     uppercase tracking-widest text-stone-400 hover:text-white">
          <ChevronLeft size={14} /> {schritt === 1 ? 'Abbrechen' : 'Zurück'}
        </button>
        {schritt < 5 ? (
          <button onClick={() => !mangel && setSchritt(s => s + 1)} disabled={!!mangel}
            className="flex items-center gap-2 bg-white text-stone-900 px-5 py-2.5 rounded-xl
                       text-[11px] font-bold uppercase tracking-widest disabled:opacity-40">
            Weiter <ChevronRight size={14} />
          </button>
        ) : (
          <div className="flex gap-2">
            <button onClick={() => anlegen('ENTWURF')} disabled={arbeitet}
              className="px-5 py-2.5 rounded-xl text-[11px] font-bold uppercase tracking-widest
                         border border-white/20 text-stone-300 hover:text-white disabled:opacity-40">
              Als Entwurf
            </button>
            <button onClick={() => anlegen('OEFFENTLICH')} disabled={arbeitet}
              className="flex items-center gap-2 bg-white text-stone-900 px-5 py-2.5 rounded-xl
                         text-[11px] font-bold uppercase tracking-widest disabled:opacity-40">
              {arbeitet ? <Loader2 size={14} className="animate-spin" /> : <Check size={14} />}
              Anlegen und veröffentlichen
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default SuperAdminTreffen;
