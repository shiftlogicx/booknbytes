'use client';

import React, { useEffect, useState } from 'react';
import { 
  Users, 
  Search, 
  Mail, 
  Phone, 
  Trash2, 
  RefreshCw, 
  ShieldCheck, 
  Plus, 
  History, 
  CheckCircle2, 
  XCircle,
  Key,
  ShieldAlert
} from 'lucide-react';
import { 
  getUsers, 
  deleteUser, 
  getAdminUsers, 
  createAdminUser, 
  deleteAdminUser, 
  getAdminLoginLogs 
} from '@/lib/data-service';
import { UserProfile, AdminUser, AdminLoginLog, AdminRole } from '@/types';

export default function UsersPage() {
  const [activeTab, setActiveTab] = useState<'diners' | 'admins' | 'logs'>('diners');
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [adminUsers, setAdminUsers] = useState<AdminUser[]>([]);
  const [loginLogs, setLoginLogs] = useState<AdminLoginLog[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  // New Admin Form State
  const [showAddModal, setShowAddModal] = useState(false);
  const [newAdminEmail, setNewAdminEmail] = useState('');
  const [newAdminName, setNewAdminName] = useState('');
  const [newAdminRole, setNewAdminRole] = useState<AdminRole>('admin');
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [dinersData, adminsData, logsData] = await Promise.all([
        getUsers(),
        getAdminUsers(),
        getAdminLoginLogs()
      ]);
      setUsers(dinersData);
      setAdminUsers(adminsData);
      setLoginLogs(logsData);
    } catch (err) {
      console.error('Error fetching users and admin directory:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDeleteDiner = async (id: string, name: string) => {
    if (confirm(`Remove user ${name} (${id})?`)) {
      try {
        await deleteUser(id);
        setUsers(prev => prev.filter(u => u.user_id !== id));
      } catch (err) {
        alert('Failed to delete user: ' + err);
      }
    }
  };

  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAdminEmail.trim() || !newAdminName.trim()) return;

    setSubmitting(true);
    try {
      const created = await createAdminUser({
        email: newAdminEmail.trim(),
        name: newAdminName.trim(),
        role: newAdminRole,
        auth_provider: 'oauth'
      });
      setAdminUsers(prev => [created, ...prev]);
      setShowAddModal(false);
      setNewAdminEmail('');
      setNewAdminName('');
    } catch (err: any) {
      alert('Failed to add admin: ' + err.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteAdmin = async (id: string, email: string) => {
    if (confirm(`Revoke administrative access for ${email}?`)) {
      try {
        await deleteAdminUser(id);
        setAdminUsers(prev => prev.filter(a => a.id !== id));
      } catch (err) {
        alert('Failed to delete admin: ' + err);
      }
    }
  };

  const filteredDiners = users.filter(u => 
    (u.name && u.name.toLowerCase().includes(search.toLowerCase())) ||
    (u.email && u.email.toLowerCase().includes(search.toLowerCase())) ||
    (u.phone_number && u.phone_number.includes(search)) ||
    u.user_id.toLowerCase().includes(search.toLowerCase())
  );

  const filteredAdmins = adminUsers.filter(a =>
    a.name.toLowerCase().includes(search.toLowerCase()) ||
    a.email.toLowerCase().includes(search.toLowerCase()) ||
    a.role.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">Identity & Access Management</h1>
          <p className="text-xs text-slate-500">Manage customer diner accounts, internal admin portal authorizations, and OAuth audit logs</p>
        </div>
        <div className="flex items-center gap-2">
          {activeTab === 'admins' && (
            <button
              onClick={() => setShowAddModal(true)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-950 text-white hover:bg-slate-800 text-xs font-semibold shadow-sm transition"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add Admin User</span>
            </button>
          )}
          <button
            onClick={loadData}
            className="p-2 rounded-lg border border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold"
            title="Refresh Directory"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200 gap-6 text-xs font-semibold">
        <button
          onClick={() => setActiveTab('diners')}
          className={`pb-3 transition flex items-center gap-2 border-b-2 -mb-[1px] ${
            activeTab === 'diners'
              ? 'border-slate-900 text-slate-950'
              : 'border-transparent text-slate-400 hover:text-slate-700'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>Platform Diners ({users.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('admins')}
          className={`pb-3 transition flex items-center gap-2 border-b-2 -mb-[1px] ${
            activeTab === 'admins'
              ? 'border-slate-900 text-slate-950'
              : 'border-transparent text-slate-400 hover:text-slate-700'
          }`}
        >
          <ShieldCheck className="w-4 h-4 text-emerald-600" />
          <span>Admin Portal Team ({adminUsers.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('logs')}
          className={`pb-3 transition flex items-center gap-2 border-b-2 -mb-[1px] ${
            activeTab === 'logs'
              ? 'border-slate-900 text-slate-950'
              : 'border-transparent text-slate-400 hover:text-slate-700'
          }`}
        >
          <History className="w-4 h-4" />
          <span>OAuth & Login Audit Logs ({loginLogs.length})</span>
        </button>
      </div>

      {/* Search Bar for Diners / Admins */}
      {activeTab !== 'logs' && (
        <div className="bg-white p-3.5 rounded-xl border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div className="relative w-full max-w-md">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder={activeTab === 'diners' ? "Search diners by name, email, phone..." : "Search admin by email or role..."}
              className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 focus:bg-white text-slate-900"
            />
          </div>
          <div className="text-xs font-semibold text-slate-500 hidden sm:block">
            Showing {activeTab === 'diners' ? filteredDiners.length : filteredAdmins.length} records
          </div>
        </div>
      )}

      {/* 1. DINERS TAB */}
      {activeTab === 'diners' && (
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
                <tr>
                  <th className="py-3 px-4">User ID</th>
                  <th className="py-3 px-4">Name</th>
                  <th className="py-3 px-4">Contact</th>
                  <th className="py-3 px-4">Preferences</th>
                  <th className="py-3 px-4">Reservations</th>
                  <th className="py-3 px-4">Joined Date</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {filteredDiners.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">
                      {loading ? 'Fetching users from Supabase...' : 'No users found.'}
                    </td>
                  </tr>
                ) : (
                  filteredDiners.map(u => (
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
                          onClick={() => handleDeleteDiner(u.user_id, u.name)}
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
      )}

      {/* 2. ADMIN USERS TAB */}
      {activeTab === 'admins' && (
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
                <tr>
                  <th className="py-3 px-4">Admin Name</th>
                  <th className="py-3 px-4">Email</th>
                  <th className="py-3 px-4">Role</th>
                  <th className="py-3 px-4">Auth Provider</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Last Sign In</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {filteredAdmins.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">
                      {loading ? 'Fetching admin team...' : 'No admin users registered.'}
                    </td>
                  </tr>
                ) : (
                  filteredAdmins.map(admin => (
                    <tr key={admin.id} className="hover:bg-slate-50/50 transition">
                      <td className="py-3 px-4 font-bold text-slate-900 flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-slate-900 text-emerald-400 flex items-center justify-center font-bold text-[10px]">
                          {admin.name.charAt(0)}
                        </div>
                        <span>{admin.name}</span>
                      </td>
                      <td className="py-3 px-4 text-slate-700 font-mono text-[11px]">
                        {admin.email}
                      </td>
                      <td className="py-3 px-4">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          admin.role === 'super_admin'
                            ? 'bg-purple-100 text-purple-800 border border-purple-200'
                            : admin.role === 'admin'
                              ? 'bg-blue-100 text-blue-800 border border-blue-200'
                              : 'bg-slate-100 text-slate-800'
                        }`}>
                          {admin.role.toUpperCase()}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-600 capitalize">
                        <span className="px-2 py-0.5 rounded bg-slate-100 text-[10px] font-semibold text-slate-700">
                          {admin.auth_provider || 'Email / OAuth'}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                          {admin.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-500 font-mono text-[11px]">
                        {admin.last_sign_in_at ? new Date(admin.last_sign_in_at).toLocaleString() : 'Never'}
                      </td>
                      <td className="py-3 px-4 text-right">
                        {admin.email !== 'shiftlogiciq@gmail.com' && (
                          <button
                            onClick={() => handleDeleteAdmin(admin.id, admin.email)}
                            className="p-1.5 text-slate-400 hover:text-red-600 rounded transition"
                            title="Revoke Admin Access"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 3. AUDIT LOGS TAB */}
      {activeTab === 'logs' && (
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
                <tr>
                  <th className="py-3 px-4">Timestamp</th>
                  <th className="py-3 px-4">Admin Email</th>
                  <th className="py-3 px-4">Auth Method</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Device / Client User Agent</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {loginLogs.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="py-8 text-center text-slate-400">
                      {loading ? 'Fetching login audit history...' : 'No audit entries recorded yet.'}
                    </td>
                  </tr>
                ) : (
                  loginLogs.map(log => (
                    <tr key={log.id} className="hover:bg-slate-50/50 transition">
                      <td className="py-3 px-4 text-slate-500 font-mono text-[11px]">
                        {new Date(log.created_at).toLocaleString()}
                      </td>
                      <td className="py-3 px-4 font-mono font-semibold text-slate-900">
                        {log.email}
                      </td>
                      <td className="py-3 px-4">
                        <span className="px-2 py-0.5 rounded bg-slate-100 text-[10px] font-semibold text-slate-700 capitalize">
                          {log.auth_provider}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        {log.status === 'success' ? (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                            SUCCESS
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-800">
                            <XCircle className="w-3 h-3 text-red-600" />
                            FAILED
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-slate-400 font-mono text-[10px] max-w-xs truncate">
                        {log.user_agent || 'Standard Web Client'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Add Admin Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">Authorize New Admin</h3>
              <p className="text-xs text-slate-500">Allow this user to sign in to BookNBytes Admin Console via OAuth or password</p>
            </div>

            <form onSubmit={handleCreateAdmin} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Full Name</label>
                <input
                  type="text"
                  required
                  value={newAdminName}
                  onChange={e => setNewAdminName(e.target.value)}
                  placeholder="e.g. Yash Chitte"
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 text-slate-900"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Admin Email (Google / GitHub)</label>
                <input
                  type="email"
                  required
                  value={newAdminEmail}
                  onChange={e => setNewAdminEmail(e.target.value)}
                  placeholder="e.g. yash@gmail.com"
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 text-slate-900"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Role Permissions</label>
                <select
                  value={newAdminRole}
                  onChange={e => setNewAdminRole(e.target.value as AdminRole)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs focus:ring-2 focus:ring-slate-900 text-slate-900"
                >
                  <option value="super_admin">Super Admin (Full access + manage team)</option>
                  <option value="admin">Admin (Manage restaurants, slots & bookings)</option>
                  <option value="manager">Manager (Read-only reservations & reviews)</option>
                  <option value="support">Support Agent (View-only)</option>
                </select>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-600 text-xs font-semibold hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-4 py-1.5 rounded-lg bg-slate-950 text-white text-xs font-semibold hover:bg-slate-800 disabled:opacity-60"
                >
                  {submitting ? 'Granting...' : 'Grant Access'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
