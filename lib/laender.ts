// Laendercodes, wie land_code() in der Datenbank sie liefert.
export const LAND_NAME: Record<string, string> = {
  XK: 'Kosovo', CH: 'Schweiz', DE: 'Deutschland', AT: 'Österreich',
  NL: 'Niederlande', FR: 'Frankreich', IT: 'Italien', AL: 'Albanien',
  MK: 'Nordmazedonien', SE: 'Schweden', BE: 'Belgien', GB: 'Grossbritannien',
  US: 'USA',
};

// Zuerst die, die im Verein am haeufigsten vorkommen.
export const HAEUFIGE_LAENDER = ['XK', 'CH', 'DE', 'AT', 'NL', 'FR', 'IT', 'SE', 'BE'];

export const landName = (code: string | null | undefined) =>
  !code ? 'ohne Land' : LAND_NAME[code] || code;
