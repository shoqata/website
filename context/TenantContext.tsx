
import React, { createContext, useContext, useState, useEffect } from 'react';
import { db } from '../services/firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { Tenant } from '../types';

interface TenantContextType {
  tenant: Tenant | null;
  loading: boolean;
  isSuperAdmin: boolean; // Flag to indicate if we are in the SuperAdmin dashboard
}

const TenantContext = createContext<TenantContextType | undefined>(undefined);

export const useTenant = () => {
  const context = useContext(TenantContext);
  if (!context) throw new Error('useTenant must be used within a TenantProvider');
  return context;
};

export const TenantProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [tenant, setTenant] = useState<Tenant | null>(null);
  const [loading, setLoading] = useState(true);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);

  useEffect(() => {
    const resolveTenant = async () => {
      const hostname = window.location.hostname;
      
      // Check for Super Admin domain/subdomain
      if (hostname.startsWith('admin.') || hostname.includes('super-admin')) {
          setIsSuperAdmin(true);
          setLoading(false);
          return;
      }

      // Check for 'www' or root domain (Landing Page)
      if (hostname === 'koretini.org' || hostname === 'www.koretini.org' || hostname === 'localhost') {
          // For localhost development, we default to a test tenant 'koretini'
          // In production, root might be the sales page
          const q = query(collection(db, 'tenants'), where('slug', '==', 'koretini'));
          const snap = await getDocs(q);
          if (!snap.empty) {
              setTenant({ id: snap.docs[0].id, ...snap.docs[0].data() } as Tenant);
          }
      } else {
          // Subdomain logic (e.g. fc-basel.koretini.org)
          const subdomain = hostname.split('.')[0];
          const q = query(collection(db, 'tenants'), where('slug', '==', subdomain));
          const snap = await getDocs(q);
          if (!snap.empty) {
              setTenant({ id: snap.docs[0].id, ...snap.docs[0].data() } as Tenant);
          }
      }
      setLoading(false);
    };

    resolveTenant();
  }, []);

  // Inject Branding CSS Variables when tenant changes
  useEffect(() => {
      if (tenant) {
          if (tenant.primaryColor) document.documentElement.style.setProperty('--primary', tenant.primaryColor);
          if (tenant.secondaryColor) document.documentElement.style.setProperty('--secondary', tenant.secondaryColor);
      }
  }, [tenant]);

  return (
    <TenantContext.Provider value={{ tenant, loading, isSuperAdmin }}>
      {children}
    </TenantContext.Provider>
  );
};
