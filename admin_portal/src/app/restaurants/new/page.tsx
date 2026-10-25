'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { 
  ArrowLeft, 
  Save, 
  Store, 
  MapPin, 
  Clock, 
  CreditCard, 
  ShieldCheck, 
  Tag, 
  Image as ImageIcon,
  CheckCircle2
} from 'lucide-react';
import { saveRestaurant } from '@/lib/data-service';
import { Restaurant } from '@/types';

export default function NewRestaurantPage() {
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [saveStatus, setSaveStatus] = useState<{
    show: boolean;
    savedToFirestore: boolean;
    restaurantId: string;
    error?: string;
  }>({ show: false, savedToFirestore: false, restaurantId: '' });

  // Form State
  const [name, setName] = useState('');
  const [upiId, setUpiId] = useState('');
  const [fssaiNumber, setFssaiNumber] = useState('');
  const [address, setAddress] = useState('');
  const [lat, setLat] = useState('18.5204');
  const [lng, setLng] = useState('73.8567');
  const [costForTwo, setCostForTwo] = useState('1200');
  const [cuisines, setCuisines] = useState('North Indian, Continental, Biryani');
  
  // Timings
  const [lunchOpen, setLunchOpen] = useState('11:30');
  const [lunchClose, setLunchClose] = useState('15:30');
  const [dinnerOpen, setDinnerOpen] = useState('19:00');
  const [dinnerClose, setDinnerClose] = useState('23:30');

  // Attributes
  const [isVegOnly, setIsVegOnly] = useState(false);
  const [hasBar, setHasBar] = useState(true);
  const [isAc, setIsAc] = useState(true);
  const [parkingAvailable, setParkingAvailable] = useState(true);

  // Visuals
  const [heroImage, setHeroImage] = useState('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1000&q=80');
  const [ambienceImages, setAmbienceImages] = useState('https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800&q=80');
  const [menuImages, setMenuImages] = useState('https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80');

  // Offers
  const [offerTitle, setOfferTitle] = useState('Flat 15% Off on Total Bill');
  const [offerValue, setOfferValue] = useState('15');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    const restaurantId = `res_${Date.now()}`;
    const today = new Date().toISOString().split('T')[0];

    const newRestaurant: Restaurant = {
      restaurant_id: restaurantId,
      name,
      upi_id: upiId,
      fssai_number: fssaiNumber,
      location: {
        address,
        geo_coordinates: [parseFloat(lat) || 0, parseFloat(lng) || 0]
      },
      cost_for_two: parseInt(costForTwo, 10) || 1000,
      timings: {
        lunch: { open: lunchOpen, close: lunchClose },
        dinner: { open: dinnerOpen, close: dinnerClose }
      },
      visuals: {
        hero_image: heroImage,
        ambience: ambienceImages.split(',').map(s => s.trim()).filter(Boolean),
        menu_images: menuImages.split(',').map(s => s.trim()).filter(Boolean)
      },
      attributes: {
        is_veg_only: isVegOnly,
        has_bar: hasBar,
        is_ac: isAc,
        parking_available: parkingAvailable
      },
      cuisines: cuisines.split(',').map(c => c.trim()).filter(Boolean),
      active_offers: offerTitle ? [
        {
          offer_id: `offer_${Date.now()}`,
          title: offerTitle,
          type: 'percentage',
          value: parseInt(offerValue, 10) || 10
        }
      ] : [],
      daily_slots: {
        [today]: {
          "19:00": 6,
          "19:30": 5,
          "20:00": 4,
          "20:30": 5,
          "21:00": 4
        }
      },
      rating: {
        average: 4.6,
        total_reviews: 1
      },
      status: 'ACTIVE',
      created_at: new Date().toISOString()
    };

    const result = await saveRestaurant(newRestaurant);
    setSubmitting(false);
    setSaveStatus({
      show: true,
      savedToFirestore: result.savedToFirestore,
      restaurantId: result.restaurantId,
      error: result.error,
    });

    setTimeout(() => {
      router.push('/restaurants');
    }, 2000);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Top Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/restaurants"
            className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 transition"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Onboard Partner Restaurant</h2>
            <p className="text-xs text-slate-500">Configure direct UPI payments, FSSAI registration, and daily slots</p>
          </div>
        </div>
      </div>

      {saveStatus.show && (
        <div className={`p-4 rounded-xl border flex flex-col gap-1.5 animate-fade-in ${
          saveStatus.savedToFirestore
            ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
            : 'bg-amber-50 border-amber-200 text-amber-900'
        }`}>
          <div className="flex items-center gap-2.5">
            <CheckCircle2 className={`w-5 h-5 ${saveStatus.savedToFirestore ? 'text-emerald-600' : 'text-amber-600'}`} />
            <span className="text-sm font-bold">
              {saveStatus.savedToFirestore
                ? `Saved to live Firebase Firestore! (Document ID: ${saveStatus.restaurantId})`
                : `Saved to local memory! (Document ID: ${saveStatus.restaurantId})`}
            </span>
          </div>
          {!saveStatus.savedToFirestore && (
            <p className="text-xs text-amber-800 ml-7.5">
              Notice: Portal is in local mock mode because live Firebase credentials are not in <code>.env.local</code>. To see data in Firebase Console, create <code>.env.local</code> with your project keys.
            </p>
          )}
        </div>
      )}

      {/* Form Container */}
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Section 1: Basic Information */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-slate-100 text-slate-800 font-bold text-base">
            <Store className="w-5 h-5 text-orange-600" />
            General Restaurant Information
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Restaurant Name *</label>
              <input
                type="text"
                required
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="e.g. Copper Chimney"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Cuisines (comma separated) *</label>
              <input
                type="text"
                required
                value={cuisines}
                onChange={e => setCuisines(e.target.value)}
                placeholder="North Indian, Mughlai, Biryani"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Average Cost for Two (₹) *</label>
              <input
                type="number"
                required
                value={costForTwo}
                onChange={e => setCostForTwo(e.target.value)}
                placeholder="1200"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Hero Image URL *</label>
              <input
                type="url"
                required
                value={heroImage}
                onChange={e => setHeroImage(e.target.value)}
                placeholder="https://..."
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
              />
            </div>
          </div>
        </div>

        {/* Section 2: Direct UPI & Compliance */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-slate-100 text-slate-800 font-bold text-base">
            <CreditCard className="w-5 h-5 text-orange-600" />
            Direct Merchant Settlements & Compliance
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Merchant UPI ID (Zero Platform Fee Settlement) *
              </label>
              <input
                type="text"
                required
                value={upiId}
                onChange={e => setUpiId(e.target.value)}
                placeholder="merchantname@icici / paytm"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800 font-mono"
              />
              <p className="text-[11px] text-slate-400 mt-1">Diners settle directly to this VPA via GPay / PhonePe</p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                14-Digit FSSAI Registration Number *
              </label>
              <input
                type="text"
                required
                value={fssaiNumber}
                onChange={e => setFssaiNumber(e.target.value)}
                placeholder="11521034000123"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800 font-mono"
              />
            </div>
          </div>
        </div>

        {/* Section 3: Location */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-slate-100 text-slate-800 font-bold text-base">
            <MapPin className="w-5 h-5 text-orange-600" />
            Location & Coordinates
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Full Street Address *</label>
              <textarea
                required
                rows={2}
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="Shop No. 4, Camp Road, Pune, Maharashtra"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-orange-500 focus:bg-white text-slate-800"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Latitude</label>
                <input
                  type="text"
                  value={lat}
                  onChange={e => setLat(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-mono text-slate-800"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Longitude</label>
                <input
                  type="text"
                  value={lng}
                  onChange={e => setLng(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-mono text-slate-800"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Section 4: Timings & Attributes */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center gap-2 pb-3 border-b border-slate-100 text-slate-800 font-bold text-base">
            <Clock className="w-5 h-5 text-orange-600" />
            Timings & Amenities
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Lunch Open</label>
              <input
                type="time"
                value={lunchOpen}
                onChange={e => setLunchOpen(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Lunch Close</label>
              <input
                type="time"
                value={lunchClose}
                onChange={e => setLunchClose(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Dinner Open</label>
              <input
                type="time"
                value={dinnerOpen}
                onChange={e => setDinnerOpen(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Dinner Close</label>
              <input
                type="time"
                value={dinnerClose}
                onChange={e => setDinnerClose(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 pt-3">
            <label className="flex items-center gap-2 p-3 bg-slate-50 rounded-xl border border-slate-200 cursor-pointer">
              <input
                type="checkbox"
                checked={isVegOnly}
                onChange={e => setIsVegOnly(e.target.checked)}
                className="w-4 h-4 text-emerald-600 rounded"
              />
              <span className="text-xs font-medium text-slate-800">Pure Veg Only</span>
            </label>
            <label className="flex items-center gap-2 p-3 bg-slate-50 rounded-xl border border-slate-200 cursor-pointer">
              <input
                type="checkbox"
                checked={hasBar}
                onChange={e => setHasBar(e.target.checked)}
                className="w-4 h-4 text-orange-600 rounded"
              />
              <span className="text-xs font-medium text-slate-800">Has Bar / Cocktails</span>
            </label>
            <label className="flex items-center gap-2 p-3 bg-slate-50 rounded-xl border border-slate-200 cursor-pointer">
              <input
                type="checkbox"
                checked={isAc}
                onChange={e => setIsAc(e.target.checked)}
                className="w-4 h-4 text-orange-600 rounded"
              />
              <span className="text-xs font-medium text-slate-800">Air Conditioned</span>
            </label>
            <label className="flex items-center gap-2 p-3 bg-slate-50 rounded-xl border border-slate-200 cursor-pointer">
              <input
                type="checkbox"
                checked={parkingAvailable}
                onChange={e => setParkingAvailable(e.target.checked)}
                className="w-4 h-4 text-orange-600 rounded"
              />
              <span className="text-xs font-medium text-slate-800">Valet Parking</span>
            </label>
          </div>
        </div>

        {/* Submit Actions */}
        <div className="flex items-center justify-end gap-3 pt-4">
          <Link
            href="/restaurants"
            className="px-5 py-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-sm font-medium transition"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-500 text-white font-semibold text-sm transition shadow-lg shadow-orange-600/30 disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            {submitting ? 'Saving to Firestore...' : 'Save & Activate Restaurant'}
          </button>
        </div>
      </form>
    </div>
  );
}
