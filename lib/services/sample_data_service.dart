import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_verification.dart';

class SampleDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create sample provider verification data for testing
  Future<void> createSampleVerificationData() async {
    try {
      // Sample provider verification data
      final sampleVerifications = [
        {
          'providerId': 'provider_001',
          'status': VerificationStatus.pending.name,
          'backgroundCheckStatus': BackgroundCheckStatus.notStarted.name,
          'verifiedCertificates': [],
          'pendingCertificates': ['cert_001.pdf', 'cert_002.pdf'],
          'trustScore': 0.0,
          'verificationData': {
            'name': 'Sarah Johnson',
            'email': 'sarah.johnson@example.com',
            'phone': '+1234567890',
            'experience': 'intermediate',
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'providerId': 'provider_002',
          'status': VerificationStatus.verified.name,
          'backgroundCheckStatus': BackgroundCheckStatus.passed.name,
          'verifiedCertificates': ['cert_003.pdf', 'cert_004.pdf'],
          'pendingCertificates': [],
          'trustScore': 85.5,
          'verifiedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'verifiedBy': 'admin',
          'verificationData': {
            'name': 'Michael Chen',
            'email': 'michael.chen@example.com',
            'phone': '+1234567891',
            'experience': 'expert',
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'providerId': 'provider_003',
          'status': VerificationStatus.pending.name,
          'backgroundCheckStatus': BackgroundCheckStatus.inProgress.name,
          'verifiedCertificates': [],
          'pendingCertificates': ['cert_005.pdf'],
          'trustScore': 0.0,
          'verificationData': {
            'name': 'Emily Rodriguez',
            'email': 'emily.rodriguez@example.com',
            'phone': '+1234567892',
            'experience': 'beginner',
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        },
        {
          'providerId': 'provider_004',
          'status': VerificationStatus.verified.name,
          'backgroundCheckStatus': BackgroundCheckStatus.passed.name,
          'verifiedCertificates': ['cert_006.pdf', 'cert_007.pdf', 'cert_008.pdf'],
          'pendingCertificates': [],
          'trustScore': 92.3,
          'verifiedAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'verifiedBy': 'admin',
          'verificationData': {
            'name': 'David Thompson',
            'email': 'david.thompson@example.com',
            'phone': '+1234567893',
            'experience': 'expert',
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        },
        {
          'providerId': 'provider_005',
          'status': VerificationStatus.rejected.name,
          'backgroundCheckStatus': BackgroundCheckStatus.failed.name,
          'verifiedCertificates': [],
          'pendingCertificates': [],
          'trustScore': 0.0,
          'rejectionReason': 'Failed background check - criminal record found',
          'verificationData': {
            'name': 'John Smith',
            'email': 'john.smith@example.com',
            'phone': '+1234567894',
            'experience': 'intermediate',
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        },
      ];

      // Create the documents
      for (final verification in sampleVerifications) {
        await _firestore
            .collection('provider_verifications')
            .doc(verification['providerId'] as String)
            .set(verification);
      }

      print('Sample verification data created successfully!');
    } catch (e) {
      print('Error creating sample data: $e');
      rethrow;
    }
  }

  // Create sample provider data to complement verification data
  Future<void> createSampleProviderData() async {
    try {
      final sampleProviders = [
        {
          'providerId': 'provider_001',
          'name': 'Sarah Johnson',
          'email': 'sarah.johnson@example.com',
          'phone': '+1234567890',
          'experience': 'intermediate',
          'rating': 4.2,
          'completedBookings': 15,
          'trustScore': 0.0,
          'verificationStatus': VerificationStatus.pending.name,
          'trustLevel': 'New Provider',
        },
        {
          'providerId': 'provider_002',
          'name': 'Michael Chen',
          'email': 'michael.chen@example.com',
          'phone': '+1234567891',
          'experience': 'expert',
          'rating': 4.8,
          'completedBookings': 45,
          'trustScore': 85.5,
          'verificationStatus': VerificationStatus.verified.name,
          'trustLevel': 'Highly Trusted',
        },
        {
          'providerId': 'provider_003',
          'name': 'Emily Rodriguez',
          'email': 'emily.rodriguez@example.com',
          'phone': '+1234567892',
          'experience': 'beginner',
          'rating': 4.0,
          'completedBookings': 8,
          'trustScore': 0.0,
          'verificationStatus': VerificationStatus.pending.name,
          'trustLevel': 'New Provider',
        },
        {
          'providerId': 'provider_004',
          'name': 'David Thompson',
          'email': 'david.thompson@example.com',
          'phone': '+1234567893',
          'experience': 'expert',
          'rating': 4.9,
          'completedBookings': 67,
          'trustScore': 92.3,
          'verificationStatus': VerificationStatus.verified.name,
          'trustLevel': 'Premium Trusted',
        },
        {
          'providerId': 'provider_005',
          'name': 'John Smith',
          'email': 'john.smith@example.com',
          'phone': '+1234567894',
          'experience': 'intermediate',
          'rating': 3.5,
          'completedBookings': 12,
          'trustScore': 0.0,
          'verificationStatus': VerificationStatus.rejected.name,
          'trustLevel': 'New Provider',
        },
      ];

      for (final provider in sampleProviders) {
        await _firestore
            .collection('providers')
            .doc(provider['providerId'] as String)
            .set(provider);
      }

      print('Sample provider data created successfully!');
    } catch (e) {
      print('Error creating sample provider data: $e');
      rethrow;
    }
  }

  // Create all sample data
  Future<void> createAllSampleData() async {
    await createSampleVerificationData();
    await createSampleProviderData();
  }

  // Clear all sample data
  Future<void> clearSampleData() async {
    try {
      // Delete verification data
      final verificationSnapshot = await _firestore
          .collection('provider_verifications')
          .where('providerId', whereIn: [
            'provider_001',
            'provider_002',
            'provider_003',
            'provider_004',
            'provider_005'
          ])
          .get();

      for (final doc in verificationSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete provider data
      final providerSnapshot = await _firestore
          .collection('providers')
          .where('providerId', whereIn: [
            'provider_001',
            'provider_002',
            'provider_003',
            'provider_004',
            'provider_005'
          ])
          .get();

      for (final doc in providerSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Sample data cleared successfully!');
    } catch (e) {
      print('Error clearing sample data: $e');
      rethrow;
    }
  }
}
