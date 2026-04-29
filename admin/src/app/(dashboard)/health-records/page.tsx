'use client';

import { useEffect, useState } from 'react';
import api from '@/lib/api';
import { ClipboardList, Users, Calendar, BarChart2 } from 'lucide-react';

interface HealthRecordStats {
  totalRecords: number;
  patientsWithRecords: number;
  recordsThisMonth: number;
  recordsByType: Record<string, number>;
}

export default function HealthRecordsPage() {
  const [stats, setStats] = useState<HealthRecordStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    api
      .get('/health-records/admin/stats')
      .then((res) => setStats(res.data.data))
      .catch(console.error)
      .finally(() => setIsLoading(false));
  }, []);

  if (isLoading) {
    return (
      <div className="p-8 text-white">
        <h1 className="text-3xl font-bold mb-8">Health Records</h1>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="bg-gray-900 rounded-2xl p-6 border border-gray-800 animate-pulse h-32"
            />
          ))}
        </div>
        <div className="bg-gray-900 rounded-2xl border border-gray-800 animate-pulse h-64" />
      </div>
    );
  }

  const statCards = [
    {
      label: 'Total Records',
      value: stats?.totalRecords ?? 0,
      icon: ClipboardList,
      gradient: 'from-blue-900/50 to-blue-800/20',
      border: 'border-blue-500/20',
      iconColor: 'text-blue-400',
    },
    {
      label: 'Patients with Records',
      value: stats?.patientsWithRecords ?? 0,
      icon: Users,
      gradient: 'from-emerald-900/50 to-emerald-800/20',
      border: 'border-emerald-500/20',
      iconColor: 'text-emerald-400',
    },
    {
      label: 'Records This Month',
      value: stats?.recordsThisMonth ?? 0,
      icon: Calendar,
      gradient: 'from-purple-900/50 to-purple-800/20',
      border: 'border-purple-500/20',
      iconColor: 'text-purple-400',
    },
  ];

  const typeEntries = Object.entries(stats?.recordsByType ?? {}).sort(
    ([, a], [, b]) => b - a
  );
  const maxCount = typeEntries[0]?.[1] ?? 1;

  return (
    <div className="p-8 text-white">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Health Records</h1>
        <p className="text-gray-400">Aggregate statistics across all patients.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <div
              key={card.label}
              className={`bg-gradient-to-br ${card.gradient} border ${card.border} rounded-2xl p-6`}
            >
              <div className="flex justify-between items-start mb-4">
                <p className="text-gray-400 text-sm font-medium">{card.label}</p>
                <Icon className={`w-5 h-5 ${card.iconColor}`} />
              </div>
              <p className="text-4xl font-bold text-white">{card.value.toLocaleString()}</p>
            </div>
          );
        })}
      </div>

      <div className="bg-gray-900 border border-gray-800 rounded-2xl p-6">
        <div className="flex items-center gap-2 mb-6">
          <BarChart2 className="w-5 h-5 text-gray-400" />
          <h2 className="text-lg font-semibold">Records by Type</h2>
        </div>

        {typeEntries.length === 0 ? (
          <p className="text-gray-500 text-center py-8">No records found.</p>
        ) : (
          <div className="space-y-4">
            {typeEntries.map(([type, count]) => (
              <div key={type}>
                <div className="flex justify-between items-center mb-1">
                  <span className="text-sm text-gray-300 capitalize">
                    {type.replace(/([A-Z])/g, ' $1').trim()}
                  </span>
                  <span className="text-sm font-semibold text-white">{count}</span>
                </div>
                <div className="w-full bg-gray-800 rounded-full h-2">
                  <div
                    className="bg-blue-500 h-2 rounded-full transition-all"
                    style={{ width: `${(count / maxCount) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
