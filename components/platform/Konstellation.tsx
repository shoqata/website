import React, { useEffect, useRef } from 'react';

// Das Signaturbild der Startseite: eine Konstellation aus Nachbarschaften.
//
// Die Vorlage setzt an dieser Stelle eine Partikelkugel. Uebernommen ist die
// Rolle -- ein abstraktes Datenbild hinter der Ueberschrift --, nicht das
// Motiv. Ein Verein ist keine Kugel; er ist in Nachbarschaften gegliedert, und
// jede davon hat unterschiedlich viele Mitglieder. Genau das wird gezeichnet:
// Gruppen unterschiedlicher Dichte, lose um eine Mitte gelegt.
//
// Gezeichnet auf Canvas statt als SVG-Pfad: mehrere hundert Punkte als Markup
// waeren unnoetiger Ballast im Buendel.
const Konstellation: React.FC<{ className?: string }> = ({ className }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const sparsam = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    let laufend = true;
    let bild = 0;

    // Gruppen unterschiedlicher Groesse -- wie die Nachbarschaften eines
    // Vereins, von einem Mitglied bis zu fuenfzig.
    const gruppen = [
      { x: 0.50, y: 0.50, n: 46, r: 0.30 },
      { x: 0.22, y: 0.34, n: 28, r: 0.17 },
      { x: 0.78, y: 0.30, n: 22, r: 0.15 },
      { x: 0.30, y: 0.74, n: 18, r: 0.13 },
      { x: 0.74, y: 0.72, n: 14, r: 0.12 },
      { x: 0.12, y: 0.58, n: 8,  r: 0.08 },
      { x: 0.88, y: 0.56, n: 7,  r: 0.08 },
      { x: 0.50, y: 0.15, n: 6,  r: 0.07 },
    ];

    type Punkt = { x: number; y: number; r: number; takt: number; hell: boolean };
    let punkte: Punkt[] = [];

    const aufbauen = () => {
      const { width: b, height: h } = canvas.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = b * dpr;
      canvas.height = h * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

      const kleiner = Math.min(b, h);
      punkte = [];
      gruppen.forEach((g, gi) => {
        for (let i = 0; i < g.n; i++) {
          // Zum Rand hin dichter, zur Mitte hin luftiger -- so bekommt jede
          // Gruppe eine erkennbare Form statt einer gleichmaessigen Wolke.
          const winkel = Math.random() * Math.PI * 2;
          const abstand = Math.pow(Math.random(), 0.55) * g.r * kleiner;
          punkte.push({
            x: g.x * b + Math.cos(winkel) * abstand,
            y: g.y * h + Math.sin(winkel) * abstand * 0.82,
            r: 0.7 + Math.random() * 1.5,
            takt: Math.random() * Math.PI * 2,
            // Nur wenige Punkte leuchten -- die Vorlage verlangt, dass das
            // Cyan wie ein Lichtbogen wirkt und nicht wie Flaechenfarbe.
            hell: gi === 0 && Math.random() < 0.06,
          });
        }
      });
    };

    const zeichnen = () => {
      if (!laufend) return;
      const { width: b, height: h } = canvas.getBoundingClientRect();
      ctx.clearRect(0, 0, b, h);

      punkte.forEach((p) => {
        const puls = sparsam ? 0.55 : 0.45 + 0.35 * Math.sin(bild * 0.012 + p.takt);
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        if (p.hell) {
          ctx.fillStyle = `rgba(52, 252, 255, ${0.35 + puls * 0.5})`;
          ctx.shadowColor = 'rgba(52, 252, 255, 0.8)';
          ctx.shadowBlur = 8;
        } else {
          ctx.fillStyle = `rgba(112, 132, 255, ${0.16 + puls * 0.34})`;
          ctx.shadowBlur = 0;
        }
        ctx.fill();
      });
      ctx.shadowBlur = 0;

      bild++;
      if (!sparsam) raf = requestAnimationFrame(zeichnen);
    };

    let raf = 0;
    aufbauen();
    zeichnen();

    const beobachter = new ResizeObserver(() => { aufbauen(); if (sparsam) zeichnen(); });
    beobachter.observe(canvas);

    return () => {
      laufend = false;
      cancelAnimationFrame(raf);
      beobachter.disconnect();
    };
  }, []);

  return <canvas ref={canvasRef} className={className} aria-hidden="true" />;
};

export default Konstellation;
