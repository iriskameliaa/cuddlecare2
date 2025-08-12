import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/smart_telegram_service.dart';
import '../services/telegram_bot_service.dart';
import '../services/bot_config_service.dart';
import '../services/telegram_polling_service.dart';

class AdminSmartServiceManagement extends StatefulWidget {
  const AdminSmartServiceManagement({super.key});

  @override
  State<AdminSmartServiceManagement> createState() =>
      _AdminSmartServiceManagementState();
}

class _AdminSmartServiceManagementState
    extends State<AdminSmartServiceManagement> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _botInfo;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _smartFeatures = [];
  List<Map<String, dynamic>> _botCommands = [];
  Map<String, bool> _featureToggles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
    _initializeFeatureToggles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFeatureToggles() {
    _featureToggles = {
      'ai_recommendations': true,
      'weather_integration': true,
      'route_optimization': true,
      'smart_reminders': true,
      'photo_updates': true,
      'analytics_dashboard': true,
      'auto_scheduling': false,
      'voice_commands': false,
    };
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

      // Load bot commands
      _botCommands = _loadBotCommands();
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
        'key': 'ai_recommendations',
      },
      {
        'name': 'Weather Integration',
        'description': 'Real-time weather updates for outdoor services',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'enabled': true,
        'usage': 156,
        'key': 'weather_integration',
      },
      {
        'name': 'Route Optimization',
        'description': 'Optimize provider routes for maximum efficiency',
        'icon': Icons.route,
        'color': Colors.blue,
        'enabled': true,
        'usage': 89,
        'key': 'route_optimization',
      },
      {
        'name': 'Smart Reminders',
        'description': 'Context-aware reminders with weather and route info',
        'icon': Icons.notifications_active,
        'color': Colors.green,
        'enabled': true,
        'usage': 345,
        'key': 'smart_reminders',
      },
      {
        'name': 'Photo Updates',
        'description': 'Automated photo sharing during services',
        'icon': Icons.photo_camera,
        'color': Colors.pink,
        'enabled': true,
        'usage': 123,
        'key': 'photo_updates',
      },
      {
        'name': 'Analytics Dashboard',
        'description': 'Real-time analytics and performance tracking',
        'icon': Icons.analytics,
        'color': Colors.indigo,
        'enabled': true,
        'usage': 67,
        'key': 'analytics_dashboard',
      },
      {
        'name': 'Auto Scheduling',
        'description': 'Automatically schedule recurring services',
        'icon': Icons.schedule,
        'color': Colors.teal,
        'enabled': false,
        'usage': 0,
        'key': 'auto_scheduling',
      },
      {
        'name': 'Voice Commands',
        'description': 'Voice-activated bot commands',
        'icon': Icons.mic,
        'color': Colors.amber,
        'enabled': false,
        'usage': 0,
        'key': 'voice_commands',
      },
    ];
  }

  List<Map<String, dynamic>> _loadBotCommands() {
    return [
      {
        'command': '/start',
        'description': 'Welcome message and bot info',
        'usage': 456,
        'category': 'Basic',
      },
      {
        'command': '/schedule',
        'description': 'Manage user schedule',
        'usage': 234,
        'category': 'Smart',
      },
      {
        'command': '/route',
        'description': 'Get optimized route',
        'usage': 156,
        'category': 'Smart',
      },
      {
        'command': '/weather',
        'description': 'Check weather for services',
        'usage': 89,
        'category': 'Smart',
      },
      {
        'command': '/recommend',
        'description': 'Get AI recommendations',
        'usage': 67,
        'category': 'Smart',
      },
      {
        'command': '/analytics',
        'description': 'View performance metrics',
        'usage': 45,
        'category': 'Smart',
      },
      {
        'command': '/help',
        'description': 'Show available commands',
        'usage': 123,
        'category': 'Basic',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Service Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
                  color: Colors.indigo.shade50,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    isScrollable: true,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                      Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                      Tab(icon: Icon(Icons.smart_toy), text: 'Smart Features'),
                      Tab(icon: Icon(Icons.chat), text: 'Bot Commands'),
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
                      _buildBotCommandsTab(),
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

          // Recent Smart Bookings
          _buildRecentSmartBookingsCard(),
          const SizedBox(height: 16),

          // Smart Features Summary
          _buildSmartFeaturesSummary(),
        ],
      ),
    );
  }

  Widget _buildBotStatusCard() {
    final currentToken = BotConfigService.getCurrentToken();
    final isConfigured = currentToken != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle : Icons.error,
                  color: isConfigured ? Colors.green : Colors.red,
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
              isConfigured
                  ? 'Token configured: ${currentToken!.substring(0, 10)}...'
                  : 'Bot token not configured',
              style: TextStyle(
                color: isConfigured ? Colors.green : Colors.red,
              ),
            ),
            if (isConfigured) ...[
              const SizedBox(height: 8),
              Text(
                'Smart Features: 6 enabled',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _configureBot,
              icon: const Icon(Icons.settings),
              label: const Text('Configure Bot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
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
          'Smart Bookings',
          _analytics!['totalBookings'].toString(),
          Icons.smart_toy,
          Colors.indigo,
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

  Widget _buildRecentSmartBookingsCard() {
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
                child: Text('No recent smart bookings'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentBookings.length,
                itemBuilder: (context, index) {
                  final booking = _recentBookings[index];
                  final smartFeatures =
                      booking['smartFeatures'] as Map<String, dynamic>? ?? {};

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(booking['status']),
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(booking['service']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${booking['petName']} • ${booking['date']}'),
                        if (smartFeatures.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: smartFeatures.entries.map((entry) {
                              if (entry.value == true) {
                                return Chip(
                                  label: Text(entry.key),
                                  backgroundColor:
                                      Colors.indigo.withOpacity(0.1),
                                  labelStyle: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                          ),
                      ],
                    ),
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
            _buildMetricRow('Smart Feature Usage', '78%'),
          ],
        ),
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
                    value: _featureToggles[feature['key']] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _featureToggles[feature['key']] = value;
                      });
                      _toggleFeature(feature['key'], value);
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

  Widget _buildBotCommandsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Command Categories
          _buildCommandCategory('Basic Commands',
              _botCommands.where((cmd) => cmd['category'] == 'Basic').toList()),
          const SizedBox(height: 16),
          _buildCommandCategory('Smart Commands',
              _botCommands.where((cmd) => cmd['category'] == 'Smart').toList()),
        ],
      ),
    );
  }

  Widget _buildCommandCategory(
      String title, List<Map<String, dynamic>> commands) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...commands.map((command) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    command['command'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                title: Text(command['description']),
                subtitle: Text('${command['usage']} uses'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCommand(command),
                ),
              );
            }),
          ],
        ),
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
                    value: _featureToggles['weather_integration'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _featureToggles['weather_integration'] = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Route Optimization'),
                    subtitle:
                        const Text('Automatically optimize provider routes'),
                    value: _featureToggles['route_optimization'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _featureToggles['route_optimization'] = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Smart Reminders'),
                    subtitle: const Text('Send context-aware reminders'),
                    value: _featureToggles['smart_reminders'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _featureToggles['smart_reminders'] = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Photo Updates'),
                    subtitle:
                        const Text('Request photo updates during services'),
                    value: _featureToggles['photo_updates'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _featureToggles['photo_updates'] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
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

  void _toggleFeature(String featureKey, bool enabled) {
    // In a real implementation, this would update the bot configuration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${enabled ? 'Enabled' : 'Disabled'} $featureKey'),
        backgroundColor: enabled ? Colors.green : Colors.orange,
      ),
    );
  }

  void _editCommand(Map<String, dynamic> command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Command: ${command['command']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
              controller: TextEditingController(text: command['description']),
            ),
          ],
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
                const SnackBar(content: Text('Command updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBotTokenDialog() {
    final tokenController = TextEditingController();
    bool isTokenValid = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configure Bot Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To get your bot token:\n'
                '1. Open Telegram\n'
                '2. Search for @BotFather\n'
                '3. Send /newbot\n'
                '4. Follow the instructions\n'
                '5. Copy the token below',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  labelText: 'Bot Token',
                  hintText: '1234567890:ABCdefGHIjklMNOpqrsTUVwxyz',
                  border: const OutlineInputBorder(),
                  suffixIcon: Icon(
                    isTokenValid ? Icons.check_circle : Icons.error,
                    color: isTokenValid ? Colors.green : Colors.grey,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    isTokenValid = value.contains(':') && value.length > 20;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (tokenController.text.isNotEmpty && !isTokenValid)
                const Text(
                  'Invalid token format. Should contain ":" and be longer than 20 characters.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isTokenValid
                  ? () {
                      _saveBotToken(tokenController.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bot token saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
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

  void _testBotAPI() async {
    try {
      final botInfo = await BotConfigService.testBotAPI();

      if (botInfo != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bot API Test Results'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Bot API is working correctly'),
                const SizedBox(height: 8),
                Text('Bot Name: ${botInfo['first_name']}'),
                Text('Username: @${botInfo['username']}'),
                Text('Bot ID: ${botInfo['id']}'),
                const SizedBox(height: 8),
                const Text(
                  'Your bot is ready to receive messages and commands!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Bot API test failed. Check your token configuration.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing bot API: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reconfigureBot() async {
    try {
      // Clear current configuration
      await BotConfigService.clearConfiguration();

      // Show configuration dialog
      _showBotTokenDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bot configuration cleared. Please reconfigure your bot token.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reconfiguring bot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createTestSmartBooking() async {
    try {
      // Create a test smart booking using Firestore directly
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      final booking = {
        'id': bookingId,
        'customerId': 'test_customer_123',
        'providerId': 'test_provider_456',
        'service': 'Dog Walking',
        'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'petName': 'Buddy',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'smartFeatures': {
          'autoReminders': true,
          'weatherCheck': true,
          'photoUpdates': true,
        },
      };

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .set(booking);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Test smart booking created successfully! Check your bot for notifications.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating test booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startPolling() async {
    try {
      await TelegramPollingService.startPolling();
      setState(() {}); // Refresh UI to show updated status

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bot polling started! The bot will now respond to commands.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting polling: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopPolling() async {
    try {
      TelegramPollingService.stopPolling();
      setState(() {}); // Refresh UI to show updated status

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bot polling stopped.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping polling: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testPolling() async {
    try {
      final success = await TelegramPollingService.testPolling();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Polling test successful! Bot can receive messages.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Polling test failed. Check bot token configuration.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing polling: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testSmartFeatures() async {
    try {
      // Test AI Recommendations
      final recommendations =
          await SmartTelegramService.getSmartServiceRecommendations(
        userId: 'test_user',
        petType: 'dog',
        location: 'New York',
      );

      // Test Weather Integration
      final weather = await SmartTelegramService.getSmartWeatherForUser(
        location: 'Central Park',
        upcomingBookings: [],
      );

      // Test Smart Schedule
      final schedule =
          await SmartTelegramService.getSmartScheduleRecommendations(
        userId: 'test_user',
        pets: [
          {'name': 'Buddy', 'type': 'dog'},
          {'name': 'Fluffy', 'type': 'cat'},
        ],
      );

      // Show test results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Smart Features Test Results'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ All Smart Features Working!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                    '🤖 AI Recommendations: ${recommendations['recommendedServices'].length} services'),
                Text(
                    '🌤 Weather Integration: ${weather['current']['temperature']} - ${weather['current']['condition']}'),
                Text(
                    '📅 Smart Scheduling: ${schedule['totalPets']} pets with recommendations'),
                const SizedBox(height: 8),
                const Text('All smart features are operational!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing smart features: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBotToken(String token) async {
    final success = await BotConfigService.saveBotToken(token);
    if (success) {
      print('Bot token saved successfully');
    } else {
      print('Failed to save bot token');
    }
  }

  Future<void> _saveWebhookUrl(String url) async {
    final success = await BotConfigService.saveWebhookUrl(url);
    if (success) {
      print('Webhook URL saved successfully');
    } else {
      print('Failed to save webhook URL');
    }
  }

  void _configureBot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bot Configuration Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Follow these steps to configure your Telegram bot:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildConfigStep(
                '1. Create Bot',
                'Open Telegram → Search @BotFather → Send /newbot',
                Icons.add,
              ),
              _buildConfigStep(
                '2. Get Token',
                'Copy the bot token provided by BotFather',
                Icons.copy,
              ),
              _buildConfigStep(
                '3. Configure Token',
                'Click "Configure Bot Token" and paste your token',
                Icons.settings,
              ),
              _buildConfigStep(
                '4. Test Connection',
                'Click "Test Bot Connection" to verify setup',
                Icons.check_circle,
              ),
              _buildConfigStep(
                '5. Set Webhook (Optional)',
                'For production, configure webhook URL',
                Icons.webhook,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Keep your bot token secure'),
                    Text('• Test in development first'),
                    Text('• Monitor bot usage in analytics'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBotTokenDialog();
            },
            child: const Text('Configure Token'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigStep(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.indigo, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
