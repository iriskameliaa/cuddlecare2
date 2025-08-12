import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, verified, rejected, suspended }

enum BackgroundCheckStatus { notStarted, inProgress, passed, failed }

class ProviderVerification {
  final String providerId;
  final VerificationStatus status;
  final BackgroundCheckStatus backgroundCheckStatus;
  final List<String> verifiedCertificates;
  final List<String> pendingCertificates;
  final double trustScore;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final Map<String, dynamic> verificationData;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderVerification({
    required this.providerId,
    this.status = VerificationStatus.pending,
    this.backgroundCheckStatus = BackgroundCheckStatus.notStarted,
    this.verifiedCertificates = const [],
    this.pendingCertificates = const [],
    this.trustScore = 0.0,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.verificationData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'status': status.name,
      'backgroundCheckStatus': backgroundCheckStatus.name,
      'verifiedCertificates': verifiedCertificates,
      'pendingCertificates': pendingCertificates,
      'trustScore': trustScore,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'verificationData': verificationData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProviderVerification.fromMap(Map<String, dynamic> map) {
    return ProviderVerification(
      providerId: map['providerId'] as String,
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      backgroundCheckStatus: BackgroundCheckStatus.values.firstWhere(
        (e) => e.name == map['backgroundCheckStatus'],
        orElse: () => BackgroundCheckStatus.notStarted,
      ),
      verifiedCertificates:
          List<String>.from(map['verifiedCertificates'] ?? []),
      pendingCertificates: List<String>.from(map['pendingCertificates'] ?? []),
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0.0,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
      verifiedBy: map['verifiedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      verificationData:
          Map<String, dynamic>.from(map['verificationData'] ?? {}),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Calculate trust score based on various factors
  double calculateTrustScore({
    required double rating,
    required int reviewCount,
    required int completedBookings,
    required int verifiedCertificates,
    required bool backgroundCheckPassed,
    required int experienceYears,
  }) {
    double score = 0.0;

    // Rating contribution (40% of total)
    score += (rating / 5.0) * 40;

    // Review count contribution (20% of total)
    score += (reviewCount / 50.0).clamp(0.0, 1.0) * 20;

    // Completed bookings contribution (15% of total)
    score += (completedBookings / 20.0).clamp(0.0, 1.0) * 15;

    // Verified certificates contribution (15% of total)
    score += (verifiedCertificates / 5.0).clamp(0.0, 1.0) * 15;

    // Background check contribution (10% of total)
    score += backgroundCheckPassed ? 10 : 0;

    return score.clamp(0.0, 100.0);
  }

  // Get verification badge based on status
  String getVerificationBadge() {
    switch (status) {
      case VerificationStatus.verified:
        return '✅ Verified Provider';
      case VerificationStatus.pending:
        return '⏳ Verification Pending';
      case VerificationStatus.rejected:
        return '❌ Verification Rejected';
      case VerificationStatus.suspended:
        return '🚫 Account Suspended';
    }
  }

  // Get trust level based on score
  String getTrustLevel() {
    if (trustScore >= 90) return '🔒 Premium Trusted';
    if (trustScore >= 75) return '✅ Highly Trusted';
    if (trustScore >= 60) return '👍 Trusted';
    if (trustScore >= 40) return '⚠️ Basic Trust';
    return '❓ New Provider';
  }
}
