
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyAFBaQxnTdWH4GCILtndH8v4I_s0e7n634",
  authDomain: "shoqatawebsite.firebaseapp.com",
  projectId: "shoqatawebsite",
  storageBucket: "shoqatawebsite.firebasestorage.app",
  messagingSenderId: "80246981420",
  appId: "1:80246981420:web:cd77602db444229d46a289",
  measurementId: "G-FDTZX2C5C1"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
