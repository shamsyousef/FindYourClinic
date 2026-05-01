'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { Users, UserPlus, FileCheck } from 'lucide-react';

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalDoctors: 0,
    pendingDoctors: 0,
  });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [usersRes, pendingDoctorsRes] = await Promise.all([
          api.get('/admin/users'),
          api.get('/admin/doctors/pending'),
        ]);

        const usersData = usersRes.data.data;
        const items: any[] = usersData?.items ?? usersData ?? [];
        const totalUsers: number = usersData?.totalCount ?? items.length;
        const pendingDoctors = pendingDoctorsRes.data.data || [];

        setStats({
          totalUsers,
          totalDoctors: items.filter((u: any) => u.role === 'Doctor').length,
          pendingDoctors: pendingDoctors.length,
        });
      } catch (error) {
        console.error('Error fetching dashboard stats:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (isLoading) {
    return (
      <div className="p-8 text-white">
        <h1 className="text-2xl font-bold mb-6">Dashboard Overview</h1>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-gray-900 rounded-2xl p-6 border border-gray-800 animate-pulse h-32"></div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 text-white">
      <h1 className="text-3xl font-bold mb-8">Dashboard Overview</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-blue-900/50 to-blue-800/20 border border-blue-500/20 rounded-2xl p-6 relative overflow-hidden">
          <div className="flex justify-between items-start relative z-10">
            <div>
              <p className="text-blue-200 text-sm font-medium mb-1">Total Users</p>
              <h3 className="text-3xl font-bold text-white">{stats.totalUsers}</h3>
            </div>
            <div className="p-3 bg-blue-500/20 rounded-xl">
              <Users className="w-6 h-6 text-blue-400" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-teal-900/50 to-teal-800/20 border border-teal-500/20 rounded-2xl p-6 relative overflow-hidden">
          <div className="flex justify-between items-start relative z-10">
            <div>
              <p className="text-teal-200 text-sm font-medium mb-1">Total Doctors</p>
              <h3 className="text-3xl font-bold text-white">{stats.totalDoctors}</h3>
            </div>
            <div className="p-3 bg-teal-500/20 rounded-xl">
              <UserPlus className="w-6 h-6 text-teal-400" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-purple-900/50 to-purple-800/20 border border-purple-500/20 rounded-2xl p-6 relative overflow-hidden">
          <div className="flex justify-between items-start relative z-10">
            <div>
              <p className="text-purple-200 text-sm font-medium mb-1">Pending Approvals</p>
              <h3 className="text-3xl font-bold text-white">{stats.pendingDoctors}</h3>
            </div>
            <div className="p-3 bg-purple-500/20 rounded-xl">
              <FileCheck className="w-6 h-6 text-purple-400" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
