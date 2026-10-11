// Welche Felder ein Nachbarschaftsverantwortlicher pflegen darf.
//
// Diese Liste stand zweimal: einmal als Katalog in der Adminmaske, die
// die Haekchen anbietet, und einmal implizit in der Betreuungsmaske als
// Satz von Eingabefeldern. Sie sind auseinandergelaufen, und das ist
// gemessen und nicht vermutet:
//
//   freigegeben in der Einstellung : 18
//   angeboten in der Maske         : 11
//   fehlten                        :  7
//
//   firstName, lastName, displayName, salutation, phoneSecondary,
//   sprache, address
//
// Darunter der Name. Ein Verantwortlicher, der einen Schreibfehler im
// Nachnamen eines Mitglieds berichtigen will, fand kein Feld dafuer --
// obwohl die Administration es ausdruecklich erlaubt hatte. Von aussen
// sah das aus wie ein fehlendes Recht, war aber eine fehlende Maske.
//
// Schlimmer als die Luecke ist die Richtung des Fehlers: der Admin
// kreuzt "Vorname" an, die Maske aendert sich nicht, und niemand
// erfaehrt davon. Eine Einstellung, die nichts bewirkt, ist schlechter
// als keine.
//
// Darum eine Liste, aus der beide Masken lesen, und ein Test, der
// vergleicht, ob die Betreuungsmaske jeden Schluessel daraus anbietet.

export type VertreterFeld = { key: string; name: string; hinweis?: string };

export const VERTRETER_GRUPPEN: { titel: string; felder: VertreterFeld[] }[] = [
  { titel: 'Person', felder: [
    { key: 'salutation', name: 'Anrede' },
    { key: 'firstName', name: 'Vorname' },
    { key: 'lastName', name: 'Nachname' },
    { key: 'displayName', name: 'Angezeigter Name' },
    { key: 'birthdate', name: 'Geburtsdatum' },
    { key: 'sprache', name: 'Sprache' },
  ] },
  { titel: 'Erreichbarkeit', felder: [
    { key: 'street', name: 'Strasse' },
    { key: 'zip', name: 'PLZ' },
    { key: 'city', name: 'Ort' },
    { key: 'country', name: 'Land' },
    { key: 'address', name: 'Adresszeile' },
    { key: 'phone', name: 'Telefon' },
    { key: 'phoneSecondary', name: 'Telefon (zweit)' },
    { key: 'email', name: 'E-Mail' },
  ] },
  { titel: 'Zuordnung', felder: [
    { key: 'membershipCategory', name: 'Kategorie' },
    { key: 'familyId', name: 'Familie' },
    { key: 'nicht_oeffentlich', name: 'Nicht öffentlich zeigen' },
    { key: 'invoiceDeliveryMethod', name: 'Rechnungsweg (E-Mail / Post)' },
  ] },
  { titel: 'Geld — mit Bedacht', felder: [
    { key: 'billingGroup', name: 'Beitragsgruppe',
      hinweis: 'bestimmt, was jemand zahlt' },
    { key: 'customAnnualFee', name: 'Eigener Beitrag',
      hinweis: 'überschreibt die Beitragsgruppe' },
  ] },
];

export const VERTRETER_FELD_KEYS: string[] =
  VERTRETER_GRUPPEN.flatMap(g => g.felder.map(f => f.key));

// address wird nicht eigens eingegeben: es wird aus street mitgefuehrt,
// weil in den Daten beide Spalten dasselbe enthalten. Der Test nimmt
// diesen einen Schluessel darum aus -- ausdruecklich und begruendet,
// damit nicht spaeter jemand eine stille Ausnahme daraus macht.
export const OHNE_EIGENES_FELD = ['address'];
