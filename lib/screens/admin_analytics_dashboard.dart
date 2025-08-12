import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/verification_service.dart';

class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _verificationStats = {};
  bool _isLoading = true;
  final VerificationService _verificationService = VerificationService();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Get verification stats from the service
      final verificationStats =
          await _verificationService.getVerificationStats();

      // Get all collections data
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final providersSnapshot =
          await FirebaseFirestore.instance.collection('providers').get();

      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      // Calculate analytics
      final analytics = await _calculateAnalytics(
        usersSnapshot.docs,
        providersSnapshot.docs,
        bookingsSnapshot.docs,
      );

      setState(() {
        _analytics = analytics;
        _verificationStats = verificationStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _calculateAnalytics(
    List<QueryDocumentSnapshot> users,
    List<QueryDocumentSnapshot> providers,
    List<QueryDocumentSnapshot> bookings,
  ) async {
    // User statistics
    int totalUsers = 0;
    int totalProviders = 0;

    // Booking statistics
    int totalBookings = 0;
    int confirmedBookings = 0;
    int pendingBookings = 0;
    int completedBookings = 0;
    int cancelledBookings = 0;

    // Calculate user stats
    for (final doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['role'] == 'provider' || data['isPetSitter'] == true) {
        totalProviders++;
      } else {
        totalUsers++;
      }
    }

    // Calculate booking stats
    for (final doc in bookings) {
      final data = doc.data() as Map<String, dynamic>;
      totalBookings++;
      final status = data['status'] as String? ?? 'pending';
      switch (status) {
        case 'confirmed':
          confirmedBookings++;
          break;
        case 'pending':
          pendingBookings++;
          break;
        case 'completed':
          completedBookings++;
          break;
        case 'cancelled':
          cancelledBookings++;
          break;
      }
    }

    // Calculate percentages
    final bookingCompletionRate = totalBookings > 0
        ? (completedBookings / totalBookings * 100).roundToDouble()
        : 0.0;

    return {
      'totalUsers': totalUsers,
      'totalProviders': totalProviders,
      'totalBookings': totalBookings,
      'confirmedBookings': confirmedBookings,
      'pendingBookings': pendingBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'bookingCompletionRate': bookingCompletionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
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
                  // Overview Cards
                  _buildOverviewCards(),
                  const SizedBox(height: 24),

                  // Trust Score Statistics
                  _buildTrustScoreStats(),
                  const SizedBox(height: 24),

                  // Detailed Statistics
                  _buildDetailedStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildOverviewCard(
              'Total Users',
              '${_analytics['totalUsers'] ?? 0}',
              Icons.people,
              Colors.blue,
            ),
            _buildOverviewCard(
              'Total Providers',
              '${_analytics['totalProviders'] ?? 0}',
              Icons.work,
              Colors.green,
            ),
            _buildOverviewCard(
              'Total Bookings',
              '${_analytics['totalBookings'] ?? 0}',
              Icons.calendar_today,
              Colors.orange,
            ),
            _buildOverviewCard(
              'Verification Rate',
              '${_verificationStats['verificationRate']?.toStringAsFixed(1) ?? '0'}%',
              Icons.verified_user,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustScoreStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trust Score Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trust Score Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Average Trust Score',
                    '${(_verificationStats['avgTrustScore'] ?? 0.0).toStringAsFixed(1)}/100'),
                _buildStatRow('Verified Providers',
                    '${_verificationStats['verified'] ?? 0}'),
                _buildStatRow('Pending Verifications',
                    '${_verificationStats['pending'] ?? 0}'),
                _buildStatRow('Rejected Verifications',
                    '${_verificationStats['rejected'] ?? 0}'),
                _buildStatRow('Suspended Providers',
                    '${_verificationStats['suspended'] ?? 0}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
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

  Widget _buildDetailedStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Booking Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                    'Total Bookings', '${_analytics['totalBookings'] ?? 0}'),
                _buildStatRow('Confirmed Bookings',
                    '${_analytics['confirmedBookings'] ?? 0}'),
                _buildStatRow('Pending Bookings',
                    '${_analytics['pendingBookings'] ?? 0}'),
                _buildStatRow('Completed Bookings',
                    '${_analytics['completedBookings'] ?? 0}'),
                _buildStatRow('Cancelled Bookings',
                    '${_analytics['cancelledBookings'] ?? 0}'),
                _buildStatRow('Completion Rate',
                    '${_analytics['bookingCompletionRate']?.toStringAsFixed(1) ?? '0'}%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
