
import { motion, AnimatePresence, useReducedMotion, LayoutGroup, Variants } from "framer-motion";
import React, { useState, useEffect } from "react";
import { BookmarkIcon, X, Loader2 } from "lucide-react";
import { db } from "../services/firebase";
import { collection, query, orderBy, limit, onSnapshot, where, Timestamp } from "firebase/firestore";
import { NewsArticle } from "../types";
import { useTranslation } from "../context/LanguageContext";

// Utility function to replace 'cn'
function cn(...classes: (string | undefined | null | false)[]) {
  return classes.filter(Boolean).join(' ');
}

// Format time ago helper
const timeAgo = (date: Date) => {
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);
  let interval = seconds / 31536000;
  if (interval > 1) return Math.floor(interval) + " years ago";
  interval = seconds / 2592000;
  if (interval > 1) return Math.floor(interval) + " months ago";
  interval = seconds / 86400;
  if (interval > 1) return Math.floor(interval) + " days ago";
  interval = seconds / 3600;
  if (interval > 1) return Math.floor(interval) + " hours ago";
  interval = seconds / 60;
  if (interval > 1) return Math.floor(interval) + " min ago";
  return "Just now";
};

export function NewsSection() {
  const { t } = useTranslation();
  const [isLoaded, setIsLoaded] = useState(false);
  const [selectedCard, setSelectedCard] = useState<NewsArticle | null>(null);
  const [bookmarkedCards, setBookmarkedCards] = useState<Set<string>>(new Set());
  const [newsCards, setNewsCards] = useState<NewsArticle[]>([]);
  const [loading, setLoading] = useState(true);
  
  const shouldReduceMotion = useReducedMotion();
  const shouldAnimate = !shouldReduceMotion;

  useEffect(() => {
    // 1. Fetch Published News
    const q = query(
        collection(db, 'news'), 
        where('status', '==', 'PUBLISHED'),
        orderBy('timestamp', 'desc')
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const now = new Date();
      const articles = snapshot.docs
        .map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            ...data,
            gradientColors: data.gradientColors || ["from-rose-500/20", "to-purple-500/20"],
            timestamp: data.timestamp,
            publishAt: data.publishAt
          } as NewsArticle;
        })
        // 2. Client-side Scheduling Filter (in case DB index isn't ready for complex where)
        .filter(article => {
            if (!article.publishAt) return true; // immediate if no schedule
            const pDate = article.publishAt.toDate();
            return pDate <= now;
        })
        .slice(0, 6);

      setNewsCards(articles);
      setLoading(false);
      setTimeout(() => setIsLoaded(true), 100);
    });
    return () => unsubscribe();
  }, []);

  const toggleBookmark = (cardId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setBookmarkedCards(prev => {
      const newSet = new Set(prev);
      if (newSet.has(cardId)) {
        newSet.delete(cardId);
      } else {
        newSet.add(cardId);
      }
      return newSet;
    });
  };

  const openCard = (card: NewsArticle) => {
    setSelectedCard(card);
    document.body.style.overflow = 'hidden';
  };

  const closeCard = () => {
    setSelectedCard(null);
    document.body.style.overflow = 'unset';
  };

  // Animation variants
  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2,
      }
    }
  };

  const headerVariants: Variants = {
    hidden: { 
      opacity: 0, 
      y: -20,
      scale: 0.95,
      filter: "blur(4px)",
    },
    visible: { 
      opacity: 1, 
      y: 0,
      scale: 1,
      filter: "blur(0px)",
      transition: { 
        type: "spring", 
        stiffness: 400, 
        damping: 28,
        mass: 0.6,
      }
    }
  };

  const cardContainerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.12,
        delayChildren: 0.8,
      }
    }
  };

  const cardVariants: Variants = {
    hidden: { 
      opacity: 0, 
      y: 30,
      scale: 0.9,
      filter: "blur(6px)",
    },
    visible: { 
      opacity: 1, 
      y: 0, 
      scale: 1,
      filter: "blur(0px)",
      transition: { 
        type: "spring", 
        stiffness: 300, 
        damping: 28,
        mass: 0.8,
      }
    }
  };

  if (loading) {
    return (
        <div className="flex justify-center py-24">
            <Loader2 className="animate-spin text-stone-300" size={32} />
        </div>
    )
  }

  if (newsCards.length === 0) return (
      <div className="text-center py-20 text-stone-400 italic">Nuk ka lajme të publikuara aktualisht.</div>
  );

  return (
    <motion.div
      id="news"
      className="w-full max-w-7xl mx-auto px-6 py-24 bg-[#faf9f6]"
      initial={shouldAnimate ? "hidden" : "visible"}
      animate={isLoaded ? "visible" : "hidden"}
      variants={shouldAnimate ? containerVariants : {}}
    >
       {/* Header */}
       <motion.div
         className="mb-12"
         variants={shouldAnimate ? headerVariants : {}}
       >
         <h2 className="text-4xl font-display font-bold italic mb-2 text-stone-900">Aktualiteti</h2>
         <p className="text-stone-500 text-lg italic">Të rejat nga Koretini dhe diaspora.</p>
         <div className="mt-6 w-24 h-1 bg-primary rounded-full" />
       </motion.div>

       <LayoutGroup>
         <motion.div
           className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 lg:gap-8"
           variants={shouldAnimate ? cardContainerVariants : {}}
         >
           {newsCards.map((card) => {
             const formattedTime = card.timestamp ? timeAgo(card.timestamp.toDate()) : '';

             return (
               <motion.article
                 key={card.id}
                 layoutId={`card-${card.id}`}
                 className={`bg-white border border-stone-100 rounded-[2rem] overflow-hidden transition-all duration-300 cursor-pointer group shadow-sm hover:shadow-xl ${selectedCard?.id === card.id ? 'opacity-0' : 'opacity-100'}`}
                 variants={shouldAnimate ? cardVariants : {}}
                 whileHover={shouldAnimate ? { 
                   y: -4,
                   scale: 1.01,
                   transition: { type: "spring", stiffness: 400, damping: 25 }
                 } : {}}
                 onClick={() => openCard(card)}
               >
                 <motion.div 
                   layoutId={`card-image-${card.id}`}
                   className="relative h-64 overflow-hidden bg-stone-100"
                 >
                   <img
                     src={card.image}
                     alt={card.title}
                     className="w-full h-full object-cover transform-gpu group-hover:scale-105 transition-transform duration-700 ease-out"
                   />
                   <div className="absolute inset-x-0 bottom-0 h-1/2 bg-gradient-to-t from-black/60 to-transparent"></div>
                   <motion.div 
                     className="absolute top-4 right-4 z-10"
                     initial={{ opacity: 0, scale: 0.8 }}
                     animate={{ opacity: 1, scale: 1 }}
                     transition={{ delay: 0.6 }}
                     onClick={(e) => toggleBookmark(card.id, e)}
                   >
                     <div className={`p-2 rounded-full backdrop-blur-md ${bookmarkedCards.has(card.id) ? 'bg-yellow-400 text-white' : 'bg-black/20 text-white hover:bg-black/40'}`}>
                        <BookmarkIcon size={16} fill={bookmarkedCards.has(card.id) ? "currentColor" : "none"} />
                     </div>
                   </motion.div>
                   <motion.div 
                     className="absolute bottom-4 left-4 text-white p-2"
                     initial={{ opacity: 0, y: 10 }}
                     animate={{ opacity: 1, y: 0 }}
                     transition={{ delay: 0.5 }}
                   >
                     <div className="text-[10px] font-bold uppercase tracking-widest mb-1 opacity-90">
                       {card.category} • {card.subcategory}
                     </div>
                     <div className="text-xs opacity-75 font-medium flex items-center gap-2">
                       {formattedTime} • {card.location}
                     </div>
                   </motion.div>
                 </motion.div>
                 <motion.div 
                   layoutId={`card-content-${card.id}`}
                   className="p-6"
                 >
                   <motion.h3 
                     layoutId={`card-title-${card.id}`}
                     className="font-display font-bold text-xl leading-tight line-clamp-2 group-hover:text-primary transition-colors text-stone-900"
                   >
                     {card.title}
                   </motion.h3>
                   <motion.p
                     initial={{ opacity: 0 }}
                     animate={{ opacity: 1 }}
                     className="text-stone-500 text-sm mt-2 line-clamp-2"
                   >
                     {card.content?.[0]}
                   </motion.p>
                 </motion.div>
               </motion.article>
             );
           })}
         </motion.div>

         <AnimatePresence>
           {selectedCard && (
             <>
               <motion.div
                 className="fixed inset-0 bg-stone-900/60 backdrop-blur-md z-[100]"
                 initial={{ opacity: 0 }}
                 animate={{ opacity: 1 }}
                 exit={{ opacity: 0 }}
                 onClick={closeCard}
               />
               <motion.div
                 layoutId={`card-${selectedCard.id}`}
                 className="fixed inset-4 md:inset-10 lg:inset-x-32 lg:inset-y-10 bg-white rounded-[2.5rem] overflow-hidden z-[101] shadow-2xl flex flex-col md:flex-row"
               >
                 <motion.button
                   className="absolute top-6 right-6 w-10 h-10 bg-white/20 backdrop-blur-md hover:bg-white text-white hover:text-stone-900 rounded-full flex items-center justify-center z-20 transition-all shadow-lg"
                   initial={{ opacity: 0, scale: 0 }}
                   animate={{ opacity: 1, scale: 1 }}
                   transition={{ delay: 0.2 }}
                   onClick={closeCard}
                 >
                   <X className="w-5 h-5" />
                 </motion.button>
                 <motion.div 
                    layoutId={`card-image-${selectedCard.id}`}
                    className="relative w-full md:w-1/2 h-64 md:h-full bg-stone-200"
                 >
                    <img
                        src={selectedCard.image}
                        alt={selectedCard.title}
                        className="w-full h-full object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-stone-900/80 via-transparent to-transparent md:bg-gradient-to-r"></div>
                    <div className="absolute bottom-8 left-8 text-white">
                        <motion.div 
                            className="inline-flex items-center gap-2 bg-primary/90 backdrop-blur-sm px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest mb-4"
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.3 }}
                        >
                           {selectedCard.category}
                        </motion.div>
                        <h2 className="text-3xl md:text-4xl font-display font-bold italic mb-2 leading-tight">
                            {selectedCard.title}
                        </h2>
                        <div className="flex items-center gap-4 text-sm font-medium text-white/80">
                            <span>{selectedCard.subcategory}</span>
                            <span>•</span>
                            <span>{selectedCard.location}</span>
                            <span>•</span>
                            <span>{selectedCard.timestamp ? timeAgo(selectedCard.timestamp.toDate()) : ''}</span>
                        </div>
                    </div>
                 </motion.div>
                 <motion.div 
                   layoutId={`card-content-${selectedCard.id}`}
                   className="w-full md:w-1/2 p-8 md:p-12 overflow-y-auto custom-scrollbar bg-white"
                 >
                   <motion.h3 layoutId={`card-title-${selectedCard.id}`} className="hidden">{selectedCard.title}</motion.h3>
                   <motion.div 
                     className="prose prose-lg max-w-none text-stone-600 leading-relaxed space-y-6"
                     initial={{ opacity: 0, y: 20 }}
                     animate={{ opacity: 1, y: 0 }}
                     transition={{ delay: 0.4, duration: 0.4 }}
                   >
                     {selectedCard.content ? (
                       selectedCard.content.map((paragraph, index) => (
                         <p key={index} className="first-letter:text-4xl first-letter:font-display first-letter:font-bold first-letter:mr-1 first-letter:float-left first-letter:text-stone-900">
                           {paragraph}
                         </p>
                       ))
                     ) : (
                       <p>No content available.</p>
                     )}
                   </motion.div>
                 </motion.div>
               </motion.div>
             </>
           )}
         </AnimatePresence>
       </LayoutGroup>
    </motion.div>
  );
}
