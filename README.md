# 🍽️ Book & Bite — Table Booking Platform (MVP 2.0)

> A Swiggy Dineout-inspired table booking app with **zero platform fees**, **MyGate-style ringing alerts** for restaurants, and **direct UPI payment**.

## 📱 Applications

| App | Platform | Tech Stack | Description |
|-----|----------|------------|-------------|
| **Customer App** | iOS & Android | Flutter | Discover restaurants, book tables frictionlessly, pay via UPI |
| **Hotel App** | iOS & Android | Flutter | Receive full-screen ringing alerts for bookings, manage reservations |
| **Admin Portal** | Web | Next.js + React | Internal restaurant onboarding, monitoring, management |

## 🏗️ Project Structure

```
BookNBytes/
├── customer_app/          # Flutter — Customer mobile app
├── hotel_app/             # Flutter — Hotel/Restaurant mobile app
├── admin_portal/          # Next.js — Admin web dashboard
├── firebase/              # Firebase backend
│   ├── functions/         # Cloud Functions (booking → FCM alerts)
│   ├── firestore.rules    # Firestore security rules
│   ├── storage.rules      # Storage security rules
│   └── firebase.json      # Firebase config
├── terraform/             # Infrastructure as Code (GCP/Firebase)
└── README.md              # This file
```

## 🔥 Core Features

### Customer App
- 🔍 Restaurant discovery with search & filters (cuisine, veg, AC, bar, offers)
- 📋 Rich restaurant detail pages (images, menu, reviews, offers)
- 🎯 **Frictionless booking** — Select party size + time slot → One-tap confirm
- 💳 **Direct UPI payment** — Deep-link to GPay/PhonePe/Paytm (no payment gateway)
- 📱 Responsive UI (iPhone SE → Pro Max, Samsung S24 Ultra)

### Hotel App
- 🔔 **MyGate-style full-screen ringing alerts** for new bookings
- ✅ Accept / Snooze booking actions
- 📊 Daily reservation dashboard with timeline view
- 🔕 Works even when app is backgrounded/killed (FCM data messages)
- 📈 Booking trends & analytics

### Admin Portal
- 📊 Dashboard with overview stats
- 🏪 Restaurant onboarding (FSSAI, UPI, images, attributes)
- 📅 Booking management with filters
- 👤 User management
- 📱 Responsive (Desktop + Mobile web)

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile Apps | Flutter (Dart) |
| Web Portal | Next.js 14 (TypeScript) + Tailwind CSS |
| Database | Firebase Cloud Firestore |
| Auth | Firebase Authentication |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| File Storage | Firebase Storage |
| Server Logic | Firebase Cloud Functions (TypeScript) |
| Infrastructure | Terraform (GCP) |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x+)
- Node.js 20+
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project

### 1. Firebase Setup

```bash
# Login to Firebase
firebase login

# Initialize the project (or use existing firebase/ config)
cd firebase/
firebase use --add  # Select your project

# Deploy Cloud Functions
cd functions/
npm install
npm run build
cd ..
firebase deploy
```

### 2. Customer App

```bash
cd customer_app/
flutter pub get

# Update Firebase config in lib/config/firebase_config.dart
# Add google-services.json (Android) & GoogleService-Info.plist (iOS)

flutter run
```

### 3. Hotel App

```bash
cd hotel_app/
flutter pub get

# Update Firebase config in lib/config/firebase_config.dart
# Add google-services.json (Android) & GoogleService-Info.plist (iOS)

flutter run
```

### 4. Admin Portal

```bash
cd admin_portal/
npm install

# Update Firebase config in src/lib/firebase.ts

npm run dev
# Open http://localhost:3000
```

### 5. Terraform (Optional)

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## 📐 Data Model

### Collections

- **`users`** — Customer profiles (name, phone, email, preferences)
- **`restaurants`** — Restaurant details (name, location, UPI, FSSAI, timings, slots, offers, images)
- **`bookings`** — Reservations (user, restaurant, party size, date, time, status)
- **`admins`** — Admin user records

## 🔄 Core Flows

### Customer Booking Flow
```
Open App → Browse Restaurants → View Details → Select Party Size & Time Slot
→ Confirm (Firestore write) → Cloud Function triggers → FCM to Hotel App
→ After dining → "Pay Bill" → UPI deep-link → Direct merchant payment
```

### Restaurant Alert Flow
```
New Booking (Firestore) → Cloud Function → FCM Data Message → Hotel App wakes
→ Full-screen ringing alert → Accept (confirms booking) or Snooze (retry in 2 min)
```

## 📄 License

MIT License — See [LICENSE](LICENSE)
