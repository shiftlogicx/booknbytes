'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  LayoutDashboard, 
  UtensilsCrossed, 
  CalendarCheck, 
  Users, 
  PlusCircle,
  Clock,
  Star,
  ShieldCheck,
  X,
  ExternalLink
} from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

const navItems = [
  { href: '/', label: 'Overview', icon: LayoutDashboard },
  { href: '/restaurants', label: 'Restaurants', icon: UtensilsCrossed },
  { href: '/restaurants/new', label: 'Onboard Restaurant', icon: PlusCircle, highlight: true },
  { href: '/bookings', label: 'Reservations', icon: CalendarCheck },
  { href: '/slots', label: 'Daily Slots', icon: Clock },
  { href: '/reviews', label: 'Guest Reviews', icon: Star },
  { href: '/users', label: 'Users & Diners', icon: Users },
];

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div 
          onClick={onClose}
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* Sidebar Container */}
      <aside className={`
        fixed top-0 bottom-0 left-0 z-50 w-72 bg-[#0A0D14] text-white flex flex-col border-r border-[#1E2638]
        transition-transform duration-300 ease-in-out font-sans
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        {/* Brand Header */}
        <div className="h-20 flex items-center justify-between px-6 border-b border-[#1E2638]">
          <Link href="/" className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-500 to-teal-400 flex items-center justify-center font-extrabold text-slate-950 shadow-md shadow-emerald-500/20 text-lg">
              B
            </div>
            <div>
              <div className="font-bold text-[15px] tracking-tight flex items-center gap-1.5 text-white">
                BookNBytes
                <span className="text-[9px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  Console
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-medium">Merchant & Reservation Ops</p>
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
        <nav className="flex-1 py-5 px-3.5 space-y-1 overflow-y-auto">
          <div className="px-3 pb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
            Platform Operations
          </div>

          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={`
                  flex items-center justify-between px-3 py-2.5 rounded-lg text-xs font-semibold transition-all
                  ${isActive 
                    ? 'bg-slate-900 text-white border border-slate-700/80 shadow-sm' 
                    : item.highlight
                      ? 'text-emerald-400 hover:bg-emerald-500/10 hover:text-emerald-300'
                      : 'text-slate-400 hover:bg-slate-900/60 hover:text-slate-200'}
                `}
              >
                <div className="flex items-center gap-2.5">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-emerald-400' : item.highlight ? 'text-emerald-400' : 'text-slate-500'}`} />
                  <span>{item.label}</span>
                </div>
                {item.highlight && !isActive && (
                  <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400">
                    NEW
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Database Status Footer */}
        <div className="p-4 border-t border-[#1E2638] bg-[#070A10]">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-[11px] font-semibold text-slate-300">Supabase Connected</span>
            </div>
            <span className="text-[10px] text-slate-400 font-mono">zmbutpsl...</span>
          </div>
          <div className="mt-2 text-[10px] text-slate-400 flex items-center justify-between">
            <span>Edge Functions Active</span>
            <span className="text-emerald-400">Live</span>
          </div>
        </div>
      </aside>
    </>
  );
}
