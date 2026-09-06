import { Neighborhood } from '../types';

// Die Quartiere tragen ihren Ort in der Spalte `city`. Das im Typ deklarierte
// `location`-Objekt existiert in keiner einzigen Zeile -- es stammt aus dem
// Firestore-Modell und hat die Migration nie mitgemacht. Ein direkter Zugriff
// auf n.location.city nimmt deshalb die ganze Seite mit.
//
// Ein Land wird bewusst nicht geraten: die 27 Quartiere liegen in Koretin,
// Zürich und München.
type NeighborhoodLike = (Partial<Neighborhood> & { city?: string }) | null | undefined;

export function neighborhoodCity(n: NeighborhoodLike): string {
  if (!n) return '';
  return n.location?.city || n.city || '';
}

export function neighborhoodPlace(n: NeighborhoodLike): string {
  return [neighborhoodCity(n), n?.location?.country].filter(Boolean).join(', ');
}
