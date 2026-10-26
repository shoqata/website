#!/usr/bin/env python3
"""Bildschirmfotos aus dem Demo-Verein in die Praesentationen einbauen.

Die Folien 10, 11, 15-18 zeigten bisher nachgezeichnete Platzhalter der
Oberflaeche. Sie bekommen echte Aufnahmen; dazu drei neue Folien (Spenden,
Rollen, Benachrichtigungen). Folie 12 wird an die Aufnahmeantraege
angepasst, Folie 5 an die Herkunft der Bilder.

Quelle der Bilder: design/bilder/rollen/folie/{de,sq}-*.jpg, aufgenommen im
Demo-Verein (erfundene Daten), Vereinsjahr 2026.

Laeuft auf der jeweils unveraenderten Fassung aus git (git show HEAD:...),
damit ein zweiter Lauf nicht doppelt einbaut.

    python3 design/bilder/einbauen.py
"""
import base64, re, subprocess, pathlib

WURZEL = pathlib.Path(__file__).resolve().parents[2]
BILDER = WURZEL / 'design/bilder/rollen/folie'

def bild(name):
    return 'data:image/jpeg;base64,' + base64.b64encode((BILDER / name).read_bytes()).decode()

def shot(name, alt):
    return f'<div class="shot"><img src="{bild(name)}" alt="{alt}"></div>'

CSS = """
/* Bildschirmfotos aus dem Demo-Verein (einbauen.py) */
.split > .shot img{height:auto; max-height:104mm; object-fit:cover; object-position:top left}
.quad{display:grid; grid-template-columns:repeat(4,1fr); gap:5mm; margin-top:2mm}
.quad figure{margin:0}
.quad .shot img{height:auto; aspect-ratio:1/1; object-fit:cover; object-position:top left}
.quad figcaption{text-align:left; margin:0 0 2.5mm}
.quad p{font-size:9.5pt; color:var(--ink-2); margin:2.5mm 0 0; line-height:1.4}
.herkunft{align-self:stretch; max-width:none; font-family:"Bricolage Grotesque",sans-serif; font-size:8pt; letter-spacing:.09em;
  text-transform:uppercase; color:var(--ink-3); margin:2.5mm 0 0; text-align:right}
"""

TEXTE = {
  'de': {
    'datei': 'design/praesentation.html',
    'alt': {10: 'Mitgliederliste in der Verwaltung', 11: 'Finanzen mit Einnahmen und offenen Rechnungen 2026',
            15: 'Bilanz 2026 in der Buchhaltung', 16: 'Nachbarschaften mit Mitgliederzahl',
            17: 'Übersicht mit überfälligen Rechnungen', 18: 'Startseite eines Mitglieds'},
    'herkunft': 'Demo-Verein · erfundene Daten · Vereinsjahr 2026',
    'note_alt': 'Alle Bildschirmfotos stammen aus einer Installation, die heute im Betrieb ist — rund 350 Mitglieder, echte Rechnungen, geführte Buchhaltung. Der Verein darin ist nicht Ihrer: Ihre Seite trägt Ihren Namen, Ihr Logo und Ihre Farben.',
    'note_neu': 'Die Bilder der öffentlichen Seite stammen aus einer Installation, die heute im Betrieb ist — rund 350 Mitglieder, echte Rechnungen, geführte Buchhaltung. Die Bilder aus der Verwaltung und den Mitgliederbereichen stammen aus unserem Demo-Verein: erfundene Namen, damit keine echten Mitgliederdaten auf einer Folie stehen. Ihre Seite trägt Ihren Namen, Ihr Logo und Ihre Farben.',
    'f12_alt': '<li><b>Neue Anmeldungen</b> landen als „ausstehend“ im Vorstand, nicht sofort in der Liste</li>',
    'f12_neu': '<li><b>Anmeldung als Antrag</b> — der Vorstand sieht mögliche Doppelte (E-Mail, Telefon, Name) und gibt frei; die Jahresrechnung entsteht dabei gleich mit</li>',
    'spenden': ('Demo — Spenden', 'Spenden sammeln, verbuchen und bescheinigen',
      'Ein Aufruf mit Ziel und Fortschritt, Spenden mit QR-Referenz — und im Februar keine Nacht mit Excel für die Bescheinigungen.',
      ['<b>Spendenaufrufe</b> mit Ziel, Zeitraum und Fortschritt — auf der Website, wenn Sie es wollen',
       '<b>Jede Spende mit eigener Referenz</b>: die Bank ordnet den Eingang selbst zu',
       '<b>Jahres-Spendenbescheinigung</b> je Spender auf einem Blatt, für alle in einem PDF',
       '<b>Anonyme Spenden</b> bleiben anonym, auch in der Verwaltung'],
      'Spendenaufrufe und Jahres-Spendenbescheinigungen'),
    'rollen': ('Demo — vier Rollen', 'Dieselbe Plattform, vier Blickwinkel', [
       ('Verwaltung', 'Mitglieder, Beiträge, Buchhaltung, Website — alles an einem Ort.', 'admin-uebersicht-ausschnitt', 'Übersicht der Verwaltung'),
       ('Vorstand', 'Sitzungen, Protokolle, Anfragen — ohne die Beitragsverwaltung.', 'vorstand', 'Startseite des Vorstands'),
       ('Nachbarschaft vor Ort', 'Wer in der eigenen Nachbarschaft offen ist, Barzahlungen melden.', 'vertreter', 'Ansicht der verantwortlichen Person einer Nachbarschaft'),
       ('Mitglied', 'Eigener Status, eigene Rechnungen, Protokolle und Anlässe.', 'mitglied-ausschnitt', 'Startseite eines Mitglieds')]),
    'push': ('Demo — Benachrichtigungen', 'Neues kommt von selbst — auch aufs Handy',
      'Niemand muss nachsehen, ob eine Rechnung, ein Anlass oder ein Aufnahmeantrag da ist.',
      ['<b>Glocke in der App</b> mit allem, was neu ist — gelesen, ungelesen, ein Tipp führt hin',
       '<b>Push auf den Sperrbildschirm</b>, wenn die App installiert ist',
       '<b>Jeder bekommt nur seins</b>: das Mitglied seine Rechnung, der Vorstand die neue Spende',
       '<b>Eigene App je Verein</b> mit Ihrem Namen und Logo auf dem Startbildschirm'],
      ('Glocke', 'Benachrichtigungen eines Mitglieds'), ('Mitgliederbereich', 'Mitgliederbereich auf dem Telefon')),
  },
  'sq': {
    'datei': 'design/prezantimi-sq.html',
    'alt': {10: 'Lista e anëtarëve në administratë', 11: 'Financat me të hyrat dhe faturat e hapura 2026',
            15: 'Bilanci 2026 në kontabilitet', 16: 'Lagjet me numrin e anëtarëve',
            17: 'Pasqyra me faturat e vonuara', 18: 'Ballina e një anëtari'},
    'herkunft': 'Shoqatë demo · të dhëna të trilluara · viti 2026',
    'note_alt': 'Të gjitha pamjet janë nga një instalim që sot është në punë — rreth 350 anëtarë, fatura reale, kontabilitet i mbajtur. Shoqata në to nuk është e juaja: faqja juaj mban emrin, logon dhe ngjyrat tuaja.',
    'note_neu': 'Pamjet e faqes publike janë nga një instalim që sot është në punë — rreth 350 anëtarë, fatura reale, kontabilitet i mbajtur. Pamjet nga administrata dhe zona e anëtarëve janë nga shoqata jonë demo: emra të trilluar, që asnjë e dhënë e vërtetë e anëtarëve të mos dalë në prezantim. Faqja juaj mban emrin, logon dhe ngjyrat tuaja.',
    'f12_alt': '<li><b>Regjistrimet e reja</b> shkojnë te kryesia si „në pritje“, jo menjëherë në listë</li>',
    'f12_neu': '<li><b>Regjistrimi si kërkesë</b> — kryesia sheh dyfishimet e mundshme (email, telefon, emër) dhe miraton; fatura vjetore krijohet njëherësh</li>',
    'spenden': ('Demo — donacionet', 'Mblidhni, regjistroni dhe vërtetoni donacionet',
      'Një thirrje me qëllim dhe ecuri, donacione me referencë QR — dhe në shkurt asnjë natë me Excel për vërtetimet.',
      ['<b>Thirrjet për donacione</b> me qëllim, periudhë dhe ecuri — në ueb-faqe, nëse e dëshironi',
       '<b>Çdo donacion me referencën e vet</b>: banka e cakton pagesën vetë',
       '<b>Vërtetimi vjetor i donacioneve</b> për çdo donator në një fletë, për të gjithë në një PDF',
       '<b>Donacionet anonime</b> mbeten anonime, edhe në administratë'],
      'Thirrjet për donacione dhe vërtetimet vjetore'),
    'rollen': ('Demo — katër role', 'E njëjta platformë, katër këndvështrime', [
       ('Administrata', 'Anëtarët, anëtarësia, kontabiliteti, ueb-faqja — gjithçka në një vend.', 'admin-uebersicht-ausschnitt', 'Pasqyra e administratës'),
       ('Kryesia', 'Mbledhjet, procesverbalet, kërkesat — pa administrimin e anëtarësisë.', 'vorstand', 'Ballina e kryesisë'),
       ('Lagjja në terren', 'Kush në lagjen e vet nuk ka paguar, njoftimi i pagesave në dorë.', 'vertreter', 'Pamja e personit përgjegjës të lagjes'),
       ('Anëtari', 'Statusi i vet, faturat e veta, procesverbalet dhe ngjarjet.', 'mitglied-ausschnitt', 'Ballina e një anëtari')]),
    'push': ('Demo — njoftimet', 'Të rejat vijnë vetë — edhe në telefon',
      'Askush nuk ka nevojë të kontrollojë nëse ka ardhur një faturë, një ngjarje apo një kërkesë për anëtarësim.',
      ['<b>Zilja në aplikacion</b> me gjithçka të re — e lexuar, e palexuar, një prekje të çon atje',
       '<b>Njoftim në ekranin e kyçur</b>, kur aplikacioni është i instaluar',
       '<b>Secili merr vetëm të vetat</b>: anëtari faturën e tij, kryesia donacionin e ri',
       '<b>Aplikacion i veçantë për çdo shoqatë</b> me emrin dhe logon tuaj në ekranin kryesor'],
      ('Zilja', 'Njoftimet e një anëtari'), ('Zona e anëtarëve', 'Zona e anëtarëve në telefon')),
  },
}

ZIEL_FOLIE = {10: 'admin-mitglieder', 11: 'admin-finanzen', 15: 'admin-buchhaltung',
              16: 'admin-nachbarschaften', 17: 'admin-uebersicht', 18: 'mitglied'}

def folie(s, n):
    m = re.search(r'<section class="slide[^"]*" data-n="%d">.*?</section>' % n, s, re.S)
    assert m, n
    return m

def ui_ersetzen(sec, html):
    # Der Platzhalter ist ein <div class="ui">...</div> mit verschachtelten divs.
    i = sec.index('<div class="ui">')
    tiefe, j = 0, i
    for t in re.finditer(r'<div\b|</div>', sec[i:]):
        tiefe += 1 if t.group(0) == '<div' else -1
        if tiefe == 0:
            j = i + t.end(); break
    return sec[:i] + html + sec[j:]

def ticks(punkte):
    return '\n'.join(f'        <li>{p}</li>' for p in punkte)

def bauen(sprache):
    T = TEXTE[sprache]
    s = subprocess.run(['git', 'show', 'HEAD:' + T['datei']], cwd=WURZEL, capture_output=True, text=True, check=True).stdout
    s = s.replace('</style>', CSS + '</style>', 1)

    # Platzhalter -> Bild
    for n, name in ZIEL_FOLIE.items():
        m = folie(s, n)
        neu = ui_ersetzen(m.group(0), '<div>' + shot(f'{sprache}-{name}.jpg', T['alt'][n])
                          + f'<p class="herkunft">{T["herkunft"]}</p></div>')
        s = s[:m.start()] + neu + s[m.end():]

    assert T['note_alt'] in s and T['f12_alt'] in s
    s = s.replace(T['note_alt'], T['note_neu'], 1).replace(T['f12_alt'], T['f12_neu'], 1)

    eb, h2, sub, pk, alt = T['spenden']
    spenden = f'''<section class="slide" data-n="X">
  <p class="eyebrow">{eb}</p>
  <h2>{h2}</h2>
  <div class="split">
    <div>
      <p class="sub" style="margin-bottom:6mm">{sub}</p>
      <ul class="ticks">
{ticks(pk)}
      </ul>
    </div>
    <div>{shot(f"{sprache}-admin-spenden.jpg", alt)}<p class="herkunft">{T["herkunft"]}</p></div>
  </div>
</section>
'''
    eb, h2, karten = T['rollen']
    figuren = '\n'.join(
        f'    <figure><figcaption>{titel}</figcaption>{shot(f"{sprache}-{bildname}.jpg", alt)}<p>{text}</p></figure>'
        for titel, text, bildname, alt in karten)
    rollen = f'''<section class="slide" data-n="X">
  <p class="eyebrow">{eb}</p>
  <h2>{h2}</h2>
  <div class="quad">
{figuren}
  </div>
  <p class="herkunft">{T["herkunft"]}</p>
</section>
'''
    eb, h2, sub, pk, (k1, a1), (k2, a2) = T['push']
    push = f'''<section class="slide" data-n="X">
  <p class="eyebrow">{eb}</p>
  <h2>{h2}</h2>
  <div class="split" style="grid-template-columns:1fr 1.25fr">
    <div>
      <p class="sub" style="margin-bottom:6mm">{sub}</p>
      <ul class="ticks">
{ticks(pk)}
      </ul>
    </div>
    <div class="phones">
      <figure><div class="ph"><img src="{bild(f"{sprache}-mitglied-glocke-handy.jpg")}" alt="{a1}"></div><figcaption>{k1}</figcaption></figure>
      <figure><div class="ph"><img src="{bild(f"{sprache}-mitglied-handy.jpg")}" alt="{a2}"></div><figcaption>{k2}</figcaption></figure>
    </div>
  </div>
</section>
'''
    # Einfuegen: Spenden nach 17, Rollen nach 19, Benachrichtigungen nach 21
    for nach, neu in ((21, push), (19, rollen), (17, spenden)):
        m = folie(s, nach)
        s = s[:m.end()] + '\n\n' + neu + s[m.end():]

    # Neu durchnummerieren
    zaehler = iter(range(1, 1000))
    s = re.sub(r'(<section class="slide[^"]*" data-n=")[^"]*(")', lambda m: m.group(1) + str(next(zaehler)) + m.group(2), s)
    (WURZEL / T['datei']).write_text(s)
    print(T['datei'], 'Folien:', len(re.findall(r'<section class="slide', s)), f'{len(s)//1024} KB')

for sprache in ('de', 'sq'):
    bauen(sprache)
