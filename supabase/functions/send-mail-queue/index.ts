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

      const a: Record<string, unknown> = {
        weg: "HTTPS (Postal)", url: postalUrl,
        schluessel: `gesetzt, ${postalKey.length} Zeichen`,
        absender: vonProbe || "(nicht gesetzt)",
        eingestellter_absender: absender ?? "(nicht gesetzt)",
      };
      try {
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
          a.ergebnis = `In Ordnung. Eine Prüfnachricht ging an ${vonProbe}.`;
          if (vonProbe !== absender) {
            a.achtung = `Geprüft wurde ${vonProbe}, gesetzt ist aber ${absender}. `
              + "Setzen Sie SMTP_FROM auf die Adresse, die funktioniert.";
          }
          await admin.rpc("postausgang_melden",
            { p_bereit: true, p_quelle: "postal", p_fehler: null }).then(() => {}, () => {});
        } else {
          a.ergebnis = `Abgelehnt — ${leib?.data?.message ?? leib?.data?.code ?? r.status}`;
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
            const dkim = await frag(`postal._domainkey.${domain}`, "TXT");
            dns.dkim = /v=DKIM1/i.test(dkim)
              ? "vorhanden"
              : `FEHLT — TXT auf postal._domainkey.${domain}`;
            a.dns = dns;
            if (dns.dkim.startsWith("FEHLT")) {
              a.naechster_schritt = `Im Postal unter ${postalUrl} die Domain ${domain} oeffnen; `
                + "dort steht der DKIM-Eintrag im Wortlaut. Diesen TXT-Eintrag im DNS "
                + `von ${domain} anlegen, dann in Postal auf "Verify" klicken.`;
            }
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
        if (ueberPostal) {
          const r = await fetch(`${postalUrl}/api/v1/send/message`, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-Server-API-Key": postalKey },
            body: JSON.stringify({
              to: [m.recipient],
              from: `${info?.name ?? p.absendername ?? "unityhub"} <${p.absender ?? absender}>`,
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
          from: `${info?.name ?? p.absendername ?? "unityhub"} <${p.absender}>`,
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
        await admin.from("mail_queue")
          .update({
            status: versuche >= 5 ? "FAILED" : "PENDING",
            attempts: versuche,
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

  return json({ ok: true, configured: true, sent: gesendet, failed: gescheitert,
                pending: liegengeblieben, ohnePostausgang, by: aufrufer });
});
