'use client';

import React from 'react';
import Link from 'next/link';
import { Menu, Plus, RefreshCw, CheckCircle2 } from 'lucide-react';

interface HeaderProps {
  onToggleSidebar: () => void;
  title?: string;
}

export default function Header({ onToggleSidebar, title = "Admin Console" }: HeaderProps) {
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
        <div className="flex items-center gap-2.5 pl-3 border-l border-slate-200">
          <div className="w-7 h-7 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-800 font-bold text-xs">
            A
          </div>
          <div className="hidden sm:block text-left leading-tight">
            <div className="text-xs font-bold text-slate-900">Admin Control</div>
            <div className="text-[10px] text-slate-400">Master Console</div>
          </div>
        </div>
      </div>
    </header>
  );
}
