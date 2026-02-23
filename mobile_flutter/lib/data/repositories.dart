import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';

// Providers
final rideRepositoryProvider = Provider<RideRepository>((ref) => RideRepository());
final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepository());

class RideRepository {
  final CollectionReference _rides = FirebaseFirestore.instance.collection('rides');

  Future<void> createRide(RideModel ride) async {
    await _rides.add(ride.toMap());
  }

  Stream<List<RideModel>> getActiveRides() {
    return _rides
        .where('status', isEqualTo: 'open')
        .orderBy('departTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<List<RideModel>> getDriverRides(String driverId) {
    return _rides
        .where('driverId', isEqualTo: driverId)
        .orderBy('departTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RideModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> updateRideStatus(String rideId, String status) async {
    await _rides.doc(rideId).update({'status': status});
  }
}

class BookingRepository {
  final CollectionReference _bookings = FirebaseFirestore.instance.collection('bookings');

  Future<void> createBooking(BookingModel booking) async {
    await _bookings.add(booking.toMap());
  }

  Stream<List<BookingModel>> getDriverBookings(String rideId) {
    return _bookings
        .where('rideId', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<List<BookingModel>> getPassengerBookings(String passengerId) {
    return _bookings
        .where('passengerId', isEqualTo: passengerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _bookings.doc(bookingId).update({'bookingStatus': status});
  }
}
