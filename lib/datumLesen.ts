// Ein Datum aus der Datenbank lesen, egal in welcher Form es ankommt:
// Date, Zeitstempel-Objekt ({seconds} / toDate) oder Text. Postgres liefert
// "2026-10-13 14:23:40+00" -- mit Leerzeichen und kurzem Versatz, das
// versteht new Date() nicht in jedem Browser ("Invalid Date").
export function datumLesen(v: any): Date | null {
  if (!v) return null;
  if (v instanceof Date) return isNaN(v.getTime()) ? null : v;
  if (typeof v?.toDate === 'function') return v.toDate();
  if (typeof v?.seconds === 'number') return new Date(v.seconds * 1000);
  if (typeof v === 'string') {
    const s = v.trim().replace(' ', 'T').replace(/(T\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?[+-]\d{2})$/, '$1:00');
    const d = new Date(s);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}
