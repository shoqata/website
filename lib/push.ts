import { supabase } from '../services/supabase-bridge';

// Push-Nachrichten auf den Sperrbildschirm (Browser-Seite).
//
// Der oeffentliche VAPID-Schluessel darf im Code stehen -- er ist dafuer
// gemacht. Der private liegt nur in der Funktion push-senden.
const VAPID_OEFFENTLICH = 'BOojn0VfYafx1vlgPtWa8os7uXsa-d6zwct1ENEviJnqRK5FG_DzUdS99umknZcRJLB3qzNBeAOsnRj8yrg4XuA';

export type PushStand = 'nicht-moeglich' | 'ios-installieren' | 'verweigert' | 'aus' | 'an';

const istIos = () => /iphone|ipad|ipod/i.test(navigator.userAgent);
const istApp = () => window.matchMedia?.('(display-mode: standalone)').matches || (navigator as any).standalone === true;

export function swRegistrieren() {
  if (typeof navigator === 'undefined' || !('serviceWorker' in navigator)) return;
  navigator.serviceWorker.register('/sw.js').catch(e => console.warn('[Push] Service Worker:', e?.message));
}

export async function pushStand(): Promise<PushStand> {
  // iOS kennt Push nur fuer Apps auf dem Home-Bildschirm (ab iOS 16.4).
  if (istIos() && !istApp()) return 'ios-installieren';
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) return 'nicht-moeglich';
  if (Notification.permission === 'denied') return 'verweigert';
  const reg = await navigator.serviceWorker.getRegistration();
  const abo = await reg?.pushManager.getSubscription();
  return abo && Notification.permission === 'granted' ? 'an' : 'aus';
}

const schluessel = (b64: string) => {
  const s = (b64 + '='.repeat((4 - (b64.length % 4)) % 4)).replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(s), c => c.charCodeAt(0));
};

// Muss aus einem Klick heraus laufen: Browser fragen nur dann nach der
// Erlaubnis.
export async function pushAn(): Promise<PushStand> {
  const erlaubt = await Notification.requestPermission();
  if (erlaubt !== 'granted') return erlaubt === 'denied' ? 'verweigert' : 'aus';
  const reg = await navigator.serviceWorker.register('/sw.js');
  await navigator.serviceWorker.ready;
  const abo = (await reg.pushManager.getSubscription())
    ?? await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: schluessel(VAPID_OEFFENTLICH) });
  const j = abo.toJSON() as any;
  const { error } = await supabase.rpc('push_abo_speichern', {
    p_endpoint: abo.endpoint, p_p256dh: j.keys?.p256dh, p_auth: j.keys?.auth,
    p_herkunft: window.location.origin, p_geraet: navigator.userAgent,
  });
  if (error) { await abo.unsubscribe().catch(() => {}); throw error; }
  return 'an';
}

export async function pushAus(): Promise<PushStand> {
  const reg = await navigator.serviceWorker.getRegistration();
  const abo = await reg?.pushManager.getSubscription();
  if (abo) {
    await supabase.rpc('push_abo_loeschen', { p_endpoint: abo.endpoint });
    await abo.unsubscribe().catch(() => {});
  }
  return 'aus';
}
