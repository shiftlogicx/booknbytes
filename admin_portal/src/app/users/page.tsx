'use client';

import React, { useEffect, useState } from 'react';
import { 
  Users, 
  Search, 
  Mail, 
  Phone, 
  Trash2, 
  RefreshCw, 
  BookmarkCheck, 
  ShieldCheck 
} from 'lucide-react';
import { getUsers, deleteUser } from '@/lib/data-service';
import { UserProfile } from '@/types';

export default function UsersPage() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (err) {
      console.error('Error fetching users:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDelete = async (id: string, name: string) => {
    if (confirm(`Remove user ${name} (${id})?`)) {
      try {
        await deleteUser(id);
        setUsers(prev => prev.filter(u => u.user_id !== id));
      } catch (err) {
        alert('Failed to delete user: ' + err);
      }
    }
  };

  const filtered = users.filter(u => 
    (u.name && u.name.toLowerCase().includes(search.toLowerCase())) ||
    (u.email && u.email.toLowerCase().includes(search.toLowerCase())) ||
    (u.phone_number && u.phone_number.includes(search)) ||
    u.user_id.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Registered Diners & Users</h1>
          <p className="text-xs text-slate-500">Live Supabase user directory across diners, restaurant owners and staff</p>
        </div>
        <button
          onClick={loadData}
          className="p-2 rounded-lg border border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold self-start sm:self-auto"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-3.5 rounded-xl border border-slate-200/80 shadow-sm flex items-center justify-between">
        <div className="relative w-full max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by name, email, phone or UUID..."
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 focus:bg-white text-slate-900"
          />
        </div>
        <div className="text-xs font-semibold text-slate-500 hidden sm:block">
          Total Registered: <span className="text-slate-900 font-bold">{users.length}</span>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
              <tr>
                <th className="py-3 px-4">User ID</th>
                <th className="py-3 px-4">Name</th>
                <th className="py-3 px-4">Contact</th>
                <th className="py-3 px-4">Preferences</th>
                <th className="py-3 px-4">Total Reservations</th>
                <th className="py-3 px-4">Joined Date</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    {loading ? 'Fetching users from Supabase...' : 'No users found.'}
                  </td>
                </tr>
              ) : (
                filtered.map(u => (
                  <tr key={u.user_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4 font-mono text-[11px] text-slate-500">
                      {u.user_id.slice(0, 13)}...
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {u.name}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div>{u.email}</div>
                      <div className="text-[10px] text-slate-400 font-mono">{u.phone_number}</div>
                    </td>
                    <td className="py-3 px-4">
                      {u.preferences && u.preferences.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {u.preferences.map((p, i) => (
                            <span key={i} className="px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 text-[10px]">
                              {p}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <span className="text-slate-400">—</span>
                      )}
                    </td>
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {u.total_bookings} bookings
                    </td>
                    <td className="py-3 px-4 text-slate-500 font-mono text-[11px]">
                      {u.created_at ? u.created_at.split('T')[0] : 'N/A'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => handleDelete(u.user_id, u.name)}
                        className="p-1.5 text-slate-400 hover:text-red-600 rounded"
                        title="Delete User"
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
    </div>
  );
}
