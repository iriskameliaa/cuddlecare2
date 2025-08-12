import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  static const List<String> availableServices = [
    'Pet Sitting',
    'Pet Grooming',
    'Pet Walking',
    'Pet Health Checkups'
  ];

  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? birthday;
  final String? address;
  final String? experience;
  final int? age;
  final Map<String, dynamic>? availability;
  final Map<String, dynamic>? rates;
  final String? bio;
  final String? location;
  final GeoPoint? geoPointLocation;
  final String? profilePicUrl;
  final List<String>? services;
  final List<String>? preferredPetTypes;
  final List<String>? certificateUrls;
  final bool isPetSitter;
  final double? serviceRadius;
  final double? rating;
  final List<Map<String, dynamic>>? reviews;
  final String? telegramChatId;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.birthday,
    this.address,
    this.experience,
    this.age,
    this.availability,
    this.rates,
    this.bio,
    this.location,
    this.geoPointLocation,
    this.profilePicUrl,
    this.services,
    this.preferredPetTypes,
    this.certificateUrls,
    this.isPetSitter = false,
    this.serviceRadius,
    this.rating,
    this.reviews,
    this.telegramChatId,
  });

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'birthday': birthday,
      'address': address,
      'experience': experience,
      'age': age,
      'availability': availability,
      'rates': rates,
      'bio': bio,
      'location': location,
      'profilePicUrl': profilePicUrl,
      'services': services,
      'petTypes': preferredPetTypes,
      'certificateUrls': certificateUrls,
      'isPetSitter': isPetSitter,
      'serviceRadius': serviceRadius,
      'rating': rating,
      'reviews': reviews,
      'telegramChatId': telegramChatId,
    };
  }

  // Create UserProfile from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    GeoPoint? geoPoint;
    String? locationString;

    if (map['location'] is GeoPoint) {
      geoPoint = map['location'] as GeoPoint;
      // Note: We don't have a string representation from the GeoPoint here.
      // The 'location' string field might be null if only GeoPoint is stored.
    } else if (map['location'] is String) {
      locationString = map['location'] as String;
    }

    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      birthday: map['birthday'],
      address: map['address'],
      experience: map['experience'],
      age: map['age'],
      availability: map['availability'],
      rates: map['rates'],
      bio: map['bio'],
      location: locationString,
      geoPointLocation: geoPoint,
      profilePicUrl: map['profilePicUrl'],
      services: List<String>.from(map['services'] ?? []),
      preferredPetTypes: List<String>.from(map['petTypes'] ?? []),
      certificateUrls: List<String>.from(map['certificateUrls'] ?? []),
      isPetSitter: map['isPetSitter'] ?? false,
      serviceRadius: map['serviceRadius']?.toDouble(),
      rating: map['rating']?.toDouble(),
      reviews: List<Map<String, dynamic>>.from(map['reviews'] ?? []),
      telegramChatId: map['telegramChatId'],
    );
  }
}
