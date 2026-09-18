import React, { useState, useEffect } from 'react';
import { COUNTRY_OPTIONS, OTHER_COUNTRY, matchCountry } from '../../lib/countries';
import { useTranslation } from '../../context/LanguageContext';

interface Props {
  value?: string | null;
  onChange: (value: string) => void;
  className?: string;
}

// Land als Kachelauswahl.
//
// Vorher ein Auswahlmenue: elf Laender hinter einem Klick verborgen, und auf
// dem Telefon oeffnet sich dafuer ein Rad ueber den halben Bildschirm. Als
// Kacheln steht die ganze Auswahl offen da und ein Land ist mit einem
// einzigen Tippen gesetzt -- bei elf Eintraegen ist das die kuerzere Bedienung.
//
// Dabei ist ein Fehler der alten Fassung aufgefallen: die Wahl "Anderes"
// setzte den Wert auf leer, worauf das Freitextfeld sofort wieder verschwand.
// Die Option war damit nicht benutzbar. Ob "Anderes" gewaehlt wurde, ist
// deshalb ein eigener Zustand und nicht aus dem Wert abgeleitet -- ein leerer
// Wert bedeutet "noch nichts eingetippt", nicht "nichts gewaehlt".
//
// Steht im Datensatz etwas, das nicht in der Liste vorkommt -- im Bestand etwa
// "DE" oder "Holland" --, ordnet matchCountry es zu. Bleibt es ein Sonderfall,
// erscheint es im Freitextfeld, statt still verlorenzugehen.
const CountrySelect: React.FC<Props> = ({ value, onChange, className }) => {
  const { t } = useTranslation();
  const matched = matchCountry(value);
  const fremderWert = !!value && !matched;

  const [andereGewaehlt, setAndereGewaehlt] = useState(fremderWert);

  // Wird von aussen ein Land aus der Liste gesetzt -- etwa beim Wechsel auf ein
  // anderes Mitglied --, faellt die Auswahl auf dieses Land zurueck.
  useEffect(() => {
    if (matched) setAndereGewaehlt(false);
    else if (fremderWert) setAndereGewaehlt(true);
  }, [matched, fremderWert]);

  const zeigeFreitext = andereGewaehlt || fremderWert;
  const aktivesLand = !andereGewaehlt && matched ? matched : '';

  const feld =
    className ||
    'w-full p-4 bg-white border border-stone-200 rounded-xl outline-none focus:border-primary/40 transition-colors';

  const kachel = (aktiv: boolean) =>
    `px-3.5 py-2 rounded-xl text-xs font-bold border transition-colors ${
      aktiv
        ? 'bg-stone-900 text-white border-stone-900'
        : 'bg-white text-stone-500 border-stone-200 hover:border-stone-400 hover:text-stone-700'
    }`;

  return (
    <div className="space-y-2.5">
      <div className="flex flex-wrap gap-2">
        {COUNTRY_OPTIONS.map((c) => (
          <button
            key={c}
            type="button"
            onClick={() => { setAndereGewaehlt(false); onChange(c); }}
            className={kachel(aktivesLand === c)}
          >
            {c}
          </button>
        ))}
        <button
          type="button"
          onClick={() => {
            setAndereGewaehlt(true);
            // Ein Land aus der Liste wird geraeumt, damit das Freitextfeld
            // leer startet. Ein bereits freier Wert bleibt stehen.
            if (matched) onChange('');
          }}
          className={kachel(zeigeFreitext)}
        >
          {t('country.other')}
        </button>
      </div>

      {zeigeFreitext && (
        <input
          autoFocus
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          placeholder={t('country.other_label')}
          className={feld}
        />
      )}
    </div>
  );
};

export default CountrySelect;
