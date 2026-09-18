import React from 'react';

// Das Zeichen der Plattform: Variante 02, Knotenpunkt.
//
// Eine Mitte, an der Vereine haengen -- das Zeichen erklaert den Namen, denn
// ein Hub ist ein Knotenpunkt. Von den drei Entwuerfen der robusteste: die
// Knoten sind gross genug, dass es auch bei 16 Pixeln traegt. Verschwinden die
// duennen Linien, halten die Punkte die Form allein.
//
// Die Aussparung in der Mitte nimmt die Farbe des Untergrunds an; auf hellem
// Grund waere ein dunkler Punkt ein Fleck.
export const Knotenpunkt: React.FC<{
  size?: number;
  className?: string;
  /** Farbe der Aussparung in der Nabe -- der Untergrund. */
  grund?: string;
  /** Auf hellem Grund faellt das Cyan aus; es ist fuer die dunkle Buehne gedacht. */
  hell?: boolean;
}> = ({ size = 32, className, grund = '#00052e', hell = false }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" className={className}
       role="img" aria-label="unityhub">
    <g stroke="#0428cb" strokeWidth="1.4" fill="none" opacity={hell ? 0.5 : 0.55}>
      <path d="M24 24 L24 10" /><path d="M24 24 L36.1 17" /><path d="M24 24 L36.1 31" />
      <path d="M24 24 L24 38" /><path d="M24 24 L11.9 31" /><path d="M24 24 L11.9 17" />
    </g>
    <g fill="#0428cb">
      <circle cx="24" cy="10" r="3.1" /><circle cx="36.1" cy="17" r="3.1" />
      <circle cx="36.1" cy="31" r="3.1" /><circle cx="24" cy="38" r="3.1" />
      <circle cx="11.9" cy="31" r="3.1" />
    </g>
    <circle cx="11.9" cy="17" r="3.1" fill={hell ? '#0428cb' : '#34fcff'} opacity={hell ? 0.5 : 1} />
    <circle cx="24" cy="24" r="5.6" fill="#0428cb" />
    <circle cx="24" cy="24" r="2.2" fill={grund} />
  </svg>
);

// Zeichen und Schriftzug zusammen.
export const Wortmarke: React.FC<{
  size?: number;
  grund?: string;
  hell?: boolean;
  className?: string;
}> = ({ size = 32, grund = '#00052e', hell = false, className = '' }) => (
  <span className={`inline-flex items-center gap-3 ${className}`}>
    <Knotenpunkt size={size} grund={grund} hell={hell} />
    <span className="font-light" style={{
      fontSize: Math.round(size * 0.68),
      letterSpacing: '-0.019em',
      color: hell ? '#00052e' : '#ffffff',
    }}>
      unityhub
    </span>
  </span>
);

export default Wortmarke;
