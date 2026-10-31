import { supabaseAdmin, supabase, EDGE_FUNCTIONS } from './supabase';
import { 
  Restaurant, 
  Booking, 
  DailySlot, 
  Review, 
  UserProfile, 
  DashboardStats,
  BookingStatus 
} from '@/types';

// ==========================================
// 1. RESTAURANTS CRUD & ONBOARDING
// ==========================================

export async function getRestaurants(): Promise<Restaurant[]> {
  const { data, error } = await supabaseAdmin
    .from('restaurants')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching restaurants from Supabase:', error);
    throw new Error(error.message);
  }

  return (data || []).map((row) => ({
    ...row,
    cuisines: Array.isArray(row.cuisines) ? row.cuisines : [],
    status: row.status || 'ACTIVE',
  })) as Restaurant[];
}

export async function getRestaurantById(restaurantId: string): Promise<Restaurant | null> {
  const { data, error } = await supabaseAdmin
    .from('restaurants')
    .select('*')
    .eq('restaurant_id', restaurantId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    console.error('Error fetching restaurant by ID:', error);
    throw new Error(error.message);
  }

  return data as Restaurant;
}

export interface OnboardRestaurantPayload {
  name: string;
  owner_name: string;
  email: string;
  phone: string;
  password?: string;
  address: string;
  fssai_number: string;
  upi_id?: string;
  cost_for_two: number;
  cuisines: string[];
  lunch_open?: string;
  lunch_close?: string;
  dinner_open?: string;
  dinner_close?: string;
  pure_veg?: boolean;
  serves_alcohol?: boolean;
  has_ac?: boolean;
  has_parking?: boolean;
  hero_image?: string;
  ambience?: string[];
  active_offers?: any[];
}

export async function onboardRestaurant(payload: OnboardRestaurantPayload): Promise<{
  restaurant: Restaurant;
  owner_id?: string;
  manager_credentials?: { email: string; default_password: string };
}> {
  const ownerPassword = payload.password || 'Restaurant@2026';
  
  // 1. Call signup-owner Edge Function to provision Owner Auth & default Manager Auth
  let edgeFunctionResult: any = null;
  try {
    const res = await fetch(EDGE_FUNCTIONS.signupOwner, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
      },
      body: jsonSafeStringify({
        name: payload.name.trim(),
        owner_name: payload.owner_name.trim(),
        email: payload.email.trim().toLowerCase(),
        password: ownerPassword,
        phone: payload.phone.trim(),
      }),
    });
    
    if (res.ok) {
      edgeFunctionResult = await res.json();
    } else {
      const errJson = await res.json().catch(() => ({}));
      console.warn('Edge function returned non-200:', errJson);
    }
  } catch (err) {
    console.warn('Edge function call failed, falling back to direct database insertion:', err);
  }

  const generatedRestId = edgeFunctionResult?.restaurant_id || 
    `res_${payload.name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${Math.floor(1000 + Math.random() * 9000)}`;

  const managerEmail = `manager.${generatedRestId}@booknbytes.app`;
  const managerPassword = 'AmitYashLogic@1999';

  const fullRestaurantData = {
    restaurant_id: generatedRestId,
    name: payload.name.trim(),
    upi_id: payload.upi_id?.trim() || `${payload.name.toLowerCase().replace(/[^a-z0-9]/g, '')}@upi`,
    fssai_number: payload.fssai_number.trim(),
    address: payload.address.trim(),
    cost_for_two: payload.cost_for_two || 1200,
    timings: {
      lunch: { open: payload.lunch_open || '11:30 AM', close: payload.lunch_close || '03:30 PM' },
      dinner: { open: payload.dinner_open || '07:00 PM', close: payload.dinner_close || '11:30 PM' },
    },
    visuals: {
      hero_image: payload.hero_image || 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
      ambience: payload.ambience || [
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=800&q=80',
      ],
      menu_images: [],
    },
    attributes: {
      pure_veg: Boolean(payload.pure_veg),
      serves_alcohol: Boolean(payload.serves_alcohol),
      has_ac: payload.has_ac !== undefined ? Boolean(payload.has_ac) : true,
      has_parking: payload.has_parking !== undefined ? Boolean(payload.has_parking) : true,
    },
    cuisines: payload.cuisines && payload.cuisines.length > 0 ? payload.cuisines : ['North Indian', 'Biryani'],
    active_offers: payload.active_offers || [
      { offer_id: 'taste15', title: '15% Off All Slots', type: 'percentage', value: 15 }
    ],
    rating: { average: 4.8, total_reviews: 24 },
    status: 'ACTIVE',
    owners_details: {
      owner_id: edgeFunctionResult?.owner_id || null,
      name: payload.owner_name,
      email: payload.email,
      phone: payload.phone,
      manager_credentials: {
        email: managerEmail,
        default_password: managerPassword,
      },
    },
    created_at: new Date().toISOString(),
  };

  // Upsert into Supabase restaurants table using admin service client
  const { data: inserted, error: insertError } = await supabaseAdmin
    .from('restaurants')
    .upsert(fullRestaurantData, { onConflict: 'restaurant_id' })
    .select()
    .single();

  if (insertError) {
    console.error('Error inserting restaurant into Supabase:', insertError);
    throw new Error(insertError.message);
  }

  // Pre-seed initial table slots for the restaurant
  try {
    await seedInitialSlotsForRestaurant(generatedRestId);
  } catch (slotErr) {
    console.warn('Initial slot generation note:', slotErr);
  }

  return {
    restaurant: inserted as Restaurant,
    owner_id: edgeFunctionResult?.owner_id,
    manager_credentials: {
      email: managerEmail,
      default_password: managerPassword,
    },
  };
}

export async function updateRestaurant(
  restaurantId: string, 
  updates: Partial<Restaurant>
): Promise<Restaurant> {
  const { data, error } = await supabaseAdmin
    .from('restaurants')
    .update(updates)
    .eq('restaurant_id', restaurantId)
    .select()
    .single();

  if (error) {
    console.error('Error updating restaurant:', error);
    throw new Error(error.message);
  }

  return data as Restaurant;
}

export async function toggleRestaurantStatus(
  restaurantId: string, 
  newStatus: 'ACTIVE' | 'INACTIVE'
): Promise<void> {
  const { error } = await supabaseAdmin
    .from('restaurants')
    .update({ status: newStatus })
    .eq('restaurant_id', restaurantId);

  if (error) throw new Error(error.message);
}

export async function deleteRestaurant(restaurantId: string): Promise<void> {
  // Cascading cleanup of slots and bookings for this restaurant
  await supabaseAdmin.from('daily_slots').delete().eq('restaurant_id', restaurantId);
  await supabaseAdmin.from('bookings').delete().eq('restaurant_id', restaurantId);
  await supabaseAdmin.from('reviews').delete().eq('restaurant_id', restaurantId);

  const { error } = await supabaseAdmin
    .from('restaurants')
    .delete()
    .eq('restaurant_id', restaurantId);

  if (error) throw new Error(error.message);
}

// ==========================================
// 2. BOOKINGS CRUD OPERATIONS
// ==========================================

export async function getBookings(): Promise<Booking[]> {
  const { data, error } = await supabaseAdmin
    .from('bookings')
    .select('*, users(name, phone_number, email)')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching bookings:', error);
    throw new Error(error.message);
  }

  return (data || []) as Booking[];
}

export async function updateBookingStatus(
  bookingId: string, 
  status: BookingStatus
): Promise<void> {
  const { error } = await supabaseAdmin
    .from('bookings')
    .update({ status })
    .eq('booking_id', bookingId);

  if (error) throw new Error(error.message);
}

export async function deleteBooking(bookingId: string): Promise<void> {
  const { error } = await supabaseAdmin
    .from('bookings')
    .delete()
    .eq('booking_id', bookingId);

  if (error) throw new Error(error.message);
}

export async function createBooking(payload: {
  restaurant_id: string;
  restaurant_name: string;
  party_size: number;
  booking_date: string;
  time_slot: string;
  status?: BookingStatus;
  user_id?: string;
  applied_offer?: string;
}): Promise<Booking> {
  // Resolve or pick default diner
  const userId = payload.user_id || '6d03741d-db04-4370-bc49-bbb1149a5c33';
  const bookingId = `bk_${Date.now().toString().slice(-6)}`;

  const { data, error } = await supabaseAdmin
    .from('bookings')
    .insert({
      booking_id: bookingId,
      user_id: userId,
      restaurant_id: payload.restaurant_id,
      restaurant_name: payload.restaurant_name,
      party_size: payload.party_size,
      booking_date: payload.booking_date,
      time_slot: payload.time_slot,
      status: payload.status || 'CONFIRMED',
      applied_offer: payload.applied_offer || null,
      created_at: new Date().toISOString(),
    })
    .select('*, users(name, phone_number, email)')
    .single();

  if (error) throw new Error(error.message);
  return data as Booking;
}

// ==========================================
// 3. DAILY SLOTS CRUD
// ==========================================

export async function getAllSlots(): Promise<DailySlot[]> {
  const { data, error } = await supabaseAdmin
    .from('daily_slots')
    .select('*, restaurants(name)')
    .order('start_datetime', { ascending: true });

  if (error) throw new Error(error.message);

  return (data || []).map((row: any) => ({
    slot_id: row.slot_id,
    restaurant_id: row.restaurant_id,
    start_datetime: row.start_datetime,
    end_datetime: row.end_datetime,
    discount_percentage: Number(row.discount_percentage) || 0,
    capacity: row.capacity || 10,
    restaurant_name: row.restaurants?.name || row.restaurant_id,
  }));
}

export async function getSlotsByRestaurant(restaurantId: string): Promise<DailySlot[]> {
  const { data, error } = await supabaseAdmin
    .from('daily_slots')
    .select('*')
    .eq('restaurant_id', restaurantId)
    .order('start_datetime', { ascending: true });

  if (error) throw new Error(error.message);
  return data as DailySlot[];
}

export async function createSlot(slot: {
  restaurant_id: string;
  start_datetime: string;
  end_datetime: string;
  discount_percentage: number;
  capacity: number;
}): Promise<DailySlot> {
  const { data, error } = await supabaseAdmin
    .from('daily_slots')
    .insert(slot)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data as DailySlot;
}

export async function updateSlot(
  slotId: string, 
  updates: Partial<DailySlot>
): Promise<DailySlot> {
  const { data, error } = await supabaseAdmin
    .from('daily_slots')
    .update(updates)
    .eq('slot_id', slotId)
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data as DailySlot;
}

export async function deleteSlot(slotId: string): Promise<void> {
  const { error } = await supabaseAdmin
    .from('daily_slots')
    .delete()
    .eq('slot_id', slotId);

  if (error) throw new Error(error.message);
}

async function seedInitialSlotsForRestaurant(restaurantId: string): Promise<void> {
  const now = new Date();
  const times = [
    { start: '12:00:00', end: '13:30:00', discount: 15 },
    { start: '13:30:00', end: '15:00:00', discount: 20 },
    { start: '19:00:00', end: '20:30:00', discount: 10 },
    { start: '20:30:00', end: '22:00:00', discount: 15 },
    { start: '22:00:00', end: '23:30:00', discount: 25 },
  ];

  const dateStr = now.toISOString().split('T')[0];
  const slotsToInsert = times.map((t) => ({
    restaurant_id: restaurantId,
    start_datetime: `${dateStr}T${t.start}+00:00`,
    end_datetime: `${dateStr}T${t.end}+00:00`,
    discount_percentage: t.discount,
    capacity: 12,
  }));

  await supabaseAdmin.from('daily_slots').insert(slotsToInsert);
}

// ==========================================
// 4. REVIEWS & RATINGS CRUD
// ==========================================

export async function getReviews(): Promise<Review[]> {
  const { data, error } = await supabaseAdmin
    .from('reviews')
    .select('*, restaurants(name), users(name, email)')
    .order('created_at', { ascending: false });

  if (error) throw new Error(error.message);

  return (data || []).map((row: any) => ({
    review_id: row.review_id,
    restaurant_id: row.restaurant_id,
    user_id: row.user_id,
    rating: row.rating,
    comment: row.comment,
    created_at: row.created_at,
    updated_at: row.updated_at,
    restaurant_name: row.restaurants?.name || row.restaurant_id,
    user_name: row.users?.name || 'Anonymous Diner',
    user_email: row.users?.email || '',
  }));
}

export async function deleteReview(reviewId: string): Promise<void> {
  const { error } = await supabaseAdmin
    .from('reviews')
    .delete()
    .eq('review_id', reviewId);

  if (error) throw new Error(error.message);
}

export async function createReview(payload: {
  restaurant_id: string;
  user_id?: string;
  rating: number;
  comment: string;
}): Promise<void> {
  const userId = payload.user_id || '6d03741d-db04-4370-bc49-bbb1149a5c33';
  const { error } = await supabaseAdmin.from('reviews').insert({
    restaurant_id: payload.restaurant_id,
    user_id: userId,
    rating: payload.rating,
    comment: payload.comment,
    created_at: new Date().toISOString(),
  });

  if (error) throw new Error(error.message);
}

// ==========================================
// 5. USERS DIRECTORY CRUD
// ==========================================

export async function getUsers(): Promise<UserProfile[]> {
  const { data, error } = await supabaseAdmin
    .from('users')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw new Error(error.message);

  return (data || []).map((u: any) => ({
    user_id: u.user_id,
    name: u.name || 'Unnamed Diner',
    phone_number: u.phone_number || 'N/A',
    email: u.email || 'N/A',
    preferences: Array.isArray(u.preferences) ? u.preferences : [],
    total_bookings: u.total_bookings || 0,
    created_at: u.created_at,
    updated_at: u.updated_at,
  }));
}

export async function deleteUser(userId: string): Promise<void> {
  const { error } = await supabaseAdmin
    .from('users')
    .delete()
    .eq('user_id', userId);

  if (error) throw new Error(error.message);
}

// ==========================================
// 6. DASHBOARD AGGREGATED METRICS
// ==========================================

export async function getDashboardStats(): Promise<DashboardStats> {
  const [restaurantsRes, bookingsRes, usersRes, reviewsRes] = await Promise.all([
    supabaseAdmin.from('restaurants').select('restaurant_id, status'),
    supabaseAdmin.from('bookings').select('booking_id, status, booking_date'),
    supabaseAdmin.from('users').select('user_id'),
    supabaseAdmin.from('reviews').select('review_id, rating'),
  ]);

  const restaurants = restaurantsRes.data || [];
  const bookings = bookingsRes.data || [];
  const users = usersRes.data || [];
  const reviews = reviewsRes.data || [];

  const todayStr = new Date().toISOString().split('T')[0];

  const totalRestaurants = restaurants.length;
  const activeRestaurants = restaurants.filter(r => r.status === 'ACTIVE').length;
  const totalBookings = bookings.length;
  const confirmedBookings = bookings.filter(b => b.status === 'CONFIRMED' || b.status === 'COMPLETED').length;
  const todayBookings = bookings.filter(b => b.booking_date === todayStr).length;
  const totalUsers = users.length;
  const totalReviews = reviews.length;
  
  const avgRating = totalReviews > 0
    ? (reviews.reduce((acc, r) => acc + (Number(r.rating) || 0), 0) / totalReviews).toFixed(1)
    : '4.8';

  return {
    totalRestaurants,
    activeRestaurants,
    totalBookings,
    confirmedBookings,
    totalUsers,
    todayBookings,
    totalReviews,
    averageRating: parseFloat(avgRating),
  };
}

function jsonSafeStringify(obj: any): string {
  return JSON.stringify(obj);
}
