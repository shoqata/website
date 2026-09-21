// Der Rueckruf von Meta nach der Anmeldung.
//
// Meta schickt den Browser hierher, mit ?code= und ?state=. Der Code ist
// einmalig und kurzlebig; getauscht wird er hier, weil dafuer das
// App-Geheimnis noetig ist -- und das liegt ausschliesslich in der Umgebung
// dieser Funktion. Nicht in der Datenbank, nicht im Bundle, nicht im
// Quelltext. Ein Seiten-Token erlaubt, im Namen des Vereins zu posten; es
// waere der naechste Schluessel, der oeffentlich lesbar herumliegt.
//
// Wer verbinden darf, wurde vorher in der Datenbank entschieden:
// social_verbinden_starten() legt die einmalige Kennung an und bindet sie an
// den Verein des angemeldeten Benutzers. Hier wird sie nur noch eingeloest.
// Ohne diesen Schritt koennte jeder diese Adresse aufrufen und seine eigene
// Seite an einen fremden Verein haengen.
//
// Benoetigte Umgebungsvariablen:
//   META_APP_ID, META_APP_SECRET
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY   (setzt Supabase selbst)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const GRAPH = "https://graph.facebook.com/v21.0";

// Eine Antwort, die der Browser versteht: zurueck zur Anwendung, mit einem
// kurzen Hinweis in der Adresse. Eine JSON-Fehlermeldung waere hier nutzlos,
// hier steht ein Mensch vor dem Bildschirm.
const zurueck = (ziel: string, stand: string, text?: string) => {
  const u = new URL(ziel);
  u.hash = `${u.hash || "#/admin"}${u.hash.includes("?") ? "&" : "?"}social=${stand}` +
           (text ? `&grund=${encodeURIComponent(text.slice(0, 160))}` : "");
  return new Response(null, { status: 302, headers: { Location: u.toString() } });
};

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const fehlerVonMeta = url.searchParams.get("error_description") ||
                        url.searchParams.get("error");

  const appId = Deno.env.get("META_APP_ID") ?? "";
  const appSecret = Deno.env.get("META_APP_SECRET") ?? "";
  const sb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  if (!state) return new Response("Fehlende Kennung.", { status: 400 });

  // Die Kennung zuerst -- ohne sie ist nicht einmal bekannt, wohin
  // zurueckgeschickt werden soll.
  const { data: stand } = await sb.from("social_oauth_state")
    .select("*").eq("nonce", state).maybeSingle();

  if (!stand) return new Response("Diese Kennung ist unbekannt oder abgelaufen.", { status: 400 });
  await sb.from("social_oauth_state").delete().eq("nonce", state);

  const ziel = stand.zurueck || "https://www.unityhub.li/";
  if (new Date(stand.laeuft_ab).getTime() < Date.now()) {
    return zurueck(ziel, "fehler", "Die Anfrage ist abgelaufen. Bitte noch einmal versuchen.");
  }
  if (fehlerVonMeta || !code) {
    return zurueck(ziel, "abgebrochen", fehlerVonMeta || "Keine Freigabe erhalten.");
  }
  if (!appId || !appSecret) {
    return zurueck(ziel, "fehler", "Die Meta-App ist beim Betreiber nicht vollstaendig hinterlegt.");
  }

  const redirectUri = `${Deno.env.get("SUPABASE_URL")}/functions/v1/meta-oauth`;

  try {
    // 1. Code gegen ein kurzlebiges Benutzertoken tauschen.
    const kurz = await (await fetch(
      `${GRAPH}/oauth/access_token?client_id=${appId}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&client_secret=${appSecret}&code=${encodeURIComponent(code)}`,
    )).json();
    if (kurz.error) throw new Error(kurz.error.message);

    // 2. Gegen ein langlebiges tauschen (rund 60 Tage). Die Seiten-Token,
    //    die daraus entstehen, laufen nicht von selbst ab -- sie enden erst,
    //    wenn der Mensch die Freigabe zurueckzieht oder sein Kennwort aendert.
    const lang = await (await fetch(
      `${GRAPH}/oauth/access_token?grant_type=fb_exchange_token` +
      `&client_id=${appId}&client_secret=${appSecret}` +
      `&fb_exchange_token=${encodeURIComponent(kurz.access_token)}`,
    )).json();
    if (lang.error) throw new Error(lang.error.message);

    const laeuftAb = lang.expires_in
      ? new Date(Date.now() + Number(lang.expires_in) * 1000).toISOString()
      : null;

    // 3. Die Seiten holen, auf denen diese Person posten darf -- samt dem
    //    verknuepften Instagram-Konto, falls eines da ist.
    const seiten = await (await fetch(
      `${GRAPH}/me/accounts?fields=id,name,access_token,` +
      `instagram_business_account{id,username}&limit=100` +
      `&access_token=${encodeURIComponent(lang.access_token)}`,
    )).json();
    if (seiten.error) throw new Error(seiten.error.message);

    const liste = (seiten.data ?? []).map((s: any) => ({
      id: s.id,
      name: s.name,
      token: s.access_token,
      ig_id: s.instagram_business_account?.id ?? "",
      ig_name: s.instagram_business_account?.username ?? "",
    }));

    if (liste.length === 0) {
      return zurueck(ziel, "keine_seite",
        "Zu diesem Konto gehoert keine Facebook-Seite, auf der gepostet werden darf.");
    }

    if (liste.length > 1) {
      // Mehrere Seiten: die Administration entscheidet, nicht wir. Die Token
      // liegen solange in der Tabelle, die kein Client lesen kann.
      await sb.from("social_connections").upsert({
        tenantId: stand.tenantId, plattform: "FACEBOOK",
        zustand: "WAEHLEN", kandidaten: liste, token_laeuft_ab: laeuftAb,
        verbunden_von: stand.benutzer, letzter_fehler: null,
      }, { onConflict: "tenantId,plattform" });
      return zurueck(ziel, "waehlen");
    }

    const s = liste[0];
    await sb.from("social_connections").upsert({
      tenantId: stand.tenantId, plattform: "FACEBOOK",
      konto_id: s.id, konto_name: s.name, zugriffstoken: s.token,
      token_laeuft_ab: laeuftAb, zustand: "AKTIV", kandidaten: null,
      letzter_fehler: null, verbunden_am: new Date().toISOString(),
      verbunden_von: stand.benutzer,
    }, { onConflict: "tenantId,plattform" });

    if (s.ig_id) {
      await sb.from("social_connections").upsert({
        tenantId: stand.tenantId, plattform: "INSTAGRAM",
        konto_id: s.ig_id, konto_name: s.ig_name || s.name, zugriffstoken: s.token,
        token_laeuft_ab: laeuftAb, zustand: "AKTIV", kandidaten: null,
        letzter_fehler: null, verbunden_am: new Date().toISOString(),
        verbunden_von: stand.benutzer,
      }, { onConflict: "tenantId,plattform" });
    }

    return zurueck(ziel, s.ig_id ? "verbunden" : "nur_facebook");
  } catch (e) {
    return zurueck(ziel, "fehler", (e as Error).message);
  }
});
