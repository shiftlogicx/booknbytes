terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "book-and-bite-mvp"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-south1"
}

# Enable Firebase on the GCP Project
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

# Provision Firestore Database
resource "google_firestore_database" "database" {
  provider    = google-beta
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_firebase_project.default]
}

# Enable Firebase Storage (via App Engine)
resource "google_app_engine_application" "app" {
  provider      = google-beta
  project       = var.project_id
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"
}

# Firebase Web App (Admin Portal)
resource "google_firebase_web_app" "admin_portal" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Book & Bite Admin Portal"

  depends_on = [google_firebase_project.default]
}

# Firebase Android App (Customer)
resource "google_firebase_android_app" "customer_app" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Book & Bite Customer"
  package_name = "com.booknbite.customer"

  depends_on = [google_firebase_project.default]
}

# Firebase Android App (Hotel)
resource "google_firebase_android_app" "hotel_app" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Book & Bite Hotel"
  package_name = "com.booknbite.hotel"

  depends_on = [google_firebase_project.default]
}

# Firebase iOS App (Customer)
resource "google_firebase_apple_app" "customer_ios" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Book & Bite Customer iOS"
  bundle_id    = "com.booknbite.customer"

  depends_on = [google_firebase_project.default]
}

# Firebase iOS App (Hotel)
resource "google_firebase_apple_app" "hotel_ios" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Book & Bite Hotel iOS"
  bundle_id    = "com.booknbite.hotel"

  depends_on = [google_firebase_project.default]
}

# Enable required APIs
resource "google_project_service" "firebase" {
  provider = google-beta
  project  = var.project_id
  service  = "firebase.googleapis.com"
}

resource "google_project_service" "firestore" {
  provider = google-beta
  project  = var.project_id
  service  = "firestore.googleapis.com"
}

resource "google_project_service" "fcm" {
  provider = google-beta
  project  = var.project_id
  service  = "fcm.googleapis.com"
}

resource "google_project_service" "cloud_functions" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudbuild.googleapis.com"
}

# Outputs
output "project_id" {
  value = var.project_id
}

output "firestore_database" {
  value = google_firestore_database.database.name
}
