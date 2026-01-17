# Cloud Functions

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set environment variables for Razorpay (and others):
   ```bash
   firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET" razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"
   ```

3. Get current config:
   ```bash
   firebase functions:config:get > .runtimeconfig.json
   ```
   *This is needed for local emulation.*

## Functions

- `onCreateBooking`: Triggered on new booking document. Reserves seats and initiates payment.
- `onPaymentWebhook`: HTTP endpoint for Razorpay webhooks.
- `onDriverDocUpload`: Triggered on Storage upload.
- `sendFCM`: Callable function to send notifications.
- `scheduledCleanup`: Scheduled job to clean up stale bookings.

## Testing

Run emulators:
```bash
npm run serve
```
