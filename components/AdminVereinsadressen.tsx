import React, { useEffect, useMemo, useState } from 'react';
import {
  Loader2, AlertTriangle, Check, Mail, Server, ClipboardList, RefreshCw,
  ArrowRight, XCircle, Copy,
} from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { weiterleitungenLesen, zuordnen, absenderPruefen } from '../lib/vorstandsmail';

// Vereinsadressen des Vorstands.
//
// Zwei Dinge, die leicht verwechselt werden:
//
//   DIE ADRESSE steht hier. Sie entscheidet, was als Antwortadresse in
//   einer Vorstandsnachricht steht -- valton.rexha@koretini.me statt
//   einer privaten Adresse.
//
//   DIE WEITERLEITUNG richtet der MAILHOST ein, nicht diese Software.
//   Hier steht nur, was dort eingetragen sein muss. Eine Software, die
//   behauptet, sie leite weiter, und es nicht tut, ist schlimmer als
//   eine, die den Auftrag sichtbar liegen laesst.

type Zeile = {
  r_user: string; r_name: string; r_privat: string | null; r_rolle: string | null;
  r_adresse: string | null; r_weiterleitung: string | null; r_aktiv: boolean;
};

const AdminVereinsadressen: React.FC = () => {
  const { t } = useTranslation();
  const [laedt, setLaedt] = useState(true);
  const [fehler, setFehler] = useState('');
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  const [domains, setDomains] = useState<string[]>([]);
  const [eingabe, setEingabe] = useState<Record<string, { adresse: string; ziel: string }>>({});
  const [speichert, setSpeichert] = useState('');
  const [listeText, setListeText] = useState('');
  const [uebernimmt, setUebernimmt] = useState(false);
  const [meldung, setMeldung] = useState('');

  const laden = async () => {
    setLaedt(true); setFehler('');
    const [l, d] = await Promise.all([
      supabase.rpc('vorstand_adressen_liste'),
      supabase.from('tenant_domains').select('domain'),
    ]);
    if ((l as any).error) setFehler((l as any).error.message);
    const r = (l.data as Zeile[]) ?? [];
    setZeilen(r);
    setDomains(((d.data as any[]) ?? []).map(x => String(x.domain)));
    setEingabe(Object.fromEntries(r.map(x => [x.r_user, {
      adresse: x.r_adresse ?? '', ziel: x.r_weiterleitung ?? '',
    }])));
    setLaedt(false);
  };

  useEffect(() => { laden(); }, []);

  const setzen = async (user: string) => {
    const e = eingabe[user];
    if (!e) return;
    const p = absenderPruefen(e.adresse, domains);
    if (!p.ok) { setFehler(p.grund || ''); return; }
    setSpeichert(user); setFehler(''); setMeldung('');
    const { error } = await supabase.rpc('vorstand_adresse_setzen', {
      p_user: user, p_adresse: e.adresse.trim(),
      p_weiterleitung: e.ziel.trim() || null,
    });
    setSpeichert('');
    if (error) { setFehler(error.message); return; }
    laden();
  };

  const abschalten = async (user: string) => {
    const { error } = await supabase.rpc('vorstand_adresse_abschalten', { p_user: user });
    if (error) { setFehler(error.message); return; }
    laden();
  };

  // Die gelieferte Liste in einem Stück übernehmen.
  const geparst = useMemo(() => {
    const { eintraege, unklar } = weiterleitungenLesen(listeText);
    const z = zuordnen(eintraege, zeilen.map(x => ({ id: x.r_user, name: x.r_name })));
    return { eintraege, unklar, ...z };
  }, [listeText, zeilen]);

  const uebernehmen = async () => {
    setUebernimmt(true); setFehler(''); setMeldung('');
    let gut = 0; const schlecht: string[] = [];
    for (const tr of geparst.treffer) {
      const p = absenderPruefen(tr.adresse, domains);
      if (!p.ok) { schlecht.push(`${tr.adresse}: ${p.grund}`); continue; }
      const { error } = await supabase.rpc('vorstand_adresse_setzen', {
        p_user: tr.person.id, p_adresse: tr.adresse, p_weiterleitung: tr.ziel,
      });
      if (error) schlecht.push(`${tr.adresse}: ${error.message}`); else gut++;
    }
    setUebernimmt(false);
    setMeldung(t('vadr.uebernommen', { anzahl: gut }));
    if (schlecht.length) setFehler(schlecht.join(' · '));
    setListeText('');
    laden();
  };

  const mitAdresse = zeilen.filter(z => z.r_aktiv && z.r_adresse);

  const kopieren = () => {
    const text = mitAdresse
      .map(z => `${z.r_adresse} -> ${z.r_weiterleitung || '???'}`).join('\n');
    navigator.clipboard?.writeText(text).then(
      () => setMeldung(t('vadr.kopiert')), () => { /* ohne Zwischenablage eben nicht */ });
  };

  if (laedt) return (
    <div className="flex items-center justify-center py-20 text-stone-400">
      <Loader2 className="animate-spin" size={22} />
    </div>
  );

  return (
    <div className="space-y-6">
      {fehler && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-sm text-red-800 flex gap-3">
          <AlertTriangle size={18} className="shrink-0 mt-0.5" /><span>{fehler}</span>
        </div>
      )}
      {meldung && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-sm text-emerald-900 flex gap-3">
          <Check size={18} className="shrink-0 mt-0.5" /><span>{meldung}</span>
        </div>
      )}

      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <h3 className="font-display text-xl font-bold text-stone-900">{t('vadr.titel')}</h3>
          <p className="text-xs text-stone-500 mt-1 max-w-2xl leading-relaxed">{t('vadr.hinweis')}</p>
        </div>
        <button onClick={laden}
          className="px-4 py-2 bg-stone-100 text-stone-700 rounded-xl text-xs font-bold hover:bg-stone-200 flex items-center gap-2">
          <RefreshCw size={14} /> {t('post.neu_laden')}
        </button>
      </div>

      <div className="bg-white border border-stone-200 rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-stone-50 text-[10px] font-bold text-stone-400 uppercase tracking-widest">
              <tr>
                <th className="text-left px-6 py-3">{t('vadr.sp.person')}</th>
                <th className="text-left px-4 py-3">{t('vadr.sp.adresse')}</th>
                <th className="text-left px-4 py-3">{t('vadr.sp.ziel')}</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-50">
              {zeilen.length === 0 && (
                <tr><td colSpan={4} className="px-6 py-8 text-center text-stone-400 text-sm">
                  {t('vadr.niemand')}
                </td></tr>
              )}
              {zeilen.map(z => {
                const e = eingabe[z.r_user] ?? { adresse: '', ziel: '' };
                const geaendert = e.adresse.trim() !== (z.r_adresse ?? '')
                               || e.ziel.trim() !== (z.r_weiterleitung ?? '');
                return (
                  <tr key={z.r_user} className="hover:bg-stone-50/50">
                    <td className="px-6 py-3">
                      <p className="font-bold text-stone-900">{z.r_name}</p>
                      <p className="text-[11px] text-stone-400">
                        {z.r_rolle ?? '—'}
                        {z.r_privat ? ` · ${z.r_privat}` : ` · ${t('vadr.ohne_privat')}`}
                      </p>
                    </td>
                    <td className="px-4 py-3">
                      <input type="email" value={e.adresse} placeholder={t('vadr.adresse_ph')}
                        onChange={ev => setEingabe({ ...eingabe, [z.r_user]: { ...e, adresse: ev.target.value } })}
                        className="w-full min-w-[14rem] p-2 bg-stone-50 border border-stone-200 rounded-lg text-xs font-mono outline-none focus:border-stone-400" />
                    </td>
                    <td className="px-4 py-3">
                      <input type="email" value={e.ziel} placeholder={t('vadr.ziel_ph')}
                        onChange={ev => setEingabe({ ...eingabe, [z.r_user]: { ...e, ziel: ev.target.value } })}
                        className="w-full min-w-[14rem] p-2 bg-stone-50 border border-stone-200 rounded-lg text-xs font-mono outline-none focus:border-stone-400" />
                    </td>
                    <td className="px-4 py-3 text-right whitespace-nowrap">
                      <button onClick={() => setzen(z.r_user)} disabled={speichert === z.r_user || !geaendert}
                        className="px-3 py-1.5 bg-stone-900 text-white rounded-lg text-xs font-bold hover:bg-stone-800 disabled:opacity-30 inline-flex items-center gap-1.5">
                        {speichert === z.r_user ? <Loader2 size={12} className="animate-spin" /> : null}
                        {t('vadr.setzen')}
                      </button>
                      {z.r_aktiv && z.r_adresse && (
                        <button onClick={() => abschalten(z.r_user)} title={t('vadr.abschalten')}
                          className="ml-2 p-1.5 text-stone-400 hover:text-red-600">
                          <XCircle size={14} />
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Die Liste in einem Stück übernehmen. */}
      <div className="bg-white border border-stone-200 rounded-2xl p-6 space-y-3">
        <div className="flex items-center gap-2">
          <ClipboardList size={16} className="text-stone-400" />
          <h3 className="font-display text-lg font-bold text-stone-900">{t('vadr.liste_titel')}</h3>
        </div>
        <p className="text-xs text-stone-500 leading-relaxed">{t('vadr.liste_hinweis')}</p>
        <textarea rows={5} value={listeText} onChange={e => setListeText(e.target.value)}
          placeholder={'valton.rexha@koretini.me -> valton.rexha@gmail.com'}
          className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl text-xs font-mono outline-none focus:border-stone-400" />
        {listeText.trim() && (
          <div className="text-xs space-y-2">
            {geparst.treffer.length > 0 && (
              <div className="space-y-1">
                {geparst.treffer.map((tr, i) => (
                  <p key={i} className="flex items-center gap-2 text-stone-700">
                    <Check size={12} className="text-emerald-600 shrink-0" />
                    <span className="font-bold">{tr.person.name}</span>
                    <span className="font-mono text-stone-500">{tr.adresse}</span>
                    <ArrowRight size={11} className="text-stone-300" />
                    <span className="font-mono text-stone-500">{tr.ziel}</span>
                  </p>
                ))}
              </div>
            )}
            {/* Nicht zugeordnet heisst: NICHT geraten. Eine Mail beim
                falschen Empfaenger ist kein kleiner Fehler. */}
            {(geparst.offen.length > 0 || geparst.unklar.length > 0) && (
              <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl space-y-1">
                {geparst.offen.map((o, i) => (
                  <p key={i} className="text-amber-800">
                    <span className="font-mono">{o.adresse}</span> — {o.grund}
                  </p>
                ))}
                {geparst.unklar.map((u, i) => (
                  <p key={'u' + i} className="text-amber-800">
                    {t('vadr.unklar', { zeile: u })}
                  </p>
                ))}
              </div>
            )}
            <button onClick={uebernehmen} disabled={uebernimmt || geparst.treffer.length === 0}
              className="px-5 py-2.5 bg-stone-900 text-white rounded-xl text-xs font-bold hover:bg-stone-800 disabled:opacity-30 flex items-center gap-2">
              {uebernimmt ? <Loader2 size={13} className="animate-spin" /> : <Check size={13} />}
              {t('vadr.uebernehmen', { anzahl: geparst.treffer.length })}
            </button>
          </div>
        )}
      </div>

      {/* Was beim Mailhost eingetragen sein MUSS. */}
      <div className="bg-stone-900 rounded-2xl p-6 text-stone-300 space-y-3">
        <div className="flex items-center gap-2">
          <Server size={16} className="text-stone-500" />
          <h3 className="font-display text-lg font-bold text-white">{t('vadr.host_titel')}</h3>
        </div>
        <p className="text-xs leading-relaxed">{t('vadr.host_hinweis')}</p>
        {mitAdresse.length === 0 ? (
          <p className="text-xs text-stone-500 italic">{t('vadr.host_leer')}</p>
        ) : (
          <>
            <div className="bg-black/30 rounded-xl p-4 font-mono text-xs space-y-1 overflow-x-auto">
              {mitAdresse.map(z => (
                <p key={z.r_user} className="whitespace-nowrap">
                  <span className="text-white">{z.r_adresse}</span>
                  <span className="text-stone-600"> → </span>
                  <span className={z.r_weiterleitung ? 'text-emerald-400' : 'text-amber-400'}>
                    {z.r_weiterleitung || t('vadr.ziel_fehlt')}
                  </span>
                </p>
              ))}
            </div>
            <button onClick={kopieren}
              className="px-4 py-2 bg-white/10 text-white rounded-xl text-xs font-bold hover:bg-white/20 flex items-center gap-2">
              <Copy size={13} /> {t('vadr.kopieren')}
            </button>
          </>
        )}
        <p className="text-[11px] text-stone-500 leading-relaxed border-t border-white/10 pt-3 flex items-start gap-2">
          <Mail size={13} className="shrink-0 mt-0.5" />
          <span>{t('vadr.host_absender')}</span>
        </p>
      </div>
    </div>
  );
};

export default AdminVereinsadressen;
