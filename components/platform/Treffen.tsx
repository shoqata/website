import React, { useEffect, useState } from 'react';
import { CalendarDays, MapPin, Users, Ticket } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { TINTE, BLAU, SCHIEFER, LINIE, MONO } from './farben';

// Die kommenden Vereinstreffen auf unityhub.li.
//
// Gezeigt wird, was veroeffentlicht ist -- und vom Programm nur, was
// freigegeben wurde. Entschieden wird beides in der Datenbank
// (treffen_oeffentlich); der Browser bekommt gar nicht erst zu sehen, was
// noch im Entwurf steht.
//
// Kontaktdaten und Kopfzahlen fehlen hier mit Absicht. Wer dabei ist, ist
// eine Ankuendigung; wie viele ein Verein schickt, geht niemanden ausser
// dem Gastgeber etwas an.
//
// Steht nichts an, erscheint der ganze Abschnitt nicht. Eine Ueberschrift
// mit "keine Termine" darunter ist schlechter als Schweigen.

const zeit = (s?: string | null) => (s ? String(s).slice(0, 5) : '');
const tag = (s: string) =>
  new Date(s).toLocaleDateString('de-CH', { day: '2-digit', month: 'long', year: 'numeric' });

const Treffen: React.FC = () => {
  const [liste, setListe] = useState<any[] | null>(null);

  useEffect(() => {
    let lebt = true;
    supabase.rpc('treffen_oeffentlich').then(({ data, error }) => {
      if (lebt) setListe(error ? [] : (data as any[]) || []);
    });
    return () => { lebt = false; };
  }, []);

  if (!liste || liste.length === 0) return null;

  return (
    <section className="max-w-5xl mx-auto px-6 py-20">
      <p className="uppercase mb-3"
         style={{ fontFamily: MONO, fontSize: 11, letterSpacing: '0.12em', color: BLAU }}>
        Vereinstreffen
      </p>
      <h2 className="font-light mb-10"
          style={{ fontSize: 30, lineHeight: 1.3, letterSpacing: '-0.012em', color: TINTE }}>
        Was als Nächstes ansteht
      </h2>

      <div className="space-y-10">
        {liste.map((t: any) => (
          <article key={t.id} style={{ borderTop: `1px solid ${LINIE}` }} className="pt-8">
            <div className="flex flex-wrap items-baseline gap-x-6 gap-y-2 mb-4">
              <h3 className="font-medium" style={{ fontSize: 22, color: TINTE }}>{t.titel}</h3>
              <span className="flex items-center gap-1.5" style={{ fontSize: 13, color: SCHIEFER }}>
                <CalendarDays size={14} /> {tag(t.datum)}
                {t.ende && t.ende !== t.datum ? ` – ${tag(t.ende)}` : ''}
                {t.beginn ? `, ${zeit(t.beginn)}` : ''}
              </span>
              {t.ort && (
                <span className="flex items-center gap-1.5" style={{ fontSize: 13, color: SCHIEFER }}>
                  <MapPin size={14} /> {t.ort}
                </span>
              )}
              <span className="flex items-center gap-1.5" style={{ fontSize: 13, color: SCHIEFER }}>
                <Ticket size={14} />
                {t.preis_art === 'KEINE' ? 'Teilnahme kostenlos'
                  : `${Number(t.preis_betrag).toLocaleString('de-CH', { minimumFractionDigits: 2 })} ${t.waehrung} `
                    + (t.preis_art === 'PRO_KOPF' ? 'pro Person' : 'pro Verein')}
              </span>
            </div>

            {t.beschreibung && (
              <p className="mb-6 max-w-2xl" style={{ fontSize: 15, lineHeight: 1.65, color: SCHIEFER }}>
                {t.beschreibung}
              </p>
            )}

            {t.vereine?.length > 0 && (
              <p className="mb-6 flex items-start gap-2" style={{ fontSize: 13, color: SCHIEFER }}>
                <Users size={14} className="shrink-0 mt-0.5" />
                <span>{t.vereine.join(' · ')}</span>
              </p>
            )}

            {t.programm?.length > 0 && (
              <div className="overflow-x-auto">
                <table className="w-full" style={{ fontSize: 13, borderCollapse: 'collapse', minWidth: '30rem' }}>
                  <tbody>
                    {t.programm.map((p: any, i: number) => (
                      <tr key={i} style={{ borderTop: i ? `1px solid ${LINIE}` : 'none' }}>
                        <td className="py-2 pr-4 whitespace-nowrap"
                            style={{ fontFamily: MONO, fontSize: 12, color: TINTE, verticalAlign: 'top' }}>
                          {zeit(p.beginn)}
                        </td>
                        <td className="py-2 pr-4 whitespace-nowrap" style={{ verticalAlign: 'top' }}>
                          <span className="uppercase px-2 py-0.5 rounded"
                                style={{ fontFamily: MONO, fontSize: 10, letterSpacing: '0.08em',
                                         color: SCHIEFER, border: `1px solid ${LINIE}` }}>
                            {p.spur}
                          </span>
                        </td>
                        <td className="py-2 pr-4" style={{ color: TINTE, verticalAlign: 'top' }}>
                          {p.titel}
                          {p.fuer === 'VERTRETER' && (
                            <em style={{ color: SCHIEFER }}> — nur Delegationsleitungen</em>
                          )}
                        </td>
                        <td className="py-2 whitespace-nowrap" style={{ color: SCHIEFER, verticalAlign: 'top' }}>
                          {[p.verantwortlich, p.ort].filter(Boolean).join(' · ')}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </article>
        ))}
      </div>
    </section>
  );
};

export default Treffen;
