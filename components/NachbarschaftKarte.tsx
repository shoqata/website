import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Search, Undo2, Trash2, Loader2 } from 'lucide-react';
import type { Punkt } from '../lib/nachbarschaften';

// Karten fuer die Nachbarschaften: anzeigen (Website) und Gebiet zeichnen
// (Verwaltung). OpenStreetMap, mit Quellenangabe, wie es dessen
// Nutzungsbedingungen verlangen.
//
// Leaflet direkt statt einer React-Huelle: die Karte lebt in einem
// eigenen Element, React gibt ihr nur Daten. Das haelt das Paket klein.

const KACHELN = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const QUELLE = '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>';
// Ohne Gebiet: Mitteleuropa bis Kosovo, damit die Karte nicht leer im Meer steht.
const START: [number, number] = [45.5, 14.5];

const farbe = () => getComputedStyle(document.documentElement).getPropertyValue('--primary').trim() || '#f43f5e';

export type Flaeche = { id: string; name: string; gebiet: Punkt[] };

// ------------------------------------------------------------ Anzeige
export const FlaechenKarte: React.FC<{
  flaechen: Flaeche[]; hoehe?: string; onWahl?: (id: string) => void; hervor?: string;
}> = ({ flaechen, hoehe = '24rem', onWahl, hervor }) => {
  const ziel = useRef<HTMLDivElement>(null);
  const karte = useRef<L.Map | null>(null);

  useEffect(() => {
    if (!ziel.current) return;
    const m = L.map(ziel.current, { scrollWheelZoom: false, attributionControl: true }).setView(START, 5);
    L.tileLayer(KACHELN, { attribution: QUELLE, maxZoom: 19 }).addTo(m);
    karte.current = m;
    return () => { m.remove(); karte.current = null; };
  }, []);

  useEffect(() => {
    const m = karte.current;
    if (!m) return;
    const ebene = L.featureGroup().addTo(m);
    const f = farbe();
    for (const fl of flaechen) {
      if (fl.gebiet.length < 3) continue;
      const stark = !hervor || hervor === fl.id;
      const p = L.polygon(fl.gebiet, {
        color: f, weight: stark ? 3 : 1.5, fillColor: f, fillOpacity: stark ? 0.25 : 0.08,
      }).addTo(ebene);
      p.bindTooltip(fl.name, { sticky: true, direction: 'top' });
      if (onWahl) p.on('click', () => onWahl(fl.id));
    }
    const grenzen = ebene.getBounds();
    if (grenzen.isValid()) m.fitBounds(grenzen, { padding: [24, 24], maxZoom: 17 });
    // Die Karte kennt ihre Groesse erst nach dem Zeichnen der Seite.
    setTimeout(() => m.invalidateSize(), 50);
    return () => { ebene.remove(); };
  }, [JSON.stringify(flaechen), hervor]);

  return <div ref={ziel} style={{ height: hoehe }} className="w-full rounded-[2rem] overflow-hidden border border-stone-100 z-0" />;
};

// -------------------------------------------------------------- Editor
// Klicken setzt einen Eckpunkt, die Flaeche schliesst sich selbst. Dazu
// eine Ortssuche (OpenStreetMap Nominatim), damit niemand von Europa aus
// ins eigene Dorf zoomen muss.
export const GebietZeichnen: React.FC<{ gebiet: Punkt[]; onChange: (g: Punkt[]) => void; andere?: Flaeche[] }> =
  ({ gebiet, onChange, andere = [] }) => {
  const ziel = useRef<HTMLDivElement>(null);
  const karte = useRef<L.Map | null>(null);
  const ebene = useRef<L.LayerGroup | null>(null);
  const aktuell = useRef(gebiet);
  aktuell.current = gebiet;
  // Der Klick-Handler entsteht einmal; ohne Ref riefe er fuer immer die
  // erste Fassung von onChange auf.
  const rueck = useRef(onChange);
  rueck.current = onChange;
  const [suche, setSuche] = useState('');
  const [sucht, setSucht] = useState(false);
  const [fehler, setFehler] = useState('');

  useEffect(() => {
    if (!ziel.current) return;
    const m = L.map(ziel.current, { attributionControl: true }).setView(START, 5);
    L.tileLayer(KACHELN, { attribution: QUELLE, maxZoom: 19 }).addTo(m);
    // Die anderen Nachbarschaften blass dahinter: so sieht man, wo die
    // Grenze zur Nachbarin verlaeuft.
    for (const a of andere) if (a.gebiet.length >= 3)
      L.polygon(a.gebiet, { color: '#78716c', weight: 1, fillOpacity: 0.06, dashArray: '4 4' })
        .bindTooltip(a.name).addTo(m);
    ebene.current = L.layerGroup().addTo(m);
    m.on('click', (e: L.LeafletMouseEvent) => {
      rueck.current([...aktuell.current, [Number(e.latlng.lat.toFixed(6)), Number(e.latlng.lng.toFixed(6))]]);
    });
    karte.current = m;
    if (gebiet.length) m.fitBounds(L.latLngBounds(gebiet), { padding: [30, 30], maxZoom: 17 });
    setTimeout(() => m.invalidateSize(), 80);
    return () => { m.remove(); karte.current = null; };
  }, []);

  useEffect(() => {
    const g = ebene.current;
    if (!g) return;
    g.clearLayers();
    const f = farbe();
    if (gebiet.length >= 3) L.polygon(gebiet, { color: f, weight: 3, fillColor: f, fillOpacity: 0.2 }).addTo(g);
    else if (gebiet.length === 2) L.polyline(gebiet, { color: f, weight: 3 }).addTo(g);
    gebiet.forEach((p, i) => L.circleMarker(p, {
      radius: i === gebiet.length - 1 ? 6 : 4, color: '#ffffff', weight: 2, fillColor: f, fillOpacity: 1,
    }).addTo(g));
  }, [JSON.stringify(gebiet)]);

  const finden = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!suche.trim()) return;
    setSucht(true); setFehler('');
    try {
      const r = await fetch(`https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(suche)}`,
        { headers: { 'Accept-Language': 'de' } });
      const d = await r.json();
      if (!d?.[0]) { setFehler('Nichts gefunden. Versuchen Sie Ort und Land, z. B. „Koretin, Kosovo“.'); return; }
      const b = d[0].boundingbox?.map(Number);
      if (b?.length === 4) karte.current?.fitBounds([[b[0], b[2]], [b[1], b[3]]], { maxZoom: 16 });
      else karte.current?.setView([Number(d[0].lat), Number(d[0].lon)], 15);
    } catch { setFehler('Die Suche ist gerade nicht erreichbar.'); }
    finally { setSucht(false); }
  };

  return (
    <div className="space-y-2">
      <form onSubmit={finden} className="flex gap-2">
        <input value={suche} onChange={e => setSuche(e.target.value)} placeholder="Ort suchen, z. B. Koretin, Kosovo"
          className="flex-1 p-2.5 bg-white border border-stone-200 rounded-xl text-sm outline-none" />
        <button type="submit" className="px-3 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center gap-1.5">
          {sucht ? <Loader2 size={13} className="animate-spin" /> : <Search size={13} />} Suchen
        </button>
      </form>
      {fehler && <p className="text-[11px] text-amber-700">{fehler}</p>}
      <div ref={ziel} className="w-full h-80 rounded-2xl overflow-hidden border border-stone-200 z-0 cursor-crosshair" />
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <p className="text-[11px] text-stone-500">
          {gebiet.length === 0 ? 'Klicken Sie auf der Karte die Ecken des Gebiets an.'
            : gebiet.length < 3 ? `Noch ${3 - gebiet.length} Punkt(e), dann entsteht eine Fläche.`
            : `${gebiet.length} Eckpunkte — die Fläche schliesst sich von selbst.`}
        </p>
        <div className="flex gap-2">
          <button type="button" disabled={!gebiet.length} onClick={() => onChange(gebiet.slice(0, -1))}
            className="px-3 py-1.5 bg-white border border-stone-200 rounded-lg text-xs font-bold text-stone-600 flex items-center gap-1 disabled:opacity-40">
            <Undo2 size={12} /> Letzten Punkt
          </button>
          <button type="button" disabled={!gebiet.length} onClick={() => onChange([])}
            className="px-3 py-1.5 bg-white border border-stone-200 rounded-lg text-xs font-bold text-stone-600 flex items-center gap-1 disabled:opacity-40">
            <Trash2 size={12} /> Neu zeichnen
          </button>
        </div>
      </div>
    </div>
  );
};
