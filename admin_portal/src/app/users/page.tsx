'use client';

import React, { useEffect, useState } from 'react';
import { 
  Users, 
  Search, 
  Mail, 
  Phone, 
  Calendar, 
  BookmarkCheck, 
  ShieldCheck,
  Smartphone
} from 'lucide-react';
import { getUsers } from '@/lib/data-service';
import { UserProfile } from '@/types';

export default function UsersPage() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const data = await getUsers();
      setUsers(data);
      setLoading(false);
    }
    load();
  }, []);

  const filtered = users.filter(u => 
    u.name.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase()) ||
    u.phone_number.includes(search)
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Registered Diners</h2>
          <p className="text-xs text-slate-500">Customer profiles authenticated across Google Sign-In and Phone OTP</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
        <div className="relative w-full max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by name, email or phone..."
            className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
          />
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-400 text-[11px] uppercase tracking-wider font-semibold border-b border-slate-200">
              <tr>
                <th className="px-6 py-4">User ID</th>
                <th className="px-6 py-4">Customer Name</th>
                <th className="px-6 py-4">Contact Details</th>
                <th className="px-6 py-4">Auth Method</th>
                <th className="px-6 py-4">Food Preferences</th>
                <th className="px-6 py-4">Total Bookings</th>
                <th className="px-6 py-4">Joined Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {filtered.map(u => (
                <tr key={u.user_id} className="hover:bg-slate-50/70 transition">
                  <td className="px-6 py-4 font-mono text-xs text-slate-500">
                    {u.user_id}
                  </td>
                  <td className="px-6 py-4 font-semibold text-slate-900">
                    {u.name}
                  </td>
                  <td className="px-6 py-4 text-xs space-y-1">
                    <div className="flex items-center gap-1.5 text-slate-700">
                      <Mail className="w-3.5 h-3.5 text-slate-400" />
                      {u.email}
                    </div>
                    <div className="flex items-center gap-1.5 text-slate-500 font-mono">
                      <Phone className="w-3.5 h-3.5 text-slate-400" />
                      {u.phone_number}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700 border border-slate-200">
                      {u.auth_provider === 'google' ? 'Google' : 'Phone OTP'}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-1">
                      {u.preferences.map((p, idx) => (
                        <span key={idx} className="bg-orange-50 text-orange-700 border border-orange-100 text-[11px] px-2 py-0.5 rounded-md font-medium">
                          {p}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-6 py-4 font-bold text-slate-800">
                    {u.total_bookings}
                  </td>
                  <td className="px-6 py-4 text-xs text-slate-500">
                    {u.created_at ? new Date(u.created_at).toLocaleDateString() : 'Recent'}
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
