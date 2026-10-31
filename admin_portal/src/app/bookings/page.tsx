'use client';

import React, { useEffect, useState } from 'react';
import { 
  CalendarCheck, 
  Search, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Trash2, 
  Plus, 
  RefreshCw,
  User,
  Users
} from 'lucide-react';
import { getBookings, updateBookingStatus, deleteBooking, createBooking, getRestaurants } from '@/lib/data-service';
import { Booking, BookingStatus, Restaurant } from '@/types';

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // New Booking Modal State
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedRestId, setSelectedRestId] = useState('');
  const [partySize, setPartySize] = useState('2');
  const [bookingDate, setBookingDate] = useState('');
  const [timeSlot, setTimeSlot] = useState('19:30');
  const [creating, setCreating] = useState(false);

  const loadData = async () => {
    setLoading(true);
    setBookingDate(new Date().toISOString().split('T')[0]);
    try {
      const [bookingsData, restsData] = await Promise.all([
        getBookings(),
        getRestaurants()
      ]);
      setBookings(bookingsData);
      setRestaurants(restsData);
      if (restsData.length > 0 && !selectedRestId) {
        setSelectedRestId(restsData[0].restaurant_id);
      }
    } catch (err) {
      console.error('Error loading bookings:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleStatusChange = async (id: string, newStatus: BookingStatus) => {
    try {
      await updateBookingStatus(id, newStatus);
      setBookings(prev => 
        prev.map(b => b.booking_id === id ? { ...b, status: newStatus } : b)
      );
    } catch (err) {
      alert('Failed to update status: ' + err);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm(`Delete reservation #${id}?`)) {
      try {
        await deleteBooking(id);
        setBookings(prev => prev.filter(b => b.booking_id !== id));
      } catch (err) {
        alert('Failed to delete booking: ' + err);
      }
    }
  };

  const handleCreateBooking = async (e: React.FormEvent) => {
    e.preventDefault();
    const rest = restaurants.find(r => r.restaurant_id === selectedRestId);
    if (!rest) return;

    setCreating(true);
    try {
      const newB = await createBooking({
        restaurant_id: rest.restaurant_id,
        restaurant_name: rest.name,
        party_size: parseInt(partySize, 10) || 2,
        booking_date: bookingDate,
        time_slot: timeSlot,
        status: 'CONFIRMED',
      });
      setBookings(prev => [newB, ...prev]);
      setShowAddModal(false);
    } catch (err: any) {
      alert('Failed to create booking: ' + (err.message || err));
    } finally {
      setCreating(false);
    }
  };

  const filtered = bookings.filter(b => {
    const query = search.toLowerCase();
    const matchesSearch = 
      b.booking_id.toLowerCase().includes(query) ||
      b.restaurant_name.toLowerCase().includes(query) ||
      (b.users?.name && b.users.name.toLowerCase().includes(query)) ||
      (b.users?.phone_number && b.users.phone_number.includes(query));

    if (filterStatus === 'ALL') return matchesSearch;
    return matchesSearch && b.status === filterStatus;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Table Reservations</h1>
          <p className="text-xs text-slate-500">Real-time floor bookings across all onboarded restaurants</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={loadData}
            className="p-2 rounded-lg border border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition"
          >
            <Plus className="w-3.5 h-3.5" />
            Create Reservation
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-3.5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search booking ref, restaurant or guest..."
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 focus:bg-white text-slate-900"
          />
        </div>

        <div className="flex items-center gap-1.5 overflow-x-auto w-full md:w-auto pb-1 md:pb-0">
          {['ALL', 'PENDING', 'CONFIRMED', 'COMPLETED', 'NO_SHOW', 'CANCELLED'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterStatus(st)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition ${
                filterStatus === st 
                  ? 'bg-slate-900 text-white' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
              <tr>
                <th className="py-3 px-4">Booking Ref</th>
                <th className="py-3 px-4">Restaurant</th>
                <th className="py-3 px-4">Guest Diner</th>
                <th className="py-3 px-4">Schedule</th>
                <th className="py-3 px-4">Covers</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    {loading ? 'Fetching bookings from Supabase...' : 'No reservations found.'}
                  </td>
                </tr>
              ) : (
                filtered.map((b) => (
                  <tr key={b.booking_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4 font-mono font-bold text-slate-900">
                      #{b.booking_id}
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {b.restaurant_name}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div className="font-semibold text-slate-800">{b.users?.name || 'Guest Diner'}</div>
                      <div className="text-[10px] text-slate-400">{b.users?.phone_number || b.users?.email || 'N/A'}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div className="font-semibold">{b.booking_date}</div>
                      <div className="text-[10px] text-slate-400">{b.time_slot}</div>
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {b.party_size} covers
                    </td>
                    <td className="py-3 px-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        b.status === 'CONFIRMED'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : b.status === 'PENDING'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : b.status === 'COMPLETED'
                              ? 'bg-blue-50 text-blue-700 border border-blue-200'
                              : b.status === 'NO_SHOW'
                                ? 'bg-red-50 text-red-700 border border-red-200'
                                : 'bg-slate-100 text-slate-600'
                      }`}>
                        {b.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="inline-flex items-center gap-1.5 justify-end">
                        {b.status === 'PENDING' && (
                          <>
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
                              Reject
                            </button>
                          </>
                        )}
                        {b.status === 'CONFIRMED' && (
                          <>
                            <button
                              onClick={() => handleStatusChange(b.booking_id, 'COMPLETED')}
                              className="px-2 py-1 rounded bg-slate-900 hover:bg-slate-800 text-white text-[10px] font-bold"
                            >
                              Seat
                            </button>
                            <button
                              onClick={() => handleStatusChange(b.booking_id, 'NO_SHOW')}
                              className="px-2 py-1 rounded bg-red-100 hover:bg-red-200 text-red-700 text-[10px] font-bold"
                            >
                              No-Show
                            </button>
                          </>
                        )}
                        <button
                          onClick={() => handleDelete(b.booking_id)}
                          className="p-1 text-slate-400 hover:text-red-600 rounded"
                          title="Delete"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Manual Booking Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-slate-200">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-sm text-slate-900">Create Table Reservation</h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateBooking} className="space-y-3.5 text-xs">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Select Restaurant</label>
                <select
                  value={selectedRestId}
                  onChange={e => setSelectedRestId(e.target.value)}
                  className="w-full px-2.5 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                >
                  {restaurants.map(r => (
                    <option key={r.restaurant_id} value={r.restaurant_id}>
                      {r.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Date</label>
                  <input
                    type="date"
                    required
                    value={bookingDate}
                    onChange={e => setBookingDate(e.target.value)}
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Time Slot</label>
                  <input
                    type="text"
                    required
                    value={timeSlot}
                    onChange={e => setTimeSlot(e.target.value)}
                    placeholder="19:30"
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Covers / Party Size</label>
                <input
                  type="number"
                  min="1"
                  max="20"
                  required
                  value={partySize}
                  onChange={e => setPartySize(e.target.value)}
                  className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-600 font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={creating}
                  className="px-4 py-1.5 rounded-lg bg-slate-900 text-white font-bold disabled:opacity-50"
                >
                  {creating ? 'Saving...' : 'Confirm Reservation'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
