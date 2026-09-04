
import React, { createContext, useContext, useState, useEffect } from 'react';
import { db, collection, query, where, getDocs } from '../services/firebase';
import { Tenant } from '../types';

interface TenantContextType {
  tenant: Tenant | null;
  loading: boolean;
  isSuperAdmin: boolean;
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
        
        if (hostname.startsWith('admin.') || hostname.includes('super-admin')) {
            console.log('[TenantContext] Super Admin mode detected');
            setIsSuperAdmin(true);
            setLoading(false);
            return;
        }

        let q;
        if (hostname === 'koretini.org' || hostname === 'www.koretini.org' || hostname === 'koretini.me' || hostname === 'www.koretini.me' || hostname === 'localhost') {
            console.log('[TenantContext] Landing domain detected, resolving default tenant');
            q = query(collection(db, 'tenants'), where('slug', '==', 'koretini'));
        } else {
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
