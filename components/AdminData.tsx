
import React, { useState, useRef, useEffect } from 'react';
import Papa from 'papaparse';
import { 
  Database, 
  Upload, 
  Download, 
  Users, 
  MapPin, 
  CreditCard,
  Loader2,
  Trash2,
  AlertTriangle,
  Rocket
} from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, addDoc, getDocs, query, where, writeBatch, doc, Timestamp, serverTimestamp } from 'firebase/firestore';
import { useFeedback } from '../context/FeedbackContext';

const AdminData: React.FC = () => {
  const { showAlert, showPrompt, showConfirm } = useFeedback();
  const [loading, setLoading] = useState(false);
  const [migrating, setMigrating] = useState(false);
  const [log, setLog] = useState<{type: 'success'|'error'|'info'|'warning', msg: string}[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [importType, setImportType] = useState<'USERS' | 'NEIGHBORHOODS' | 'PAYMENTS'>('USERS');

  const addLog = (type: 'success'|'error'|'info'|'warning', msg: string) => {
    setLog(prev => [{type, msg}, ...prev]);
  };

  useEffect(() => {
    const runMigrations = async () => {
      setMigrating(true);
      try {
        const usersRef = collection(db, 'users');
        const q = query(usersRef, where('migrationRequired', '>', ''));
        const qSnap = await getDocs(q);
        
        if (qSnap.empty) {
          setMigrating(false);
          return;
        }
        
        addLog('info', `Found ${qSnap.size} users requiring migration. Processing...`);
        
        for (const userDoc of qSnap.docs) {
          const newId = userDoc.id;
          const oldId = userDoc.data().migrationRequired;
          
          if (!oldId) continue;
          
          const batch = writeBatch(db);
          let count = 0;
          
          // Payments
          const paymentsQ = query(collection(db, 'payments'), where('userId', '==', oldId));
          const paymentsSnap = await getDocs(paymentsQ);
          paymentsSnap.forEach(p => { batch.update(p.ref, { userId: newId }); count++; });
          
          // Event Registrations
          const eventsQ = query(collection(db, 'event_registrations'), where('userId', '==', oldId));
          const eventsSnap = await getDocs(eventsQ);
          eventsSnap.forEach(e => { batch.update(e.ref, { userId: newId }); count++; });
          
          // Inquiries
          const inquiriesQ = query(collection(db, 'inquiries'), where('userId', '==', oldId));
          const inquiriesSnap = await getDocs(inquiriesQ);
          inquiriesSnap.forEach(i => { batch.update(i.ref, { userId: newId }); count++; });
          
          // Tasks
          const tasksQ = query(collection(db, 'tasks'), where('assignedTo', 'array-contains', oldId));
          const tasksSnap = await getDocs(tasksQ);
          tasksSnap.forEach(t => {
              const data = t.data();
              const newAssignedTo = (data.assignedTo || []).map((id: string) => id === oldId ? newId : id);
              batch.update(t.ref, { assignedTo: newAssignedTo });
              count++;
          });
          
          // Board Members
          const boardQ = query(collection(db, 'board_members'), where('userId', '==', oldId));
          const boardSnap = await getDocs(boardQ);
          boardSnap.forEach(b => { batch.update(b.ref, { userId: newId }); count++; });
          
          // Remove migrationRequired flag
          batch.update(userDoc.ref, { migrationRequired: null });
          
          // Delete old document
          batch.delete(doc(db, 'users', oldId));
          
          await batch.commit();
          addLog('success', `Migrated user ${userDoc.data().email} (updated ${count} records).`);
        }
      } catch (error: any) {
        // Log silently if index is missing or other error
        console.error("Migration failed:", error);
      }
      setMigrating(false);
    };
    
    runMigrations();
  }, []);

  // --- EXPORT LOGIC ---
  const handleExport = async (collectionName: string) => {
    setLoading(true);
    addLog('info', `Starting export for ${collectionName}...`);
    try {
      let neighborhoodMap: Record<string, string> = {};
      if (collectionName === 'users') {
          const nSnap = await getDocs(collection(db, 'neighborhoods'));
          nSnap.forEach(doc => {
              const data = doc.data();
              if (data.name) neighborhoodMap[doc.id] = data.name;
          });
      }

      const q = query(collection(db, collectionName));
      const snapshot = await getDocs(q);
      
      const data = snapshot.docs.map(doc => {
        const d = doc.data();
        
        if (collectionName === 'users') {
            // STRICT ORDER REQUESTED + Extra Fields
            return {
                nachbarschaft: neighborhoodMap[d.neighborhoodId] || '',
                anrede: d.salutation || '',
                vorname: d.firstName || '',
                nachname: d.lastName || '',
                email: d.email && d.email.includes('@koretini.legacy') ? '' : d.email, // Don't export placeholder emails
                staat: d.country || '',
                'strasse nr': d.street || '',
                plz: d.zip || '',
                ort: d.city || '',
                telefon: d.phone || '',
                telefon2: d.phoneSecondary || '',
                geburtsdatum: d.birthdate || '',
                währung: d.currency || '',
                betrag: d.customAnnualFee || '',
                familienid: d.familyId || '',
                notizen: d.internalNotes || '',
                versandart: d.invoiceDeliveryMethod || 'EMAIL',
                rolle: d.role || 'MEMBER',
                status: d.membershipStatus || 'ACTIVE'
            };
        }

        const safeData: any = { id: doc.id, ...d };
        Object.keys(safeData).forEach(key => {
           const val = safeData[key];
           if (!val) return; 
           if (typeof val.toDate === 'function') {
               safeData[key] = val.toDate().toISOString();
           } else if (val.path && typeof val.firestore !== 'undefined') {
               safeData[key] = val.path; 
           } else if (typeof val === 'object') {
               try { safeData[key] = JSON.stringify(val); } catch (e) { safeData[key] = ''; }
           }
        });
        return safeData;
      });

      if (data.length === 0) {
          addLog('info', 'No data to export.');
          setLoading(false);
          return;
      }

      const csv = Papa.unparse(data);
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', `${collectionName}_export_${new Date().toISOString().split('T')[0]}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      addLog('success', `Exported ${data.length} records.`);
    } catch (e: any) {
      console.error(e);
      addLog('error', `Export failed: ${e.message}`);
    } finally {
      setLoading(false);
    }
  };

  // --- IMPORT LOGIC ---
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setLoading(true);
    addLog('info', `Parsing ${file.name}...`);

    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: async (results) => {
        if (results.errors.length > 0) {
           addLog('error', `CSV Parse Error: ${results.errors[0].message}`);
           setLoading(false);
           return;
        }
        await processImport(results.data);
        setLoading(false);
        if(fileInputRef.current) fileInputRef.current.value = '';
      }
    });
  };

  const processImport = async (data: any[]) => {
      addLog('info', `Processing ${data.length} rows for ${importType}...`);
      let successCount = 0;
      let errorCount = 0;

      // Pre-fetch all users for duplicate checking (Performance optimization)
      // We need this to check duplicates by Name when Email is missing
      let existingUsersMap = new Map<string, string>(); // Key: "firstname lastname", Value: ID
      if (importType === 'USERS') {
          const uSnap = await getDocs(collection(db, 'users'));
          uSnap.forEach(doc => {
              const d = doc.data();
              if (d.displayName) {
                  existingUsersMap.set(d.displayName.toLowerCase().trim(), doc.id);
              }
              // Also map email if exists
              if (d.email) {
                  existingUsersMap.set(d.email.toLowerCase().trim(), doc.id);
              }
          });
      }

      // Prepare Neighborhood Lookup Map (Name -> ID)
      let neighborhoodLookup: Record<string, string> = {};
      if (importType === 'USERS') {
          const nSnap = await getDocs(collection(db, 'neighborhoods'));
          nSnap.forEach(doc => {
              const name = doc.data().name;
              if (name) neighborhoodLookup[name.toLowerCase().trim()] = doc.id;
          });
      }

      for (const row of data) {
          try {
              if (importType === 'USERS') {
                  // Normalize keys to lowercase for matching
                  const safeRow: any = {};
                  Object.keys(row).forEach(k => {
                      safeRow[k.toLowerCase().trim()] = row[k];
                  });

                  // Basic Fields
                  const firstName = safeRow['vorname'] || safeRow['first name'] || safeRow['firstname'] || '';
                  const lastName = safeRow['nachname'] || safeRow['last name'] || safeRow['lastname'] || '';
                  
                  if (!firstName && !lastName) {
                      addLog('error', `Row skipped: Missing Name.`);
                      errorCount++;
                      continue;
                  }

                  const displayName = `${firstName} ${lastName}`.trim();
                  
                  // --- EMAIL & ID STRATEGY ---
                  let email = safeRow['email'] || safeRow['e-mail'];
                  let isPlaceholderEmail = false;

                  if (!email) {
                      // NO EMAIL PROVIDED: Generate a unique placeholder
                      // Format: firstname.lastname.no-email-[timestamp]-[random]@koretini.legacy
                      const cleanName = displayName.toLowerCase().replace(/[^a-z0-9]/g, '.');
                      const uniqueSuffix = Date.now().toString().slice(-6) + Math.floor(Math.random() * 100);
                      email = `${cleanName}.no-email-${uniqueSuffix}@koretini.legacy`;
                      isPlaceholderEmail = true;
                  } else {
                      email = email.toLowerCase().trim();
                  }

                  // --- DUPLICATE CHECK ---
                  // 1. Check by Email (if provided or map has it)
                  if (existingUsersMap.has(email)) {
                      addLog('warning', `Skipped duplicate email: ${email}`);
                      errorCount++;
                      continue;
                  }
                  
                  // 2. Check by Name (Only if it was a placeholder email import)
                  // If we generated a placeholder, we must ensure we don't import "Agim Gashi" twice just because the CSV has him twice without email
                  if (isPlaceholderEmail && existingUsersMap.has(displayName.toLowerCase())) {
                      addLog('warning', `Skipped potential duplicate by name: ${displayName} (No email provided in row)`);
                      errorCount++;
                      continue;
                  }

                  // Mapping German CSV Headers (Permissive Matching)
                  const salutation = safeRow['anrede'] || safeRow['salutation'] || '';
                  const country = safeRow['staat'] || safeRow['land'] || safeRow['country'] || '';
                  const street = safeRow['strasse nr'] || safeRow['strasse'] || safeRow['street'] || '';
                  const zip = safeRow['plz'] || safeRow['zip'] || '';
                  const city = safeRow['ort'] || safeRow['city'] || '';
                  const phone = safeRow['telefon'] || safeRow['phone'] || safeRow['mobile'] || safeRow['natel'] || '';
                  const phoneSecondary = safeRow['telefon2'] || safeRow['phone2'] || '';
                  const birthdate = safeRow['geburtsdatum'] || safeRow['birthdate'] || safeRow['dob'] || ''; 
                  
                  const currency = safeRow['währung'] || 'CHF';
                  const familyId = safeRow['familienid'] || safeRow['familyid'] || null;
                  const internalNotes = safeRow['notizen'] || safeRow['notes'] || null;
                  const invoiceDeliveryMethod = safeRow['versandart'] || safeRow['delivery'] || 'EMAIL';
                  const role = safeRow['rolle'] || safeRow['role'] || 'MEMBER';
                  const membershipStatus = safeRow['status'] || 'ACTIVE';
                  
                  // Handle Custom Fee Amount (betrag)
                  let customAnnualFee = null;
                  if (safeRow['betrag']) {
                      const parsed = parseFloat(safeRow['betrag'].replace(/[^0-9.]/g, ''));
                      if (!isNaN(parsed)) customAnnualFee = parsed;
                  }

                  // Resolve Neighborhood (nachbarschaft)
                  let neighborhoodId = '';
                  const nName = safeRow['nachbarschaft'] || safeRow['neighborhood'];
                  if (nName && neighborhoodLookup[nName.toLowerCase().trim()]) {
                      neighborhoodId = neighborhoodLookup[nName.toLowerCase().trim()];
                  }

                  // AUTO-CALCULATE COMPLETENESS
                  // If placeholder email OR missing address/phone -> Incomplete
                  const isProfileComplete = !isPlaceholderEmail && !!(
                      street && 
                      zip && 
                      city && 
                      phone && 
                      birthdate
                  );

                  // Construct Data Object (Ensure NO undefined values)
                  const userData = {
                      email: email,
                      displayName: displayName,
                      salutation: salutation || null,
                      firstName: firstName || null,
                      lastName: lastName || null,
                      street: street || null,
                      city: city || null,
                      zip: zip || null,
                      country: country || null,
                      phone: phone || null,
                      phoneSecondary: phoneSecondary || null,
                      birthdate: birthdate || null,
                      currency: currency || null,
                      customAnnualFee: customAnnualFee, 
                      neighborhoodId: neighborhoodId || null,
                      familyId: familyId,
                      internalNotes: internalNotes,
                      role: role,
                      membershipStatus: membershipStatus,
                      joinedAt: new Date().toISOString(),
                      
                      // Critical Flags
                      profileComplete: isProfileComplete,
                      dataUpdateRequested: !isProfileComplete, // If incomplete, trigger the alert automatically
                      isLegacyImport: true, // Marker for admin
                      
                      invoiceDeliveryMethod: invoiceDeliveryMethod,
                      tenantId: 'koretini'
                  };

                  await addDoc(collection(db, 'users'), userData);
                  
                  // Add to local map to prevent duplicates within the same file being processed
                  existingUsersMap.set(email, 'imported');
                  if (isPlaceholderEmail) existingUsersMap.set(displayName.toLowerCase(), 'imported');
              } 
              else if (importType === 'NEIGHBORHOODS') {
                  if (!row.name) throw new Error("Missing name");
                  
                  await addDoc(collection(db, 'neighborhoods'), {
                      name: row.name,
                      location: {
                          city: row.city || '',
                          country: row.country || '',
                          lat: parseFloat(row.lat) || 0,
                          lng: parseFloat(row.lng) || 0
                      },
                      status: 'ACTIVE',
                      memberCount: 0, 
                      contactPerson: row.contactPerson || '',
                      contactEmail: row.contactEmail || '',
                      createdAt: new Date().toISOString(),
                      lastActivity: new Date().toISOString()
                  });
              }
              else if (importType === 'PAYMENTS') {
                  if (!row.amount) throw new Error("Missing amount");

                  let userId = '';
                  if (!userId && row.email) {
                      // Try find by email
                      const q = query(collection(db, 'users'), where('email', '==', row.email));
                      const snap = await getDocs(q);
                      if (!snap.empty) userId = snap.docs[0].id;
                  }

                  if (!userId) {
                      addLog('error', `Could not link payment: ${row.reference || row.email || 'Unknown'}`);
                      errorCount++;
                      continue;
                  }

                  await addDoc(collection(db, 'payments'), {
                      userId: userId,
                      amount: parseFloat(row.amount),
                      currency: row.currency || 'CHF',
                      method: 'BANK_TRANSFER',
                      status: 'PAID',
                      timestamp: row.date ? Timestamp.fromDate(new Date(row.date)) : serverTimestamp(),
                      description: row.description || 'Imported Payment',
                      reference: row.reference || '',
                      invoiceNumber: `IMP-${Date.now()}-${Math.floor(Math.random()*1000)}`
                  });
              }
              successCount++;
          } catch (e: any) {
              console.error("Row Error:", e);
              addLog('error', `Error on row: ${e.message}`);
              errorCount++;
          }
      }
      addLog('success', `Finished. Imported: ${successCount}, Failed/Skipped: ${errorCount}`);
  };

  const triggerImport = (type: 'USERS' | 'NEIGHBORHOODS' | 'PAYMENTS') => {
      setImportType(type);
      fileInputRef.current?.click();
  };

  // --- GO LIVE RESET ---
  const handleGoLiveReset = async () => {
      const confirmText = await showPrompt({
          title: "GO LIVE PREPARATION",
          message: "This will delete ALL test Members, Payments, Expenses, and Accounting Data. \n\nYOUR ADMIN ACCOUNT WILL BE KEPT SAFE.\n\nType 'GO-LIVE' to confirm.",
          placeholder: "GO-LIVE",
          confirmText: "RESET OPERATIONAL DATA"
      });
      
      if (confirmText !== 'GO-LIVE') return;

      setLoading(true);
      addLog('info', 'Starting Go-Live Clean...');
      const currentUserId = auth.currentUser?.uid;

      // Collections to wipe completely
      const operationalCollections = ['payments', 'accounting_journal', 'expenses', 'invoices', 'event_registrations'];
      
      let totalDeleted = 0;

      // 1. Wipe Operational Collections
      for (const colName of operationalCollections) {
          try {
              addLog('info', `Cleaning ${colName}...`);
              const q = query(collection(db, colName));
              const snap = await getDocs(q);
              
              const batchSize = 400; 
              let batch = writeBatch(db);
              let count = 0;

              for (const docSnap of snap.docs) {
                  batch.delete(doc(db, colName, docSnap.id));
                  count++;
                  totalDeleted++;
                  if (count >= batchSize) {
                      await batch.commit();
                      batch = writeBatch(db);
                      count = 0;
                  }
              }
              if (count > 0) await batch.commit();
              addLog('success', `Cleared ${colName}.`);
          } catch (e: any) {
              addLog('error', `Failed to clear ${colName}: ${e.message}`);
          }
      }

      // 2. Wipe Users (EXCEPT CURRENT ADMIN)
      try {
          addLog('info', 'Cleaning Member Database...');
          const qUsers = query(collection(db, 'users'));
          const snapUsers = await getDocs(qUsers);
          let batch = writeBatch(db);
          let count = 0;
          let deletedUsers = 0;

          for (const docSnap of snapUsers.docs) {
              // SAFETY CHECK: Do not delete current admin
              if (docSnap.id === currentUserId) {
                  addLog('info', 'Skipping current admin user (SAFE).');
                  continue;
              }

              batch.delete(doc(db, 'users', docSnap.id));
              count++;
              deletedUsers++;
              
              if (count >= 400) {
                  await batch.commit();
                  batch = writeBatch(db);
                  count = 0;
              }
          }
          if (count > 0) await batch.commit();
          addLog('success', `Deleted ${deletedUsers} test users.`);
      } catch (e: any) {
          addLog('error', `Failed to clean users: ${e.message}`);
      }

      setLoading(false);
      showAlert({ type: 'success', message: "Ready for Go Live! Operational data cleared." });
  };

  const handleWipeData = async () => {
      const confirmText = await showPrompt({
          title: "WARNING: FACTORY RESET",
          message: "This will delete ALL data including your admin account settings potentially. Type 'DELETE-ALL' to confirm.",
          placeholder: "DELETE-ALL",
          confirmText: "WIPE EVERYTHING"
      });
      
      if (confirmText !== 'DELETE-ALL') return;

      setLoading(true);
      addLog('info', 'Starting complete wipe...');

      const collections = ['users', 'neighborhoods', 'payments', 'events', 'accounting_journal', 'socialMediaPosts', 'news', 'expenses'];
      let totalDeleted = 0;

      for (const colName of collections) {
          try {
              addLog('info', `Deleting ${colName}...`);
              const q = query(collection(db, colName));
              const snap = await getDocs(q);
              
              const batchSize = 400; 
              let batch = writeBatch(db);
              let count = 0;

              for (const docSnap of snap.docs) {
                  batch.delete(doc(db, colName, docSnap.id));
                  count++;
                  totalDeleted++;
                  if (count >= batchSize) {
                      await batch.commit();
                      batch = writeBatch(db);
                      count = 0;
                  }
              }
              if (count > 0) await batch.commit();
              addLog('success', `Cleared ${colName}.`);
          } catch (e: any) {
              addLog('error', `Failed to clear ${colName}: ${e.message}`);
          }
      }
      
      setLoading(false);
      addLog('success', `Factory Reset complete.`);
      showAlert({ type: 'success', message: "System reset complete." });
  };

  return (
    <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm p-10 min-h-[600px]">
      <div className="flex justify-between items-center mb-10">
        <div>
            <h2 className="text-3xl font-display font-bold italic mb-2">Data Center</h2>
            <p className="text-stone-500">Import and Export system data via CSV.</p>
        </div>
        <div className="flex items-center gap-4">
            {migrating && (
                <div className="bg-amber-50 px-4 py-2 rounded-xl text-xs font-mono text-amber-600 border border-amber-200 flex items-center gap-2">
                    <Loader2 size={14} className="animate-spin" />
                    Migrating Users...
                </div>
            )}
            <div className="bg-stone-50 px-4 py-2 rounded-xl text-xs font-mono text-stone-400 border border-stone-200">
                Supports .csv files
            </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
          {/* USERS CARD */}
          <div className="border border-stone-200 rounded-3xl p-6 hover:border-primary/30 transition-all group">
              <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                  <Users size={24} />
              </div>
              <h3 className="font-bold text-lg mb-2">Members</h3>
              <p className="text-xs text-stone-500 mb-6 h-10">Import members. If email is missing, a placeholder will be generated. Duplicates are checked by Name or Email.</p>
              
              <div className="flex gap-2">
                  <button onClick={() => triggerImport('USERS')} disabled={loading} className="flex-1 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-800 transition-all">
                      <Upload size={14} /> Import
                  </button>
                  <button onClick={() => handleExport('users')} disabled={loading} className="flex-1 py-2 bg-stone-100 text-stone-600 rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-200 transition-all">
                      <Download size={14} /> Export
                  </button>
              </div>
          </div>

          {/* NEIGHBORHOODS CARD */}
          <div className="border border-stone-200 rounded-3xl p-6 hover:border-primary/30 transition-all group">
              <div className="w-12 h-12 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                  <MapPin size={24} />
              </div>
              <h3 className="font-bold text-lg mb-2">Neighborhoods</h3>
              <p className="text-xs text-stone-500 mb-6 h-10">Manage locations and community groups.</p>
              
              <div className="flex gap-2">
                  <button onClick={() => triggerImport('NEIGHBORHOODS')} disabled={loading} className="flex-1 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-800 transition-all">
                      <Upload size={14} /> Import
                  </button>
                  <button onClick={() => handleExport('neighborhoods')} disabled={loading} className="flex-1 py-2 bg-stone-100 text-stone-600 rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-200 transition-all">
                      <Download size={14} /> Export
                  </button>
              </div>
          </div>

          {/* PAYMENTS CARD */}
          <div className="border border-stone-200 rounded-3xl p-6 hover:border-primary/30 transition-all group">
              <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                  <CreditCard size={24} />
              </div>
              <h3 className="font-bold text-lg mb-2">Payments</h3>
              <p className="text-xs text-stone-500 mb-6 h-10">Import bank CSVs. Matches user by Email or Reference.</p>
              
              <div className="flex gap-2">
                  <button onClick={() => triggerImport('PAYMENTS')} disabled={loading} className="flex-1 py-2 bg-stone-900 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-800 transition-all">
                      <Upload size={14} /> Import
                  </button>
                  <button onClick={() => handleExport('payments')} disabled={loading} className="flex-1 py-2 bg-stone-100 text-stone-600 rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-stone-200 transition-all">
                      <Download size={14} /> Export
                  </button>
              </div>
          </div>
      </div>

      {/* DANGER ZONES */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
          {/* GO LIVE RESET */}
          <div className="bg-emerald-50 rounded-3xl p-8 border border-emerald-100">
              <div className="flex items-center gap-4 mb-6">
                  <div className="p-3 bg-emerald-100 rounded-xl text-emerald-600"><Rocket size={24} /></div>
                  <div>
                      <h3 className="font-bold text-emerald-900">Go Live Preparation</h3>
                      <p className="text-emerald-700 text-sm">Delete test data (Users, Payments, Journal) but keep Admin account.</p>
                  </div>
              </div>
              <button onClick={handleGoLiveReset} className="w-full bg-white border border-emerald-200 text-emerald-700 px-6 py-3 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-emerald-600 hover:text-white transition-all shadow-sm">
                  <Trash2 size={18} /> Reset Operational Data
              </button>
          </div>

          {/* FACTORY RESET */}
          <div className="bg-red-50 rounded-3xl p-8 border border-red-100">
              <div className="flex items-center gap-4 mb-6">
                  <div className="p-3 bg-red-100 rounded-xl text-red-600"><AlertTriangle size={24} /></div>
                  <div>
                      <h3 className="font-bold text-red-900">Factory Reset</h3>
                      <p className="text-red-700 text-sm">Irreversible. Deletes EVERYTHING including neighborhoods and settings.</p>
                  </div>
              </div>
              <button onClick={handleWipeData} className="w-full bg-white border border-red-200 text-red-600 px-6 py-3 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-red-600 hover:text-white transition-all shadow-sm">
                  <Trash2 size={18} /> Wipe All Data
              </button>
          </div>
      </div>

      {/* Hidden File Input */}
      <input type="file" accept=".csv" ref={fileInputRef} onChange={handleFileChange} className="hidden" />

      {/* Console / Log */}
      <div className="bg-stone-900 rounded-2xl p-6 text-stone-400 font-mono text-xs h-64 overflow-y-auto">
          <div className="flex justify-between items-center mb-4 border-b border-stone-800 pb-2">
              <span className="font-bold uppercase tracking-widest text-stone-500">System Log</span>
              {loading && <Loader2 className="animate-spin text-primary" size={14} />}
          </div>
          <div className="space-y-1">
              {log.length === 0 && <span className="opacity-30">Waiting for actions...</span>}
              {log.map((l, i) => (
                  <div key={i} className={`flex gap-2 ${l.type === 'error' ? 'text-red-400' : l.type === 'success' ? 'text-green-400' : l.type === 'warning' ? 'text-amber-400' : 'text-stone-300'}`}>
                      <span className="opacity-50">[{new Date().toLocaleTimeString()}]</span>
                      <span>{l.msg}</span>
                  </div>
              ))}
          </div>
      </div>
    </div>
  );
};

export default AdminData;
