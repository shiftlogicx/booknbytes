'use client';

import React, { useEffect, useState } from 'react';
import { 
  Clock, 
  Plus, 
  Trash2, 
  Percent, 
  Users, 
  RefreshCw, 
  Store,
  Calendar,
  CheckCircle2
} from 'lucide-react';
import { getAllSlots, getRestaurants, createSlot, deleteSlot, updateSlot } from '@/lib/data-service';
import { DailySlot, Restaurant } from '@/types';

export default function SlotsPage() {
  const [slots, setSlots] = useState<DailySlot[]>([]);
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [selectedRestFilter, setSelectedRestFilter] = useState<string>('ALL');
  const [loading, setLoading] = useState(true);

  // New Slot State
  const [showAddModal, setShowAddModal] = useState(false);
  const [targetRestId, setTargetRestId] = useState('');
  const [slotDate, setSlotDate] = useState('');
  const [startTime, setStartTime] = useState('19:00');
  const [endTime, setEndTime] = useState('20:30');
  const [discount, setDiscount] = useState('15');
  const [capacity, setCapacity] = useState('12');
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    setLoading(true);
    setSlotDate(new Date().toISOString().split('T')[0]);
    try {
      const [sData, rData] = await Promise.all([
        getAllSlots(),
        getRestaurants()
      ]);
      setSlots(sData);
      setRestaurants(rData);
      if (rData.length > 0 && !targetRestId) {
        setTargetRestId(rData[0].restaurant_id);
      }
    } catch (err) {
      console.error('Error fetching slots:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDelete = async (slotId: string) => {
    if (confirm('Delete this slot?')) {
      try {
        await deleteSlot(slotId);
        setSlots(prev => prev.filter(s => s.slot_id !== slotId));
      } catch (err) {
        alert('Failed to delete slot: ' + err);
      }
    }
  };

  const handleUpdateDiscount = async (slot: DailySlot, newDiscount: number) => {
    try {
      await updateSlot(slot.slot_id, { discount_percentage: newDiscount });
      setSlots(prev => prev.map(s => s.slot_id === slot.slot_id ? { ...s, discount_percentage: newDiscount } : s));
    } catch (err) {
      alert('Failed to update discount: ' + err);
    }
  };

  const handleCreateSlot = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetRestId) return;

    setSubmitting(true);
    try {
      const startDt = `${slotDate}T${startTime}:00+00:00`;
      const endDt = `${slotDate}T${endTime}:00+00:00`;

      const created = await createSlot({
        restaurant_id: targetRestId,
        start_datetime: startDt,
        end_datetime: endDt,
        discount_percentage: parseFloat(discount) || 0,
        capacity: parseInt(capacity, 10) || 10,
      });

      const rest = restaurants.find(r => r.restaurant_id === targetRestId);
      setSlots(prev => [...prev, { ...created, restaurant_name: rest?.name || targetRestId }]);
      setShowAddModal(false);
    } catch (err: any) {
      alert('Failed to create slot: ' + (err.message || err));
    } finally {
      setSubmitting(false);
    }
  };

  const filtered = selectedRestFilter === 'ALL'
    ? slots
    : slots.filter(s => s.restaurant_id === selectedRestFilter);

  const formatSlotTime = (isoString?: string) => {
    if (!isoString) return 'N/A';
    try {
      const d = new Date(isoString);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch {
      return isoString;
    }
  };

  const formatSlotDate = (isoString?: string) => {
    if (!isoString) return 'N/A';
    try {
      return isoString.split('T')[0];
    } catch {
      return isoString;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Daily Slots & Floor Capacity</h1>
          <p className="text-xs text-slate-500">Configure bookable table slots, hourly discounts, and covers for each outlet</p>
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
            Add Custom Slot
          </button>
        </div>
      </div>

      {/* Filter by Restaurant */}
      <div className="bg-white p-3.5 rounded-xl border border-slate-200/80 shadow-sm flex items-center gap-3">
        <Store className="w-4 h-4 text-slate-400" />
        <span className="text-xs font-bold text-slate-700">Filter by Outlet:</span>
        <select
          value={selectedRestFilter}
          onChange={e => setSelectedRestFilter(e.target.value)}
          className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-semibold text-slate-900 focus:outline-none"
        >
          <option value="ALL">All Restaurants ({restaurants.length})</option>
          {restaurants.map(r => (
            <option key={r.restaurant_id} value={r.restaurant_id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>

      {/* Slots Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
              <tr>
                <th className="py-3 px-4">Restaurant</th>
                <th className="py-3 px-4">Date</th>
                <th className="py-3 px-4">Time Window</th>
                <th className="py-3 px-4">Discount %</th>
                <th className="py-3 px-4">Table Capacity</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    {loading ? 'Loading slots...' : 'No table slots configured for this restaurant.'}
                  </td>
                </tr>
              ) : (
                filtered.map((s) => (
                  <tr key={s.slot_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {s.restaurant_name}
                    </td>
                    <td className="py-3 px-4 text-slate-600 font-mono">
                      {formatSlotDate(s.start_datetime)}
                    </td>
                    <td className="py-3 px-4 text-slate-800 font-semibold">
                      {formatSlotTime(s.start_datetime)} – {formatSlotTime(s.end_datetime)}
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                        <Percent className="w-3 h-3 text-amber-600" />
                        {s.discount_percentage}% OFF
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-800 font-bold">
                      {s.capacity} covers
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => handleDelete(s.slot_id)}
                        className="p-1.5 text-slate-400 hover:text-red-600 rounded"
                        title="Delete Slot"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Slot Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-slate-200">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-sm text-slate-900">Add Table Slot</h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateSlot} className="space-y-3 text-xs">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Outlet</label>
                <select
                  value={targetRestId}
                  onChange={e => setTargetRestId(e.target.value)}
                  className="w-full px-2.5 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                >
                  {restaurants.map(r => (
                    <option key={r.restaurant_id} value={r.restaurant_id}>
                      {r.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Date</label>
                <input
                  type="date"
                  required
                  value={slotDate}
                  onChange={e => setSlotDate(e.target.value)}
                  className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Start Time (HH:mm)</label>
                  <input
                    type="text"
                    required
                    value={startTime}
                    onChange={e => setStartTime(e.target.value)}
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">End Time (HH:mm)</label>
                  <input
                    type="text"
                    required
                    value={endTime}
                    onChange={e => setEndTime(e.target.value)}
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Discount %</label>
                  <input
                    type="number"
                    min="0"
                    max="70"
                    required
                    value={discount}
                    onChange={e => setDiscount(e.target.value)}
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Table Capacity</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={capacity}
                    onChange={e => setCapacity(e.target.value)}
                    className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
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
                  disabled={submitting}
                  className="px-4 py-1.5 rounded-lg bg-slate-900 text-white font-bold disabled:opacity-50"
                >
                  {submitting ? 'Publishing...' : 'Add Slot'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
