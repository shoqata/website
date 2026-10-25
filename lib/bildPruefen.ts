import { supabase } from '@/services/supabase-bridge';

// Bild verkleinern (im Browser) und pruefen lassen (auf dem Server).
//
// Verkleinern: laengste Seite hoechstens 1920 px, als JPEG neu gezeichnet.
// Spart Datenvolumen -- ein Handyfoto hat 4-8 MB, danach meist unter
// 500 KB -- und laesst schon hier Metadaten wie den GPS-Ort weg.
//
// Pruefen: bild-pruefen erzeugt das Bild auf dem Server noch einmal aus
// seinen Pixeln und legt es im geprueften Ordner ab. Das Verkleinern hier
// ist Bequemlichkeit, die Sicherheit liegt dort -- was im Browser
// geschieht, laesst sich umgehen.

const MAX_SEITE = 1920;

export async function bildVerkleinern(datei: File): Promise<Blob> {
  if (!/^image\/(jpeg|png|webp)$/i.test(datei.type)) {
    throw new Error('Bitte ein JPEG-, PNG- oder WebP-Bild wählen.');
  }
  if (datei.size > 25 * 1024 * 1024) throw new Error('Das Bild ist grösser als 25 MB.');
  let bild: ImageBitmap;
  try { bild = await createImageBitmap(datei); }
  catch { throw new Error('Die Datei lässt sich nicht als Bild öffnen.'); }
  const faktor = Math.min(1, MAX_SEITE / Math.max(bild.width, bild.height));
  const b = Math.round(bild.width * faktor), h = Math.round(bild.height * faktor);
  const leinwand = document.createElement('canvas');
  leinwand.width = b; leinwand.height = h;
  const ctx = leinwand.getContext('2d')!;
  ctx.fillStyle = '#ffffff';               // durchsichtige PNG nicht schwarz
  ctx.fillRect(0, 0, b, h);
  ctx.drawImage(bild, 0, 0, b, h);
  bild.close();
  const blob = await new Promise<Blob | null>(r => leinwand.toBlob(r, 'image/jpeg', 0.85));
  if (!blob) throw new Error('Das Bild konnte nicht verkleinert werden.');
  return blob;
}

export async function nachbarschaftsbildHochladen(datei: File, nachbarschaft: string): Promise<string> {
  const klein = await bildVerkleinern(datei);
  const form = new FormData();
  form.append('nachbarschaft', nachbarschaft);
  form.append('bild', new File([klein], 'bild.jpg', { type: 'image/jpeg' }));
  const { data, error } = await supabase.functions.invoke('bild-pruefen', { body: form });
  if (error) {
    // Die Meldung der Funktion steht im Koerper der Antwort.
    let text = error.message;
    try { const k = await (error as any).context?.json?.(); if (k?.fehler) text = k.fehler; } catch { /* egal */ }
    throw new Error(text);
  }
  if (!(data as any)?.url) throw new Error((data as any)?.fehler || 'Das Bild wurde nicht angenommen.');
  return (data as any).url;
}
