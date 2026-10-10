import { assert, assertEquals, assertStringIncludes }
  from "https://deno.land/std@0.224.0/assert/mod.ts";
import { briefBauen, kopfwert, umbrechen } from "../brevo_smtp.ts";

// Diese Tests pruefen den Briefaufbau, nicht den Versand. Genau das ist
// der Punkt: der Aufbau laesst sich vollstaendig pruefen, ohne eine
// einzige Nachricht zu verschicken -- und er ist die Stelle, an der ein
// Fehler einen Brief ergibt, der zugestellt AUSSIEHT und beim Empfaenger
// unlesbar ankommt.

const brief = (x: Partial<Parameters<typeof briefBauen>[0]> = {}) => ({
  von: "office@unityhub.li", vonName: "unityhub", an: "a@b.ch",
  betreff: "Test", html: "<p>Hallo</p>", ...x,
}) as Parameters<typeof briefBauen>[0];

Deno.test("Umlaute im Betreff werden kodiert", () => {
  const k = kopfwert("Beitragsrechnung für 2026 · Fatura");
  assertStringIncludes(k, "=?UTF-8?B?");
  assert(!k.includes("für"), "Rohtext darf nicht im Kopf stehen");
});

Deno.test("reiner ASCII-Betreff bleibt lesbar", () => {
  assertEquals(kopfwert("Invoice 2026"), "Invoice 2026");
});

Deno.test("kein kodiertes Wort wird zu lang", () => {
  const lang = "ä".repeat(400);
  for (const z of kopfwert(lang).split("\r\n")) {
    assert(z.trim().length <= 76, `Zeile zu lang: ${z.trim().length}`);
  }
});

Deno.test("Zeilenumbruch im Betreff kann keinen Kopf einschmuggeln", () => {
  // Ohne diese Saeuberung koennte ein Betreff aus der Datenbank
  // "Test\r\nBcc: fremd@x.ch" einen zusaetzlichen Empfaenger anlegen.
  const k = kopfwert("Test\r\nBcc: fremd@x.ch");
  assert(!k.includes("\r"), "CR ueberlebt");
  assert(!k.includes("\n"), "LF ueberlebt");
});

Deno.test("keine Zeile beginnt mit einem einzelnen Punkt", () => {
  // Eine Zeile aus genau einem Punkt beendet die Nachricht; eine Zeile,
  // die mit einem beginnt, verliert ihn beim Empfaenger.
  //
  // Dieser Test schlug zuerst in der anderen Richtung fehl, und das war
  // aufschlussreich: er suchte das GESTOPFTE Doppelzeichen und fand
  // keines. Der Grund ist, dass alle Teile base64 kodiert sind und das
  // base64-Alphabet keinen Punkt enthaelt -- die Gefahr besteht also
  // gar nicht. Das Stopfen in briefBauen bleibt als Schutz, falls spaeter
  // auf quoted-printable oder 8bit gewechselt wird; geprueft wird hier
  // die Eigenschaft, auf die es ankommt, nicht der Mechanismus.
  const t = briefBauen(brief({
    text: ".Mit Punkt\n.\nnormal", html: "<p>.Punkt</p>",
  }), "G");
  const schlimm = t.split("\r\n").filter(z => /^\.(?!\.)/.test(z));
  assertEquals(schlimm, [], "Zeile mit einzelnem Punkt am Anfang");
});

Deno.test("nur CRLF, nie ein einzelnes LF", () => {
  const t = briefBauen(brief({ text: "a\nb", html: "<p>a</p>" }), "G");
  assertEquals(t.split("\n").length - 1, t.split("\r\n").length - 1);
});

Deno.test("keine Zeile ueber der Norm von 998", () => {
  const t = briefBauen(brief({
    html: "<p>" + "x".repeat(20000) + "</p>",
    anhaenge: [{ filename: "r.pdf", content: btoa("P".repeat(40000)) }],
  }), "G");
  const zu = t.split("\r\n").filter(z => z.length > 998);
  assertEquals(zu.length, 0, `${zu.length} Zeilen zu lang`);
});

Deno.test("Anhang ergibt multipart/mixed und wird nicht doppelt kodiert", () => {
  const inhalt = btoa("PDFINHALT");
  const t = briefBauen(brief({ anhaenge: [{ filename: "rechnung.pdf", content: inhalt }] }), "G");
  assertStringIncludes(t, 'multipart/mixed; boundary="G"');
  assertStringIncludes(t, 'filename="rechnung.pdf"');
  assertStringIncludes(t, inhalt);   // unverandert, nicht erneut base64
  assertStringIncludes(t, "\r\n--G--");
});

Deno.test("Text und HTML ergeben Alternativen", () => {
  const t = briefBauen(brief({ text: "Hallo" }), "G");
  assertStringIncludes(t, "multipart/alternative");
  assertStringIncludes(t, "text/plain; charset=UTF-8");
  assertStringIncludes(t, "text/html; charset=UTF-8");
});

Deno.test("ohne Text nur HTML, ohne leeren Alternativteil", () => {
  const t = briefBauen(brief(), "G");
  assert(!t.includes("multipart/alternative"), "leere Alternative gebaut");
  assertStringIncludes(t, "text/html");
});

Deno.test("Reply-To nur wenn gesetzt", () => {
  assert(!briefBauen(brief(), "G").includes("Reply-To"));
  assertStringIncludes(briefBauen(brief({ antwortAn: "x@y.ch" }), "G"), "Reply-To: x@y.ch");
});

Deno.test("umbrechen haelt 76 Zeichen ein", () => {
  for (const z of umbrechen("A".repeat(1000)).split("\r\n")) {
    assert(z.length <= 76, `${z.length} Zeichen`);
  }
});

Deno.test("der Umlaut kommt am Ende wieder heil heraus", () => {
  // Die Kette Text -> UTF-8 -> base64 -> Brief laesst sich ruecklaeufig
  // pruefen. Ohne diesen Test waere ein kaputter Umlaut erst im
  // Postfach des Mitglieds sichtbar.
  const t = briefBauen(brief({ html: "<p>Grüezi · Përshëndetje</p>" }), "G");
  const b64 = t.split("\r\n\r\n").slice(1).join("").replace(/\s+/g, "");
  const roh = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
  assertStringIncludes(new TextDecoder().decode(roh), "Grüezi · Përshëndetje");
});
