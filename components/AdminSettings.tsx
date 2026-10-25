
import React, { useState, useEffect } from 'react';
import AdminPostausgang from './AdminPostausgang';
import AdminTexte from './AdminTexte';
import AdminRollenverwaltung from './AdminRollenverwaltung';
import AdminUebergabe from './AdminUebergabe';
import AenderungsProtokoll from './AenderungsProtokoll';
import AdminFloky from './AdminFloky';
import AdminVereinsjahr from './AdminVereinsjahr';
import { Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';
import { motion } from 'framer-motion';
import { ArrowRight, Banknote, Eye, Gauge, Globe, Heart, LayoutTemplate, Loader2, Mail, Power, Save, Server, Settings, Shield, Sparkles, ToggleLeft, ToggleRight, Users } from 'lucide-react';
import { db } from '../services/datenzugriff';
import { doc, onSnapshot, setDoc, serverTimestamp, supabase } from '@/services/supabase-bridge';
import { SystemSettings, GlobalPaymentSettings } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { useModule } from '../lib/useModule';
import { VollMarke } from './PaketSperre';

const AdminSettings: React.FC = () => {
  const { t } = useTranslation();
  const { showAlert } = useFeedback();
  const [loading, setLoading] = useState(false);
  // Was oeffentlich ueber die Beitraege steht. Die Stellung liegt in
  // settings/system; entschieden wird sie aber in der Datenbank, nicht hier
  // -- beitragsstand_oeffentlich() liest sie selbst, sonst koennte jeder die
  // Sicht direkt abfragen und den Schalter umgehen.
  const [vorschau, setVorschau] = useState<any>(null);
  const [widersprueche, setWidersprueche] = useState(0);
  const { aktiv: modulAktiv, gesperrt: modulGesperrt } = useModule();
  
  // System Settings
  const [settings, setSettings] = useState<SystemSettings>({
    maintenanceMode: false,
    allowRegistration: true,
    modules: {
      villageLive: true,
      events: true,
      news: true
    },
    // Leer, nicht Koretini: das Feld wird mit handleSave geschrieben, ein
    // anderer Verein haette sonst Koretinis Absenderadresse uebernommen,
    // ohne je etwas eingetippt zu haben.
    systemEmail: '',
    beitraegeOeffentlich: 'AUS',
    // Vorgaben wie in mail_grenze_heute(). Sie hier zu verschweigen
    // hiesse, dass die Maske leere Felder zeigt, wo eine Grenze gilt.
    mailGrenzeVorstandTag: 150,
    mailGrenzePersonTag: 60,
    startseiteVariante: 'STANDARD',
    spendenseite: 'IMMER'
  });

  // Payment Settings (for Fee Structure)
  const [paymentSettings, setPaymentSettings] = useState<GlobalPaymentSettings>({
      iban: '', bankName: '', bic: '', accountHolder: '', street: '', zip: '', city: '', country: '', paypalEmail: '', currency: 'CHF', annualFeeAmount: 100,
      fees: {
          STANDARD: { amount: 120, currency: 'CHF', label: t('admin.members.billing.standard') },
          KOSOVO: { amount: 12, currency: 'EUR', label: t('admin.members.billing.kosovo') },
          REDUCED: { amount: 100, currency: 'EUR', label: t('admin.members.billing.reduced') }
      }
  });

  useEffect(() => {
    const unsubSystem = onSnapshot(doc(db, 'settings', 'system'), (snap) => {
      if (snap.exists()) {
        const data = snap.data() as SystemSettings;
        setSettings(prev => ({
            ...prev,
            ...data,
            modules: { ...prev.modules, ...(data.modules || {}) }
        }));
      }
    });

    const unsubPayment = onSnapshot(doc(db, 'settings', 'payment'), (snap) => {
        if(snap.exists()) {
            const data = snap.data() as GlobalPaymentSettings;
            setPaymentSettings(prev => ({
                ...prev,
                ...data,
                fees: {
                    STANDARD: { amount: 120, currency: 'CHF', label: t('admin.members.billing.standard'), ...data.fees?.STANDARD },
                    KOSOVO: { amount: 12, currency: 'EUR', label: t('admin.members.billing.kosovo'), ...data.fees?.KOSOVO },
                    REDUCED: { amount: 100, currency: 'EUR', label: t('admin.members.billing.reduced'), ...data.fees?.REDUCED },
                }
            }));
        }
    });

    return () => { unsubSystem(); unsubPayment(); };
  }, []);

  useEffect(() => {
    (async () => {
      const [{ data: stand }, { data: wid }] = await Promise.all([
        supabase.rpc('beitragsstand_oeffentlich'),
        supabase.rpc('widersprueche_zaehlen'),
      ]);
      setVorschau(stand);
      setWidersprueche(typeof wid === 'number' ? wid : 0);
    })();
  }, [settings.beitraegeOeffentlich, loading]);

  const handleSave = async () => {
    setLoading(true);
    try {
      await setDoc(doc(db, 'settings', 'system'), {
          ...settings,
          updatedAt: serverTimestamp()
      }, { merge: true });

      await setDoc(doc(db, 'settings', 'payment'), paymentSettings, { merge: true });
      
      showAlert({ type: 'success', message: t('set.saved') });
    } catch (err) {
      console.error(err);
      showAlert({ type: 'error', message: t('set.save_failed') });
    } finally {
      setLoading(false);
    }
  };

  const Toggle = ({ checked, onChange, label, description }: { checked: boolean, onChange: (val: boolean) => void, label: string, description?: string }) => (
    <div className="flex items-center justify-between p-4 bg-white rounded-2xl border border-stone-100 shadow-sm">
        <div className="flex items-center gap-4">
            <div onClick={() => onChange(!checked)} className={`cursor-pointer transition-colors ${checked ? 'text-primary' : 'text-stone-300'}`}>
                {checked ? <ToggleRight size={40} /> : <ToggleLeft size={40} />}
            </div>
            <div>
                <p className="font-bold text-stone-900 text-sm">{label}</p>
                {description && <p className="text-xs text-stone-400">{description}</p>}
            </div>
        </div>
        <div className={`w-3 h-3 rounded-full ${checked ? 'bg-green-500 animate-pulse' : 'bg-stone-200'}`} />
    </div>
  );

  return (
    <div className="max-w-5xl mx-auto space-y-8 min-h-[600px] p-2">
        {/* Header */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div>
                <h2 className="text-3xl font-display font-bold italic mb-2">{t('set.title')}</h2>
                <p className="text-stone-500">{t('set.subtitle')}</p>
            </div>
            
            <div className={`px-6 py-3 rounded-2xl border flex items-center gap-3 ${settings.maintenanceMode ? 'bg-amber-50 border-amber-200 text-amber-700' : 'bg-green-50 border-green-200 text-green-700'}`}>
                <Server size={20} />
                <div>
                    <p className="text-xs font-bold uppercase tracking-widest">{t('set.status')}</p>
                    <p className="font-bold">{settings.maintenanceMode ? 'MAINTENANCE MODE' : 'OPERATIONAL'}</p>
                </div>
                <div className={`w-3 h-3 rounded-full ml-2 ${settings.maintenanceMode ? 'bg-amber-500' : 'bg-green-500'} animate-pulse`} />
            </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            
            {/* Access Control */}
            <section className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <Shield size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.access')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <Toggle 
                        label={t('set.maintenance')} 
                        description="Only admins can access the dashboard."
                        checked={settings.maintenanceMode} 
                        onChange={v => setSettings({...settings, maintenanceMode: v})} 
                    />
                    <Toggle 
                        label={t('set.allow_registration')} 
                        description="New users can sign up via the wizard."
                        checked={settings.allowRegistration} 
                        onChange={v => setSettings({...settings, allowRegistration: v})} 
                    />
                </div>
            </section>

            {/* Wann die Spendenseite erscheint.
                Drei Stellungen statt ein/aus, weil eine allgemeine Spende
                ohne Aufruf sinnvoll bleibt -- bis heute war das der
                Normalfall. */}
            {/* Die Tagesgrenze des Vorstandspostausgangs.
                Steht hier und nicht in der Vorstandsmaske: wer eine
                Grenze setzen darf, ist nicht derselbe, fuer den sie
                gilt. */}
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Gauge size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('mgrenze.titel')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <p className="text-xs text-stone-500 leading-relaxed max-w-2xl">{t('mgrenze.hinweis')}</p>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">
                                {t('mgrenze.verein')}
                            </label>
                            <input type="number" min="0" max="400"
                                value={settings.mailGrenzeVorstandTag ?? 150}
                                onChange={e => setSettings({ ...settings, mailGrenzeVorstandTag: Number(e.target.value) })}
                                className="w-32 p-3 bg-white border border-stone-200 rounded-xl text-sm font-mono font-bold outline-none focus:border-stone-400" />
                            <p className="text-[11px] text-stone-400 mt-1">{t('mgrenze.verein_hinweis')}</p>
                        </div>
                        <div>
                            <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">
                                {t('mgrenze.person')}
                            </label>
                            <input type="number" min="0" max="400"
                                value={settings.mailGrenzePersonTag ?? 60}
                                onChange={e => setSettings({ ...settings, mailGrenzePersonTag: Number(e.target.value) })}
                                className="w-32 p-3 bg-white border border-stone-200 rounded-xl text-sm font-mono font-bold outline-none focus:border-stone-400" />
                            <p className="text-[11px] text-stone-400 mt-1">{t('mgrenze.person_hinweis')}</p>
                        </div>
                    </div>
                    {/* Die Decke des Betreibers. Sie steht hier, damit
                        niemand eine Zahl eintippt, die still gekappt wird. */}
                    <p className="text-[11px] text-stone-400 leading-relaxed border-t border-stone-200 pt-3">
                        {t('mgrenze.decke')}
                    </p>
                </div>
            </section>

            {/* Nicht gebucht: ausgegraut statt verschwunden (Paket Light). */}
            {modulGesperrt('SPENDEN') && (
            <section className="opacity-50">
                <div className="flex items-center gap-2 mb-4">
                    <Heart size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('spseite.titel')}</h3>
                    <VollMarke />
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-dashed border-stone-200 text-sm text-stone-500">
                    Spendenseite, Spendenaufrufe und Spendenbescheinigungen sind im Paket Voll enthalten.
                </div>
            </section>
            )}

            {modulAktiv('SPENDEN') && !modulGesperrt('SPENDEN') && (
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Heart size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('spseite.titel')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        {([
                            { wert: 'IMMER',      titel: t('spseite.immer'),   text: t('spseite.immer_text') },
                            { wert: 'BEI_AUFRUF', titel: t('spseite.aufruf'),  text: t('spseite.aufruf_text') },
                            { wert: 'AUS',        titel: t('spseite.aus'),     text: t('spseite.aus_text') },
                        ]).map(o => {
                            const gewaehlt = (settings.spendenseite || 'IMMER') === o.wert;
                            return (
                                <button key={o.wert} type="button"
                                    onClick={() => setSettings({ ...settings, spendenseite: o.wert as SystemSettings['spendenseite'] })}
                                    className={`text-left p-5 rounded-2xl border transition-all ${gewaehlt
                                        ? 'bg-white border-primary shadow-sm'
                                        : 'bg-white/60 border-stone-200 hover:border-stone-300'}`}>
                                    <p className={`font-bold text-sm mb-1 ${gewaehlt ? 'text-primary' : 'text-stone-900'}`}>{o.titel}</p>
                                    <p className="text-[11px] text-stone-500 leading-relaxed">{o.text}</p>
                                </button>
                            );
                        })}
                    </div>
                    <p className="text-[11px] text-stone-400 leading-relaxed">{t('spseite.hinweis')}</p>
                </div>
            </section>
            )}

            {/* Die Auswahl der Startseite ist umgezogen.
                Sie stand hier, solange es eine Umschaltung war (Standard
                oder Premium). Mit sechs Vorlagen ist es eine Auswahl, und
                die gehoert dorthin, wo ein Verein seine Website macht.

                Hier bleibt ein Wegweiser statt nichts: wer den Schalter
                einmal hier gefunden hat, sucht ihn beim naechsten Mal
                wieder hier. Ein zweiter Auswahlknopf waere schlimmer --
                er schriebe einen Schluessel, den niemand mehr liest. */}
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Sparkles size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('prem.titel')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100">
                    <p className="text-sm text-stone-600 leading-relaxed mb-4">{t('prem.umgezogen')}</p>
                    <Link to="/admin?tab=WEBSITE"
                        className="inline-flex items-center gap-2 text-[11px] font-bold uppercase tracking-widest text-primary hover:underline">
                        {t('prem.zur_website')} <ArrowRight size={13} />
                    </Link>
                </div>
            </section>

            {/* Was die Website ueber die Beitraege sagt.
                Drei Stellungen statt ein/aus, weil zwischen "nichts" und
                "Namensliste" ein Schritt liegt, der oft der richtige ist: die
                blosse Zahl zeigt den Rueckhalt des Vereins, ohne dass
                jemand durch Abwesenheit als saeumig dasteht. */}
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Eye size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('oeff.titel')}</h3>
                </div>

                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
                    <p className="text-xs text-stone-500 leading-relaxed max-w-2xl">{t('oeff.hinweis')}</p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        {([
                            { wert: 'AUS',      titel: t('oeff.aus'),      text: t('oeff.aus_text') },
                            { wert: 'ZAHL',     titel: t('oeff.zahl'),     text: t('oeff.zahl_text') },
                            { wert: 'NAMEN',    titel: t('oeff.namen'),    text: t('oeff.namen_text') },
                            { wert: 'BETRAEGE', titel: t('oeff.betraege'), text: t('oeff.betraege_text') },
                        ]).map(o => {
                            const aktiv = (settings.beitraegeOeffentlich || 'AUS') === o.wert;
                            return (
                                <button key={o.wert} type="button"
                                    onClick={() => setSettings({ ...settings, beitraegeOeffentlich: o.wert as SystemSettings['beitraegeOeffentlich'] })}
                                    className={`text-left p-5 rounded-2xl border transition-all ${aktiv
                                        ? 'bg-white border-primary shadow-sm'
                                        : 'bg-white/60 border-stone-200 hover:border-stone-300'}`}>
                                    <p className={`font-bold text-sm mb-1 ${aktiv ? 'text-primary' : 'text-stone-900'}`}>{o.titel}</p>
                                    <p className="text-[11px] text-stone-500 leading-relaxed">{o.text}</p>
                                </button>
                            );
                        })}
                    </div>

                    {/* Die Vorschau kommt aus derselben Funktion, die auch die
                        Website aufruft -- was hier steht, steht dort. */}
                    <div className="bg-white rounded-2xl border border-stone-100 p-5">
                        <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-3">{t('oeff.vorschau')}</p>
                        {!vorschau || vorschau.stellung === 'AUS' ? (
                            <p className="text-sm text-stone-400 italic">{t('oeff.vorschau_nichts')}</p>
                        ) : vorschau.stellung === 'ZAHL' ? (
                            <p className="text-sm text-stone-800">
                                <strong>{vorschau.anzahl}</strong> {t('oeff.vorschau_zahl', { jahr: vorschau.jahr, gesamt: vorschau.gesamt })}
                            </p>
                        ) : vorschau.stellung === 'BETRAEGE' ? (
                            <div className="space-y-2">
                                <p className="text-sm text-stone-800">
                                    <strong>{(vorschau.zeilen || []).length}</strong>{' '}
                                    {t('oeff.vorschau_betraege', {
                                      jahr: vorschau.jahr,
                                      summe: `${vorschau.waehrung || 'CHF'} ${Number(vorschau.summe || 0).toLocaleString('de-CH', { minimumFractionDigits: 2 })}`,
                                    })}
                                </p>
                                {/* Die Vorschau zeigt BETRAEGE -- und genau das ist
                                    der Punkt: wer das einschaltet, soll vorher
                                    sehen, was draussen steht. */}
                                <div className="space-y-1">
                                    {(vorschau.zeilen || []).slice(0, 8).map((z: any, i: number) => (
                                        <div key={i} className="flex justify-between gap-3 text-xs">
                                            <span className="text-stone-700 truncate">{z.name}</span>
                                            <span className="font-mono text-stone-900 shrink-0">
                                                {vorschau.waehrung || 'CHF'} {Number(z.betrag || 0).toFixed(2)}
                                            </span>
                                        </div>
                                    ))}
                                    {(vorschau.zeilen || []).length > 8 && (
                                        <p className="text-[11px] text-stone-400">
                                            … {t('oeff.vorschau_weitere', { anzahl: (vorschau.zeilen || []).length - 8 })}
                                        </p>
                                    )}
                                </div>
                                <p className="text-[11px] text-amber-700 leading-relaxed pt-2">
                                    {t('oeff.betraege_warnung')}
                                </p>
                            </div>
                        ) : (
                            <div className="space-y-2">
                                <p className="text-sm text-stone-800">
                                    <strong>{(vorschau.namen || []).length}</strong> {t('oeff.vorschau_namen', { jahr: vorschau.jahr })}
                                </p>
                                <p className="text-xs text-stone-500 leading-relaxed">
                                    {(vorschau.namen || []).slice(0, 12).join(' · ')}
                                    {(vorschau.namen || []).length > 12 ? ' …' : ''}
                                </p>
                            </div>
                        )}
                        {vorschau && vorschau.stellung !== 'AUS' && (
                            <p className="text-[11px] text-stone-400 mt-3 flex items-center gap-1.5 pt-3 border-t border-stone-100">
                                <Users size={12} /> {t('oeff.widersprueche', { anzahl: widersprueche })}
                            </p>
                        )}
                        {(settings.beitraegeOeffentlich || 'AUS') !== (vorschau?.stellung || 'AUS') && (
                            <p className="text-[11px] text-amber-600 mt-3">{t('oeff.erst_speichern')}</p>
                        )}
                    </div>
                </div>
            </section>

            {/* Zahlerliste mit Statistik je Nachbarschaft -- eine eigene Seite
                (/beitraege). Ob oeffentlich oder nur fuer Mitglieder, prueft
                zahlerliste() in der Datenbank; ein Besucher bekommt bei
                "Nur Mitglieder" weder Zahl noch Namen. */}
            <section>
                <div className="flex items-center gap-2 mb-4">
                    <Users size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('zl.admin_titel')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 space-y-5">
                    <p className="text-xs text-stone-500 leading-relaxed max-w-2xl">{t('zl.admin_hinweis')}</p>
                    {(() => {
                        const zl = { sichtbar: 'AUS', inhalt: 'STATISTIK', nachbarschaften: true, ...((settings as any).zahlerliste || {}) };
                        const setz = (k: string, v: any) => setSettings({ ...settings, zahlerliste: { ...zl, [k]: v } } as any);
                        const knopf = (aktiv: boolean) => `text-left p-4 rounded-2xl border transition-all ${aktiv ? 'bg-white border-primary shadow-sm' : 'bg-white/60 border-stone-200 hover:border-stone-300'}`;
                        return (<>
                            <div>
                                <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('zl.wer')}</p>
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                                    {(['AUS', 'MITGLIEDER', 'OEFFENTLICH'] as const).map(w => (
                                        <button key={w} type="button" onClick={() => setz('sichtbar', w)} className={knopf(zl.sichtbar === w)}>
                                            <p className={`font-bold text-sm mb-1 ${zl.sichtbar === w ? 'text-primary' : 'text-stone-900'}`}>{t(`zl.wer_${w}`)}</p>
                                            <p className="text-[11px] text-stone-500 leading-relaxed">{t(`zl.wer_${w}_text`)}</p>
                                        </button>
                                    ))}
                                </div>
                            </div>
                            {zl.sichtbar !== 'AUS' && (<>
                                <div>
                                    <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2">{t('zl.inhalt')}</p>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                                        {(['STATISTIK', 'NAMEN'] as const).map(w => (
                                            <button key={w} type="button" onClick={() => setz('inhalt', w)} className={knopf(zl.inhalt === w)}>
                                                <p className={`font-bold text-sm mb-1 ${zl.inhalt === w ? 'text-primary' : 'text-stone-900'}`}>{t(`zl.inhalt_${w}`)}</p>
                                                <p className="text-[11px] text-stone-500 leading-relaxed">{t(`zl.inhalt_${w}_text`)}</p>
                                            </button>
                                        ))}
                                    </div>
                                </div>
                                <Toggle checked={!!zl.nachbarschaften} onChange={v => setz('nachbarschaften', v)}
                                    label={t('zl.nb_label')} description={t('zl.nb_text')} />
                                <p className="text-[11px] text-stone-500">
                                    {t('zl.seite')} <Link to="/beitraege" target="_blank" className="font-bold text-primary hover:underline">/beitraege</Link>
                                    {' · '}{t('zl.nav_hinweis')}
                                </p>
                            </>)}
                        </>);
                    })()}
                </div>
            </section>

            {/* Die frueheren Modulschalter sind entfallen.
                Gemessen: sie wurden gespeichert und an keiner einzigen Stelle
                ausgewertet -- "Events aus" liess die Seite erreichbar und die
                Daten ueber die Schnittstelle abrufbar. Ein Schalter, der nur
                die Oberflaeche verbirgt, ist schlimmer als keiner: er
                behauptet eine Wirkung, die es nicht gibt.
                Ersetzt durch den Marktplatz, dessen Schalter in den
                Zeilenregeln sitzt. */}
            <section className="space-y-4">
                <div className="flex items-center gap-2 mb-2">
                    <LayoutTemplate size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.modules')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100">
                    <p className="text-xs text-stone-500 leading-relaxed">{t('set.modules_verschoben')}</p>
                </div>
            </section>

            {/* FEE STRUCTURE */}
            <section className="space-y-4 md:col-span-2">
                <div className="flex items-center gap-2 mb-2">
                    <Banknote size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.fees')}</h3>
                </div>
                <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm grid grid-cols-1 md:grid-cols-3 gap-6">
                    {/* STANDARD */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-stone-200 text-stone-500 px-2 py-1 rounded">STANDARD</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_standard_desc')}</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.STANDARD.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, STANDARD: { ...paymentSettings.fees!.STANDARD, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.STANDARD.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, STANDARD: { ...paymentSettings.fees!.STANDARD, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>

                    {/* KOSOVO */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-blue-100 text-blue-600 px-2 py-1 rounded">{t('set.fee_resident')}</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_resident_desc')}</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.KOSOVO.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, KOSOVO: { ...paymentSettings.fees!.KOSOVO, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.KOSOVO.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, KOSOVO: { ...paymentSettings.fees!.KOSOVO, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>

                    {/* REDUCED */}
                    <div className="p-4 bg-stone-50 rounded-2xl border border-stone-200">
                        <div className="mb-2">
                            <span className="text-[10px] font-bold bg-amber-100 text-amber-600 px-2 py-1 rounded">{t('set.fee_reduced')}</span>
                        </div>
                        <p className="text-xs text-stone-400 mb-2">{t('set.fee_reduced_desc')}</p>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={paymentSettings.fees?.REDUCED.amount} 
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, REDUCED: { ...paymentSettings.fees!.REDUCED, amount: parseFloat(e.target.value) } } })} 
                                className="w-full p-2 rounded-lg border border-stone-200 font-bold"
                            />
                            <select 
                                value={paymentSettings.fees?.REDUCED.currency}
                                onChange={e => setPaymentSettings({...paymentSettings, fees: { ...paymentSettings.fees!, REDUCED: { ...paymentSettings.fees!.REDUCED, currency: e.target.value } } })}
                                className="p-2 rounded-lg border border-stone-200 text-xs font-bold"
                            >
                                <option value="CHF">CHF</option>
                                <option value="EUR">EUR</option>
                            </select>
                        </div>
                    </div>
                </div>
            </section>

            {/* Communication */}
            <section className="space-y-4 md:col-span-2">
                <div className="flex items-center gap-2 mb-2">
                    <Mail size={18} className="text-stone-400" />
                    <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">{t('set.communication')}</h3>
                </div>
                <div className="bg-stone-50 p-6 rounded-3xl border border-stone-100 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest mb-2 block">{t('set.reply_to')}</label>
                        <input 
                            type="email" 
                            value={settings.systemEmail} 
                            onChange={e => setSettings({...settings, systemEmail: e.target.value})}
                            className="w-full p-4 bg-white border border-stone-200 rounded-xl font-bold text-stone-700 outline-none focus:border-[color:color-mix(in_srgb,var(--primary)_50%,transparent)]"
                        />
                        <p className="text-xs text-stone-400 mt-2">{t('set.reply_to_hint')}</p>
                    </div>
                </div>

                {/* Der Postausgang. Hier stand ein Hinweis aus der
                    Firebase-Zeit -- "Trigger Email", "Firebase Console" --,
                    der seit der Umstellung auf Supabase nicht mehr zutraf und
                    hinter dem sich nichts einstellen liess. */}
                <AdminPostausgang />
            </section>

            {/* Textbausteine und Glossar. Sie gehoeren zur Kommunikation,
                nicht zu den Stammdaten: was an Mitglieder geht und wie die
                Vereinsbegriffe darin heissen. */}
            <section className="space-y-5 md:col-span-2">
                <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Texte und Begriffe</h3>
                <AdminTexte />
            </section>

            {/* Der Assistent. Steht bei den Einstellungen und nicht beim
                Marktplatz: hier geht es nicht um das Buchen, sondern darum,
                wie er im Verein heisst und wie er mit Mitgliedern spricht. */}
            <section className="space-y-5">
                <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Vereinsassistent</h3>
                <AdminFloky />
            </section>

            {/* Das Vereinsjahr. Steht neben dem Assistenten, weil er die
                Erinnerungen verschickt -- aber es ist eine Angabe ueber den
                Verein, nicht ueber Floky: wann seine GV ist, weiss er auch
                ohne Assistent. */}
            <section className="space-y-5 md:col-span-2">
                <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Vereinsjahr</h3>
                <AdminVereinsjahr />
            </section>

            {/* Wer im Verein aendern darf. Steht bewusst bei den
                Einstellungen und nicht bei den Mitgliedern: es ist eine
                Entscheidung ueber den Verein, nicht ueber eine Person. */}
            {/* Rollenverwaltung ueber die volle Breite: hier stehen eine
                Personenliste und zwei Rechtetafeln nebeneinander. */}
            <section className="space-y-5 md:col-span-2">
                <h3 className="text-xs font-bold uppercase tracking-widest text-stone-500">Rollenverwaltung</h3>
                <AdminRollenverwaltung />
                <AdminUebergabe />
                <AenderungsProtokoll limit={100} />
            </section>

        </div>

        <div className="pt-8 border-t border-stone-100 flex justify-end">
            <button 
                onClick={handleSave} 
                disabled={loading}
                className="bg-stone-900 text-white px-8 py-4 rounded-2xl font-bold flex items-center gap-3 shadow-xl hover:scale-105 transition-all disabled:opacity-50"
            >
                {loading ? <Loader2 className="animate-spin" /> : <Save size={20} />} Save Configuration
            </button>
        </div>
    </div>
  );
};

export default AdminSettings;
