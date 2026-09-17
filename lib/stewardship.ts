import { Neighborhood } from '../types';

// Fuer welche Nachbarschaften ist jemand verantwortlich?
//
// Seit die Betreuungsrechte an der Zuordnung haengen und nicht mehr an der
// Rollenbezeichnung, ist diese Frage die eigentliche Auskunft ueber die
// Befugnis einer Person. Im Adminbereich war sie bisher nirgends zu sehen:
// die Rolle stand auf MEMBER, und dass jemand eine Nachbarschaft fuehrt,
// liess sich nur in der Nachbarschaft selbst nachschlagen.
//
// Die Regel bildet my_neighborhoods() in der Datenbank nach -- dieselben drei
// Felder in derselben Reihenfolge. Weichen beide voneinander ab, zeigt die
// Oberflaeche etwas anderes an, als die Zugriffsregeln durchlassen; genau das
// soll nicht passieren.
export const neighborhoodsLedBy = (
  userId: string | undefined | null,
  neighborhoods: Neighborhood[] | undefined | null
): Neighborhood[] => {
  if (!userId || !neighborhoods?.length) return [];
  return neighborhoods.filter((n) => {
    const liste = Array.isArray(n.contactPersonIds) ? n.contactPersonIds : [];
    return (
      liste.includes(userId) ||
      (n as any).representativeId === userId ||
      n.managerId === userId
    );
  });
};

export const isSteward = (
  userId: string | undefined | null,
  neighborhoods: Neighborhood[] | undefined | null
): boolean => neighborhoodsLedBy(userId, neighborhoods).length > 0;
