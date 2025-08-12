import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/models/review.dart';
import 'package:uuid/uuid.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Get all reviews for a pet sitter
  Future<List<Review>> getPetSitterReviews(String petSitterId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('petSitterId', isEqualTo: petSitterId)
          .get();

      final reviews = snapshot.docs.map((doc) {
        try {
          return Review.fromMap(doc.data());
        } catch (e) {
          print('Error parsing review ${doc.id}: $e');
          print('Review data: ${doc.data()}');
          rethrow;
        }
      }).toList();

      // Sort by createdAt in descending order (newest first)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reviews;
    } catch (e) {
      print('Error getting reviews for petSitterId $petSitterId: $e');
      rethrow;
    }
  }

  // Add a new review
  Future<void> addReview(Review review) async {
    await _firestore.collection(_collection).doc(review.id).set(review.toMap());
  }

  // Update an existing review
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection(_collection)
        .doc(review.id)
        .update(review.toMap());
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection(_collection).doc(reviewId).delete();
  }

  // Get average rating for a pet sitter
  Future<double> getAverageRating(String petSitterId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('petSitterId', isEqualTo: petSitterId)
        .get();

    if (snapshot.docs.isEmpty) return 0.0;

    final totalRating = snapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );

    return totalRating / snapshot.docs.length;
  }

  // Get reviews by a specific user
  Future<List<Review>> getUserReviews(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();
  }
}
