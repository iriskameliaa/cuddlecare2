import 'package:cloud_firestore/cloud_firestore.dart';

enum SimpleVerificationStatus { pending, verified, rejected }

class SimpleVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate reliability score based on essential factors
  int calculateReliabilityScore({
    required bool hasIdDocument,
    required bool hasProfileImage,
    required bool hasAddress,
    required bool hasPhone,
    required String experience,
    required bool hasPetCareExperience,
    required bool hasReferences,
    required bool backgroundCheckConsent,
  }) {
    int score = 0;

    // Basic requirements (40 points)
    if (hasPhone) score += 10;
    if (hasAddress) score += 10;
    if (hasProfileImage) score += 10;
    if (hasIdDocument) score += 10;

    // Experience and qualifications (30 points)
    switch (experience.toLowerCase()) {
      case 'expert':
        score += 15;
        break;
      case 'intermediate':
        score += 10;
        break;
      case 'beginner':
        score += 5;
        break;
    }

    if (hasPetCareExperience) score += 10;
    if (hasReferences) score += 5;

    // Identity verification (20 points)
    if (hasIdDocument) score += 20;

    // Background check consent (10 points)
    if (backgroundCheckConsent) score += 10;

    return score;
  }

  // Get reliability level based on score
  String getReliabilityLevel(int score) {
    if (score >= 90) return '🔒 Premium Trusted';
    if (score >= 75) return '✅ Highly Trusted';
    if (score >= 60) return '👍 Trusted';
    if (score >= 40) return '⚠️ Basic Trust';
    return '❓ New Provider';
  }

  // Update provider verification status
  Future<void> updateVerificationStatus(
      String providerId, SimpleVerificationStatus status) async {
    await _firestore.collection('providers').doc(providerId).update({
      'verificationStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get verification status for a provider
  Future<SimpleVerificationStatus> getVerificationStatus(
      String providerId) async {
    try {
      final doc =
          await _firestore.collection('providers').doc(providerId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['verificationStatus'] as String? ?? 'pending';

        return SimpleVerificationStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => SimpleVerificationStatus.pending,
        );
      }
      return SimpleVerificationStatus.pending;
    } catch (e) {
      print('Error getting verification status: $e');
      return SimpleVerificationStatus.pending;
    }
  }

  // Get providers by verification status
  Future<List<Map<String, dynamic>>> getProvidersByStatus(
      SimpleVerificationStatus status) async {
    try {
      final snapshot = await _firestore
          .collection('providers')
          .where('verificationStatus', isEqualTo: status.name)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting providers by status: $e');
      return [];
    }
  }

  // Get verified providers with high reliability scores
  Future<List<Map<String, dynamic>>> getReliableProviders(
      {int minScore = 60}) async {
    try {
      final snapshot = await _firestore
          .collection('providers')
          .where('verificationStatus',
              isEqualTo: SimpleVerificationStatus.verified.name)
          .where('reliabilityScore', isGreaterThanOrEqualTo: minScore)
          .orderBy('reliabilityScore', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting reliable providers: $e');
      return [];
    }
  }

  // Auto-verify providers based on reliability score
  Future<void> autoVerifyProvider(String providerId) async {
    try {
      final doc =
          await _firestore.collection('providers').doc(providerId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final reliabilityScore = data['reliabilityScore'] as int? ?? 0;

        // Auto-verify if score is 60 or higher
        if (reliabilityScore >= 60) {
          await updateVerificationStatus(
              providerId, SimpleVerificationStatus.verified);
        }
      }
    } catch (e) {
      print('Error auto-verifying provider: $e');
    }
  }

  // Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final snapshot = await _firestore.collection('providers').get();

      int total = 0;
      int verified = 0;
      int pending = 0;
      int rejected = 0;
      double avgReliabilityScore = 0.0;
      int totalReliabilityScore = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        total++;

        final reliabilityScore = data['reliabilityScore'] as int? ?? 0;
        totalReliabilityScore += reliabilityScore;

        final status = data['verificationStatus'] as String? ?? 'pending';

        switch (status) {
          case 'verified':
            verified++;
            break;
          case 'pending':
            pending++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      avgReliabilityScore = total > 0 ? totalReliabilityScore / total : 0.0;

      return {
        'total': total,
        'verified': verified,
        'pending': pending,
        'rejected': rejected,
        'avgReliabilityScore': avgReliabilityScore,
        'verificationRate': total > 0 ? (verified / total * 100) : 0.0,
      };
    } catch (e) {
      print('Error getting verification stats: $e');
      return {};
    }
  }
}
