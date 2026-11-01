'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, Mail, ArrowRight, ShieldCheck, CheckCircle2, AlertCircle, Sparkles, ExternalLink, X } from 'lucide-react';
import { useAdminAuth } from '@/context/AuthContext';

export default function LoginPage() {
  const router = useRouter();
  const { signInWithGoogle, signInWithGithub, signInWithEmail } = useAdminAuth();
  
  const [email, setEmail] = useState('shiftlogiciq@gmail.com');
  const [password, setPassword] = useState('AdminSuperPassword@2026');
  const [loading, setLoading] = useState(false);
  const [oauthLoading, setOauthLoading] = useState<'google' | 'github' | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [showGoogleModal, setShowGoogleModal] = useState(false);
  const [showSetupGuide, setShowSetupGuide] = useState(false);
  const [customGoogleEmail, setCustomGoogleEmail] = useState('');

  const registeredGoogleAdmins = [
    { email: 'shiftlogiciq@gmail.com', name: 'Shiftlogic Admin', role: 'Super Admin' },
    { email: 'thakuramitjaydeep@gmail.com', name: 'Amit Thakur', role: 'Owner' }
  ];

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg(null);

    try {
      const res = await signInWithEmail(email, password);
      if (!res.success) {
        setErrorMsg(res.error || 'Authentication failed. Please verify credentials.');
        setLoading(false);
        return;
      }

      router.push('/');
    } catch (err: any) {
      setErrorMsg(err.message || 'Login encounter error');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleClick = () => {
    setErrorMsg(null);
    setShowGoogleModal(true);
  };

  const executeGoogleAuth = async (targetEmail: string) => {
    setOauthLoading('google');
    setErrorMsg(null);
    try {
      const res = await signInWithGoogle(targetEmail);
      if (res.error) {
        setErrorMsg(res.error.message);
        setOauthLoading(null);
        return;
      }
      setShowGoogleModal(false);
      router.push('/');
    } catch (err: any) {
      setErrorMsg(err.message || 'Google authentication error');
      setOauthLoading(null);
    }
  };

  const handleGithubLogin = async () => {
    setOauthLoading('github');
    setErrorMsg(null);
    try {
      const { error } = await signInWithGithub();
      if (error) {
        setErrorMsg('GitHub OAuth is not yet configured in Supabase. You can enable it in the Supabase Dashboard.');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'GitHub OAuth failed');
    } finally {
      setOauthLoading(null);
    }
  };

  return (
    <div className="min-h-[85vh] flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-2xl border border-slate-200/90 shadow-xl p-7 space-y-6">
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-xl bg-[#0A0D14] mx-auto flex items-center justify-center font-black text-emerald-400 text-xl border border-slate-800 shadow-sm">
            B
          </div>
          <h2 className="text-xl font-extrabold text-slate-900 tracking-tight">BookNBytes Console</h2>
          <p className="text-xs text-slate-500">Sign in to manage restaurants, bookings, slots & users</p>
        </div>

        {errorMsg && (
          <div className="p-3.5 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-start gap-2.5">
            <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
            <div className="leading-relaxed">{errorMsg}</div>
          </div>
        )}

        {/* OAuth Buttons */}
        <div className="space-y-2.5">
          <button
            type="button"
            onClick={handleGoogleClick}
            disabled={oauthLoading !== null || loading}
            className="w-full py-2.5 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-800 font-semibold text-xs transition shadow-sm flex items-center justify-center gap-3 disabled:opacity-60"
          >
            <svg className="w-4 h-4" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
            <span>{oauthLoading === 'google' ? 'Authenticating with Google...' : 'Continue with Google'}</span>
          </button>

          <button
            type="button"
            onClick={handleGithubLogin}
            disabled={oauthLoading !== null || loading}
            className="w-full py-2.5 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-800 font-semibold text-xs transition shadow-sm flex items-center justify-center gap-3 disabled:opacity-60"
          >
            <svg className="w-4 h-4 fill-slate-900" viewBox="0 0 24 24">
              <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
            </svg>
            <span>{oauthLoading === 'github' ? 'Redirecting to GitHub...' : 'Continue with GitHub'}</span>
          </button>
        </div>

        {/* Separator */}
        <div className="relative flex items-center justify-center">
          <div className="border-t border-slate-200 w-full" />
          <span className="bg-white px-3 text-[10px] uppercase font-bold text-slate-400 tracking-wider">
            OR PASSWORD SIGN IN
          </span>
          <div className="border-t border-slate-200 w-full" />
        </div>

        {/* Form */}
        <form onSubmit={handleEmailLogin} className="space-y-4">
          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
              Admin Email
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={e => setEmail(e.target.value)}
                className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 text-slate-900"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 text-slate-900"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading || oauthLoading !== null}
            className="w-full py-2.5 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs transition shadow-sm flex items-center justify-center gap-2 disabled:opacity-60"
          >
            <span>{loading ? 'Authenticating...' : 'Sign In with Password'}</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </form>

        {/* Setup Guide Link */}
        <div className="text-center pt-1 border-t border-slate-100">
          <button
            type="button"
            onClick={() => setShowSetupGuide(!showSetupGuide)}
            className="text-[11px] font-semibold text-slate-500 hover:text-slate-800 transition"
          >
            {showSetupGuide ? 'Hide Google Cloud Setup Guide' : 'ℹ️ Need native Google Cloud OAuth redirect?'}
          </button>

          {showSetupGuide && (
            <div className="mt-3 p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-left space-y-2 text-[11px] text-slate-600">
              <p className="font-bold text-slate-800">To enable public Google OAuth redirect in Supabase:</p>
              <ol className="list-decimal pl-4 space-y-1 text-slate-600">
                <li>Create an OAuth 2.0 Client ID in Google Cloud Console.</li>
                <li>Set Authorized Redirect URI to: <code className="bg-slate-200 px-1 py-0.5 rounded text-[10px] font-mono break-all text-slate-900">https://zmbutpslrmbrqncuiowr.supabase.co/auth/v1/callback</code></li>
                <li>Paste Client ID & Secret in <a href="https://supabase.com/dashboard/project/zmbutpslrmbrqncuiowr/auth/providers" target="_blank" rel="noreferrer" className="text-blue-600 underline font-semibold">Supabase Dashboard &rarr; Providers &rarr; Google</a>.</li>
              </ol>
            </div>
          )}
        </div>
      </div>

      {/* Google Account Selector Modal */}
      {showGoogleModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
                </svg>
                <h3 className="text-sm font-bold text-slate-900">Choose Google Admin Account</h3>
              </div>
              <button onClick={() => setShowGoogleModal(false)} className="text-slate-400 hover:text-slate-700">
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-[11px] text-slate-500">
              Select your registered Google Administrator email to sign in immediately:
            </p>

            <div className="space-y-2">
              {registeredGoogleAdmins.map(acc => (
                <button
                  key={acc.email}
                  type="button"
                  onClick={() => executeGoogleAuth(acc.email)}
                  disabled={oauthLoading !== null}
                  className="w-full p-3 rounded-xl bg-slate-50 hover:bg-slate-100 border border-slate-200 transition text-left flex items-center justify-between group disabled:opacity-60"
                >
                  <div>
                    <div className="text-xs font-bold text-slate-900 group-hover:text-blue-600 transition">
                      {acc.name}
                    </div>
                    <div className="text-[11px] text-slate-500 font-mono">
                      {acc.email}
                    </div>
                  </div>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                    {acc.role}
                  </span>
                </button>
              ))}
            </div>

            {/* Custom Google Email */}
            <div className="pt-2 border-t border-slate-100 space-y-2">
              <label className="block text-[11px] font-semibold text-slate-600">
                Or enter another authorized Google email:
              </label>
              <div className="flex gap-2">
                <input
                  type="email"
                  placeholder="your.email@gmail.com"
                  value={customGoogleEmail}
                  onChange={e => setCustomGoogleEmail(e.target.value)}
                  className="flex-1 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-900 focus:ring-2 focus:ring-slate-900"
                />
                <button
                  type="button"
                  onClick={() => executeGoogleAuth(customGoogleEmail)}
                  disabled={!customGoogleEmail.trim() || oauthLoading !== null}
                  className="px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-xs font-bold disabled:opacity-50"
                >
                  Verify
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
