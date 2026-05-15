'use client';

import { useEffect, useMemo, useState } from 'react';
import api from '@/lib/api';
import { Users, UserPlus, FileCheck, DollarSign, TrendingUp, CreditCard, PieChart, Activity } from 'lucide-react';
import {
  AreaChart,
  AreaChartPoint,
  DonutChart,
  DonutSlice,
  BarChart,
  BarChartItem,
  TimeRange,
  TimeRangeToggle,
} from '@/components/Charts';

interface AppUser {
  id: string;
  role: string;
  isActive: boolean;
  createdAt: string;
}

interface FinancialStats {
  totalRevenue: number;
  totalVolume: number;
  totalTransactions: number;
  paidTransactions: number;
  pendingPayouts: number;
  totalWithdrawn: number;
}

interface AdminTransaction {
  id: string;
  platformFee: number;
  consultationFee: number;
  paymentMethod: string;
  status: string;
  createdAt: string;
}

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const fmtEgp = (n: number) =>
  new Intl.NumberFormat('en-EG', { maximumFractionDigits: 0 }).format(n);

// ─── Bucketing ─────────────────────────────────────────────────────────────

interface Bucket {
  key: string;
  label: string;
  start: Date;
  end: Date;
}

function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function startOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

function buildBuckets(range: TimeRange): Bucket[] {
  const now = new Date();
  const buckets: Bucket[] = [];

  if (range === '7D' || range === '30D') {
    const days = range === '7D' ? 7 : 30;
    for (let i = days - 1; i >= 0; i--) {
      const day = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() - i));
      const next = startOfDay(new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1));
      buckets.push({
        key: `${day.getFullYear()}-${day.getMonth()}-${day.getDate()}`,
        label: range === '7D'
          ? day.toLocaleDateString('en-US', { weekday: 'short' })
          : `${MONTH_LABELS[day.getMonth()]} ${day.getDate()}`,
        start: day,
        end: next,
      });
    }
  } else {
    const months = range === '6M' ? 6 : 12;
    for (let i = months - 1; i >= 0; i--) {
      const m = startOfMonth(new Date(now.getFullYear(), now.getMonth() - i, 1));
      const next = startOfMonth(new Date(m.getFullYear(), m.getMonth() + 1, 1));
      buckets.push({
        key: `${m.getFullYear()}-${m.getMonth()}`,
        label: MONTH_LABELS[m.getMonth()],
        start: m,
        end: next,
      });
    }
  }
  return buckets;
}

function aggregate<T>(
  range: TimeRange,
  items: T[],
  dateOf: (t: T) => string,
  valueOf: (t: T) => number,
  filter?: (t: T) => boolean,
): AreaChartPoint[] {
  const buckets = buildBuckets(range);
  const totals = new Map(buckets.map((b) => [b.key, 0]));
  const startMs = buckets[0].start.getTime();
  const endMs = buckets[buckets.length - 1].end.getTime();

  for (const item of items) {
    if (filter && !filter(item)) continue;
    const ts = new Date(dateOf(item)).getTime();
    if (ts < startMs || ts >= endMs) continue;

    let key: string;
    if (range === '7D' || range === '30D') {
      const d = new Date(ts);
      key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
    } else {
      const d = new Date(ts);
      key = `${d.getFullYear()}-${d.getMonth()}`;
    }
    if (totals.has(key)) totals.set(key, (totals.get(key) ?? 0) + valueOf(item));
  }

  return buckets.map((b) => ({ label: b.label, value: Math.round(totals.get(b.key) ?? 0) }));
}

// ─── Component ─────────────────────────────────────────────────────────────

export default function Dashboard() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [pendingDoctors, setPendingDoctors] = useState<number>(0);
  const [stats, setStats] = useState<FinancialStats | null>(null);
  const [transactions, setTransactions] = useState<AdminTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const [userRange, setUserRange] = useState<TimeRange>('30D');
  const [revenueRange, setRevenueRange] = useState<TimeRange>('30D');

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [usersRes, pendingRes, statsRes, txRes] = await Promise.all([
          api.get('/admin/users', { params: { page: 1, pageSize: 1000 } }),
          api.get('/admin/doctors/pending'),
          api.get('/admin/financial/stats').catch(() => null),
          api.get('/admin/financial/transactions', { params: { page: 1, pageSize: 500 } }).catch(() => null),
        ]);

        const usersData = usersRes.data.data;
        const items: AppUser[] = usersData?.items ?? usersData ?? [];
        setUsers(items);

        const pending = pendingRes.data.data || [];
        setPendingDoctors(pending.length);

        if (statsRes) setStats(statsRes.data.data ?? null);
        if (txRes) setTransactions(txRes.data.data?.items ?? []);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchAll();
  }, []);

  // ─── Derived metrics ──────────────────────────────────────────────────
  const totalUsers = users.length;
  const totalDoctors = users.filter((u) => u.role === 'Doctor').length;
  const totalPatients = users.filter((u) => u.role === 'Patient').length;
  const totalAdmins = users.filter((u) => u.role === 'Admin').length;

  const userGrowth = useMemo<AreaChartPoint[]>(
    () => aggregate(userRange, users, (u) => u.createdAt, () => 1),
    [users, userRange],
  );

  const revenueTrend = useMemo<AreaChartPoint[]>(
    () =>
      aggregate(
        revenueRange,
        transactions,
        (tx) => tx.createdAt,
        (tx) => tx.platformFee,
        (tx) => tx.status === 'Paid',
      ),
    [transactions, revenueRange],
  );

  const roleDistribution: DonutSlice[] = [
    { label: 'Patients', value: totalPatients, color: '#3b82f6' },
    { label: 'Doctors', value: totalDoctors, color: '#14b8a6' },
    { label: 'Admins', value: totalAdmins, color: '#a855f7' },
  ].filter((s) => s.value > 0);

  const paymentMethods: BarChartItem[] = (() => {
    const counts: Record<string, number> = { Card: 0, Wallet: 0, Cash: 0 };
    transactions.forEach((tx) => {
      if (tx.paymentMethod in counts) counts[tx.paymentMethod] += 1;
    });
    return [
      { label: 'Card', value: counts.Card, color: '#3b82f6' },
      { label: 'Wallet', value: counts.Wallet, color: '#a855f7' },
      { label: 'Cash', value: counts.Cash, color: '#14b8a6' },
    ];
  })();

  const userGrowthTotal = userGrowth.reduce((s, p) => s + p.value, 0);
  const revenueTotal = revenueTrend.reduce((s, p) => s + p.value, 0);

  // ─── Render ──────────────────────────────────────────────────────────

  if (isLoading) {
    return (
      <div className="p-8 text-white">
        <h1 className="text-3xl font-bold mb-8">Dashboard Overview</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-gray-900 rounded-2xl p-6 border border-gray-800 animate-pulse h-32" />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-gray-900 rounded-2xl p-6 border border-gray-800 animate-pulse h-80" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 text-white">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Dashboard Overview</h1>
        <p className="text-gray-400">Real-time insights into platform activity, users, and revenue.</p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
        <StatCard
          label="Total Users"
          value={totalUsers.toString()}
          icon={<Users className="w-6 h-6 text-blue-400" />}
          gradient="from-blue-900/50 to-blue-800/20"
          border="border-blue-500/20"
          iconBg="bg-blue-500/20"
          accent="text-blue-200"
        />
        <StatCard
          label="Total Doctors"
          value={totalDoctors.toString()}
          icon={<UserPlus className="w-6 h-6 text-teal-400" />}
          gradient="from-teal-900/50 to-teal-800/20"
          border="border-teal-500/20"
          iconBg="bg-teal-500/20"
          accent="text-teal-200"
        />
        <StatCard
          label="Pending Approvals"
          value={pendingDoctors.toString()}
          icon={<FileCheck className="w-6 h-6 text-purple-400" />}
          gradient="from-purple-900/50 to-purple-800/20"
          border="border-purple-500/20"
          iconBg="bg-purple-500/20"
          accent="text-purple-200"
        />
        <StatCard
          label="Platform Revenue"
          value={`EGP ${fmtEgp(stats?.totalRevenue ?? 0)}`}
          icon={<DollarSign className="w-6 h-6 text-emerald-400" />}
          gradient="from-emerald-900/50 to-emerald-800/20"
          border="border-emerald-500/20"
          iconBg="bg-emerald-500/20"
          accent="text-emerald-200"
        />
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <ChartCard
          className="lg:col-span-2"
          title="User Growth"
          subtitle={`${userGrowthTotal} new registration${userGrowthTotal === 1 ? '' : 's'} in selected period`}
          icon={<TrendingUp className="w-4 h-4 text-blue-400" />}
          action={<TimeRangeToggle value={userRange} onChange={setUserRange} />}
        >
          <div className="h-64">
            <AreaChart data={userGrowth} color="#3b82f6" height={240} />
          </div>
        </ChartCard>

        <ChartCard
          title="User Distribution"
          subtitle="By role"
          icon={<PieChart className="w-4 h-4 text-purple-400" />}
        >
          <DonutChart data={roleDistribution} centerLabel="Total" centerValue={totalUsers} />
        </ChartCard>
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <ChartCard
          className="lg:col-span-2"
          title="Revenue Trend"
          subtitle={`EGP ${fmtEgp(revenueTotal)} in platform fees during selected period`}
          icon={<Activity className="w-4 h-4 text-emerald-400" />}
          action={<TimeRangeToggle value={revenueRange} onChange={setRevenueRange} />}
        >
          <div className="h-64">
            <AreaChart
              data={revenueTrend}
              color="#10b981"
              height={240}
              valueFormatter={(n) => `EGP ${fmtEgp(n)}`}
            />
          </div>
        </ChartCard>

        <ChartCard
          title="Payment Methods"
          subtitle="Transaction count by method"
          icon={<CreditCard className="w-4 h-4 text-blue-400" />}
        >
          <BarChart data={paymentMethods} />
        </ChartCard>
      </div>
    </div>
  );
}

// ─── Sub-components ─────────────────────────────────────────────────────────

function StatCard({
  label,
  value,
  icon,
  gradient,
  border,
  iconBg,
  accent,
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  gradient: string;
  border: string;
  iconBg: string;
  accent: string;
}) {
  return (
    <div className={`bg-gradient-to-br ${gradient} border ${border} rounded-2xl p-6 relative overflow-hidden`}>
      <div className="flex justify-between items-start relative z-10">
        <div>
          <p className={`${accent} text-sm font-medium mb-1`}>{label}</p>
          <h3 className="text-3xl font-bold text-white tabular-nums">{value}</h3>
        </div>
        <div className={`p-3 ${iconBg} rounded-xl`}>{icon}</div>
      </div>
    </div>
  );
}

function ChartCard({
  title,
  subtitle,
  icon,
  children,
  className = '',
  action,
}: {
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
  className?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className={`bg-gray-900 border border-gray-800 rounded-2xl p-6 ${className}`}>
      <div className="flex items-start justify-between gap-4 mb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            {icon}
            <h3 className="text-base font-semibold text-white">{title}</h3>
          </div>
          {subtitle && <p className="text-xs text-gray-500">{subtitle}</p>}
        </div>
        {action && <div className="shrink-0">{action}</div>}
      </div>
      {children}
    </div>
  );
}
