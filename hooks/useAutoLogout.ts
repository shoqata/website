
import { useEffect, useRef, useCallback } from 'react';
import { signOut } from '@/services/supabase-bridge';
import { auth } from '../services/firebase';

export const useAutoLogout = (user: any) => {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  
  // 30 Minutes in milliseconds
  const TIMEOUT_MS = 30 * 60 * 1000; 

  const logout = useCallback(async () => {
    if (auth.currentUser) {
        // Set a flag so the login page knows why we are here
        localStorage.setItem('koretini_session_expired', 'true');
        await signOut(auth);
        window.location.hash = '/login';
    }
  }, []);

  const resetTimer = useCallback(() => {
    if (timerRef.current) clearTimeout(timerRef.current);
    if (user) {
        timerRef.current = setTimeout(logout, TIMEOUT_MS);
    }
  }, [user, logout]);

  useEffect(() => {
    if (!user) return;

    const events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];
    
    // Throttling mechanism to prevent performance issues
    let lastResetTimestamp = 0;
    const handleActivity = () => {
        const now = Date.now();
        // Only reset max once every 2 seconds
        if (now - lastResetTimestamp > 2000) {
            resetTimer();
            lastResetTimestamp = now;
        }
    };

    // Initialize timer
    resetTimer();

    // Add listeners
    events.forEach(e => window.addEventListener(e, handleActivity));

    // Cleanup
    return () => {
        if (timerRef.current) clearTimeout(timerRef.current);
        events.forEach(e => window.removeEventListener(e, handleActivity));
    };
  }, [user, resetTimer]);
};
