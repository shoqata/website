import React, { useEffect, useState } from 'react';
import { UserPlus, Check, X, Loader2, KeyRound, Users, AlertTriangle } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import AdminPasswordReset from './AdminPasswordReset';

// Aufnahmeantraege: wer sich auf der Website registriert, landet hier.
//
// Zu jedem Antrag zeigt die Datenbank moegliche Treffer unter den
// bestehenden Mitgliedern (aufnahme_treffer: E-Mail, Telefon, Name,
// Nachbarschaft). Der Vorstand entscheidet: als bestehendes Mitglied
// uebernehmen, als neues aufnehmen oder ablehnen. Beim Freigeben entsteht
// gleich die Rechnung fuer das laufende Jahr; danach setzt er das Passwort.

type Antrag = {
  id: string; anrede: string | null; vorname: string; nachname: string; email: string;
  telefon: string | null; strasse: string | null; plz: string | null; ort: string | null;
  land: string | null; nachbarschaft: string | null; rechnungsweg: string; eingegangen_am: string;
};
type Treffer = {
  mitglied: string; name: string; email: string | null; telefon: string | null;
  nachbarschaft: string | null; status: string; hat_konto: boolean; punkte: number; gruende: string[];
};
type Ergebnis = {
  mitglied: string; name: string; email: string; rechnungsnummer: string | null;
  betrag: number | null; waehrung: string | null; rechnung_bestand_schon: boolean; hat_konto: boolean;
};

const GRUPPEN = [['STANDARD', 'aufn.gruppe_standard'], ['REDUCED', 'aufn.gruppe_reduziert'], ['KOSOVO', 'aufn.gruppe_kosovo']] as const;
const istKosovo = (land: string | null) => /kosov|kosov[eë]/i.test(land || '');

const AdminAufnahmen: React.FC = () => {
  const { t } = useTranslation();
  const [antraege, setAntraege] = useState<Antrag[] | null>(null);
  const [treffer, setTreffer] = useState<Record<string, Treffer[]>>({});
  const [nachbarschaften, setNachbarschaften] = useState<Record<string, string>>({});
  const [gruppe, setGruppe] = useState<Record<string, string>>({});
  const [arbeitet, setArbeitet] = useState<string | null>(null);
  const [fehler, setFehler] = useState<string | null>(null);
  const [ablehnen, setAblehnen] = useState<{ id: string; grund: string } | null>(null);
  const [erledigt, setErledigt] = useState<Ergebnis[]>([]);
  const [passwortFuer, setPasswortFuer] = useState<any>(null);

  const laden = async () => {
    const { data, error } = await supabase.from('aufnahmeantraege')
      .select('id, anrede, vorname, nachname, email, telefon, strasse, plz, ort, land, nachbarschaft, rechnungsweg, eingegangen_am')
      .eq('status', 'OFFEN').order('eingegangen_am', { ascending: false });
    if (error) { setAntraege([]); return; }
    const liste = (data as Antrag[]) || [];
    setAntraege(liste);
    setGruppe(g => Object.fromEntries(liste.map(a => [a.id, g[a.id] ?? (istKosovo(a.land) ? 'KOSOVO' : 'STANDARD')])));
    const paare = await Promise.all(liste.map(async a => {
      const { data: tr } = await supabase.rpc('aufnahme_treffer', { p_antrag: a.id });
      return [a.id, (tr as Treffer[]) || []] as const;
    }));
    setTreffer(Object.fromEntries(paare));
  };

  useEffect(() => {
    laden();
    supabase.from('neighborhoods').select('id, name').then(({ data }: any) =>
      setNachbarschaften(Object.fromEntries((data || []).map((n: any) => [n.id, n.name]))));
  }, []);

  const freigeben = async (a: Antrag, mitglied: string | null) => {
    setArbeitet(a.id + (mitglied ?? 'neu')); setFehler(null);
    const { data, error } = await supabase.rpc('aufnahme_freigeben',
      { p_antrag: a.id, p_mitglied: mitglied, p_gruppe: gruppe[a.id] || 'STANDARD' });
    setArbeitet(null);
    if (error) { setFehler(error.message); return; }
    setErledigt(e => [data as Ergebnis, ...e]);
    setAntraege(l => (l || []).filter(x => x.id !== a.id));
  };

  const ablehnenBestaetigen = async () => {
    if (!ablehnen) return;
    setArbeitet(ablehnen.id); setFehler(null);
    const { error } = await supabase.rpc('aufnahme_ablehnen', { p_antrag: ablehnen.id, p_grund: ablehnen.grund || null });
    setArbeitet(null);
    if (error) { setFehler(error.message); return; }
    setAntraege(l => (l || []).filter(x => x.id !== ablehnen.id));
    setAblehnen(null);
  };

  if (antraege === null) return null;
  if (antraege.length === 0 && erledigt.length === 0) return null;

  const knopf = 'px-3 py-2 rounded-xl text-xs font-bold inline-flex items-center gap-1.5 disabled:opacity-50';

  return (
    <section className="space-y-4 mb-8">
      <div className="flex items-center gap-3">
        <div className="bg-[color:color-mix(in_srgb,var(--primary)_12%,transparent)] text-primary p-2.5 rounded-xl"><UserPlus size={18} /></div>
        <div>
          <h3 className="font-bold text-stone-900">{t('aufn.titel')}</h3>
          <p className="text-xs text-stone-500">{t('aufn.untertitel')}</p>
        </div>
        {antraege.length > 0 && (
          <span className="ml-auto px-2.5 py-1 rounded-lg bg-amber-50 text-amber-700 text-xs font-bold tabular-nums">{antraege.length} {t('aufn.offen')}</span>
        )}
      </div>

      {fehler && <p className="p-3 rounded-xl bg-red-50 text-red-700 text-sm">{fehler}</p>}

      {/* Frisch freigegeben: naechster Schritt ist das Passwort. */}
      {erledigt.map(e => (
        <div key={e.mitglied} className="p-4 rounded-2xl bg-emerald-50 border border-emerald-100 flex flex-wrap items-center gap-3">
          <Check size={18} className="text-emerald-600 shrink-0" />
          <div className="min-w-0 flex-1 text-sm text-emerald-900">
            <p className="font-bold [overflow-wrap:anywhere]">{t('aufn.ist_mitglied', { name: e.name })}</p>
            <p className="text-xs text-emerald-800">
              {e.rechnung_bestand_schon
                ? t('aufn.rechnung_bestand', { nr: e.rechnungsnummer || '' })
                : t('aufn.rechnung_neu', { nr: e.rechnungsnummer || '', betrag: `${e.waehrung} ${Number(e.betrag).toFixed(2)}` })}
            </p>
          </div>
          <button onClick={() => setPasswortFuer({ id: e.mitglied, displayName: e.name, email: e.email })}
                  className={`${knopf} bg-stone-900 text-white`}>
            <KeyRound size={13} /> {e.hat_konto ? t('aufn.passwort_neu') : t('aufn.passwort_setzen')}
          </button>
        </div>
      ))}

      {antraege.map(a => {
        const tr = treffer[a.id] || [];
        const emailVergeben = tr.some(x => x.gruende.includes('E-Mail'));
        const adresse = [a.strasse, [a.plz, a.ort].filter(Boolean).join(' '), a.land].filter(Boolean).join(', ');
        return (
          <div key={a.id} className="bg-white rounded-2xl border border-stone-100 shadow-sm overflow-hidden">
            <div className="p-5 grid gap-4 md:grid-cols-2">
              <div className="min-w-0 space-y-1 text-sm">
                <p className="font-bold text-stone-900 text-base [overflow-wrap:anywhere]">{[a.anrede, a.vorname, a.nachname].filter(Boolean).join(' ')}</p>
                <p className="text-stone-600 [overflow-wrap:anywhere]">{a.email}{a.telefon ? ` · ${a.telefon}` : ''}</p>
                {adresse && <p className="text-stone-500 [overflow-wrap:anywhere]">{adresse}</p>}
                <p className="text-stone-500">
                  {a.nachbarschaft ? (nachbarschaften[a.nachbarschaft] || a.nachbarschaft) : t('aufn.keine_nachbarschaft')}
                  {' · '}{new Date(a.eingegangen_am).toLocaleDateString('de-CH')}
                </p>
              </div>

              <div className="min-w-0">
                <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2 flex items-center gap-1.5">
                  <Users size={12} /> {t('aufn.treffer')}
                </p>
                {tr.length === 0 ? (
                  <p className="text-sm text-stone-500">{t('aufn.kein_treffer')}</p>
                ) : (
                  <div className="space-y-2">
                    {tr.map(x => (
                      <div key={x.mitglied} className={`p-3 rounded-xl border text-sm ${x.punkte >= 50 ? 'border-amber-200 bg-amber-50/60' : 'border-stone-100 bg-stone-50'}`}>
                        <div className="flex items-start justify-between gap-2">
                          <div className="min-w-0">
                            <p className="font-bold text-stone-900 [overflow-wrap:anywhere]">
                              {x.name}
                              {x.status !== 'ACTIVE' && <span className="ml-2 text-[10px] font-bold uppercase text-stone-500">{t(`status.${x.status.toLowerCase()}`)}</span>}
                            </p>
                            <p className="text-xs text-stone-500 [overflow-wrap:anywhere]">
                              {[x.email, x.telefon, x.nachbarschaft].filter(Boolean).join(' · ')}
                            </p>
                            <p className="text-[11px] text-stone-600 mt-1">{t('aufn.gleich')}: {x.gruende.join(', ')}</p>
                          </div>
                          <button onClick={() => freigeben(a, x.mitglied)} disabled={!!arbeitet}
                                  className={`${knopf} bg-stone-900 text-white shrink-0`}>
                            {arbeitet === a.id + x.mitglied ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} />}
                            {t('aufn.uebernehmen')}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            <div className="px-5 py-3 bg-stone-50 border-t border-stone-100 flex flex-wrap items-center gap-2">
              <label className="text-xs text-stone-500 flex items-center gap-2">
                {t('aufn.beitrag')}
                <select value={gruppe[a.id] || 'STANDARD'} onChange={e => setGruppe(g => ({ ...g, [a.id]: e.target.value }))}
                        className="px-2 py-1.5 rounded-lg border border-stone-200 bg-white text-xs font-bold">
                  {GRUPPEN.map(([w, k]) => <option key={w} value={w}>{t(k)}</option>)}
                </select>
              </label>
              <div className="flex-1" />
              {ablehnen?.id === a.id ? (
                <>
                  <input value={ablehnen.grund} onChange={e => setAblehnen({ id: a.id, grund: e.target.value })}
                         placeholder={t('aufn.grund')} className="px-3 py-2 rounded-xl border border-stone-200 text-xs min-w-0 flex-1 md:flex-none md:w-56" />
                  <button onClick={ablehnenBestaetigen} disabled={!!arbeitet} className={`${knopf} bg-red-600 text-white`}>{t('aufn.ablehnen')}</button>
                  <button onClick={() => setAblehnen(null)} className={`${knopf} text-stone-500`}><X size={13} /></button>
                </>
              ) : (
                <>
                  <button onClick={() => setAblehnen({ id: a.id, grund: '' })} className={`${knopf} text-stone-500 hover:text-red-600`}>{t('aufn.ablehnen')}</button>
                  <button onClick={() => freigeben(a, null)} disabled={!!arbeitet || emailVergeben}
                          title={emailVergeben ? t('aufn.email_vergeben') : undefined}
                          className={`${knopf} bg-primary text-white`}>
                    {arbeitet === a.id + 'neu' ? <Loader2 size={13} className="animate-spin" /> : <UserPlus size={13} />}
                    {t('aufn.neu_aufnehmen')}
                  </button>
                </>
              )}
            </div>
            {emailVergeben && (
              <p className="px-5 pb-3 bg-stone-50 text-[11px] text-amber-700 flex items-center gap-1.5">
                <AlertTriangle size={12} /> {t('aufn.email_vergeben')}
              </p>
            )}
          </div>
        );
      })}

      {passwortFuer && <AdminPasswordReset member={passwortFuer} onClose={() => setPasswortFuer(null)} />}
    </section>
  );
};

export default AdminAufnahmen;
