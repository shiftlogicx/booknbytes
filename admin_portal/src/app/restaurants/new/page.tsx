'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  ArrowLeft, 
  Store, 
  CheckCircle2, 
  ShieldCheck, 
  CreditCard, 
  Clock, 
  Lock, 
  Mail, 
  Phone, 
  User, 
  MapPin, 
  Utensils, 
  Percent, 
  KeyRound, 
  Copy, 
  Check
} from 'lucide-react';
import { onboardRestaurant } from '@/lib/data-service';

export default function NewRestaurantPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [copiedField, setCopiedField] = useState<string | null>(null);

  // Success modal / result
  const [createdData, setCreatedData] = useState<{
    restaurantId: string;
    restaurantName: string;
    ownerEmail: string;
    managerEmail: string;
    managerPass: string;
  } | null>(null);

  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Form Fields
  const [restaurantName, setRestaurantName] = useState('');
  const [ownerName, setOwnerName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('+91 98');
  const [password, setPassword] = useState('Restaurant@2026');
  const [address, setAddress] = useState('');
  const [fssaiNumber, setFssaiNumber] = useState('11521034000123');
  const [upiId, setUpiId] = useState('');
  const [costForTwo, setCostForTwo] = useState('1200');
  const [cuisines, setCuisines] = useState('North Indian, Continental, Biryani');

  // Timings
  const [lunchOpen, setLunchOpen] = useState('11:30 AM');
  const [lunchClose, setLunchClose] = useState('03:30 PM');
  const [dinnerOpen, setDinnerOpen] = useState('07:00 PM');
  const [dinnerClose, setDinnerClose] = useState('11:30 PM');

  // Attributes
  const [pureVeg, setPureVeg] = useState(false);
  const [servesAlcohol, setServesAlcohol] = useState(true);
  const [hasAc, setHasAc] = useState(true);
  const [hasParking, setHasParking] = useState(true);

  // Promo Offer
  const [promoTitle, setPromoTitle] = useState('15% Off All Table Bookings');
  const [promoDiscount, setPromoDiscount] = useState('15');

  // Validation checks
  const isEmailValid = email.includes('@') && email.includes('.');
  const hasMinLength = password.length >= 6;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  const isPasswordValid = hasMinLength && hasUpper && hasLower && hasSpecial;

  const handleCopy = (text: string, field: string) => {
    navigator.clipboard.writeText(text);
    setCopiedField(field);
    setTimeout(() => setCopiedField(null), 2000);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    if (!restaurantName.trim() || !ownerName.trim()) {
      setErrorMsg('Please enter both Restaurant Name and Owner Name.');
      return;
    }

    if (!isEmailValid) {
      setErrorMsg('Please enter a valid email address with @ (e.g. owner@restaurant.com).');
      return;
    }

    if (!isPasswordValid) {
      setErrorMsg('Password must be at least 6 characters, and contain uppercase, lowercase, and special characters.');
      return;
    }

    setLoading(true);
    try {
      const result = await onboardRestaurant({
        name: restaurantName.trim(),
        owner_name: ownerName.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        password,
        address: address.trim() || 'High Street, Pune',
        fssai_number: fssaiNumber.trim() || '11521034000123',
        upi_id: upiId.trim() || `${restaurantName.toLowerCase().replace(/[^a-z0-9]/g, '')}@upi`,
        cost_for_two: parseInt(costForTwo, 10) || 1200,
        cuisines: cuisines.split(',').map(c => c.trim()).filter(Boolean),
        lunch_open: lunchOpen,
        lunch_close: lunchClose,
        dinner_open: dinnerOpen,
        dinner_close: dinnerClose,
        pure_veg: pureVeg,
        serves_alcohol: servesAlcohol,
        has_ac: hasAc,
        has_parking: hasParking,
        active_offers: [
          { offer_id: 'promo_default', title: promoTitle, type: 'percentage', value: parseInt(promoDiscount, 10) || 15 }
        ]
      });

      setCreatedData({
        restaurantId: result.restaurant.restaurant_id,
        restaurantName: result.restaurant.name,
        ownerEmail: email.trim().toLowerCase(),
        managerEmail: result.manager_credentials?.email || `manager.${result.restaurant.restaurant_id}@booknbytes.app`,
        managerPass: result.manager_credentials?.default_password || 'AmitYashLogic@1999',
      });
    } catch (err: any) {
      console.error('Onboarding failed:', err);
      setErrorMsg(err.message || 'Failed to onboard restaurant to Supabase. Check console logs.');
    } finally {
      setLoading(false);
    }
  };

  if (createdData) {
    return (
      <div className="max-w-2xl mx-auto py-8">
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-8 text-center space-y-6">
          <div className="w-14 h-14 rounded-full bg-emerald-50 border border-emerald-200 flex items-center justify-center mx-auto text-emerald-600">
            <CheckCircle2 className="w-8 h-8" />
          </div>

          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
              Onboarded & Published to Supabase
            </span>
            <h2 className="text-xl font-extrabold text-slate-900 mt-2">
              {createdData.restaurantName} is Live!
            </h2>
            <p className="text-xs text-slate-500 mt-1">
              Assigned ID: <code className="font-mono text-slate-800 font-bold bg-slate-100 px-1.5 py-0.5 rounded">{createdData.restaurantId}</code>
            </p>
          </div>

          {/* Credentials Box */}
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-200 text-left space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-200 pb-2.5">
              <KeyRound className="w-4 h-4 text-slate-700" />
              <h3 className="text-xs font-bold text-slate-900">Provisioned Merchant Credentials</h3>
            </div>

            {/* Owner credentials */}
            <div className="flex items-center justify-between text-xs">
              <div>
                <span className="text-[10px] font-bold text-slate-400 uppercase">Owner Login Email</span>
                <div className="font-mono text-slate-800 font-bold">{createdData.ownerEmail}</div>
              </div>
              <button
                onClick={() => handleCopy(createdData.ownerEmail, 'owner_email')}
                className="p-1.5 text-slate-500 hover:text-slate-900 rounded bg-white border border-slate-200"
              >
                {copiedField === 'owner_email' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>

            {/* Manager ID */}
            <div className="flex items-center justify-between text-xs pt-2 border-t border-slate-200/60">
              <div>
                <span className="text-[10px] font-bold text-slate-400 uppercase">Floor Manager Email</span>
                <div className="font-mono text-slate-800 font-bold">{createdData.managerEmail}</div>
              </div>
              <button
                onClick={() => handleCopy(createdData.managerEmail, 'manager_email')}
                className="p-1.5 text-slate-500 hover:text-slate-900 rounded bg-white border border-slate-200"
              >
                {copiedField === 'manager_email' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>

            {/* Manager Password */}
            <div className="flex items-center justify-between text-xs pt-2 border-t border-slate-200/60">
              <div>
                <span className="text-[10px] font-bold text-slate-400 uppercase">Manager Default Password</span>
                <div className="font-mono text-emerald-700 font-bold">{createdData.managerPass}</div>
              </div>
              <button
                onClick={() => handleCopy(createdData.managerPass, 'manager_pass')}
                className="p-1.5 text-slate-500 hover:text-slate-900 rounded bg-white border border-slate-200"
              >
                {copiedField === 'manager_pass' ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3 pt-2">
            <Link
              href="/restaurants"
              className="px-4 py-2 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition"
            >
              View in Restaurants Directory
            </Link>
            <button
              onClick={() => {
                setCreatedData(null);
                setRestaurantName('');
                setEmail('');
              }}
              className="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition"
            >
              Onboard Another Outlet
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-16 font-sans">
      {/* Top Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/restaurants"
            className="p-2 rounded-lg border border-slate-200 text-slate-500 hover:text-slate-900 hover:bg-slate-50 transition"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <div>
            <h1 className="text-lg font-extrabold text-slate-900 tracking-tight">Onboard Restaurant Partner</h1>
            <p className="text-xs text-slate-500">Add merchant details & publish directly to Supabase live tables</p>
          </div>
        </div>
      </div>

      {errorMsg && (
        <div className="p-3.5 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold">
          {errorMsg}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Section 1: Basic Restaurant Info */}
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm p-6 space-y-4">
          <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
            <Store className="w-4 h-4 text-emerald-600" />
            <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Outlet Details</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Restaurant Name *
              </label>
              <input
                type="text"
                required
                value={restaurantName}
                onChange={(e) => setRestaurantName(e.target.value)}
                placeholder="e.g. Copper Chimney Bistro"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Cuisines (comma-separated) *
              </label>
              <input
                type="text"
                value={cuisines}
                onChange={(e) => setCuisines(e.target.value)}
                placeholder="North Indian, Biryani, Mughlai"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Outlet Street Address *
              </label>
              <input
                type="text"
                required
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="e.g. Plot 42, Koregaon Park Road, Pune"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Cost for Two (₹)
              </label>
              <input
                type="number"
                value={costForTwo}
                onChange={(e) => setCostForTwo(e.target.value)}
                placeholder="1200"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                14-Digit FSSAI License Number
              </label>
              <input
                type="text"
                value={fssaiNumber}
                onChange={(e) => setFssaiNumber(e.target.value)}
                placeholder="11521034000123"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Merchant Settlement UPI VPA ID
              </label>
              <input
                type="text"
                value={upiId}
                onChange={(e) => setUpiId(e.target.value)}
                placeholder="copperchimney@icici"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>
          </div>
        </div>

        {/* Section 2: Owner Account & Security */}
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm p-6 space-y-4">
          <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
            <User className="w-4 h-4 text-emerald-600" />
            <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Owner Account & Security</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Owner Full Name *
              </label>
              <input
                type="text"
                required
                value={ownerName}
                onChange={(e) => setOwnerName(e.target.value)}
                placeholder="e.g. Vikram Malhotra"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Business Email * (Must contain @)
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="owner@copperchimney.com"
                className={`w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border transition ${
                  email && !isEmailValid ? 'border-red-300 focus:ring-red-400' : 'border-slate-200 focus:ring-emerald-500'
                }`}
              />
              {email && !isEmailValid && (
                <p className="text-[10px] text-red-600 mt-1 font-semibold">Please enter a valid email containing "@" and domain.</p>
              )}
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Contact Phone Number *
              </label>
              <input
                type="text"
                required
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+91 98765 43210"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Owner Initial Password *
              </label>
              <input
                type="text"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="e.g. Restaurant@2026"
                className={`w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs font-mono rounded-lg border transition ${
                  password && !isPasswordValid ? 'border-amber-300 focus:ring-amber-400' : 'border-slate-200 focus:ring-emerald-500'
                }`}
              />
            </div>
          </div>

          {/* Password Validation Checklist */}
          <div className="bg-slate-50 rounded-lg p-3 border border-slate-200 text-xs space-y-1.5">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Security Criteria</span>
            <div className="flex flex-wrap gap-2 text-[11px]">
              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded ${hasMinLength ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-200 text-slate-600'}`}>
                {hasMinLength ? '✓' : '•'} 6+ Characters
              </span>
              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded ${hasUpper ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-200 text-slate-600'}`}>
                {hasUpper ? '✓' : '•'} Uppercase (A-Z)
              </span>
              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded ${hasLower ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-200 text-slate-600'}`}>
                {hasLower ? '✓' : '•'} Lowercase (a-z)
              </span>
              <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded ${hasSpecial ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-200 text-slate-600'}`}>
                {hasSpecial ? '✓' : '•'} Special Char (!@#...)
              </span>
            </div>
          </div>
        </div>

        {/* Section 3: Operating Hours & Floor Attributes */}
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm p-6 space-y-4">
          <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
            <Clock className="w-4 h-4 text-emerald-600" />
            <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Service Timings & Features</h2>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
            <div>
              <label className="text-[10px] font-bold text-slate-500 uppercase">Lunch Open</label>
              <input
                type="text"
                value={lunchOpen}
                onChange={(e) => setLunchOpen(e.target.value)}
                className="w-full mt-1 px-2.5 py-1.5 bg-slate-50 rounded border border-slate-200 text-xs"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-500 uppercase">Lunch Close</label>
              <input
                type="text"
                value={lunchClose}
                onChange={(e) => setLunchClose(e.target.value)}
                className="w-full mt-1 px-2.5 py-1.5 bg-slate-50 rounded border border-slate-200 text-xs"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-500 uppercase">Dinner Open</label>
              <input
                type="text"
                value={dinnerOpen}
                onChange={(e) => setDinnerOpen(e.target.value)}
                className="w-full mt-1 px-2.5 py-1.5 bg-slate-50 rounded border border-slate-200 text-xs"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-500 uppercase">Dinner Close</label>
              <input
                type="text"
                value={dinnerClose}
                onChange={(e) => setDinnerClose(e.target.value)}
                className="w-full mt-1 px-2.5 py-1.5 bg-slate-50 rounded border border-slate-200 text-xs"
              />
            </div>
          </div>

          {/* Toggle Attributes */}
          <div className="pt-2 grid grid-cols-2 sm:grid-cols-4 gap-3">
            <label className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-200 bg-slate-50/50 cursor-pointer text-xs font-semibold text-slate-700">
              <input
                type="checkbox"
                checked={pureVeg}
                onChange={(e) => setPureVeg(e.target.checked)}
                className="rounded text-emerald-600 focus:ring-emerald-500"
              />
              Pure Veg Only
            </label>

            <label className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-200 bg-slate-50/50 cursor-pointer text-xs font-semibold text-slate-700">
              <input
                type="checkbox"
                checked={servesAlcohol}
                onChange={(e) => setServesAlcohol(e.target.checked)}
                className="rounded text-emerald-600 focus:ring-emerald-500"
              />
              Serves Alcohol
            </label>

            <label className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-200 bg-slate-50/50 cursor-pointer text-xs font-semibold text-slate-700">
              <input
                type="checkbox"
                checked={hasAc}
                onChange={(e) => setHasAc(e.target.checked)}
                className="rounded text-emerald-600 focus:ring-emerald-500"
              />
              AC Seating
            </label>

            <label className="flex items-center gap-2 p-2.5 rounded-lg border border-slate-200 bg-slate-50/50 cursor-pointer text-xs font-semibold text-slate-700">
              <input
                type="checkbox"
                checked={hasParking}
                onChange={(e) => setHasParking(e.target.checked)}
                className="rounded text-emerald-600 focus:ring-emerald-500"
              />
              Valet / Parking
            </label>
          </div>
        </div>

        {/* Section 4: Initial Promotional Offer */}
        <div className="bg-white rounded-xl border border-slate-200/80 shadow-sm p-6 space-y-4">
          <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
            <Percent className="w-4 h-4 text-emerald-600" />
            <h2 className="text-xs font-bold text-slate-900 uppercase tracking-wider">Initial Launch Offer</h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="sm:col-span-2">
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Offer Title
              </label>
              <input
                type="text"
                value={promoTitle}
                onChange={(e) => setPromoTitle(e.target.value)}
                placeholder="Flat 15% Off on All Bill Sizes"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200"
              />
            </div>
            <div>
              <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-1">
                Discount Percentage (%)
              </label>
              <input
                type="number"
                value={promoDiscount}
                onChange={(e) => setPromoDiscount(e.target.value)}
                placeholder="15"
                className="w-full px-3 py-2 bg-slate-50 text-slate-900 text-xs rounded-lg border border-slate-200"
              />
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="flex items-center justify-end gap-3 pt-4">
          <Link
            href="/restaurants"
            className="px-4 py-2.5 rounded-lg border border-slate-300 text-slate-700 hover:bg-slate-50 text-xs font-bold transition"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2.5 rounded-lg bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-sm transition disabled:opacity-50 flex items-center gap-2"
          >
            {loading ? (
              <>
                <span className="w-3.5 h-3.5 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                Publishing to Supabase...
              </>
            ) : (
              <>
                <CheckCircle2 className="w-4 h-4" />
                Publish & Onboard Restaurant
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
