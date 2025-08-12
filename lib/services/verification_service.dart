import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/models/provider_verification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'provider_verifications';

  // Initialize verification for a new provider
  Future<void> initializeVerification(String providerId) async {
    final verification = ProviderVerification(
      providerId: providerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(providerId)
        .set(verification.toMap());
  }

  // Get verification status for a provider
  Future<ProviderVerification?> getVerification(String providerId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(providerId).get();

      if (doc.exists) {
        return ProviderVerification.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting verification: $e');
      return null;
    }
  }

  // Update verification status
  Future<void> updateVerificationStatus(
    String providerId,
    VerificationStatus status, {
    String? verifiedBy,
    String? rejectionReason,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == VerificationStatus.verified) {
      updateData['verifiedAt'] = DateTime.now().toIso8601String();
      updateData['verifiedBy'] = verifiedBy ?? 'system';
    }

    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }

    await _firestore.collection(_collection).doc(providerId).update(updateData);
  }

  // Update background check status
  Future<void> updateBackgroundCheckStatus(
    String providerId,
    BackgroundCheckStatus status,
  ) async {
    await _firestore.collection(_collection).doc(providerId).update({
      'backgroundCheckStatus': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Add certificate for verification
  Future<void> addCertificate(String providerId, String certificateUrl) async {
    await _firestore.collection(_collection).doc(providerId).update({
      'pendingCertificates': FieldValue.arrayUnion([certificateUrl]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Verify a certificate
  Future<void> verifyCertificate(
      String providerId, String certificateUrl) async {
    await _firestore.collection(_collection).doc(providerId).update({
      'pendingCertificates': FieldValue.arrayRemove([certificateUrl]),
      'verifiedCertificates': FieldValue.arrayUnion([certificateUrl]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Calculate and update trust score
  Future<void> updateTrustScore(String providerId) async {
    try {
      // Get provider data
      final providerDoc =
          await _firestore.collection('providers').doc(providerId).get();

      if (!providerDoc.exists) return;

      final providerData = providerDoc.data() as Map<String, dynamic>;

      // Get verification data
      final verification = await getVerification(providerId);
      if (verification == null) return;

      // Get review data
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('petSitterId', isEqualTo: providerId)
          .get();

      final rating = (providerData['rating'] as num?)?.toDouble() ?? 0.0;
      final reviewCount = reviewsSnapshot.docs.length;
      final completedBookings =
          (providerData['completedBookings'] as num?)?.toInt() ?? 0;
      final verifiedCertificates = verification.verifiedCertificates.length;
      final backgroundCheckPassed =
          verification.backgroundCheckStatus == BackgroundCheckStatus.passed;
      final experienceYears =
          _calculateExperienceYears(providerData['experience'] as String?);

      // Calculate new trust score
      final newTrustScore = verification.calculateTrustScore(
        rating: rating,
        reviewCount: reviewCount,
        completedBookings: completedBookings,
        verifiedCertificates: verifiedCertificates,
        backgroundCheckPassed: backgroundCheckPassed,
        experienceYears: experienceYears,
      );

      // Update trust score
      await _firestore.collection(_collection).doc(providerId).update({
        'trustScore': newTrustScore,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Also update in providers collection for easy access
      await _firestore.collection('providers').doc(providerId).update({
        'trustScore': newTrustScore,
        'verificationStatus': verification.status.name,
        'trustLevel': verification.getTrustLevel(),
      });
    } catch (e) {
      print('Error updating trust score: $e');
    }
  }

  // Calculate experience years from experience string
  int _calculateExperienceYears(String? experience) {
    if (experience == null) return 0;

    switch (experience.toLowerCase()) {
      case 'beginner':
        return 1;
      case 'intermediate':
        return 3;
      case 'expert':
        return 5;
      default:
        return 0;
    }
  }

  // Get all verified providers
  Future<List<ProviderVerification>> getVerifiedProviders() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: VerificationStatus.verified.name)
          .get();

      return snapshot.docs
          .map((doc) => ProviderVerification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting verified providers: $e');
      return [];
    }
  }

  // Get providers by trust level
  Future<List<ProviderVerification>> getProvidersByTrustLevel(
      String trustLevel) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: VerificationStatus.verified.name)
          .get();

      final verifications = snapshot.docs
          .map((doc) => ProviderVerification.fromMap(doc.data()))
          .toList();

      return verifications
          .where((v) => v.getTrustLevel() == trustLevel)
          .toList();
    } catch (e) {
      print('Error getting providers by trust level: $e');
      return [];
    }
  }

  // Request background check
  Future<void> requestBackgroundCheck(String providerId) async {
    await updateBackgroundCheckStatus(
        providerId, BackgroundCheckStatus.inProgress);

    // In a real implementation, this would integrate with a background check service
    // For now, we'll simulate the process
    await _simulateBackgroundCheck(providerId);
  }

  // Simulate background check process
  Future<void> _simulateBackgroundCheck(String providerId) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // For demo purposes, randomly pass/fail
    final random = DateTime.now().millisecond % 10;
    final passed = random > 2; // 70% pass rate

    await updateBackgroundCheckStatus(
      providerId,
      passed ? BackgroundCheckStatus.passed : BackgroundCheckStatus.failed,
    );

    // Update trust score after background check
    await updateTrustScore(providerId);
  }

  // Get verification statistics
  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      int total = 0;
      int verified = 0;
      int pending = 0;
      int rejected = 0;
      int suspended = 0;
      double avgTrustScore = 0.0;
      int totalTrustScore = 0;

      for (final doc in snapshot.docs) {
        final verification = ProviderVerification.fromMap(doc.data());
        total++;
        totalTrustScore += verification.trustScore.toInt();

        switch (verification.status) {
          case VerificationStatus.verified:
            verified++;
            break;
          case VerificationStatus.pending:
            pending++;
            break;
          case VerificationStatus.rejected:
            rejected++;
            break;
          case VerificationStatus.suspended:
            suspended++;
            break;
        }
      }

      avgTrustScore = total > 0 ? totalTrustScore / total : 0.0;

      return {
        'total': total,
        'verified': verified,
        'pending': pending,
        'rejected': rejected,
        'suspended': suspended,
        'avgTrustScore': avgTrustScore,
        'verificationRate': total > 0 ? (verified / total * 100) : 0.0,
      };
    } catch (e) {
      print('Error getting verification stats: $e');
      return {};
    }
  }
}
