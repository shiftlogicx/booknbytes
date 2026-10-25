import { db } from './firebase';
import { 
  collection, 
  getDocs, 
  doc, 
  getDoc, 
  setDoc, 
  updateDoc, 
  deleteDoc, 
  query, 
  orderBy, 
  limit, 
  where 
} from 'firebase/firestore';
import { Restaurant, Booking, UserProfile, DashboardStats } from '@/types';

// Mock seed data directly from the specification document
export const INITIAL_RESTAURANTS: Restaurant[] = [
  {
    restaurant_id: "res_12345xyz",
    name: "Mahesh Lunch Home",
    upi_id: "maheshlunch@sbi",
    fssai_number: "11521034000123",
    location: {
      address: "Camp, Pune, Maharashtra",
      geo_coordinates: [18.5196, 73.8773]
    },
    cost_for_two: 1200,
    timings: {
      lunch: { open: "11:30", close: "15:30" },
      dinner: { open: "19:00", close: "23:30" }
    },
    visuals: {
      hero_image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1000&q=80",
      ambience: [
        "https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80"
      ],
      menu_images: [
        "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80"
      ]
    },
    attributes: {
      is_veg_only: false,
      has_bar: true,
      is_ac: true,
      parking_available: true
    },
    cuisines: ["Seafood", "Mangalorean", "North Indian"],
    active_offers: [
      { offer_id: "flat_10", title: "Flat 10% Off on Total Bill", type: "percentage", value: 10 },
      { offer_id: "dineout_20", title: "Flat 20% Early Bird", type: "percentage", value: 20 }
    ],
    daily_slots: {
      "2026-10-25": { "19:00": 5, "19:30": 3, "20:00": 0, "20:30": 4, "21:00": 2 },
      "2026-10-26": { "19:00": 6, "19:30": 5, "20:00": 4, "20:30": 3, "21:00": 5 }
    },
    rating: {
      average: 4.5,
      total_reviews: 128
    },
    status: "ACTIVE"
  },
  {
    restaurant_id: "res_67890abc",
    name: "The Bombay Canteen",
    upi_id: "bombaycanteen@icici",
    fssai_number: "11521034000555",
    location: {
      address: "Lower Parel, Mumbai, Maharashtra",
      geo_coordinates: [19.0028, 72.8295]
    },
    cost_for_two: 2200,
    timings: {
      lunch: { open: "12:00", close: "15:30" },
      dinner: { open: "19:00", close: "01:00" }
    },
    visuals: {
      hero_image: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1000&q=80",
      ambience: [
        "https://images.unsplash.com/photo-1578474846511-04ba529f0b88?auto=format&fit=crop&w=800&q=80"
      ],
      menu_images: [
        "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80"
      ]
    },
    attributes: {
      is_veg_only: false,
      has_bar: true,
      is_ac: true,
      parking_available: true
    },
    cuisines: ["Modern Indian", "Regional", "Craft Cocktails"],
    active_offers: [
      { offer_id: "happy_hour_15", title: "15% Off Cocktail Dinners", type: "percentage", value: 15 }
    ],
    daily_slots: {
      "2026-10-25": { "19:00": 4, "19:30": 2, "20:00": 0, "20:30": 1, "21:00": 2 },
      "2026-10-26": { "19:00": 5, "19:30": 3, "20:00": 2, "20:30": 4, "21:00": 4 }
    },
    rating: {
      average: 4.8,
      total_reviews: 492
    },
    status: "ACTIVE"
  },
  {
    restaurant_id: "res_green_sattvam",
    name: "Sattvam - Pure Vegetarian",
    upi_id: "sattvam@hdfcbank",
    fssai_number: "11521034000999",
    location: {
      address: "Sadashivnagar, Bengaluru, Karnataka",
      geo_coordinates: [13.0068, 77.5813]
    },
    cost_for_two: 1400,
    timings: {
      lunch: { open: "12:00", close: "15:30" },
      dinner: { open: "19:00", close: "22:30" }
    },
    visuals: {
      hero_image: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1000&q=80",
      ambience: [
        "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"
      ],
      menu_images: [
        "https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=800&q=80"
      ]
    },
    attributes: {
      is_veg_only: true,
      has_bar: false,
      is_ac: true,
      parking_available: true
    },
    cuisines: ["Sattvik", "South Indian", "North Indian Thali"],
    active_offers: [
      { offer_id: "veg_fest_20", title: "Flat 20% on Buffet", type: "percentage", value: 20 }
    ],
    daily_slots: {
      "2026-10-25": { "19:00": 8, "19:30": 6, "20:00": 5, "20:30": 7, "21:00": 6 },
      "2026-10-26": { "19:00": 10, "19:30": 8, "20:00": 6, "20:30": 7, "21:00": 8 }
    },
    rating: {
      average: 4.6,
      total_reviews: 215
    },
    status: "ACTIVE"
  }
];

export const INITIAL_BOOKINGS: Booking[] = [
  {
    booking_id: "bk_889900",
    user_id: "usr_98765abc",
    user_name: "Rahul Sharma",
    user_phone: "+919876543210",
    restaurant_id: "res_12345xyz",
    restaurant_name: "Mahesh Lunch Home",
    party_size: 4,
    date: "2026-10-25",
    time_slot: "19:30",
    status: "CONFIRMED",
    applied_offer: "flat_10",
    special_requests: "Window table requested",
    created_at: "2026-10-25T11:00:00Z",
    notification_sent: true
  },
  {
    booking_id: "bk_889901",
    user_id: "usr_33445def",
    user_name: "Pooja Hegde",
    user_phone: "+919812345678",
    restaurant_id: "res_67890abc",
    restaurant_name: "The Bombay Canteen",
    party_size: 2,
    date: "2026-10-25",
    time_slot: "20:30",
    status: "PENDING",
    applied_offer: "happy_hour_15",
    special_requests: "Anniversary celebration",
    created_at: "2026-10-25T16:20:00Z",
    notification_sent: true
  },
  {
    booking_id: "bk_889902",
    user_id: "usr_77889ghi",
    user_name: "Anil Deshmukh",
    user_phone: "+919765432109",
    restaurant_id: "res_green_sattvam",
    restaurant_name: "Sattvam - Pure Vegetarian",
    party_size: 6,
    date: "2026-10-26",
    time_slot: "19:00",
    status: "CONFIRMED",
    applied_offer: "veg_fest_20",
    created_at: "2026-10-25T14:15:00Z",
    notification_sent: true
  }
];

export const INITIAL_USERS: UserProfile[] = [
  {
    user_id: "usr_98765abc",
    name: "Rahul Sharma",
    phone_number: "+919876543210",
    email: "rahul.sharma@gmail.com",
    auth_provider: "google",
    preferences: ["Veg", "Spicy", "North Indian"],
    total_bookings: 4,
    created_at: "2026-10-25T17:41:00Z"
  },
  {
    user_id: "usr_33445def",
    name: "Pooja Hegde",
    phone_number: "+919812345678",
    email: "pooja.h@outlook.com",
    auth_provider: "phone",
    preferences: ["Cocktails", "Modern Indian", "Non-Veg"],
    total_bookings: 7,
    created_at: "2026-09-12T10:20:00Z"
  },
  {
    user_id: "usr_77889ghi",
    name: "Anil Deshmukh",
    phone_number: "+919765432109",
    email: "anil.d@gmail.com",
    auth_provider: "google",
    preferences: ["Pure Veg", "South Indian", "Jain Food"],
    total_bookings: 12,
    created_at: "2026-08-01T08:00:00Z"
  }
];

// In-memory local cache for instant zero-latency feedback and offline dev
let localRestaurants: Restaurant[] = [...INITIAL_RESTAURANTS];
let localBookings: Booking[] = [...INITIAL_BOOKINGS];
let localUsers: UserProfile[] = [...INITIAL_USERS];

export async function getRestaurants(): Promise<Restaurant[]> {
  if (db) {
    try {
      const q = query(collection(db, "restaurants"));
      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        return snapshot.docs.map(doc => ({ ...doc.data(), restaurant_id: doc.id } as Restaurant));
      }
    } catch (err) {
      console.warn("Firestore fetch error, falling back to local dataset:", err);
    }
  }
  return localRestaurants;
}

export async function getRestaurantById(id: string): Promise<Restaurant | null> {
  if (db) {
    try {
      const docRef = doc(db, "restaurants", id);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        return { ...docSnap.data(), restaurant_id: docSnap.id } as Restaurant;
      }
    } catch (err) {
      console.warn("Firestore getDoc error:", err);
    }
  }
  return localRestaurants.find(r => r.restaurant_id === id) || null;
}

export interface SaveResult {
  success: boolean;
  savedToFirestore: boolean;
  restaurantId: string;
  error?: string;
}

export async function saveRestaurant(restaurant: Restaurant): Promise<SaveResult> {
  const id = restaurant.restaurant_id || `res_${Date.now()}`;
  const data = { ...restaurant, restaurant_id: id };

  const existingIdx = localRestaurants.findIndex(r => r.restaurant_id === id);
  if (existingIdx >= 0) {
    localRestaurants[existingIdx] = data;
  } else {
    localRestaurants.unshift(data);
  }

  let savedToFirestore = false;
  let errorMsg: string | undefined;

  if (db) {
    try {
      await setDoc(doc(db, "restaurants", id), data, { merge: true });
      savedToFirestore = true;
    } catch (err: any) {
      console.warn("Firestore save error:", err);
      errorMsg = err?.message || String(err);
    }
  }

  return {
    success: true,
    savedToFirestore,
    restaurantId: id,
    error: errorMsg,
  };
}

export async function deleteRestaurant(id: string): Promise<void> {
  localRestaurants = localRestaurants.filter(r => r.restaurant_id !== id);
  if (db) {
    try {
      await deleteDoc(doc(db, "restaurants", id));
    } catch (err) {
      console.warn("Firestore delete error:", err);
    }
  }
}

export async function getBookings(): Promise<Booking[]> {
  if (db) {
    try {
      const q = query(collection(db, "bookings"), orderBy("created_at", "desc"));
      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        return snapshot.docs.map(d => ({ ...d.data(), booking_id: d.id } as Booking));
      }
    } catch (err) {
      console.warn("Firestore bookings fetch error:", err);
    }
  }
  return localBookings;
}

export async function updateBookingStatus(bookingId: string, status: Booking['status']): Promise<void> {
  const b = localBookings.find(item => item.booking_id === bookingId);
  if (b) {
    b.status = status;
  }
  if (db) {
    try {
      await updateDoc(doc(db, "bookings", bookingId), { status });
    } catch (err) {
      console.warn("Firestore booking status update error:", err);
    }
  }
}

export async function getUsers(): Promise<UserProfile[]> {
  if (db) {
    try {
      const q = query(collection(db, "users"));
      const snapshot = await getDocs(q);
      if (!snapshot.empty) {
        return snapshot.docs.map(d => ({ ...d.data(), user_id: d.id } as UserProfile));
      }
    } catch (err) {
      console.warn("Firestore users fetch error:", err);
    }
  }
  return localUsers;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const rests = await getRestaurants();
  const bks = await getBookings();
  const usrs = await getUsers();

  const todayStr = new Date().toISOString().split('T')[0];

  return {
    totalRestaurants: rests.length,
    activeRestaurants: rests.filter(r => r.status === 'ACTIVE').length,
    totalBookings: bks.length,
    confirmedBookings: bks.filter(b => b.status === 'CONFIRMED').length,
    totalUsers: usrs.length,
    todayBookings: bks.filter(b => b.date === todayStr).length
  };
}
