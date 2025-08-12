import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // Add a provider to the user's favorites
  Future<void> addFavorite(String providerId) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .doc(providerId)
        .set({'favoritedAt': Timestamp.now()});
  }

  // Remove a provider from the user's favorites
  Future<void> removeFavorite(String providerId) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .doc(providerId)
        .delete();
  }

  // Check if a provider is a favorite
  Future<bool> isFavorite(String providerId) async {
    if (_currentUser == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .doc(providerId)
        .get();
    return doc.exists;
  }

  // Get a stream of favorite provider IDs
  Stream<List<String>> getFavoriteProviderIds() {
    if (_currentUser == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
