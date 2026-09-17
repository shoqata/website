
import { db } from './firebase';
import { collection, addDoc, serverTimestamp } from '@/services/supabase-bridge';

interface EmailAttachment {
  filename: string;
  content: string; // base64 string
  encoding?: 'base64'; // Default is base64 for the extension
}

interface EmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  attachments?: EmailAttachment[];
  template?: {
    name: string;
    data: any;
  };
}

// Eine Nachricht in die Warteschlange stellen.
//
// Frueher schrieb diese Funktion in eine Sammlung 'mail' und setzte darauf,
// dass die Firebase-Erweiterung "Trigger Email" sie abholt. Seit der
// Umstellung auf Supabase gibt es diese Tabelle nicht -- der Aufruf scheiterte
// still, und es ging seither keine einzige Nachricht hinaus. Auch keine
// Rechnung.
//
// Jetzt geht alles in mail_queue. Von dort holt die Funktion send-mail-queue
// die Nachrichten ab und versendet sie ueber den hinterlegten Postausgang.
// Solange keiner hinterlegt ist, bleibt alles stehen -- sichtbar und
// nachholbar, statt unbemerkt verloren.
export const sendEmail = async (options: EmailOptions) => {
  const empfaenger = Array.isArray(options.to) ? options.to : [options.to];
  const text = options.text || options.html.replace(/<[^>]*>?/gm, '');

  // Je Empfaenger eine Zeile: so laesst sich nachsehen, wer die Nachricht
  // bekommen hat und wer nicht, statt eines Sammeleintrags mit einem Zustand
  // fuer alle.
  for (const to of empfaenger) {
    await addDoc(collection(db, 'mail_queue'), {
      recipient: to,
      subject: options.subject,
      html: options.html,
      text,
      attachments: options.attachments || [],
      kind: options.template?.name ? String(options.template.name).toUpperCase() : 'GENERIC',
      status: 'PENDING',
      scheduledFor: new Date().toISOString(),
      createdAt: serverTimestamp(),
    });
  }
  return { success: true, queued: empfaenger.length };
};

// Die Warteschlange sofort abarbeiten lassen, statt auf den taeglichen Lauf zu
// warten. Der Postausgang selbst bleibt dabei serverseitig -- die Anwendung
// kennt weder Adresse noch Kennwort.
export const flushMailQueue = async (): Promise<{
  configured: boolean; sent?: number; failed?: number; hinweis?: string;
}> => {
  const { supabase } = await import('./supabase-bridge');
  if (!supabase) throw new Error('Supabase ist nicht eingerichtet.');
  const { data: sess } = await supabase.auth.getSession();
  const token = sess?.session?.access_token;
  if (!token) throw new Error('Nicht angemeldet.');

  const res = await fetch(
    `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/send-mail-queue`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: import.meta.env.VITE_SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      },
      body: '{}',
    }
  );
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.error) throw new Error(body?.error || `Serverfehler ${res.status}`);
  return body;
};
