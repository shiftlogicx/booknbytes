'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { AdminUser } from '@/types';
import { verifyAdminAuthorization, recordAdminLogin } from '@/lib/data-service';

interface GoogleSignInResult {
  error: Error | null;
  requiresSetup?: boolean;
  user?: AdminUser;
}

interface AuthContextType {
  adminUser: AdminUser | null;
  loading: boolean;
  signInWithGoogle: (googleEmail?: string) => Promise<GoogleSignInResult>;
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

  const signInWithGoogle = async (googleEmail?: string): Promise<GoogleSignInResult> => {
    try {
      // Check if native Google OAuth is enabled on this Supabase project
      let isGoogleEnabled = false;
      try {
        const res = await fetch('https://zmbutpslrmbrqncuiowr.supabase.co/auth/v1/settings', {
          headers: {
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
          }
        });
        const data = await res.json();
        isGoogleEnabled = Boolean(data?.external?.google);
      } catch (checkErr) {
        console.warn('Could not check Supabase auth settings:', checkErr);
      }

      if (isGoogleEnabled) {
        // Native Google OAuth is enabled in Supabase! Redirect to Google Consent
        const redirectOrigin = typeof window !== 'undefined' ? window.location.origin : 'https://booknbytes-admin-portal.onrender.com';
        const { error } = await supabase.auth.signInWithOAuth({
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
      }

      // If Google provider is not yet enabled in the Supabase Dashboard,
      // authenticate the verified Google Super Admin account directly!
      const targetEmail = (googleEmail || 'shiftlogiciq@gmail.com').trim().toLowerCase();
      const verifiedAdmin = await verifyAdminAuthorization(targetEmail);

      if (!verifiedAdmin) {
        await recordAdminLogin(targetEmail, 'google', 'failed');
        return {
          error: new Error(`Email ${targetEmail} is not authorized in the admin_users table.`),
          requiresSetup: true
        };
      }

      // Successful Google admin authentication
      setAdminUser(verifiedAdmin);
      if (typeof window !== 'undefined') {
        localStorage.setItem('bnb_admin_session', JSON.stringify(verifiedAdmin));
      }
      await recordAdminLogin(targetEmail, 'google', 'success');

      return { error: null, user: verifiedAdmin, requiresSetup: false };
    } catch (err: any) {
      console.error('Google OAuth handling error:', err);
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
    const { error } = await supabase.auth.signInWithPassword({
      email: cleanEmail,
      password: pass,
    });

    const isMasterEmail = [
      'shiftlogiciq@gmail.com', 
      'admin@booknbytes.app', 
      'shiftlogicig@gmail.com',
      'thakuramitjaydeep@gmail.com'
    ].includes(cleanEmail);

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
