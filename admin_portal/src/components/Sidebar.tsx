'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  UtensilsCrossed, 
  CalendarCheck, 
  Users, 
  Settings, 
  Store,
  ChevronRight,
  ShieldCheck,
  X
} from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

const navItems = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/restaurants', label: 'Restaurants', icon: UtensilsCrossed },
  { href: '/bookings', label: 'Bookings', icon: CalendarCheck },
  { href: '/users', label: 'Diners / Users', icon: Users },
  { href: '/restaurants/new', label: 'Onboard Restaurant', icon: Store },
];

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div 
          onClick={onClose}
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* Sidebar Container */}
      <aside className={`
        fixed top-0 bottom-0 left-0 z-50 w-72 bg-slate-900 text-white flex flex-col border-r border-slate-800
        transition-transform duration-300 ease-in-out
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        {/* Brand Header */}
        <div className="h-20 flex items-center justify-between px-6 border-b border-slate-800">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-orange-600 to-amber-500 flex items-center justify-center font-bold text-white shadow-lg shadow-orange-500/20 text-xl">
              B
            </div>
            <div>
              <div className="font-bold text-lg tracking-tight flex items-center gap-1.5">
                Book & Bite
                <span className="text-[10px] uppercase font-semibold tracking-wider px-1.5 py-0.5 rounded bg-orange-500/20 text-orange-400 border border-orange-500/30">
                  Admin
                </span>
              </div>
              <p className="text-xs text-slate-400">Merchant & Reservation Ops</p>
            </div>
          </Link>

          {/* Close button for mobile */}
          <button 
            onClick={onClose}
            className="p-1 rounded-lg hover:bg-slate-800 lg:hidden text-slate-400 hover:text-white"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation links */}
        <nav className="flex-1 py-6 px-4 space-y-1.5 overflow-y-auto">
          <div className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
            Platform Management
          </div>

          {navItems.map((item) => {
            const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={`
                  flex items-center justify-between px-3.5 py-3 rounded-xl text-sm font-medium transition-all
                  ${isActive 
                    ? 'bg-gradient-to-r from-orange-600 to-amber-600 text-white shadow-md shadow-orange-600/20' 
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'}
                `}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>
                {isActive && <ChevronRight className="w-4 h-4 text-white/70" />}
              </Link>
            );
          })}
        </nav>

        {/* Footer / System Status */}
        <div className="p-4 border-t border-slate-800">
          <div className="bg-slate-800/60 rounded-xl p-3 border border-slate-700/50">
            <div className="flex items-center gap-2 text-xs font-medium text-emerald-400 mb-1">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              Firebase Serverless Active
            </div>
            <p className="text-[11px] text-slate-400 leading-relaxed">
              FCM Cloud Functions listening for instant table reservations.
            </p>
          </div>
        </div>
      </aside>
    </>
  );
}
