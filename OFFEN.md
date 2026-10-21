# Offene Punkte

Stand 21.10.2026. Was hier steht, ist offen — nicht, was einmal offen war.

## Von dir

### Werbemessung: die IDs fehlen
Meta-Pixel und Google-Conversion sind gebaut und geprüft, aber ohne IDs
lädt nichts (das ist Absicht, siehe `WERBUNG.md`). Drei Werte bei Vercel
unter *Settings → Environment Variables*, danach neu deployen:

```
VITE_META_PIXEL_ID              Pixel-ID aus dem Events Manager
VITE_GOOGLE_ADS_ID              AW-XXXXXXXXX aus Google Ads
VITE_GOOGLE_CONVERSION_LABEL    AW-XXXXXXXXX/abcDEFghi
```

Ohne das Label wird `generate_lead` gemeldet — in GA4 sichtbar, aber
**keine** Ads-Conversion.

### Pingen: Schritt 2 von 4
Die Functions sind deployt, der Webhook antwortet korrekt mit 503 ohne
Geheimnis. Offen:

1. Fünf Geheimnisse im Supabase-Dashboard → *Edge Functions → Secrets*:
   `PINGEN_CLIENT_ID`, `PINGEN_CLIENT_SECRET`, `PINGEN_ORG`,
   `PINGEN_UMGEBUNG=staging`, `PINGEN_WEBHOOK_SECRET`
2. Webhook-URL bei Pingen für alle vier Kategorien eintragen
3. Modul `POSTVERSAND` für einen Verein freischalten, Preis setzen
4. Staging-Lauf (dort wird nichts gedruckt)

Dazu fehlen noch von Pingen: die **Sperrbereiche** (Bild mit den
Millimetern) und die Dokumentation zum **QR-Feld**. Solange letztere
fehlt, zeichnet die Rechnung den Swiss QR selbst — `PINGEN` als
Zahlungsteil wird abgelehnt statt stillschweigend zu wirken.

### Social Media: Meta-App nicht verbunden
`META_APP_ID` und `META_APP_SECRET` sind nicht hinterlegt, verbundene
Konten 0. Und die Berechtigungen `pages_manage_posts`,
`instagram_content_publish`, `business_management` sind bei Meta
prüfpflichtig — **früh beantragen**, das dauert Tage bis Wochen. Anleitung
in `WERBUNG.md`.

### E-Mail: koretini.me
- **SPF, DKIM, DMARC** stehen jetzt (gemessen). Offen: DMARC läuft auf
  `p=none`, sammelt also nur Berichte. Wenn die zeigen, dass alles
  durchgeht, auf `p=quarantine` erhöhen.
- Die fünf Vorstandsadressen stehen auf **„wartet"**: Antworten gehen an
  die privaten Adressen. Nach dem Test der Postal-Routen im Adminbereich
  unter *Vereinsadressen* je Zeile bestätigen.

### Entscheidungen
- **Beiträge öffentlich** steht auf `AUS`. Ob `BETRAEGE` an soll, ist
  deine Entscheidung — ich würde die Mitglieder vorher fragen.
- **Montags-Wochenstart** ist noch offen.
- **Squash der Migrationen**: `grundschema.sql` schliesst die Lücke, die
  422 Dateien bleiben wie sie sind. Mein Rat war, es so zu lassen.

## Im Produkt

### Zeilenregeln: 174 von 190 noch je Zeile ausgewertet
Auf den Lesepfaden von `users` und `payments` ist es behoben (26 s → 0,12 s,
siehe Migration 20261105000000). Die übrigen Regeln tragen das Muster
noch: ein nackter Funktionsaufruf wird pro Zeile ausgewertet, ein
geklammerter einmal.

Alle anderen Tabellen sind klein, die Wirkung also gering — aber
`payment_reports` (7), `event_registrations` (7), `inquiries` (6),
`sponsors` (6) wachsen mit der Nutzung. Ein Rundumschlag ist mechanisch,
berührt aber sicherheitsrelevanten Code und braucht denselben Nachweis je
Tabelle: Sichtbarkeit vorher festhalten, nachher die **IDs** vergleichen,
nicht die Anzahl.

### PayPal
Das Geheimnis liegt sicher, aber **nichts ruft es auf**. Für Mitglieder
ausserhalb der Schweiz gibt es weiterhin nur Überweisung. Der Bezahlvorgang
selbst ist nicht gebaut.

### Albanische Vorlagen
Korrigiert (ein echter Fehler, drei Stellen Ton), aber **ohne
Prüfvermerk**. Der gehört einem Menschen, der die Sprache spricht. Zehn
Vorlagen warten auf das Gegenlesen.

### Masken ohne Übersetzung
`AdminSeo` und die Reiterbeschriftungen in `AdminWebsite` sind deutsch.
Die drei Masken dieser Woche (Briefversand, Brieftarife, Vereinsadressen)
sind dreisprachig.
