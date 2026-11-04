#!/usr/bin/env bash
set -e

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
APK="/Users/amitjaydeepsinghthakur/BookNBytes/BookNBite_Hotel_v1.0.apk"

echo "🔍 Waiting for OnePlus device to be connected via ADB..."
$ADB wait-for-device

echo "📱 Device detected:"
$ADB devices -l

echo "📦 Installing $APK directly to phone..."
$ADB install -r "$APK"

echo "🚀 Launching Book & Bite Partner app on phone..."
$ADB shell am start -n com.booknbite.hotel/.MainActivity

echo "✅ App successfully pushed and running on your phone!"
