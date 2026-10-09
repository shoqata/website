// Schneidet den Kuerzel-Aufloeser aus index.ts heraus, damit der Test ihn
// einzeln aufrufen kann.
//
// Warum nicht einfach eine eigene Datei fuer den Aufloeser? Weil eine Edge
// Function als EIN Buendel ausgeliefert wird und ein zweiter Import den
// Aufbau verkompliziert haette. Herausschneiden heisst dafuer: der Test
// prueft immer die Fassung, die wirklich laeuft.
//
// Aufruf:  deno run --allow-read --allow-write supabase/functions/floky/tests/vorbereiten.ts

const quelle = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
const a = quelle.indexOf("// ------------------------------------------------------- Inline-Kuerzel");
const b = quelle.indexOf("// ------------------------------------------------------------ Wochenstart");
if (a < 0 || b < 0 || b <= a) {
  throw new Error("Der Abschnitt Inline-Kuerzel ist in index.ts nicht mehr auffindbar -- "
    + "wurden die Trennkommentare geaendert?");
}
await Deno.writeTextFile(new URL("./ausschnitt.ts", import.meta.url),
  quelle.slice(a, b) + "\nexport { kuerzelAufloesen, datumLesen, kandidaten, bausteinSchluessel };\n");
console.log("ausschnitt.ts erzeugt");
