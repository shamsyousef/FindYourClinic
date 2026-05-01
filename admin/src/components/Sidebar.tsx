'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { Users, FileCheck, Stethoscope, LogOut, LayoutDashboard, ClipboardList, Star } from 'lucide-react';

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const navigation = [
    { name: 'Dashboard', href: '/', icon: LayoutDashboard },
    { name: 'Approvals', href: '/approvals', icon: FileCheck },
    { name: 'Users', href: '/users', icon: Users },
    { name: 'Specialties', href: '/specialties', icon: Stethoscope },
    { name: 'Health Records', href: '/health-records', icon: ClipboardList },
    { name: 'Reviews', href: '/reviews', icon: Star },
  ];

  const handleLogout = () => {
    localStorage.removeItem('token');
    router.push('/login');
  };

  return (
    <div className="flex flex-col w-64 bg-gray-900 border-r border-gray-800 min-h-screen text-gray-300">
      <div className="flex items-center justify-center h-20 border-b border-gray-800">
        <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-teal-400 bg-clip-text text-transparent">
          Find Your Clinic
        </h1>
      </div>
      <nav className="flex-1 px-4 py-6 space-y-2">
        {navigation.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center px-4 py-3 rounded-xl transition-all ${
                isActive
                  ? 'bg-blue-600/10 text-blue-400 font-medium border border-blue-500/20'
                  : 'hover:bg-gray-800 hover:text-white'
              }`}
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.name}
            </Link>
          );
        })}
      </nav>
      <div className="p-4 border-t border-gray-800">
        <button
          onClick={handleLogout}
          className="flex items-center w-full px-4 py-3 text-red-400 rounded-xl hover:bg-red-500/10 transition-all"
        >
          <LogOut className="w-5 h-5 mr-3" />
          Logout
        </button>
      </div>
    </div>
  );
}
