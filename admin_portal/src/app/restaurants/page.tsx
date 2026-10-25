'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { 
  UtensilsCrossed, 
  PlusCircle, 
  Search, 
  SlidersHorizontal, 
  Edit3, 
  Trash2, 
  ExternalLink,
  MapPin,
  Clock,
  ShieldCheck,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { getRestaurants, deleteRestaurant } from '@/lib/data-service';
import { Restaurant } from '@/types';

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [vegFilter, setVegFilter] = useState<'ALL' | 'VEG_ONLY' | 'NON_VEG'>('ALL');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch() {
      const data = await getRestaurants();
      setRestaurants(data);
      setLoading(false);
    }
    fetch();
  }, []);

  const handleDelete = async (id: string, name: string) => {
    if (confirm(`Are you sure you want to delete ${name}?`)) {
      await deleteRestaurant(id);
      setRestaurants(prev => prev.filter(r => r.restaurant_id !== id));
    }
  };

  const filtered = restaurants.filter(r => {
    const matchesSearch = r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.cuisines.some(c => c.toLowerCase().includes(searchQuery.toLowerCase())) ||
      r.location.address.toLowerCase().includes(searchQuery.toLowerCase());
    
    if (vegFilter === 'VEG_ONLY') return matchesSearch && r.attributes.is_veg_only;
    if (vegFilter === 'NON_VEG') return matchesSearch && !r.attributes.is_veg_only;
    return matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Onboarded Restaurants</h2>
          <p className="text-xs text-slate-500">Manage dining partners, FSSAI verification, and direct UPI settlements</p>
        </div>
        <Link
          href="/restaurants/new"
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-500 text-white font-medium text-sm transition shadow-lg shadow-orange-600/20"
        >
          <PlusCircle className="w-4 h-4" />
          Onboard New Partner
        </Link>
      </div>

      {/* Filters Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by restaurant name, cuisine or city..."
            className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
          />
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto">
          <button
            onClick={() => setVegFilter('ALL')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition ${
              vegFilter === 'ALL' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All Places
          </button>
          <button
            onClick={() => setVegFilter('VEG_ONLY')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition flex items-center gap-1.5 ${
              vegFilter === 'VEG_ONLY' ? 'bg-emerald-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span> Pure Veg
          </button>
          <button
            onClick={() => setVegFilter('NON_VEG')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition ${
              vegFilter === 'NON_VEG' ? 'bg-amber-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Bar & Dining
          </button>
        </div>
      </div>

      {/* Restaurants Grid / Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filtered.map((r) => (
          <div key={r.restaurant_id} className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden flex flex-col hover:shadow-md transition">
            {/* Header Image */}
            <div className="relative h-44 bg-slate-100">
              <img
                src={r.visuals.hero_image}
                alt={r.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute top-3 right-3 flex items-center gap-2">
                <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider backdrop-blur-md shadow ${
                  r.status === 'ACTIVE' ? 'bg-emerald-500/90 text-white' : 'bg-slate-700/90 text-white'
                }`}>
                  {r.status}
                </span>
              </div>
              <div className="absolute bottom-3 left-3 flex items-center gap-1.5">
                <span className="bg-black/60 backdrop-blur-md text-amber-300 font-bold px-2 py-0.5 rounded text-xs">
                  ★ {r.rating.average} ({r.rating.total_reviews})
                </span>
                {r.attributes.is_veg_only && (
                  <span className="bg-emerald-600 text-white font-semibold text-[10px] px-2 py-0.5 rounded shadow">
                    PURE VEG
                  </span>
                )}
                {r.attributes.has_bar && (
                  <span className="bg-purple-600 text-white font-semibold text-[10px] px-2 py-0.5 rounded shadow">
                    BAR
                  </span>
                )}
              </div>
            </div>

            {/* Content Body */}
            <div className="p-5 flex-1 flex flex-col justify-between space-y-4">
              <div>
                <h3 className="font-bold text-base text-slate-800">{r.name}</h3>
                <p className="text-xs text-slate-500 mt-1 flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  <span className="truncate">{r.location.address}</span>
                </p>

                <div className="mt-3 flex flex-wrap gap-1.5">
                  {r.cuisines.map((c, i) => (
                    <span key={i} className="text-[11px] font-medium bg-slate-100 text-slate-600 px-2 py-0.5 rounded-md">
                      {c}
                    </span>
                  ))}
                </div>
              </div>

              {/* Settlement & Compliance Meta */}
              <div className="pt-3 border-t border-slate-100 text-xs text-slate-500 space-y-1.5 bg-slate-50/50 -mx-5 -mb-5 p-5">
                <div className="flex items-center justify-between">
                  <span className="text-slate-400">Direct UPI:</span>
                  <span className="font-mono font-medium text-slate-800">{r.upi_id}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-400">FSSAI License:</span>
                  <span className="font-mono font-medium text-slate-700">{r.fssai_number}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-400">Cost for Two:</span>
                  <span className="font-semibold text-slate-800">₹{r.cost_for_two}</span>
                </div>

                <div className="pt-3 flex items-center justify-end gap-2">
                  <button
                    onClick={() => handleDelete(r.restaurant_id, r.name)}
                    className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 transition"
                    title="Delete Restaurant"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
