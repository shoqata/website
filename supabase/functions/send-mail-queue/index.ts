// Die Warteschlange abarbeiten und tatsaechlich versenden.
//
// Seit der Umstellung von Firebase auf Supabase gab es keinen Versandweg mehr:
// sendEmail() schrieb in eine Tabelle, die es nicht gibt, und scheiterte
// still. Diese Funktion ist der fehlende Weg nach draussen.
//
// Die Zugangsdaten des Postausgangs stehen in der Umgebung der Funktion und
// nirgends sonst -- nicht im Bundle, nicht in der Datenbank, nicht im
// Quelltext. Das war die ausdrueckliche Bedingung: "die Eigener SMTP-Server
// muessen sicher sein, da sonst das misbruacht werden kann."
//
// Benoetigte Umgebungsvariablen:
//   POSTAL_URL, POSTAL_API_KEY   bevorzugt, siehe unten
//   BREVO_API_KEY                fuer Microsoft-Empfaenger, siehe unten
//   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
//
// ZWEI WEGE HINAUS, und der Grund dafuer ist gemessen:
//
// SMTP geht aus diesem Rechenzentrum nicht zu jedem Anbieter. Bei
// mail.helvico.ch sind 25, 465 und 587 von einem gewoehnlichen Anschluss
// aus offen -- von hier aus wird 465 abgewiesen und 587 antwortet
// ueberhaupt nicht. Das ist eine Sperre gegen Rechenzentren, und sie
// laesst sich von dieser Seite nicht umgehen: Edge Functions haben keine
// feste Absenderadresse, die man freischalten lassen koennte.
//
// HTTPS geht. Dieselbe Maschine betreibt Postal (postalserver.io), und
// dessen Schnittstelle auf 443 antwortete aus dem Supabase-Netz in 16
// Millisekunden. Deshalb hat POSTAL_URL Vorrang vor SMTP, wo beides
// gesetzt ist.
//   SMTP_TLS        optional, "starttls" (Vorgabe) oder "tls"
//
// Vorrang hat inzwischen die Tabelle mail_settings: dort traegt jeder Verein
// seinen eigenen Postausgang ein, ueber die Verwaltung. Die Secrets bleiben
// als Rueckfall bestehen -- fuer Vereine ohne eigenen Eintrag und damit eine
// bestehende Einrichtung nicht ploetzlich stillsteht.
//   MAIL_BATCH      optional, Hoechstzahl je Lauf (Vorgabe 40)
//   MAIL_CRON_TOKEN optional, Kennwort fuer den Aufruf durch den Zeitplan

import { brevoSmtpPruefen, brevoSmtpSenden, ipv4Herkunft, BREVO_SCHALTER }
  from "./brevo_smtp.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";
import { geheimschluessel } from "../_shared/schluessel.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

// Darf Brevo im Namen dieser Domain senden?
//
// Das ist eine andere Frage als "gilt der Schluessel". Ein gueltiger
// Schluessel verschickt; ob die Nachricht ANKOMMT, entscheidet der
// Empfaenger anhand von DKIM und DMARC. Steht DMARC auf p=reject und
// stimmt die Unterschrift nicht, wird die Nachricht nicht in den Spam
// gelegt, sondern zurueckgewiesen -- waehrend der Versand Erfolg
// meldet. Ohne diese Pruefung waere das unsichtbar.
//
// Diese Funktion stand zuerst falsch hier: sie suchte ein TXT auf
// brevo._domainkey. Brevo arbeitet aber mit ZWEI CNAME, brevo1 und
// brevo2._domainkey, die auf b1/b2.<domain-mit-bindestrich>.dkim.brevo.com
// zeigen; der Schluessel selbst liegt erst am Ende dieser Kette. Mit
// zwei Eintraegen kann Brevo den Schluessel wechseln, ohne dass der
// Versand stillsteht. Derselbe Irrtum -- den Namen raten statt ihn
// nachzusehen -- hat bei Postal dazu gefuehrt, dass mein Hinweis den
// falschen Eintrag als fehlend meldete und der richtige geloescht wurde.
// Darum wird die Kette hier bis zum Schluessel verfolgt und nicht nur
// das Vorhandensein des Namens geprueft.
async function brevoDns(domain: string): Promise<Record<string, string>> {
  const txt = async (name: string) => {
    try {
      const r = await Deno.resolveDns(name, "TXT");
      return (r as string[][]).map((x) => x.join("")).join(" ");
    } catch { return ""; }
  };
  const cname = async (name: string) => {
    try { return (await Deno.resolveDns(name, "CNAME"))[0] ?? ""; }
    catch { return ""; }
  };

  // Je Haelfte: zeigt der CNAME irgendwohin, und liegt dort ein
  // RSA-Schluessel? Ein CNAME, der ins Leere zeigt, sieht in der
  // DNS-Verwaltung richtig aus und unterschreibt nichts.
  const haelfte = async (n: 1 | 2) => {
    const ziel = await cname(`brevo${n}._domainkey.${domain}`);
    if (!ziel) return `FEHLT — CNAME brevo${n}._domainkey fehlt`;
    const schluessel = await txt(ziel.replace(/\.$/, ""));
    if (!/k=rsa/i.test(schluessel)) {
      return `zeigt auf ${ziel} — dort aber kein Schlüssel`;
    }
    return `in Ordnung (${ziel.replace(/\.$/, "")})`;
  };

  const [apex, d1, d2, dmarc] = await Promise.all([
    txt(domain), haelfte(1), haelfte(2), txt(`_dmarc.${domain}`),
  ]);
  const dkimSteht = d1.startsWith("in Ordnung") || d2.startsWith("in Ordnung");
  const strenge = /p=reject/i.test(dmarc) ? "reject"
    : /p=quarantine/i.test(dmarc) ? "quarantine"
    : /v=DMARC1/i.test(dmarc) ? "none" : "keiner";

  return {
    besitznachweis: /brevo-code/i.test(apex) ? "vorhanden" : "FEHLT (brevo-code im Stamm)",
    dkim_1: d1,
    dkim_2: d2,
    dmarc: `p=${strenge}`,
    // Brevo schlaegt auf seiner Einrichtungsseite p=none vor. Dem zu
    // folgen waere ein Rueckschritt: p=none heisst, dass ein Fremder
    // unter unityhub.li schreiben kann, ohne dass der Empfaenger es
    // abweist. Mit gueltigem DKIM braucht Brevo das nicht -- die
    // Unterschrift stellt die Zuordnung her, und reject bleibt richtig.
    bewertung: !dkimSteht
      ? (strenge === "reject" || strenge === "quarantine"
          ? `Ohne DKIM und mit p=${strenge} weist der Empfänger die Nachricht ab — `
            + "der Versand meldete trotzdem Erfolg."
          : "Ohne DKIM landet die Post beim Empfänger eher im Spam.")
      : strenge === "none"
        ? "Brevo darf senden. DMARC steht aber auf p=none — damit kann ein Fremder "
          + "unter dieser Domain schreiben, ohne abgewiesen zu werden. Da das DKIM "
          + "steht, ist p=reject möglich und besser."
        : strenge === "keiner"
          ? "Brevo darf senden; ein DMARC-Eintrag fehlt ganz."
          : `Brevo darf senden, und p=${strenge} bleibt dabei bestehen — `
            + "Unterschrift und strenge Regel zusammen.",
  };
}


// Gilt der Brevo-Schluessel, und was steht noch zur Verfuegung?
//
// /v3/account verschickt nichts und beantwortet beides. "Ein Geheimnis
// ist gesetzt" ist keine Auskunft -- bei Postal hat genau diese Annahme
// zwei Tage gekostet.
async function brevoPruefen(key: string): Promise<string> {
  try {
    const r = await fetch("https://api.brevo.com/v3/account", {
      headers: { "api-key": key, accept: "application/json" },
    });
    const leib = await r.json().catch(() => ({}));
    if (!r.ok) {
      // Brevo hat zwei Arten von Schluesseln, und sie sehen beide lang
      // und zufaellig aus: xkeysib- fuer die Programmschnittstelle,
      // xsmtpsib- fuer den SMTP-Versand. Nur der erste funktioniert
      // hier. Das Praefix ist kein Geheimnis, sondern die Art -- und es
      // zu nennen erspart das Raten, das bei Postal zwei Tage gekostet
      // hat.
      // Brevo sperrt fremde Absenderadressen, wenn die IP-Beschraenkung
      // an ist. Das sieht aus wie ein ungueltiger Schluessel, ist aber
      // das Gegenteil: der Schluessel stimmt, nur der Ort passt nicht.
      // Den Unterschied nicht zu nennen schickt an die falsche Stelle --
      // derselbe Fehler, den mein Hinweis bei Postal schon einmal
      // gemacht hat.
      const meldung = String(leib?.message ?? "");
      if (/unrecognised IP|unrecognized IP|authorised_ips/i.test(meldung)) {
        // Die Adresse mit ausgeben: sie ist bei jedem Aufruf eine
        // andere, und genau das ist der Beweis, dass Freigeben einzelner
        // Adressen nicht haelt.
        const ip = meldung.match(/address ([0-9a-f.:]+)/i)?.[1] ?? "unbekannt";
        // Dieselbe Wegbeschreibung wie beim SMTP-Weg, aus derselben
        // Quelle. Hier stand sie getrennt und zeigte noch auf die Seite
        // mit der Adressliste -- also dorthin, wo man nur freigeben
        // kann. Genau der Fall, den der Kommentar an der Konstante
        // beschreibt: zwei Beschreibungen, eine davon veraltet.
        return `Schlüssel gilt, aber Brevo lässt diese Herkunft nicht zu (${ip}). `
          + "Edge Functions haben keine feste Absenderadresse — gemessen sieben "
          + "Aufrufe, sieben Adressen, keine zweimal. Freigeben trägt deshalb "
          + `nicht. Abschalten unter ${BREVO_SCHALTER}`;
      }

      const art = key.startsWith("xsmtpsib-")
        ? ' Es ist ein SMTP-Schlüssel (xsmtpsib-…). Gebraucht wird ein '
          + 'API-Schlüssel (xkeysib-…): Brevo → SMTP & API → API Keys.'
        : key.startsWith("xkeysib-")
          ? ' Die Art stimmt (xkeysib-…) — der Schlüssel ist wohl gelöscht oder falsch kopiert.'
          : ` Unbekannte Art: beginnt mit "${key.slice(0, 9)}". Erwartet wird xkeysib-…`;
      return `Schlüssel gilt nicht — ${leib?.message ?? r.status}.${art}`;
    }
    const frei = (leib?.plan ?? [])
      .map((p: any) => `${p.type}: ${p.credits ?? "?"} ${p.creditsType ?? ""}`.trim())
      .join(", ");
    return `in Ordnung — ${leib?.companyName ?? leib?.email ?? "Konto"}`
      + (frei ? ` (${frei})` : "");
  } catch (e) {
    return `nicht erreichbar — ${e instanceof Error ? e.message : e}`;
  }
}


// --------------------------------------------- Weg je Empfaengerdomain
//
// Erkannt wird am MX-Eintrag, nicht an einer Liste. Gemessen an den
// Mitgliedern von Koretini: isen-tiefbau.ch, dervishi.ch, ha-tech.ch,
// multinetcom.ch und direct.ch liegen alle bei Microsoft 365 -- das
// sieht man nur am MX (*.mail.protection.outlook.com). Eine Liste
// haette sie uebersehen, und niemand haette gemerkt, warum deren Post
// nicht ankommt.
//
// Die bekannten Endkundendomains stehen trotzdem als Abkuerzung da:
// fuer hotmail.com braucht es keine DNS-Abfrage.

const MS_DIREKT = /@(hotmail|outlook|live|msn|windowslive|passport)\./i;

async function istMicrosoft(admin: any, adresse: string): Promise<boolean> {
  const domain = (adresse.split("@")[1] ?? "").trim().toLowerCase();
  if (!domain) return false;
  if (MS_DIREKT.test("@" + domain)) return true;

  // Gemerktes zuerst. Aelter als 30 Tage wird neu geprueft -- eine
  // Domain kann den Anbieter wechseln.
  const { data: bekannt } = await admin.from("mail_domain_weg")
    .select("weg,geprueft_am").eq("domain", domain).maybeSingle();
  if (bekannt?.geprueft_am
      && Date.now() - new Date(bekannt.geprueft_am).getTime() < 30 * 864e5) {
    return bekannt.weg === "brevo";
  }

  let ms = false;
  let grund = "kein MX";
  try {
    const mx = await Deno.resolveDns(domain, "MX");
    const ziele = (mx ?? []).map((m: any) => String(m.exchange ?? "").toLowerCase());
    ms = ziele.some((z) => z.includes("outlook.com") || z.includes("protection.outlook"));
    grund = ziele[0] ?? "kein MX";
  } catch {
    // Keine Antwort: Postal bleibt der Weg. Eine fehlgeschlagene
    // Abfrage darf nicht dazu fuehren, dass alles ueber Brevo geht --
    // dort gibt es 300 Nachrichten am Tag und sonst nichts.
    ms = false;
  }

  await admin.from("mail_domain_weg").upsert({
    domain, weg: ms ? "brevo" : "postal",
    grund: String(grund).slice(0, 120), geprueft_am: new Date().toISOString(),
  }, { onConflict: "domain" }).then(() => {}, () => {});

  return ms;
}


Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = geheimschluessel();
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const host = Deno.env.get("SMTP_HOST");
  const port = Number(Deno.env.get("SMTP_PORT") ?? "587");
  const benutzer = Deno.env.get("SMTP_USER");
  const kennwort = Deno.env.get("SMTP_PASS");
  const absender = Deno.env.get("SMTP_FROM");
  const tlsArt = (Deno.env.get("SMTP_TLS") ?? "starttls").toLowerCase();
  // Der Weg ueber HTTPS. URL ohne Pfad, z.B. https://mail.helvico.ch
  const postalUrl = (Deno.env.get("POSTAL_URL") ?? "").replace(/\/+$/, "");
  const postalKey = Deno.env.get("POSTAL_API_KEY") ?? "";
  const ueberPostal = !!postalUrl && !!postalKey;
  // Microsoft nimmt von Contabo-Adressen keine Post an, und dort steht
  // der Postal-Server. Fuer Microsoft-Empfaenger deshalb Brevo.
  // Der Schluessel darf auch umhuellt ankommen.
  //
  // Brevos MCP-Einrichtung gibt ihn als base64-verpacktes JSON heraus
  // ({"api_key": "xkeysib-..."}), und genau das wurde gesetzt. Statt den
  // Betreiber ein zweites Mal durch die Oberflaeche zu schicken, wird
  // ausgepackt, was eindeutig auspackbar ist -- die Pruefung sagt
  // trotzdem, dass es umhuellt war.
  const brevoRoh = (Deno.env.get("BREVO_API_KEY") ?? "").trim();
  const brevoAuspacken = (v: string): { key: string; umhuellt: boolean } => {
    if (!v || v.startsWith("xkeysib-")) return { key: v, umhuellt: false };
    try {
      const klar = atob(v);
      if (!klar.trimStart().startsWith("{")) return { key: v, umhuellt: false };
      const o = JSON.parse(klar);
      const k = String(o?.api_key ?? o?.apiKey ?? o?.key ?? "");
      if (k.startsWith("xkeysib-")) return { key: k, umhuellt: true };
    } catch { /* dann eben unveraendert */ }
    return { key: v, umhuellt: false };
  };
  const { key: brevoKey, umhuellt: brevoUmhuellt } = brevoAuspacken(brevoRoh);

// Brevo bietet zwei Wege, und sie unterscheiden sich hier nicht in der
// Bequemlichkeit, sondern darin, ob sie ueberhaupt funktionieren: die
// Programmschnittstelle wird von der IP-Beschraenkung des Kontos
// abgewiesen (gemessen, mit drei verschiedenen Herkunftsadressen in drei
// aufeinanderfolgenden Aufrufen), SMTP meldet sich mit Benutzer und
// Schluessel an und fragt nicht nach dem Ort. Darum hat SMTP den
// Vorrang, wenn beides hinterlegt ist.
const brevoSmtpLogin = (Deno.env.get("BREVO_SMTP_LOGIN") ?? "").trim();
const brevoSmtpKey = (Deno.env.get("BREVO_SMTP_KEY") ?? "").trim();
const brevoSmtpDa = !!brevoSmtpLogin && !!brevoSmtpKey;
  const menge = Math.min(Number(Deno.env.get("MAIL_BATCH") ?? "40"), 200);
  const cronToken = Deno.env.get("MAIL_CRON_TOKEN");

  // Zwei Wege herein: der Zeitplan mit einem geteilten Kennwort, oder eine
  // angemeldete Person aus der Geschaeftsfuehrung. Alles andere bleibt aussen.
  const tokenHeader = req.headers.get("x-cron-token");
  let erlaubt = false;
  let aufrufer = "zeitplan";

  const admin0 = createClient(url, serviceKey, { auth: { persistSession: false } });

  if (cronToken && tokenHeader && tokenHeader === cronToken) {
    erlaubt = true;
  } else if (tokenHeader) {
    // Das Zeitplan-Kennwort steht auch in mail_settings -- dort wird es beim
    // Anlegen erzeugt, damit niemand es von Hand in die Secrets eintragen
    // muss. Verglichen wird ueber die Datenbank, nicht in JavaScript, damit
    // der Vergleich nicht ueber die Laufzeit verraet, wie weit er kam.
    const { data: treffer } = await admin0
      .rpc("zeitplan_token_gueltig", { p_token: tokenHeader });
    if (treffer === true) erlaubt = true;
  }
  if (!erlaubt) {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (authHeader.startsWith("Bearer ")) {
      const asCaller = createClient(url, anonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data } = await asCaller.auth.getUser();
      const mail = (data?.user?.email ?? "").toLowerCase();
      if (mail) {
        const { data: rows } = await admin0
          .from("users").select("role").ilike("email", mail).limit(1);
        const rolle = rows?.[0]?.role ?? "";
        if (["ADMIN", "SUPER_ADMIN", "BOARD"].includes(rolle)) {
          erlaubt = true;
          aufrufer = mail;
        }
      }
    }
  }
  if (!erlaubt) return json({ error: "Nicht berechtigt." }, 403);

  const admin = admin0;

  // ------------------------------------------------------- Pruefen
  //
  // Der Betreiber setzt die Zugangsdaten als Geheimnis der Funktion --
  // das war die Bedingung, und sie ist richtig. Die Folge: niemand sonst
  // sieht, WAS dort steht, auch nicht, wer beim Einrichten einen Zahlen-
  // dreher gemacht hat. "Connection refused" allein hilft dabei nicht
  // weiter.
  //
  // Diese Pruefung zeigt dem Betreiber seine eigenen Werte zurueck --
  // Adresse, Port, Verschluesselung, Absender, Benutzername verkuerzt --
  // und versucht eine Verbindung. Das Kennwort erscheint nie.
  let koerper: any = {};
  try { koerper = await req.json(); } catch { /* leerer Leib ist in Ordnung */ }

  if (koerper?.pruefen === true) {
    const verkuerzt = (v: string | undefined) =>
      !v ? "(nicht gesetzt)" : v.length <= 4 ? "****" : v.slice(0, 2) + "***" + v.slice(-2);

    // Ein anderer Port am GLEICHEN Rechner darf geprueft werden -- so
    // laesst sich vor dem Umstellen sehen, ob 587 geht, wenn 465 nicht
    // antwortet. Eine andere Adresse ist nicht erlaubt: das waere ein
    // Portscanner, und dafuer ist diese Funktion nicht da.
    const probePort = Number.isInteger(koerper?.port) && koerper.port > 0 && koerper.port < 65536
      ? koerper.port as number : port;

    // Der Weg ueber HTTPS wird zuerst geprueft, weil er Vorrang hat.
    if (ueberPostal) {
      // Eine andere Absenderadresse laesst sich zum Pruefen mitgeben.
      // Postal gibt Mail nur fuer Domains frei, die auf dem Server
      // eingerichtet sind -- welche das ist, weiss nur der Betreiber,
      // und Durchprobieren per Neusetzen der Geheimnisse waere muehsam.
      const vonProbe = typeof koerper?.von === "string" && koerper.von.includes("@")
        ? String(koerper.von).slice(0, 120) : (absender ?? "");

      // Pruefen OHNE Probenachricht: Verbindung, Schluessel und DNS lassen
      // sich feststellen, ohne dass etwas hinausgeht. Vorher war beides
      // dasselbe -- wer nur nachsehen wollte, verschickte dabei Post.
      const ohneMail = koerper?.ohne_mail === true;

      const a: Record<string, unknown> = {
        weg: "HTTPS (Postal)", url: postalUrl, probenachricht: !ohneMail,
        // Microsoft-Empfaenger gehen einen anderen Weg; ob der steht,
        // gehoert in dieselbe Auskunft. Und zwar GEPRUEFT -- dass ein
        // Geheimnis da ist, heisst nicht, dass es gilt.
        brevo_dns: brevoKey
          ? await brevoDns((absender ?? "@").split("@")[1] ?? "") : undefined,
        microsoft_weg: brevoSmtpDa ? "Brevo über SMTP"
          : brevoKey ? "Brevo über die Programmschnittstelle"
          : "keiner — Microsoft-Post geht über Postal und wird dort abgewiesen",
        // Beide Proben bauen eine Verbindung nach draussen auf, und jede
        // davon legt bei Brevo eine Zeile in der Liste "nicht
        // autorisierte IP-Adressen" an -- die Liste wuchs von 20 auf 57,
        // waehrend ich gemessen habe. Eine Diagnose, die den Zustand
        // verschlechtert, den sie beschreibt, laeuft nicht bei jedem
        // Aufruf. Darum nur auf ausdrueckliche Anforderung.
        ...(koerper?.smtp_pruefen
          ? {
              microsoft_ueber_brevo_smtp:
                await brevoSmtpPruefen(brevoSmtpLogin, brevoSmtpKey),
              ipv4_herkunft: await ipv4Herkunft(admin),
            }
          : {
              microsoft_ueber_brevo_smtp: brevoSmtpDa
                ? "Zugangsdaten hinterlegt. Für die Anmeldeprobe "
                  + '{"pruefen":true,"smtp_pruefen":true} senden — sie baut eine '
                  + "Verbindung auf und hinterlässt dabei eine Adresse in Brevos Liste."
                : "BREVO_SMTP_LOGIN und BREVO_SMTP_KEY fehlen.",
            }),
        microsoft_ueber_brevo: brevoKey
          ? (await brevoPruefen(brevoKey))
            + (brevoUmhuellt
                ? ' — Hinweis: das Geheimnis ist base64-verpacktes JSON; es wird '
                  + 'ausgepackt. Sauberer wäre der blosse Schlüssel (xkeysib-…).' : '')
          : "NICHT eingerichtet — Microsoft-Empfänger gehen über Postal und "
            + "werden von Microsoft abgewiesen",
        // Die Form des Schluessels -- nicht sein Inhalt. Ein mitkopiertes
        // Leerzeichen sieht man in keiner Oberflaeche, macht den Schluessel
        // aber ungueltig, und "24 Zeichen" allein verraet es nicht.
        schluessel: `${postalKey.length} Zeichen`
          + (postalKey !== postalKey.trim()
              ? ` — ACHTUNG: Leerzeichen am Rand (getrimmt ${postalKey.trim().length})` : "")
          + (/[^A-Za-z0-9_-]/.test(postalKey.trim())
              ? " — enthält Sonderzeichen, untypisch für einen Postal-Schlüssel" : "")
          + `, beginnt ${postalKey.trim().slice(0, 2)}…${postalKey.trim().slice(-2)}`,
        absender: vonProbe || "(nicht gesetzt)",
        eingestellter_absender: absender ?? "(nicht gesetzt)",
      };
      try {
        // Ohne Probenachricht wird GAR NICHT der Sendeweg benutzt.
        //
        // Vorher ging die Pruefung an eine Adresse unter .invalid -- und
        // Postal wies sie wegen des EMPFAENGERS ab, nicht wegen des
        // Schluessels. Die Antwort lautete "Abgelehnt" ohne Grund, und
        // das sagte ueber die Einrichtung genau nichts.
        //
        // Stattdessen eine Abfrage, die nichts verschickt: eine
        // Nachricht mit unmoeglicher Kennung nachschlagen. Gilt der
        // Schluessel nicht, antwortet Postal mit InvalidServerAPIKey;
        // gilt er, meldet es schlicht, dass es die Nachricht nicht gibt.
        if (ohneMail) {
          const r2 = await fetch(`${postalUrl}/api/v1/messages/message`, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-Server-API-Key": postalKey },
            body: JSON.stringify({ id: 0 }),
          });
          const l2 = await r2.json().catch(() => ({}));
          const code2 = String(l2?.data?.code ?? "");
          if (code2 === "InvalidServerAPIKey") {
            a.ergebnis = "Abgelehnt — dieser Schlüssel gilt nicht.";
            a.hinweis = "In Postal haben Zugangsdaten einen Typ: nur Type=API "
              + "funktioniert hier, Type=SMTP nicht.";
          } else {
            a.ergebnis = "In Ordnung. Verbindung und Schlüssel stimmen; "
              + "es wurde nichts verschickt.";
            await admin.rpc("postausgang_melden",
              { p_bereit: true, p_quelle: "postal", p_fehler: null }).then(() => {}, () => {});
          }
          return json(a, 200);
        }

        const r = await fetch(`${postalUrl}/api/v1/send/message`, {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-Server-API-Key": postalKey },
          body: JSON.stringify({
            to: [vonProbe], from: vonProbe,
            subject: "unityhub — Prüfung des Postausgangs",
            plain_body: "Diese Nachricht bestätigt, dass der Versand über Postal funktioniert.",
          }),
        });
        const leib = await r.json().catch(() => ({}));
        if (leib?.status === "success") {
          a.ergebnis = ohneMail
            ? "In Ordnung. Schlüssel und Absender werden angenommen; es wurde nichts verschickt."
            : `In Ordnung. Eine Prüfnachricht ging an ${vonProbe}.`;
          if (vonProbe !== absender) {
            a.achtung = `Geprüft wurde ${vonProbe}, gesetzt ist aber ${absender}. `
              + "Setzen Sie SMTP_FROM auf die Adresse, die funktioniert.";
          }
          await admin.rpc("postausgang_melden",
            { p_bereit: true, p_quelle: "postal", p_fehler: null }).then(() => {}, () => {});
        } else {
          const code = String(leib?.data?.code ?? "");
          a.ergebnis = `Abgelehnt — ${leib?.data?.message ?? code ?? r.status}`;

          // Der Hinweis stand fest auf "der Schluessel gilt" -- auch dann,
          // wenn Postal genau das Gegenteil meldete. Ein Hinweis, der
          // nicht zur Meldung passt, schickt an die falsche Stelle.
          if (code === "InvalidServerAPIKey") {
            a.hinweis = "Die Verbindung steht, aber dieser Schlüssel gilt nicht. "
              + "In Postal haben Zugangsdaten einen Typ: nur Type=API funktioniert hier, "
              + "Type=SMTP nicht. Prüfen Sie ausserdem, ob beim Kopieren ein Leerzeichen "
              + "mitgegangen ist.";
            return json(a, 200);   // Ohne gueltigen Schluessel sagt das DNS nichts aus.
          }
          a.hinweis = "Die Verbindung steht und der Schlüssel gilt. Es fehlt an der Domain.";

          // Nachsehen, welcher DNS-Eintrag fehlt.
          //
          // Postal gibt eine Domain erst frei, wenn SPF, Return-Pfad UND
          // DKIM stehen. "The From address is not authorised" nennt aber
          // nicht, welcher der drei fehlt -- und danach sucht man lange.
          const domain = vonProbe.split("@")[1] ?? "";
          if (domain) {
            const dns: Record<string, string> = {};
            const frag = async (name: string, art: "TXT" | "CNAME") => {
              try {
                const r2 = await Deno.resolveDns(name, art);
                return Array.isArray(r2) && r2.length
                  ? (art === "TXT" ? (r2 as string[][]).map((x) => x.join("")).join(" ")
                                   : String(r2[0]))
                  : "";
              } catch { return ""; }
            };
            const spf = await frag(domain, "TXT");
            dns.spf = /v=spf1/i.test(spf) ? "vorhanden" : "FEHLT";
            dns.rueckpfad = (await frag(`psrp.${domain}`, "CNAME")) ? "vorhanden" : "FEHLT";
            // Postal vergibt je Domain einen eigenen Selektor --
            // "postal" bei der einen, "postal-yyk2bc" bei der naechsten.
            // Raten ist zwecklos, und DNS laesst sich nicht auflisten.
            // Also: den Standardnamen pruefen, einen mitgegebenen
            // Selektor pruefen -- und sonst sagen, dass man ihn nicht
            // kennt, statt "FEHLT" zu behaupten. Genau das hat hier in
            // die Irre gefuehrt: der Eintrag stand laengst da.
            const selektoren = ["postal"];
            if (typeof koerper?.selektor === "string") {
              selektoren.unshift(String(koerper.selektor).replace(/[^A-Za-z0-9_-]/g, ""));
            }
            let gefunden = "";
            for (const sel of selektoren) {
              const t = await frag(`${sel}._domainkey.${domain}`, "TXT");
              if (/v=DKIM1/i.test(t)) { gefunden = sel; break; }
            }
            dns.dkim = gefunden
              ? `vorhanden (Selektor ${gefunden})`
              : `nicht gefunden unter ${selektoren.join(", ")}._domainkey.${domain} — `
                + "Postal nutzt je Domain einen eigenen Selektor (z.B. postal-yyk2bc). "
                + "Mit {\"selektor\": \"...\"} pruefen oder in Postal nachsehen.";
            a.dns = dns;
            a.naechster_schritt = dns.dkim.startsWith("vorhanden")
              // Alle drei Eintraege stehen und Postal lehnt trotzdem ab:
              // dann liegt es nicht am DNS, sondern daran, WELCHEM Server
              // der Schluessel gehoert. In Postal hat jeder Server seine
              // eigenen Domains und seine eigenen Zugangsdaten.
              ? `SPF, Rückpfad und DKIM stehen. Dann gehört der API-Schlüssel zu einem `
                + `anderen Postal-Server als die Domain ${domain}. In ${postalUrl} prüfen: `
                + `Ist ${domain} unter DEMSELBEN Server eingetragen, unter dem der Schlüssel `
                + "erzeugt wurde — und steht die Domain dort auf verifiziert?"
              : `Im Postal unter ${postalUrl} die Domain ${domain} oeffnen; dort steht der `
                + "DKIM-Eintrag mit seinem Selektor im Wortlaut.";
          }
        }
      } catch (e) {
        a.ergebnis = `Nicht erreichbar — ${e instanceof Error ? e.message : e}`;
      }
      return json(a, 200);
    }

    const antwort: Record<string, unknown> = {
      weg: "SMTP",
      host: host ?? "(nicht gesetzt)",
      port: probePort, eingestellter_port: port, tls: tlsArt,
      benutzer: verkuerzt(benutzer),
      kennwort: kennwort ? `gesetzt, ${kennwort.length} Zeichen` : "(nicht gesetzt)",
      absender: absender ?? "(nicht gesetzt)",
    };

    if (!host || !kennwort) {
      antwort.ergebnis = "Unvollstaendig — ohne Adresse oder Kennwort wird nichts versucht.";
      return json(antwort, 200);
    }

    // Erst die blosse Verbindung: scheitert sie, liegt es an Adresse oder
    // Port, nicht an Benutzername oder Kennwort. Diese beiden Faelle
    // auseinanderzuhalten erspart das Suchen an der falschen Stelle.
    try {
      const verb = await Deno.connect({ hostname: host, port: probePort });
      verb.close();
      antwort.verbindung = `offen auf ${host}:${probePort}`;
    } catch (e) {
      antwort.verbindung = `FEHLGESCHLAGEN auf ${host}:${probePort} — ${e instanceof Error ? e.message : e}`;
      antwort.hinweis = "Nichts hoert auf diesem Port. Ueblich sind 587 (starttls) "
        + "und 465 (tls). Pruefen Sie Adresse und Port beim Anbieter.";
      return json(antwort, 200);
    }

    if (probePort !== port) {
      antwort.ergebnis = `Port ${probePort} ist erreichbar. Eingestellt ist derzeit ${port}.`;
      return json(antwort, 200);
    }

    // Dann die Anmeldung.
    try {
      const probe = new SMTPClient({
        connection: { hostname: host, port, tls: tlsArt === "tls",
                      auth: benutzer ? { username: benutzer, password: kennwort } : undefined },
      });
      await probe.send({ from: absender ?? benutzer ?? "", to: absender ?? benutzer ?? "",
                         subject: "unityhub — Prüfung des Postausgangs",
                         content: "Diese Nachricht bestätigt, dass der Postausgang funktioniert." });
      await probe.close();
      antwort.ergebnis = `In Ordnung. Eine Prüfnachricht ging an ${absender ?? benutzer}.`;
      await admin.rpc("postausgang_melden",
        { p_bereit: true, p_quelle: "geheimnis", p_fehler: null }).then(() => {}, () => {});
    } catch (e) {
      antwort.ergebnis = `Anmeldung fehlgeschlagen — ${e instanceof Error ? e.message : e}`;
      antwort.hinweis = "Die Verbindung stand, aber der Dienst hat abgelehnt. "
        + "Pruefen Sie Benutzername, Kennwort und ob TLS 'starttls' oder 'tls' sein muss.";
    }
    return json(antwort, 200);
  }

  // Offene Nachrichten holen -- vereinsuebergreifend, danach nach Verein
  // getrennt versendet. Jeder Verein hat seinen eigenen Postausgang; ueber
  // den eines anderen zu versenden waere ein Mandantenbruch.
  const { data: offen, error: leseFehler } = await admin
    .from("mail_queue")
    .select("*")
    .eq("status", "PENDING")
    .lte("scheduledFor", new Date().toISOString())
    .order("createdAt", { ascending: true })
    .limit(menge);

  if (leseFehler) return json({ error: leseFehler.message }, 500);
  if (!offen?.length) return json({ ok: true, configured: true, sent: 0, failed: 0 });

  // Zugangsdaten je Verein. Vorrang hat der Eintrag in mail_settings; fehlt
  // er, gelten die Secrets der Funktion -- so steht eine bestehende
  // Einrichtung nicht ploetzlich still.
  const { data: eintraege } = await admin
    .from("mail_settings")
    .select('"tenantId", host, port, benutzer, kennwort, absender, absendername, tls, aktiv');

  const ausSecrets = {
    host, port, benutzer, kennwort, absender, absendername: null as string | null,
    tls: tlsArt, aktiv: true,
  };

  // EIN Postausgang fuer alle. Vorher trug jeder Verein seinen eigenen ein;
  // das bedeutete, dass jeder Verein einen Anbieter finden, einrichten und
  // pflegen musste -- und bei Koretini scheiterte genau das: der Anbieter
  // nimmt keine Verbindungen aus Rechenzentren an (Connection timed out,
  // waehrend derselbe Server von einem gewoehnlichen Anschluss in 0,1 s
  // antwortet).
  //
  // Gesucht wird die Zeile fuer 'plattform'; die Secrets bleiben der
  // Rueckfall. Vereinszeilen werden NICHT mehr gelesen.
  // Die Zeile gilt nur, wenn sie BRAUCHBAR ist.
  //
  // Vorher genuegte ihr blosses Dasein: eine angelegte, aber leere und
  // inaktive Zeile verdraengte die Secrets vollstaendig. Genau das ist
  // am 09.10. passiert -- der Betreiber setzte SMTP_HOST und Co., und es
  // ging trotzdem nichts hinaus, weil eine leere Zeile aus einer
  // frueheren Migration davorstand. Eine Einstellung, die nichts
  // enthaelt, darf nichts verdraengen.
  const zentral = (eintraege ?? []).find((e: any) => e.tenantId === "plattform");
  const zeileBrauchbar = !!zentral && zentral.aktiv !== false
    && !!String(zentral.host ?? "").trim() && !!String(zentral.kennwort ?? "").trim();

  const postausgangZentral = zeileBrauchbar
    ? {
        host: zentral.host, port: zentral.port ?? 587, benutzer: zentral.benutzer,
        kennwort: zentral.kennwort, absender: zentral.absender,
        absendername: zentral.absendername,
        tls: (zentral.tls ?? "starttls").toLowerCase(), aktiv: true,
      }
    : ausSecrets;

  const quelle = zeileBrauchbar ? "tabelle" : "geheimnis";

  // Der Oberflaeche sagen, ob ueberhaupt etwas hinausgehen kann. Sie
  // konnte das bisher nur in mail_settings nachsehen -- der falschen
  // Stelle, wenn die Zugangsdaten als Geheimnis liegen.
  const kannUeberhaupt = ueberPostal
    || (!!postausgangZentral.host && !!postausgangZentral.kennwort);
  await admin.rpc("postausgang_melden", {
    p_bereit: kannUeberhaupt, p_quelle: ueberPostal ? "postal" : quelle,
    p_fehler: kannUeberhaupt ? null
      : "Weder POSTAL_URL/POSTAL_API_KEY noch eine brauchbare SMTP-Einstellung.",
  }).then(() => {}, () => {});

  if (!kannUeberhaupt) {
    return json({ ok: false, configured: false,
      error: "Kein Postausgang: weder POSTAL_URL/POSTAL_API_KEY noch SMTP." }, 200);
  }

  // Name und Antwortadresse je Verein. Der technische Absender bleibt
  // unityhub -- nur dessen Domain ist bei SPF und DKIM hinterlegt. Wuerde
  // hier info@koretini.me als From stehen, scheiterte die Absenderpruefung
  // beim Empfaenger und die Nachricht landete im Spam. Der Empfaenger sieht
  // trotzdem den Vereinsnamen, und seine Antwort geht an den Verein.
  const vereinsInfo = new Map<string, { name: string; antwortAn: string | null }>();
  const { data: vereine } = await admin0
    .from("tenants").select('id, name, "contactEmail"');
  for (const v of vereine ?? []) {
    vereinsInfo.set(v.id, { name: v.name ?? v.id, antwortAn: v.contactEmail ?? null });
  }

  const vollstaendig = (p: typeof ausSecrets | undefined) =>
    !!(p && p.aktiv && p.host && p.benutzer && p.kennwort && p.absender);

  // Nach Verein gruppieren.
  const nachVerein = new Map<string, any[]>();
  for (const m of offen) {
    const v = m.tenantId ?? "";
    if (!nachVerein.has(v)) nachVerein.set(v, []);
    nachVerein.get(v)!.push(m);
  }

  let ueberBrevoGesendet = 0;
  let gesendet = 0;
  let gescheitert = 0;
  let liegengeblieben = 0;
  const ohnePostausgang: string[] = [];

  for (const [verein, nachrichten] of nachVerein) {
    const p = postausgangZentral;
    const info = vereinsInfo.get(verein);

    // Ohne Postausgang wird nichts versendet -- und nichts angetastet. Die
    // Nachrichten bleiben stehen, statt als gescheitert zu gelten.
    if (!ueberPostal && !vollstaendig(p)) {
      liegengeblieben += nachrichten.length;
      if (!ohnePostausgang.includes(verein)) ohnePostausgang.push(verein);
      continue;
    }

    // Ueber HTTPS braucht es keine Verbindung, die offen bleibt.
    const client = ueberPostal ? null : new SMTPClient({
      connection: {
        hostname: p.host!,
        port: p.port,
        tls: p.tls === "tls",
        auth: { username: p.benutzer!, password: p.kennwort! },
      },
    });

    for (const m of nachrichten) {
      try {
        // Microsoft-Empfaenger ueber Brevo, alle uebrigen ueber Postal.
        const zeigeName = info?.name ?? p.absendername ?? "unityhub";

        // Einmal fragen, dann entscheiden. Die Abfrage ist
        // zwischengespeichert; zweimal zu fragen waere nur unordentlich.
        const istMs = (brevoSmtpDa || !!brevoKey)
          && await istMicrosoft(admin, String(m.recipient));
        const ueberBrevoSmtp = istMs && brevoSmtpDa;
        const ueberBrevo = istMs && !brevoSmtpDa && !!brevoKey;

        if (ueberBrevoSmtp) {
          await brevoSmtpSenden(brevoSmtpLogin, brevoSmtpKey, {
            von: p.absender ?? absender,
            vonName: zeigeName,
            an: String(m.recipient),
            antwortAn: info?.antwortAn ?? null,
            betreff: String(m.subject ?? ""),
            html: String(m.html ?? ""),
            text: m.text ?? null,
            anhaenge: Array.isArray(m.attachments)
              ? m.attachments.map((a: any) => ({
                  filename: String(a.filename ?? "anhang.pdf"),
                  content: String(a.content ?? ""),
                })) : [],
          });
          ueberBrevoGesendet++;
        } else if (ueberBrevo) {
          const r = await fetch("https://api.brevo.com/v3/smtp/email", {
            method: "POST",
            headers: { "Content-Type": "application/json", "api-key": brevoKey },
            body: JSON.stringify({
              sender: { name: zeigeName, email: p.absender ?? absender },
              to: [{ email: m.recipient }],
              ...(info?.antwortAn ? { replyTo: { email: info.antwortAn } } : {}),
              subject: m.subject,
              htmlContent: m.html,
              ...(m.text ? { textContent: m.text } : {}),
              ...(Array.isArray(m.attachments) && m.attachments.length
                ? { attachment: m.attachments.map((a: any) => ({
                      name: a.filename, content: a.content })) }
                : {}),
            }),
          });
          if (!r.ok) {
            const leib = await r.text();
            // Brevo nennt den Grund im Leib; der Statuscode allein sagt
            // nicht, ob der Absender unbestaetigt oder das Kontingent
            // aufgebraucht ist.
            throw new Error(`Brevo meldet ${r.status}: ${leib.slice(0, 300)}`);
          }
          ueberBrevoGesendet++;
        } else if (ueberPostal) {
          const r = await fetch(`${postalUrl}/api/v1/send/message`, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-Server-API-Key": postalKey },
            body: JSON.stringify({
              to: [m.recipient],
              from: `${zeigeName} <${p.absender ?? absender}>`,
              sender: p.absender ?? absender,
              reply_to: info?.antwortAn ?? undefined,
              subject: m.subject,
              html_body: m.html,
              plain_body: m.text ?? undefined,
              attachments: Array.isArray(m.attachments) && m.attachments.length
                ? m.attachments.map((a: any) => ({
                    name: a.filename, content_type: "application/pdf", data: a.content }))
                : undefined,
            }),
          });
          const leib = await r.json().catch(() => ({}));
          // Postal antwortet mit HTTP 200 auch dann, wenn es ablehnt --
          // der Zustand steht im Leib. Nur auf den Statuscode zu sehen
          // hiesse, jede Ablehnung als Erfolg zu verbuchen.
          if (!r.ok || leib?.status !== "success") {
            throw new Error(leib?.data?.message
              ?? leib?.data?.code ?? `Postal meldet ${r.status}`);
          }
        } else {
        await client!.send({
          // Anzeigename: der Verein, dem die Nachricht gehoert. Ohne
          // Vereinsbezug (Betreiber-Nachrichten) der Name des Postausgangs.
          from: `${zeigeName} <${p.absender}>`,
          replyTo: info?.antwortAn ?? undefined,
          to: m.recipient,
          subject: m.subject,
          html: m.html,
          content: m.text ?? undefined,
          attachments: Array.isArray(m.attachments) && m.attachments.length
            ? m.attachments.map((a: any) => ({
                filename: a.filename,
                content: a.content,
                encoding: "base64" as const,
              }))
            : undefined,
        });
        }
        await admin.from("mail_queue")
          .update({ status: "SENT", sentAt: new Date().toISOString(), attempts: (m.attempts ?? 0) + 1 })
          .eq("id", m.id);
        gesendet++;
      } catch (e) {
        const versuche = (m.attempts ?? 0) + 1;
        // Erst nach dem fuenften vergeblichen Versuch endgueltig aufgeben --
        // ein voruebergehend nicht erreichbarer Postausgang soll keine
        // Nachricht verbrennen.
        //
        // Dazu wachsender Abstand. Vorher lief der Zeitplan alle zehn
        // Minuten und verbrauchte damit alle fuenf Versuche in knapp einer
        // Stunde: am 09.10. sind sechs Nachrichten waehrend einer Stoerung
        // verbrannt, die Wochen dauerte. Jetzt 10 Min, 1 h, 4 h, 12 h --
        // nach fuenf Versuchen sind gut zwei Tage vergangen statt einer
        // Stunde.
        const wartezeit = [10, 60, 240, 720][Math.min(versuche - 1, 3)];
        await admin.from("mail_queue")
          .update({
            status: versuche >= 5 ? "FAILED" : "PENDING",
            attempts: versuche,
            scheduledFor: new Date(Date.now() + wartezeit * 60_000).toISOString(),
            lastError: String((e as any)?.message ?? e).slice(0, 500),
          })
          .eq("id", m.id);
        gescheitert++;
      }
    }

    try { await client?.close(); } catch { /* geschlossen ist geschlossen */ }
  }

  // Wessen Post bleibt liegen? Frueher stand hier ein pauschales "Kein
  // Postausgang hinterlegt" -- unverstaendlich fuer jemanden, der gerade
  // einen eingetragen hat, waehrend die wartende Nachricht zu einem anderen
  // Mandanten gehoert. Jetzt wird der Mandant benannt.
  if (gesendet === 0 && gescheitert === 0 && liegengeblieben > 0) {
    const wer = ohnePostausgang.map((v) => v || "(ohne Zuordnung)").join(", ");
    return json({
      ok: false,
      configured: false,
      sent: 0, failed: 0, pending: liegengeblieben,
      ohnePostausgang,
      hinweis:
        `${liegengeblieben} Nachricht(en) warten auf einen Postausgang fuer: ${wer}. ` +
        "Jeder Mandant versendet ueber seinen eigenen Server -- ueber den eines " +
        "anderen zu versenden waere ein Mandantenbruch. Bis ein Postausgang " +
        "eingetragen ist, bleibt alles stehen und geht nicht verloren.",
    }, 200);
  }

  // Aufgeschluesselt nach Weg: ohne das sieht man nicht, ob die
  // Umleitung fuer Microsoft ueberhaupt greift.
  return json({ ok: true, configured: true, sent: gesendet, failed: gescheitert,
                davon_brevo: ueberBrevoGesendet,
                davon_postal: gesendet - ueberBrevoGesendet,
                pending: liegengeblieben, ohnePostausgang, by: aufrufer });
});
