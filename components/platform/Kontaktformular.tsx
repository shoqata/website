import React, { useState } from 'react';
import { Loader2, Check, AlertTriangle, ArrowRight } from 'lucide-react';
import { submitPlatformLead } from '@/services/supabase-bridge';
import { useTranslation } from '../../context/LanguageContext';

// Anfrage von der Startseite der Plattform.
//
// Statt einer E-Mail-Adresse, die in einem fremden Postfach landet und dort
// vergessen wird: die Anfrage entsteht als Eintrag im Bereich des Betreibers,
// wo sie eine Stufe bekommt und ein Gespraech ueber Wochen begleiten kann.
//
// Die Pruefung, was hineindarf, steht serverseitig. Hier wird nur geprueft,
// was sich ohne Netzanfrage feststellen laesst -- damit niemand auf eine
// Antwort wartet, um dann zu erfahren, dass ein Feld leer war.
const Kontaktformular: React.FC<{ farben: { tinte: string; blau: string; nebel: string; schiefer: string; linie: string; mono: string } }> =
({ farben }) => {
  const { t } = useTranslation();
  const [form, setForm] = useState({
    name: '', contactName: '', email: '', phone: '', city: '', expectedMembers: '', note: '',
  });
  const [sendet, setSendet] = useState(false);
  const [gesendet, setGesendet] = useState(false);
  const [fehler, setFehler] = useState('');

  const setzen = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));

  const senden = async (e: React.FormEvent) => {
    e.preventDefault();
    setFehler('');

    if (!form.name.trim())        { setFehler(t('plat.form_need_name')); return; }
    if (!form.contactName.trim()) { setFehler(t('plat.form_need_contact')); return; }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.email.trim())) {
      setFehler(t('plat.form_need_email')); return;
    }

    setSendet(true);
    try {
      await submitPlatformLead({
        name: form.name.trim(),
        contactName: form.contactName.trim(),
        email: form.email.trim(),
        phone: form.phone.trim() || null,
        city: form.city.trim() || null,
        expectedMembers: form.expectedMembers.trim() ? Number(form.expectedMembers) : null,
        note: form.note.trim() || null,
      });
      setGesendet(true);
    } catch (err: any) {
      setFehler(err?.message || '?');
    } finally {
      setSendet(false);
    }
  };

  const feld = 'w-full rounded-lg px-4 py-3 outline-none transition-colors';
  const feldStil: React.CSSProperties = {
    background: 'transparent',
    border: `1px solid ${farben.schiefer}`,
    color: '#ffffff',
    fontSize: 15,
  };
  const marke: React.CSSProperties = {
    fontFamily: farben.mono, fontSize: 11, letterSpacing: '0.085em',
    color: farben.nebel, textTransform: 'uppercase', display: 'block', marginBottom: 7,
  };

  if (gesendet) {
    return (
      <div className="rounded-lg p-8 text-center" style={{ border: `1px solid ${farben.schiefer}` }}>
        <div className="w-12 h-12 rounded-lg mx-auto mb-5 flex items-center justify-center"
             style={{ background: farben.blau }}>
          <Check size={22} className="text-white" />
        </div>
        <h3 className="text-white font-light mb-3"
            style={{ fontSize: 27, lineHeight: 1.41, letterSpacing: '-0.012em' }}>
          {t('plat.form_done_title')}
        </h3>
        <p style={{ fontSize: 16, lineHeight: 1.6, color: farben.nebel, maxWidth: 400, margin: '0 auto' }}>
          {t('plat.form_done_text')}
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={senden} className="rounded-lg p-6 md:p-8 space-y-5"
          style={{ border: `1px solid ${farben.schiefer}` }}>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div>
          <label style={marke}>{t('plat.form_assoc')} *</label>
          <input value={form.name} onChange={setzen('name')} className={feld} style={feldStil}
                 placeholder={t('plat.form_assoc_ph')} />
        </div>
        <div>
          <label style={marke}>{t('plat.form_contact')} *</label>
          <input value={form.contactName} onChange={setzen('contactName')} className={feld} style={feldStil} />
        </div>
        <div>
          <label style={marke}>{t('field.email')} *</label>
          <input type="email" value={form.email} onChange={setzen('email')} className={feld} style={feldStil} />
        </div>
        <div>
          <label style={marke}>{t('field.phone')}</label>
          <input value={form.phone} onChange={setzen('phone')} className={feld} style={feldStil} />
        </div>
        <div>
          <label style={marke}>{t('field.city')}</label>
          <input value={form.city} onChange={setzen('city')} className={feld} style={feldStil} />
        </div>
        <div>
          <label style={marke}>{t('plat.form_members')}</label>
          <input type="number" min={0} value={form.expectedMembers} onChange={setzen('expectedMembers')}
                 className={feld} style={feldStil} placeholder="150" />
        </div>
      </div>

      <div>
        <label style={marke}>{t('plat.form_note')}</label>
        <textarea rows={4} value={form.note} onChange={setzen('note')}
                  className={feld + ' resize-none'} style={feldStil}
                  placeholder={t('plat.form_note_ph')} />
      </div>

      {fehler && (
        <div className="flex items-start gap-2.5 rounded-lg p-3"
             style={{ border: '1px solid #7f1d3a', background: 'rgba(127,29,58,0.18)' }}>
          <AlertTriangle size={15} className="mt-0.5 shrink-0" style={{ color: '#ff8fa8' }} />
          <p style={{ fontSize: 14, lineHeight: 1.5, color: '#ff8fa8' }}>{fehler}</p>
        </div>
      )}

      <div className="flex flex-wrap items-center gap-5 pt-1">
        <button type="submit" disabled={sendet}
          className="inline-flex items-center gap-2 px-6 py-4 rounded-lg text-white transition-opacity hover:opacity-90 disabled:opacity-60"
          style={{ background: farben.blau, fontSize: 14 }}>
          {sendet ? <Loader2 size={15} className="animate-spin" /> : <ArrowRight size={15} />}
          {t('plat.form_send')}
        </button>
        <p style={{ fontSize: 13, lineHeight: 1.5, color: farben.nebel, maxWidth: 320 }}>
          {t('plat.form_privacy')}
        </p>
      </div>
    </form>
  );
};

export default Kontaktformular;
