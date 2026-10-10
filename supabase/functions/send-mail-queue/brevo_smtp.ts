// Brevo auch ueber SMTP erreichen koennen.
//
// Zwei Gruende, warum das nicht bloss eine zweite Variante ist:
//
// 1. Der Nutzer hat einen SMTP-Schluessel (xsmtpsib-…). Der funktioniert
//    an der Programmschnittstelle NICHT -- sie braucht xkeysib-… Statt
//    ihn in die Verwaltung zurueckzuschicken, kann die Software den
//    Schluessel nehmen, den er hat.
//
// 2. Die IP-Beschraenkung, an der die Schnittstelle scheitert, ist eine
//    Einstellung FUER die Schnittstelle. Ob sie auch beim SMTP-Versand
//    greift, weiss ich nicht -- deshalb wird es gemessen und nicht
//    behauptet.
//
// Die Pruefung geht bis zur Anmeldung und bricht dort ab. Kein MAIL
// FROM, kein DATA, also kein Versand -- auch nicht versehentlich.

// Wo der Schalter wirklich sitzt. Einmal benannt, damit die beiden
// Meldungen nicht auseinanderlaufen.
export const BREVO_SCHALTER =
  "Einstellungen → Sicherheit → Autorisierte IPs, Abschnitt \"Blockierung "
  + "nicht autorisierter IP-Adressen\". Dort stehen ZWEI Zeilen, "
  + "API-Schlüssel und SMTP-Schlüssel, je mit eigenem Schalter — "
  + "beide deaktivieren.";

type Draht = { lesen: () => Promise<string>; schreiben: (s: string) => Promise<void> };

const draht = (c: Deno.Conn): Draht => {
  const aus = new TextEncoder(); const ein = new TextDecoder();
  return {
    async lesen() {
      // SMTP-Antworten koennen mehrzeilig sein (250-PIPELINING, 250-SIZE,
      // dann 250 OK). Bis zur Zeile ohne Bindestrich nach dem Code lesen,
      // sonst liest der naechste Schritt eine fremde Antwort.
      let alles = "";
      const puffer = new Uint8Array(4096);
      for (let i = 0; i < 24; i++) {
        const n = await c.read(puffer);
        if (n === null) break;
        alles += ein.decode(puffer.subarray(0, n));
        const zeilen = alles.trimEnd().split("\r\n");
        const letzte = zeilen[zeilen.length - 1] ?? "";
        if (/^\d{3} /.test(letzte)) break;
      }
      return alles.trimEnd();
    },
    async schreiben(s) { await c.write(aus.encode(s + "\r\n")); },
  };
};

export async function brevoSmtpPruefen(
  login: string, schluessel: string,
): Promise<string> {
  const wirt = "smtp-relay.brevo.com";
  // Zwei Namen fuer eine Verbindung: startTls verlangt ausdruecklich eine
  // TCP-Verbindung, waehrend nach der Aufwertung eine allgemeine daraus
  // wird. Ein einziger Name dafuer geht nicht durch die Typpruefung.
  let tcp: Deno.TcpConn | null = null;
  let rohe: Deno.Conn | null = null;
  try {
    // Erreichbarkeit zuerst. Scheitert das, liegt es an Supabase und
    // nicht an Brevo -- ein Unterschied, der die Suche halbiert.
    tcp = await Deno.connect({ hostname: wirt, port: 587 });
    rohe = tcp;
  } catch (e) {
    return `Port 587 nicht erreichbar (${e instanceof Error ? e.message : e}). `
      + "Edge Functions dürfen offenbar keine SMTP-Verbindung öffnen — dann bleibt "
      + "nur die Programmschnittstelle mit einem xkeysib-Schlüssel.";
  }

  try {
    let d = draht(tcp!);
    const gruss = await d.lesen();
    if (!gruss.startsWith("220")) return `Unerwarteter Gruss: ${gruss.slice(0, 80)}`;

    await d.schreiben("EHLO unityhub.li");
    const ehlo1 = await d.lesen();

    // Die Adresse, die BREVO sieht -- nicht die, die wir vermuten.
    // Viele SMTP-Server nennen sie in der Begruessung oder in der
    // EHLO-Antwort. Das ist die genaueste Messung, die hier moeglich
    // ist: dieselbe Verbindung, derselbe Augenblick, kein fremder
    // Dienst dazwischen. Ohne sie waere die Frage "welche IP?" nur
    // ueber die Brevo-Verwaltung beantwortbar, also mit einer
    // Rueckfrage je Versuch.
    const gesehen = (gruss + " " + ehlo1)
      .match(/\b(?:\d{1,3}\.){3}\d{1,3}\b|\b(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\b/i)?.[0];
    if (!/STARTTLS/i.test(ehlo1)) {
      return "Server bietet kein STARTTLS an — unverschlüsselt wird hier nicht "
        + `angemeldet. Antwort: ${ehlo1.slice(0, 120)}`;
    }

    await d.schreiben("STARTTLS");
    const bereit = await d.lesen();
    if (!bereit.startsWith("220")) return `STARTTLS abgelehnt: ${bereit.slice(0, 80)}`;

    // Ab hier verschluesselt. Ohne diesen Schritt ginge der Schluessel
    // im Klartext ueber die Leitung.
    const sicher = await Deno.startTls(tcp!, { hostname: wirt });
    rohe = sicher;
    d = draht(sicher);
    await d.schreiben("EHLO unityhub.li");
    const ehlo2 = await d.lesen();
    if (!ehlo2.startsWith("250")) return `EHLO nach TLS abgelehnt: ${ehlo2.slice(0, 80)}`;

    if (!login || !schluessel) {
      return "Verbindung und TLS stehen. Für die Anmeldung fehlen noch "
        + "BREVO_SMTP_LOGIN und BREVO_SMTP_KEY."
        + (gesehen ? ` Herkunft laut Brevo: ${gesehen}.` : "");
    }

    // AUTH LOGIN: Benutzer und Schluessel je als base64, getrennt.
    await d.schreiben("AUTH LOGIN");
    const f1 = await d.lesen();
    if (!f1.startsWith("334")) return `AUTH LOGIN nicht angeboten: ${f1.slice(0, 80)}`;
    await d.schreiben(btoa(login));
    const f2 = await d.lesen();
    if (!f2.startsWith("334")) return `Benutzer abgelehnt: ${f2.slice(0, 90)}`;
    await d.schreiben(btoa(schluessel));
    const f3 = await d.lesen();

    // Hier wird bewusst NICHT weitergemacht. Nach 235 waere der naechste
    // Schritt MAIL FROM -- und damit ein Versand.
    await d.schreiben("QUIT").catch(() => {});

    if (f3.startsWith("235")) {
      return "in Ordnung — Anmeldung über SMTP gelingt, es wurde nichts verschickt."
        + (gesehen ? ` Herkunft: ${gesehen}.` : "");
    }
    // Gemessen: Brevo prueft die Herkunft auch beim SMTP-Versand und
    // antwortet "525 5.7.1 Unauthorized IP address". Ich hatte das
    // Gegenteil angenommen -- SMTP melde sich mit Benutzer und
    // Schluessel an und frage nicht nach dem Ort. Diese Annahme war der
    // Grund, diesen Weg ueberhaupt zu bauen; sie hat nicht gehalten.
    //
    // Das Muster deckt bewusst mehrere Schreibweisen ab. Brevo
    // schreibt an der Schnittstelle "unrecognised IP" (britisch) und
    // hier "Unauthorized IP" (amerikanisch); ein Muster fuer nur eine
    // davon liess diese Antwort als blosses "Anmeldung abgelehnt"
    // durch -- und schickte damit zur Schluesselsuche statt zur
    // Einstellung, an der es wirklich liegt.
    if (/\b5\.7\.1\b|unauthori[sz]ed ip|unrecogni[sz]ed ip|authoris?ed_ips/i.test(f3)) {
      // Der Schalter liegt NICHT auf der Seite mit der Adressliste --
      // dort kann man nur freigeben. Gemessen, warum Freigeben nicht
      // traegt: sechs Aufrufe ergaben sechs IPv4-Adressen in vier
      // Bereichen, dazu zwanzig IPv6-Adressen in Brevos eigenem
      // Protokoll. Und es sind ZWEI Schalter; wer nur den fuer die
      // Schnittstelle abschaltet, steht hier wieder.
      return "Die IP-Beschränkung greift auch bei SMTP — Brevo antwortet "
        + `"${f3.slice(0, 60).trim()}". Freigeben trägt nicht: die Adresse `
        + "wechselt mit jedem Aufruf. Abschalten unter "
        + BREVO_SCHALTER;
    }
    return `Anmeldung abgelehnt: ${f3.slice(0, 140)}`;
  } catch (e) {
    return `SMTP-Fehler — ${e instanceof Error ? e.message : e}`;
  } finally {
    try { rohe?.close(); } catch { /* schon zu */ }
  }
}


// ----------------------------------------------------------- Der Versand
//
// Beim API-Weg baut Brevo die Nachricht; hier muss sie selbst gebaut
// werden. Vier Dinge gehen dabei leicht schief, und jedes davon ergibt
// einen Brief, der zugestellt aussieht und beim Empfaenger kaputt
// ankommt:
//
//   Umlaute im Betreff. "Beitragsrechnung für 2026" roh in den Kopf
//   geschrieben ergibt "f??r" oder eine abgewiesene Nachricht. Koepfe
//   sind nach Norm siebenbittig; nicht-ASCII braucht die =?UTF-8?B?-Form.
//
//   Ein Punkt am Zeilenanfang. Eine einzelne Zeile "." beendet die
//   Nachricht. Hier tritt der Fall nicht ein, weil alle Teile base64
//   kodiert sind und das base64-Alphabet keinen Punkt kennt -- der Test
//   dazu hat das gezeigt, nachdem er zuerst das Gegenteil behauptete.
//   Das Stopfen bleibt trotzdem stehen: es kostet nichts und traegt,
//   falls spaeter auf quoted-printable gewechselt wird.
//
//   Zeilenlaenge. Base64 ohne Umbruch ergibt bei einem QR-Rechnungs-PDF
//   eine Zeile von 60'000 Zeichen; die Norm erlaubt 998.
//
//   Zeilenenden. SMTP verlangt CRLF. Ein blosses \n wird je nach Server
//   verschluckt oder verdoppelt.

const KOPF_GRENZE = 998;


// Nicht-ASCII im Kopf kodieren -- aber nur dann. Ein reiner ASCII-Betreff
// bleibt lesbar, auch in Protokollen und Fehlermeldungen.
export const kopfwert = (v: string): string => {
  const s = String(v ?? "").replace(/[\r\n]+/g, " ").trim();
  if (!s) return "";
  // eslint-disable-next-line no-control-regex
  if (!/[^\x20-\x7E]/.test(s) && s.length < KOPF_GRENZE) return s;
  const roh = new TextEncoder().encode(s);
  let b = "";
  for (let i = 0; i < roh.length; i++) b += String.fromCharCode(roh[i]);
  // In Haeppchen: ein kodiertes Wort darf samt Huelle 75 Zeichen haben.
  // 45 Zeichen Rohtext ergeben 60 Zeichen base64 und passen darunter.
  const teile: string[] = [];
  for (let i = 0; i < b.length; i += 45) {
    teile.push(`=?UTF-8?B?${btoa(b.slice(i, i + 45))}?=`);
  }
  return teile.join("\r\n ");
};

// Base64 in Zeilen von 76 Zeichen.
export const umbrechen = (b64: string): string =>
  (b64.match(/.{1,76}/g) ?? []).join("\r\n");

const alsB64 = (text: string): string => {
  const roh = new TextEncoder().encode(text);
  let b = "";
  for (let i = 0; i < roh.length; i++) b += String.fromCharCode(roh[i]);
  return umbrechen(btoa(b));
};

export type Brief = {
  von: string; vonName: string; an: string; antwortAn?: string | null;
  betreff: string; html: string; text?: string | null;
  anhaenge?: { filename: string; content: string }[];
};

export function briefBauen(b: Brief, grenze: string): string {
  const z: string[] = [];
  const anhaenge = (b.anhaenge ?? []).filter(a => a?.content);

  z.push(`From: ${b.vonName ? `${kopfwert(b.vonName)} <${b.von}>` : b.von}`);
  z.push(`To: ${b.an}`);
  if (b.antwortAn) z.push(`Reply-To: ${b.antwortAn}`);
  z.push(`Subject: ${kopfwert(b.betreff)}`);
  z.push("MIME-Version: 1.0");

  const innen = `alt_${grenze}`;
  const koerper: string[] = [];

  // Text und HTML als Alternativen. Der Textteil ist kein Beiwerk: ein
  // Brief ohne ihn wird von manchen Filtern als Werbung gewertet.
  const zweiteilig = !!b.text;
  const alternativ = () => {
    if (!zweiteilig) {
      koerper.push("Content-Type: text/html; charset=UTF-8",
                   "Content-Transfer-Encoding: base64", "", alsB64(b.html));
      return;
    }
    koerper.push(`Content-Type: multipart/alternative; boundary="${innen}"`, "",
      `--${innen}`, "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: base64", "", alsB64(b.text!), "",
      `--${innen}`, "Content-Type: text/html; charset=UTF-8",
      "Content-Transfer-Encoding: base64", "", alsB64(b.html), "",
      `--${innen}--`);
  };

  if (!anhaenge.length) {
    alternativ();
    z.push(...koerper);
  } else {
    z.push(`Content-Type: multipart/mixed; boundary="${grenze}"`, "",
           `--${grenze}`);
    alternativ();
    z.push(...koerper);
    for (const a of anhaenge) {
      const name = String(a.filename ?? "anhang.pdf");
      z.push("", `--${grenze}`,
        `Content-Type: application/pdf; name="${name}"`,
        "Content-Transfer-Encoding: base64",
        `Content-Disposition: attachment; filename="${name}"`, "",
        // Der Inhalt ist schon base64; nur umbrechen, nicht doppelt kodieren.
        umbrechen(String(a.content).replace(/\s+/g, "")));
    }
    z.push("", `--${grenze}--`);
  }

  // Punkt-Stopfen: eine Zeile, die mit einem Punkt beginnt, bekommt einen
  // zweiten. Der Empfaenger entfernt ihn wieder. Ohne das bricht die
  // Nachricht bei einem solchen Absatz mitten ab.
  return z.join("\r\n").split("\r\n")
    .map(l => (l.startsWith(".") ? "." + l : l)).join("\r\n");
}

export async function brevoSmtpSenden(
  login: string, schluessel: string, b: Brief,
): Promise<void> {
  const wirt = "smtp-relay.brevo.com";
  let tcp: Deno.TcpConn | null = null;
  let offen: Deno.Conn | null = null;
  try {
    tcp = await Deno.connect({ hostname: wirt, port: 587 });
    offen = tcp;
    let d = draht(tcp);
    const gruss = await d.lesen();
    if (!gruss.startsWith("220")) throw new Error(`Gruss: ${gruss.slice(0, 80)}`);
    await d.schreiben("EHLO unityhub.li");
    await d.lesen();
    await d.schreiben("STARTTLS");
    const bereit = await d.lesen();
    if (!bereit.startsWith("220")) throw new Error(`STARTTLS: ${bereit.slice(0, 80)}`);
    const sicher = await Deno.startTls(tcp, { hostname: wirt });
    offen = sicher;
    d = draht(sicher);
    await d.schreiben("EHLO unityhub.li");
    await d.lesen();

    await d.schreiben("AUTH LOGIN"); await d.lesen();
    await d.schreiben(btoa(login)); await d.lesen();
    await d.schreiben(btoa(schluessel));
    const ang = await d.lesen();
    if (!ang.startsWith("235")) {
      // Denselben Hinweis auch hier. Sonst steht in der Fehlerspalte
      // der Warteschlange "Anmeldung: 525 5.7.1 …" -- richtig, aber es
      // sagt niemandem, wo der Schalter sitzt.
      const ip = /\b5\.7\.1\b|unauthori[sz]ed ip/i.test(ang)
        ? ` Die IP-Beschränkung im Brevo-Konto ist noch an: ${BREVO_SCHALTER}`
        : "";
      throw new Error(`Anmeldung: ${ang.slice(0, 140)}.${ip}`);
    }

    await d.schreiben(`MAIL FROM:<${b.von}>`);
    const mf = await d.lesen();
    if (!mf.startsWith("250")) throw new Error(`Absender: ${mf.slice(0, 140)}`);
    await d.schreiben(`RCPT TO:<${b.an}>`);
    const rc = await d.lesen();
    if (!rc.startsWith("250") && !rc.startsWith("251")) {
      throw new Error(`Empfänger: ${rc.slice(0, 140)}`);
    }
    await d.schreiben("DATA");
    const da = await d.lesen();
    if (!da.startsWith("354")) throw new Error(`DATA: ${da.slice(0, 140)}`);

    const grenze = `g_${crypto.randomUUID().replace(/-/g, "")}`;
    await d.schreiben(briefBauen(b, grenze) + "\r\n.");
    const ende = await d.lesen();
    // Das ist die einzige Antwort, die "angenommen" bedeutet. Alles
    // andere als Erfolg zu verbuchen war bei Postal der Fehler, der
    // wochenlang unentdeckt blieb.
    if (!ende.startsWith("250")) throw new Error(`Abgewiesen: ${ende.slice(0, 200)}`);
    await d.schreiben("QUIT").catch(() => {});
  } finally {
    try { offen?.close(); } catch { /* schon zu */ }
  }
}


// Welche IPv4-Adressen benutzt Supabase nach aussen?
//
// Die Frage entsteht, weil Brevo nur das Freigeben einzelner Adressen
// anbietet und nicht das Abschalten der Pruefung. Ueber IPv6 ist die
// Frage sinnlos -- gemessen zwanzig verschiedene Adressen. Ueber IPv4
// koennte sie beantwortbar sein, denn smtp-relay.brevo.com hat keinen
// AAAA-Eintrag; die SMTP-Verbindung MUSS also ueber IPv4 laufen, und
// dort ist der Vorrat an Adressen erfahrungsgemaess kleiner.
//
// Brevos Begruessung nennt die gesehene Adresse nicht, also wird sie
// bei einem Echodienst erfragt -- aber ausdruecklich ueber IPv4, sonst
// antwortet er mit der IPv6-Adresse und die Messung ginge am Fall
// vorbei. Dazu wird der A-Eintrag selbst aufgeloest und die Verbindung
// zur Zahl aufgebaut, statt dem Namen zu folgen.
//
// Nach aussen geht dabei nur die Frage nach der eigenen Adresse. Keine
// Vereinsdaten, kein Schluessel, keine Empfaengeradresse.
export async function ipv4Herkunft(admin: any, versuche = 2): Promise<string> {
  const wirt = "api.ipify.org";
  const gesehen = new Map<string, number>();
  let fehler = "";

  for (let i = 0; i < versuche; i++) {
    let c: Deno.Conn | null = null;
    try {
      const a = (await Deno.resolveDns(wirt, "A"))[0];
      if (!a) { fehler = "kein A-Eintrag"; break; }
      c = await Deno.connect({ hostname: a, port: 80 });
      await c.write(new TextEncoder().encode(
        `GET / HTTP/1.1\r\nHost: ${wirt}\r\nConnection: close\r\n`
        + "User-Agent: unityhub-diagnose\r\n\r\n"));
      let roh = ""; const puffer = new Uint8Array(2048);
      for (let k = 0; k < 8; k++) {
        const n = await c.read(puffer);
        if (n === null) break;
        roh += new TextDecoder().decode(puffer.subarray(0, n));
      }
      const ip = roh.split("\r\n\r\n").pop()?.trim()
        .match(/\b(?:\d{1,3}\.){3}\d{1,3}\b/)?.[0];
      if (ip) gesehen.set(ip, (gesehen.get(ip) ?? 0) + 1);
      else fehler = `keine Adresse in der Antwort (${roh.slice(0, 60)})`;
    } catch (e) {
      fehler = e instanceof Error ? e.message : String(e);
    } finally {
      try { c?.close(); } catch { /* schon zu */ }
    }
  }

  if (!gesehen.size) return `nicht messbar — ${fehler || "unbekannt"}`;

  // Hier stand zuerst das Urteil aus DIESEM Aufruf, und es war falsch.
  // Sechs Messungen ergaben sechs Mal dieselbe Adresse, und daraus wurde
  // "Freigeben ist aussichtsreich". Vier Aufrufe spaeter waren es vier
  // verschiedene Adressen in drei Bereichen. Die Adresse ist je
  // Behaelter fest, nicht je Plattform -- ein Behaelter lebt Minuten,
  // und innerhalb eines Aufrufs sieht man darum immer nur eine.
  //
  // Ein Urteil aus einem Aufruf kann diese Frage nicht beantworten. Es
  // braucht das Gedaechtnis ueber Aufrufe hinweg; genau dafuer gibt es
  // versand_herkunft. Waere das nicht korrigiert worden, haette die
  // Meldung in die stundenlange Pflege einer Freigabeliste geschickt,
  // die nie vollstaendig wird.
  let alle: { ip: string; n: number }[] = [];
  for (const ip of gesehen.keys()) {
    const { data, error } = await admin.rpc("herkunft_vermerken", { p_ip: ip });
    if (error) return `${[...gesehen.keys()].join(", ")} · nicht bewertbar — `
      + `das Gedächtnis ist nicht erreichbar (${error.message})`;
    alle = (data ?? []).map((z: any) => ({ ip: z.r_ip, n: z.r_anzahl }));
  }

  const jetzt = [...gesehen.keys()].join(", ");
  const zahl = alle.length;
  // Der Bereich zaehlt mit: Adressen in verschiedenen /8 stammen aus
  // verschiedenen Bloecken des Anbieters. Dass 16.62.x, 16.63.x UND
  // 51.34.x auftreten, sagt mehr als die blosse Anzahl -- es gibt keinen
  // zusammenhaengenden Bereich, den man eintragen koennte.
  const bereiche = new Set(alle.map(z => z.ip.split(".").slice(0, 2).join(".")));
  const urteil = zahl <= 1
    ? "erst eine Adresse bekannt — für ein Urteil zu früh, die Messung sammelt weiter"
    : zahl <= 4 && bereiche.size === 1
      ? `${zahl} Adressen in einem Bereich (${[...bereiche][0]}.x) — eine Freigabeliste `
        + "könnte tragen, sicher ist es nicht"
      : `${zahl} verschiedene Adressen in ${bereiche.size} Bereichen `
        + `(${[...bereiche].slice(0, 5).join(", ")}) — eine Freigabeliste trägt nicht`;
  return `jetzt ${jetzt} · bisher gesehen: ${urteil}`;
}
