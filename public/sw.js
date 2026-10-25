// Service Worker: zeigt Push-Nachrichten an und oeffnet beim Antippen die
// richtige Seite.
//
// Bewusst ohne fetch-Handler: nichts wird zwischengespeichert. Eine
// zwischengespeicherte alte Fassung der App nach einem Update waere
// schlimmer als keine Offline-Faehigkeit.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('push', (e) => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch { d = { titel: e.data && e.data.text() }; }
  e.waitUntil(self.registration.showNotification(d.titel || 'Neu', {
    body: d.text || '',
    icon: '/api/pwa-icon?s=192',
    tag: d.tag,
    data: { url: d.url || '/' },
  }));
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const ziel = new URL((e.notification.data && e.notification.data.url) || '/', self.location.origin);
  e.waitUntil((async () => {
    const fenster = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    // Ein offenes Fenster derselben Seite nehmen statt ein zweites zu oeffnen.
    for (const f of fenster) {
      if (new URL(f.url).origin === ziel.origin) {
        await f.focus();
        if ('navigate' in f) return f.navigate(ziel.href);
        return;
      }
    }
    return self.clients.openWindow(ziel.href);
  })());
});
