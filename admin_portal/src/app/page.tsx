'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  UtensilsCrossed, 
  CalendarCheck, 
  Users, 
  Clock, 
  PlusCircle, 
  ArrowUpRight, 
  Star,
  CheckCircle2, 
  XCircle,
  Clock4,
  RefreshCw,
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
import { Booking, Restaurant, DashboardStats, BookingStatus } from '@/types';

const chartData = [
  { day: 'Mon', bookings: 24, covers: 78 },
  { day: 'Tue', bookings: 32, covers: 104 },
  { day: 'Wed', bookings: 45, covers: 142 },
  { day: 'Thu', bookings: 38, covers: 120 },
  { day: 'Fri', bookings: 68, covers: 215 },
  { day: 'Sat', bookings: 94, covers: 310 },
  { day: 'Sun', bookings: 86, covers: 280 },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    totalRestaurants: 0,
    activeRestaurants: 0,
    totalBookings: 0,
    confirmedBookings: 0,
    totalUsers: 0,
    todayBookings: 0,
    totalReviews: 0,
    averageRating: 4.8,
  });
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);
  const [topRestaurants, setTopRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const [dStats, bookings, restaurants] = await Promise.all([
        getDashboardStats(),
        getBookings(),
        getRestaurants()
      ]);
      setStats(dStats);
      setRecentBookings(bookings.slice(0, 6));
      setTopRestaurants(restaurants.slice(0, 4));
    } catch (err) {
      console.error("Dashboard data load error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleStatusChange = async (bookingId: string, newStatus: BookingStatus) => {
    try {
      await updateBookingStatus(bookingId, newStatus);
      setRecentBookings(prev => 
        prev.map(b => b.booking_id === bookingId ? { ...b, status: newStatus } : b)
      );
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  return (
    <div className="space-y-6">
      {/* Sleek Minimal Command Header */}
      <div className="bg-[#0A0D14] rounded-2xl p-6 sm:p-7 text-white border border-[#1E2638] shadow-sm relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-5">
          <div className="space-y-1.5">
            <div className="inline-flex items-center gap-2 px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[11px] font-bold border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              Live Operations & Management
            </div>
            <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-white">
              Restaurant Reservation Command Center
            </h2>
            <p className="text-slate-400 text-xs max-w-xl leading-relaxed">
              Real-time synchronization across Supabase DB, restaurant floor mobile apps, and diner table bookings.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            <Link
              href="/restaurants/new"
              className="inline-flex items-center gap-2 px-3.5 py-2 rounded-lg bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs transition shadow-sm"
            >
              <PlusCircle className="w-3.5 h-3.5" />
              Onboard Restaurant
            </Link>
            <button
              onClick={loadData}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-slate-900 hover:bg-slate-800 text-slate-300 font-semibold text-xs border border-slate-700/80 transition"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
              Sync
            </button>
          </div>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Restaurants */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm hover:border-slate-300 transition">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Restaurants</span>
            <div className="p-2 rounded-lg bg-slate-100 text-slate-700">
              <UtensilsCrossed className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 tracking-tight">{stats.totalRestaurants}</div>
          <div className="mt-2 flex items-center gap-1.5 text-xs text-emerald-600 font-semibold">
            <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500" />
            <span>{stats.activeRestaurants} Live Outlets</span>
          </div>
        </div>

        {/* Total Bookings */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm hover:border-slate-300 transition">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Total Reservations</span>
            <div className="p-2 rounded-lg bg-slate-100 text-slate-700">
              <CalendarCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 tracking-tight">{stats.totalBookings}</div>
          <div className="mt-2 flex items-center gap-1.5 text-xs text-slate-600 font-medium">
            <span className="font-bold text-emerald-600">{stats.confirmedBookings} Confirmed</span>
            <span className="text-slate-400">· {stats.todayBookings} Scheduled Today</span>
          </div>
        </div>

        {/* Users */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm hover:border-slate-300 transition">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Registered Users</span>
            <div className="p-2 rounded-lg bg-slate-100 text-slate-700">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 tracking-tight">{stats.totalUsers}</div>
          <div className="mt-2 text-xs text-slate-500 font-medium">
            Owners, managers, and diners
          </div>
        </div>

        {/* Rating & Reviews */}
        <div className="bg-white p-5 rounded-xl border border-slate-200/80 shadow-sm hover:border-slate-300 transition">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Rating & Reviews</span>
            <div className="p-2 rounded-lg bg-amber-50 text-amber-600">
              <Star className="w-4 h-4 fill-amber-500 text-amber-500" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 tracking-tight flex items-baseline gap-2">
            <span>★ {stats.averageRating}</span>
            <span className="text-xs text-slate-400 font-normal">/ 5.0</span>
          </div>
          <div className="mt-2 text-xs text-slate-500 font-medium">
            Across {stats.totalReviews} guest reviews
          </div>
        </div>
      </div>

      {/* Two Column Layout: Reservation Chart + Top Restaurants */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Weekly Trend Chart */}
        <div className="lg:col-span-2 bg-white p-5 sm:p-6 rounded-xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Reservation Volume Trends</h3>
              <p className="text-xs text-slate-500">Weekly dine-in covers and table bookings</p>
            </div>
            <div className="flex items-center gap-3 text-xs">
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-sm bg-slate-900" />
                <span className="text-slate-600 font-medium">Bookings</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-sm bg-emerald-400" />
                <span className="text-slate-600 font-medium">Covers</span>
              </div>
            </div>
          </div>

          <div className="h-60 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="day" stroke="#94a3b8" fontSize={11} tickLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#0A0D14', border: '1px solid #1E2638', borderRadius: '8px', color: '#fff', fontSize: '12px' }}
                />
                <Bar dataKey="bookings" fill="#0A0D14" radius={[4, 4, 0, 0]} />
                <Bar dataKey="covers" fill="#34D399" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Featured Restaurants List */}
        <div className="bg-white p-5 sm:p-6 rounded-xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-slate-900">Active Outlets</h3>
              <Link href="/restaurants" className="text-xs font-bold text-emerald-600 hover:text-emerald-700 flex items-center gap-1">
                View All <ArrowUpRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            <div className="space-y-3">
              {topRestaurants.map((restaurant) => (
                <div key={restaurant.restaurant_id} className="p-3 rounded-lg border border-slate-100 bg-slate-50/60 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-slate-200 overflow-hidden flex-shrink-0">
                    <img
                      src={restaurant.visuals?.hero_image || 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80'}
                      alt={restaurant.name}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="text-xs font-bold text-slate-900 truncate">{restaurant.name}</h4>
                    <p className="text-[11px] text-slate-500 truncate">{restaurant.cuisines?.join(', ') || 'Multi-Cuisine'}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">
                        ★ {restaurant.rating?.average || '4.8'}
                      </span>
                      <span className="text-[10px] text-slate-400 font-mono">₹{restaurant.cost_for_two} for 2</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <Link
            href="/restaurants/new"
            className="mt-4 w-full py-2 px-3 text-center rounded-lg border border-dashed border-slate-300 text-xs font-semibold text-slate-600 hover:text-slate-900 hover:border-slate-400 transition block"
          >
            + Onboard New Partner
          </Link>
        </div>
      </div>

      {/* Recent Reservations Table with Live Actions */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-slate-900">Live Booking Feed</h3>
            <p className="text-xs text-slate-500">Recent reservations streamed from diners</p>
          </div>
          <Link
            href="/bookings"
            className="text-xs font-bold text-slate-700 hover:text-slate-900 flex items-center gap-1"
          >
            Full Queue <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-100 text-slate-500 font-semibold uppercase text-[10px] tracking-wider">
              <tr>
                <th className="py-3 px-4">Booking ID</th>
                <th className="py-3 px-4">Restaurant</th>
                <th className="py-3 px-4">Guest</th>
                <th className="py-3 px-4">Schedule</th>
                <th className="py-3 px-4">Covers</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Quick Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {recentBookings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    No reservations recorded yet.
                  </td>
                </tr>
              ) : (
                recentBookings.map((b) => (
                  <tr key={b.booking_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4 font-mono font-bold text-slate-800">
                      #{b.booking_id}
                    </td>
                    <td className="py-3 px-4 text-slate-900 font-semibold">
                      {b.restaurant_name}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div>{b.users?.name || 'Guest Diner'}</div>
                      <div className="text-[10px] text-slate-400">{b.users?.phone_number || ''}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div>{b.booking_date}</div>
                      <div className="text-[10px] text-slate-400">{b.time_slot}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-800 font-bold">
                      {b.party_size} guests
                    </td>
                    <td className="py-3 px-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        b.status === 'CONFIRMED'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : b.status === 'PENDING'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : b.status === 'COMPLETED'
                              ? 'bg-blue-50 text-blue-700 border border-blue-200'
                              : 'bg-slate-100 text-slate-600'
                      }`}>
                        {b.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      {b.status === 'PENDING' && (
                        <div className="inline-flex gap-1.5 justify-end">
                          <button
                            onClick={() => handleStatusChange(b.booking_id, 'CONFIRMED')}
                            className="px-2 py-1 rounded bg-emerald-600 hover:bg-emerald-500 text-white text-[10px] font-bold"
                          >
                            Confirm
                          </button>
                          <button
                            onClick={() => handleStatusChange(b.booking_id, 'REJECTED')}
                            className="px-2 py-1 rounded bg-slate-200 hover:bg-slate-300 text-slate-700 text-[10px] font-bold"
                          >
                            Decline
                          </button>
                        </div>
                      )}
                      {b.status === 'CONFIRMED' && (
                        <button
                          onClick={() => handleStatusChange(b.booking_id, 'COMPLETED')}
                          className="px-2 py-1 rounded bg-slate-900 hover:bg-slate-800 text-white text-[10px] font-bold"
                        >
                          Mark Seated
                        </button>
                      )}
                      {(b.status === 'COMPLETED' || b.status === 'CANCELLED' || b.status === 'REJECTED') && (
                        <span className="text-[11px] text-slate-400">—</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
