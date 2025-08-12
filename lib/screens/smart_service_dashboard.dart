import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/smart_telegram_service.dart';
import '../services/telegram_bot_service.dart';

class SmartServiceDashboard extends StatefulWidget {
  const SmartServiceDashboard({super.key});

  @override
  State<SmartServiceDashboard> createState() => _SmartServiceDashboardState();
}

class _SmartServiceDashboardState extends State<SmartServiceDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _botInfo;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _smartFeatures = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load bot info
      _botInfo = await SmartTelegramService.getSmartBotInfo();

      // Load analytics
      _analytics = await _loadAnalytics();

      // Load recent bookings
      _recentBookings = await _loadRecentBookings();

      // Load smart features
      _smartFeatures = _loadSmartFeatures();
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    // Simulate analytics data
    return {
      'totalBookings': 156,
      'activeProviders': 23,
      'totalCustomers': 89,
      'monthlyRevenue': 12500.0,
      'averageRating': 4.7,
      'smartFeaturesUsed': {
        'weatherIntegration': 45,
        'routeOptimization': 67,
        'autoReminders': 123,
        'photoUpdates': 89,
      },
      'botCommands': {
        '/schedule': 234,
        '/route': 156,
        '/weather': 89,
        '/recommend': 67,
        '/analytics': 45,
      },
    };
  }

  Future<List<Map<String, dynamic>>> _loadRecentBookings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'service': data['service'] ?? '',
          'status': data['status'] ?? '',
          'date': data['date'] ?? '',
          'petName': data['petName'] ?? '',
          'smartFeatures': data['smartFeatures'] ?? {},
        };
      }).toList();
    } catch (e) {
      print('Error loading recent bookings: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _loadSmartFeatures() {
    return [
      {
        'name': 'AI Recommendations',
        'description':
            'Smart service suggestions based on pet type and location',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'enabled': true,
        'usage': 234,
      },
      {
        'name': 'Weather Integration',
        'description': 'Real-time weather updates for outdoor services',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'enabled': true,
        'usage': 156,
      },
      {
        'name': 'Route Optimization',
        'description': 'Optimize provider routes for maximum efficiency',
        'icon': Icons.route,
        'color': Colors.blue,
        'enabled': true,
        'usage': 89,
      },
      {
        'name': 'Smart Reminders',
        'description': 'Context-aware reminders with weather and route info',
        'icon': Icons.notifications_active,
        'color': Colors.green,
        'enabled': true,
        'usage': 345,
      },
      {
        'name': 'Photo Updates',
        'description': 'Automated photo sharing during services',
        'icon': Icons.photo_camera,
        'color': Colors.pink,
        'enabled': true,
        'usage': 123,
      },
      {
        'name': 'Analytics Dashboard',
        'description': 'Real-time analytics and performance tracking',
        'icon': Icons.analytics,
        'color': Colors.indigo,
        'enabled': true,
        'usage': 67,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Service Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.purple.shade50,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.purple,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                      Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                      Tab(icon: Icon(Icons.smart_toy), text: 'Smart Features'),
                      Tab(icon: Icon(Icons.settings), text: 'Settings'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildAnalyticsTab(),
                      _buildSmartFeaturesTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Status Card
          _buildBotStatusCard(),
          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 16),

          // Recent Bookings
          _buildRecentBookingsCard(),
          const SizedBox(height: 16),

          // Smart Features Summary
          _buildSmartFeaturesSummary(),
        ],
      ),
    );
  }

  Widget _buildBotStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _botInfo != null ? Icons.check_circle : Icons.error,
                  color: _botInfo != null ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Telegram Bot Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _botInfo != null
                  ? 'Connected as @${_botInfo!['username']}'
                  : 'Bot not configured',
              style: TextStyle(
                color: _botInfo != null ? Colors.green : Colors.red,
              ),
            ),
            if (_botInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Smart Features: ${_botInfo!['smartFeatures']?.length ?? 0} enabled',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_analytics == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Bookings',
          _analytics!['totalBookings'].toString(),
          Icons.book_online,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Providers',
          _analytics!['activeProviders'].toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Monthly Revenue',
          '\$${_analytics!['monthlyRevenue'].toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Rating',
          _analytics!['averageRating'].toString(),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recent_actors, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Recent Smart Bookings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentBookings.isEmpty)
              const Center(
                child: Text('No recent bookings'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentBookings.length,
                itemBuilder: (context, index) {
                  final booking = _recentBookings[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(booking['status']),
                      child: Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(booking['service']),
                    subtitle:
                        Text('${booking['petName']} • ${booking['date']}'),
                    trailing: Chip(
                      label: Text(booking['status']),
                      backgroundColor:
                          _getStatusColor(booking['status']).withOpacity(0.2),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFeaturesSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Smart Features Usage',
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
              children: _smartFeatures.map((feature) {
                return Chip(
                  avatar: Icon(
                    feature['icon'],
                    color: feature['color'],
                    size: 16,
                  ),
                  label: Text('${feature['name']} (${feature['usage']})'),
                  backgroundColor: feature['color'].withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null)
      return const Center(child: Text('No analytics data'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Commands Analytics
          _buildBotCommandsAnalytics(),
          const SizedBox(height: 16),

          // Smart Features Usage
          _buildSmartFeaturesAnalytics(),
          const SizedBox(height: 16),

          // Performance Metrics
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildBotCommandsAnalytics() {
    final commands = _analytics!['botCommands'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bot Commands Usage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...commands.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(entry.key),
                    const Spacer(),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFeaturesAnalytics() {
    final features = _analytics!['smartFeaturesUsed'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Features Usage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...features.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(_formatFeatureName(entry.key)),
                    const Spacer(),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Response Time', '2.3s'),
            _buildMetricRow('Uptime', '99.8%'),
            _buildMetricRow('Error Rate', '0.2%'),
            _buildMetricRow('User Satisfaction', '4.7/5'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _smartFeatures.map((feature) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: feature['color'].withOpacity(0.2),
                child: Icon(
                  feature['icon'],
                  color: feature['color'],
                ),
              ),
              title: Text(feature['name']),
              subtitle: Text(feature['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${feature['usage']} uses'),
                  const SizedBox(width: 8),
                  Switch(
                    value: feature['enabled'],
                    onChanged: (value) {
                      setState(() {
                        feature['enabled'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bot Configuration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.token),
                    title: const Text('Bot Token'),
                    subtitle: Text(
                        _botInfo != null ? 'Configured' : 'Not configured'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showBotTokenDialog(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.webhook),
                    title: const Text('Webhook URL'),
                    subtitle: const Text('Not configured'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showWebhookDialog(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Smart Features Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Features Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto Weather Updates'),
                    subtitle: const Text(
                        'Send weather alerts before outdoor services'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Route Optimization'),
                    subtitle:
                        const Text('Automatically optimize provider routes'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Smart Reminders'),
                    subtitle: const Text('Send context-aware reminders'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Photo Updates'),
                    subtitle:
                        const Text('Request photo updates during services'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFeatureName(String feature) {
    return feature
        .replaceAll(RegExp(r'([A-Z])'), ' \$1')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }

  void _showBotTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Bot Token'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Bot Token',
            hintText: 'Enter your Telegram bot token',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bot token updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWebhookDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Webhook'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Webhook URL',
            hintText: 'https://your-domain.com/webhook',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Webhook URL updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
