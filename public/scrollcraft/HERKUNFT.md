# scrollcraft

Der Laufzeitkern stammt aus **scroll-craft** von Nate Herk,
https://github.com/nateherkai/scroll-craft, MIT-Lizenz (siehe LICENSE).

Uebernommen sind ausschliesslich `engine/scrollcraft.js` und
`engine/scrollcraft.css`. Die CSS-Datei ist unveraendert; an der JS-Datei
ist **ein Zusatz** angebracht (siehe unten). Das uebrige Projekt dort ist eine
Anleitung fuer Programmierwerkzeuge und kein Programmteil; es gehoert nicht
in diese Anwendung.

Der Kern hat **keine Abhaengigkeiten** und erzeugt kein Markup. Er liest
`data-sc-*`-Attribute an vorhandenem HTML und steuert sie aus einem einzigen
Scrollwert. Gestartet wird er ausdruecklich mit `ScrollCraft.mount(wurzel)`;
er startet nicht von selbst.

Beides liegt bewusst unter `public/` und nicht im Bundle: geladen wird es nur
fuer Vereine, die das Modul "Startseite Premium" nutzen. Alle anderen zahlen
die 1211 Zeilen nicht mit.

## Der Zusatz: destroy()

Der Kern kennt kein Abhaengen. Bildschleife und Fensterzuhoerer bleiben fuer
die Lebensdauer des Dokuments bestehen — in einem Dokument mit einer Seite
richtig, in einer Einseiten-Anwendung ein Fehler: wer die Startseite
verlaesst, laesst eine Schleife auf abgehaengtem Markup zurueck, und beim
Zurueckkehren kaeme eine zweite dazu.

Angebracht sind daher vier Stellen, alle mit `Zusatz` kommentiert:

1. in `mount()` ein Totschalter `scTot` und eine Sammelstelle `scAbhaengen`
2. `tick()` kehrt sofort zurueck, sobald `scTot` gesetzt ist
3. die vier Fensterzuhoerer (`scroll`, `pointermove`, `focusin`, `resize`)
   laufen ueber `scLauscher()` und sind damit wieder abhaengbar
4. `api.destroy()` setzt den Schalter, haengt die Zuhoerer ab, nimmt die
   Instanz aus `ScrollCraft.instances` und entfernt `sc-ready`

Nachgemessen im Browser: nach `destroy()` stehen 0 Instanzen, `sc-ready` ist
weg, der Fortschrittsbalken reagiert nicht mehr auf Scrollen, und ein
erneutes `mount()` ergibt wieder genau eine Instanz statt zwei.

## Bei einer Aktualisierung

Beide Dateien ersetzen, **den Zusatz erneut anbringen** und pruefen, ob
`ScrollCraft.mount` und die benutzten Attribute (`data-sc-act`, `-span`,
`-cue`, `-kinetic`, `-count`, `-drift`, `-stage`, `-progress`) noch gelten.
