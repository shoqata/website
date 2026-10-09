// Prueft den Kuerzel-Aufloeser gegen eine nachgebaute Datenbank.
//
// Aufruf:  deno test --allow-read supabase/functions/floky/tests/
//
// ausschnitt.ts wird vor dem Lauf aus index.ts erzeugt (siehe
// vorbereiten.ts). Eine Kopie des Aufloesers waere ein Test, der bald
// etwas anderes prueft als das, was ausgeliefert ist.

import { kuerzelAufloesen, datumLesen, kandidaten, bausteinSchluessel } from "./ausschnitt.ts";

Deno.test("Inline-Kuerzel", async () => {
await pruefungen();
});

async function pruefungen() {

// Eine nachgebaute Datenbank: genau so viel, wie der Aufloeser anfasst.
const DATEN: Record<string, any[]> = {
  users: [
    { id: "u1", displayName: "Arben Krasniqi", email: "a@x.ch", membershipStatus: "ACTIVE" },
    { id: "u2", displayName: "Fatime Gashi", email: "f@x.ch", membershipStatus: "ACTIVE" },
    { id: "u3", displayName: "Shpend Gashi", email: "s@x.ch", membershipStatus: "INACTIVE" },
  ],
  families: [{ id: "f1", name: "Familie Gashi" }],
  events: [{ id: "e1", title: "Sommerfest", date: "2026-07-04" }],
  treffen: [{ id: "t1", titel: "Vereinstreffen 2026", datum: "2026-11-14" }],
  payments: [{ id: "p2", invoiceNumber: "2026-0180", amount: 60, status: "PENDING" }],
  neighborhoods: [{ id: "n1", name: "Lagjja e Poshtme" }],
  accounting_accounts: [{ code: "3000", name: "Mitgliederbeiträge" }],
  textbausteine: [
    { schluessel: "MAHNUNG_1", sprache: "de", betreff: "Erinnerung an den Beitrag {{jahr}}",
      text: "Guten Tag {{anrede}}\nFür {{jahr}} sind {{betrag}} offen." },
    { schluessel: "MAHNUNG_1", sprache: "sq", betreff: "Kujtesë", text: "Përshëndetje {{anrede}}" },
    { schluessel: "DANK_SPENDE", sprache: "de", betreff: "Danke", text: "Danke für {{betrag}}." },
  ],
};

const sb = {
  from(t: string) {
    let rows = [...(DATEN[t] ?? [])];
    const api: any = {
      select: () => api,
      limit: () => api,
      eq: (f: string, v: any) => { rows = rows.filter(r => String(r[f]) === String(v)); return api; },
      ilike: (f: string, v: string) => {
        const p = v.replace(/%/g, "").toLowerCase();
        rows = rows.filter(r => String(r[f] ?? "").toLowerCase().includes(p)); return api;
      },
      then: (ok: any) => ok({ data: rows }),
    };
    return api;
  },
};

let fehler = 0;
const pruefe = (name: string, ist: boolean, zusatz = "") => {
  console.log(`${ist ? "  ok  " : "FEHLER"}  ${name}${zusatz ? "  — " + zusatz : ""}`);
  if (!ist) fehler++;
};

console.log("--- Datum ---");
pruefe("14.11.2026", datumLesen("14.11.2026")?.iso === "2026-11-14");
pruefe("2026-11-14", datumLesen("2026-11-14")?.iso === "2026-11-14");
pruefe("morgen ist morgen", !!datumLesen("morgen"));
pruefe("nesër (albanisch)", !!datumLesen("nesër"));
pruefe("Ende Monat", !!datumLesen("Ende Monat"));
pruefe("in 14 Tagen", !!datumLesen("in 14 Tagen"));
pruefe("GV ist KEIN Datum", datumLesen("GV") === null, "darf nicht geraten werden");
pruefe("Unsinn ist kein Datum", datumLesen("irgendwann") === null);

console.log("\n--- Namensgrenze ---");
pruefe("vier Woerter, laengste zuerst",
  kandidaten("Arben Krasniqi hat bezahlt")[0] === "Arben Krasniqi hat bezahlt" &&
  kandidaten("Arben Krasniqi hat bezahlt").slice(-1)[0] === "Arben");
pruefe("Satzzeichen fallen weg", kandidaten("Arben.").includes("Arben"));

console.log("\n--- Bausteinschluessel ---");
pruefe('"Mahnung 1" -> MAHNUNG_1', bausteinSchluessel("Mahnung 1") === "MAHNUNG_1");
pruefe('"Dank Spende" -> DANK_SPENDE', bausteinSchluessel("Dank Spende") === "DANK_SPENDE");

console.log("\n--- Aufloesung ---");
const f = async (t: string) => (await kuerzelAufloesen(sb, t, "de"))?.text ?? "";
// Die knappe Liste fuer den Menschen -- sie darf den Bausteintext NICHT
// enthalten, sonst steht der ganze Brief im Gespraechsfenster.
const l = async (t: string) => (await kuerzelAufloesen(sb, t, "de"))?.liste ?? [];

let r = await f("@Arben Krasniqi hat bar bezahlt");
pruefe("@ findet genau ein Mitglied", r.includes("Arben Krasniqi") && r.includes("u1"));
pruefe("@ frisst nicht den Rest des Satzes", !r.includes("hat bar bezahlt"), r.split("\n")[1] ?? "");

r = await f("@Gashi soll zahlen");
pruefe("@ mehrdeutig -> Rueckfrage, keine Wahl",
  r.includes("mehrdeutig") && r.includes("Frag nach") && r.includes("Fatime") && r.includes("Shpend"));

r = await f("@Niemand Gibtsnicht");
pruefe("@ unbekannt -> Rate nicht", r.includes("nichts gefunden") && r.includes("Rate nicht"));

r = await f(">Mahnung 1 an ihn");
pruefe("> setzt den ECHTEN Text ein",
  r.includes("Für {{jahr}} sind {{betrag}} offen.") && r.includes("de, sq"));

r = await f(">Gibtsnicht");
pruefe("> unbekannt nennt die vorhandenen", r.includes("MAHNUNG_1") && r.includes("DANK_SPENDE"));

r = await f("#Lagjja e Poshtme");
pruefe("# findet die Nachbarschaft", r.includes("Nachbarschaft"));
r = await f("#3000");
pruefe("# findet das Konto", r.includes("Konto 3000"));
r = await f("#AKTIV");
pruefe("# kennt die Kategorie", r.includes("Mitgliederkategorie AKTIV"));

r = await f("!dringend bitte");
pruefe("! wird als Vorrang gelesen", r.includes("dringend") && r.includes("vorziehen"));

r = await f("@Sommerfest");
pruefe("@ findet auch Anlaesse", r.includes("Anlass"));
r = await f("@2026-0180");
pruefe("@ findet auch Rechnungen", r.includes("Rechnung 2026-0180"));

r = await f("@Arben Krasniqi //morgen >Mahnung 1 #3000 !dringend");
pruefe("alle fuenf in einem Satz",
  r.includes("Arben Krasniqi") && r.includes("morgen") &&
  r.includes("MAHNUNG_1") && r.includes("Konto 3000") && r.includes("dringend"));

const li = await l("@Arben Krasniqi >Mahnung 1 @Niemand");
pruefe("Liste nennt jedes Kuerzel", li.length === 3, li.map(x => x.kuerzel).join(" "));
pruefe("Liste kennzeichnet Ungeloestes",
  li.filter(x => x.offen).length === 1 && li.find(x => x.kuerzel.includes("Niemand"))?.offen === true);
pruefe("Liste enthaelt NICHT den Bausteintext",
  !JSON.stringify(li).includes("{{betrag}}"), "sonst steht der Brief im Fenster");

// Eine fehlgeschlagene Abfrage darf NICHT wie "nichts gefunden" aussehen.
// Genau dieser stille Ausfall war der Grund, Fehler durchzureichen.
const kaputt = {
  from() {
    const api: any = { select: () => api, limit: () => api, eq: () => api, ilike: () => api,
      then: (ok: any) => ok({ data: null, error: { message: "permission denied" } }) };
    return api;
  },
};
const panne = (await kuerzelAufloesen(kaputt, "@Arben Krasniqi", "de"))?.text ?? "";
pruefe("Abfragefehler wird genannt",
  panne.includes("Abfrage fehlgeschlagen") && panne.includes("permission denied"),
  panne.split("\n").slice(-2)[0] ?? "");

pruefe("ohne Kuerzel: keine Beilage", (await kuerzelAufloesen(sb, "Guten Tag", "de")) === null);
pruefe("E-Mail ist kein Kuerzel",
  (await kuerzelAufloesen(sb, "schreib an a@x.ch", "de")) === null, "kein @ mitten im Wort");

console.log(fehler === 0 ? "\nALLE BESTANDEN" : `\n${fehler} FEHLGESCHLAGEN`);
if (fehler) throw new Error(`${fehler} Pruefung(en) fehlgeschlagen`);

}
