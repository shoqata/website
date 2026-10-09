// Floky -- der Vereinsassistent.
//
// Die eine Entscheidung, die diese Datei traegt: der Prompt ist keine
// Sicherheitsgrenze. Rolle, Verein und Rechte kommen aus der Datenbank,
// und jede Abfrage laeuft mit dem Konto des Fragenden -- nicht mit dem
// Dienstschluessel. Wer nicht sehen darf, bekommt nicht zu sehen; das
// entscheiden die Zeilenregeln, nicht die Anweisung im Systemtext.
//
// Daraus folgt der Zuschnitt:
//   - LESEN macht Floky selbst. Was er dabei sieht, sieht der Fragende
//     ohnehin. Ein Vertreter bekommt seine Nachbarschaft und sonst nichts,
//     weil die Datenbank ihm nur das gibt.
//   - SCHREIBEN macht Floky nie. Er fuellt eine Karte; der Mensch klickt.
//     Deshalb gibt es hier keine schreibenden Werkzeuge, auch nicht
//     versehentlich: die Liste unten enthaelt nur SELECTs.
//   - Das Kontingent zaehlt die Datenbank. Ein Zaehler, den der Aufrufer
//     fuehrt, waere keiner.
//
// Der Antwortdienst ist Infomaniak AI Tools -- Schweizer Rechenzentrum.
// Das ist hier keine Geschmacksfrage: Mitgliederdaten eines Schweizer
// Vereins verlassen damit das Land nicht, und das DSG-Kapitel des Konzepts
// verlangt genau das. Die Schnittstelle ist OpenAI-kompatibel.
//
// Umgebungsvariablen:
//   INFOMANIAK_AI_API_KEY     Pflicht. API-Token aus dem Infomaniak-Manager.
//   INFOMANIAK_AI_PRODUCT_ID  optional. Fehlt er, wird er ueber GET /1/ai
//                             ermittelt und fuer die Laufzeit gemerkt.
//   ASSISTANT_MODELS          optional. Welches Modell. Mehrere durch Komma
//                             getrennt sind erlaubt -- genommen wird das
//                             erste; die uebrigen stehen fuer spaeter.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

// Der Name steht im Plural, also wird auch eine Liste vertragen. Genommen
// wird das erste Modell -- eine Liste stillschweigend als einen Namen zu
// verwenden, haette "mistral, llama" an Infomaniak geschickt.
const MODELL = (Deno.env.get("ASSISTANT_MODELS") ?? "mistralai/Mistral-Small-4-119B-2603")
  .split(",")[0].trim();

// Die Produkt-Nummer aendert sich nicht; sie einmal je Kaltstart zu holen
// reicht. Ein Fehlschlag wird NICHT gemerkt -- sonst bliebe eine Funktion
// nach einer Stoerung dauerhaft stumm.
let produktId: string | null = Deno.env.get("INFOMANIAK_AI_PRODUCT_ID") ?? null;
async function produktErmitteln(token: string): Promise<string> {
  if (produktId) return produktId;
  const r = await fetch("https://api.infomaniak.com/1/ai", {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!r.ok) throw new Error(`Infomaniak meldet ${r.status} beim Abruf der Produkte. `
    + `Stimmt der Token, und hat er das Recht "ai"?`);
  const j = await r.json();
  const erstes = (j?.data ?? [])[0];
  if (!erstes?.id) throw new Error("Keine AI-Tools-Produkte in diesem Infomaniak-Konto gefunden.");
  produktId = String(erstes.id);
  return produktId;
}

// --------------------------------------------------------------- Werkzeuge
//
// Nur lesende. Jedes bekommt den Client des Fragenden; was zurueckkommt,
// hat die Datenbank bereits gefiltert.
type Werkzeug = {
  name: string; beschreibung: string; schema: Record<string, unknown>;
  rollen: string[];
  lauf: (sb: any, a: any) => Promise<unknown>;
};

const WERKZEUGE: Werkzeug[] = [
  {
    name: "offene_posten",
    beschreibung: "Offene Beitraege und Rechnungen. Ohne Angabe fuer den ganzen Verein, "
      + "mit mitglied_name fuer eine Person. Ein Vertreter bekommt nur seine Nachbarschaft, "
      + "ein Mitglied nur sich selbst -- das regelt die Datenbank.",
    schema: { type: "object", properties: {
      jahr: { type: "integer", description: "Beitragsjahr, z.B. 2026" },
      mitglied_name: { type: "string", description: "Name oder Teil davon" },
    } },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD", "MEMBER", "REPRESENTATIVE"],
    lauf: async (sb, a) => {
      let q = sb.from("payments")
        .select('id,userId,amount,currency,status,billingYear,dueDate,invoiceNumber,description,dunningLevel')
        .neq("status", "PAID").neq("status", "CANCELLED").neq("status", "WRITTEN_OFF")
        .limit(200);
      if (a?.jahr) q = q.eq("billingYear", a.jahr);
      const { data: zahlungen, error } = await q;
      if (error) throw new Error(error.message);

      const ids = [...new Set((zahlungen ?? []).map((z: any) => z.userId))];
      const { data: leute } = ids.length
        ? await sb.from("users").select("id,displayName,email,sprache,neighborhoodId").in("id", ids)
        : { data: [] };
      const name = (id: string) => (leute ?? []).find((u: any) => u.id === id)?.displayName ?? id;

      let zeilen = (zahlungen ?? []).map((z: any) => ({
        // Die Kennung braucht eine Karte, um sich auf genau diese Rechnung
        // zu beziehen. Angezeigt wird sie nicht -- der Mensch prueft Name,
        // Betrag und Rechnungsnummer.
        id: z.id,
        mitglied: name(z.userId), betrag: z.amount, waehrung: z.currency,
        jahr: z.billingYear, faellig: z.dueDate, rechnung: z.invoiceNumber,
        zweck: z.description, mahnstufe: z.dunningLevel ?? 0, status: z.status,
      }));
      if (a?.mitglied_name) {
        const s = String(a.mitglied_name).toLowerCase();
        zeilen = zeilen.filter((z: any) => z.mitglied.toLowerCase().includes(s));
      }
      return { anzahl: zeilen.length,
               summe: zeilen.reduce((n: number, z: any) => n + Number(z.betrag || 0), 0),
               posten: zeilen.slice(0, 60) };
    },
  },
  {
    name: "mitglied_suchen",
    beschreibung: "Mitglieder nach Name, Ort oder Nachbarschaft finden. Liefert Stammdaten, "
      + "keine Notizen des Vorstands.",
    schema: { type: "object", properties: {
      suche: { type: "string", description: "Name, Ort oder Teil davon" },
      nur_aktive: { type: "boolean" },
    }, required: ["suche"] },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD", "REPRESENTATIVE"],
    lauf: async (sb, a) => {
      // Der Suchtext kommt aus dem Modell und damit mittelbar aus dem, was
      // jemand geschrieben hat. Er geht in einen PostgREST-Ausdruck, in dem
      // Komma und Klammer Trennzeichen sind -- ungefiltert liesse sich der
      // Ausdruck umbauen. An den Zeilenregeln aendert das nichts, aber eine
      // Abfrage soll das suchen, wonach gefragt wurde.
      const s = String(a?.suche ?? "").replace(/[,()*%\\]/g, " ").trim().slice(0, 60);
      if (!s) return { treffer: [] };
      let q = sb.from("users")
        .select("id,displayName,email,phone,city,zip,membershipStatus,membershipCategory,"
              + "billingGroup,neighborhoodId,joinedAt,sprache,role")
        .or(`displayName.ilike.%${s}%,city.ilike.%${s}%,email.ilike.%${s}%`)
        .limit(25);
      if (a?.nur_aktive) q = q.eq("membershipStatus", "ACTIVE");
      const { data, error } = await q;
      if (error) throw new Error(error.message);
      return { treffer: data ?? [] };
    },
  },
  {
    name: "kasse_auskunft",
    beschreibung: "Saldo je Konto aus der Buchhaltung, fuer ein Geschaeftsjahr.",
    schema: { type: "object", properties: { jahr: { type: "integer" } } },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (sb, a) => {
      const jahr = a?.jahr ?? new Date().getFullYear();
      const { data, error } = await sb.from("accounting_journal")
        .select("debitCode,creditCode,amount,date,description,belegnr")
        .gte("date", `${jahr}-01-01`).lte("date", `${jahr}-12-31`).limit(2000);
      if (error) throw new Error(error.message);
      const salden: Record<string, number> = {};
      for (const b of data ?? []) {
        if (b.debitCode)  salden[b.debitCode]  = (salden[b.debitCode]  ?? 0) + Number(b.amount || 0);
        if (b.creditCode) salden[b.creditCode] = (salden[b.creditCode] ?? 0) - Number(b.amount || 0);
      }
      return { jahr, buchungen: (data ?? []).length, salden };
    },
  },
  {
    name: "anmeldungen_zaehlen",
    beschreibung: "Teilnehmende zu einem Anlass oder einem Vereinstreffen. Eine Essenswahl "
      + "wird derzeit nicht erfasst -- nenne sie nicht.",
    schema: { type: "object", properties: { titel: { type: "string" } } },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD", "MEMBER", "REPRESENTATIVE"],
    lauf: async (sb, a) => {
      let qa = sb.from("events").select("id,title,date,time,location,status").limit(15);
      if (a?.titel) qa = qa.ilike("title", `%${a.titel}%`);
      const { data: anlaesse, error } = await qa;
      if (error) throw new Error(error.message);

      const out = [];
      for (const e of anlaesse ?? []) {
        const { data: an } = await sb.from("event_registrations")
          .select("id,tickets,status,type").eq("eventId", e.id).limit(1000);
        const gueltig = (an ?? []).filter((r: any) => r.status !== "CANCELLED");
        out.push({
          anlass: e.title, datum: e.date, zeit: e.time, ort: e.location, zustand: e.status,
          anmeldungen: gueltig.length,
          personen: gueltig.reduce((n: number, r: any) => n + Number(r.tickets || 1), 0),
        });
      }

      // Vereinstreffen fuehren ihre Zusagen in einer eigenen Tabelle.
      let qt = sb.from("treffen").select("id,titel,datum,ort,status").limit(10);
      if (a?.titel) qt = qt.ilike("titel", `%${a.titel}%`);
      const { data: treffen } = await qt;
      const treffenOut = [];
      for (const t of treffen ?? []) {
        const { data: tn } = await sb.from("treffen_teilnehmer")
          .select("art,zugesagt,personen,name").eq("treffen_id", t.id).limit(500);
        const zu = (tn ?? []).filter((r: any) => r.zugesagt === true);
        treffenOut.push({
          treffen: t.titel, datum: t.datum, ort: t.ort, zustand: t.status,
          eingeladen: (tn ?? []).length, zugesagt: zu.length,
          personen: zu.reduce((n: number, r: any) => n + Number(r.personen || 1), 0),
        });
      }
      return { anlaesse: out, treffen: treffenOut };
    },
  },
  {
    name: "textbaustein_lesen",
    beschreibung: "Einen Textbaustein des Vereins abrufen, um ihn als Grundlage zu nehmen. "
      + "Schluessel z.B. MAHNUNG_1, DANK_SPENDE, EINLADUNG_GV.",
    schema: { type: "object", properties: {
      schluessel: { type: "string" }, sprache: { type: "string", enum: ["de", "sq", "en"] },
    } },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (sb, a) => {
      let q = sb.from("textbausteine").select("schluessel,sprache,betreff,text").limit(40);
      if (a?.schluessel) q = q.eq("schluessel", a.schluessel);
      if (a?.sprache) q = q.eq("sprache", a.sprache);
      const { data, error } = await q;
      if (error) throw new Error(error.message);
      return { bausteine: data ?? [] };
    },
  },
];

// ------------------------------------------------------------- Karten
//
// Ein Kartenwerkzeug SCHREIBT NICHT. Es fuellt eine Karte, die zurueck an
// die Oberflaeche geht; erst der Klick eines Menschen loest etwas aus, und
// zwar ueber dieselbe Funktion, die auch die Handarbeit benutzt.
//
// Dem Modell wird als Werkzeugergebnis ausdruecklich gesagt, dass nichts
// geschehen ist. Ohne das schreibt es hinterher "ist gebucht" -- und die
// Oberflaeche zeigte eine unbestaetigte Karte neben einem Satz, der das
// Gegenteil behauptet.

type Karte = { art: string; titel: string; felder: [string, string][]; werte: Record<string, unknown> };

const KARTEN: Werkzeug[] = [
  {
    name: "zahlung_erfassen",
    beschreibung: "Bereitet vor, eine offene Rechnung als bezahlt zu kennzeichnen. "
      + "Die Kennung bekommst du aus offene_posten. Es wird nichts gebucht -- "
      + "die Vereinsverwaltung bestaetigt die Karte.",
    schema: { type: "object", properties: {
      rechnung_id: { type: "string", description: "id aus offene_posten" },
      mitglied: { type: "string", description: "Name, nur zur Anzeige auf der Karte" },
      betrag: { type: "number" },
      weg: { type: "string", enum: ["CASH", "TWINT", "BANK_TRANSFER", "QR_BILL", "PAYPAL"] },
      datum: { type: "string", description: "TT.MM.JJJJ oder JJJJ-MM-TT" },
    }, required: ["rechnung_id", "weg"] },
    rollen: ["SUPER_ADMIN", "ADMIN"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "barzahlung_melden",
    beschreibung: "Bereitet die Meldung einer Barzahlung vor, die der Vertreter "
      + "entgegengenommen hat. Die Verwaltung entscheidet, ob sie gilt.",
    schema: { type: "object", properties: {
      rechnung_id: { type: "string" }, mitglied: { type: "string" },
      betrag: { type: "number" }, datum: { type: "string" }, bemerkung: { type: "string" },
    }, required: ["rechnung_id"] },
    rollen: ["REPRESENTATIVE", "SUPER_ADMIN", "ADMIN"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "buchung_vorschlagen",
    beschreibung: "Bereitet eine Buchung vor: Datum, Soll- und Habenkonto, Betrag, Text. "
      + "Ein gesperrtes Jahr weist die Buchhaltung ab -- sag das, statt es zu versuchen.",
    schema: { type: "object", properties: {
      datum: { type: "string" }, soll: { type: "string", description: "Kontonummer, z.B. 1020" },
      haben: { type: "string" }, betrag: { type: "number" }, text: { type: "string" },
    }, required: ["soll", "haben", "betrag", "text"] },
    rollen: ["SUPER_ADMIN", "ADMIN"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "mahnung_vorschlagen",
    beschreibung: "Bereitet eine Mahnung fuer eine offene Rechnung vor. Die Stufe ergibt "
      + "sich aus der bisherigen; Text und Sprache kommen aus den Textbausteinen des "
      + "Vereins. Schreibe den Brief NICHT selbst -- er steht schon da.",
    schema: { type: "object", properties: {
      rechnung_id: { type: "string", description: "id aus offene_posten" },
      mitglied: { type: "string" }, betrag: { type: "number" },
      stufe: { type: "integer", description: "Nur zur Anzeige; die Stufe zaehlt der Server" },
    }, required: ["rechnung_id"] },
    rollen: ["SUPER_ADMIN", "ADMIN"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "text_entwerfen",
    beschreibung: "Legt einen Entwurf fuer eine Neuigkeit auf der Vereinswebsite an. "
      + "Er wird NICHT veroeffentlicht -- er landet als Entwurf und der Verein "
      + "gibt ihn frei. Schreibe Titel und Text vollstaendig aus.",
    schema: { type: "object", properties: {
      titel: { type: "string" }, text: { type: "string" },
    }, required: ["titel", "text"] },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "mitglied_erfassen",
    beschreibung: "Bereitet die Aufnahme eines neuen Mitglieds vor. Frage nach, was fehlt — "
      + "ein Mitglied ohne Adresse bekommt keine Rechnung. Erfinde nichts.",
    schema: { type: "object", properties: {
      vorname: { type: "string" }, nachname: { type: "string" },
      email: { type: "string" }, telefon: { type: "string" },
      strasse: { type: "string" }, plz: { type: "string" }, ort: { type: "string" },
      kategorie: { type: "string", enum: ["AKTIV", "PASSIV", "INDIVIDUAL"] },
      beitragsgruppe: { type: "string", enum: ["STANDARD", "KOSOVO"] },
      nachbarschaft: { type: "string", description: "Name der Lagje" },
      sprache: { type: "string", enum: ["de", "sq", "en"] },
    }, required: ["vorname", "nachname"] },
    rollen: ["SUPER_ADMIN", "ADMIN"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "anlass_anlegen",
    beschreibung: "Bereitet einen Anlass vor. Er wird als Entwurf angelegt, nicht "
      + "veroeffentlicht — der Verein gibt ihn frei.",
    schema: { type: "object", properties: {
      titel: { type: "string" }, datum: { type: "string" }, zeit: { type: "string" },
      ort: { type: "string" }, beschreibung: { type: "string" },
      anmeldung: { type: "boolean", description: "Koennen sich Mitglieder anmelden?" },
    }, required: ["titel", "datum"] },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "spendenaufruf_entwerfen",
    beschreibung: "Bereitet einen Spendenaufruf vor. Schreibe Titel und Text vollstaendig aus. "
      + "Er wird als Entwurf abgelegt, nicht veroeffentlicht.",
    schema: { type: "object", properties: {
      titel: { type: "string" }, text: { type: "string" },
      zielbetrag: { type: "number" }, endet_am: { type: "string" },
    }, required: ["titel", "text"] },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (_sb, a) => a,
  },
  {
    name: "protokoll_entwerfen",
    beschreibung: "Bereitet aus Stichworten einen Sitzungsentwurf vor: Traktanden und "
      + "Beschluesse. Erfinde keine Beschluesse, die nicht in den Stichworten stehen.",
    schema: { type: "object", properties: {
      titel: { type: "string" }, datum: { type: "string" }, ort: { type: "string" },
      traktanden: { type: "array", items: { type: "object", properties: {
        titel: { type: "string" }, inhalt: { type: "string" } }, required: ["titel"] } },
      beschluesse: { type: "array", items: { type: "object", properties: {
        titel: { type: "string" }, inhalt: { type: "string" },
        zustaendig: { type: "string" }, frist: { type: "string" } }, required: ["titel"] } },
    }, required: ["titel"] },
    rollen: ["SUPER_ADMIN", "ADMIN", "BOARD"],
    lauf: async (_sb, a) => a,
  },
];

const KARTE_BAUEN = (name: string, a: any): Karte | null => {
  const z = (v: unknown) => (v === undefined || v === null || v === "" ? "—" : String(v));
  const geld = (v: unknown) => (v === undefined || v === null ? "—"
    : `CHF ${Number(v).toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`);
  const WEGE: Record<string, string> = { CASH: "Bar", TWINT: "TWINT",
    BANK_TRANSFER: "Banküberweisung", QR_BILL: "QR-Rechnung", PAYPAL: "PayPal" };

  if (name === "zahlung_erfassen") {
    if (!a?.rechnung_id) return null;
    return { art: "zahlung_erfassen", titel: "Zahlung erfassen",
      felder: [["Mitglied", z(a.mitglied)], ["Betrag", geld(a.betrag)],
               ["Zahlungsweg", WEGE[a.weg] ?? z(a.weg)], ["Datum", z(a.datum)]],
      werte: { rechnung_id: a.rechnung_id, weg: a.weg, datum: a.datum } };
  }
  if (name === "barzahlung_melden") {
    if (!a?.rechnung_id) return null;
    return { art: "barzahlung_melden", titel: "Barzahlung melden",
      felder: [["Mitglied", z(a.mitglied)], ["Betrag", geld(a.betrag)],
               ["Datum", z(a.datum)], ["Bemerkung", z(a.bemerkung)]],
      werte: { rechnung_id: a.rechnung_id, datum: a.datum, bemerkung: a.bemerkung } };
  }
  if (name === "buchung_vorschlagen") {
    if (!a?.soll || !a?.haben) return null;
    return { art: "buchung_vorschlagen", titel: "Buchung vorschlagen",
      felder: [["Datum", z(a.datum)], ["Soll", z(a.soll)], ["Haben", z(a.haben)],
               ["Betrag", geld(a.betrag)], ["Text", z(a.text)]],
      werte: { datum: a.datum, soll: a.soll, haben: a.haben,
               betrag: a.betrag, text: a.text } };
  }
  if (name === "mahnung_vorschlagen") {
    if (!a?.rechnung_id) return null;
    return { art: "mahnung_vorschlagen", titel: "Mahnung verschicken",
      felder: [["Mitglied", z(a.mitglied)], ["Offener Betrag", geld(a.betrag)],
               ["Stufe", a.stufe ? `${a.stufe}. Mahnung` : "naechste Stufe"],
               ["Text", "aus den Textbausteinen, in der Sprache des Mitglieds"]],
      werte: { rechnung_id: a.rechnung_id } };
  }
  if (name === "text_entwerfen") {
    if (!a?.titel || !a?.text) return null;
    const gekuerzt = String(a.text).length > 400
      ? String(a.text).slice(0, 400) + " …" : String(a.text);
    return { art: "text_entwerfen", titel: "Neuigkeit als Entwurf ablegen",
      felder: [["Titel", z(a.titel)], ["Text", gekuerzt],
               ["Veröffentlichung", "nein — nur Entwurf"]],
      werte: { titel: a.titel, text: a.text } };
  }
  if (name === "mitglied_erfassen") {
    if (!a?.vorname || !a?.nachname) return null;
    const anschrift = [a.strasse, [a.plz, a.ort].filter(Boolean).join(" ")]
      .filter(Boolean).join(", ");
    return { art: "mitglied_erfassen", titel: "Mitglied aufnehmen",
      felder: [["Name", `${a.vorname} ${a.nachname}`], ["E-Mail", z(a.email)],
               ["Telefon", z(a.telefon)], ["Adresse", z(anschrift)],
               ["Kategorie", z(a.kategorie)], ["Beitragsgruppe", z(a.beitragsgruppe)],
               ["Nachbarschaft", z(a.nachbarschaft)], ["Sprache", z(a.sprache)]],
      werte: { vorname: a.vorname, nachname: a.nachname, email: a.email, telefon: a.telefon,
               strasse: a.strasse, plz: a.plz, ort: a.ort, kategorie: a.kategorie,
               beitragsgruppe: a.beitragsgruppe, nachbarschaft: a.nachbarschaft,
               sprache: a.sprache } };
  }
  if (name === "anlass_anlegen") {
    if (!a?.titel || !a?.datum) return null;
    return { art: "anlass_anlegen", titel: "Anlass anlegen",
      felder: [["Titel", z(a.titel)], ["Datum", z(a.datum)], ["Zeit", z(a.zeit)],
               ["Ort", z(a.ort)], ["Anmeldung", a.anmeldung ? "ja" : "nein"],
               ["Veröffentlichung", "nein — nur Entwurf"]],
      werte: { titel: a.titel, datum: a.datum, zeit: a.zeit, ort: a.ort,
               beschreibung: a.beschreibung, anmeldung: !!a.anmeldung } };
  }
  if (name === "spendenaufruf_entwerfen") {
    if (!a?.titel || !a?.text) return null;
    const gekuerzt = String(a.text).length > 400
      ? String(a.text).slice(0, 400) + " …" : String(a.text);
    return { art: "spendenaufruf_entwerfen", titel: "Spendenaufruf als Entwurf ablegen",
      felder: [["Titel", z(a.titel)], ["Text", gekuerzt],
               ["Zielbetrag", a.zielbetrag ? geld(a.zielbetrag) : "—"],
               ["Läuft bis", z(a.endet_am)], ["Veröffentlichung", "nein — nur Entwurf"]],
      werte: { titel: a.titel, text: a.text, zielbetrag: a.zielbetrag, endet_am: a.endet_am } };
  }
  if (name === "protokoll_entwerfen") {
    if (!a?.titel) return null;
    const tr = Array.isArray(a.traktanden) ? a.traktanden : [];
    const be = Array.isArray(a.beschluesse) ? a.beschluesse : [];
    return { art: "protokoll_entwerfen", titel: "Sitzung als Entwurf ablegen",
      felder: [["Titel", z(a.titel)], ["Datum", z(a.datum)], ["Ort", z(a.ort)],
               ["Traktanden", tr.length ? tr.map((t: any) => `· ${t.titel}`).join("\n") : "—"],
               ["Beschlüsse", be.length
                 ? be.map((b: any) => `· ${b.titel}`
                     + (b.zustaendig ? ` (${b.zustaendig}${b.frist ? `, bis ${b.frist}` : ""})` : ""))
                     .join("\n")
                 : "—"]],
      werte: { titel: a.titel, datum: a.datum, ort: a.ort, traktanden: tr, beschluesse: be } };
  }
  return null;
};

// --------------------------------------------------------- Kurzbefehle
//
// Zwei Arten, und der Unterschied ist wichtig:
//
//   /hilfe und /wochenstart werden HIER beantwortet, ohne KI. Das Konzept
//   verlangt das ausdruecklich, und es ist auch richtig so: eine Liste der
//   eigenen Faehigkeiten von einem Sprachmodell erfinden zu lassen, ist
//   eine Einladung zur Fantasie. Ohne KI heisst zugleich: ohne Kontingent.
//
//   Alle uebrigen werden zu einer klaren Anweisung ausgeschrieben und der
//   Nachricht vorangestellt. "/mahnung Arben" allein versteht kein Modell
//   als Auftrag -- ausgeschrieben schon.

const BEFEHLE: Record<string, { zweck: string; rollen: string[] }> = {
  mitglied:   { zweck: "Ein Mitglied aufnehmen oder Stammdaten aendern.", rollen: ["SUPER_ADMIN","ADMIN"] },
  beitrag:    { zweck: "Den Beitragslauf vorbereiten oder offene Beitraege zeigen.", rollen: ["SUPER_ADMIN","ADMIN","BOARD"] },
  mahnung:    { zweck: "Fuer offene Rechnungen die naechste Mahnstufe vorschlagen.", rollen: ["SUPER_ADMIN","ADMIN"] },
  zahlung:    { zweck: "Eine Zahlung oder Barzahlung erfassen.", rollen: ["SUPER_ADMIN","ADMIN","REPRESENTATIVE"] },
  buchung:    { zweck: "Eine Buchung vorschlagen.", rollen: ["SUPER_ADMIN","ADMIN"] },
  anlass:     { zweck: "Einen Anlass oder ein Treffen anlegen, Anmeldungen zaehlen.", rollen: ["SUPER_ADMIN","ADMIN","BOARD"] },
  spende:     { zweck: "Einen Spendenaufruf entwerfen oder einem Spender danken.", rollen: ["SUPER_ADMIN","ADMIN","BOARD"] },
  news:       { zweck: "Eine Neuigkeit fuer die Website entwerfen.", rollen: ["SUPER_ADMIN","ADMIN","BOARD"] },
  protokoll:  { zweck: "Aus Stichworten einen Protokollentwurf machen.", rollen: ["SUPER_ADMIN","ADMIN","BOARD"] },
};

// Die Oberflaeche fragt diese Liste ab, damit die Befehle auffindbar sind.
// Ein Kuerzel, das niemand kennt, ist keines.
function befehlsliste(rolle: string) {
  const eigene = Object.entries(BEFEHLE)
    .filter(([, b]) => b.rollen.includes(rolle))
    .map(([name, b]) => ({ name: `/${name}`, zweck: b.zweck }));
  return [
    { name: "/hilfe", zweck: "Was ich kann — ohne KI-Anfrage." },
    { name: "/wochenstart", zweck: "Offene Beitraege, Meldungen, naechste Anlaesse — ohne KI-Anfrage." },
    ...eigene,
  ];
}

function hilfetext(rolle: string, name: string, sprache: string): string {
  const liste = befehlsliste(rolle).map((b) => `${b.name} — ${b.zweck}`).join("\n");
  const kuerzel = sprache === "sq"
    ? "@ anëtar/familje/ngjarje · // datë · # lagje/kategori/llogari · ! prioritet · > tekst i gatshëm"
    : "@ Mitglied/Familie/Anlass · // Datum · # Nachbarschaft/Kategorie/Konto · ! Priorität · > Textbaustein";
  const kopf = sprache === "sq"
    ? `Unë jam ${name}. Shkruani lirisht — shqip, gjermanisht ose anglisht.`
    : sprache === "en"
    ? `I am ${name}. Just write — German, Albanian or English.`
    : `Ich bin ${name}. Schreiben Sie einfach — deutsch, shqip oder englisch.`;
  const schluss = sprache === "sq"
    ? "Unë propozoj; ju vendosni. Asgjë nuk regjistrohet pa konfirmimin tuaj."
    : sprache === "en"
    ? "I propose; you decide. Nothing is recorded without your confirmation."
    : "Ich schlage vor, Sie entscheiden. Ohne Ihre Bestätigung wird nichts gebucht.";
  return `${kopf}\n\n${liste}\n\n${kuerzel}\n\n${schluss}`;
}

// Teilt eine Nachricht in Befehl und Rest.
function befehlLesen(text: string): { befehl: string | null; rest: string } {
  const m = String(text ?? "").trim().match(/^\/([a-zA-ZäöüÄÖÜ]+)\s*([\s\S]*)$/);
  if (!m) return { befehl: null, rest: String(text ?? "") };
  return { befehl: m[1].toLowerCase(), rest: m[2] };
}

// ------------------------------------------------------- Inline-Kuerzel
//
// @ Mitglied/Familie/Anlass/Rechnung · // Datum · # Nachbarschaft/Kategorie/
// Konto · ! Prioritaet · > Textbaustein
//
// Sie werden HIER aufgeloest, gegen die Datenbank, und das Ergebnis geht
// als Tatsache an das Modell. Der Grund ist derselbe wie ueberall:
// ">Mahnung 1" soll den Text des Vereins einsetzen, nicht einen, den sich
// ein Sprachmodell ausdenkt. Ein erfundener Mahntext geht an ein Mitglied
// hinaus und ist dann nicht mehr einzuholen.
//
// Gelesen wird mit dem Konto des Fragenden. Ein Vertreter loest damit nur
// auf, was er ohnehin sehen darf -- das muss hier nicht programmiert
// werden, die Zeilenregeln tun es.
//
// Mehrdeutigkeit wird NICHT aufgeloest. Zwei Mitglieder "Gashi" ergeben
// eine Rueckfrage, keine Auswahl per Zufall.

type Treffer = { kuerzel: string; aufloesung: string; zusatz?: string };

// Wie weit reicht ein Name? "@Arben Gashi hat bezahlt" soll Arben Gashi
// finden, nicht "Arben Gashi hat bezahlt". Deshalb werden bis zu vier
// Woerter genommen und von der laengsten Fassung abwaerts probiert -- die
// Datenbank entscheidet, wo der Name endet.
function kandidaten(rest: string, maxWorte = 4): string[] {
  const worte = rest.trim().split(/\s+/).slice(0, maxWorte);
  const out: string[] = [];
  for (let n = worte.length; n >= 1; n--) {
    const s = worte.slice(0, n).join(" ").replace(/[.,;:!?]+$/, "");
    if (s) out.push(s);
  }
  return out;
}

function heuteInZuerich(): Date {
  const s = new Date().toLocaleDateString("en-CA", { timeZone: "Europe/Zurich" });
  return new Date(s + "T00:00:00");
}
const alsIso = (d: Date) => d.toISOString().slice(0, 10);
const alsSchweiz = (d: Date) => d.toLocaleDateString("de-CH");

// Datum aufloesen. Was sich nicht eindeutig bestimmen laesst, wird NICHT
// geraten -- "//GV" kann der Mensch meinen, aber nur er weiss welche.
function datumLesen(text: string): { iso: string; wie: string } | null {
  const t = text.trim().toLowerCase();
  const heute = heuteInZuerich();
  const plus = (tage: number) => { const d = new Date(heute); d.setDate(d.getDate() + tage); return d; };

  let m = t.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})/);
  if (m) return { iso: `${m[3]}-${m[2].padStart(2,"0")}-${m[1].padStart(2,"0")}`, wie: "Datum" };
  m = t.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (m) return { iso: `${m[1]}-${m[2]}-${m[3]}`, wie: "Datum" };
  // Ohne Jahr: das naechste Vorkommen, nicht das vergangene.
  m = t.match(/^(\d{1,2})\.(\d{1,2})\.?$/);
  if (m) {
    const tag = +m[1], monat = +m[2];
    let jahr = heute.getFullYear();
    const d = new Date(`${jahr}-${String(monat).padStart(2,"0")}-${String(tag).padStart(2,"0")}T00:00:00`);
    if (d < heute) { jahr++; }
    return { iso: `${jahr}-${String(monat).padStart(2,"0")}-${String(tag).padStart(2,"0")}`,
             wie: "Datum (Jahr ergaenzt)" };
  }

  if (/^(heute|sot|today)$/.test(t)) return { iso: alsIso(heute), wie: "heute" };
  if (/^(morgen|nes[eë]r|tomorrow)$/.test(t)) return { iso: alsIso(plus(1)), wie: "morgen" };
  if (/^([uü]bermorgen|pasnes[eë]r)$/.test(t)) return { iso: alsIso(plus(2)), wie: "uebermorgen" };

  m = t.match(/^in\s+(\d{1,3})\s*(tag|tage|tagen|dit[eë]|days?)$/);
  if (m) return { iso: alsIso(plus(+m[1])), wie: `in ${m[1]} Tagen` };
  m = t.match(/^in\s+(\d{1,2})\s*(woche|wochen|jav[eë]|weeks?)$/);
  if (m) return { iso: alsIso(plus(+m[1] * 7)), wie: `in ${m[1]} Wochen` };

  if (/^(ende monat|monatsende|fundi i muajit|end of month)$/.test(t)) {
    const d = new Date(heute.getFullYear(), heute.getMonth() + 1, 0);
    return { iso: alsIso(d), wie: "Ende des Monats" };
  }
  if (/^(n[aä]chste woche|java e ardhshme|next week)$/.test(t)) {
    return { iso: alsIso(plus(7)), wie: "in einer Woche" };
  }
  if (/^(ende jahr|jahresende|fundi i vitit|end of year)$/.test(t)) {
    return { iso: `${heute.getFullYear()}-12-31`, wie: "Ende des Jahres" };
  }
  return null;
}

// Freundliche Namen auf Schluessel. "Mahnung 1" tippt sich leichter als
// MAHNUNG_1, und das Konzept nennt genau diese Schreibweise.
function bausteinSchluessel(text: string): string {
  return text.trim().toUpperCase()
    .replace(/[ÄÖÜ]/g, (z) => ({ "Ä":"AE","Ö":"OE","Ü":"UE" }[z] as string))
    .replace(/[^A-Z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

async function kuerzelAufloesen(sb: any, text: string, sprache: string) {
  const treffer: Treffer[] = [];
  const offen: string[] = [];
  const gesehen = new Set<string>();

  // Erst die Marken FINDEN, dann dazwischen schneiden.
  //
  // Ein einziger Ausdruck, der Zeichen und Rest zusammen greift, verschluckt
  // die ganze Zeile: "@Arben //morgen >Mahnung 1" waere EINE Fundstelle, und
  // alles nach dem @ ginge verloren. Genau das ist passiert.
  //
  // Die Marke muss am Wortanfang stehen -- sonst waere jede E-Mail-Adresse
  // ein Mitgliedsverweis.
  const roh = String(text);
  const stellen: { zeichen: string; von: number }[] = [];
  for (const m of roh.matchAll(/(?:^|\s)(\/\/|@|#|!|>)(?=[^\s@#!>])/g)) {
    stellen.push({ zeichen: m[1], von: m.index! + m[0].length });
  }

  for (let i = 0; i < stellen.length; i++) {
    const zeichen = stellen[i].zeichen;
    // Bis zur naechsten Marke -- oder bis zum Ende.
    const bis = i + 1 < stellen.length
      ? stellen[i + 1].von - stellen[i + 1].zeichen.length - 1 : roh.length;
    const rest = roh.slice(stellen[i].von, Math.max(bis, stellen[i].von));

    // ---------------------------------------------------------- Prioritaet
    if (zeichen === "!") {
      const wort = rest.trim().split(/\s+/)[0].replace(/[.,;:!?]+$/, "");
      if (!wort) continue;
      const k = `!${wort}`;
      if (gesehen.has(k)) continue; gesehen.add(k);
      treffer.push({ kuerzel: k, aufloesung: `als "${wort}" gekennzeichnet — vorziehen` });
      continue;
    }

    // ---------------------------------------------------------- Datum
    if (zeichen === "//") {
      let gefunden = false;
      for (const kand of kandidaten(rest, 3)) {
        const d = datumLesen(kand);
        if (!d) continue;
        const k = `//${kand}`;
        if (!gesehen.has(k)) {
          gesehen.add(k);
          treffer.push({ kuerzel: k,
            aufloesung: `${alsSchweiz(new Date(d.iso + "T00:00:00"))} (${d.iso}) — ${d.wie}` });
        }
        gefunden = true; break;
      }
      if (!gefunden) {
        // "//GV" kann der Mensch meinen -- aber nur er weiss, welche.
        offen.push(`//${rest.trim().split(/\s+/).slice(0, 2).join(" ")} `
          + `— kein eindeutiges Datum; frag nach, welches gemeint ist`);
      }
      continue;
    }

    // ---------------------------------------------------------- Baustein
    if (zeichen === ">") {
      let gefunden = false;
      for (const kand of kandidaten(rest, 3)) {
        const schluessel = bausteinSchluessel(kand);
        const { data } = await sb.from("textbausteine")
          .select("schluessel,sprache,betreff,text").eq("schluessel", schluessel);
        if (data?.length) {
          const k = `>${kand}`;
          if (gesehen.has(k)) { gefunden = true; break; }
          gesehen.add(k);
          const eigene = data.find((b: any) => b.sprache === sprache) ?? data[0];
          treffer.push({ kuerzel: k,
            aufloesung: `Textbaustein ${schluessel}, vorhanden in: ${data.map((b: any) => b.sprache).join(", ")}`,
            zusatz: `Betreff: ${eigene.betreff ?? "—"}\nText:\n${eigene.text}` });
          gefunden = true; break;
        }
      }
      if (!gefunden) {
        const { data: alle } = await sb.from("textbausteine").select("schluessel");
        const namen = [...new Set((alle ?? []).map((b: any) => b.schluessel))];
        offen.push(`>${rest.trim().split(/\s+/).slice(0,2).join(" ")} — kein solcher Textbaustein. `
          + `Vorhanden: ${namen.join(", ") || "keine"}`);
      }
      continue;
    }

    // ---------------------------------------------------------- # und @
    let erledigt = false;
    for (const kand of kandidaten(rest)) {
      const k = `${zeichen}${kand}`;
      if (gesehen.has(k)) { erledigt = true; break; }

      const funde: string[] = [];

      if (zeichen === "#") {
        const { data: lagje } = await sb.from("neighborhoods")
          .select("id,name").ilike("name", kand).limit(5);
        for (const n of lagje ?? []) funde.push(`Nachbarschaft „${n.name}"`);

        // Zwei Abfragen statt .or(): in einem PostgREST-or sind Komma und
        // Punkt Trennzeichen, und der Text kommt aus dem, was jemand
        // getippt hat. Eine Abfrage soll suchen, wonach gefragt wurde.
        const { data: perCode } = await sb.from("accounting_accounts")
          .select("code,name").eq("code", kand).limit(5);
        const { data: perName } = await sb.from("accounting_accounts")
          .select("code,name").ilike("name", kand).limit(5);
        for (const c of [...(perCode ?? []), ...(perName ?? [])])
          funde.push(`Konto ${c.code} „${c.name}"`);

        const gross = kand.toUpperCase();
        if (["AKTIV","PASSIV","INDIVIDUAL"].includes(gross)) funde.push(`Mitgliederkategorie ${gross}`);
        if (["STANDARD","KOSOVO"].includes(gross)) funde.push(`Beitragsgruppe ${gross}`);
      } else {
        const { data: leute } = await sb.from("users")
          .select("id,displayName,email,membershipStatus").ilike("displayName", kand).limit(5);
        for (const u of leute ?? [])
          funde.push(`Mitglied „${u.displayName}" (id ${u.id}, ${u.membershipStatus})`);

        const { data: fam } = await sb.from("families").select("id,name").ilike("name", kand).limit(5);
        for (const f of fam ?? []) funde.push(`Familie „${f.name}" (id ${f.id})`);

        const { data: anl } = await sb.from("events").select("id,title,date").ilike("title", kand).limit(5);
        for (const e of anl ?? []) funde.push(`Anlass „${e.title}" am ${e.date} (id ${e.id})`);

        const { data: tr } = await sb.from("treffen").select("id,titel,datum").ilike("titel", kand).limit(5);
        for (const t of tr ?? []) funde.push(`Treffen „${t.titel}" am ${t.datum} (id ${t.id})`);

        const { data: re } = await sb.from("payments")
          .select("id,invoiceNumber,amount,status").eq("invoiceNumber", kand).limit(5);
        for (const p of re ?? [])
          funde.push(`Rechnung ${p.invoiceNumber} über ${p.amount} (${p.status}, id ${p.id})`);
      }

      if (funde.length === 1) {
        gesehen.add(k);
        treffer.push({ kuerzel: k, aufloesung: funde[0] });
        erledigt = true; break;
      }
      if (funde.length > 1) {
        gesehen.add(k);
        // Mehrdeutig: ausdruecklich NICHT entscheiden.
        offen.push(`${k} — mehrdeutig: ${funde.join(" | ")}. Frag nach, wer gemeint ist.`);
        erledigt = true; break;
      }
    }
    if (!erledigt) {
      const kurz = rest.trim().split(/\s+/).slice(0, 2).join(" ");
      offen.push(`${zeichen}${kurz} — nichts gefunden. Rate nicht; frag nach.`);
    }
  }

  if (!treffer.length && !offen.length) return null;

  const zeilen = [
    ...treffer.map((t) => `${t.kuerzel} → ${t.aufloesung}` + (t.zusatz ? `\n${t.zusatz}` : "")),
    ...offen.map((o) => `${o}`),
  ];
  return {
    // Fuer das Modell: als Tatsachen, mit dem vollen Bausteintext.
    text: `[Aufgelöste Kürzel — das sind Tatsachen aus der Datenbank, nicht zu ändern:\n`
        + zeilen.join("\n") + `\n]`,
    // Fuer den Menschen: knapp, ohne den Bausteintext -- er soll sehen,
    // WAS verstanden wurde, nicht den ganzen Brief noch einmal.
    liste: [
      ...treffer.map((t) => ({ kuerzel: t.kuerzel, wurde: t.aufloesung, offen: false })),
      ...offen.map((o) => ({ kuerzel: o.split(" — ")[0], wurde: o.split(" — ").slice(1).join(" — "),
                             offen: true })),
    ],
  };
}

// ------------------------------------------------------------ Wochenstart
//
// Ohne KI, aus der Datenbank. Gelesen wird mit dem Konto des Fragenden --
// ein Vertreter bekommt damit nur seine Nachbarschaft zu sehen, ohne dass
// das hier eigens programmiert werden muesste.
//
// Es wird nur genannt, was tatsaechlich da ist. Eine Uebersicht, die
// "0 offene Meldungen" neben "0 Anlaesse" neben "0 Pendenzen" stellt, liest
// niemand zweimal.
async function wochenstart(sb: any, rolle: string, sprache: string): Promise<string> {
  const chf = (n: number) =>
    `CHF ${n.toLocaleString("de-CH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  const W = sprache === "sq"
    ? { titel: "Fillimi i javës", offen: "Kuota të hapura", meldungen: "Pagesa të raportuara, në pritje",
        anlaesse: "Ngjarjet e 14 ditëve të ardhshme", nichts: "Asgjë për të raportuar — java është e qetë.",
        posten: "pozicione", personen: "persona" }
    : sprache === "en"
    ? { titel: "Week start", offen: "Open fees", meldungen: "Reported payments awaiting a decision",
        anlaesse: "Events in the next 14 days", nichts: "Nothing to report — a quiet week.",
        posten: "items", personen: "people" }
    : { titel: "Wochenstart", offen: "Offene Beiträge", meldungen: "Gemeldete Zahlungen, noch offen",
        anlaesse: "Anlässe der nächsten 14 Tage", nichts: "Nichts zu melden — eine ruhige Woche.",
        posten: "Posten", personen: "Personen" };

  const teile: string[] = [];

  // Offene Beitraege
  const { data: offen } = await sb.from("payments")
    .select("amount,status").neq("status", "PAID")
    .neq("status", "CANCELLED").neq("status", "WRITTEN_OFF").limit(1000);
  if (offen?.length) {
    const summe = offen.reduce((n: number, z: any) => n + Number(z.amount || 0), 0);
    teile.push(`**${W.offen}:** ${offen.length} ${W.posten}, ${chf(summe)}`);
  }

  // Meldungen der Vertreter, die auf Entscheid warten
  if (["SUPER_ADMIN", "ADMIN", "BOARD"].includes(rolle)) {
    const { data: meld } = await sb.from("payment_reports")
      .select("amount,method,paidOn").eq("status", "OPEN").limit(200);
    if (meld?.length) {
      const summe = meld.reduce((n: number, m: any) => n + Number(m.amount || 0), 0);
      teile.push(`**${W.meldungen}:** ${meld.length} × ${chf(summe)}`);
    }
  }

  // Anlaesse der naechsten 14 Tage
  const heute = new Date().toISOString().slice(0, 10);
  const in14 = new Date(Date.now() + 14 * 864e5).toISOString().slice(0, 10);
  const { data: anl } = await sb.from("events")
    .select("id,title,date").gte("date", heute).lte("date", in14)
    .order("date").limit(10);
  if (anl?.length) {
    const zeilen: string[] = [];
    for (const e of anl) {
      const { data: an } = await sb.from("event_registrations")
        .select("tickets,status").eq("eventId", e.id).limit(1000);
      const gueltig = (an ?? []).filter((r: any) => r.status !== "CANCELLED");
      const kopf = gueltig.reduce((n: number, r: any) => n + Number(r.tickets || 1), 0);
      const d = new Date(e.date).toLocaleDateString("de-CH");
      zeilen.push(`· ${d} — ${e.title} (${kopf} ${W.personen})`);
    }
    teile.push(`**${W.anlaesse}:**\n${zeilen.join("\n")}`);
  }

  if (!teile.length) return W.nichts;
  return `**${W.titel}**\n\n${teile.join("\n\n")}`;
}


// ------------------------------------------------------------ Systemtext
const SPRACHNAME: Record<string, string> = {
  de: "Deutsch", sq: "Albanisch (shqip)", en: "Englisch",
};

function systemtext(k: {
  name: string; verein: string; person: string; rolle: string;
  nachbarschaft: string | null; module: string[]; glossar: string;
  du: boolean; werkzeuge: string[]; sprache: string;
}) {
  const heute = new Date().toLocaleDateString("de-CH", { timeZone: "Europe/Zurich" });
  return `Du bist ${k.name}, der Helfer des Vereins ${k.verein} in unityhub.
Du sprichst mit ${k.person}, Rolle ${k.rolle}${k.nachbarschaft ? `, Vertreter für ${k.nachbarschaft}` : ""}.
Heute ist ${heute} (Europe/Zurich). Gebuchte Module: ${k.module.join(", ") || "keine"}.

Der Verein arbeitet ehrenamtlich. Sei kurz, freundlich und konkret: zuerst das Ergebnis, dann was fehlt.

Sprache:
- ANTWORTE AUF ${SPRACHNAME[k.sprache] ?? "Deutsch"}. Das ist die Sprache, die diese Person eingestellt hat. Sie gilt auch dann, wenn der Vereinsname, das Glossar oder Mitgliedernamen albanisch sind — daran erkennst du die Sprache nicht.
- Nur wenn die letzte Nachricht eindeutig in einer anderen Sprache geschrieben ist, antwortest du in dieser.
- Texte an Mitglieder in deren hinterlegter Sprache; fehlt sie: Albanisch, darunter Deutsch.
- Vereinsbegriffe nach dem Glossar: ${k.glossar || "keines hinterlegt"}.
- Namen von Personen und Orten nie verändern (ë, ç beibehalten).
- Beträge als CHF 1'250.00, Daten als TT.MM.JJJJ, auch im albanischen Text.
- Gegenüber Mitgliedern ${k.du ? "«du»" : "«Sie»"}.

Regeln:
1. Was etwas schreibt, versendet oder veröffentlicht, kannst du nicht tun. Du bereitest es vor und sagst, was der Mensch bestätigen muss. Behaupte nie, etwas sei gebucht, verschickt oder veröffentlicht.
2. Du arbeitest nur für diesen Verein und nur mit den Daten, die diese Rolle sehen darf.
3. Buchungen sind Vorschläge. Ein gesperrtes Jahr wird nicht verändert; sag das und schlage eine Korrekturbuchung im offenen Jahr vor.
4. Barzahlungen von Vertretern sind Meldungen. Ob sie gelten, entscheidet die Vereinsverwaltung.
5. Bist du unsicher (welches Mitglied, welches Konto, welcher Betrag), frag nach. Rate nie.
6. Herkunft, Religion, Gesundheit und Familienverhältnisse erwähnst du nur, wenn danach gefragt wird.
7. Keine Rechts- oder Steuerberatung; allgemein erklären und an Fachleute verweisen.
8. Ein nicht gebuchtes Modul erwähnst du höchstens einmal als Hinweis.

Kürzel: @ Mitglied/Familie/Anlass/Rechnung, // Datum, # Nachbarschaft/Kategorie/Konto, ! Priorität, > Textbaustein.
Was die Person mit einem Kürzel schreibt, ist bereits aufgelöst und steht am Ende ihrer Nachricht unter "[Aufgelöste Kürzel". Das sind Tatsachen aus der Datenbank: übernimm sie wörtlich, erfinde nichts dazu und ändere keine Namen, Beträge oder Texte. Steht dort "mehrdeutig" oder "nichts gefunden", frag nach — rate nicht.
Steht dort der Text eines Textbausteins, ist das der Text des Vereins. Schreibe keinen eigenen.

Verfügbare Werkzeuge für diese Rolle: ${k.werkzeuge.join(", ") || "keine"}.`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ fehler: "Nur POST." }, 405);

  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return json({ fehler: "Nicht angemeldet." }, 401);

  // Der Client des Fragenden. Ausdruecklich NICHT der Dienstschluessel:
  // sonst saehe Floky alles, und die Rollen stuenden nur im Prompt.
  const sb = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth, Origin: req.headers.get("Origin") ?? "" } } },
  );

  let koerper: any;
  try { koerper = await req.json(); } catch { return json({ fehler: "Kein gueltiger Auftrag." }, 400); }
  const verlauf = Array.isArray(koerper?.verlauf) ? koerper.verlauf : [];
  // Die Oberflaeche kennt die eingestellte Sprache. Floky hat sie bisher
  // aus der Nachricht geraten und lag falsch -- der Vereinsname und das
  // Glossar sind albanisch, daran erkennt man die Sprache nicht.
  const sprache = ["de", "sq", "en"].includes(String(koerper?.sprache))
    ? String(koerper.sprache) : "de";
  // Selbsttest und Befehlsliste brauchen keinen Gespraechsverlauf.
  if (!verlauf.length && koerper?.pruefen !== true && koerper?.befehle !== true) {
    return json({ fehler: "Keine Nachricht." }, 400);
  }

  // --------------------------------------------------- Wer, ob, wie oft
  const schluessel = Deno.env.get("INFOMANIAK_AI_API_KEY");

  const { data: wer, error: werFehler } = await sb.rpc("wer_bin_ich");
  if (werFehler) return json({ fehler: werFehler.message }, 403);
  const ich = Array.isArray(wer) ? wer[0] : wer;
  // ------------------------------------------------------- Selbsttest
  //
  // Der Betreiber soll die Einrichtung pruefen koennen, ohne jemandem den
  // Token zu zeigen. Antwortet: welche Produktnummer gefunden wurde, welche
  // Modelle das Konto hat, und ob das eingestellte darunter ist.
  //
  // Er steht VOR der Vereins- und Modulpruefung: geprueft wird die
  // Einrichtung der PLATTFORM, nicht die eines Vereins. Stuende er
  // dahinter, kaeme der Betreiber auf unityhub.li nie an ihn heran -- er
  // gehoert dort zu keinem Verein. Genau dafuer ist er aber da.
  if (koerper?.pruefen === true) {
    if (!ich?.ist_betreiber) return json({ fehler: "Nur der Plattformbetreiber." }, 403);
    if (!schluessel) return json({ ok: false,
      fehler: "Das Geheimnis INFOMANIAK_AI_API_KEY ist nicht gesetzt." }, 503);
    try {
      const pid = await produktErmitteln(schluessel);
      const r = await fetch(`https://api.infomaniak.com/2/ai/${pid}/openai/v1/models`,
        { headers: { Authorization: `Bearer ${schluessel}` } });
      const leib = await r.text();
      if (!r.ok) return json({ ok: false, produkt: pid,
        fehler: `Modellabruf meldet ${r.status}: ${leib.slice(0, 300)}` }, 502);
      let modelle: string[] = [];
      try { modelle = (JSON.parse(leib)?.data ?? []).map((m: any) => m.id).filter(Boolean); }
      catch { /* dann eben ohne Liste */ }
      return json({ ok: true, produkt: pid, modell: MODELL,
                    modell_vorhanden: modelle.length ? modelle.includes(MODELL) : null,
                    modelle });
    } catch (e) {
      return json({ ok: false, fehler: e instanceof Error ? e.message : String(e) }, 502);
    }
  }


  // wer_bin_ich faellt ohne Anmeldung auf rolle MEMBER zurueck, laesst aber
  // verein leer. Ohne Verein ist niemand da, der fragen koennte -- und die
  // Abweisung soll sagen, was zutrifft, statt "nicht gebucht".
  if (!ich || !ich.verein) return json({ fehler: "Nicht angemeldet." }, 401);

  const rolleRoh = String(ich.rolle ?? "MEMBER");

  // Welche Befehle es gibt, darf jeder Angemeldete erfahren -- das kostet
  // nichts und verraet nichts. Ohne diese Auskunft bliebe jedes Kuerzel
  // unsichtbar, und ein Kuerzel, das niemand kennt, ist keines.
  if (koerper?.befehle === true) {
    return json({ befehle: befehlsliste(rolleRoh) });
  }

  const { data: einstVorab } = await sb.from("floky_einstellungen")
    .select("assistent_name,anrede_du").maybeSingle();

  const { data: darf } = await sb.rpc("floky_darf");
  if (!darf) {
    return json({ fehler: "Floky ist fuer diesen Verein nicht gebucht." , gebucht: false }, 403);
  }

  // ----------------------------------------------- Befehle ohne KI
  //
  // Sie stehen vor dem Zaehler UND vor der Schluesselpruefung. Das
  // Konzept sagt "lokal beantwortet, ohne KI-Aufruf" -- dann duerfen sie
  // weder etwas vom Kontingent nehmen noch daran scheitern, dass der
  // Betreiber das Geheimnis noch nicht hinterlegt hat.
  //
  // Genau daran lagen sie vorher: ohne Schluessel meldete /hilfe einen
  // 503 fuer einen Antwortdienst, den es gar nicht fragt.
  const letzte = String(verlauf[verlauf.length - 1]?.text ?? "");
  const { befehl, rest } = befehlLesen(letzte);
  const assistentName = einstVorab?.assistent_name ?? "Floky";

  if (befehl === "hilfe" || befehl === "help" || befehl === "ndihme") {
    return json({ text: hilfetext(rolleRoh, assistentName, sprache),
                  ohne_ki: true, name: assistentName });
  }

  if (befehl === "wochenstart" || befehl === "java" || befehl === "weekstart") {
    const text = await wochenstart(sb, rolleRoh, sprache);
    return json({ text, ohne_ki: true, name: assistentName });
  }

  // Erst jetzt: ob die Plattform eingerichtet ist, erfaehrt nur, wer
  // angemeldet ist, dessen Verein das Modul gebucht hat und etwas will,
  // wofuer tatsaechlich ein Antwortdienst gebraucht wird.
  if (!schluessel) {
    return json({ fehler: "Floky ist noch nicht eingerichtet: der Plattformbetreiber "
      + "muss das Geheimnis INFOMANIAK_AI_API_KEY hinterlegen." }, 503);
  }

  const { data: kont } = await sb.rpc("floky_kontingent");
  const kontingent = Array.isArray(kont) ? kont[0] : kont;

  // Zaehlen, bevor gefragt wird. Scheitert das, gibt es keine Antwort.
  const { data: uebrig, error: zaehlFehler } = await sb.rpc("floky_anfrage_zaehlen");
  if (zaehlFehler) return json({ fehler: zaehlFehler.message, kontingent }, 429);

  // ------------------------------------------------------------ Kontext
  const { data: meineId } = await sb.rpc("current_user_row_id");
  const [{ data: ichZeile }, { data: begriffe }, { data: einst }, { data: module },
         { data: meineLagje }] = await Promise.all([
      meineId
        ? sb.from("users").select("displayName,email,neighborhoodId").eq("id", meineId).maybeSingle()
        : Promise.resolve({ data: null }),
      sb.from("glossar").select("begriff,de,sq,en").limit(50),
      Promise.resolve({ data: einstVorab }),
      sb.from("tenant_modules").select("modul,zustand"),
      sb.rpc("my_neighborhoods"),
    ]);

  // Betreute Nachbarschaften -- bei einem Vertreter steht sie im Systemtext,
  // damit er nicht nach etwas fragt, das er ohnehin nicht bekommt.
  const lagjeIds = (meineLagje ?? []).map((n: any) => n.id ?? n).filter(Boolean);
  const { data: lagjeNamen } = lagjeIds.length
    ? await sb.from("neighborhoods").select("name").in("id", lagjeIds)
    : { data: [] };

  const rolle = String(ich.rolle ?? "MEMBER");
  // Lesende Werkzeuge und Kartenwerkzeuge zusammen -- beide nach Rolle
  // gefiltert. Die Karten schreiben nichts; was sie ausloesen, loest erst
  // ein Klick aus.
  const erlaubt = [...WERKZEUGE, ...KARTEN].filter((w) => w.rollen.includes(rolle));

  const system = systemtext({
    name: einst?.assistent_name ?? "Floky",
    verein: String(ich.vereinsname ?? ich.verein ?? ""),
    person: String(ichZeile?.displayName ?? ichZeile?.email ?? ""),
    rolle,
    nachbarschaft: (lagjeNamen ?? []).map((n: any) => n.name).join(", ") || null,
    module: (module ?? []).filter((m: any) => m.zustand === "AN" || m.zustand === "TESTPHASE")
                          .map((m: any) => m.modul),
    glossar: (begriffe ?? []).map((g: any) =>
      `${g.begriff}=${g.de ?? g.sq ?? g.en ?? g.begriff}`).join("; "),
    du: !!einst?.anrede_du,
    werkzeuge: erlaubt.map((w) => w.name),
    sprache,
  });

  // ----------------------------------------------------- Das Gespraech
  // Einen Befehl ausschreiben. "/mahnung Arben" allein versteht kein
  // Modell als Auftrag; mit dem Zweck davor schon. Der Befehl wird dabei
  // NICHT entfernt -- im Verlauf soll stehen, was die Person getippt hat.
  const ausgeschrieben = (text: string) => {
    const { befehl, rest } = befehlLesen(text);
    const b = befehl ? BEFEHLE[befehl] : null;
    if (!b) return text;
    if (!b.rollen.includes(rolleRoh)) {
      return `${text}\n\n[Hinweis: Der Befehl /${befehl} steht der Rolle ${rolleRoh} `
           + `nicht zur Verfuegung. Sage das und biete an, was stattdessen geht.]`;
    }
    return `[Auftrag: ${b.zweck}]\n${rest || text}`;
  };

  // Kuerzel der letzten Nachricht aufloesen. Nur der letzten: was frueher
  // aufgeloest wurde, steht schon im Verlauf, und eine zweite Aufloesung
  // koennte inzwischen etwas anderes ergeben.
  const aufgeloest = await kuerzelAufloesen(sb, letzte, sprache);

  const nachrichten: any[] = [
    { role: "system", content: system },
    ...verlauf.map((n: any, i: number) => {
      const roh = String(n.text ?? "");
      if (n.rolle === "floky" || i !== verlauf.length - 1) {
        return { role: n.rolle === "floky" ? "assistant" : "user", content: roh };
      }
      // Die letzte Nachricht bekommt Befehl und Kuerzel ausgeschrieben.
      return { role: "user",
               content: ausgeschrieben(roh) + (aufgeloest ? `\n\n${aufgeloest.text}` : "") };
    }).filter((n: any) => n.content),
  ];

  const werkzeugliste = erlaubt.map((w) => ({
    type: "function",
    function: { name: w.name, description: w.beschreibung, parameters: w.schema },
  }));

  const fragen = async (msgs: any[]) => {
    const pid = await produktErmitteln(schluessel);
    const r = await fetch(
      `https://api.infomaniak.com/2/ai/${pid}/openai/v1/chat/completions`, {
      method: "POST",
      headers: { "content-type": "application/json", Authorization: `Bearer ${schluessel}` },
      body: JSON.stringify({
        model: MODELL, max_tokens: 2000, messages: msgs,
        ...(werkzeugliste.length ? { tools: werkzeugliste, tool_choice: "auto" } : {}),
      }),
    });
    if (!r.ok) {
      const leib = await r.text();
      // Den Text mitgeben: "502" allein sagt dem Betreiber nicht, ob der
      // Token falsch ist, das Modell unbekannt oder das Kontingent leer.
      throw new Error(`Infomaniak meldet ${r.status}: ${leib.slice(0, 300)}`);
    }
    return await r.json();
  };

  try {
    let msgs = nachrichten;
    let antwort = await fragen(msgs);
    const benutzt: string[] = [];
    const karten: Karte[] = [];

    // Hoechstens drei Werkzeugrunden. Ohne Deckel koennte eine Antwort
    // beliebig lange laufen -- und das Kontingent zaehlt nur die Frage.
    for (let runde = 0; runde < 3; runde++) {
      const m = antwort?.choices?.[0]?.message;
      const rufe = m?.tool_calls ?? [];
      if (!rufe.length) break;

      msgs = [...msgs, m];
      for (const ruf of rufe) {
        const name = ruf?.function?.name;
        const w = erlaubt.find((x) => x.name === name);
        let inhalt: string;
        if (!w) {
          // Nennt das Modell ein Werkzeug, das dieser Rolle nicht zusteht,
          // wird es nicht ausgefuehrt -- auch nicht "nur lesend".
          inhalt = "Dieses Werkzeug steht dieser Rolle nicht zur Verfuegung.";
        } else {
          benutzt.push(w.name);
          let eingabe: any = {};
          try { eingabe = JSON.parse(ruf.function.arguments || "{}"); } catch { eingabe = {}; }
          const karte = KARTEN.some((k) => k.name === w.name) ? KARTE_BAUEN(w.name, eingabe) : null;
          if (KARTEN.some((k) => k.name === w.name)) {
            // Ausdruecklich in Worten, nicht nur durch Weglassen: sonst
            // schreibt das Modell hinterher "ist gebucht".
            if (karte) { karten.push(karte);
              inhalt = "Karte vorbereitet und dem Menschen vorgelegt. Es ist NICHTS gebucht, "
                     + "verschickt oder veroeffentlicht. Sage, was zu bestaetigen ist.";
            } else {
              inhalt = "Karte unvollstaendig -- es fehlen Pflichtangaben. Frag nach, statt zu raten.";
            }
          } else {
            try { inhalt = JSON.stringify(await w.lauf(sb, eingabe)); }
            catch (e) { inhalt = `Fehlgeschlagen: ${e instanceof Error ? e.message : String(e)}`; }
          }
        }
        msgs = [...msgs, { role: "tool", tool_call_id: ruf.id, content: inhalt }];
      }
      antwort = await fragen(msgs);
    }

    const text = String(antwort?.choices?.[0]?.message?.content ?? "").trim();

    for (const k of karten) {
      await sb.rpc("floky_protokollieren", {
        p_art: "KARTE", p_werkzeug: k.art,
        p_zusammenfassung: k.felder.map(([a, b]) => `${a}: ${b}`).join(", "),
      });
    }
    await sb.rpc("floky_protokollieren", {
      p_art: "ANFRAGE", p_werkzeug: benutzt.join(",") || null,
      p_zusammenfassung: String(verlauf[verlauf.length - 1]?.text ?? "").slice(0, 200),
    });

    return json({ text, werkzeuge: benutzt, karten, kuerzel: aufgeloest?.liste ?? [], uebrig,
                  kontingent: kontingent?.kontingent, name: einst?.assistent_name ?? "Floky" });
  } catch (e) {
    return json({ fehler: e instanceof Error ? e.message : String(e) }, 502);
  }
});
