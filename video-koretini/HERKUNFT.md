# Testfilm Koretini

Gebaut am 28.09.2026 mit **hyperframes-student-kit**
(https://github.com/nateherkai/hyperframes-student-kit) und dem Compiler
`hyperframes` (Apache 2.0). Das Kit selbst steht unter MIT plus einer
ausdruecklichen Nutzungserlaubnis, die auch kommerzielle Videos einschliesst
(`licenses/PIPELINE-USE-PERMISSION.txt`).

## Was hier liegt

Nur die Komposition — `index.html` ist der ganze Film. Der Rest entsteht beim
Rendern. `node_modules` und `renders/` sind bewusst nicht mit eingecheckt:
das Kit wiegt 822 MB, die fertige Datei liegt in der Ablage.

## Wieder rendern

```
git clone --depth 1 https://github.com/nateherkai/hyperframes-student-kit.git /tmp/hf-kit
cd /tmp/hf-kit && npm install
cd <dieses Verzeichnis>
node /tmp/hf-kit/node_modules/.bin/hyperframes check
node /tmp/hf-kit/node_modules/.bin/hyperframes render --quality draft --output renders/film.mp4
```

Braucht Node 22+, FFmpeg und Chrome. Der Lauf dauerte hier 6 Sekunden fuer
15 Sekunden Film.

## Was die Pruefung zu Recht bemaengelt hat

1. **Selektoren in Vorlagen-Zeichenketten** (`"#akt" + nr`) bringen den
   Buendler zum Absturz — sein CSS-Leser kann die eingesetzte Variable nicht
   aufloesen. Jeder Selektor steht jetzt ausgeschrieben da.
2. **Elemente blieben beim Vorspulen sichtbar.** Eine Tween beschreibt den
   Weg, nicht den Zustand davor und danach; nach jedem Abgang steht deshalb
   ein `tl.set()`.
3. **Kontrast.** Das graue „/ 331" lag bei 1,45:1 und war nicht lesbar.
4. **Ueberlappung**, von mir im Bild gefunden, nicht vom Werkzeug: kursives
   Playfair in 900 ragt weit ueber seinen Zeilenkasten hinaus. Bei 300px lief
   die Zeile darunter mitten in die Ziffern. Jetzt 230px mit echtem Abstand.

## Die Zahlen

Alle am 28.09.2026 in der Datenbank gemessen: 340 Mitglieder,
27 Nachbarschaften, 78 von 331 haben den Beitrag 2026 geleistet. Wer den Film
neu rendert, muss sie nachfuehren — sie stehen in `index.html` und nirgends
sonst, und genau dort koennen sie auseinanderlaufen.
