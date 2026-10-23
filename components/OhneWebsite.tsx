import React from 'react';
import { Link } from 'react-router-dom';
import { LogIn } from 'lucide-react';
import { useTenant } from '../context/TenantContext';
import { useTranslation } from '../context/LanguageContext';

// Startseite eines Vereins ohne oeffentliche Website (Paket Light).
//
// Der Verein nutzt die Plattform fuer Mitglieder, Nachbarschaften,
// Rechnungen und Vorstand -- nach aussen zeigt er nichts. Ein Besucher
// bekommt darum keine halbe Website, sondern nur den Weg zur Anmeldung.
const OhneWebsite: React.FC = () => {
  const { tenant } = useTenant();
  const { t } = useTranslation();
  return (
    <div className="min-h-screen flex items-center justify-center px-6 bg-[#faf9f6]">
      <div className="max-w-md w-full text-center bg-white border border-stone-100 rounded-[2.5rem] p-10 shadow-sm">
        {tenant?.logoUrl && <img src={tenant.logoUrl} alt="" className="h-16 mx-auto mb-6 object-contain" />}
        <h1 className="text-3xl font-display font-bold italic text-stone-900">{tenant?.name}</h1>
        <p className="text-sm text-stone-500 mt-3 leading-relaxed">{t('ow.text')}</p>
        <Link to="/login" className="mt-8 inline-flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-xl font-bold text-sm">
          <LogIn size={16} /> {t('nav.login')}
        </Link>
      </div>
    </div>
  );
};

export default OhneWebsite;
