// Die Sponsorenpakete des Turniers.
//
// Betraege und Reihenfolge stehen hier zentral, damit das oeffentliche
// Formular und die Liste im Vorstand dieselbe Quelle benutzen. Die Texte
// liegen als Uebersetzungsschluessel vor, nicht als fertige Saetze.

export type SponsorPackageKey = 'BASIC' | 'STANDARD' | 'GOLD' | 'TOURNAMENT' | 'CUSTOM';

export interface SponsorPackage {
  key: SponsorPackageKey;
  amount: number | null;      // null = Betrag gibt der Sponsor selbst an
  titleKey: string;
  benefitKeys: string[];
  highlight?: boolean;
}

export const SPONSOR_PACKAGES: SponsorPackage[] = [
  {
    key: 'BASIC',
    amount: 300,
    titleKey: 'sponsor.pkg.basic',
    benefitKeys: ['sponsor.pkg.basic.b1', 'sponsor.pkg.basic.b2'],
  },
  {
    key: 'STANDARD',
    amount: 500,
    titleKey: 'sponsor.pkg.standard',
    benefitKeys: ['sponsor.pkg.standard.b1', 'sponsor.pkg.standard.b2', 'sponsor.pkg.standard.b3'],
  },
  {
    key: 'GOLD',
    amount: 1500,
    titleKey: 'sponsor.pkg.gold',
    benefitKeys: ['sponsor.pkg.gold.b1', 'sponsor.pkg.gold.b2', 'sponsor.pkg.gold.b3'],
    highlight: true,
  },
  {
    key: 'TOURNAMENT',
    amount: 3000,
    titleKey: 'sponsor.pkg.tournament',
    benefitKeys: [
      'sponsor.pkg.tournament.b1',
      'sponsor.pkg.tournament.b2',
      'sponsor.pkg.tournament.b3',
      'sponsor.pkg.tournament.b4',
    ],
  },
  {
    key: 'CUSTOM',
    amount: null,
    titleKey: 'sponsor.pkg.custom',
    benefitKeys: ['sponsor.pkg.custom.b1'],
  },
];

export const packageByKey = (key?: string): SponsorPackage | undefined =>
  SPONSOR_PACKAGES.find((p) => p.key === key);
