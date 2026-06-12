
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
      try {
        const hostname = window.location.hostname;
        console.log(`[TenantContext] Resolving tenant for hostname: ${hostname}`);
        
        // Check for Super Admin domain/subdomain
        if (hostname.startsWith('admin.') || hostname.includes('super-admin')) {
            console.log('[TenantContext] Super Admin mode detected');
            setIsSuperAdmin(true);
            setLoading(false);
            return;
        }

        let q;
        // Check for 'www' or root domain (Landing Page)
        if (hostname === 'koretini.org' || hostname === 'www.koretini.org' || hostname === 'koretini.me' || hostname === 'www.koretini.me' || hostname === 'localhost') {
            // For localhost development or main landing domains, we default to a test tenant 'koretini'
            console.log('[TenantContext] Landing domain detected, resolving default tenant');
            q = query(collection(db, 'tenants'), where('slug', '==', 'koretini'));
        } else {
            // Subdomain logic (e.g. fc-basel.koretini.org)
            const subdomain = hostname.split('.')[0];
            console.log(`[TenantContext] Subdomain detected: ${subdomain}`);
            q = query(collection(db, 'tenants'), where('slug', '==', subdomain));
        }

        const snap = await getDocs(q);
        if (!snap.empty) {
            const data = snap.docs[0].data();
            console.log('[TenantContext] Tenant resolved:', data.name);
            setTenant({ id: snap.docs[0].id, ...data } as Tenant);
        } else {
            console.warn('[TenantContext] No tenant found for this hostname');
        }
      } catch (error) {
        console.error('[TenantContext] Error resolving tenant:', error);
      } finally {
        setLoading(false);
      }
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
