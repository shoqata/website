# Social Media und Werbemessung

Zwei Dinge, die leicht in einen Topf geraten:

| | |
|---|---|
| **Veröffentlichen** | Beiträge auf Facebook und Instagram schreiben und planen. Ist gebaut, aber **nicht verbunden**. |
| **Messen** | Sehen, welche Anzeige zu einer Anfrage führt. Ist gebaut, braucht **die IDs**. |

Anzeigen *schalten* kann diese Software nicht und soll es nicht. Das
geschieht im Werbeanzeigenmanager von Meta bzw. in Google Ads. Hier wird
nur gemessen, was dabei herauskommt.

Stand beim Schreiben dieser Datei (gemessen, nicht angenommen):
verbundene Konten **0**, `META_APP_ID`/`META_APP_SECRET` **nicht
hinterlegt**, Pixel- und Conversion-ID **nicht hinterlegt**.

---

## 1. Beiträge veröffentlichen (Facebook, Instagram)

Was es kann: Beiträge im Adminbereich unter *Social AI* schreiben,
planen und veröffentlichen — Facebook-Seite und Instagram-Business-Konto.
Gepostet wird über die Graph API v21.0.

### Einzurichten

**a) Meta-App anlegen** auf https://developers.facebook.com → *Business*.

**b) Zwei Geheimnisse hinterlegen**, im Supabase-Dashboard unter
*Edge Functions → Secrets*:

```
META_APP_ID        die App-ID
META_APP_SECRET    das App-Geheimnis
```

Nicht in `.env`, nicht im Quelltext: ein Seiten-Token erlaubt, im Namen
des Vereins zu posten. Es ist der nächste Schlüssel, der sonst öffentlich
lesbar herumliegt.

**c) Rückleitadresse in der Meta-App eintragen** (*Valid OAuth Redirect
URIs*):

```
https://rabpkwwozkwsnyoivocy.supabase.co/functions/v1/meta-oauth
```

**d) Berechtigungen.** Die Anwendung fragt diese an:

```
pages_show_list, pages_read_engagement, pages_manage_posts,
instagram_basic, instagram_content_publish, business_management
```

Davon sind `pages_manage_posts`, `instagram_content_publish` und
`business_management` bei Meta **prüfpflichtig** (App Review). Solange die
App im Entwicklungsmodus ist, funktioniert es nur mit Konten, die als
Tester eingetragen sind. Das ist der Teil, der Zeit braucht — Tage bis
Wochen, nicht Minuten.

**e) Verbinden.** Adminbereich → *Social AI* → Konto verbinden. Wer
verbinden darf, entscheidet die Datenbank: `social_verbinden_starten()`
legt eine einmalige Kennung an und bindet sie an den Verein des
angemeldeten Benutzers. Ohne diesen Schritt könnte jeder die
Rückleitadresse aufrufen und seine Seite an einen fremden Verein hängen.

---

## 2. Werbemessung (Meta-Pixel, Google-Conversion)

Misst zwei Dinge auf **unityhub.li**: wie viele Besucher kommen, und wer
von ihnen das Anfrageformular abschickt.

### Einzurichten

Drei Werte als Umgebungsvariablen bei Vercel (*Project → Settings →
Environment Variables*), danach **neu deployen** — `VITE_`-Werte werden
in das Bündel eingebacken:

```
VITE_META_PIXEL_ID              die Pixel-ID aus dem Events Manager
VITE_GOOGLE_ADS_ID              AW-XXXXXXXXX aus Google Ads
VITE_GOOGLE_CONVERSION_LABEL    AW-XXXXXXXXX/abcDEFghi   (optional)
```

Zum **Conversion-Label**: ohne es wird `generate_lead` gemeldet — in GA4
sichtbar, aber **keine** Ads-Conversion. Erst mit Label wird
`gtag('event','conversion', {send_to: …})` gesendet, und nur das zählt
Google Ads als Conversion. Es steht in Google Ads beim Erstellen der
Conversion-Aktion, in der Form `AW-123456789/AbCdEfGhIj`.

### Drei Regeln, die nicht einstellbar sind

**Nur auf der Betreiberseite.** Auf einer Vereinsdomain lädt nichts, auch
nicht mit Zustimmung und eingetragenen IDs. Die Mitglieder von
koretini.me haben sich bei ihrem Verein angemeldet, nicht bei einer
Werbeplattform. Das ist keine Einstellung, sondern eine Grenze — sie
steht in `darfMessen()` und ist mit einem Test festgehalten.

**Nur mit Zustimmung.** Der Cookie-Hinweis speicherte bisher „accepted"
oder „declined", und **niemand las die Antwort** — er fragte nach
Zustimmung zu nichts. Jetzt wird vor dem Laden gelesen; wer ablehnt,
bekommt wirklich nichts. Die Skripte werden erst nach dem Klick
eingefügt, nicht beim Seitenaufbau mit einem Schalter davor: ein
geladenes Meta-Skript nimmt Verbindung auf, bevor irgendein Schalter
greift.

**Nur mit ID.** Ohne ID gibt es nichts zu melden, und ein Skript ohne
Ziel zu laden wäre reine Verlangsamung.

### Nachsehen, ob es wirkt

1. unityhub.li öffnen, im Hinweis **Annehmen** drücken.
2. Entwicklerwerkzeuge → *Network*, nach `fbevents.js` und `gtag/js`
   suchen. Beide da heisst: geladen. Beide fehlen und keine ID ist
   gesetzt — dann ist das richtig.
3. Anfrageformular abschicken. In Metas *Events Manager* → *Test Events*
   erscheint `Lead`, in Google Ads die Conversion (mit Verzögerung).
4. In einem neuen privaten Fenster **Ablehnen** drücken: beide Skripte
   dürfen **nicht** erscheinen. Das ist der Test, der wirklich etwas
   beweist.

### Eigener Zähler daneben

Unabhängig davon zählt die Software selbst — ohne Cookies, serverseitig
gehasht, Besuche, Verweildauer, Herkunft, Ziele. Im Adminbereich unter
*Besuche & SEO*, beim Betreiber über alle Vereinswebsites. Das Ziel
`ANFRAGE` wird dort auch ohne Meta und Google gezählt. Wenn die
Werbekonten also einmal nicht messen, ist die Zahl nicht verloren.

---

## 3. Was fehlt, wenn es schnell gehen soll

Ehrlich geordnet nach dem, was am schnellsten Wirkung zeigt:

1. **Pixel- und Conversion-ID setzen** — Minuten. Danach ist jede
   Anzeige auswertbar.
2. **Google Ads und Meta-Anzeigen schalten** — in deren eigenen
   Werkzeugen. Die Software liefert die Zielseite und die Messung.
3. **Meta-App-Prüfung beantragen** — das Posten auf Facebook und
   Instagram braucht sie, und sie dauert. Früh beantragen.
4. **Die Landingpage** ist fertig und misst: Anfrageformular,
   Vereinsmodule, Produktbilder, dreisprachig.
