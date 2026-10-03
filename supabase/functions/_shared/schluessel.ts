// Welchen Geheimschluessel benutzt eine Funktion?
//
// Supabase hinterlegt inzwischen von selbst SUPABASE_SECRET_KEYS -- ein
// JSON-Verzeichnis der neuen sb_secret_-Schluessel, mit "default" als
// Standardeintrag. Daneben steht weiter der alte
// SUPABASE_SERVICE_ROLE_KEY, der abgeschaltet werden soll.
//
// Erst der neue, dann der alte. Solange beide da sind, aendert sich
// nichts; faellt der alte weg, laufen die Funktionen weiter. Genau das ist
// die Voraussetzung dafuer, den geleakten Alt-Schluessel ueberhaupt
// deaktivieren zu koennen -- vorher haetten Passwort-Zuruecksetzen,
// Postausgang, Meta-Anmeldung und Social-Veroeffentlichung im selben
// Moment stillgestanden.
//
// Ein frueherer Versuch suchte SUPABASE_SECRET_KEY in der EINZAHL. Die
// gibt es nicht; der Rueckfall haette also immer gegriffen, und das
// Abschalten waere trotzdem schiefgegangen.
export function geheimschluessel(): string {
  const verzeichnis = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (verzeichnis) {
    try {
      const d = JSON.parse(verzeichnis) as Record<string, string>;
      const k = d["default"] ?? Object.values(d)[0];
      if (k) return k;
    } catch {
      // Unlesbares Verzeichnis darf die Funktion nicht umbringen -- dann
      // eben der alte Schluessel, solange es ihn noch gibt.
    }
  }
  const einzeln = Deno.env.get("SUPABASE_SECRET_KEY");       // von Hand gesetzt
  const alt     = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // Alt-Schluessel
  const k = einzeln ?? alt;
  if (!k) throw new Error("Kein Geheimschluessel verfuegbar: weder SUPABASE_SECRET_KEYS noch SUPABASE_SERVICE_ROLE_KEY gesetzt.");
  return k;
}
