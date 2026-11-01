'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Menu, Plus, LogOut, ShieldCheck, User } from 'lucide-react';
import { useAdminAuth } from '@/context/AuthContext';

interface HeaderProps {
  onToggleSidebar: () => void;
  title?: string;
}

export default function Header({ onToggleSidebar, title = "Admin Console" }: HeaderProps) {
  const router = useRouter();
  const { adminUser, signOut } = useAdminAuth();

  const handleLogout = async () => {
    await signOut();
    router.push('/login');
  };

  return (
    <header className="h-16 bg-white border-b border-slate-200/80 px-6 lg:px-8 flex items-center justify-between sticky top-0 z-30">
      {/* Left section */}
      <div className="flex items-center gap-4">
        <button
          onClick={onToggleSidebar}
          className="p-1.5 -ml-1 rounded-md hover:bg-slate-100 lg:hidden text-slate-600"
          aria-label="Toggle Navigation"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-sm font-bold text-slate-900 tracking-tight">{title}</h1>
            <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200/60">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Live DB
            </span>
          </div>
        </div>
      </div>

      {/* Right section */}
      <div className="flex items-center gap-3">
        <Link
          href="/restaurants/new"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-950 text-white hover:bg-slate-800 transition shadow-sm"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>Onboard Restaurant</span>
        </Link>

        {/* Admin profile */}
        <div className="flex items-center gap-3 pl-3 border-l border-slate-200">
          <div className="w-8 h-8 rounded-full bg-slate-900 border border-slate-700 flex items-center justify-center text-emerald-400 font-bold text-xs uppercase shadow-sm">
            {adminUser?.name ? adminUser.name.charAt(0) : 'A'}
          </div>
          <div className="hidden sm:block text-left leading-tight">
            <div className="text-xs font-bold text-slate-900 flex items-center gap-1">
              {adminUser?.name || 'Super Admin'}
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600 inline" />
            </div>
            <div className="text-[10px] text-slate-500 truncate max-w-[150px]">
              {adminUser?.email || 'shiftlogiciq@gmail.com'}
            </div>
          </div>

          <button
            onClick={handleLogout}
            title="Sign Out of Admin Console"
            className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
}
