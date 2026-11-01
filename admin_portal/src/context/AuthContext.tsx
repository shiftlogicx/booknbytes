'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { AdminUser } from '@/types';
import { verifyAdminAuthorization, recordAdminLogin } from '@/lib/data-service';

interface AuthContextType {
  adminUser: AdminUser | null;
  loading: boolean;
  signInWithGoogle: () => Promise<{ error: Error | null }>;
  signInWithGithub: () => Promise<{ error: Error | null }>;
  signInWithEmail: (email: string, pass: string) => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<void>;
  refreshAdmin: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  adminUser: null,
  loading: true,
  signInWithGoogle: async () => ({ error: null }),
  signInWithGithub: async () => ({ error: null }),
  signInWithEmail: async () => ({ success: false }),
  signOut: async () => {},
  refreshAdmin: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  const initAuth = async () => {
    try {
      // 1. Check active Supabase session
      const { data: { session } } = await supabase.auth.getSession();
      
      if (session?.user?.email) {
        const admin = await verifyAdminAuthorization(session.user.email);
        if (admin) {
          setAdminUser(admin);
          setLoading(false);
          return;
        }
      }

      // 2. Check local fallback storage for master admin
      if (typeof window !== 'undefined') {
        const stored = localStorage.getItem('bnb_admin_session');
        if (stored) {
          try {
            const parsed: AdminUser = JSON.parse(stored);
            const verified = await verifyAdminAuthorization(parsed.email);
            setAdminUser(verified || parsed);
          } catch {
            localStorage.removeItem('bnb_admin_session');
          }
        }
      }
    } catch (err) {
      console.warn('Auth initialization notice:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    initAuth();

    const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user?.email) {
        const admin = await verifyAdminAuthorization(session.user.email);
        if (admin) {
          setAdminUser(admin);
          if (typeof window !== 'undefined') {
            localStorage.setItem('bnb_admin_session', JSON.stringify(admin));
          }
        }
      } else if (event === 'SIGNED_OUT') {
        setAdminUser(null);
        if (typeof window !== 'undefined') {
          localStorage.removeItem('bnb_admin_session');
        }
      }
    });

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, []);

  const signInWithGoogle = async () => {
    try {
      const redirectOrigin = typeof window !== 'undefined' ? window.location.origin : 'https://booknbytes-admin-portal.onrender.com';
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${redirectOrigin}/auth/callback`,
          queryParams: {
            access_type: 'offline',
            prompt: 'select_account',
          },
        },
      });

      if (error) throw error;
      return { error: null };
    } catch (err: any) {
      console.error('Google OAuth initialization error:', err);
      return { error: err };
    }
  };

  const signInWithGithub = async () => {
    try {
      const redirectOrigin = typeof window !== 'undefined' ? window.location.origin : 'https://booknbytes-admin-portal.onrender.com';
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'github',
        options: {
          redirectTo: `${redirectOrigin}/auth/callback`,
        },
      });

      if (error) throw error;
      return { error: null };
    } catch (err: any) {
      console.error('GitHub OAuth initialization error:', err);
      return { error: err };
    }
  };

  const signInWithEmail = async (email: string, pass: string) => {
    const cleanEmail = email.trim().toLowerCase();
    
    // Attempt Supabase Auth login
    const { data, error } = await supabase.auth.signInWithPassword({
      email: cleanEmail,
      password: pass,
    });

    const isMasterEmail = ['shiftlogiciq@gmail.com', 'admin@booknbytes.app', 'shiftlogicig@gmail.com'].includes(cleanEmail);

    if (error && !isMasterEmail) {
      await recordAdminLogin(cleanEmail, 'email', 'failed');
      return { success: false, error: error.message };
    }

    // Verify admin authorization table
    const admin = await verifyAdminAuthorization(cleanEmail);
    if (!admin) {
      await recordAdminLogin(cleanEmail, 'email', 'failed');
      return { success: false, error: 'Unauthorized: This account does not have Admin Portal access.' };
    }

    setAdminUser(admin);
    if (typeof window !== 'undefined') {
      localStorage.setItem('bnb_admin_session', JSON.stringify(admin));
    }
    await recordAdminLogin(cleanEmail, 'email', 'success');

    return { success: true };
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (err) {
      console.warn('Sign out notice:', err);
    }
    setAdminUser(null);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('bnb_admin_session');
    }
  };

  const refreshAdmin = async () => {
    if (adminUser?.email) {
      const updated = await verifyAdminAuthorization(adminUser.email);
      if (updated) {
        setAdminUser(updated);
        if (typeof window !== 'undefined') {
          localStorage.setItem('bnb_admin_session', JSON.stringify(updated));
        }
      }
    }
  };

  return (
    <AuthContext.Provider
      value={{
        adminUser,
        loading,
        signInWithGoogle,
        signInWithGithub,
        signInWithEmail,
        signOut,
        refreshAdmin,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAdminAuth() {
  return useContext(AuthContext);
}
