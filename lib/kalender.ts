// Kalendereintrag (.ics) fuer einen Anlass. Ohne Uhrzeit ganztaegig, mit
// Uhrzeit zwei Stunden lang -- die Anlaesse haben keine Endzeit.
const zwei = (n: number) => String(n).padStart(2, '0');
const ics = (s: string) => (s || '').replace(/\\/g, '\\\\').replace(/;/g, '\;').replace(/,/g, '\\,').replace(/\r?\n/g, '\\n');

export function anlassIcs(a: { id: string; title: string; date: string; time?: string; location?: string; description?: string }, url?: string): string {
  const [j, m, t] = a.date.slice(0, 10).split('-').map(Number);
  const zeit = (a.time || '').match(/(\d{1,2})[:.](\d{2})/);
  const stempel = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d+/, '');
  let von: string, bis: string;
  if (zeit) {
    const h = Number(zeit[1]), min = Number(zeit[2]);
    von = `DTSTART:${j}${zwei(m)}${zwei(t)}T${zwei(h)}${zwei(min)}00`;
    bis = `DTEND:${j}${zwei(m)}${zwei(t)}T${zwei(Math.min(h + 2, 23))}${zwei(min)}00`;
  } else {
    const n = new Date(Date.UTC(j, m - 1, t + 1));
    von = `DTSTART;VALUE=DATE:${j}${zwei(m)}${zwei(t)}`;
    bis = `DTEND;VALUE=DATE:${n.getUTCFullYear()}${zwei(n.getUTCMonth() + 1)}${zwei(n.getUTCDate())}`;
  }
  return [
    'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//UnityHub//Anlaesse//DE', 'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT', `UID:${a.id}@unityhub.li`, `DTSTAMP:${stempel}`, von, bis,
    `SUMMARY:${ics(a.title)}`,
    a.location ? `LOCATION:${ics(a.location)}` : '',
    `DESCRIPTION:${ics((a.description || '').slice(0, 900) + (url ? `\n${url}` : ''))}`,
    url ? `URL:${url}` : '',
    'END:VEVENT', 'END:VCALENDAR',
  ].filter(Boolean).join('\r\n');
}

export function icsHerunterladen(a: Parameters<typeof anlassIcs>[0], url?: string) {
  const blob = new Blob([anlassIcs(a, url)], { type: 'text/calendar;charset=utf-8' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${(a.title || 'anlass').replace(/[^\w\-]+/g, '_').slice(0, 40)}.ics`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(link.href), 2000);
}
