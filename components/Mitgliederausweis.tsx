import React, { useEffect, useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { useParams, Link } from 'react-router-dom';
import { BadgeCheck, XCircle, Loader2, ShieldAlert } from 'lucide-react';
import { supabase } from '../services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { useTenant } from '../context/TenantContext';
import type { UserProfile } from '../types';
import { datumLesen } from '../lib/datumLesen';

// Mitgliederausweis im Mitgliederbereich. Der QR-Code fuehrt auf
// /ausweis/<nummer>; dort sieht nur Vorstand oder Vertreter, ob die Person
// Mitglied ist und den Beitrag bezahlt hat (ausweis_pruefen).

// joinedAt kommt als Text, Date oder Firestore-artiger Zeitstempel.
const jahrVon = (v: any): number | null => datumLesen(v)?.getFullYear() ?? null;

export const AusweisKarte: React.FC<{ user: UserProfile }> = ({ user }) => {
  const { t } = useTranslation();
  const { tenant } = useTenant() as any;
  const jahr = new Date().getFullYear();
  const link = `${window.location.origin}/#/ausweis/${user.id}`;
  return (
    <div className="relative overflow-hidden rounded-[2rem] p-6 text-white shadow-xl" style={{ background: 'linear-gradient(135deg, var(--primary), #1c1917)' }}>
      <div className="absolute -right-10 -top-10 w-40 h-40 rounded-full bg-white/10" />
      <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-white/70">{t('ausweis.titel')} {jahr}</p>
      <p className="font-display text-xl font-bold italic mt-1 truncate" title={tenant?.name || ''}>{tenant?.name || ''}</p>
      <div className="flex items-end justify-between gap-4 mt-6">
        <div className="min-w-0">
          <p className="text-lg font-bold truncate" title={user.displayName}>{user.displayName}</p>
          <p className="text-[11px] font-mono text-white/70">Nr. {user.id.slice(0, 8).toUpperCase()}</p>
          {jahrVon((user as any).joinedAt) && <p className="text-[11px] text-white/70">{t('ausweis.seit')} {jahrVon((user as any).joinedAt)}</p>}
        </div>
        <div className="bg-white p-2 rounded-xl shrink-0"><QRCodeSVG value={link} size={88} level="M" /></div>
      </div>
    </div>
  );
};

export const AusweisPruefen: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { t } = useTranslation();
  const [d, setD] = useState<any>(undefined);
  const [fehler, setFehler] = useState<string | null>(null);
  useEffect(() => {
    supabase.rpc('ausweis_pruefen', { p_id: id }).then(({ data, error }) => {
      if (error) setFehler(error.message); else setD(data);
    });
  }, [id]);

  const gueltig = d?.gefunden && d.status !== 'INACTIVE';
  return (
    <div className="min-h-screen pt-32 pb-20 px-6 bg-[#faf9f6] flex justify-center">
      <div className="w-full max-w-md bg-white rounded-[2rem] border border-stone-100 shadow-sm p-8 text-center">
        {d === undefined && !fehler && <Loader2 className="animate-spin mx-auto text-stone-300" />}
        {fehler && (<>
          <ShieldAlert size={40} className="mx-auto text-stone-400 mb-4" />
          <p className="font-bold text-stone-800 mb-2">{t('ausweis.nur_vorstand')}</p>
          <Link to="/login" className="text-sm font-bold" style={{ color: 'var(--primary)' }}>{t('login.submit')}</Link>
        </>)}
        {d && (<>
          {gueltig ? <BadgeCheck size={56} className="mx-auto text-emerald-600 mb-4" /> : <XCircle size={56} className="mx-auto text-rose-600 mb-4" />}
          <p className={`text-2xl font-bold mb-1 ${gueltig ? 'text-emerald-700' : 'text-rose-700'}`}>{gueltig ? t('ausweis.gueltig') : t('ausweis.ungueltig')}</p>
          {d.gefunden && <>
            <p className="text-lg font-bold text-stone-900">{d.name}</p>
            <p className="text-sm text-stone-500">{d.nachbarschaft || ''}{jahrVon(d.seit) ? ` · ${t('ausweis.seit')} ${jahrVon(d.seit)}` : ''}</p>
            <p className={`mt-4 inline-block px-4 py-2 rounded-xl text-sm font-bold ${d.bezahlt ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>
              {d.bezahlt ? t('ausweis.bezahlt', { jahr: d.jahr }) : t('ausweis.offen', { jahr: d.jahr })}
            </p>
          </>}
        </>)}
      </div>
    </div>
  );
};
