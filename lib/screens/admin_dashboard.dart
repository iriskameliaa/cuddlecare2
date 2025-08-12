import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_verification_dashboard.dart';
import 'admin_analytics_dashboard.dart';
import 'admin_user_management.dart';
import 'welcome_screen.dart';
import '../utils/fix_chat_rooms.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content:
              const Text('Are you sure you want to logout from admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Navigate to welcome screen and clear the navigation stack
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminHomeTab(onNavigateToTab: _navigateToTab),
      const AdminVerificationDashboard(),
      const AdminAnalyticsDashboard(),
      const AdminUserManagement(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text('Admin Dashboard'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ],
            )
          : null,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const AdminHomeTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Admin Dashboard',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to the CuddleCare Admin Panel',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Text(
            'Quick Overview',
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
            childAspectRatio: 1.2,
            children: [
              _buildQuickStatCard(
                context,
                'Provider Verification',
                'Manage provider verification process',
                Icons.verified_user,
                Colors.green,
                () => onNavigateToTab(1),
              ),
              _buildQuickStatCard(
                context,
                'Analytics',
                'View platform analytics and insights',
                Icons.analytics,
                Colors.blue,
                () => onNavigateToTab(2),
              ),
              _buildQuickStatCard(
                context,
                'User Management',
                'Manage all users and providers',
                Icons.people,
                Colors.purple,
                () => onNavigateToTab(3),
              ),
              _buildQuickStatCard(
                context,
                'System Status',
                'Check platform health and performance',
                Icons.monitor_heart,
                Colors.orange,
                () => _showSystemStatus(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  'Verify Providers',
                  Icons.verified_user,
                  Colors.green,
                  () => onNavigateToTab(1),
                ),
                _buildActionChip(
                  'View Analytics',
                  Icons.analytics,
                  Colors.blue,
                  () => onNavigateToTab(2),
                ),
                _buildActionChip(
                  'Manage Users',
                  Icons.people,
                  Colors.purple,
                  () => onNavigateToTab(3),
                ),
                _buildActionChip(
                  'System Status',
                  Icons.monitor_heart,
                  Colors.orange,
                  () => _showSystemStatus(context),
                ),
                _buildActionChip(
                  'Check Fadh Status',
                  Icons.search,
                  Colors.teal,
                  () => _checkFadhStatus(context),
                ),
                _buildActionChip(
                  'Fix Chat Rooms',
                  Icons.chat_bubble_outline,
                  Colors.indigo,
                  () => _fixChatRooms(context),
                ),
                _buildActionChip(
                  'Clean Chat Rooms',
                  Icons.cleaning_services,
                  Colors.red,
                  () => _cleanChatRooms(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  void _showSystemStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusItem('Database', 'Online', Colors.green),
            _buildStatusItem('Authentication', 'Online', Colors.green),
            _buildStatusItem('Storage', 'Online', Colors.green),
            _buildStatusItem('Analytics', 'Online', Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String service, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 8),
          Text(service),
          const Spacer(),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _checkFadhStatus(BuildContext context) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Search for Fadh in users collection
      final usersSnapshot = await firestore.collection('users').get();
      DocumentSnapshot? fadhUserDoc;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        final email = data['email'] ?? '';

        if (name.toLowerCase().contains('fadh') ||
            email.toLowerCase().contains('fadh')) {
          fadhUserDoc = doc;
          break;
        }
      }

      if (fadhUserDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fadh not found in users collection!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final fadhUserId = fadhUserDoc.id;
      final fadhUserData = fadhUserDoc.data() as Map<String, dynamic>;

      // Check verification status
      final verificationDoc = await firestore
          .collection('provider_verifications')
          .doc(fadhUserId)
          .get();

      String statusMessage = '';
      Color statusColor = Colors.blue;

      if (!verificationDoc.exists) {
        statusMessage = '❌ No verification record found for Fadh';
        statusColor = Colors.red;
      } else {
        final verificationData = verificationDoc.data() as Map<String, dynamic>;
        final status = verificationData['status'] as String? ?? 'pending';
        final trustScore =
            (verificationData['trustScore'] as num?)?.toDouble() ?? 0.0;

        switch (status) {
          case 'verified':
            statusMessage =
                '✅ Fadh is VERIFIED! Trust Score: ${trustScore.toStringAsFixed(1)}';
            statusColor = Colors.green;
            break;
          case 'pending':
            statusMessage =
                '⏳ Fadh verification is PENDING. Trust Score: ${trustScore.toStringAsFixed(1)}';
            statusColor = Colors.orange;
            break;
          case 'rejected':
            statusMessage =
                '❌ Fadh verification was REJECTED. Trust Score: ${trustScore.toStringAsFixed(1)}';
            statusColor = Colors.red;
            break;
          default:
            statusMessage =
                '❓ Fadh verification status: $status. Trust Score: ${trustScore.toStringAsFixed(1)}';
            statusColor = Colors.grey;
        }
      }

      // Show detailed status dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fadh Verification Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: ${fadhUserId.substring(0, 8)}...'),
              Text('Name: ${fadhUserData['name'] ?? 'N/A'}'),
              Text('Email: ${fadhUserData['email'] ?? 'N/A'}'),
              Text('Role: ${fadhUserData['role'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (verificationDoc.exists)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onNavigateToTab(1); // Go to verification dashboard
                },
                child: const Text('View in Verification'),
              ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error checking Fadh status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fixChatRooms(BuildContext context) async {
    // Show confirmation dialog
    final shouldFix = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Chat Rooms'),
        content: const Text(
          'This will attempt to fix chat rooms with empty provider IDs by matching them with booking data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Fix Chat Rooms'),
          ),
        ],
      ),
    );

    if (shouldFix != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Fixing chat rooms...'),
          ],
        ),
      ),
    );

    try {
      await ChatRoomFixer.fixEmptyProviderIds();

      Navigator.pop(context); // Close loading dialog

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fix Complete'),
          content: const Text(
            'Chat room fixing process completed successfully! Check the console logs for details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fixing chat rooms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cleanChatRooms(BuildContext context) async {
    // Show confirmation dialog
    final shouldClean = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Chat Rooms'),
        content: const Text(
          'This will permanently delete chat rooms that have no valid booking or provider information. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Orphaned Rooms'),
          ),
        ],
      ),
    );

    if (shouldClean != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Cleaning chat rooms...'),
          ],
        ),
      ),
    );

    try {
      await ChatRoomFixer.deleteOrphanedChatRooms();

      Navigator.pop(context); // Close loading dialog

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cleanup Complete'),
          content: const Text(
            'Chat room cleanup process completed successfully! Check the console logs for details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cleaning chat rooms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
