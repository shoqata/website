import React, { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import {
  MapPin, Globe as GlobeIcon, Users, Target, ShieldCheck, Heart, GraduationCap, Home, HandHeart,
  ArrowRight, Star, Mail, UserPlus, History,
} from 'lucide-react';
import { db } from '../services/datenzugriff';
import { collection, onSnapshot, doc } from '@/services/supabase-bridge';
import { UserProfile, BoardMember } from '../types';
import { TestimonialGlobe, type GlobeTestimonial } from './ui/testimonial-globe';
import { laenderZaehlen, heimatLesen } from '../lib/weltkarte';
import { useTranslation } from '../context/LanguageContext';
import { TestimonialSlider, Review } from './ui/TestimonialSlider';
import { SeitenInhalt } from './EigeneSeite';
import { useChronik, chronikDatum } from '../lib/useChronik';
import { abschnitte, wertSymbol, FESTE, type Abschnitt } from '../lib/ueberUns';
import { usePaket } from '../lib/usePaket';
import { onImageError } from '../lib/imageFallback';

// "Ueber uns" -- aus Abschnitten, die der Verein selbst anordnet.
//
// Bisher war die Seite fest: Einleitung mit Globus, drei Karten, eine
// Zeitleiste, der Vorstand. Gemessen am 24.10.2026 hatten Koretini und der
// Demo-Verein weder Karten noch Zeitleiste hinterlegt -- die Seite bestand
// aus einem Satz und einem Globus. Jetzt bringt sie mit, was schon da ist
// (Zahlen, Vorstand, Chronik), und der Verein kann Abschnitte umstellen,
// ausblenden und eigene dazwischenschieben (Website -> Ueber uns).

const SYMBOL: Record<string, React.ReactNode> = {
  ZIEL: <Target size={22} />, GEMEINSCHAFT: <Users size={22} />, TRANSPARENZ: <ShieldCheck size={22} />,
  HERZ: <Heart size={22} />, BILDUNG: <GraduationCap size={22} />, HEIMAT: <Home size={22} />,
  HILFE: <HandHeart size={22} />, WELT: <GlobeIcon size={22} />,
};

const Kopf: React.FC<{ marke: string; titel: string; text?: string }> = ({ marke, titel, text }) => (
  <div className="max-w-2xl mb-10">
    <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-primary mb-3">{marke}</p>
    <h2 className="font-display text-3xl md:text-4xl font-bold italic text-stone-900 leading-tight">{titel}</h2>
    {text && <p className="text-stone-500 leading-relaxed mt-4">{text}</p>}
  </div>
);

const AboutUsPage: React.FC = () => {
  const { t, language, loc } = useTranslation();
  const paket = usePaket();
  const [branding, setBranding] = useState<any>({});
  const [mitglieder, setMitglieder] = useState<UserProfile[]>([]);
  const [neighborhoodCount, setNeighborhoodCount] = useState(0);
  const [boardReviews, setBoardReviews] = useState<Review[]>([]);
  const chronik = useChronik();

  useEffect(() => {
    const unsubBranding = onSnapshot(doc(db, 'public_settings', 'branding'), (snap) => {
      if (snap.exists()) setBranding(snap.data());
    });
    const unsubNb = onSnapshot(collection(db, 'neighborhoods'), (snap) => setNeighborhoodCount(snap.size));
    let unsubBoard: (() => void) | null = null;
    const unsubUsers = onSnapshot(collection(db, 'public_members'), (snap) => {
      const liste = snap.docs.map(d => ({ id: d.id, ...d.data() } as UserProfile));
      setMitglieder(liste);
      const nachId = new Map<string, UserProfile>(liste.map(u => [u.id, u]));
      unsubBoard?.();
      unsubBoard = onSnapshot(collection(db, 'board_members'), (boardSnap) => {
        const reviews: Review[] = [];
        boardSnap.forEach(d => {
          const bm = d.data() as BoardMember;
          const u = nachId.get(bm.userId);
          if (!u) return;
          const bild = bm.image || u.photoFileName || 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=1000';
          reviews.push({ id: bm.id || d.id, name: u.displayName || '', affiliation: bm.role,
                         quote: bm.quote, imageSrc: bild, thumbnailSrc: bild });
        });
        setBoardReviews(reviews);
      });
    });
    return () => { unsubBranding(); unsubUsers(); unsubNb(); unsubBoard?.(); };
  }, []);

  const laender = useMemo(() =>
    new Set(mitglieder.map(u => (u.country || '').trim().toLowerCase()).filter(Boolean)).size, [mitglieder]);

  // Weltkarte: je Land gezaehlt, nie je Person (lib/weltkarte.ts).
  const welt = useMemo(() => laenderZaehlen(mitglieder, language), [mitglieder, language]);

  const gruendung: number | null = Number(branding.gruendungsjahr) || (chronik?.length ? chronik[0].jahr : null);
  const zahlen = [
    { wert: mitglieder.length, text: t('about.stats.members') },
    { wert: neighborhoodCount, text: t('about.stats.neighborhoods') },
    ...(laender > 1 ? [{ wert: laender, text: t('about.stats.laender') }] : []),
    ...(gruendung ? [{ wert: new Date().getFullYear() - gruendung, text: t('about.stats.jahre') }] : []),
    ...((branding.ueberUnsZahlen || []) as any[]).filter(z => String(z?.wert ?? '').trim())
      .map(z => ({ wert: z.wert, text: loc(z.text) })),
  ].filter(z => z.wert !== 0 && z.wert !== '0');

  // Meilensteine der Chronik; gibt es keine, die vier juengsten Eintraege.
  const geschichte = useMemo(() => {
    const alle = chronik ?? [];
    const m = alle.filter(e => e.meilenstein);
    return (m.length ? m : alle).slice(-4);
  }, [chronik]);

  const werte = (branding.missions || []).filter((m: any) => loc(m.title) || loc(m.description));
  const ziele = (branding.roadmap || []).filter((r: any) => loc(r.title) || loc(r.description));
  const titelVon = (a: Abschnitt, vorgabe: string) => loc(a.titel) || t(vorgabe);
  const vorgabe = (art: string) => FESTE.find(f => f.art === art)?.titel ?? '';

  const abschnitt = (a: Abschnitt): React.ReactNode => {
    switch (a.art) {
      case 'einleitung':
        return (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 bg-emerald-50 text-emerald-600 px-4 py-2 rounded-full text-xs font-bold mb-6 uppercase tracking-widest">
                <GlobeIcon size={14} /> {loc(branding.aboutBadge) || t('about.badge')}
              </div>
              <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">
                {loc(a.titel) || loc(branding.aboutTitle) || t('about.title')}
              </h1>
              <div className="text-xl text-stone-500 leading-relaxed italic space-y-4">
                {(loc(branding.aboutIntro) || t('about.intro')).split(/\n{2,}/).map((s, i) => (
                  <p key={i} className="whitespace-pre-line">{s}</p>
                ))}
              </div>
              {gruendung && (
                <p className="mt-8 text-xs font-bold uppercase tracking-widest text-stone-400">
                  {t('about.seit', { jahr: String(gruendung) })}
                </p>
              )}
            </div>
            {branding.aboutBild ? (
              <div className="relative">
                <img src={branding.aboutBild} alt="" onError={onImageError}
                     className="w-full aspect-[4/3] object-cover rounded-[2.5rem] shadow-xl" />
                {loc(branding.footerAddress) && (
                  <div className="absolute -bottom-6 left-6 bg-white p-5 rounded-3xl shadow-xl border border-stone-100 max-w-xs flex items-center gap-3">
                    <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-white shrink-0"><MapPin size={16} /></div>
                    <p className="font-bold text-sm text-stone-900">{loc(branding.footerAddress)}</p>
                  </div>
                )}
              </div>
            ) : loc(branding.footerAddress) ? (
              // Ohne Bild stand hier bis zum 31.10.2026 der Globus. Er hat
              // jetzt einen eigenen Abschnitt ("Weltkarte"); hier bleibt die
              // Adresse.
              <div className="bg-white p-8 rounded-[2.5rem] shadow-xl border border-stone-100 max-w-sm lg:justify-self-end">
                <div className="flex items-center gap-3 mb-2">
                  <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-white"><MapPin size={16} /></div>
                  <p className="font-bold text-sm text-stone-900">{loc(branding.footerAddress)}</p>
                </div>
                <p className="text-xs text-stone-500 italic">{t('about.map.center_desc')}</p>
              </div>
            ) : null}
          </div>
        );

      case 'weltkarte': {
        const liste = welt.laender;
        if (liste.length === 0) return null;
        const heimat = heimatLesen(a.heimat);
        const gesamt = liste.reduce((n, l) => n + l.anzahl, 0);
        const max = Math.max(...liste.map(l => l.anzahl));
        // Mittlere Breite, nach Anzahl gewichtet; daraus die Neigung.
        const breite = liste.reduce((n, l) => n + l.lat * l.anzahl, 0) / gesamt;
        const neigung = Math.max(0.15, Math.min(0.85, (breite * Math.PI) / 180 * 0.95));
        const aufzaehlen = (w: string[]) => new Intl.ListFormat(language, { type: 'conjunction' }).format(w);
        const items: GlobeTestimonial[] = [
          ...(heimat ? [{
            id: 'heimat', name: heimat.name, lat: heimat.lat, lng: heimat.lng, tone: 2 as const,
            badge: <Home size={16} />, role: t('about.weltkarte.heimat_rolle'), city: '', weight: 6,
            quote: t('about.weltkarte.heimat_text', { ort: heimat.name, laender: String(liste.length) }),
            label: `${heimat.name}: ${t('about.weltkarte.heimat_rolle')}`,
          }] : []),
          ...liste.map(l => {
            const wer = l.anzahl === 1 ? t('about.weltkarte.mitglied') : t('about.weltkarte.mitglieder', { n: String(l.anzahl) });
            const anteil = Math.round((l.anzahl / gesamt) * 100);
            return {
              id: l.code, name: l.name, lat: l.lat, lng: l.lng, tone: 1 as const,
              badge: String(l.anzahl), role: wer, country: l.code, weight: Math.sqrt(l.anzahl),
              city: anteil < 1 ? '< 1 %' : `${anteil} %`,
              quote: l.anzahl === 1 ? t('about.weltkarte.land_eins', { land: l.name })
                : l.staedte.length ? t('about.weltkarte.land_staedte', { n: String(l.anzahl), land: l.name, staedte: aufzaehlen(l.staedte) })
                : t('about.weltkarte.land', { n: String(l.anzahl), land: l.name }),
              label: `${l.name}: ${wer}`,
            };
          }),
        ];
        // Auf dem Globus selbst: die echte Lage, Groesse nach Anzahl; vom
        // Heimatort ein Bogen zu jedem Land, das nicht gleich daneben liegt.
        const markers = [
          ...liste.map(l => ({ location: [l.lat, l.lng] as [number, number], size: 0.03 + 0.05 * Math.sqrt(l.anzahl / max) })),
          ...(heimat ? [{ location: [heimat.lat, heimat.lng] as [number, number], size: 0.05 }] : []),
        ];
        const arcs = heimat ? liste
          .filter(l => Math.hypot(l.lat - heimat.lat, l.lng - heimat.lng) > 3)
          .map(l => ({ from: [heimat.lat, heimat.lng] as [number, number], to: [l.lat, l.lng] as [number, number] })) : [];
        return (
          <TestimonialGlobe
            items={items}
            variant="fact"
            markers={markers}
            arcs={arcs}
            eyebrow={t('about.weltkarte.marke')}
            heading={titelVon(a, vorgabe('weltkarte'))}
            headingClassName="font-display font-bold italic text-stone-900"
            caption={t('about.weltkarte.text')}
            stats={[
              { value: gesamt, label: t('about.weltkarte.mit_land') },
              { value: liste.length, label: t('about.stats.laender') },
            ]}
            autoplay
            interval={4500}
            // Auf die Laender ausgerichtet: geneigt bis etwa zu ihrer
            // mittleren Breite, leicht vergroessert. Bei Mitgliedern rund
            // um den Globus waere die Vorgabe (flach, ganz) besser.
            tilt={neigung}
            zoom={1.2}
            size={520}
            pinSize={36}
            labels={{ previous: t('about.weltkarte.zurueck'), next: t('about.weltkarte.weiter'), pin: '' }}
            className="rounded-[2.5rem]"
          />
        );
      }

      case 'zahlen':
        if (zahlen.length === 0) return null;
        return (
          <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm p-8 md:p-10">
            {loc(a.titel) && <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-primary mb-6">{loc(a.titel)}</p>}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
              {zahlen.map((z, i) => (
                <div key={i}>
                  <p className="text-4xl md:text-5xl font-bold text-primary tabular-nums leading-none">{z.wert}</p>
                  <p className="text-xs font-bold text-stone-400 uppercase tracking-widest mt-2">{z.text}</p>
                </div>
              ))}
            </div>
          </div>
        );

      case 'werte':
        if (werte.length === 0) return null;
        return (
          <>
            <Kopf marke={t('about.werte.marke')} titel={titelVon(a, vorgabe('werte'))} />
            <div className={`grid grid-cols-1 md:grid-cols-2 ${werte.length % 3 === 0 ? 'lg:grid-cols-3' : werte.length >= 4 ? 'lg:grid-cols-4' : ''} gap-6`}>
              {werte.map((m: any, i: number) => (
                <div key={i} className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-stone-100">
                  <div className="w-12 h-12 tupfer-primaer rounded-2xl flex items-center justify-center mb-6">
                    {SYMBOL[wertSymbol(m.type)]}
                  </div>
                  <h3 className="text-2xl font-display font-bold mb-3 italic text-stone-900">{loc(m.title)}</h3>
                  <p className="text-stone-500 leading-relaxed text-sm whitespace-pre-line">{loc(m.description)}</p>
                </div>
              ))}
            </div>
          </>
        );

      case 'geschichte':
        if (geschichte.length === 0) return null;
        return (
          <>
            <div className="flex items-end justify-between gap-6 flex-wrap">
              <Kopf marke={t('about.geschichte.marke')} titel={titelVon(a, vorgabe('geschichte'))} />
              <Link to="/chronik" className="mb-10 inline-flex items-center gap-2 text-sm font-bold text-primary hover:gap-3 transition-[gap,color] duration-200 ease-out-strong">
                {t('about.geschichte.alle')} <ArrowRight size={16} />
              </Link>
            </div>
            <div className="relative">
              <div aria-hidden="true" className="hidden md:block absolute left-0 right-0 top-[1.15rem] h-px bg-stone-200" />
              <div className={`grid grid-cols-1 md:grid-cols-2 ${geschichte.length >= 4 ? 'lg:grid-cols-4' : geschichte.length === 3 ? 'lg:grid-cols-3' : ''} gap-6`}>
                {geschichte.map(e => (
                  <div key={e.id} className="relative">
                    <span className="relative z-10 inline-flex items-center gap-1.5 bg-stone-900 text-white text-sm font-bold px-3 py-1.5 rounded-full tabular-nums">
                      {e.meilenstein && <Star size={11} fill="currentColor" />} {e.jahr}
                    </span>
                    <div className="mt-4 bg-white rounded-[2rem] border border-stone-100 p-6 shadow-sm h-[calc(100%-3.25rem)]">
                      <p className="text-[10px] font-bold uppercase tracking-widest text-stone-400 mb-2">{chronikDatum(e, language)}</p>
                      <h3 className="font-display text-xl font-bold text-stone-900 leading-snug">{loc(e.titel)}</h3>
                      {loc(e.text) && <p className="text-sm text-stone-500 leading-relaxed mt-2 line-clamp-4">{loc(e.text)}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </>
        );

      case 'ziele':
        if (ziele.length === 0) return null;
        return (
          <>
            <Kopf marke={t('about.ziele.marke')} titel={titelVon(a, vorgabe('ziele'))} />
            <ol className="space-y-4">
              {ziele.map((r: any, i: number) => (
                <li key={i} className="bg-white rounded-[2rem] border border-stone-100 shadow-sm p-6 md:p-8 flex gap-6 items-start">
                  <span className="w-11 h-11 shrink-0 rounded-2xl bg-stone-900 text-white flex items-center justify-center font-bold tabular-nums">{i + 1}</span>
                  <div>
                    <h3 className="font-display text-xl md:text-2xl font-bold text-stone-900">{loc(r.title)}</h3>
                    {loc(r.description) && <p className="text-stone-500 leading-relaxed mt-2 whitespace-pre-line">{loc(r.description)}</p>}
                  </div>
                </li>
              ))}
            </ol>
          </>
        );

      case 'vorstand':
        if (boardReviews.length === 0) return null;
        return (
          <>
            <Kopf marke={t('about.vorstand.marke')} titel={titelVon(a, vorgabe('vorstand'))} />
            <TestimonialSlider reviews={boardReviews} />
          </>
        );

      case 'mitmachen': {
        const email = loc(branding.footerEmail);
        return (
          <div className="bg-stone-900 text-white rounded-[2.5rem] p-10 md:p-14 relative overflow-hidden">
            <div className="absolute -right-16 -top-16 w-72 h-72 rounded-full blur-3xl bg-[color:color-mix(in_srgb,var(--primary)_30%,transparent)]" />
            <div className="relative max-w-2xl">
              <h2 className="font-display text-3xl md:text-4xl font-bold italic leading-tight">
                {loc(a.titel) || loc(branding.mitmachenTitel) || t('about.mitmachen.titel')}
              </h2>
              <p className="text-white/70 leading-relaxed mt-4 whitespace-pre-line">
                {loc(branding.mitmachenText) || t('about.mitmachen.text')}
              </p>
              <div className="flex flex-wrap gap-3 mt-8">
                {paket !== 'LIGHT' && (
                  <Link to="/register" className="inline-flex items-center gap-2 bg-primary text-white px-6 py-3.5 rounded-2xl font-bold text-sm shadow-lg">
                    <UserPlus size={16} /> {t('nav.join')}
                  </Link>
                )}
                {email && (
                  <a href={`mailto:${email}`} className="inline-flex items-center gap-2 bg-white/10 hover:bg-white/15 text-white px-6 py-3.5 rounded-2xl font-bold text-sm">
                    <Mail size={16} /> {email}
                  </a>
                )}
                {(chronik?.length ?? 0) > 0 && (
                  <Link to="/chronik" className="inline-flex items-center gap-2 text-white/70 hover:text-white px-2 py-3.5 font-bold text-sm">
                    <History size={16} /> {t('nav.chronik')}
                  </Link>
                )}
              </div>
            </div>
          </div>
        );
      }

      case 'eigen':
        if (!a.bloecke?.length && !loc(a.titel)) return null;
        return (
          <div className="max-w-3xl">
            {loc(a.titel) && (
              <h2 className="font-display text-3xl md:text-4xl font-bold italic text-stone-900 leading-tight mb-8">{loc(a.titel)}</h2>
            )}
            <SeitenInhalt bloecke={(a.bloecke ?? []) as any} />
          </div>
        );
      default:
        return null;
    }
  };

  const liste = abschnitte(branding.ueberUns).filter(a => a.an);

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-24">
      <div className="max-w-7xl mx-auto px-6 space-y-24">
        {liste.map(a => {
          const inhalt = abschnitt(a);
          return inhalt ? <section key={a.id}>{inhalt}</section> : null;
        })}
      </div>
    </div>
  );
};

export default AboutUsPage;
