export type BookingStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'NO_SHOW'
  | 'REJECTED';

export interface UserProfile {
  user_id: string;
  name: string;
  phone_number: string;
  email: string;
  preferences?: string[];
  total_bookings: number;
  created_at: string;
  updated_at?: string;
  role?: 'diner' | 'owner' | 'manager' | 'admin';
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
  pure_veg: boolean;
  serves_alcohol: boolean;
  has_ac: boolean;
  has_parking: boolean;
}

export interface ManagerCredentials {
  manager_id?: string;
  email?: string;
  default_password?: string;
}

export interface OwnerDetails {
  owner_id?: string;
  name?: string;
  email?: string;
  phone?: string;
  manager_credentials?: ManagerCredentials;
}

export interface Restaurant {
  restaurant_id: string;
  name: string;
  upi_id?: string;
  fssai_number: string;
  address: string;
  cost_for_two: number;
  timings?: RestaurantTimings;
  visuals?: RestaurantVisuals;
  attributes?: RestaurantAttributes;
  cuisines: string[];
  active_offers?: Offer[];
  rating?: {
    average: number;
    total_reviews: number;
  };
  status: 'ACTIVE' | 'INACTIVE' | 'PENDING_APPROVAL';
  created_at?: string;
  owners_details?: OwnerDetails;
  gst_num?: string;
}

export interface Booking {
  booking_id: string;
  user_id: string;
  restaurant_id: string;
  restaurant_name: string;
  party_size: number;
  booking_date: string; // YYYY-MM-DD
  time_slot: string; // HH:mm or e.g. 19:30
  applied_offer?: string | null;
  payment_id?: string | null;
  status: BookingStatus;
  created_at: string;
  slot_id?: string | null;
  users?: {
    name?: string;
    phone_number?: string;
    email?: string;
  };
}

export interface DailySlot {
  slot_id: string;
  restaurant_id: string;
  start_datetime: string;
  end_datetime: string;
  discount_percentage: number;
  capacity: number;
  restaurant_name?: string;
}

export interface Review {
  review_id: string;
  restaurant_id: string;
  user_id: string;
  rating: number;
  comment?: string;
  created_at: string;
  updated_at?: string;
  restaurant_name?: string;
  user_name?: string;
  user_email?: string;
}

export interface DashboardStats {
  totalRestaurants: number;
  activeRestaurants: number;
  totalBookings: number;
  confirmedBookings: number;
  totalUsers: number;
  todayBookings: number;
  totalReviews: number;
  averageRating: number;
}
