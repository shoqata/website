
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { db } from '../services/datenzugriff';
import { doc, onSnapshot } from '@/services/supabase-bridge';
import { ShieldCheck, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from '../context/LanguageContext';
import { useIstPlattformDomain } from '../lib/useIstPlattformDomain';

// Der Text fuer die Betreiber-Domain.
//
// Auf unityhub.li gibt es keinen Verein, also auch keine settings-Zeile --
// die Seite blieb deshalb leer. Der Betreiber hat aber eine eigene
// Erklaerung zu schulden, nicht die eines Vereins.
//
// Was hier steht, ist am 27.09.2026 an der Anwendung nachgemessen und nicht
// aus einer Vorlage abgeschrieben: es gibt keinerlei Zaehl- oder
// Verfolgungsdienste (kein Analytics, kein Pixel, keine Werbung), wohl aber
// Schriften und ein CSS-Geruest von fremden Servern, die dabei die
// IP-Adresse des Besuchers sehen. Beides steht deshalb ausdruecklich drin.
//
// ACHTUNG: Die Angaben zum Verantwortlichen fehlen bewusst -- Rechtsform,
// Anschrift und Kontakt kennt nur der Betreiber. Und eine
// Datenschutzerklaerung gehoert vor der Veroeffentlichung juristisch
// geprueft; dies ist ein belastbarer Entwurf, kein Rechtsrat.
const PLATTFORM_DATENSCHUTZ: Record<string, string> = {
  de: `Wer verantwortlich ist
[Rechtsform, Name, Anschrift und E-Mail des Betreibers hier eintragen.]

Was unityhub ist
unityhub stellt Vereinen eine Plattform bereit, auf der sie ihre Mitglieder, Beiträge, Protokolle und Veranstaltungen führen. Für die Daten seiner Mitglieder ist jeder Verein selbst verantwortlich; unityhub verarbeitet sie in seinem Auftrag und nur zu diesem Zweck. Kein Verein sieht die Daten eines anderen — das ist in den Zugriffsregeln der Datenbank festgelegt und nicht nur in der Oberfläche.

Welche Daten anfallen
Auf dieser Seite: nur die Angaben, die Sie in ein Formular schreiben, etwa Name, E-Mail-Adresse und Ihre Nachricht in einer Anfrage. Ohne Anfrage bleibt von einem Besuch nichts als der technische Server-Eintrag.

In der Anwendung selbst, im Auftrag des jeweiligen Vereins: Mitgliederdaten wie Name, Anschrift, Telefonnummer, E-Mail-Adresse und Geburtsdatum, dazu Beiträge, Zahlungen, Spenden, Protokolle und Anmeldungen zu Veranstaltungen.

Was wir nicht tun
Es gibt auf dieser Seite keinerlei Zähl- oder Verfolgungsdienste: kein Analytics, keine Zählpixel, keine Werbung, kein Weiterverkauf von Daten, keine Profilbildung. Das ist keine Absichtserklärung, sondern der Stand der Anwendung.

Cookies und Browserspeicher
Es werden keine Werbe- oder Verfolgungscookies gesetzt. Gespeichert wird nur, was für den Betrieb nötig ist: Ihre Anmeldesitzung, die gewählte Sprache und die Zuordnung, welcher Verein zu der aufgerufenen Adresse gehört. Diese Angaben verlassen Ihr Gerät nicht zu Werbezwecken.

Fremde Dienste
Der Betrieb stützt sich auf Dienstleister, die dabei technisch notwendige Daten sehen — insbesondere Ihre IP-Adresse:

· Supabase — Datenbank und Anmeldung
· Vercel — Auslieferung der Website
· Google Fonts (fonts.googleapis.com, fonts.gstatic.com) — Schriften
· Tailwind CDN (cdn.tailwindcss.com) — Gestaltungsgerüst

Die beiden letzten werden beim Aufruf der Seite von Ihrem Browser direkt angefragt; dabei sieht der jeweilige Anbieter Ihre IP-Adresse. Wir arbeiten daran, Schriften und Gestaltungsgerüst selbst auszuliefern, damit auch das entfällt.

Wie lange
Vereinsdaten bleiben, solange der Verein die Plattform nutzt, und werden auf seine Weisung gelöscht. Anfragen über das Formular werden gelöscht, sobald sie erledigt sind.

Ihre Rechte
Sie können Auskunft verlangen, Berichtigung, Löschung oder Einschränkung, und der Bearbeitung widersprechen. Betrifft Ihre Anfrage Daten, die ein Verein führt, wenden Sie sich zuerst an diesen Verein — er entscheidet darüber. Wir unterstützen ihn dabei.

Ein Beispiel dafür, was das praktisch heisst: Wer nicht öffentlich auf der Website seines Vereins erscheinen will, kann das im eigenen Profil abstellen oder es der Nachbarschaftsbetreuung sagen. Der Widerspruch wirkt sofort und gilt auch gegen die Einstellung des Vereins.

Änderungen
Diese Erklärung gilt ab dem Datum der letzten Änderung. Wesentliche Änderungen kündigen wir den Vereinen an.`,

  en: `Who is responsible
[Enter the operator's legal form, name, address and email here.]

What unityhub is
unityhub provides associations with a platform for their members, contributions, minutes and events. Each association remains responsible for its own members' data; unityhub processes it on their behalf and for that purpose only. No association sees another's data — that is enforced in the database access rules, not merely in the interface.

What data arises
On this site: only what you type into a form — name, email address and your message. Without an enquiry, nothing remains of a visit but the technical server log.

Inside the application, on behalf of the respective association: member data such as name, address, telephone number, email address and date of birth, plus contributions, payments, donations, minutes and event registrations.

What we do not do
There are no analytics or tracking services on this site: no analytics, no tracking pixels, no advertising, no selling of data, no profiling. That is the measured state of the application, not a statement of intent.

Cookies and browser storage
No advertising or tracking cookies are set. Only what operation requires is stored: your session, the chosen language, and which association belongs to the address you called up.

Third parties
Operation relies on providers who necessarily see technical data, in particular your IP address:

· Supabase — database and authentication
· Vercel — delivery of the website
· Google Fonts (fonts.googleapis.com, fonts.gstatic.com) — typefaces
· Tailwind CDN (cdn.tailwindcss.com) — styling framework

The last two are requested directly by your browser when the page loads, and the respective provider sees your IP address. We are working towards serving fonts and styling ourselves so that this no longer happens.

How long
Association data remains for as long as the association uses the platform and is deleted on its instruction. Enquiries are deleted once they have been dealt with.

Your rights
You may request access, correction, deletion or restriction, and object to processing. If your request concerns data held by an association, please approach that association first — it decides. We support it in doing so.

Changes
This statement applies from the date of its last change. Material changes are announced to the associations.`,

  sq: `Kush është përgjegjës
[Shënoni këtu formën juridike, emrin, adresën dhe email-in e operatorit.]

Çfarë është unityhub
unityhub u ofron shoqatave një platformë për anëtarët, kuotat, procesverbalet dhe ngjarjet e tyre. Për të dhënat e anëtarëve përgjegjëse mbetet vetë shoqata; unityhub i përpunon me porosi të saj dhe vetëm për atë qëllim. Asnjë shoqatë nuk i sheh të dhënat e një tjetre — kjo është e përcaktuar në rregullat e qasjes së bazës së të dhënave, jo vetëm në ndërfaqe.

Cilat të dhëna lindin
Në këtë faqe: vetëm ato që shkruani në një formular — emri, email-i dhe mesazhi juaj. Pa një kërkesë, nga një vizitë nuk mbetet veçse shënimi teknik i serverit.

Brenda aplikacionit, me porosi të shoqatës përkatëse: të dhëna të anëtarëve si emri, adresa, numri i telefonit, email-i dhe datëlindja, si dhe kuotat, pagesat, donacionet, procesverbalet dhe regjistrimet në ngjarje.

Çfarë nuk bëjmë
Në këtë faqe nuk ka asnjë shërbim numërimi apo gjurmimi: pa analytics, pa pixel gjurmimi, pa reklama, pa shitje të dhënash, pa profilizim.

Cookies dhe ruajtja në shfletues
Nuk vendosen cookies reklamash apo gjurmimi. Ruhet vetëm ajo që është e nevojshme për funksionimin: sesioni juaj, gjuha e zgjedhur dhe cila shoqatë i përket adresës së thirrur.

Shërbime të palëve të treta
Funksionimi mbështetet te ofrues që shohin të dhëna teknike, veçanërisht IP-në tuaj:

· Supabase — baza e të dhënave dhe kyçja
· Vercel — shpërndarja e faqes
· Google Fonts (fonts.googleapis.com, fonts.gstatic.com) — shkronjat
· Tailwind CDN (cdn.tailwindcss.com) — korniza e stilit

Dy të fundit i kërkon drejtpërdrejt shfletuesi juaj kur ngarkohet faqja, dhe ofruesi përkatës sheh IP-në tuaj.

Sa gjatë
Të dhënat e shoqatës mbeten sa kohë që shoqata e përdor platformën dhe fshihen me udhëzimin e saj.

Të drejtat tuaja
Mund të kërkoni qasje, korrigjim, fshirje ose kufizim, dhe të kundërshtoni përpunimin. Nëse kërkesa juaj ka të bëjë me të dhëna që mban një shoqatë, drejtohuni së pari asaj shoqate.

Ndryshimet
Kjo deklaratë vlen nga data e ndryshimit të fundit.`,
};

interface LegalPageProps {
    type: 'GDPR' | 'PRIVACY';
}

const LegalPage: React.FC<LegalPageProps> = ({ type }) => {
  const { t, language } = useTranslation();
  const istPlattform = useIstPlattformDomain();
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);

  // Helper to get localized string from branding object
  const getLoc = (val: any) => {
      if (!val) return '';
      if (typeof val === 'string') return val;
      return val[language] || val['de'] || ''; 
  };

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'public_settings', 'branding'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        const rawContent = type === 'GDPR' ? data.gdprText : data.privacyText;
        setContent(getLoc(rawContent));
      }
      setLoading(false);
    });
    return () => unsub();
  }, [type, language]);

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-40 pb-20">
      <div className="max-w-4xl mx-auto px-6">
        <Link to="/" className="inline-flex items-center gap-2 text-stone-400 hover:text-primary font-bold text-xs uppercase tracking-widest mb-12 transition-colors">
            <ArrowLeft size={16} /> {t('nav.back_home')}
        </Link>

        <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-[3rem] p-10 md:p-16 shadow-sm border border-stone-100"
        >
            <div className="w-16 h-16 bg-rose-50 text-primary rounded-2xl flex items-center justify-center mb-8">
                <ShieldCheck size={32} />
            </div>
            
            <h1 className="text-4xl font-display font-bold italic text-stone-900 mb-12">
                {type === 'GDPR' ? t('web.gdpr_text') : t('web.privacy_policy')}
            </h1>

            {loading ? (
                <div className="space-y-4">
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-full" />
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-5/6" />
                    <div className="h-4 bg-stone-50 rounded-full animate-pulse w-4/6" />
                </div>
            ) : istPlattform && !content ? (
                // Auf der Betreiber-Domain gibt es keinen Verein und damit keine
                // settings-Zeile; ohne diesen Zweig blieb die Seite leer.
                <div className="prose prose-stone max-w-none">
                    {(PLATTFORM_DATENSCHUTZ[language] || PLATTFORM_DATENSCHUTZ.de)
                      .split('\n').map((para, i) => (
                        para.trim() === '' ? <div key={i} className="h-3" /> :
                        /^[A-ZÄÖÜ][^.·]{2,48}$/.test(para.trim()) ? (
                          <h2 key={i} className="text-lg font-bold text-stone-900 mt-10 mb-3">{para}</h2>
                        ) : (
                          <p key={i} className="text-stone-600 leading-relaxed mb-3 whitespace-pre-wrap">{para}</p>
                        )
                    ))}
                </div>
            ) : (
                <div className="prose prose-stone max-w-none">
                    {content ? (
                        content.split('\n').map((para, i) => (
                            <p key={i} className="text-stone-600 leading-relaxed mb-6 font-medium whitespace-pre-wrap">
                                {para}
                            </p>
                        ))
                    ) : (
                        <p className="text-stone-400 italic">{t('legal.empty')}</p>
                    )}
                </div>
            )}
        </motion.div>
      </div>
    </div>
  );
};

export default LegalPage;
