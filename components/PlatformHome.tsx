import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Building2, ShieldCheck, LogIn } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';
import { UserProfile } from '../types';

interface Props { user: UserProfile | null; }

// Startseite der Betreiber-Domain.
//
// Diese Adresse gehoert keinem Verein. Ohne eigene Seite erschiene hier die
// Vereinsseite ohne Inhalte -- Ueberschriften ueber leeren Listen, was wie ein
// Fehler aussieht statt wie eine Absicht.
//
// Gezeigt wird deshalb nur, was hier hingehoert: der Weg zur Anmeldung und,
// wenn jemand angemeldet ist, der Weg in die Verwaltung der Vereine. Bewusst
// ohne Aufzaehlung der betreuten Vereine -- wer sie sehen darf, sieht sie nach
// der Anmeldung, und vorher geht es niemanden etwas an, welche Vereine hier
// gefuehrt werden.
const PlatformHome: React.FC<Props> = ({ user }) => {
  const { t } = useTranslation();
  const angemeldet = !!user;

  return (
    <div className="min-h-screen bg-[#faf9f6] flex items-center justify-center p-6">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="w-full max-w-xl"
      >
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
          <div className="bg-stone-900 text-white p-10">
            <div className="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center mb-6">
              <Building2 size={22} />
            </div>
            <h1 className="text-3xl md:text-4xl font-display font-bold italic mb-3">
              {t('platform.title')}
            </h1>
            <p className="text-stone-400 text-sm leading-relaxed max-w-md">
              {t('platform.subtitle')}
            </p>
          </div>

          <div className="p-10 space-y-6">
            {angemeldet ? (
              <>
                <div className="flex items-start gap-3 text-sm text-stone-600">
                  <ShieldCheck size={18} className="text-emerald-600 mt-0.5 shrink-0" />
                  <p className="leading-relaxed">
                    {t('platform.signed_in_as')} <b className="text-stone-900">{user!.email}</b>
                  </p>
                </div>
                <Link
                  to="/super-admin"
                  className="w-full py-4 bg-primary text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-rose-100 hover:bg-rose-600 transition-colors"
                >
                  {t('platform.open_admin')} <ArrowRight size={18} />
                </Link>
              </>
            ) : (
              <>
                <p className="text-sm text-stone-600 leading-relaxed">{t('platform.login_hint')}</p>
                <Link
                  to="/login"
                  className="w-full py-4 bg-primary text-white rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-rose-100 hover:bg-rose-600 transition-colors"
                >
                  <LogIn size={18} /> {t('nav.login')}
                </Link>
              </>
            )}

            <p className="text-[11px] text-stone-400 leading-relaxed border-t border-stone-100 pt-5">
              {t('platform.footer_note')}
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default PlatformHome;
