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
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}
