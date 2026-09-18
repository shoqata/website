import React, { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';

// Zeichnet eine Familie als Baum.
//
// Ein Stammbaum ist keine Hierarchie im Sinne von d3.hierarchy: ein Kind hat
// zwei Eltern, Partner stehen nebeneinander, und Zyklen sind ausgeschlossen,
// aber Querverbindungen nicht. Deshalb wird nicht d3.tree verwendet, sondern
// nach Generationen geschichtet -- die Ebene ergibt sich aus dem laengsten
// Weg von einer Person ohne erfasste Eltern.
//
// Gezeichnet wird zweischichtig: die Linien als SVG, die Kaesten als HTML
// darueber. Grund ist das Ziehen -- das draggable-Attribut wirkt auf
// SVG-Elementen nicht in allen Browsern, auf einem div dagegen ueberall.
//
// Die Anordnung ist gerechnet, nicht simuliert: bei gleichen Daten kommt
// dasselbe Bild heraus. Eine Kraftsimulation sieht lebendiger aus, ordnet aber
// bei jedem Aufruf anders an -- bei einer Verwandtschaft waere das nicht
// Darstellung, sondern Verwirrung. Aus demselben Grund gerade Strecken statt
// Kurven: ein Stammbaum wird gelesen, nicht bewundert.

export type Knoten = {
  person: string; name: string; geburtsdatum: string | null;
  eltern: { id: string; name: string }[];
  partner: { id: string; name: string }[];
  kinder: { id: string; name: string }[];
  // Ausdrueckliche Geschwister. Gebraucht, wenn die Eltern nicht erfasst
  // sind -- sonst gaebe es niemanden, ueber den sich zwei verbinden liessen.
  geschwister: { id: string; name: string }[];
};

// Generation je Person.
//
// Zwei Regeln, abwechselnd angewandt, bis sich nichts mehr aendert:
//   1. Ein Kind steht eine Ebene unter seinem tiefsten Elternteil.
//   2. Partner stehen auf derselben Ebene, und zwar auf der tieferen.
//
// Das Angleichen der Partner kann Regel 1 verletzen -- wird ein Elternteil
// nach unten gezogen, muessen die Kinder nach. Deshalb die Schleife und nicht
// zwei Durchgaenge.
//
// Frueher stand hier das Minimum statt des Maximums. Ein Elternteil, dessen
// eigene Eltern erfasst waren, wurde dadurch von seinem Partner ohne erfasste
// Eltern nach oben gezogen -- und stand neben den eigenen Eltern.
//
// Steht hier und nicht in der aufrufenden Ansicht, weil beide dieselbe
// Antwort brauchen: der Baum fuer die Anordnung, die Kopfzeile fuer die
// Anzahl der Generationen.
export function generationen(leute: Knoten[]): Map<string, number> {
  const dabei = new Set(leute.map(l => l.person));
  const ebene = new Map<string, number>(leute.map(l => [l.person, 0]));

  for (let runde = 0; runde < 60; runde++) {
    let geaendert = false;

    for (const p of leute) {
      const eltern = p.eltern.filter(e => dabei.has(e.id));
      if (!eltern.length) continue;
      const soll = Math.max(...eltern.map(e => ebene.get(e.id) ?? 0)) + 1;
      if (soll > (ebene.get(p.person) ?? 0)) { ebene.set(p.person, soll); geaendert = true; }
    }

    for (const p of leute) {
      // Partner und Geschwister stehen beide auf derselben Ebene, und zwar
      // auf der tieferen -- wer erfasste Eltern hat, bestimmt sie.
      for (const q of [...p.partner, ...p.geschwister]) {
        if (!dabei.has(q.id)) continue;
        const tiefer = Math.max(ebene.get(p.person) ?? 0, ebene.get(q.id) ?? 0);
        if ((ebene.get(p.person) ?? 0) !== tiefer) { ebene.set(p.person, tiefer); geaendert = true; }
        if ((ebene.get(q.id) ?? 0) !== tiefer) { ebene.set(q.id, tiefer); geaendert = true; }
      }
    }

    if (!geaendert) break;
  }

  const kleinste = Math.min(...ebene.values());
  if (kleinste > 0) for (const [k, v] of ebene) ebene.set(k, v - kleinste);

  return ebene;
}

const BREITE = 168;
const HOEHE = 52;
const LUECKE = 28;      // zwischen zwei Kaesten derselben Generation
const PAARLUECKE = 22;  // zwischen zwei Partnern -- enger, sie gehoeren zusammen,
                        // aber weit genug, dass die Verbindung sichtbar bleibt
const ZEILE = 128;

// Eine Einheit ist das, was nebeneinander steht: ein Paar oder eine einzelne
// Person. Der Baum wird ueber Einheiten angeordnet, nicht ueber Personen --
// sonst laesst sich ein Paar auseinanderreissen und die Linien zu den
// gemeinsamen Kindern kreuzen sich.
type Einheit = { leute: Knoten[]; ebene: number; x: number; breite: number };

export type Zone = 'ELTERNTEIL' | 'PARTNER' | 'KIND' | 'GESCHWISTER';

const Familienbaum: React.FC<{
  leute: Knoten[];
  // Ohne diese Rueckrufe ist der Baum reine Anzeige -- so wird er in der
  // Uebersicht verwendet. Mit ihnen laesst sich ziehen und ablegen.
  onAblegen?: (ziel: string, zone: Zone, quelle: string) => void;
  onWaehlen?: (id: string | null) => void;
  gewaehltId?: string | null;
  t3?: (s: string) => string;
  // Breite Familien passend verkleinern statt seitlich scrollen zu lassen.
  // Auf der Betreiberseite ist das noetig -- dort steht der Baum in einem
  // festen Rahmen, und ein abgeschnittener Kasten sieht nach Fehler aus.
  einpassen?: boolean;
}> = ({ leute, onAblegen, onWaehlen, gewaehltId = null, t3 = (s) => s, einpassen = false }) => {
  const huelle = useRef<HTMLDivElement>(null);
  const [faktor, setFaktor] = useState(1);
  const [markiert, setMarkiert] = useState<string | null>(null);
  const [zieht, setZieht] = useState<string | null>(null);
  const [ziel, setZiel] = useState<{ id: string; zone: Zone } | null>(null);

  const plan = useMemo(() => {
    const dabei = new Set(leute.map(l => l.person));
    const nach = new Map(leute.map(l => [l.person, l]));
    const ebene = generationen(leute);

    // --- Einheiten bilden --------------------------------------------------
    const einheitVon = new Map<string, Einheit>();
    const einheiten: Einheit[] = [];
    for (const p of [...leute].sort((a, b) => a.name.localeCompare(b.name))) {
      if (einheitVon.has(p.person)) continue;
      const partner = p.partner
        .map(q => nach.get(q.id))
        .filter((q): q is Knoten => !!q && !einheitVon.has(q.person)
                                     && ebene.get(q.person) === ebene.get(p.person));
      // Nur ein Partner je Einheit. Wer mehrere hat, bekommt den ersten
      // danebengestellt; die uebrigen Verbindungen bleiben als Linie sichtbar.
      const mitglieder = partner.length ? [p, partner[0]] : [p];
      const e: Einheit = {
        leute: mitglieder, ebene: ebene.get(p.person) ?? 0, x: 0,
        breite: mitglieder.length * BREITE + (mitglieder.length - 1) * PAARLUECKE,
      };
      mitglieder.forEach(m => einheitVon.set(m.person, e));
      einheiten.push(e);
    }

    // --- Kinder je Einheit -------------------------------------------------
    // Ein Kind haengt an der Einheit seiner Eltern. Hat es Eltern in zwei
    // Einheiten, zaehlt die erste -- die zweite Verbindung bleibt als Linie
    // erhalten, nur die Anordnung folgt der ersten.
    const kinderVon = new Map<Einheit, Einheit[]>();
    const schonZugeordnet = new Set<Einheit>();
    for (const e of einheiten) {
      const kinder: Einheit[] = [];
      const gesehen = new Set<Einheit>();
      for (const m of e.leute) {
        for (const k of m.kinder) {
          const ke = einheitVon.get(k.id);
          if (!ke || gesehen.has(ke) || schonZugeordnet.has(ke) || ke === e) continue;
          gesehen.add(ke); schonZugeordnet.add(ke); kinder.push(ke);
        }
      }
      kinderVon.set(e, kinder);
    }

    // --- Anordnen ----------------------------------------------------------
    // Nachgeordnete Durchmusterung: erst die Kinder legen, dann die Eltern
    // ueber deren Mitte. So steht jede Familie zusammen und die Linien
    // kreuzen sich nicht -- vorher war alphabetisch sortiert, und Kinder
    // landeten quer ueber das Bild verteilt.
    let naechstesX = 0;
    const gelegt = new Set<Einheit>();

    const legen = (e: Einheit): void => {
      if (gelegt.has(e)) return;
      gelegt.add(e);
      const kinder = kinderVon.get(e) ?? [];
      if (!kinder.length) {
        e.x = naechstesX;
        naechstesX += e.breite + LUECKE;
        return;
      }
      kinder.forEach(legen);
      const links = Math.min(...kinder.map(k => k.x));
      const rechts = Math.max(...kinder.map(k => k.x + k.breite));
      e.x = (links + rechts) / 2 - e.breite / 2;
      // Stiesse die Einheit mit einer bereits gelegten zusammen, wird alles
      // nach rechts geschoben statt uebereinander gezeichnet.
      const stoss = einheiten.filter(a => a !== e && gelegt.has(a) && a.ebene === e.ebene
                                       && a.x < e.x + e.breite + LUECKE
                                       && a.x + a.breite + LUECKE > e.x);
      if (stoss.length) {
        const noetig = Math.max(...stoss.map(a => a.x + a.breite + LUECKE)) - e.x;
        e.x += noetig;
      }
      naechstesX = Math.max(naechstesX, e.x + e.breite + LUECKE);
    };

    const wurzeln = einheiten.filter(e => !schonZugeordnet.has(e));
    wurzeln.forEach(legen);
    einheiten.forEach(legen);  // Nachzuegler aus Kreisen oder losen Teilen

    // --- Stellen der einzelnen Personen -----------------------------------
    const pos = new Map<string, { x: number; y: number }>();
    for (const e of einheiten) {
      e.leute.forEach((m, i) => pos.set(m.person, {
        x: e.x + i * (BREITE + PAARLUECKE), y: e.ebene * ZEILE,
      }));
    }

    // Nach links buendig schieben.
    const minX = Math.min(...[...pos.values()].map(p => p.x));
    if (minX !== 0) for (const [k, v] of pos) pos.set(k, { x: v.x - minX, y: v.y });
    for (const e of einheiten) e.x -= minX;

    // --- Linien ------------------------------------------------------------
    // Von der Mitte eines Paares hinunter zu einem Geschwisterbalken, von dort
    // kurze Tropfen zu jedem Kind. Das ist die uebliche Form eines
    // Stammbaums und halbiert die Zahl der Linien gegenueber je einer Linie
    // von jedem Elternteil zu jedem Kind.
    const familienlinien: { d: string; leute: string[] }[] = [];
    for (const e of einheiten) {
      const kinder = (kinderVon.get(e) ?? [])
        .map(k => k.leute.filter(m => m.eltern.some(x => e.leute.some(p => p.person === x.id))))
        .flat();
      if (!kinder.length) continue;
      const mitte = e.x + e.breite / 2;
      const oben = e.ebene * ZEILE + HOEHE;
      const balken = (e.ebene + 1) * ZEILE - 34;
      const xs = kinder.map(k => pos.get(k.person)!.x + BREITE / 2).sort((a, b) => a - b);
      // Der Balken muss auch die Linie vom Paar erreichen -- sonst haengt sie
      // bei einem einzelnen Kind, das nicht genau unter der Mitte steht, frei
      // in der Luft. Genau das war zu sehen.
      const links = Math.min(xs[0], mitte);
      const rechts = Math.max(xs[xs.length - 1], mitte);
      const d = [
        `M ${mitte} ${oben} V ${balken}`,
        `M ${links} ${balken} H ${rechts}`,
        ...xs.map(x => `M ${x} ${balken} V ${(e.ebene + 1) * ZEILE}`),
      ].join(' ');
      familienlinien.push({ d, leute: [...e.leute.map(m => m.person), ...kinder.map(k => k.person)] });
    }

    // Partnerschaften, die nicht schon nebeneinander stehen, bekommen eine
    // eigene Linie -- sonst waere eine zweite Ehe unsichtbar.
    const partnerlinien: { x1: number; y1: number; x2: number; y2: number; a: string; b: string }[] = [];
    const gesehenP = new Set<string>();
    for (const p of leute) {
      for (const q of p.partner) {
        const schluessel = [p.person, q.id].sort().join('|');
        if (gesehenP.has(schluessel)) continue;
        gesehenP.add(schluessel);
        const a = pos.get(p.person), b = pos.get(q.id);
        if (!a || !b) continue;
        partnerlinien.push({
          x1: Math.min(a.x, b.x) + BREITE, y1: a.y + HOEHE / 2,
          x2: Math.max(a.x, b.x), y2: b.y + HOEHE / 2,
          a: p.person, b: q.id,
        });
      }
    }

    // Geschwister ohne gemeinsamen erfassten Elternteil bekommen eine eigene
    // Klammer -- sonst waere die Verbindung unsichtbar, weil kein
    // Geschwisterbalken von oben kommt.
    const geschwisterlinien: { d: string; a: string; b: string }[] = [];
    const gesehenG = new Set<string>();
    for (const p of leute) {
      for (const q of p.geschwister) {
        const schluessel = [p.person, q.id].sort().join('|');
        if (gesehenG.has(schluessel)) continue;
        gesehenG.add(schluessel);
        const a = pos.get(p.person), b = pos.get(q.id);
        if (!a || !b) continue;
        const links = Math.min(a.x, b.x) + BREITE / 2;
        const rechts = Math.max(a.x, b.x) + BREITE / 2;
        const y = a.y - 16;
        geschwisterlinien.push({
          d: `M ${links} ${a.y} V ${y} H ${rechts} V ${b.y}`,
          a: p.person, b: q.id,
        });
      }
    }

    const alleX = [...pos.values()].map(p => p.x);
    const alleY = [...pos.values()].map(p => p.y);
    return {
      pos, familienlinien, partnerlinien, geschwisterlinien,
      breite: Math.max(...alleX) + BREITE,
      hoehe: Math.max(...alleY) + HOEHE,
    };
  }, [leute]);

  // Was gehoert zur markierten Person? Eltern, Partner und Kinder bleiben
  // kraeftig, alles andere tritt zurueck.
  // Nur wo mit dem Baum gearbeitet wird. Auf der Betreiberseite steht er als
  // Bild -- dort liesse ein zufaellig darauf ruhender Zeiger die halbe
  // Familie verblassen, was nach einem Fehler aussieht statt nach einer
  // Hervorhebung.
  const interaktiv = !!(onAblegen || onWaehlen);

  const verbunden = (id: string) => {
    if (!interaktiv || !markiert) return true;
    if (id === markiert) return true;
    const m = leute.find(l => l.person === markiert);
    if (!m) return true;
    return [...m.eltern, ...m.partner, ...m.kinder].some(x => x.id === id);
  };

  const rand = 16;
  const vollBreite = plan.breite + rand * 2;
  const vollHoehe = plan.hoehe + rand * 2 + 16;

  // Der Faktor wird gemessen, nicht geschaetzt: die verfuegbare Breite steht
  // erst nach dem Anordnen fest, und sie aendert sich beim Drehen des Geraets.
  useLayoutEffect(() => {
    if (!einpassen) { setFaktor(1); return; }
    const messen = () => {
      const da = huelle.current?.clientWidth ?? 0;
      setFaktor(da > 0 && vollBreite > da ? da / vollBreite : 1);
    };
    messen();
    const beobachter = new ResizeObserver(messen);
    if (huelle.current) beobachter.observe(huelle.current);
    return () => beobachter.disconnect();
  }, [einpassen, vollBreite]);

  const zonen: { zone: Zone; text: string; oben: string }[] = [
    { zone: 'ELTERNTEIL',  text: t3('Elternteil'),  oben: '-16px' },
    { zone: 'GESCHWISTER', text: t3('Geschwister'), oben: `${HOEHE / 2 - 22}px` },
    { zone: 'PARTNER',     text: t3('Partner'),     oben: `${HOEHE / 2 + 1}px` },
    { zone: 'KIND',        text: t3('Kind'),        oben: `${HOEHE - 6}px` },
  ];

  return (
    <div ref={huelle} className={einpassen ? 'overflow-hidden' : 'overflow-auto'}>
      <div style={einpassen ? { height: vollHoehe * faktor } : undefined}>
      <div className="relative"
           style={{
             width: vollBreite, height: vollHoehe,
             transform: faktor < 1 ? `scale(${faktor})` : undefined,
             transformOrigin: 'top left',
           }}>

        {/* Linien. Liegen unter den Kaesten und nehmen keine Mausereignisse
            an, sonst liesse sich auf ihnen nichts ablegen. */}
        <svg width={plan.breite + rand * 2} height={plan.hoehe + rand * 2}
             className="absolute inset-0 pointer-events-none" role="img" aria-label="Stammbaum">
          <g transform={`translate(${rand},${rand})`}>
            {plan.familienlinien.map((l, i) => (
              <path key={`f${i}`} d={l.d} fill="none" stroke="#d6d3d1" strokeWidth={2}
                    strokeLinecap="round" opacity={l.leute.some(verbunden) ? 1 : 0.2} />
            ))}
            {plan.geschwisterlinien.map((l, i) => (
              <path key={`g${i}`} d={l.d} fill="none" stroke="#a8a29e" strokeWidth={1.5}
                    strokeDasharray="3 3" strokeLinecap="round"
                    opacity={verbunden(l.a) && verbunden(l.b) ? 0.7 : 0.12} />
            ))}
            {plan.partnerlinien.map((l, i) => (
              <line key={`p${i}`} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2}
                    stroke="var(--primary)" strokeWidth={2.5} strokeLinecap="round"
                    opacity={verbunden(l.a) && verbunden(l.b) ? 0.8 : 0.12} />
            ))}
          </g>
        </svg>

        {leute.map(p => {
          const s = plan.pos.get(p.person)!;
          const hell = verbunden(p.person);
          const gewaehlt = p.person === gewaehltId;
          return (
            <div key={p.person}
                 className="absolute rounded-[10px] border transition-opacity select-none"
                 style={{
                   left: s.x + rand, top: s.y + rand, width: BREITE, height: HOEHE,
                   opacity: hell ? 1 : 0.28,
                   background: gewaehlt ? 'var(--primary)' : '#ffffff',
                   borderColor: gewaehlt ? 'var(--primary)' : '#e7e5e4',
                   cursor: onAblegen ? 'grab' : 'default',
                 }}
                 draggable={!!onAblegen}
                 onDragStart={(e) => { e.dataTransfer.setData('text/plain', p.person); setZieht(p.person); }}
                 onDragEnd={() => { setZieht(null); setZiel(null); }}
                 onMouseEnter={() => interaktiv && setMarkiert(p.person)}
                 onMouseLeave={() => interaktiv && setMarkiert(null)}
                 onClick={() => onWaehlen?.(gewaehlt ? null : p.person)}>
              <p className="px-3 pt-2 text-[12px] font-bold truncate"
                 style={{ color: gewaehlt ? '#fff' : '#44403c' }}>{p.name}</p>
              <p className="px-3 text-[10px]"
                 style={{ color: gewaehlt ? 'rgba(255,255,255,.75)' : '#a8a29e' }}>
                {p.geburtsdatum || '—'}
              </p>

              {/* Ablegeflaechen. Sie erscheinen nur waehrend eines Zuges und
                  nur an fremden Kaesten -- auf sich selbst kann niemand
                  abgelegt werden. */}
              {onAblegen && zieht && zieht !== p.person && (
                <div className="absolute inset-0">
                  {zonen.map(z => (
                    <div key={z.zone}
                         className="absolute left-0 right-0 flex items-center justify-center
                                    text-[9px] font-bold uppercase tracking-widest rounded"
                         style={{
                           top: z.oben, height: 20,
                           background: ziel?.id === p.person && ziel.zone === z.zone
                             ? 'var(--primary)' : 'rgba(255,255,255,.94)',
                           color: ziel?.id === p.person && ziel.zone === z.zone ? '#fff' : '#a8a29e',
                           border: '1px dashed #d6d3d1',
                         }}
                         onDragOver={(e) => { e.preventDefault(); setZiel({ id: p.person, zone: z.zone }); }}
                         onDragLeave={() => setZiel(null)}
                         onDrop={(e) => {
                           e.preventDefault();
                           const quelle = e.dataTransfer.getData('text/plain');
                           setZiel(null); setZieht(null);
                           if (quelle && quelle !== p.person) onAblegen(p.person, z.zone, quelle);
                         }}>
                      {z.text}
                    </div>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>
      </div>
    </div>
  );
};

export default Familienbaum;
