import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// import * as Razorpay from "razorpay";

admin.initializeApp();

// Initialize Razorpay
// const razorpay = new Razorpay({
//   key_id: functions.config().razorpay.key_id,
//   key_secret: functions.config().razorpay.key_secret,
// });

/**
 * Triggered when a booking is created.
 * Reserves seats, sends push notification to driver, and creates Razorpay order.
 */
export const onCreateBooking = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snapshot, context) => {
        const booking = snapshot.data();
        const bookingId = context.params.bookingId;
        console.log(`Processing new booking: ${bookingId}`);

        // 1. Reserve seats (Atomic transaction recommended in real app)
        const rideRef = admin.firestore().collection("rides").doc(booking.rideId);

        try {
            await admin.firestore().runTransaction(async (t) => {
                const rideDoc = await t.get(rideRef);
                if (!rideDoc.exists) {
                    throw new Error("Ride does not exist");
                }
                const rideData = rideDoc.data();
                if (rideData && rideData.seatsAvailable >= booking.seatsBooked) {
                    t.update(rideRef, {
                        seatsAvailable: rideData.seatsAvailable - booking.seatsBooked,
                    });
                } else {
                    throw new Error("Not enough seats available");
                }
            });
            console.log("Seats reserved successfully");
        } catch (e) {
            console.error("Error reserving seats:", e);
            // Mark booking as failed?
            return;
        }

        // 2. Send Push Notification to Driver
        // await sendFCM(...)

        // 3. Create Razorpay Order (if payment is required)
        // const order = await razorpay.orders.create(...)
        // Update booking with orderId
    });

/**
 * Webhook to verify payment signatures from Razorpay.
 */
export const onPaymentWebhook = functions.https.onRequest(async (req, res) => {
    // const secret = "YOUR_WEBHOOK_SECRET"; // functions.config().razorpay.webhook_secret
    // Verify signature
    // Update payment status in Firestore
    // Update booking status to 'confirmed'
    res.json({ status: "ok" });
});

/**
 * Triggered when a driver uploads a document.
 * Notifies admin for verification.
 */
export const onDriverDocUpload = functions.storage.object().onFinalize(async (object) => {
    // Check if it's a driver doc
    // Update driver profile docsStatus
    // Notify admin
});

/**
 * General purpose function to send FCM notifications.
 * Callable from client or other functions.
 */
export const sendFCM = functions.https.onCall(async (data, context) => {
    // if (!context.auth) return { error: "Unauthorized" };
    const { tokens, title, body, data: msgData } = data;

    const message = {
        notification: { title, body },
        data: msgData,
        tokens: tokens,
    };

    try {
        const response = await admin.messaging().sendMulticast(message);
        return { success: true, response };
    } catch (error) {
        console.error("Error sending FCM:", error);
        return { error: error };
    }
});

/**
 * Scheduled cleanup for stale pending bookings.
 */
export const scheduledCleanup = functions.pubsub.schedule("every 15 minutes").onRun(async (context) => {
    // Query pending bookings older than X minutes
    // Cancel them and release seats
});
