// v4: Full Supabase Auth Migration - 2026-09-04
// Firebase is no longer used. All auth and DB operations go through Supabase.
import {
  db as supabaseDb,
  storage as supabaseStorage,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  where,
  orderBy,
  limit,
  serverTimestamp,
  writeBatch,
  Timestamp,
  ref,
  uploadBytes,
  getDownloadURL,
  supabase,
  supabaseAuth,
  supabaseOnAuthStateChanged,
  supabaseSignOut,
  supabaseSignInWithEmailAndPassword,
  supabaseCreateUserWithEmailAndPassword,
  supabaseSendPasswordResetEmail,
  supabaseSendSignInLinkToEmail,
  supabaseIsSignInWithEmailLink,
  supabaseSignInWithEmailLink,
  supabaseSignInWithPopup,
  GoogleAuthProvider,
  sendEmailVerification,
  updateProfile,
} from './supabase-bridge';

// The "auth" object compatible with existing call signatures (auth.currentUser, etc.)
export const auth = supabaseAuth;
export const db = supabaseDb;
export const storage = supabaseStorage;

// Auth helpers — re-exported to match the Firebase API surface
export {
  supabaseOnAuthStateChanged as onAuthStateChanged,
  supabaseSignOut as signOut,
  supabaseSignInWithEmailAndPassword as signInWithEmailAndPassword,
  supabaseCreateUserWithEmailAndPassword as createUserWithEmailAndPassword,
  supabaseSendPasswordResetEmail as sendPasswordResetEmail,
  supabaseSendSignInLinkToEmail as sendSignInLinkToEmail,
  supabaseIsSignInWithEmailLink as isSignInWithEmailLink,
  supabaseSignInWithEmailLink as signInWithEmailLink,
  supabaseSignInWithPopup as signInWithPopup,
  GoogleAuthProvider,
  sendEmailVerification,
  updateProfile,
};

// DB/Storage helpers — re-exported from bridge
export {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  where,
  orderBy,
  limit,
  serverTimestamp,
  writeBatch,
  Timestamp,
  ref,
  uploadBytes,
  getDownloadURL,
};

// Raw Supabase client (for advanced usage)
export { supabase };

export default { name: 'supabase-only' };
