'use client';

import { useEffect, useState } from 'react';
import { CheckCircle, XCircle, Power, FileText } from 'lucide-react';
import api from '@/lib/api';
import DocumentsDrawer from '@/components/DocumentsDrawer';

type DoctorStatusFilter = 'All' | 'Pending' | 'Approved' | 'Rejected';

interface Doctor {
  doctorId: string;
  userId: string;
  fullName: string;
  email: string;
  specialty: string;
  status: string;
  isActive: boolean;
  reviewedAt: string | null;
  rejectionReason: string | null;
  documentUrls: string[];
}

const TABS: DoctorStatusFilter[] = ['All', 'Pending', 'Approved', 'Rejected'];

const statusBadgeClass: Record<string, string> = {
  PendingReview: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
  Approved: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
  Rejected: 'bg-red-500/10 text-red-400 border-red-500/20',
};

const statusLabel: Record<string, string> = {
  PendingReview: 'Pending Review',
  Approved: 'Approved',
  Rejected: 'Rejected',
};

export default function ApprovalsPage() {
  const [activeTab, setActiveTab] = useState<DoctorStatusFilter>('Pending');
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [rejectionReason, setRejectionReason] = useState('');
  const [selectedDoctorId, setSelectedDoctorId] = useState<string | null>(null);
  const [drawerUserId, setDrawerUserId] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<string | null>(null);

  const [deletingDoctorId, setDeletingDoctorId] = useState<string | null>(null);
  const [deleteReason, setDeleteReason] = useState('');

  const fetchDoctors = async (tab: DoctorStatusFilter) => {
    setIsLoading(true);
    try {
      const params = tab !== 'All' ? `?status=${tab}` : '';
      const response = await api.get(`/admin/doctors${params}`);
      setDoctors(response.data.data ?? []);
    } catch (error) {
      console.error('Error fetching doctors:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDoctors(activeTab);
  }, [activeTab]);

  const handleApprove = async (id: string) => {
    try {
      await api.post(`/admin/doctors/${id}/approve`);
      fetchDoctors(activeTab);
    } catch {
      alert('Failed to approve doctor.');
    }
  };

  const handleSetPending = async (id: string) => {
    try {
      await api.post(`/admin/doctors/${id}/pending`);
      fetchDoctors(activeTab);
    } catch {
      alert('Failed to set doctor to pending.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!deleteReason) {
      alert('Please provide a reason for deletion.');
      return;
    }
    try {
      if (confirm('Are you sure you want to completely delete this account? This cannot be undone.')) {
        await api.delete(`/admin/doctors/${id}`, { data: { reason: deleteReason } });
        setDeleteReason('');
        setDeletingDoctorId(null);
        fetchDoctors(activeTab);
      }
    } catch {
      alert('Failed to delete doctor.');
    }
  };

  const handleReject = async (id: string) => {
    if (!rejectionReason) {
      alert('Please provide a reason for rejection.');
      return;
    }
    try {
      await api.post(`/admin/doctors/${id}/reject`, { reason: rejectionReason });
      setRejectionReason('');
      setSelectedDoctorId(null);
      fetchDoctors(activeTab);
    } catch {
      alert('Failed to reject doctor.');
    }
  };

  const handleToggleActive = async (doctor: Doctor) => {
    setTogglingId(doctor.doctorId);
    try {
      const response = await api.post(`/admin/doctors/${doctor.doctorId}/toggle-active`);
      const newIsActive: boolean = response.data.data?.isActive ?? !doctor.isActive;
      setDoctors((prev) =>
        prev.map((d) => d.doctorId === doctor.doctorId ? { ...d, isActive: newIsActive } : d)
      );
    } catch {
      alert('Failed to update doctor status.');
    } finally {
      setTogglingId(null);
    }
  };

  const pendingCount = doctors.filter((d) => d.status === 'PendingReview').length;

  return (
    <div className="p-8 text-white">
      <h1 className="text-3xl font-bold mb-8">Doctors Management</h1>

      {/* Tabs */}
      <div className="flex gap-2 mb-6 border-b border-gray-800">
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-2.5 text-sm font-medium rounded-t-lg transition-colors border-b-2 -mb-px ${
              activeTab === tab
                ? 'border-blue-500 text-blue-400 bg-blue-500/5'
                : 'border-transparent text-gray-400 hover:text-white hover:bg-gray-800/50'
            }`}
          >
            {tab}
            {tab === 'Pending' && pendingCount > 0 && (
              <span className="ml-2 px-1.5 py-0.5 bg-yellow-500/20 text-yellow-400 text-xs rounded-full">
                {pendingCount}
              </span>
            )}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="text-gray-400 py-12">Loading doctors...</div>
      ) : doctors.length === 0 ? (
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-12 text-center text-gray-400">
          <CheckCircle className="w-16 h-16 mx-auto mb-4 text-gray-600" />
          <h2 className="text-xl font-semibold mb-2">
            {activeTab === 'Pending' ? 'All caught up!' : `No ${activeTab.toLowerCase()} doctors.`}
          </h2>
          <p>
            {activeTab === 'Pending'
              ? 'There are no doctors pending approval at this time.'
              : `No doctors with ${activeTab.toLowerCase()} status found.`}
          </p>
        </div>
      ) : (
        <div className="grid gap-6">
          {doctors.map((doctor) => (
            <div key={doctor.doctorId} className="bg-gray-900 border border-gray-800 rounded-2xl p-6 flex flex-col md:flex-row gap-6">
              <div className="flex-1">
                <div className="flex flex-wrap items-center gap-2 mb-2">
                  <h3 className="text-xl font-bold text-white">{doctor.fullName}</h3>
                  <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium border ${statusBadgeClass[doctor.status] ?? 'bg-gray-700 text-gray-400 border-gray-600'}`}>
                    {statusLabel[doctor.status] ?? doctor.status}
                  </span>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${doctor.isActive ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' : 'bg-gray-700 text-gray-400 border-gray-600'}`}>
                    <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${doctor.isActive ? 'bg-emerald-400' : 'bg-gray-500'}`} />
                    {doctor.isActive ? 'Active' : 'Inactive'}
                  </span>
                </div>
                <p className="text-gray-400 mb-2">{doctor.specialty} · {doctor.email}</p>
                {doctor.rejectionReason && (
                  <p className="text-red-400 text-sm mt-1">Rejection reason: {doctor.rejectionReason}</p>
                )}
              </div>

              <div className="flex flex-col gap-3 min-w-[200px] border-t md:border-t-0 md:border-l border-gray-800 pt-4 md:pt-0 md:pl-6">
                {/* Documents button — always shown */}
                <button
                  onClick={() => setDrawerUserId(doctor.userId)}
                  className="w-full bg-gray-800 hover:bg-gray-700 text-gray-300 border border-gray-700 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center gap-2"
                >
                  <FileText className="w-4 h-4" />
                  Documents
                </button>

                {/* Per-status actions */}
                {doctor.status === 'PendingReview' && (
                  <>
                    <button
                      onClick={() => handleApprove(doctor.doctorId)}
                      className="w-full bg-emerald-500/10 text-emerald-500 hover:bg-emerald-500 hover:text-white border border-emerald-500/20 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center"
                    >
                      <CheckCircle className="w-5 h-5 mr-2" />
                      Approve
                    </button>

                    {selectedDoctorId === doctor.doctorId ? (
                      <div className="space-y-3">
                        <textarea
                          value={rejectionReason}
                          onChange={(e) => setRejectionReason(e.target.value)}
                          placeholder="Reason for rejection..."
                          className="w-full bg-gray-800 border border-gray-700 rounded-lg p-2 text-sm text-white focus:outline-none focus:border-red-500 h-20 resize-none"
                        />
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleReject(doctor.doctorId)}
                            className="flex-1 bg-red-500 text-white font-medium py-2 rounded-lg text-sm hover:bg-red-600 transition-colors"
                          >
                            Confirm
                          </button>
                          <button
                            onClick={() => { setSelectedDoctorId(null); setRejectionReason(''); }}
                            className="flex-1 bg-gray-700 text-white font-medium py-2 rounded-lg text-sm hover:bg-gray-600 transition-colors"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : (
                      <button
                        onClick={() => setSelectedDoctorId(doctor.doctorId)}
                        className="w-full bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white border border-red-500/20 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center"
                      >
                        <XCircle className="w-5 h-5 mr-2" />
                        Reject
                      </button>
                    )}
                  </>
                )}

                {doctor.status === 'Rejected' && (
                  <>
                    <button
                      onClick={() => handleApprove(doctor.doctorId)}
                      className="w-full bg-emerald-500/10 text-emerald-500 hover:bg-emerald-500 hover:text-white border border-emerald-500/20 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center"
                    >
                      <CheckCircle className="w-5 h-5 mr-2" />
                      Approve
                    </button>
                    <button
                      onClick={() => handleSetPending(doctor.doctorId)}
                      className="w-full bg-yellow-500/10 text-yellow-500 hover:bg-yellow-500 hover:text-white border border-yellow-500/20 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center mt-2"
                    >
                      Set to Pending
                    </button>
                  </>
                )}

                {(doctor.status === 'Approved' || doctor.status === 'Rejected') && (
                  <button
                    onClick={() => handleToggleActive(doctor)}
                    disabled={togglingId === doctor.doctorId}
                    className={`w-full font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center gap-2 border disabled:opacity-50 disabled:cursor-not-allowed ${
                      doctor.isActive
                        ? 'bg-red-500/10 text-red-400 hover:bg-red-500 hover:text-white border-red-500/20'
                        : 'bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500 hover:text-white border-emerald-500/20'
                    }`}
                  >
                    <Power className="w-4 h-4" />
                    {togglingId === doctor.doctorId ? 'Updating...' : doctor.isActive ? 'Deactivate' : 'Activate'}
                  </button>
                )}

                {/* Delete Account */}
                <div className="mt-4 pt-4 border-t border-gray-800">
                  {deletingDoctorId === doctor.doctorId ? (
                    <div className="space-y-3">
                      <textarea
                        value={deleteReason}
                        onChange={(e) => setDeleteReason(e.target.value)}
                        placeholder="Reason for deletion..."
                        className="w-full bg-gray-800 border border-gray-700 rounded-lg p-2 text-sm text-white focus:outline-none focus:border-red-500 h-20 resize-none"
                      />
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleDelete(doctor.doctorId)}
                          className="flex-1 bg-red-600 text-white font-medium py-2 rounded-lg text-sm hover:bg-red-700 transition-colors"
                        >
                          Confirm Delete
                        </button>
                        <button
                          onClick={() => { setDeletingDoctorId(null); setDeleteReason(''); }}
                          className="flex-1 bg-gray-700 text-white font-medium py-2 rounded-lg text-sm hover:bg-gray-600 transition-colors"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <button
                      onClick={() => setDeletingDoctorId(doctor.doctorId)}
                      className="w-full bg-red-900/20 text-red-500 hover:bg-red-600 hover:text-white border border-red-900/30 font-medium py-2 px-4 rounded-xl transition-all flex items-center justify-center"
                    >
                      Delete Account
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <DocumentsDrawer userId={drawerUserId} onClose={() => setDrawerUserId(null)} />
    </div>
  );
}
