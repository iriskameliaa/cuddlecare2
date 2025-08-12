import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/models/user_profile.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_profiles';

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing Firestore connection...');
      // Try to write a test document
      await _firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Firestore connection successful!');
      return true;
    } catch (e) {
      debugPrint('Firestore connection failed: $e');
      return false;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      debugPrint('Fetching profile for user: $uid');
      final doc = await _firestore.collection(_collection).doc(uid).get();

      if (doc.exists) {
        debugPrint('Profile found: ${doc.data()}');
        return UserProfile.fromMap(doc.data()!);
      }

      debugPrint('No profile found for user: $uid');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all pet sitters
  Future<List<UserProfile>> getPetSitters() async {
    try {
      debugPrint('Fetching all pet sitters...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPetSitter', isEqualTo: true)
          .get();

      final petSitters = querySnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();

      debugPrint('Found ${petSitters.length} pet sitters');
      return petSitters;
    } catch (e, stackTrace) {
      debugPrint('Error getting pet sitters: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      debugPrint('Saving profile for user: ${profile.uid}');
      debugPrint('Profile data: ${profile.toMap()}');

      await _firestore
          .collection(_collection)
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));

      debugPrint('Profile saved successfully');
    } catch (e, stackTrace) {
      debugPrint('Error saving user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<UserProfile>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      return querySnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting profiles by IDs: $e');
      return [];
    }
  }
}
