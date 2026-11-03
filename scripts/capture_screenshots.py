#!/usr/bin/env python3
import time
import urllib.request
import urllib.error
import subprocess
import os
import sys

SCREENS = [
    (0, "01_splash_screen.png", "App Splash & Brand Identity"),
    (1, "02_login_owner.png", "Partner Login - Restaurant Owner Mode"),
    (2, "03_login_manager.png", "Partner Login - Floor Manager Mode"),
    (3, "04_onboarding_register_partner.png", "Onboarding - Register Restaurant Partner"),
    (4, "05_restaurant_activated_dialog.png", "Restaurant Activated - Credentials Popup"),
    (5, "06_partner_walkthrough_ring.png", "Partner Walkthrough - Priority Ring Alarm"),
    (6, "07_partner_walkthrough_swipe.png", "Partner Walkthrough - 1-Touch Confirmation"),
    (7, "08_dashboard_pulse_check.png", "Dashboard - Pulse Check & Shift Bento"),
    (8, "09_dashboard_live_dining_queue.png", "Dashboard - Live Dining Queue & Active Tables"),
    (9, "10_incoming_booking_alert.png", "Full-Screen Incoming Booking Ring Alert"),
    (10, "11_reservation_confirmed_dialog.png", "Reservation Confirmed & Table Assigned Dialog"),
    (11, "12_bookings_list_all.png", "Bookings List - All Live Reservations"),
    (12, "13_slots_management_published.png", "Slot Management - Published Shift Capacity"),
    (13, "14_slots_inventory_matrix.png", "Slot Inventory - Day & Time Slot Matrix"),
    (14, "15_discounts_and_offers.png", "Discounts & Flash Offers Management"),
    (15, "16_restaurant_profile.png", "Restaurant Profile & Operating Hours"),
    (16, "17_location_picker_sheet.png", "Location & Geofencing Picker"),
    (17, "18_settings_and_staff.png", "Settings - Passkeys & Acoustic Ring Volumes"),
    (18, "19_booking_audit_document.png", "Official Booking Audit & Daily Ledger Statement"),
    (19, "20_support_and_helpdesk.png", "Partner Support & VIP Escalation Desk"),
]

OUTPUT_DIR = "/Users/amitjaydeepsinghthakur/BookNBytes/ios_screenshots"

def wait_for_server(max_retries=60):
    print("Waiting for screenshot harness server at http://127.0.0.1:8088 ...")
    for i in range(max_retries):
        try:
            with urllib.request.urlopen("http://127.0.0.1:8088/status", timeout=2) as resp:
                if resp.status == 200:
                    print("Connected to screenshot runner!")
                    return True
        except Exception:
            time.sleep(2)
            sys.stdout.write(".")
            sys.stdout.flush()
    return False

def capture_all():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    if not wait_for_server():
        print("\nError: Could not connect to screenshot runner on port 8088.")
        sys.exit(1)

    print(f"\nStarting capture of {len(SCREENS)} iOS screens to {OUTPUT_DIR} ...\n")
    results = []

    for idx, filename, desc in SCREENS:
        filepath = os.path.join(OUTPUT_DIR, filename)
        url = f"http://127.0.0.1:8088/screen?index={idx}"
        try:
            with urllib.request.urlopen(url, timeout=5) as resp:
                resp.read()
        except Exception as e:
            print(f"Error navigating to screen {idx}: {e}")
            continue

        # Allow animations / fonts to settle
        time.sleep(1.2)

        # Capture using xcrun simctl io
        cmd = ["xcrun", "simctl", "io", "booted", "screenshot", filepath]
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if p.returncode == 0 and os.path.exists(filepath):
            size_kb = os.path.getsize(filepath) // 1024
            print(f"[{idx+1:02d}/{len(SCREENS):02d}] Captured: {filename} ({size_kb} KB) - {desc}")
            results.append((filename, size_kb, desc))
        else:
            print(f"[{idx+1:02d}/{len(SCREENS):02d}] FAILED: {filename} - {p.stderr}")

    print("\nCapture finished successfully!")
    print(f"Total screenshots captured: {len(results)}/{len(SCREENS)}")
    return results

if __name__ == "__main__":
    capture_all()
