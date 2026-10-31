'use client';

import React, { useEffect, useState } from 'react';
import { 
  Star, 
  Trash2, 
  Plus, 
  RefreshCw, 
  MessageSquare, 
  User, 
  Store
} from 'lucide-react';
import { getReviews, deleteReview, createReview, getRestaurants } from '@/lib/data-service';
import { Review, Restaurant } from '@/types';

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);

  // New Review Modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedRestId, setSelectedRestId] = useState('');
  const [rating, setRating] = useState('5');
  const [comment, setComment] = useState('Outstanding food and very prompt table service!');
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [rData, rests] = await Promise.all([
        getReviews(),
        getRestaurants()
      ]);
      setReviews(rData);
      setRestaurants(rests);
      if (rests.length > 0 && !selectedRestId) {
        setSelectedRestId(rests[0].restaurant_id);
      }
    } catch (err) {
      console.error('Error loading reviews:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleDelete = async (id: string) => {
    if (confirm('Delete this review?')) {
      try {
        await deleteReview(id);
        setReviews(prev => prev.filter(r => r.review_id !== id));
      } catch (err) {
        alert('Failed to delete review: ' + err);
      }
    }
  };

  const handleCreateReview = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedRestId) return;

    setSubmitting(true);
    try {
      await createReview({
        restaurant_id: selectedRestId,
        rating: parseInt(rating, 10) || 5,
        comment,
      });
      setShowAddModal(false);
      loadData();
    } catch (err: any) {
      alert('Failed to create review: ' + (err.message || err));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Guest Reviews & Feedback</h1>
          <p className="text-xs text-slate-500">Monitor guest ratings, feedback, and moderation across outlets</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={loadData}
            className="p-2 rounded-lg border border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-50 text-xs font-semibold"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition"
          >
            <Plus className="w-3.5 h-3.5" />
            Add Test Review
          </button>
        </div>
      </div>

      {/* Reviews Table */}
      <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-100">
              <tr>
                <th className="py-3 px-4">Restaurant</th>
                <th className="py-3 px-4">Guest Diner</th>
                <th className="py-3 px-4">Rating</th>
                <th className="py-3 px-4">Feedback Comment</th>
                <th className="py-3 px-4">Date</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {reviews.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    {loading ? 'Fetching reviews from Supabase...' : 'No guest reviews recorded yet.'}
                  </td>
                </tr>
              ) : (
                reviews.map((r) => (
                  <tr key={r.review_id} className="hover:bg-slate-50/50 transition">
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {r.restaurant_name}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div className="font-semibold">{r.user_name}</div>
                      <div className="text-[10px] text-slate-400">{r.user_email || ''}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-1 text-amber-500 font-bold">
                        <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                        <span>{r.rating}.0</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-slate-700 max-w-sm">
                      <p className="line-clamp-2">{r.comment || 'No comment provided.'}</p>
                    </td>
                    <td className="py-3 px-4 text-slate-400 font-mono text-[11px]">
                      {r.created_at ? r.created_at.split('T')[0] : 'N/A'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => handleDelete(r.review_id)}
                        className="p-1.5 text-slate-400 hover:text-red-600 rounded"
                        title="Delete Review"
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

      {/* Add Review Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-xl border border-slate-200">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-sm text-slate-900">Add Diner Review</h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateReview} className="space-y-3.5 text-xs">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Outlet</label>
                <select
                  value={selectedRestId}
                  onChange={e => setSelectedRestId(e.target.value)}
                  className="w-full px-2.5 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                >
                  {restaurants.map(r => (
                    <option key={r.restaurant_id} value={r.restaurant_id}>
                      {r.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Rating (1 to 5 Stars)</label>
                <select
                  value={rating}
                  onChange={e => setRating(e.target.value)}
                  className="w-full px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-bold"
                >
                  <option value="5">★★★★★ (5 Stars)</option>
                  <option value="4">★★★★☆ (4 Stars)</option>
                  <option value="3">★★★☆☆ (3 Stars)</option>
                  <option value="2">★★☆☆☆ (2 Stars)</option>
                  <option value="1">★☆☆☆☆ (1 Star)</option>
                </select>
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase mb-1">Guest Comment</label>
                <textarea
                  rows={3}
                  required
                  value={comment}
                  onChange={e => setComment(e.target.value)}
                  className="w-full px-2.5 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs"
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-600 font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-4 py-1.5 rounded-lg bg-slate-900 text-white font-bold disabled:opacity-50"
                >
                  {submitting ? 'Saving...' : 'Publish Review'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
