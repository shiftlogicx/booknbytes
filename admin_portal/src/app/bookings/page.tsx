'use client';

import React, { useEffect, useState } from 'react';
import { 
  CalendarCheck, 
  Search, 
  Filter, 
  CheckCircle2, 
  Clock, 
  XCircle, 
  AlertCircle,
  Phone,
  User,
  Users
} from 'lucide-react';
import { getBookings, updateBookingStatus } from '@/lib/data-service';
import { Booking } from '@/types';

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const data = await getBookings();
      setBookings(data);
      setLoading(false);
    }
    load();
  }, []);

  const handleStatus = async (id: string, newStatus: Booking['status']) => {
    await updateBookingStatus(id, newStatus);
    setBookings(prev => 
      prev.map(b => b.booking_id === id ? { ...b, status: newStatus } : b)
    );
  };

  const filtered = bookings.filter(b => {
    const matchesSearch = 
      b.booking_id.toLowerCase().includes(search.toLowerCase()) ||
      b.restaurant_name.toLowerCase().includes(search.toLowerCase()) ||
      (b.user_name && b.user_name.toLowerCase().includes(search.toLowerCase()));

    if (filterStatus === 'ALL') return matchesSearch;
    return matchesSearch && b.status === filterStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Table Reservations</h2>
          <p className="text-xs text-slate-500">Live booking stream dispatched to hotel MyGate ringing alerts</p>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search booking ID, restaurant or guest..."
            className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0">
          {['ALL', 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
                filterStatus === status 
                  ? 'bg-slate-900 text-white' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {/* Table View */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-400 text-[11px] uppercase tracking-wider font-semibold border-b border-slate-200">
              <tr>
                <th className="px-6 py-4">Booking Ref</th>
                <th className="px-6 py-4">Restaurant</th>
                <th className="px-6 py-4">Guest Details</th>
                <th className="px-6 py-4">Date & Time</th>
                <th className="px-6 py-4">Party Size</th>
                <th className="px-6 py-4">Offer Applied</th>
                <th className="px-6 py-4">Current Status</th>
                <th className="px-6 py-4 text-right">Update Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filtered.map((b) => (
                <tr key={b.booking_id} className="hover:bg-slate-50/70 transition">
                  <td className="px-6 py-4 font-mono text-xs font-bold text-slate-900">
                    {b.booking_id}
                  </td>
                  <td className="px-6 py-4 font-semibold text-slate-900">
                    {b.restaurant_name}
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-800 flex items-center gap-1.5">
                      <User className="w-3.5 h-3.5 text-slate-400" />
                      {b.user_name || 'Rahul Sharma'}
                    </div>
                    <div className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                      <Phone className="w-3 h-3 text-slate-400" />
                      {b.user_phone || '+91 98765 43210'}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-semibold text-slate-800 text-xs">{b.date}</div>
                    <div className="text-xs text-slate-500 font-mono">{b.time_slot}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center gap-1 font-semibold text-slate-800 text-xs bg-slate-100 px-2 py-1 rounded-md">
                      <Users className="w-3 h-3 text-slate-500" />
                      {b.party_size} {b.party_size === 1 ? 'Person' : 'People'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-xs font-mono text-amber-700">
                    {b.applied_offer ? (
                      <span className="bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                        {b.applied_offer}
                      </span>
                    ) : (
                      <span className="text-slate-400">None</span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
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
                    <div className="flex items-center justify-end gap-1.5">
                      {b.status === 'PENDING' && (
                        <button
                          onClick={() => handleStatus(b.booking_id, 'CONFIRMED')}
                          className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded text-xs font-medium transition"
                        >
                          Confirm
                        </button>
                      )}
                      {b.status === 'CONFIRMED' && (
                        <button
                          onClick={() => handleStatus(b.booking_id, 'COMPLETED')}
                          className="px-2.5 py-1 bg-blue-600 hover:bg-blue-500 text-white rounded text-xs font-medium transition"
                        >
                          Complete
                        </button>
                      )}
                      {b.status !== 'CANCELLED' && b.status !== 'COMPLETED' && (
                        <button
                          onClick={() => handleStatus(b.booking_id, 'CANCELLED')}
                          className="px-2.5 py-1 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded text-xs font-medium transition"
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
