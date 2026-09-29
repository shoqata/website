# Prozesslandkarten

Die Karten unter `public/prozesse/*.html` sind mit **archify**
(https://github.com/tt-a1i/archify, MIT) aus den Quellen in diesem
Verzeichnis erzeugt. Jede HTML-Datei traegt alles in sich: kein Server, keine
Abhaengigkeit, laeuft aus einer Datei.

## Warum sie hier entstehen und nicht in der Anwendung

archify ist ein Node-Werkzeug. Es laeuft weder im Browser noch in der
Datenbank, also lassen sich die Karten nicht je Verein zur Laufzeit erzeugen.
Das ist kein Verlust: die Ablaeufe gehoeren der Plattform, nicht dem
einzelnen Verein. Wie ein Beitrag zur Buchung wird, ist bei jedem Verein
gleich -- eine gut gemachte Karte dient deshalb allen. Was sich unterscheidet,
ist nur, welche Karten ein Verein ueberhaupt sieht: das richtet sich nach
seinen gebuchten Modulen.

## Aendern

```
node <pfad>/archify/bin/archify.mjs finalize workflow <quelle>.json <ziel>.html \
  --quality showcase --out-dir belege
cp <ziel>.html ../public/prozesse/
```

`finalize` prueft in vier Stufen und verlangt bei "showcase" NULL Warnungen.
Was dabei aufgefallen ist und beim naechsten Mal Zeit spart:

- Zwei Knoten in derselben Bahn und Spalte ueberlappen. Entweder eine andere
  Spalte oder `yOffset`.
- Wege duerfen einander nicht kreuzen. Ein Ausgang, der zur selben Zeit
  eintritt wie ein anderer, gehoert in dieselbe Spalte -- nicht dahinter.
- Das Bild darf nicht hoeher als breit mal 1.55 sein, sonst passt die Seite
  nicht auf einen 1440x900-Bildschirm. Notfalls `meta.viewBox` verbreitern.
- Die Vorgabelegende spricht Werkzeugsprache ("Agent logic", "Policy"). Fuer
  einen Verein ueber `meta.legend.entries` umbenennen -- kurz, sonst waechst
  die Seite wieder ueber die Hoehe.
- Bei einem zweiten Lauf `--out-dir` setzen: sonst steht der Beleg des ersten
  im Weg und die Browserpruefung scheitert an etwas, das nichts mit dem Bild
  zu tun hat.
