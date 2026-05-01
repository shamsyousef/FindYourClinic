'use client';

import { useEffect, useState } from 'react';
import { Star, Trash2, Search } from 'lucide-react';
import api from '@/lib/api';

interface Review {
  id: string;
  doctorName: string;
  doctorId: string;
  patientName: string;
  rating: number;
  comment: string | null;
  createdAt: string;
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [deletingId, setDeletingId] = useState<string | null>(null);

  useEffect(() => {
    fetchReviews();
  }, []);

  const fetchReviews = async () => {
    try {
      const response = await api.get('/admin/reviews');
      setReviews(response.data.data ?? []);
    } catch (error) {
      console.error('Error fetching reviews:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const deleteReview = async (reviewId: string) => {
    if (!confirm('Are you sure you want to delete this review? This cannot be undone.')) return;
    setDeletingId(reviewId);
    try {
      await api.delete(`/admin/reviews/${reviewId}`);
      setReviews((prev) => prev.filter((r) => r.id !== reviewId));
    } catch (error) {
      console.error('Error deleting review:', error);
      alert('Failed to delete review.');
    } finally {
      setDeletingId(null);
    }
  };

  const filtered = reviews.filter((r) => {
    const q = searchTerm.toLowerCase();
    return (
      r.doctorName.toLowerCase().includes(q) ||
      r.patientName.toLowerCase().includes(q) ||
      (r.comment ?? '').toLowerCase().includes(q)
    );
  });

  return (
    <div className="p-8 text-white">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Reviews Management</h1>
        <p className="text-gray-400">Moderate patient reviews across all doctors on the platform.</p>
      </div>

      {/* Stats Bar */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
          <p className="text-gray-400 text-sm mb-1">Total Reviews</p>
          <p className="text-3xl font-bold">{reviews.length}</p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
          <p className="text-gray-400 text-sm mb-1">Average Rating</p>
          <p className="text-3xl font-bold">
            {reviews.length === 0
              ? '—'
              : (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1)}
          </p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
          <p className="text-gray-400 text-sm mb-1">5-Star Reviews</p>
          <p className="text-3xl font-bold">{reviews.filter((r) => r.rating === 5).length}</p>
        </div>
      </div>

      {/* Table */}
      <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden">
        <div className="p-4 border-b border-gray-800 bg-gray-800/50">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 w-5 h-5" />
            <input
              type="text"
              placeholder="Search by doctor, patient or comment..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 text-sm"
            />
          </div>
        </div>

        {isLoading ? (
          <div className="flex justify-center items-center py-20">
            <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-blue-500" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-20 text-gray-500">No reviews found.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-gray-400 border-b border-gray-800 text-left">
                  <th className="px-6 py-3 font-medium">Doctor</th>
                  <th className="px-6 py-3 font-medium">Patient</th>
                  <th className="px-6 py-3 font-medium">Rating</th>
                  <th className="px-6 py-3 font-medium">Comment</th>
                  <th className="px-6 py-3 font-medium">Date</th>
                  <th className="px-6 py-3 font-medium text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {filtered.map((review) => (
                  <tr key={review.id} className="hover:bg-gray-800/40 transition-colors">
                    <td className="px-6 py-4 font-medium whitespace-nowrap">
                      Dr. {review.doctorName}
                    </td>
                    <td className="px-6 py-4 text-gray-300 whitespace-nowrap">
                      {review.patientName}
                    </td>
                    <td className="px-6 py-4">
                      <StarRating value={review.rating} />
                    </td>
                    <td className="px-6 py-4 text-gray-400 max-w-xs">
                      {review.comment ? (
                        <span className="line-clamp-2">{review.comment}</span>
                      ) : (
                        <span className="italic text-gray-600">No comment</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-gray-400 whitespace-nowrap">
                      {new Date(review.createdAt).toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => deleteReview(review.id)}
                        disabled={deletingId === review.id}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-red-400 hover:bg-red-500/10 border border-red-500/20 transition-all disabled:opacity-50 disabled:cursor-not-allowed text-xs font-medium"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        {deletingId === review.id ? 'Deleting…' : 'Delete'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function StarRating({ value }: { value: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((star) => (
        <Star
          key={star}
          className={`w-4 h-4 ${star <= value ? 'text-amber-400 fill-amber-400' : 'text-gray-600'}`}
        />
      ))}
    </div>
  );
}
