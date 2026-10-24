import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, MapPin, Phone, Send, Check, Loader2, AlertTriangle, MessageSquare } from 'lucide-react';
import { supabase, doc, onSnapshot } from '@/services/supabase-bridge';
import { db } from '../services/datenzugriff';
import { useTranslation } from '../context/LanguageContext';

// Kontakt: die Angaben des Vereins und ein Formular.
//
// Was hier abgeschickt wird, landet als Anfrage beim Vorstand
// (Kommunikation -> Anfragen) und als Mail an die Kontaktadresse des
// Vereins. Die Pruefungen -- Pflichtfelder, Falle, Mindestzeit, Obergrenze
// -- macht kontakt_senden() in der Datenbank; die Maske hier prueft nur,
// damit niemand erst nach dem Absenden erfaehrt, dass die Adresse fehlt.

const KontaktSeite: React.FC = () => {
  const { t, loc } = useTranslation();
  const [marke, setMarke] = useState<any>({});
  const [offen, setOffen] = useState<boolean | null>(null);
  const [f, setF] = useState({ name: '', email: '', telefon: '', betreff: '', nachricht: '', falle: '' });
  const [zustimmung, setZustimmung] = useState(false);
  const [sendet, setSendet] = useState(false);
  const [fertig, setFertig] = useState(false);
  const [fehler, setFehler] = useState('');
  const geoeffnet = useRef(Date.now());

  useEffect(() => onSnapshot(doc(db, 'public_settings', 'branding'),
    (s: any) => { if (s.exists()) setMarke(s.data()); }), []);
  useEffect(() => {
    supabase.rpc('kontakt_offen').then(({ data }) => setOffen(data !== false), () => setOffen(true));
  }, []);

  const adresse = loc(marke.footerAddress);
  const email = loc(marke.footerEmail);
  const telefon = marke.kontaktTelefon || '';

  const senden = async (e: React.FormEvent) => {
    e.preventDefault();
    setFehler('');
    if (!f.name.trim() || !/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/i.test(f.email.trim()) || f.nachricht.trim().length < 10) {
      setFehler(t('kontakt.pflicht')); return;
    }
    if (!zustimmung) { setFehler(t('kontakt.zustimmung_fehlt')); return; }
    setSendet(true);
    const { error } = await supabase.rpc('kontakt_senden', {
      p_name: f.name, p_email: f.email, p_telefon: f.telefon, p_betreff: f.betreff,
      p_nachricht: f.nachricht, p_falle: f.falle, p_dauer_ms: Date.now() - geoeffnet.current,
    });
    setSendet(false);
    if (error) { setFehler(error.message); return; }
    setFertig(true);
  };

  const feld = 'w-full p-4 bg-white border border-stone-200 rounded-2xl text-sm outline-none focus:border-stone-400 transition-colors';
  const marken = 'text-[10px] font-bold uppercase tracking-widest text-stone-400 block mb-2';

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-24">
      <div className="max-w-6xl mx-auto px-6 grid grid-cols-1 lg:grid-cols-5 gap-12">
        <div className="lg:col-span-2">
          <div className="inline-flex items-center gap-2 bg-rose-50 text-primary px-4 py-2 rounded-full text-xs font-bold mb-6 uppercase tracking-widest">
            <MessageSquare size={14} /> {t('kontakt.badge')}
          </div>
          <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">
            {loc(marke.kontaktTitel) || t('kontakt.titel')}
          </h1>
          <p className="text-xl text-stone-500 leading-relaxed italic whitespace-pre-line">
            {loc(marke.kontaktIntro) || t('kontakt.intro')}
          </p>

          <div className="mt-10 space-y-4">
            {adresse && (
              <div className="flex items-start gap-4">
                <span className="w-11 h-11 rounded-2xl tupfer-primaer flex items-center justify-center shrink-0"><MapPin size={18} /></span>
                <div>
                  <p className={marken}>{t('kontakt.adresse')}</p>
                  <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(adresse)}`} target="_blank" rel="noopener noreferrer"
                     className="text-stone-900 font-bold hover:text-primary">{adresse}</a>
                </div>
              </div>
            )}
            {email && (
              <div className="flex items-start gap-4">
                <span className="w-11 h-11 rounded-2xl tupfer-primaer flex items-center justify-center shrink-0"><Mail size={18} /></span>
                <div>
                  <p className={marken}>E-Mail</p>
                  <a href={`mailto:${email}`} className="text-stone-900 font-bold hover:text-primary break-all">{email}</a>
                </div>
              </div>
            )}
            {telefon && (
              <div className="flex items-start gap-4">
                <span className="w-11 h-11 rounded-2xl tupfer-primaer flex items-center justify-center shrink-0"><Phone size={18} /></span>
                <div>
                  <p className={marken}>{t('kontakt.telefon')}</p>
                  <a href={`tel:${telefon.replace(/\s+/g, '')}`} className="text-stone-900 font-bold hover:text-primary">{telefon}</a>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="lg:col-span-3">
          <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm p-8 md:p-10">
            {offen === false ? (
              <p className="text-stone-500 text-center py-10">{t('kontakt.geschlossen')}</p>
            ) : fertig ? (
              <div className="text-center py-12">
                <div className="w-16 h-16 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto mb-6"><Check size={30} /></div>
                <h2 className="font-display text-3xl font-bold text-stone-900">{t('kontakt.danke')}</h2>
                <p className="text-stone-500 mt-3 max-w-sm mx-auto">{t('kontakt.danke_text')}</p>
                <Link to="/" className="inline-block mt-8 text-sm font-bold text-primary">{t('nav.home')} →</Link>
              </div>
            ) : (
              <form onSubmit={senden} className="space-y-5" noValidate>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label className={marken} htmlFor="k-name">{t('kontakt.name')} *</label>
                    <input id="k-name" className={feld} value={f.name} autoComplete="name" maxLength={120}
                      onChange={e => setF({ ...f, name: e.target.value })} />
                  </div>
                  <div>
                    <label className={marken} htmlFor="k-mail">E-Mail *</label>
                    <input id="k-mail" type="email" className={feld} value={f.email} autoComplete="email"
                      onChange={e => setF({ ...f, email: e.target.value })} />
                  </div>
                  <div>
                    <label className={marken} htmlFor="k-tel">{t('kontakt.telefon')}</label>
                    <input id="k-tel" type="tel" className={feld} value={f.telefon} autoComplete="tel" maxLength={40}
                      onChange={e => setF({ ...f, telefon: e.target.value })} />
                  </div>
                  <div>
                    <label className={marken} htmlFor="k-betreff">{t('kontakt.betreff')}</label>
                    <input id="k-betreff" className={feld} value={f.betreff} maxLength={200}
                      onChange={e => setF({ ...f, betreff: e.target.value })} />
                  </div>
                </div>
                <div>
                  <label className={marken} htmlFor="k-text">{t('kontakt.nachricht')} *</label>
                  <textarea id="k-text" rows={7} className={`${feld} leading-relaxed`} value={f.nachricht} maxLength={5000}
                    onChange={e => setF({ ...f, nachricht: e.target.value })} />
                </div>
                {/* Die Falle: fuer Menschen unsichtbar und nicht erreichbar. */}
                <div aria-hidden="true" style={{ position: 'absolute', left: '-10000px', width: 1, height: 1, overflow: 'hidden' }}>
                  <label htmlFor="k-website">Website</label>
                  <input id="k-website" tabIndex={-1} autoComplete="off" value={f.falle}
                    onChange={e => setF({ ...f, falle: e.target.value })} />
                </div>
                <label className="flex items-start gap-3 cursor-pointer">
                  <input type="checkbox" checked={zustimmung} onChange={e => setZustimmung(e.target.checked)}
                    className="w-4 h-4 mt-0.5 accent-[color:var(--primary)]" />
                  <span className="text-xs text-stone-500 leading-relaxed">
                    {t('kontakt.zustimmung')}{' '}
                    <Link to="/privacy" className="underline hover:text-stone-900">{t('kontakt.datenschutz')}</Link>
                  </span>
                </label>
                {fehler && (
                  <p className="text-sm text-red-700 bg-red-50 border border-red-100 rounded-2xl p-4 flex gap-2">
                    <AlertTriangle size={16} className="shrink-0 mt-0.5" /> {fehler}
                  </p>
                )}
                <button type="submit" disabled={sendet}
                  className="w-full md:w-auto inline-flex items-center justify-center gap-2 bg-primary text-white px-8 py-4 rounded-2xl font-bold text-sm shadow-lg disabled:opacity-60">
                  {sendet ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />} {t('kontakt.senden')}
                </button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default KontaktSeite;
