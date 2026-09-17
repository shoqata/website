import React from 'react';
import { COUNTRY_OPTIONS, OTHER_COUNTRY, matchCountry } from '../../lib/countries';
import { useTranslation } from '../../context/LanguageContext';

interface Props {
  value?: string | null;
  onChange: (value: string) => void;
  className?: string;
}

// Land als Auswahl statt als freies Feld.
//
// Steht im Datensatz etwas, das nicht in der Liste vorkommt -- im Bestand etwa
// "DE" oder "Holland" --, ordnet matchCountry es zu. Bleibt es ein Sonderfall,
// springt die Auswahl auf "Anderes" und der urspruengliche Wert steht im
// Freitextfeld daneben, statt still verlorenzugehen.
const CountrySelect: React.FC<Props> = ({ value, onChange, className }) => {
  const { t } = useTranslation();
  const matched = matchCountry(value);
  const isOther = !!value && !matched;
  const selected = matched || (isOther ? OTHER_COUNTRY : '');

  const base =
    className ||
    'w-full p-4 bg-white border border-stone-200 rounded-xl outline-none focus:border-primary/40 transition-colors';

  return (
    <div className="space-y-2">
      <select
        value={selected}
        onChange={(e) => onChange(e.target.value === OTHER_COUNTRY ? '' : e.target.value)}
        className={base}
      >
        <option value="">{t('common.select')}</option>
        {COUNTRY_OPTIONS.map((c) => (
          <option key={c} value={c}>{c}</option>
        ))}
        <option value={OTHER_COUNTRY}>{t('country.other')}</option>
      </select>

      {selected === OTHER_COUNTRY && (
        <input
          autoFocus
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder={t('country.other_label')}
          className={base}
        />
      )}
    </div>
  );
};

export default CountrySelect;
