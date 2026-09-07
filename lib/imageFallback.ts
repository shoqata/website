import type { SyntheticEvent } from 'react';

// Neutraler Platzhalter als Data-URI. Bewusst ohne Netzwerkzugriff: ein
// Fallback, der selbst geladen werden muss, kann selbst ins Leere laufen.
export const IMAGE_PLACEHOLDER = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA0OCI+PHJlY3Qgd2lkdGg9IjY0IiBoZWlnaHQ9IjQ4IiBmaWxsPSIjZjVmNWY0Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIxNiIgcj0iNSIgZmlsbD0iI2Q2ZDNkMSIvPjxwYXRoIGQ9Ik02IDQyIEwyNCAyNCBMMzYgMzQgTDQ2IDI2IEw1OCA0MiBaIiBmaWxsPSIjZDZkM2QxIi8+PC9zdmc+";

// Bildquellen in den Inhalten sind nicht verlaesslich -- hochgeladene Dateien
// koennen verschwinden (der Firebase-Bucket antwortet inzwischen mit 402) und
// fremd gehostete Fotos werden entfernt. Ohne Behandlung bleibt an der Stelle
// ein sichtbar kaputtes Bild stehen.
export function onImageError(e: SyntheticEvent<HTMLImageElement>) {
  const img = e.currentTarget;
  if (img.dataset.fallbackApplied) return; // sonst Endlosschleife, falls auch der Platzhalter scheitert
  img.dataset.fallbackApplied = '1';
  img.src = IMAGE_PLACEHOLDER;
}
