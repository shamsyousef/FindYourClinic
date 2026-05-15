'use client';

import { useEffect, useState } from 'react';
import { Search, Power, FileText } from 'lucide-react';
import api from '@/lib/api';
import DocumentsDrawer from '@/components/DocumentsDrawer';

interface User {
  id: string;
  email: string;
  fullName: string;
  role: string;
  isActive: boolean;
  createdAt: string;
  doctorId: string | null;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('All');
  const [drawerUserId, setDrawerUserId] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<string | null>(null);

  useEffect(() => {
    api.get('/admin/users', { params: { page: 1, pageSize: 1000 } })
      .then((res) => setUsers(res.data.data?.items ?? res.data.data ?? []))
      .catch((err) => console.error('Error fetching users:', err))
      .finally(() => setIsLoading(false));
  }, []);

  const requestAvailability = async (doctorId: string) => {
    try {
      await api.post(`/admin/doctors/${doctorId}/request-availability`);
      alert('Availability request sent successfully.');
    } catch {
      alert('Failed to send availability request.');
    }
  };

  const handleToggleActive = async (user: User) => {
    setTogglingId(user.id);
    try {
      let newIsActive: boolean;
      if (user.role === 'Doctor' && user.doctorId) {
        const res = await api.post(`/admin/doctors/${user.doctorId}/toggle-active`);
        newIsActive = res.data.data?.isActive ?? !user.isActive;
      } else {
        const res = await api.post(`/admin/users/${user.id}/toggle-active`);
        newIsActive = res.data.data?.isActive ?? !user.isActive;
      }
      setUsers((prev) =>
        prev.map((u) => u.id === user.id ? { ...u, isActive: newIsActive } : u)
      );
    } catch {
      alert('Failed to update user status.');
    } finally {
      setTogglingId(null);
    }
  };

  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      user.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = roleFilter === 'All' || user.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  return (
    <div className="p-8 text-white">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold mb-2">Users Directory</h1>
          <p className="text-gray-400">Manage all registered patients and doctors on the platform.</p>
        </div>
      </div>

      <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden">
        <div className="p-4 border-b border-gray-800 flex flex-col sm:flex-row gap-4 justify-between items-center bg-gray-800/50">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search users by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-gray-900 border border-gray-700 rounded-xl text-sm focus:outline-none focus:border-blue-500 transition-colors"
            />
          </div>
          <div className="flex bg-gray-900 rounded-lg p-1 border border-gray-700 w-full sm:w-auto">
            {['All', 'Patient', 'Doctor'].map((role) => (
              <button
                key={role}
                onClick={() => setRoleFilter(role)}
                className={`flex-1 sm:flex-none px-4 py-1.5 text-sm font-medium rounded-md transition-colors ${
                  roleFilter === role
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'text-gray-400 hover:text-white hover:bg-gray-800'
                }`}
              >
                {role}
              </button>
            ))}
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-800/50 text-gray-400 font-medium">
              <tr>
                <th className="px-6 py-4">Name</th>
                <th className="px-6 py-4">Email</th>
                <th className="px-6 py-4">Role</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Joined Date</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400">Loading users...</td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400">No users found matching your search.</td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-800/50 transition-colors">
                    <td className="px-6 py-4 font-medium text-gray-200">{user.fullName}</td>
                    <td className="px-6 py-4 text-gray-400">{user.email}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex px-2.5 py-1 rounded-md text-xs font-medium border ${
                        user.role === 'Doctor'
                          ? 'bg-teal-500/10 text-teal-400 border-teal-500/20'
                          : user.role === 'Admin'
                            ? 'bg-purple-500/10 text-purple-400 border-purple-500/20'
                            : 'bg-blue-500/10 text-blue-400 border-blue-500/20'
                      }`}>
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className={`w-2 h-2 rounded-full mr-2 ${user.isActive ? 'bg-emerald-500' : 'bg-red-500'}`} />
                        <span className={user.isActive ? 'text-gray-300' : 'text-gray-500'}>
                          {user.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-500">
                      {new Date(user.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setDrawerUserId(user.id)}
                          className="p-2 bg-gray-800 hover:bg-gray-700 text-gray-400 hover:text-white border border-gray-700 rounded-lg transition-colors"
                          title="View documents"
                        >
                          <FileText className="w-4 h-4" />
                        </button>

                        {user.role !== 'Admin' && (
                          <button
                            onClick={() => handleToggleActive(user)}
                            disabled={togglingId === user.id}
                            title={user.isActive ? 'Deactivate user' : 'Activate user'}
                            className={`p-2 border rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                              user.isActive
                                ? 'bg-red-500/10 text-red-400 hover:bg-red-500 hover:text-white border-red-500/20'
                                : 'bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500 hover:text-white border-emerald-500/20'
                            }`}
                          >
                            <Power className="w-4 h-4" />
                          </button>
                        )}

                        {user.role === 'Doctor' && user.doctorId && (
                          <button
                            onClick={() => requestAvailability(user.doctorId!)}
                            className="px-3 py-1.5 bg-blue-500/10 text-blue-400 hover:bg-blue-500/20 border border-blue-500/20 rounded-lg text-xs font-medium transition-colors"
                          >
                            Request Availability
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <DocumentsDrawer userId={drawerUserId} onClose={() => setDrawerUserId(null)} />
    </div>
  );
}
