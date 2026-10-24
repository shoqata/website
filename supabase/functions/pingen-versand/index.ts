import { createClient } from "jsr:@supabase/supabase-js@2";

// Briefe an Pingen uebergeben.
//
// Der Ablauf ist von Pingen vorgegeben und hat drei Schritte, die alle
// gelingen muessen -- ein halb erledigter Brief ist schlimmer als ein
// nicht begonnener:
//
//   1. Zugangsmarke holen   POST {identity}/auth/access-tokens
//   2. Ablageort erfragen   GET  {api}/file-upload  -> url + url_signature
//   3. PDF hochladen        PUT  <url>
//   4. Brief anlegen        POST {api}/organisations/{org}/deliveries/letters
//
// Scheitert Schritt 3, ist nichts passiert -- der Brief bleibt WARTEND
// und wird spaeter erneut versucht. Scheitert Schritt 4, liegt die Datei
// bei Pingen, ohne dass ein Brief daraus wurde; das kostet nichts und
// wird dort aufgeraeumt. Nur ein erfolgreicher Schritt 4 heisst, dass
// der Brief wirklich aufgegeben ist, und erst dann wird der Zustand
// gesetzt.
//
// Die Testumgebung entspricht der echten, hat aber keine Druckerei --
// dort werden aufgegebene Briefe als "versendet" simuliert. Darum laeuft
// alles zuerst dort, und PINGEN_UMGEBUNG entscheidet, wohin es geht.
// Die Zugangsdaten sind je Umgebung verschieden; die der Produktion
// funktionieren im Staging nicht und umgekehrt.

const UMGEBUNGEN = {
  staging: { api: "https://api-staging.pingen.com", id: "https://identity-staging.pingen.com" },
  produktion: { api: "https://api.pingen.com", id: "https://identity.pingen.com" },
} as const;

const umgebung = (Deno.env.get("PINGEN_UMGEBUNG") ?? "staging").toLowerCase() === "produktion"
  ? "produktion" : "staging";
const ZIEL = UMGEBUNGEN[umgebung];

const clientId = (Deno.env.get("PINGEN_CLIENT_ID") ?? "").trim();
const clientSecret = (Deno.env.get("PINGEN_CLIENT_SECRET") ?? "").trim();
const organisation = (Deno.env.get("PINGEN_ORG") ?? "").trim();
const cronToken = (Deno.env.get("CRON_TOKEN") ?? "").trim();

const json = (koerper: unknown, status = 200) =>
  new Response(JSON.stringify(koerper), {
    status, headers: { "Content-Type": "application/json" },
  });

// ------------------------------------------------------------- Zugang
async function marke(): Promise<string> {
  const leib = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: clientId,
    client_secret: clientSecret,
  });
  const r = await fetch(`${ZIEL.id}/auth/access-tokens`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: leib.toString(),
  });
  const t = await r.text();
  if (!r.ok) {
    // Den Text mitgeben, nicht nur den Code. Bei Postal hat uns ein
    // blosser Statuscode zwei Tage gekostet.
    throw new Error(`Zugang abgelehnt (${r.status}): ${t.slice(0, 200)}`);
  }
  const d = JSON.parse(t);
  if (!d?.access_token) throw new Error("Zugang ohne Marke erhalten.");
  return d.access_token as string;
}

// --------------------------------------------------------- Datei ablegen
async function ablegen(tok: string, pdf: Uint8Array): Promise<{ url: string; sig: string }> {
  const r = await fetch(`${ZIEL.api}/file-upload`, {
    headers: { Authorization: `Bearer ${tok}`, Accept: "application/vnd.api+json" },
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`Ablageort abgelehnt (${r.status}): ${t.slice(0, 200)}`);
  const d = JSON.parse(t);
  // JSON:API -- die Werte liegen unter data.attributes. Beide Formen
  // beruecksichtigen, weil aeltere Faelle sie flach liefern.
  const a = d?.data?.attributes ?? d;
  const url = a?.url, sig = a?.url_signature;
  if (!url || !sig) throw new Error(`Ablageort unvollstaendig: ${t.slice(0, 200)}`);

  const put = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "application/pdf" },
    body: pdf,
  });
  if (!put.ok) {
    throw new Error(`Hochladen fehlgeschlagen (${put.status}): `
      + (await put.text()).slice(0, 200));
  }
  return { url, sig };
}

// ----------------------------------------------------------- Brief anlegen
async function briefAnlegen(tok: string, z: any, url: string, sig: string): Promise<string> {
  const r = await fetch(`${ZIEL.api}/organisations/${organisation}/deliveries/letters`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${tok}`,
      "Content-Type": "application/vnd.api+json",
      Accept: "application/vnd.api+json",
    },
    body: JSON.stringify({
      data: {
        type: "letters",
        attributes: {
          file_original_name: z.dateiname,
          file_url: url,
          file_url_signature: sig,
          // Sofort aufgeben. Ohne das liegt der Brief bei Pingen und
          // wartet auf eine zweite Freigabe -- eine Warteschlange hinter
          // unserer Warteschlange, in der Briefe unbemerkt liegenbleiben.
          auto_send: true,
          address_position: z.adresslage,
          delivery_product: z.produkt,
          print_mode: z.duplex ? "duplex" : "simplex",
          print_spectrum: z.farbe,
          meta_data: {
            // Damit die Statusmeldung spaeter zugeordnet werden kann,
            // auch wenn unsere Kennung verloren ginge.
            recipient: { name: String(z.empfaenger ?? "").slice(0, 120) },
          },
        },
      },
    }),
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`Brief abgelehnt (${r.status}): ${t.slice(0, 300)}`);
  const d = JSON.parse(t);
  const id = d?.data?.id;
  if (!id) throw new Error(`Brief ohne Kennung angelegt: ${t.slice(0, 200)}`);
  return String(id);
}

const vonBase64 = (b64: string): Uint8Array => {
  const roh = atob(b64.replace(/\s+/g, ""));
  const aus = new Uint8Array(roh.length);
  for (let i = 0; i < roh.length; i++) aus[i] = roh.charCodeAt(i);
  return aus;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Nur POST." }, 405);

  // Derselbe Riegel wie beim Mailversand. Drei Wege herein:
  //   * CRON_TOKEN aus den Secrets,
  //   * das Zeitplan-Kennwort aus mail_settings (damit muss niemand ein
  //     Kennwort von Hand in die Secrets tragen -- der Zeitplan schickt es),
  //   * eine angemeldete Verwaltung (Knopf "Zugang pruefen", Anstossen
  //     nach dem Einreihen).
  // Bisher galt nur der erste, und es gab ihn nicht: jeder Aufruf wurde
  // abgewiesen, und eingereihte Briefe blieben liegen.
  const marke_kopf = req.headers.get("x-cron-token") ?? "";
  const dienst = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  let erlaubt = !!cronToken && marke_kopf === cronToken;
  if (!erlaubt && marke_kopf) {
    const { data: treffer } = await dienst.rpc("zeitplan_token_gueltig", { p_token: marke_kopf });
    erlaubt = treffer === true;
  }
  if (!erlaubt) {
    const kopf = req.headers.get("Authorization") ?? "";
    if (kopf.startsWith("Bearer ")) {
      const alsAufrufer = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: kopf } }, auth: { persistSession: false } },
      );
      const { data } = await alsAufrufer.auth.getUser();
      const mail = (data?.user?.email ?? "").toLowerCase();
      if (mail) {
        const { data: zeilen } = await dienst.from("users").select("role").ilike("email", mail).limit(1);
        erlaubt = ["ADMIN", "SUPER_ADMIN", "BOARD"].includes(zeilen?.[0]?.role ?? "");
        if (!erlaubt) {
          const { data: betr } = await dienst.from("platform_admins").select("email").ilike("email", mail).limit(1);
          erlaubt = !!betr?.length;
        }
      }
    }
  }
  if (!erlaubt) return json({ error: "Nicht berechtigt." }, 401);

  let koerper: any = {};
  try { koerper = await req.json(); } catch { /* leer ist in Ordnung */ }

  const fehlt = [
    !clientId && "PINGEN_CLIENT_ID",
    !clientSecret && "PINGEN_CLIENT_SECRET",
    !organisation && "PINGEN_ORG",
  ].filter(Boolean);

  if (koerper?.pruefen === true) {
    if (fehlt.length) {
      return json({ ok: false, umgebung, fehlt,
        ergebnis: `Es fehlen: ${fehlt.join(", ")}. Ohne sie kann nichts aufgegeben werden.` });
    }
    try {
      const tok = await marke();
      return json({ ok: true, umgebung, api: ZIEL.api,
        ergebnis: `Zugang gilt (${tok.length} Zeichen). `
          + (umgebung === "staging"
             ? "Testumgebung — es wird nichts gedruckt und nichts verschickt."
             : "ECHTE Umgebung — aufgegebene Briefe werden gedruckt und verschickt."),
      });
    } catch (e) {
      return json({ ok: false, umgebung,
        ergebnis: e instanceof Error ? e.message : String(e) });
    }
  }

  if (fehlt.length) return json({ error: `Es fehlen: ${fehlt.join(", ")}` }, 500);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const menge = Number.isInteger(koerper?.menge) ? Math.min(koerper.menge, 50) : 10;
  const { data: offen, error: leseFehler } = await admin
    .from("post_ausgang")
    .select("*")
    .eq("zustand", "WARTEND")
    .lte("naechster_versuch", new Date().toISOString())
    .order("erstellt_am", { ascending: true })
    .limit(menge);

  if (leseFehler) return json({ error: leseFehler.message }, 500);
  if (!offen?.length) return json({ ok: true, umgebung, aufgegeben: 0, offen: 0 });

  let tok: string;
  try { tok = await marke(); }
  catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 502);
  }

  let aufgegeben = 0, gescheitert = 0;
  const probleme: string[] = [];

  // Kontingentstaende je Verein, einmal gelesen. Der Verbrauch wird
  // danach je Brief abgebucht, aber die Pruefung VORHER verhindert, dass
  // wir bei Pingen einen Brief kaufen, den niemand bezahlt hat.
  const staende = new Map<string, number>();
  for (const verein of new Set(offen.map((z: any) => z.tenantId as string))) {
    const { data } = await admin.rpc("post_kontingent_stand", { p_verein: verein });
    staende.set(verein, Number((data as any)?.stand ?? 0));
  }

  let ohneKontingent = 0;

  for (const z of offen) {
    try {
      if (!z.pdf) throw new Error("Das Dokument fehlt -- der Brief wurde wohl zurueckgezogen.");

      // Kein Guthaben, kein Brief. Und zwar OHNE Versuchszaehler: das ist
      // kein Fehler, der sich durch Warten behebt, sondern ein Zustand,
      // den der Verein aufloesen muss. Ihn als Fehlversuch zu zaehlen
      // wuerde den Brief nach vier Anlaeufen in zwoelf Stunden Abstand
      // schicken und am Ende aussehen wie ein technisches Problem.
      const stand = staende.get(z.tenantId) ?? 0;
      if (stand < 1) {
        await admin.rpc("post_zustand_melden", {
          p_id: z.id, p_zustand: "PROBLEM",
          p_meldung: "Kontingent aufgebraucht — der Verein muss Briefe nachkaufen. "
            + "Der Brief bleibt liegen und geht hinaus, sobald Guthaben da ist.",
        });
        ohneKontingent++;
        continue;
      }
      const { url, sig } = await ablegen(tok, vonBase64(z.pdf));
      const pingenId = await briefAnlegen(tok, z, url, sig);

      // Erst JETZT den Zustand setzen. Jeder frueher gesetzte Zustand
      // waere eine Behauptung ueber etwas, das noch nicht geschehen ist.
      await admin.rpc("post_zustand_melden", {
        p_id: z.id, p_pingen_id: pingenId, p_zustand: "UEBERGEBEN",
        p_status: "submitted",
        p_meldung: umgebung === "staging" ? "Testumgebung — nicht gedruckt" : null,
      });

      // Abbuchen erst JETZT. Pingen hat den Brief angenommen; vorher
      // abzubuchen hiesse, Guthaben fuer etwas zu verbrauchen, das
      // vielleicht nie hinausgeht.
      //
      // In der Testumgebung wird ebenfalls abgebucht -- dort kostet der
      // Brief nichts, aber ein Ablauf, der im Test anders rechnet als im
      // Betrieb, prueft den Betrieb nicht.
      const { data: vb } = await admin.rpc("post_kontingent_verbrauchen",
                                           { p_post: z.id });
      if ((vb as any)?.verbraucht) {
        staende.set(z.tenantId, Number((vb as any).stand ?? 0));
      }
      aufgegeben++;
    } catch (e) {
      const grund = e instanceof Error ? e.message : String(e);
      await admin.rpc("post_zustand_melden", { p_id: z.id, p_fehler: grund });
      gescheitert++;
      probleme.push(`${z.empfaenger}: ${grund.slice(0, 120)}`);
    }
  }

  return json({
    ok: true, umgebung, aufgegeben, gescheitert, ohne_kontingent: ohneKontingent,
    probleme: probleme.slice(0, 10),
    hinweis: umgebung === "staging"
      ? "Testumgebung: aufgegebene Briefe werden als versendet simuliert, "
        + "gedruckt wird nichts."
      : undefined,
  });
});
