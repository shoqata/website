import React, { useEffect, useState } from 'react';
import { History, Loader2 } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';

// Wer hat was geaendert (protokoll_lesen). Mit `mitglied` nur die
// Eintraege zu dieser Person: ihr Datensatz, ihre Rechnungen, ihr Stammbaum.

type Eintrag = { id: number; tabelle: string; zeile: string; aktion: string; felder: Record<string, any>; wer: string | null; wann: string };

const FELDNAME: Record<string, string> = {
  displayName: 'Name', firstName: 'Vorname', lastName: 'Nachname', street: 'Strasse', zip: 'PLZ', city: 'Ort', country: 'Land',
  email: 'E-Mail', phone: 'Telefon', birthdate: 'Geburtsdatum', role: 'Rolle', membershipStatus: 'Status', neighborhoodId: 'Nachbarschaft',
  salutation: 'Anrede', amount: 'Betrag', status: 'Status', description: 'Beschreibung', dueDate: 'Fällig', paidAt: 'Bezahlt am',
  invoiceDeliveryMethod: 'Zustellung', billingGroup: 'Beitragsgruppe', internalNotes: 'Notiz', art: 'Art', von: 'von', nach: 'nach',
};
const wert = (v: any) => v === null || v === undefined || v === '' ? '—' : typeof v === 'object' ? JSON.stringify(v).slice(0, 60) : String(v).slice(0, 80);

const AenderungsProtokoll: React.FC<{ mitglied?: string; limit?: number }> = ({ mitglied, limit = 60 }) => {
  const { t } = useTranslation();
  const [eintraege, setEintraege] = useState<Eintrag[] | null>(null);

  useEffect(() => {
    supabase.rpc('protokoll_lesen', { p_mitglied: mitglied ?? null, p_tabelle: null, p_limit: limit })
      .then(({ data }) => setEintraege((data ?? []) as Eintrag[]));
  }, [mitglied, limit]);

  if (eintraege === null) return <div className="p-4 text-stone-400"><Loader2 size={16} className="animate-spin" /></div>;

  return (
    <div className="bg-white rounded-2xl border border-stone-100 p-5">
      <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-4 flex items-center gap-2"><History size={14} /> {t('prot.titel')}</h4>
      {!eintraege.length ? <p className="text-xs text-stone-400">{t('prot.leer')}</p> : (
        <div className="space-y-2">
          {eintraege.map(e => (
            <div key={e.id} className="text-xs border-l-2 border-stone-200 pl-3 py-1">
              <p className="text-stone-500">
                <span className="font-bold text-stone-700">{e.wer || '—'}</span> · {new Date(e.wann).toLocaleString('de-CH', { dateStyle: 'short', timeStyle: 'short' })} ·{' '}
                {t(`prot.tab.${e.tabelle}`)} {t(`prot.akt.${e.aktion}`)}
              </p>
              {e.aktion === 'GEAENDERT' ? (
                <ul className="mt-0.5 space-y-0.5">
                  {Object.entries(e.felder).slice(0, 8).map(([k, [a, b]]: any) => (
                    <li key={k} className="text-stone-600"><span className="text-stone-400">{FELDNAME[k] || k}:</span> <span className="line-through text-stone-400">{wert(a)}</span> → <b>{wert(b)}</b></li>
                  ))}
                </ul>
              ) : (
                <p className="text-stone-600 mt-0.5">{Object.entries(e.felder).map(([k, v]) => `${FELDNAME[k] || k}: ${wert(v)}`).join(' · ')}</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default AenderungsProtokoll;
