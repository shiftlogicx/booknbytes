'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { verifyAdminAuthorization, recordAdminLogin } from '@/lib/data-service';
import { ShieldCheck, AlertCircle, RefreshCw, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function AuthCallbackPage() {
  const router = useRouter();
  const [status, setStatus] = useState<'verifying' | 'success' | 'unauthorized' | 'error'>('verifying');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [userEmail, setUserEmail] = useState<string | null>(null);

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // Retrieve session established by Supabase OAuth redirect
        const { data: { session }, error } = await supabase.auth.getSession();

        if (error) {
          throw error;
        }

        if (!session?.user?.email) {
          // Listen once for auth state change in case hash is being exchanged
          const { data: sub } = supabase.auth.onAuthStateChange(async (event, newSession) => {
            if (newSession?.user?.email) {
              await processAdminLogin(newSession.user.email, newSession.user.app_metadata?.provider || 'oauth');
            }
          });

          // Timeout fallback after 4 seconds
          setTimeout(() => {
            if (status === 'verifying') {
              setStatus('error');
              setErrorMessage('Authentication session expired or not found. Please try again.');
            }
          }, 4000);
          return;
        }

        await processAdminLogin(session.user.email, session.user.app_metadata?.provider || 'oauth');
      } catch (err: any) {
        console.error('OAuth callback handling error:', err);
        setStatus('error');
        setErrorMessage(err.message || 'An error occurred during authentication verification.');
      }
    };

    const processAdminLogin = async (email: string, provider: string) => {
      setUserEmail(email);
      const admin = await verifyAdminAuthorization(email);

      if (!admin) {
        await recordAdminLogin(email, provider, 'failed');
        setStatus('unauthorized');
        return;
      }

      await recordAdminLogin(email, provider, 'success');
      if (typeof window !== 'undefined') {
        localStorage.setItem('bnb_admin_session', JSON.stringify(admin));
      }

      setStatus('success');
      setTimeout(() => {
        router.push('/');
      }, 800);
    };

    handleAuthCallback();
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[#0A0D14] text-white">
      <div className="w-full max-w-md bg-[#111624] border border-[#1E2638] rounded-2xl p-8 shadow-2xl text-center space-y-6">
        <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-emerald-500 to-teal-400 mx-auto flex items-center justify-center font-black text-slate-950 text-2xl shadow-lg shadow-emerald-500/20">
          B
        </div>

        {status === 'verifying' && (
          <div className="space-y-4">
            <RefreshCw className="w-8 h-8 text-emerald-400 animate-spin mx-auto" />
            <h2 className="text-lg font-bold">Verifying Admin Credentials...</h2>
            <p className="text-xs text-slate-400">
              Validating OAuth tokens and verifying permissions in the Supabase admin registry.
            </p>
          </div>
        )}

        {status === 'success' && (
          <div className="space-y-4">
            <ShieldCheck className="w-10 h-10 text-emerald-400 mx-auto" />
            <h2 className="text-lg font-bold text-white">Welcome to Admin Console</h2>
            <p className="text-xs text-emerald-400 font-semibold">
              Authorized as {userEmail}. Redirecting to dashboard...
            </p>
          </div>
        )}

        {status === 'unauthorized' && (
          <div className="space-y-4">
            <AlertCircle className="w-10 h-10 text-amber-400 mx-auto" />
            <h2 className="text-lg font-bold text-white">Access Denied</h2>
            <p className="text-xs text-slate-300">
              Your account (<span className="text-amber-400 font-mono">{userEmail}</span>) is authenticated but is not listed in the <span className="font-semibold text-white">admin_users</span> table.
            </p>
            <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-500/20 text-[11px] text-amber-300 text-left">
              Contact your super administrator to grant your email administrative access.
            </div>
            <Link
              href="/login"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold transition"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back to Login</span>
            </Link>
          </div>
        )}

        {status === 'error' && (
          <div className="space-y-4">
            <AlertCircle className="w-10 h-10 text-red-400 mx-auto" />
            <h2 className="text-lg font-bold text-white">Verification Failed</h2>
            <p className="text-xs text-red-300 font-mono">
              {errorMessage}
            </p>
            <Link
              href="/login"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold transition"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Try Again</span>
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
