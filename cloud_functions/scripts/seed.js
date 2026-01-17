const admin = require('firebase-admin');
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9100';

admin.initializeApp({
    projectId: 'demo-gotogether',
});

const db = admin.firestore();

async function seed() {
    console.log('Seeding data...');

    // 1. Create a Driver
    const driverId = 'driver1';
    await db.collection('users').doc(driverId).set({
        name: 'John Driver',
        email: 'driver@college.edu',
        phone: '+919876543210',
        role: 'driver',
        verified: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('driver_profiles').doc(driverId).set({
        vehicleModel: 'Swift Dzire',
        vehicleRegUrl: 'http://example.com/rc.jpg',
        seats: 4,
        isAvailable: true,
        verifiedByAdmin: true,
    });

    // 2. Create a Passenger
    const passengerId = 'passenger1';
    await db.collection('users').doc(passengerId).set({
        name: 'Jane Student',
        email: 'student@college.edu',
        phone: '+919876543211',
        role: 'passenger',
        verified: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Create a Ride
    const rideId = 'ride1';
    await db.collection('rides').doc(rideId).set({
        driverId: driverId,
        origin: { text: 'College Gate 1', lat: 12.9716, lng: 77.5946 },
        destination: { text: 'City Center', lat: 12.9352, lng: 77.6245 },
        departTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 3600000)), // 1 hour later
        seatsAvailable: 3,
        farePerSeat: 50,
        status: 'open',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Seeding complete.');
}

seed().catch(console.error);
