'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  UtensilsCrossed, 
  CalendarCheck, 
  Users, 
  TrendingUp, 
  PlusCircle, 
  ArrowUpRight, 
  Clock, 
  CheckCircle2, 
  AlertCircle,
  ExternalLink,
  Sparkles
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid 
} from 'recharts';
import { 
  getDashboardStats, 
  getBookings, 
  getRestaurants, 
  updateBookingStatus 
} from '@/lib/data-service';
import { Booking, Restaurant, DashboardStats } from '@/types';

const chartData = [
  { day: 'Mon', bookings: 24, covers: 82 },
  { day: 'Tue', bookings: 32, covers: 110 },
  { day: 'Wed', bookings: 45, covers: 148 },
  { day: 'Thu', bookings: 38, covers: 124 },
  { day: 'Fri', bookings: 68, covers: 230 },
  { day: 'Sat', bookings: 94, covers: 340 },
  { day: 'Sun', bookings: 86, covers: 295 },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    totalRestaurants: 0,
    activeRestaurants: 0,
    totalBookings: 0,
    confirmedBookings: 0,
    totalUsers: 0,
    todayBookings: 0,
  });
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);
  const [topRestaurants, setTopRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [dStats, bookings, restaurants] = await Promise.all([
          getDashboardStats(),
          getBookings(),
          getRestaurants()
        ]);
        setStats(dStats);
        setRecentBookings(bookings.slice(0, 5));
        setTopRestaurants(restaurants.slice(0, 3));
      } catch (err) {
        console.error("Dashboard data load error:", err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  const handleStatusChange = async (bookingId: string, newStatus: Booking['status']) => {
    await updateBookingStatus(bookingId, newStatus);
    setRecentBookings(prev => 
      prev.map(b => b.booking_id === bookingId ? { ...b, status: newStatus } : b)
    );
  };

  return (
    <div className="space-y-8">
      {/* Top Banner / Quick Actions */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-orange-950 rounded-2xl p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-orange-500/20 via-transparent to-transparent pointer-events-none" />
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/20 text-orange-400 text-xs font-medium border border-orange-500/30">
              <Sparkles className="w-3.5 h-3.5" /> Book & Bite MVP 2.0 Operational
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
              Restaurant Reservation Command Center
            </h2>
            <p className="text-slate-300 text-sm max-w-xl leading-relaxed">
              Zero platform fees. MyGate-style instant ringing alerts on restaurant devices. Direct-to-merchant UPI settlements.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <Link
              href="/restaurants/new"
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-500 text-white font-medium text-sm transition shadow-lg shadow-orange-600/30"
            >
              <PlusCircle className="w-4 h-4" />
              Onboard Restaurant
            </Link>
            <Link
              href="/bookings"
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-200 font-medium text-sm border border-slate-700 transition"
            >
              <CalendarCheck className="w-4 h-4" />
              Manage Bookings
            </Link>
          </div>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Total Restaurants</span>
            <div className="p-2.5 rounded-xl bg-orange-50 text-orange-600">
              <UtensilsCrossed className="w-5 h-5" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-800">{stats.totalRestaurants}</div>
          <div className="mt-2 flex items-center text-xs text-emerald-600 font-medium">
            <span className="bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100 mr-1.5">
              {stats.activeRestaurants} Live
            </span>
            Ready for instant table bookings
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Total Bookings</span>
            <div className="p-2.5 rounded-xl bg-blue-50 text-blue-600">
              <CalendarCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-800">{stats.totalBookings}</div>
          <div className="mt-2 flex items-center text-xs text-emerald-600 font-medium">
            <TrendingUp className="w-3.5 h-3.5 mr-1" />
            <span>{stats.confirmedBookings} Confirmed</span>
            <span className="text-slate-400 ml-1.5">across all slots</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Today's Reservations</span>
            <div className="p-2.5 rounded-xl bg-amber-50 text-amber-600">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-800">{stats.todayBookings}</div>
          <div className="mt-2 text-xs text-slate-500">
            Real-time Firestore stream active
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Registered Diners</span>
            <div className="p-2.5 rounded-xl bg-purple-50 text-purple-600">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-800">{stats.totalUsers}</div>
          <div className="mt-2 text-xs text-slate-500">
            Authenticated via Google & OTP
          </div>
        </div>
      </div>

      {/* Two Column Layout: Reservation Chart + Top Restaurants */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Weekly Trend Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-bold text-slate-800">Reservation Volume Trends</h3>
              <p className="text-xs text-slate-500">Weekly dine-in covers and table reservations</p>
            </div>
            <div className="flex items-center gap-4 text-xs">
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded bg-orange-500"></span>
                <span className="text-slate-600 font-medium">Bookings</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded bg-amber-300"></span>
                <span className="text-slate-600 font-medium">Covers</span>
              </div>
            </div>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="day" stroke="#94a3b8" fontSize={12} tickLine={false} />
                <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '12px', color: '#fff', fontSize: '12px' }}
                />
                <Bar dataKey="bookings" fill="#ea580c" radius={[6, 6, 0, 0]} />
                <Bar dataKey="covers" fill="#fcd34d" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Featured Restaurants List */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-bold text-slate-800">Featured Merchants</h3>
              <Link href="/restaurants" className="text-xs font-semibold text-orange-600 hover:text-orange-700 flex items-center gap-1">
                View All <ArrowUpRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            <div className="space-y-4">
              {topRestaurants.map((restaurant) => (
                <div key={restaurant.restaurant_id} className="p-3.5 rounded-xl border border-slate-100 hover:border-slate-200 bg-slate-50/50 flex items-center gap-3 transition">
                  <img
                    src={restaurant.visuals.hero_image}
                    alt={restaurant.name}
                    className="w-12 h-12 rounded-lg object-cover bg-slate-200"
                  />
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-semibold text-slate-800 truncate">{restaurant.name}</h4>
                    <p className="text-xs text-slate-500 truncate">{restaurant.cuisines.join(', ')}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[11px] font-bold text-amber-600 bg-amber-50 px-1.5 py-0.2 rounded border border-amber-200">
                        ★ {restaurant.rating.average}
                      </span>
                      <span className="text-[11px] text-slate-400">UPI: {restaurant.upi_id}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100">
            <Link
              href="/restaurants/new"
              className="w-full py-2.5 px-4 rounded-xl border border-dashed border-orange-300 text-orange-600 hover:bg-orange-50 font-medium text-xs flex items-center justify-center gap-2 transition"
            >
              <PlusCircle className="w-4 h-4" /> Add Partner Restaurant
            </Link>
          </div>
        </div>
      </div>

      {/* Recent Bookings Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-base font-bold text-slate-800">Recent Table Reservations</h3>
            <p className="text-xs text-slate-500">Live feed of reservations dispatched to hotel devices</p>
          </div>
          <Link
            href="/bookings"
            className="text-xs font-semibold text-orange-600 hover:text-orange-700 flex items-center gap-1 self-start sm:self-auto"
          >
            All Bookings <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-400 text-[11px] uppercase tracking-wider font-semibold border-b border-slate-200">
              <tr>
                <th className="px-6 py-3.5">Booking ID</th>
                <th className="px-6 py-3.5">Restaurant</th>
                <th className="px-6 py-3.5">Diner</th>
                <th className="px-6 py-3.5">Date & Slot</th>
                <th className="px-6 py-3.5">Guests</th>
                <th className="px-6 py-3.5">Status</th>
                <th className="px-6 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {recentBookings.map((b) => (
                <tr key={b.booking_id} className="hover:bg-slate-50/70 transition">
                  <td className="px-6 py-4 font-mono text-xs font-semibold text-slate-800">
                    {b.booking_id}
                  </td>
                  <td className="px-6 py-4 font-medium text-slate-900">
                    {b.restaurant_name}
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-800">{b.user_name || 'Guest User'}</div>
                    <div className="text-xs text-slate-400">{b.user_phone || '+91 98765 43210'}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-xs font-medium text-slate-800">{b.date}</div>
                    <div className="text-xs text-slate-500">{b.time_slot}</div>
                  </td>
                  <td className="px-6 py-4 font-semibold text-slate-800">
                    {b.party_size} {b.party_size === 1 ? 'Guest' : 'Guests'}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${
                      b.status === 'CONFIRMED' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                      b.status === 'PENDING' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                      b.status === 'COMPLETED' ? 'bg-blue-50 text-blue-700 border border-blue-200' :
                      'bg-rose-50 text-rose-700 border border-rose-200'
                    }`}>
                      {b.status === 'CONFIRMED' && <CheckCircle2 className="w-3 h-3" />}
                      {b.status === 'PENDING' && <Clock className="w-3 h-3" />}
                      {b.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      {b.status === 'PENDING' && (
                        <button
                          onClick={() => handleStatusChange(b.booking_id, 'CONFIRMED')}
                          className="px-2.5 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-medium transition"
                        >
                          Confirm
                        </button>
                      )}
                      {b.status === 'CONFIRMED' && (
                        <button
                          onClick={() => handleStatusChange(b.booking_id, 'COMPLETED')}
                          className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-medium transition"
                        >
                          Complete
                        </button>
                      )}
                      {b.status !== 'CANCELLED' && b.status !== 'COMPLETED' && (
                        <button
                          onClick={() => handleStatusChange(b.booking_id, 'CANCELLED')}
                          className="px-2.5 py-1 rounded-lg hover:bg-rose-50 text-rose-600 text-xs font-medium transition"
                        >
                          Cancel
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
