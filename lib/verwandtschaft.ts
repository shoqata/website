// Verwandtschaftsgrade aus dem Stammbaum ableiten.
//
// Gespeichert werden nur zwei Arten: ELTERNTEIL und PARTNER. Alles andere
// ergibt sich daraus -- Geschwister, Grosseltern, Onkel, Cousins. Sie zu
// speichern waere eine zweite Wahrheit, die mit der ersten auseinanderlaeuft:
// wer einen Elternteil korrigiert, muesste sonst auch alle abgeleiteten
// Angaben nachziehen.
//
// Gerechnet wird ueber den naechsten gemeinsamen Vorfahren. Das ist die
// uebliche Regel und deckt auch die Faelle ab, die man selten von Hand
// benennt: Cousin zweiten Grades, Grosscousine, Urgrossonkel.

export type Kante = { von: string; nach: string; art: 'ELTERNTEIL' | 'PARTNER' };

export type Grad = {
  id: string;
  bezeichnung: string;   // 'Cousin 1. Grades', 'Grossmutter', ...
  gruppe: 'kern' | 'abstammung' | 'seitenlinie' | 'angeheiratet';
  entfernung: number;    // fuer die Sortierung: klein = nah
};

type Netz = {
  eltern: Map<string, Set<string>>;
  kinder: Map<string, Set<string>>;
  partner: Map<string, Set<string>>;
};

export function netzAus(kanten: Kante[]): Netz {
  const eltern = new Map<string, Set<string>>();
  const kinder = new Map<string, Set<string>>();
  const partner = new Map<string, Set<string>>();
  const dazu = (m: Map<string, Set<string>>, a: string, b: string) => {
    if (!m.has(a)) m.set(a, new Set());
    m.get(a)!.add(b);
  };
  for (const k of kanten) {
    if (k.art === 'ELTERNTEIL') { dazu(kinder, k.von, k.nach); dazu(eltern, k.nach, k.von); }
    else { dazu(partner, k.von, k.nach); dazu(partner, k.nach, k.von); }
  }
  return { eltern, kinder, partner };
}

// Alle Vorfahren mit ihrem Abstand. Abstand 0 ist die Person selbst.
function vorfahren(netz: Netz, person: string, grenze = 8): Map<string, number> {
  const gefunden = new Map<string, number>([[person, 0]]);
  let welle = [person];
  for (let d = 1; d <= grenze && welle.length; d++) {
    const naechste: string[] = [];
    for (const p of welle) {
      for (const e of netz.eltern.get(p) ?? []) {
        if (gefunden.has(e)) continue;   // Kreise sind ausgeschlossen, aber
        gefunden.set(e, d);              // ein Elternteil kann ueber zwei Wege
        naechste.push(e);                // erreichbar sein -- der kuerzere gilt
      }
    }
    welle = naechste;
  }
  return gefunden;
}

const ORDNUNGSZAHL = ['', 'ersten', 'zweiten', 'dritten', 'vierten', 'fünften'];

function generationswort(d: number, weiblich: boolean | null): string {
  // d = 1 Eltern, 2 Grosseltern, 3 Urgrosseltern …
  if (d === 1) return weiblich === true ? 'Mutter' : weiblich === false ? 'Vater' : 'Elternteil';
  const stamm = weiblich === true ? 'mutter' : weiblich === false ? 'vater' : 'elternteil';
  return 'Ur'.repeat(Math.max(0, d - 2)) + 'Gross' + stamm;
}

function abkommenswort(d: number): string {
  if (d === 1) return 'Kind';
  return 'Ur'.repeat(Math.max(0, d - 2)) + 'Enkelkind';
}

// Der Grad zwischen zwei Personen, oder null wenn keine Blutsverwandtschaft
// besteht.
export function gradZwischen(netz: Netz, a: string, b: string): Grad | null {
  if (a === b) return null;

  const va = vorfahren(netz, a);
  const vb = vorfahren(netz, b);

  // Naechster gemeinsamer Vorfahre: der mit der kleinsten Summe der Abstaende.
  let besterA = Infinity, besterB = Infinity, summe = Infinity;
  for (const [ahn, da] of va) {
    const db = vb.get(ahn);
    if (db === undefined) continue;
    if (da + db < summe) { summe = da + db; besterA = da; besterB = db; }
  }
  if (summe === Infinity) return null;

  // Gerade Linie: einer ist Vorfahre des anderen.
  if (besterA === 0) return {
    id: b, bezeichnung: abkommenswort(besterB), gruppe: 'abstammung', entfernung: besterB,
  };
  if (besterB === 0) return {
    id: b, bezeichnung: generationswort(besterA, null), gruppe: 'abstammung', entfernung: besterA,
  };

  // Geschwister.
  if (besterA === 1 && besterB === 1) {
    const gemeinsam = [...va.keys()].filter(x => va.get(x) === 1 && vb.get(x) === 1).length;
    return {
      id: b,
      bezeichnung: gemeinsam >= 2 ? 'Geschwister' : 'Halbgeschwister',
      gruppe: 'kern', entfernung: 1,
    };
  }

  // Onkel/Tante und Neffe/Nichte.
  if (besterA === 1) return {
    id: b, bezeichnung: besterB === 2 ? 'Neffe/Nichte' : `Gross-Neffe/Nichte (${besterB - 1}×)`,
    gruppe: 'seitenlinie', entfernung: besterB,
  };
  if (besterB === 1) return {
    id: b, bezeichnung: besterA === 2 ? 'Onkel/Tante' : `Gross-Onkel/Tante (${besterA - 1}×)`,
    gruppe: 'seitenlinie', entfernung: besterA,
  };

  // Cousins. Der Grad richtet sich nach dem naeheren Zweig, "entfernt" nach
  // dem Unterschied der beiden Abstaende.
  const grad = Math.min(besterA, besterB) - 1;
  const entfernt = Math.abs(besterA - besterB);
  const wort = `Cousin/Cousine ${ORDNUNGSZAHL[grad] ?? grad + '.'} Grades`;
  return {
    id: b,
    bezeichnung: entfernt ? `${wort}, ${entfernt}× entfernt` : wort,
    gruppe: 'seitenlinie', entfernung: besterA + besterB,
  };
}

// Alle Verwandten einer Person, benannt und sortiert -- nah zuerst.
export function verwandteVon(
  netz: Netz, person: string, alle: string[], namen: Map<string, string>
): Grad[] {
  const raus: Grad[] = [];

  for (const q of netz.partner.get(person) ?? []) {
    raus.push({ id: q, bezeichnung: 'Partner/in', gruppe: 'kern', entfernung: 0 });
  }

  for (const anderer of alle) {
    if (anderer === person) continue;
    if ((netz.partner.get(person) ?? new Set()).has(anderer)) continue;
    const g = gradZwischen(netz, person, anderer);
    if (g) { raus.push(g); continue; }

    // Angeheiratet: keine Blutsverwandtschaft, aber Partner einer
    // Blutsverwandten. Wird genannt, weil sonst der Schwager fehlt.
    for (const p of netz.partner.get(anderer) ?? []) {
      const ueber = gradZwischen(netz, person, p);
      if (ueber) {
        raus.push({
          id: anderer, bezeichnung: `angeheiratet (Partner/in von ${namen.get(p) ?? '…'})`,
          gruppe: 'angeheiratet', entfernung: ueber.entfernung + 10,
        });
        break;
      }
    }
  }

  const rang = { kern: 0, abstammung: 1, seitenlinie: 2, angeheiratet: 3 };
  return raus.sort((x, y) =>
    rang[x.gruppe] - rang[y.gruppe] || x.entfernung - y.entfernung ||
    (namen.get(x.id) ?? '').localeCompare(namen.get(y.id) ?? ''));
}
