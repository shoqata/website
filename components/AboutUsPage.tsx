
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { MapPin, Globe as GlobeIcon, Users, Target, ShieldCheck } from 'lucide-react';
import { db } from '../services/firebase';
import { collection, onSnapshot, doc, getDoc } from 'firebase/firestore';
import { UserProfile, BoardMember } from '../types';
import { Globe } from './Globe';
import { useTranslation } from '../context/LanguageContext';
import { Timeline } from './ui/Timeline';
import { TestimonialSlider, Review } from './ui/TestimonialSlider';

// Mapping table for common cities/countries to coordinates
const LOCATION_MAP: Record<string, [number, number]> = {
    'koretin': [42.54, 21.58],
    'kamenice': [42.57, 21.58],
    'gjilan': [42.46, 21.46],
    'prishtine': [42.66, 21.16],
    'zurich': [47.37, 8.54],
    'zürich': [47.37, 8.54],
    'geneva': [46.20, 6.14],
    'bern': [46.94, 7.44],
    'basel': [47.55, 7.59],
    'st. gallen': [47.42, 9.37],
    'lausanne': [46.51, 6.63],
    'munich': [48.13, 11.58],
    'berlin': [52.52, 13.40],
    'vienna': [48.20, 16.37],
    'london': [51.50, -0.12],
    'new york': [40.71, -74.00],
    'paris': [48.85, 2.35],
    'brussels': [50.85, 4.35],
    'rome': [41.90, 12.49],
    'switzerland': [46.81, 8.22],
    'zvicer': [46.81, 8.22],
    'germany': [51.16, 10.45],
    'kosovo': [42.60, 20.90]
};

const AboutUsPage: React.FC = () => {
  const { t, language } = useTranslation();
  const [branding, setBranding] = useState<any>({});
  const [globeMarkers, setGlobeMarkers] = useState<{ location: [number, number]; size: number }[]>([
      { location: [42.54, 21.58], size: 0.1 }
  ]);
  const [memberCount, setMemberCount] = useState(0);
  const [timelineData, setTimelineData] = useState<{ title: string, content: React.ReactNode }[]>([]);
  
  // Board Members Data
  const [boardReviews, setBoardReviews] = useState<Review[]>([]);

  // Helper to get localized string from branding object
  const getLoc = (val: any) => {
      if (!val) return '';
      if (typeof val === 'string') return val;
      return val[language] || val['de'] || ''; 
  };

  useEffect(() => {
    // 1. Fetch Branding (Missions & Roadmap)
    const unsubBranding = onSnapshot(doc(db, 'settings', 'branding'), (snap) => {
        if (snap.exists()) {
            const data = snap.data();
            setBranding(data);
        }
    });

    // 2. Fetch User Locations for Globe
    const unsubUsers = onSnapshot(collection(db, 'public_members'), (snap) => {
        setMemberCount(snap.size);
        const markers: { location: [number, number]; size: number }[] = [{ location: [42.54, 21.58], size: 0.1 }];
        const usersMap = new Map<string, UserProfile>();
        
        snap.docs.forEach(d => {
            const userData = d.data() as UserProfile;
            usersMap.set(d.id, userData);

            const city = userData.city?.toLowerCase();
            const country = userData.country?.toLowerCase();
            let coords: [number, number] | undefined;

            if (city && LOCATION_MAP[city]) coords = LOCATION_MAP[city];
            else if (country && LOCATION_MAP[country]) {
                const base = LOCATION_MAP[country];
                coords = [base[0] + (Math.random() - 0.5), base[1] + (Math.random() - 0.5)];
            }
            if (coords) markers.push({ location: coords, size: 0.05 });
        });
        setGlobeMarkers(markers);

        // Fetch Board Members immediately after to ensure we have users loaded
        const unsubBoard = onSnapshot(collection(db, 'board_members'), (boardSnap) => {
            const reviews: Review[] = [];
            boardSnap.forEach(doc => {
                const bm = doc.data() as BoardMember;
                const user = usersMap.get(bm.userId);
                if (user) {
                    const finalImage = bm.image || user.photoFileName || 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80&w=1000';
                    reviews.push({
                        id: bm.id || doc.id,
                        name: user.displayName || 'Unknown',
                        affiliation: bm.role,
                        quote: bm.quote,
                        imageSrc: finalImage,
                        thumbnailSrc: finalImage
                    });
                }
            });
            setBoardReviews(reviews);
        });
    });

    return () => { unsubBranding(); unsubUsers(); };
  }, []);

  // Update Timeline when branding or language changes
  useEffect(() => {
      if (branding.roadmap && Array.isArray(branding.roadmap)) {
          setTimelineData(branding.roadmap.map((item: any) => ({
              title: getLoc(item.title),
              content: <p className="text-stone-500 text-sm md:text-base font-normal mb-8 italic">"{getLoc(item.description)}"</p>
          })));
      }
  }, [branding, language]);

  const getIcon = (type: string) => {
      switch(type) {
          case 'MISSION': return <Target size={24}/>;
          case 'COMMUNITY': return <Users size={24}/>;
          case 'TRANSPARENCY': return <ShieldCheck size={24}/>;
          default: return <GlobeIcon size={24}/>;
      }
  };

  const getIconColor = (type: string) => {
      switch(type) {
          case 'MISSION': return 'bg-rose-50 text-primary';
          case 'COMMUNITY': return 'bg-blue-50 text-blue-600';
          case 'TRANSPARENCY': return 'bg-emerald-50 text-emerald-600';
          default: return 'bg-stone-50 text-stone-600';
      }
  };

  return (
    <div className="bg-[#faf9f6] min-h-screen pt-32 pb-20">
      <div className="max-w-7xl mx-auto px-6">
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-24">
            <div>
                <div className="inline-flex items-center gap-2 bg-emerald-50 text-emerald-600 px-4 py-2 rounded-full text-xs font-bold mb-6 uppercase tracking-widest">
                    <GlobeIcon size={14} /> Global Network
                </div>
                <h1 className="font-display text-5xl md:text-6xl font-bold italic mb-6 text-stone-900">
                    Rreth Nesh
                </h1>
                <p className="text-xl text-stone-500 leading-relaxed mb-8 italic">
                    Shoqata Koretini është urë lidhëse mes vendlindjes dhe diasporës. 
                    Ne jemi të përkushtuar për zhvillimin e komunitetit tonë përmes projekteve konkrete dhe solidaritetit.
                </p>
                <div className="flex gap-8">
                    <div>
                        <p className="text-4xl font-bold text-primary mb-1">{memberCount}</p>
                        <p className="text-xs font-bold text-stone-400 uppercase tracking-widest">Anëtarë Aktiv</p>
                    </div>
                    <div>
                        <p className="text-4xl font-bold text-primary mb-1">{globeMarkers.length}</p>
                        <p className="text-xs font-bold text-stone-400 uppercase tracking-widest">Lokacione</p>
                    </div>
                </div>
            </div>
            
            <div className="relative h-[600px] flex items-center justify-center">
                 <Globe markers={globeMarkers} />
                 <div className="absolute bottom-10 left-10 bg-white/80 backdrop-blur-md p-6 rounded-3xl shadow-xl border border-white max-w-xs">
                    <div className="flex items-center gap-3 mb-2">
                        <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-white"><MapPin size={16} /></div>
                        <p className="font-bold text-sm">Koretin, Kosovë</p>
                    </div>
                    <p className="text-xs text-stone-500 italic">Pika qendrore e rrjetit tonë global.</p>
                 </div>
            </div>
        </div>

        {/* Mission Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-24">
            {(branding.missions || []).map((m: any, i: number) => (
                <div key={i} className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-stone-100 hover:shadow-xl transition-all">
                    <div className={`w-12 h-12 ${getIconColor(m.type)} rounded-2xl flex items-center justify-center mb-6`}>
                        {getIcon(m.type)}
                    </div>
                    <h3 className="text-2xl font-display font-bold mb-4 italic">{getLoc(m.title)}</h3>
                    <p className="text-stone-500 leading-relaxed text-sm italic">"{getLoc(m.description)}"</p>
                </div>
            ))}
        </div>

        {/* Roadmap Section */}
        {timelineData.length > 0 && (
            <div className="mb-24">
                <Timeline data={timelineData} />
            </div>
        )}

        {/* Board Members Slider (Moved to Bottom) */}
        {boardReviews.length > 0 && (
            <div className="mb-24">
                <TestimonialSlider reviews={boardReviews} />
            </div>
        )}

      </div>
    </div>
  );
};

export default AboutUsPage;
