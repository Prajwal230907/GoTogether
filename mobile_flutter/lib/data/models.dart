import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({required this.name, required this.phone});

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? collegeId;
  final String role; // "passenger" | "driver" | "admin"
  final double rating;
  final int tripsCompleted;
  final Timestamp createdAt;
  final List<EmergencyContact> emergencyContacts;
  final String? vehicleModel;
  final String? documentStatus;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.collegeId,
    required this.role,
    this.rating = 0.0,
    this.tripsCompleted = 0,
    required this.createdAt,
    this.emergencyContacts = const [],
    this.vehicleModel,
    this.documentStatus,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      collegeId: data['collegeId'],
      role: data['role'] ?? 'passenger',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      tripsCompleted: data['tripsCompleted'] ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      vehicleModel: data['vehicleModel'],
      documentStatus: data['documentStatus'],
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'collegeId': collegeId,
      'role': role,
      'rating': rating,
      'tripsCompleted': tripsCompleted,
      'createdAt': createdAt,
      'vehicleModel': vehicleModel,
      'documentStatus': documentStatus,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
    };
  }
  
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? collegeId,
    String? role,
    double? rating,
    int? tripsCompleted,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      collegeId: collegeId ?? this.collegeId,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      tripsCompleted: tripsCompleted ?? this.tripsCompleted,
      createdAt: this.createdAt,
      vehicleModel: vehicleModel,
      documentStatus: documentStatus,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class LocationPoint {
  final String text;
  final double lat;
  final double lng;

  LocationPoint({required this.text, required this.lat, required this.lng});

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      text: map['text'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'lat': lat,
      'lng': lng,
    };
  }
}

class RideModel {
  final String id;
  final String driverId;
  final LocationPoint origin;
  final LocationPoint destination;
  final Timestamp departTime;
  final num seatsAvailable;
  final num farePerSeat;
  final String status; // "open" | "active" | "completed" | "cancelled"
  final Timestamp createdAt;
  final String? vehicleModel;
  final List<dynamic>? routePolyline; // List of {'lat': double, 'lng': double}

  RideModel({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departTime,
    required this.seatsAvailable,
    required this.farePerSeat,
    required this.status,
    required this.createdAt,
    this.vehicleModel,
    this.routePolyline,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    return RideModel(
      id: id,
      driverId: map['driverId'] ?? '',
      origin: LocationPoint.fromMap(Map<String, dynamic>.from(map['origin'] ?? {})),
      destination: LocationPoint.fromMap(Map<String, dynamic>.from(map['destination'] ?? {})),
      departTime: map['departTime'] as Timestamp? ?? Timestamp.now(),
      seatsAvailable: map['seatsAvailable'] ?? 0,
      farePerSeat: map['farePerSeat'] ?? 0,
      status: map['status'] ?? 'open',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      vehicleModel: map['vehicleModel'],
      routePolyline: map['routePolyline'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'departTime': departTime,
      'seatsAvailable': seatsAvailable,
      'farePerSeat': farePerSeat,
      'status': status,
      'createdAt': createdAt,
      'vehicleModel': vehicleModel,
      'routePolyline': routePolyline,
    };
  }
}

class BookingModel {
  final String id;
  final String rideId;
  final String passengerId;
  final num seatsBooked;
  final num amount;
  final String paymentStatus; // "pending" | "paid" | "failed"
  final String bookingStatus; // "pending" | "confirmed" | "declined" | "completed" | "cancelled"
  final Timestamp createdAt;
  final LocationPoint? pickupLatLng;
  final LocationPoint? dropLatLng;
  final num? distanceKm;
  final String? otp;
  final Timestamp? acceptedAt;
  final Timestamp? startedAt;
  final Timestamp? completedAt;

  BookingModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.amount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.createdAt,
    this.pickupLatLng,
    this.dropLatLng,
    this.distanceKm,
    this.otp,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      rideId: map['rideId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      seatsBooked: map['seatsBooked'] ?? 1,
      amount: map['amount'] ?? 0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      bookingStatus: map['bookingStatus'] ?? 'pending',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      pickupLatLng: map['pickupLatLng'] != null ? LocationPoint.fromMap(Map<String, dynamic>.from(map['pickupLatLng'])) : null,
      dropLatLng: map['dropLatLng'] != null ? LocationPoint.fromMap(Map<String, dynamic>.from(map['dropLatLng'])) : null,
      distanceKm: map['distanceKm'],
      otp: map['otp'],
      acceptedAt: map['acceptedAt'],
      startedAt: map['startedAt'],
      completedAt: map['completedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'passengerId': passengerId,
      'seatsBooked': seatsBooked,
      'amount': amount,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'createdAt': createdAt,
      'pickupLatLng': pickupLatLng?.toMap(),
      'dropLatLng': dropLatLng?.toMap(),
      'distanceKm': distanceKm,
      'otp': otp,
      'acceptedAt': acceptedAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }
}
