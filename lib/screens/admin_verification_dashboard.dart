import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_verification.dart';
import '../services/verification_service.dart';
import '../services/sample_data_service.dart';

class AdminVerificationDashboard extends StatefulWidget {
  const AdminVerificationDashboard({super.key});

  @override
  State<AdminVerificationDashboard> createState() =>
      _AdminVerificationDashboardState();
}

class _AdminVerificationDashboardState
    extends State<AdminVerificationDashboard> {
  final VerificationService _verificationService = VerificationService();
  final SampleDataService _sampleDataService = SampleDataService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _verificationService.getVerificationStats();

      // If no data exists, automatically create sample data
      if (stats['total'] == 0) {
        print('No verification data found. Creating sample data...');
        await _sampleDataService.createAllSampleData();
        // Reload stats after creating sample data
        final newStats = await _verificationService.getVerificationStats();
        setState(() {
          _stats = newStats;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample verification data created automatically!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Verification Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create_sample':
                  _createSampleData();
                  break;
                case 'clear_sample':
                  _clearSampleData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_sample',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Create Sample Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_sample',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Sample Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatsCards(),
                  const SizedBox(height: 16),

                  // Show create sample data button if no data exists
                  if (_stats['total'] == 0) _buildNoDataWidget(),
                  const SizedBox(height: 24),

                  // Verification Management
                  _buildSectionTitle('Verification Management'),
                  const SizedBox(height: 16),

                  // Pending Verifications
                  _buildPendingVerifications(),
                  const SizedBox(height: 24),

                  // Background Checks
                  _buildSectionTitle('Background Checks'),
                  const SizedBox(height: 16),

                  _buildBackgroundCheckRequests(),
                  const SizedBox(height: 24),

                  // Certificate Verification
                  _buildSectionTitle('Certificate Verification'),
                  const SizedBox(height: 16),

                  _buildCertificateVerifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Providers',
          '${_stats['total'] ?? 0}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Verified',
          '${_stats['verified'] ?? 0}',
          Icons.verified,
          Colors.green,
        ),
        _buildStatCard(
          'Pending',
          '${_stats['pending'] ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Trust Score',
          '${(_stats['avgTrustScore'] ?? 0.0).toStringAsFixed(1)}',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 48),
          const SizedBox(height: 16),
          Text(
            'No Provider Data Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create sample verification data to test the system',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _createSampleData,
                icon: const Icon(Icons.add_circle),
                label: const Text('Create Sample Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPendingVerifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('provider_verifications')
          .where('status', isEqualTo: VerificationStatus.pending.name)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.error, color: Colors.red.shade700, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Permission Denied',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin access required. Please ensure you are logged in as admin.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final verifications = snapshot.data?.docs ?? [];

        if (verifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No pending verifications'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: verifications.length,
          itemBuilder: (context, index) {
            final verification = ProviderVerification.fromMap(
              verifications[index].data() as Map<String, dynamic>,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.person, color: Colors.orange.shade700),
                ),
                title: Text(
                    'Provider ${verification.providerId.substring(0, 8)}...'),
                subtitle: Text(
                    'Trust Score: ${verification.trustScore.toStringAsFixed(1)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _approveVerification(verification.providerId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _rejectVerification(verification.providerId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundCheckRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('provider_verifications')
          .where('backgroundCheckStatus',
              isEqualTo: BackgroundCheckStatus.inProgress.name)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.error, color: Colors.red.shade700, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Permission Denied',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin access required for background check management.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final verifications = snapshot.data?.docs ?? [];

        if (verifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No background checks in progress'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: verifications.length,
          itemBuilder: (context, index) {
            final verification = ProviderVerification.fromMap(
              verifications[index].data() as Map<String, dynamic>,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.security, color: Colors.red.shade700),
                ),
                title: Text(
                    'Background Check - ${verification.providerId.substring(0, 8)}...'),
                subtitle: const Text('Processing...'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _approveBackgroundCheck(verification.providerId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _rejectBackgroundCheck(verification.providerId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCertificateVerifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('provider_verifications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final verifications = snapshot.data?.docs ?? [];
        final pendingCertificates = <ProviderVerification>[];

        for (final doc in verifications) {
          final verification = ProviderVerification.fromMap(
            doc.data() as Map<String, dynamic>,
          );
          if (verification.pendingCertificates.isNotEmpty) {
            pendingCertificates.add(verification);
          }
        }

        if (pendingCertificates.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No certificates pending verification'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingCertificates.length,
          itemBuilder: (context, index) {
            final verification = pendingCertificates[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.description, color: Colors.blue.shade700),
                ),
                title: Text(
                    'Certificates - ${verification.providerId.substring(0, 8)}...'),
                subtitle:
                    Text('${verification.pendingCertificates.length} pending'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _approveCertificates(verification.providerId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _rejectCertificates(verification.providerId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveVerification(String providerId) async {
    try {
      await _verificationService.updateVerificationStatus(
        providerId,
        VerificationStatus.verified,
        verifiedBy: 'admin',
      );
      await _verificationService.updateTrustScore(providerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(String providerId) async {
    final reason = await _showRejectionDialog();
    if (reason != null) {
      try {
        await _verificationService.updateVerificationStatus(
          providerId,
          VerificationStatus.rejected,
          rejectionReason: reason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Provider verification rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _approveBackgroundCheck(String providerId) async {
    try {
      await _verificationService.updateBackgroundCheckStatus(
        providerId,
        BackgroundCheckStatus.passed,
      );
      await _verificationService.updateTrustScore(providerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background check approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBackgroundCheck(String providerId) async {
    try {
      await _verificationService.updateBackgroundCheckStatus(
        providerId,
        BackgroundCheckStatus.failed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background check rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveCertificates(String providerId) async {
    try {
      final verification =
          await _verificationService.getVerification(providerId);
      if (verification != null) {
        for (final certificate in verification.pendingCertificates) {
          await _verificationService.verifyCertificate(providerId, certificate);
        }
        await _verificationService.updateTrustScore(providerId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificates approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCertificates(String providerId) async {
    try {
      final verification =
          await _verificationService.getVerification(providerId);
      if (verification != null) {
        // Remove all pending certificates
        for (final certificate in verification.pendingCertificates) {
          await FirebaseFirestore.instance
              .collection('provider_verifications')
              .doc(providerId)
              .update({
            'pendingCertificates': FieldValue.arrayRemove([certificate]),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificates rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSampleData() async {
    try {
      await _sampleDataService.createAllSampleData();
      await _loadStats(); // Refresh the stats

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample verification data created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearSampleData() async {
    try {
      await _sampleDataService.clearSampleData();
      await _loadStats(); // Refresh the stats

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data cleared successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing sample data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Please provide a reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
