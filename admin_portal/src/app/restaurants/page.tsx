'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  UtensilsCrossed, 
  PlusCircle, 
  Search, 
  Trash2, 
  KeyRound, 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Store,
  RefreshCw,
  ExternalLink,
  ShieldCheck
} from 'lucide-react';
import { getRestaurants, deleteRestaurant, toggleRestaurantStatus } from '@/lib/data-service';
import { Restaurant } from '@/types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [loading, setLoading] = useState(true);
  const [selectedRest, setSelectedRest] = useState<Restaurant | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await getRestaurants();
      setRestaurants(data);
    } catch (err) {
      console.error('Error fetching restaurants:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDelete = async (id: string, name: string) => {
    if (confirm(`Are you sure you want to delete ${name}? This will also delete associated slots and reservations.`)) {
      try {
        await deleteRestaurant(id);
        setRestaurants(prev => prev.filter(r => r.restaurant_id !== id));
      } catch (err) {
        alert('Failed to delete restaurant: ' + err);
      }
    }
  };

  const handleToggleStatus = async (restaurant: Restaurant) => {
    const newStatus = restaurant.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    try {
      await toggleRestaurantStatus(restaurant.restaurant_id, newStatus);
      setRestaurants(prev => prev.map(r => r.restaurant_id === restaurant.restaurant_id ? { ...r, status: newStatus } : r));
    } catch (err) {
      alert('Failed to update status: ' + err);
    }
  };

  const filtered = restaurants.filter(r => {
    const query = searchQuery.toLowerCase();
    const matchesSearch = 
      r.name.toLowerCase().includes(query) ||
      (r.address && r.address.toLowerCase().includes(query)) ||
      (r.cuisines && r.cuisines.some(c => c.toLowerCase().includes(query))) ||
      r.restaurant_id.toLowerCase().includes(query);
    
    if (statusFilter === 'ACTIVE') return matchesSearch && r.status === 'ACTIVE';
    if (statusFilter === 'INACTIVE') return matchesSearch && r.status === 'INACTIVE';
    return matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Onboarded Restaurants</h1>
          <p className="text-xs text-slate-500">Live Supabase merchant directory with instant status toggles and credentials</p>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={loadData}
            className="p-2 rounded-lg border border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <Link
            href="/restaurants/new"
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition"
          >
            <PlusCircle className="w-3.5 h-3.5" />
            Onboard New Partner
          </Link>
        </div>
      </div>

      {/* Filter / Search Bar */}
      <div className="bg-white p-3.5 rounded-xl border border-slate-200/80 shadow-sm flex flex-col md:flex-row items-center justify-between gap-3">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by outlet name, cuisines, or ID..."
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:outline-none focus:ring-2 focus:ring-slate-900 focus:bg-white text-slate-900"
          />
        </div>

        <div className="flex items-center gap-1.5 w-full md:w-auto">
          <button
            onClick={() => setStatusFilter('ALL')}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
              statusFilter === 'ALL' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All ({restaurants.length})
          </button>
          <button
            onClick={() => setStatusFilter('ACTIVE')}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              statusFilter === 'ACTIVE' ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Active ({restaurants.filter(r => r.status === 'ACTIVE').length})
          </button>
          <button
            onClick={() => setStatusFilter('INACTIVE')}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              statusFilter === 'INACTIVE' ? 'bg-slate-700 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Paused ({restaurants.filter(r => r.status === 'INACTIVE').length})
          </button>
        </div>
      </div>

      {/* Directory Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 border-b border-slate-100 text-slate-500 font-semibold uppercase text-[10px] tracking-wider">
              <tr>
                <th className="py-3 px-4">Restaurant</th>
                <th className="py-3 px-4">Address & Cuisines</th>
                <th className="py-3 px-4">Cost for Two</th>
                <th className="py-3 px-4">Rating</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    {loading ? 'Loading restaurants from Supabase...' : 'No restaurants found matching your criteria.'}
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={r.restaurant_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-lg bg-slate-100 overflow-hidden flex-shrink-0">
                          <img
                            src={r.visuals?.hero_image || 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80'}
                            alt={r.name}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div>
                          <div className="font-bold text-slate-900">{r.name}</div>
                          <div className="text-[10px] text-slate-400 font-mono">ID: {r.restaurant_id}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-slate-600 max-w-xs">
                      <div className="truncate">{r.address || 'Address not listed'}</div>
                      <div className="text-[10px] text-slate-400 truncate">{r.cuisines?.join(', ') || 'Multi-Cuisine'}</div>
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      ₹{r.cost_for_two}
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 text-[10px] font-bold border border-amber-200">
                        ★ {r.rating?.average || 4.8} ({r.rating?.total_reviews || 0})
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => handleToggleStatus(r)}
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold transition cursor-pointer ${
                          r.status === 'ACTIVE'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100'
                            : 'bg-slate-100 text-slate-600 border border-slate-200 hover:bg-slate-200'
                        }`}
                        title="Click to toggle status"
                      >
                        <span className={`w-1.5 h-1.5 rounded-full ${r.status === 'ACTIVE' ? 'bg-emerald-500' : 'bg-slate-400'}`} />
                        {r.status === 'ACTIVE' ? 'Live' : 'Paused'}
                      </button>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="inline-flex items-center gap-1.5 justify-end">
                        <button
                          onClick={() => setSelectedRest(r)}
                          className="p-1.5 text-slate-500 hover:text-slate-900 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 transition"
                          title="View Details & Credentials"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => handleDelete(r.restaurant_id, r.name)}
                          className="p-1.5 text-red-500 hover:text-red-700 rounded bg-red-50 hover:bg-red-100 border border-red-200 transition"
                          title="Delete Restaurant"
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

      {/* Details & Credentials Modal */}
      {selectedRest && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 space-y-4 shadow-xl border border-slate-200">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center gap-2">
                <Store className="w-4 h-4 text-emerald-600" />
                <h3 className="font-bold text-sm text-slate-900">{selectedRest.name}</h3>
              </div>
              <button
                onClick={() => setSelectedRest(null)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕ Close
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-2">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Merchant Credentials</span>
                <div>
                  <span className="text-slate-500">Owner Email: </span>
                  <span className="font-mono font-bold text-slate-900">{selectedRest.owners_details?.email || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-slate-500">Floor Manager Email: </span>
                  <span className="font-mono font-bold text-slate-900">
                    {selectedRest.owners_details?.manager_credentials?.email || `manager.${selectedRest.restaurant_id}@booknbytes.app`}
                  </span>
                </div>
                <div>
                  <span className="text-slate-500">Manager Password: </span>
                  <span className="font-mono font-bold text-emerald-700">
                    {selectedRest.owners_details?.manager_credentials?.default_password || 'AmitYashLogic@1999'}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-slate-600">
                <div className="p-2.5 rounded-lg border border-slate-100 bg-slate-50">
                  <span className="text-[10px] text-slate-400 font-bold block uppercase">UPI ID</span>
                  <span className="font-mono text-slate-800">{selectedRest.upi_id || 'N/A'}</span>
                </div>
                <div className="p-2.5 rounded-lg border border-slate-100 bg-slate-50">
                  <span className="text-[10px] text-slate-400 font-bold block uppercase">FSSAI Number</span>
                  <span className="font-mono text-slate-800">{selectedRest.fssai_number}</span>
                </div>
              </div>

              <div className="p-2.5 rounded-lg border border-slate-100 bg-slate-50 text-slate-600">
                <span className="text-[10px] text-slate-400 font-bold block uppercase">Street Address</span>
                <span>{selectedRest.address}</span>
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                onClick={() => setSelectedRest(null)}
                className="px-4 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
