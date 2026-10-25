"use strict";
/**
 * Book & Bite — Firebase Cloud Functions
 *
 * Primary function: When a new booking is created in Firestore,
 * send a high-priority FCM data message to the restaurant owner's
 * device to trigger a MyGate-style full-screen ringing alert.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupExpiredSlots = exports.onBookingStatusUpdate = exports.onBookingCreated = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
// Initialize Firebase Admin
admin.initializeApp();
// Set default region
(0, v2_1.setGlobalOptions)({ region: "asia-south1" });
const db = admin.firestore();
const messaging = admin.messaging();
/**
 * Triggered when a new booking document is created.
 * Sends a high-priority FCM data message to the restaurant's registered devices.
 */
exports.onBookingCreated = (0, firestore_1.onDocumentCreated)("bookings/{bookingId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }
    const bookingData = snapshot.data();
    const bookingId = event.params.bookingId;
    const restaurantId = bookingData.restaurant_id;
    console.log(`New booking ${bookingId} for restaurant ${restaurantId}`);
    try {
        // Get the restaurant's device tokens
        const tokensSnapshot = await db
            .collection("restaurants")
            .doc(restaurantId)
            .collection("device_tokens")
            .get();
        if (tokensSnapshot.empty) {
            console.log(`No device tokens found for restaurant ${restaurantId}`);
            return;
        }
        const tokens = [];
        tokensSnapshot.forEach((doc) => {
            const tokenData = doc.data();
            if (tokenData.token) {
                tokens.push(tokenData.token);
            }
        });
        if (tokens.length === 0) {
            console.log("No valid tokens found");
            return;
        }
        // Get customer name from users collection
        let customerName = "A Customer";
        try {
            const userDoc = await db
                .collection("users")
                .doc(bookingData.user_id)
                .get();
            if (userDoc.exists) {
                customerName = userDoc.data()?.name || customerName;
            }
        }
        catch (err) {
            console.log("Could not fetch customer name:", err);
        }
        // Build the FCM data message (DATA-ONLY — no notification payload)
        // This ensures the app wakes up and handles the alert even when backgrounded
        const message = {
            tokens: tokens,
            data: {
                type: "NEW_BOOKING",
                booking_id: bookingId,
                restaurant_id: restaurantId,
                restaurant_name: bookingData.restaurant_name || "",
                customer_name: customerName,
                party_size: String(bookingData.party_size || 0),
                date: bookingData.date || "",
                time_slot: bookingData.time_slot || "",
                applied_offer: bookingData.applied_offer || "",
                created_at: bookingData.created_at || new Date().toISOString(),
            },
            android: {
                priority: "high",
                ttl: 300000, // 5 minutes TTL
            },
            apns: {
                headers: {
                    "apns-priority": "10", // High priority
                    "apns-push-type": "background",
                },
                payload: {
                    aps: {
                        "content-available": 1,
                        sound: "alert_ringtone.caf",
                    },
                },
            },
        };
        // Send to all registered devices
        const response = await messaging.sendEachForMulticast(message);
        console.log(`FCM sent: ${response.successCount} success, ${response.failureCount} failures`);
        // Clean up invalid tokens
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                const error = resp.error;
                console.log(`Error sending to token ${idx}:`, error?.message);
                // Remove invalid tokens
                if (error?.code === "messaging/invalid-registration-token" ||
                    error?.code === "messaging/registration-token-not-registered") {
                    // Find the token doc to delete
                    tokensSnapshot.docs.forEach((doc) => {
                        if (doc.data().token === tokens[idx]) {
                            tokensToRemove.push(doc.ref.delete());
                        }
                    });
                }
            }
        });
        if (tokensToRemove.length > 0) {
            await Promise.all(tokensToRemove);
            console.log(`Removed ${tokensToRemove.length} invalid tokens`);
        }
        // Update booking with notification status
        await snapshot.ref.update({
            notification_sent: true,
            notification_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (error) {
        console.error("Error sending FCM notification:", error);
    }
});
/**
 * When a booking status is updated (e.g., CONFIRMED or CANCELLED),
 * optionally notify the customer via FCM.
 */
exports.onBookingStatusUpdate = (0, firestore_1.onDocumentCreated)("bookings/{bookingId}", async (event) => {
    // This is a placeholder — in a real app, you'd use onDocumentUpdated
    // and check if status changed, then send notification to customer.
    // For MVP, the main focus is the restaurant alert flow above.
    console.log("Booking status update handler — placeholder for MVP");
});
/**
 * Scheduled function: Clean up expired daily slots
 * Runs daily at midnight IST
 */
exports.cleanupExpiredSlots = (0, scheduler_1.onSchedule)({
    schedule: "0 0 * * *",
    timeZone: "Asia/Kolkata",
}, async () => {
    const today = new Date();
    const cutoffDate = new Date(today);
    cutoffDate.setDate(cutoffDate.getDate() - 7); // Keep 7 days of history
    const cutoffStr = cutoffDate.toISOString().split("T")[0]; // YYYY-MM-DD
    console.log(`Cleaning up slots older than ${cutoffStr}`);
    try {
        const restaurantsSnapshot = await db.collection("restaurants").get();
        const batch = db.batch();
        let updateCount = 0;
        for (const doc of restaurantsSnapshot.docs) {
            const data = doc.data();
            const dailySlots = data.daily_slots || {};
            const updatedSlots = {};
            let hasChanges = false;
            for (const dateKey of Object.keys(dailySlots)) {
                if (dateKey >= cutoffStr) {
                    updatedSlots[dateKey] = dailySlots[dateKey];
                }
                else {
                    hasChanges = true;
                }
            }
            if (hasChanges) {
                batch.update(doc.ref, { daily_slots: updatedSlots });
                updateCount++;
            }
        }
        if (updateCount > 0) {
            await batch.commit();
            console.log(`Updated ${updateCount} restaurants`);
        }
        else {
            console.log("No expired slots to clean up");
        }
    }
    catch (error) {
        console.error("Error cleaning up slots:", error);
    }
});
//# sourceMappingURL=index.js.map