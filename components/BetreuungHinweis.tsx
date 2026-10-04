import React, { useEffect, useState } from 'react';
import { ShieldAlert, Loader2, LogOut, Eye } from 'lucide-react';
import {
  collection, onSnapshot, resolveTenantId,
  startTenantSupport, endTenantSupport,
} from '@/services/supabase-bridge';
import { db } from '../services/datenzugriff';
import { useWerBinIch } from '../lib/useWerBinIch';
import { useIstPlattformDomain } from '../lib/useIstPlattformDomain';
import { useFeedback } from '../context/FeedbackContext';

// Der Betreiber auf der Domain eines Vereins.
//
// Am 28.09.2026 gemeldet: "ich habe mich angemeldet, aber ich sehe keine
// Daten." Gemessen war es das Betreiberkonto burim@dervishi.ch. Es gehoert
// zu keinem Verein, also gibt current_tenant() nichts zurueck und jede
// Abfrage liefert 0 Zeilen -- waehrend is_staff() wahr bleibt und die
// Oberflaeche deshalb alle Verwaltungsmenues zeigt. Eine Anwendung, die
// vollstaendig aussieht und ueberall leer ist, ist schlimmer als eine, die
// sagt, was los ist.
//
// Der Weg an die Daten eines Vereins ist die Betreuung: start_tenant_support()
// laesst current_tenant() auf diesen Verein zeigen. Das ist ein Zugriff auf
// fremde Mitgliederdaten und wird protokolliert -- deshalb steht er hier
// sichtbar und mit einem Knopf zum Beenden, statt still im Hintergrund.
const BetreuungHinweis: React.FC<{ user: any }> = ({ user }) => {
  const istPlattform = useIstPlattformDomain();
  const wer = useWerBinIch(!!user);
  const { showAlert } = useFeedback();

  const [verein, setVerein] = useState<string | null>(null);
  const [betreuung, setBetreuung] = useState<any | null>(null);
  const [arbeitet, setArbeitet] = useState(false);

  useEffect(() => {
    resolveTenantId().then((id) => setVerein(id ?? null)).catch(() => setVerein(null));
  }, []);

  useEffect(() => {
    if (!user || !wer?.ist_betreiber) return;
    const ab = onSnapshot(collection(db, 'platform_support'), (snap: any) => {
      // Nur die eigene Sitzung, und nur eine, die noch gilt. Beim ersten
      // Entwurf nahm ich die neueste offene Zeile von irgendwem -- eine
      // fremde, liegengebliebene Betreuung haette das Feld dauerhaft auf
      // "laeuft" stehen lassen. Genau so eine lag vom 17.09. herum.
      // Die acht Stunden stehen auch in current_tenant(); Oberflaeche und
      // Datenbank sollen dasselbe sagen.
      const meine = String(user?.email || '').toLowerCase();
      const grenze = Date.now() - 8 * 3600 * 1000;
      const offen = snap.docs.map((d: any) => ({ id: d.id, ...d.data() }))
        .filter((r: any) => !r.endedAt
          && String(r.email || '').toLowerCase() === meine
          && new Date(r.startedAt).getTime() > grenze)
        .sort((a: any, b: any) => String(b.startedAt).localeCompare(String(a.startedAt)));
      setBetreuung(offen[0] || null);
    }, () => { /* ohne Leserecht kein Hinweis -- dann gilt der Normalfall */ });
    return () => ab();
  }, [user, user?.email, wer?.ist_betreiber]);

  // Nur fuer den Betreiber, nur auf der Domain eines Vereins, und nur wenn
  // er selbst zu keinem Verein gehoert. Ein Vereinsadministrator sieht das
  // hier nie.
  if (!user || istPlattform !== false || !wer?.ist_betreiber || wer.verein) return null;
  if (!verein) return null;

  const betreutDiesen = betreuung?.tenantId === verein;

  const starten = async () => {
    setArbeitet(true);
    try {
      await startTenantSupport(verein, 'Zugriff über die Vereinsdomain');
      // Neu laden, weil die halbe Anwendung ihre Daten beim Aufbau holt und
      // sonst leer bliebe, bis jemand von Hand neu laedt.
      window.location.reload();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || 'Betreuung konnte nicht gestartet werden.' });
      setArbeitet(false);
    }
  };

  const beenden = async () => {
    setArbeitet(true);
    try {
      await endTenantSupport();
      window.location.reload();
    } catch (e: any) {
      showAlert({ type: 'error', message: e?.message || 'Betreuung konnte nicht beendet werden.' });
      setArbeitet(false);
    }
  };

  return (
    <div className={`fixed bottom-4 left-4 right-4 md:left-auto md:right-6 md:w-[27rem] z-[300]
                     rounded-2xl border shadow-xl p-5 text-sm
                     ${betreutDiesen
                        ? 'bg-amber-50 border-amber-200 text-amber-900'
                        : 'bg-stone-900 border-stone-700 text-stone-100'}`}>
      <div className="flex items-start gap-3">
        {betreutDiesen
          ? <Eye size={18} className="shrink-0 mt-0.5 text-amber-600" />
          : <ShieldAlert size={18} className="shrink-0 mt-0.5 text-stone-400" />}
        <div className="space-y-2 min-w-0">
          {betreutDiesen ? (
            <>
              <p className="font-bold">Betreuung läuft</p>
              <p className="text-xs leading-relaxed">
                Sie sehen die Daten dieses Vereins als Betreiber. Das ist protokolliert.
                Beenden Sie die Betreuung, wenn Sie fertig sind.
              </p>
              <button onClick={beenden} disabled={arbeitet}
                className="mt-1 inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-500 text-stone-900 text-xs font-bold hover:bg-amber-400 transition-colors disabled:opacity-50">
                {arbeitet ? <Loader2 size={13} className="animate-spin" /> : <LogOut size={13} />}
                Betreuung beenden
              </button>
            </>
          ) : (
            <>
              <p className="font-bold">Sie sind als Betreiber angemeldet</p>
              <p className="text-xs leading-relaxed text-stone-300">
                Dieses Konto gehört zu keinem Verein — deshalb bleibt hier alles leer,
                obwohl die Menüs vollständig aussehen. Um die Daten dieses Vereins zu
                sehen, starten Sie die Betreuung. Sie wird protokolliert.
              </p>
              <button onClick={starten} disabled={arbeitet}
                className="mt-1 inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-white text-stone-900 text-xs font-bold hover:bg-stone-200 transition-colors disabled:opacity-50">
                {arbeitet ? <Loader2 size={13} className="animate-spin" /> : <Eye size={13} />}
                Betreuung starten
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default BetreuungHinweis;
