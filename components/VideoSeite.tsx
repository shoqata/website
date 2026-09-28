import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Film, Play } from 'lucide-react';
import { supabase } from '@/services/supabase-bridge';
import { useTranslation } from '../context/LanguageContext';
import { onImageError } from '../lib/imageFallback';

type Video = {
  id: string; titel: string; beschreibung: string | null;
  quelle: string; vorschaubild: string | null; dauer_s: number | null;
};

// Die oeffentliche Videoseite des Vereins.
//
// Was hier erscheint, entscheidet die Zeilenregel videos_public_read: der
// Beitrag muss freigegeben sein UND das Modul muss fuer diesen Verein
// laufen. Eine Pruefung an dieser Stelle waere wirkungslos -- wer die
// Schnittstelle kennt, fragt sie ohne diese Seite ab.
const VideoSeite: React.FC = () => {
  const { t } = useTranslation();
  const [videos, setVideos] = useState<Video[] | null>(null);
  const [laeuft, setLaeuft] = useState<string | null>(null);

  useEffect(() => {
    supabase.from('videos')
      .select('id,titel,beschreibung,quelle,vorschaubild,dauer_s')
      .order('reihenfolge')
      .then(({ data, error }) => setVideos(error ? [] : ((data as Video[]) || [])));
  }, []);

  const dauer = (s: number | null) =>
    s == null ? '' : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;

  return (
    <div className="min-h-screen bg-[#faf9f6] pt-36 pb-24">
      <div className="max-w-5xl mx-auto px-6">
        <div className="mb-14">
          <p className="text-[11px] font-bold text-stone-400 uppercase tracking-[0.2em] mb-4">
            {t('video.oeff_marke')}
          </p>
          <h1 className="text-4xl md:text-5xl font-display font-bold italic text-stone-900">
            {t('video.oeff_titel')}
          </h1>
        </div>

        {videos === null ? (
          <div className="space-y-4">
            {[0, 1].map(i => (
              <div key={i} className="h-64 bg-stone-100 rounded-[2rem] animate-pulse" />
            ))}
          </div>
        ) : videos.length === 0 ? (
          <div className="text-center py-24 bg-white rounded-[2.5rem] border border-dashed border-stone-200">
            <Film size={40} className="mx-auto text-stone-200 mb-5" />
            <p className="text-stone-400 text-sm">{t('video.oeff_leer')}</p>
          </div>
        ) : (
          <div className="space-y-10">
            {videos.map((v, i) => (
              <motion.article key={v.id}
                initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.08 }}
                className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden">
                <div className="relative bg-stone-900 aspect-video">
                  {laeuft === v.id ? (
                    <video src={v.quelle} controls autoPlay playsInline
                      className="w-full h-full object-contain bg-black" />
                  ) : (
                    <button onClick={() => setLaeuft(v.id)}
                      className="group w-full h-full relative"
                      aria-label={`${v.titel} abspielen`}>
                      {v.vorschaubild
                        ? <img src={v.vorschaubild} alt="" onError={onImageError}
                               className="w-full h-full object-cover" />
                        : <div className="w-full h-full bg-stone-900" />}
                      <span className="absolute inset-0 flex items-center justify-center">
                        <span className="w-20 h-20 rounded-full bg-white/95 flex items-center justify-center shadow-2xl group-hover:scale-105 transition-transform">
                          <Play size={28} className="text-stone-900 ml-1" fill="currentColor" />
                        </span>
                      </span>
                      {v.dauer_s != null && (
                        <span className="absolute bottom-4 right-4 px-2.5 py-1 rounded-md bg-black/65 text-white text-[11px] font-mono">
                          {dauer(v.dauer_s)}
                        </span>
                      )}
                    </button>
                  )}
                </div>
                <div className="p-8 md:p-10">
                  <h2 className="text-xl font-bold text-stone-900 mb-2">{v.titel}</h2>
                  {v.beschreibung && (
                    <p className="text-sm text-stone-500 leading-relaxed max-w-2xl">{v.beschreibung}</p>
                  )}
                </div>
              </motion.article>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default VideoSeite;
