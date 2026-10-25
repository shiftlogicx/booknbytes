export interface UserProfile {
  user_id: string;
  name: string;
  phone_number: string;
  email: string;
  auth_provider: 'google' | 'phone' | 'email';
  preferences: string[];
  total_bookings: number;
  created_at: string;
}

export interface Offer {
  offer_id: string;
  title: string;
  type: 'percentage' | 'flat';
  value: number;
}

export interface RestaurantTimings {
  lunch: { open: string; close: string };
  dinner: { open: string; close: string };
}

export interface RestaurantVisuals {
  hero_image: string;
  ambience: string[];
  menu_images: string[];
}

export interface RestaurantAttributes {
  is_veg_only: boolean;
  has_bar: boolean;
  is_ac: boolean;
  parking_available: boolean;
}

export interface RestaurantLocation {
  address: string;
  geo_coordinates: [number, number]; // [lat, lng]
}

export interface DailySlots {
  [date: string]: {
    [timeSlot: string]: number; // available table count
  };
}

export interface Restaurant {
  restaurant_id: string;
  name: string;
  upi_id: string;
  fssai_number: string;
  location: RestaurantLocation;
  cost_for_two: number;
  timings: RestaurantTimings;
  visuals: RestaurantVisuals;
  attributes: RestaurantAttributes;
  cuisines: string[];
  active_offers: Offer[];
  daily_slots: DailySlots;
  rating: {
    average: number;
    total_reviews: number;
  };
  status: 'ACTIVE' | 'INACTIVE' | 'PENDING_APPROVAL';
  created_at?: string;
  owner_uid?: string;
}

export type BookingStatus = 'PENDING' | 'CONFIRMED' | 'SEATED' | 'COMPLETED' | 'CANCELLED';

export interface Booking {
  booking_id: string;
  user_id: string;
  user_name?: string;
  user_phone?: string;
  restaurant_id: string;
  restaurant_name: string;
  party_size: number;
  date: string; // YYYY-MM-DD
  time_slot: string; // HH:mm
  status: BookingStatus;
  applied_offer?: string;
  special_requests?: string;
  created_at: string;
  notification_sent?: boolean;
}

export interface DashboardStats {
  totalRestaurants: number;
  activeRestaurants: number;
  totalBookings: number;
  confirmedBookings: number;
  totalUsers: number;
  todayBookings: number;
}
