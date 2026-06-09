import { createClient } from "@supabase/supabase-js";

// Credentials
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || "";
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || "";

// Suppress console initialization warnings if blank
export const supabase = supabaseUrl && supabaseAnonKey ? createClient(supabaseUrl, supabaseAnonKey) : null as any;

// Timestamp compatibility class
export class Timestamp {
  constructor(public seconds: number, public nanoseconds: number) {}
  static now() {
    const ms = Date.now();
    return new Timestamp(Math.floor(ms / 1000), (ms % 1000) * 1000000);
  }
  static fromDate(date: Date) {
    const ms = date.getTime();
    return new Timestamp(Math.floor(ms / 1000), (ms % 1000) * 1000000);
  }
  toDate() {
    return new Date(this.seconds * 1000);
  }
  toISOString() {
    return this.toDate().toISOString();
  }
}

// Convert ISO string fields into Timestamp instances for full Firestore compatibility
function convertToTimestamps(data: any): any {
  if (!data) return data;
  if (Array.isArray(data)) {
    return data.map(convertToTimestamps);
  }
  if (typeof data === "object") {
    const copy = { ...data };
    for (const key in copy) {
      const val = copy[key];
      if (typeof val === "string" && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(val)) {
        copy[key] = Timestamp.fromDate(new Date(val));
      } else if (val && typeof val === "object" && !(val instanceof Timestamp)) {
        copy[key] = convertToTimestamps(val);
      }
    }
    return copy;
  }
  return data;
}

// Clean helper for Supabase insertion/updates
function cleanDataForSupabase(data: any) {
  if (!data) return data;
  const cleaned: any = {};
  for (const key in data) {
    const val = data[key];
    if (val && typeof val === "object" && val.constructor?.name === "FieldValueImpl") {
      cleaned[key] = new Date().toISOString();
    } else if (val instanceof Timestamp) {
      cleaned[key] = val.toDate().toISOString();
    } else if (val instanceof Date) {
      cleaned[key] = val.toISOString();
    } else {
      cleaned[key] = val;
    }
  }
  return cleaned;
}

// --- Firebase App Interface ---
export function initializeApp() {
  return { name: "supabase-bridge" };
}

// --- Firestore Compatibility Layer ---
export function getFirestore() {
  return { type: "db" };
}

export const db = getFirestore();

export function collection(dbObj: any, path: string) {
  return { type: "collection", path };
}

export function doc(dbOrColRef: any, ...paths: string[]) {
  if (dbOrColRef.type === "collection") {
    return { type: "document", path: dbOrColRef.path, id: paths[0] };
  }
  return { type: "document", path: dbOrColRef, id: paths[0] };
}

export function query(colRef: any, ...constraints: any[]) {
  return { type: "query", path: colRef.path, constraints };
}

export function where(field: string, op: string, value: any) {
  return { type: "where", field, op, value };
}

export function orderBy(field: string, direction: "asc" | "desc" = "asc") {
  return { type: "orderBy", field, direction };
}

export function limit(value: number) {
  return { type: "limit", value };
}

export function serverTimestamp() {
  return { constructor: { name: "FieldValueImpl" } };
}

async function buildSupabaseQuery(table: string, constraints: any[] = []) {
  if (!supabase) throw new Error("Supabase is not configured. Go to settings/env to configure VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY");
  let q = supabase.from(table).select("*");

  for (const c of constraints) {
    if (c.type === "where") {
      const { field, op, value } = c;
      if (op === "==") {
        q = q.eq(field, value);
      } else if (op === ">") {
        q = q.gt(field, value);
      } else if (op === "<") {
        q = q.lt(field, value);
      } else if (op === ">=") {
        q = q.gte(field, value);
      } else if (op === "<=") {
        q = q.lte(field, value);
      } else if (op === "array-contains") {
        q = q.contains(field, [value]);
      }
    } else if (c.type === "orderBy") {
      const { field, direction } = c;
      q = q.order(field, { ascending: direction === "asc" });
    } else if (c.type === "limit") {
      q = q.limit(c.value);
    }
  }
  return q;
}

export async function getDocs(queryOrColRef: any) {
  const table = queryOrColRef.path;
  const constraints = queryOrColRef.constraints || [];
  const q = await buildSupabaseQuery(table, constraints);
  const { data, error } = await q;

  if (error) {
    console.error(`Supabase fetch error for ${table}:`, error);
    throw error;
  }

  const mappedDocs = (data || []).map((row: any) => {
    const docData = convertToTimestamps(row);
    return {
      id: row.id,
      ref: { id: row.id, path: `${table}/${row.id}` },
      data: () => docData,
      exists: () => true
    };
  });

  return {
    docs: mappedDocs,
    empty: mappedDocs.length === 0,
    forEach: (cb: (doc: any) => void) => mappedDocs.forEach(cb),
    size: mappedDocs.length
  };
}

export async function getDoc(docRef: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { path, id } = docRef;
  const { data, error } = await supabase.from(path).select("*").eq("id", id).maybeSingle();

  if (error) {
    console.error(`Supabase getDoc error for ${path}/${id}:`, error);
    throw error;
  }

  if (!data) {
    return { exists: () => false, data: () => null, ref: docRef };
  }

  const docData = convertToTimestamps(data);
  return {
    id,
    exists: () => true,
    data: () => docData,
    ref: docRef
  };
}

export async function addDoc(colRef: any, data: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const table = colRef.path;
  const id = crypto.randomUUID();
  const row = { id, ...cleanDataForSupabase(data) };

  const { error } = await supabase.from(table).insert([row]);
  if (error) {
    console.error(`Supabase addDoc error for ${table}:`, error);
    throw error;
  }
  return { id };
}

export async function setDoc(docRef: any, data: any, options?: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { path, id } = docRef;
  const row = { id, ...cleanDataForSupabase(data) };

  const { error } = await supabase.from(path).upsert([row]);
  if (error) {
    console.error(`Supabase setDoc error for ${path}/${id}:`, error);
    throw error;
  }
  return {};
}

export async function updateDoc(docRef: any, data: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { path, id } = docRef;
  const row = cleanDataForSupabase(data);

  const { error } = await supabase.from(path).update(row).eq("id", id);
  if (error) {
    console.error(`Supabase updateDoc error for ${path}/${id}:`, error);
    throw error;
  }
  return {};
}

export async function deleteDoc(docRef: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { path, id } = docRef;

  const { error } = await supabase.from(path).delete().eq("id", id);
  if (error) {
    console.error(`Supabase deleteDoc error for ${path}/${id}:`, error);
    throw error;
  }
  return {};
}

export function writeBatch() {
  const operations: Array<() => Promise<void>> = [];
  return {
    set: (docRef: any, data: any) => {
      operations.push(() => setDoc(docRef, data));
    },
    update: (docRef: any, data: any) => {
      operations.push(() => updateDoc(docRef, data));
    },
    delete: (docRef: any) => {
      operations.push(() => deleteDoc(docRef));
    },
    commit: async () => {
      for (const op of operations) {
        await op();
      }
    }
  };
}

export function onSnapshot(ref: any, callback: (snap: any) => void) {
  let isCancelled = false;

  const pullAndCallback = async () => {
    if (isCancelled) return;
    try {
      if (ref.type === "document") {
        const snap = await getDoc(ref);
        if (!isCancelled) callback(snap);
      } else {
        const snap = await getDocs(ref);
        if (!isCancelled) callback(snap);
      }
    } catch (e) {
      console.warn("onSnapshot dynamic pull error:", e);
    }
  };

  pullAndCallback();

  if (!supabase) {
    // If Supabase is not configured, we still need to stop the loading spinner
    // but without data. The components should handle null data gracefully.
    return () => { isCancelled = true; };
  }

  const table = ref.type === "document" ? ref.path : ref.path;
  const channel = supabase
    .channel(`realtime-pub-${table}-${Math.random()}`)
    .on("postgres_changes", { event: "*", schema: "public", table }, () => {
      pullAndCallback();
    })
    .subscribe();

  return () => {
    isCancelled = true;
    supabase.removeChannel(channel);
  };
}

// --- Storage Compatibility Layer ---
export function getStorage() {
  return { type: "storage" };
}

export const storage = getStorage();

export function ref(storageObj: any, path: string) {
  return { type: "storage-ref", path };
}

export async function uploadBytes(refObj: any, file: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const cleanedPath = refObj.path.replace(/^\//, "");
  
  // Use bucket named 'uploads' by default
  const { data, error } = await supabase.storage
    .from("uploads")
    .upload(cleanedPath, file, { upsert: true });

  if (error) {
    console.error("Supabase Storage upload error:", error);
    throw error;
  }

  return { ref: refObj };
}

export async function getDownloadURL(refObj: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const cleanedPath = refObj.path.replace(/^\//, "");
  const { data } = supabase.storage.from("uploads").getPublicUrl(cleanedPath);
  return data.publicUrl;
}

// --- Auth Compatibility Layer ---
class SupabaseProjectAuth {
  private listeners: Set<(user: any) => void> = new Set();
  
  constructor() {
    if (!supabase) return;
    supabase.auth.onAuthStateChange((event, session) => {
      const user = session?.user ? {
        uid: session.user.id,
        email: session.user.email || "",
        displayName: session.user.user_metadata?.displayName || session.user.email?.split("@")[0] || "User",
        emailVerified: !!session.user.email_confirmed_at
      } : null;
      this.listeners.forEach((cb) => cb(user));
    });
  }

  get currentUser() {
    if (!supabase) return null;
    const localSessionKey = Object.keys(localStorage).find(
      key => key.startsWith("sb-") && key.endsWith("-auth-token")
    );
    if (localSessionKey) {
      try {
        const session = JSON.parse(localStorage.getItem(localSessionKey) || "");
        const user = session?.user;
        if (user) {
          return {
            uid: user.id,
            email: user.email || "",
            displayName: user.user_metadata?.displayName || user.email?.split("@")[0] || "User",
            emailVerified: !!user.email_confirmed_at
          };
        }
      } catch (e) {}
    }
    return null;
  }
}

export const auth = new SupabaseProjectAuth();

export function onAuthStateChanged(authObj: any, callback: (user: any) => void) {
  authObj.listeners.add(callback);
  callback(authObj.currentUser);
  return () => {
    authObj.listeners.delete(callback);
  };
}

export async function signOut() {
  if (!supabase) return;
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function signInWithEmailAndPassword(authObj: any, email: string, password: string) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return {
    user: {
      uid: data.user?.id,
      email: data.user?.email || ""
    }
  };
}

export async function createUserWithEmailAndPassword(authObj: any, email: string, password: string) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        displayName: email.split("@")[0]
      }
    }
  });
  if (error) throw error;
  return {
    user: {
      uid: data.user?.id,
      email: data.user?.email || ""
    }
  };
}

export async function sendPasswordResetEmail(authObj: any, email: string) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/#/login`
  });
  if (error) throw error;
}

export async function sendSignInLinkToEmail(authObj: any, email: string, actionCodeSettings: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: actionCodeSettings?.url || window.location.href
    }
  });
  if (error) throw error;
}

export function isSignInWithEmailLink(authObj: any, href: string) {
  return href.includes("access_token=") || href.includes("type=magiclink");
}

export async function signInWithEmailLink(authObj: any, email: string, href: string) {
  return { user: authObj.currentUser };
}

export async function signInWithPopup(authObj: any, provider: any) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: window.location.origin
    }
  });
  if (error) throw error;
  return { user: authObj.currentUser };
}

export class GoogleAuthProvider {}

// Export default compatibility app
const app = { name: "supabase-bridge" };
export default app;
