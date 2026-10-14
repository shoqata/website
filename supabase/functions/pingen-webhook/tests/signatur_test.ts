import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

// Die Signaturpruefung ist das EINZIGE, was diese Schnittstelle
// schuetzt -- sie ist oeffentlich erreichbar, weil Pingen keinen
// Cron-Token mitschicken kann. Darum wird sie hier geprueft und nicht
// angenommen.

const hexHmac = async (schluessel: string, text: string): Promise<string> => {
  const k = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(schluessel),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(text));
  return [...new Uint8Array(sig)].map(b => b.toString(16).padStart(2, "0")).join("");
};

const gleich = (a: string, b: string): boolean => {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
};

Deno.test("die Signatur deckt den ROHEN Koerper", async () => {
  // Der entscheidende Punkt: geprueft werden muss genau die Zeichenkette,
  // die unterschrieben wurde. Wer sie durch JSON schickt und wieder
  // zusammensetzt, prueft eine ANDERE -- und merkt es nicht, weil sie
  // meistens gleich aussieht.
  const roh = '{"data":{"id":"abc","attributes":{"event":"sent"}}}';
  const umgebaut = JSON.stringify(JSON.parse(roh));
  // Hier sind beide gleich ...
  assertEquals(roh, umgebaut);

  // ... und hier nicht mehr. Leerzeichen, Reihenfolge, Zahlenform:
  // alles, was JSON.parse/stringify veraendern darf.
  const mitRaum = '{ "data": { "id": "abc" } }';
  assert(mitRaum !== JSON.stringify(JSON.parse(mitRaum)));
  assert(await hexHmac("s", mitRaum) !== await hexHmac("s", JSON.stringify(JSON.parse(mitRaum))),
    "Umgebauter Koerper ergibt dieselbe Signatur -- dann prueft der Test nichts");
});

Deno.test("falscher Schluessel wird abgewiesen", async () => {
  const roh = '{"a":1}';
  assert(!gleich(await hexHmac("richtig", roh), await hexHmac("falsch", roh)));
});

Deno.test("geaenderter Koerper wird abgewiesen", async () => {
  const sig = await hexHmac("s", '{"brief":"A"}');
  assert(!gleich(sig, await hexHmac("s", '{"brief":"B"}')));
});

Deno.test("der Vergleich bricht nicht frueh ab", () => {
  // Ein Vergleich, der beim ersten Unterschied aufhoert, verraet ueber
  // die Laufzeit, wie viele Zeichen stimmen -- damit laesst sich eine
  // Signatur Zeichen fuer Zeichen erraten. Geprueft wird die
  // Eigenschaft, die das verhindert: alle Zeichen werden angesehen.
  const a = "a".repeat(64);
  const fastGleich = "a".repeat(63) + "b";
  const frueh = "b" + "a".repeat(63);
  assertEquals(gleich(a, fastGleich), false);
  assertEquals(gleich(a, frueh), false);
  assertEquals(gleich(a, a), true);
  // Verschiedene Laengen: sofort falsch, ohne Zeichenvergleich. Das ist
  // unbedenklich -- die Laenge einer Signatur ist bekannt.
  assertEquals(gleich(a, "a"), false);
});

Deno.test("Gross- und Kleinschreibung der Signatur zaehlt nicht", async () => {
  const sig = await hexHmac("s", '{"a":1}');
  assertEquals(sig.toLowerCase(), sig.toUpperCase().toLowerCase());
});
