// Geburtstage und Mitgliedschafts-Jubilaeen in den naechsten Tagen.
export type Anlass = { id: string; name: string; email?: string | null; art: 'GEBURTSTAG' | 'JUBILAEUM'; datum: Date; jahre: number };

export function anstehend(
  leute: { id: string; displayName?: string | null; email?: string | null; birthdate?: string | null; joinedAt?: string | null; membershipStatus?: string | null }[],
  heute = new Date(), tage = 7,
): Anlass[] {
  const start = new Date(heute.getFullYear(), heute.getMonth(), heute.getDate());
  const ende = new Date(start.getTime() + tage * 864e5);
  const raus: Anlass[] = [];
  const naechster = (m: number, t: number) => {
    let d = new Date(start.getFullYear(), m, t);
    if (d < start) d = new Date(start.getFullYear() + 1, m, t);
    return d;
  };
  for (const p of leute) {
    if (p.membershipStatus === 'INACTIVE') continue;
    const g = (p.birthdate || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (g) {
      const d = naechster(Number(g[2]) - 1, Number(g[3]));
      const jahre = d.getFullYear() - Number(g[1]);
      if (d < ende && jahre > 0 && jahre < 120) raus.push({ id: p.id, name: p.displayName || '', email: p.email, art: 'GEBURTSTAG', datum: d, jahre });
    }
    const j = (p.joinedAt || '').match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (j) {
      const d = naechster(Number(j[2]) - 1, Number(j[3]));
      const jahre = d.getFullYear() - Number(j[1]);
      // Runde Jubilaeen: 5, 10, 15 …
      if (d < ende && jahre > 0 && jahre % 5 === 0) raus.push({ id: p.id, name: p.displayName || '', email: p.email, art: 'JUBILAEUM', datum: d, jahre });
    }
  }
  return raus.sort((a, b) => a.datum.getTime() - b.datum.getTime() || a.name.localeCompare(b.name));
}
