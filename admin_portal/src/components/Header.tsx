'use client';

import React from 'react';
import { Menu, Bell, Search, Database, AlertCircle } from 'lucide-react';
import { isLiveFirebase, activeProjectId } from '@/lib/firebase';

interface HeaderProps {
  onToggleSidebar: () => void;
  title?: string;
}

export default function Header({ onToggleSidebar, title = "Admin Portal" }: HeaderProps) {
  return (
    <header className="h-20 bg-white border-b border-slate-200 px-6 lg:px-8 flex items-center justify-between sticky top-0 z-30">
      {/* Left section: Hamburger button & Title */}
      <div className="flex items-center gap-4">
        <button
          onClick={onToggleSidebar}
          className="p-2 -ml-2 rounded-lg hover:bg-slate-100 lg:hidden text-slate-600"
          aria-label="Toggle Navigation"
        >
          <Menu className="w-6 h-6" />
        </button>
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-slate-800 tracking-tight">{title}</h1>
            {isLiveFirebase ? (
              <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                Firestore: {activeProjectId}
              </span>
            ) : (
              <span 
                className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-amber-50 text-amber-800 border border-amber-200 cursor-help"
                title="Running in local fallback mode. Add your Firebase keys to .env.local to sync directly to Firebase Console."
              >
                <AlertCircle className="w-3 h-3 text-amber-600" />
                Local Demo Mode (No .env.local)
              </span>
            )}
          </div>
          <p className="text-xs text-slate-500 hidden sm:block">Real-time dine-in reservations and merchant settlements</p>
        </div>
      </div>

      {/* Right section: Search bar & Admin badge */}
      <div className="flex items-center gap-3 sm:gap-5">
        <div className="relative hidden md:block">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search restaurants, bookings..."
            className="pl-9 pr-4 py-2 bg-slate-100 text-sm rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:bg-white w-64 text-slate-800 transition"
          />
        </div>

        {/* Live Notification Indicator */}
        <div className="relative p-2 rounded-lg hover:bg-slate-100 text-slate-600 cursor-pointer">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-orange-600 rounded-full ring-2 ring-white"></span>
        </div>

        {/* Admin profile */}
        <div className="flex items-center gap-3 pl-3 border-l border-slate-200">
          <div className="w-9 h-9 rounded-full bg-orange-100 border border-orange-200 flex items-center justify-center text-orange-700 font-semibold text-sm">
            AD
          </div>
          <div className="hidden sm:block text-left">
            <div className="text-xs font-semibold text-slate-800">Operations Admin</div>
            <div className="text-[10px] text-slate-500">ops@booknbite.com</div>
          </div>
        </div>
      </div>
    </header>
  );
}
