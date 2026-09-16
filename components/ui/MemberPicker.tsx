import React, { useMemo, useRef, useState } from 'react';
import { Search, X, Star, Check } from 'lucide-react';
import { UserProfile } from '../../types';
import { useTranslation } from '../../context/LanguageContext';

interface Props {
  users: UserProfile[];
  value: string[];                 // ausgewaehlte Benutzer-Kennungen, erste = federfuehrend
  onChange: (ids: string[]) => void;
  max?: number;                    // hoechstens so viele Treffer anzeigen
  placeholder?: string;
  single?: boolean;                // nur eine Person waehlbar
  filter?: (u: UserProfile) => boolean;  // zusaetzliche Einschraenkung
  includeInactive?: boolean;
}

// Auswahl mehrerer Personen mit Suche.
//
// Ein Auswahlfeld mit allen Mitgliedern ist bei dreihundert Namen unbrauchbar:
// man scrollt, statt zu finden. Hier wird getippt und gefiltert, Ausgewaehlte
// stehen als entfernbare Marken darueber. Die erste Person gilt als
// federfuehrend -- sie erscheint dort, wo bisher genau eine Person stand.
const MemberPicker: React.FC<Props> = ({ users, value, onChange, max = 40, placeholder, single, filter, includeInactive }) => {
  const { t } = useTranslation();
  const [term, setTerm] = useState('');
  const [open, setOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const selected = useMemo(
    () => value.map((id) => users.find((u) => u.id === id)).filter(Boolean) as UserProfile[],
    [value, users]
  );

  const matches = useMemo(() => {
    const q = term.trim().toLowerCase();
    const pool = users.filter((u) =>
      (includeInactive || u.membershipStatus !== 'INACTIVE') &&
      !value.includes(u.id) &&
      (!filter || filter(u)));
    const hit = (u: UserProfile) =>
      !q ||
      (u.displayName || '').toLowerCase().includes(q) ||
      (u.email || '').toLowerCase().includes(q) ||
      (u.city || '').toLowerCase().includes(q) ||
      (u.phone || '').toLowerCase().includes(q);
    return pool.filter(hit).sort((a, b) => (a.displayName || '').localeCompare(b.displayName || ''));
  }, [users, term, value, filter, includeInactive]);

  const shown = matches.slice(0, max);
  const rest = matches.length - shown.length;

  const add = (id: string) => {
    onChange(single ? [id] : [...value, id]);
    setTerm('');
    if (single) setOpen(false); else inputRef.current?.focus();
  };
  const remove = (id: string) => onChange(value.filter((v) => v !== id));
  const makePrimary = (id: string) => onChange([id, ...value.filter((v) => v !== id)]);

  return (
    <div>
      {/* Ausgewaehlte */}
      {selected.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-2.5">
          {selected.map((u, i) => (
            <span
              key={u.id}
              className={`inline-flex items-center gap-1.5 pl-2.5 pr-1.5 py-1.5 rounded-xl text-xs font-bold border transition-colors ${
                i === 0 && !single ? 'bg-rose-50 border-primary/30 text-primary'
                : single ? 'bg-rose-50 border-primary/30 text-primary'
                : 'bg-stone-100 border-stone-200 text-stone-600'
              }`}
            >
              {i === 0 && !single && <Star size={11} fill="currentColor" />}
              {u.displayName || u.email}
              {i !== 0 && !single && (
                <button
                  type="button"
                  onClick={() => makePrimary(u.id)}
                  title={t('picker.make_primary')}
                  className="p-0.5 hover:text-primary transition-colors"
                >
                  <Star size={11} />
                </button>
              )}
              <button
                type="button"
                onClick={() => remove(u.id)}
                title={t('picker.remove')}
                className="p-0.5 rounded-md hover:bg-black/10 transition-colors"
              >
                <X size={12} />
              </button>
            </span>
          ))}
        </div>
      )}

      {/* Suche -- im Einzelmodus nur, solange niemand gewaehlt ist */}
      {!(single && selected.length > 0) && (
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-stone-400 pointer-events-none" size={15} />
        <input
          ref={inputRef}
          value={term}
          onChange={(e) => { setTerm(e.target.value); setOpen(true); }}
          onFocus={() => setOpen(true)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && shown[0]) { e.preventDefault(); add(shown[0].id); }
            if (e.key === 'Escape') setOpen(false);
          }}
          placeholder={placeholder || t('picker.search')}
          className="w-full pl-9 pr-3 py-3 bg-stone-50 border border-stone-200 rounded-xl outline-none text-sm focus:border-primary/40 transition-colors"
        />
      </div>
      )}

      {open && !(single && selected.length > 0) && (
        <div className="mt-2 border border-stone-200 rounded-xl bg-white shadow-lg max-h-56 overflow-y-auto custom-scrollbar">
          {shown.length === 0 && (
            <p className="px-4 py-4 text-xs text-stone-400 italic">{t('picker.no_match')}</p>
          )}
          {shown.map((u) => (
            <button
              type="button"
              key={u.id}
              onClick={() => add(u.id)}
              className="w-full text-left px-4 py-2.5 hover:bg-stone-50 flex items-center justify-between gap-3 transition-colors border-b border-stone-50 last:border-b-0"
            >
              <span className="min-w-0">
                <span className="block text-sm text-stone-800 font-medium truncate">{u.displayName || u.email}</span>
                <span className="block text-[10px] text-stone-400 truncate">
                  {[u.email, u.city].filter(Boolean).join(' · ')}
                </span>
              </span>
              <Check size={14} className="text-stone-300 shrink-0" />
            </button>
          ))}
          {rest > 0 && (
            <p className="px-4 py-2.5 text-[10px] text-stone-400 bg-stone-50 border-t border-stone-100">
              {t('picker.more', { count: rest })}
            </p>
          )}
        </div>
      )}
    </div>
  );
};

export default MemberPicker;
