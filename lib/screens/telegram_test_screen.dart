import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/telegram_bot_service.dart';
import '../services/telegram_polling_service.dart';

class TelegramTestScreen extends StatefulWidget {
  const TelegramTestScreen({super.key});

  @override
  State<TelegramTestScreen> createState() => _TelegramTestScreenState();
}

class _TelegramTestScreenState extends State<TelegramTestScreen> {
  final TextEditingController _chatIdController = TextEditingController();
  bool _isPolling = false;
  List<Map<String, dynamic>> _usersWithTelegram = [];
  List<Map<String, dynamic>> _recentBookings = [];
  List<Map<String, dynamic>> _recentPets = [];
  bool _isLoading = true;
  Duration? _lastResponseTime;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _chatIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    setState(() => _isLoading = true);

    try {
      // Load users with Telegram Chat IDs
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('telegramChatId', isNull: false)
          .get();

      _usersWithTelegram = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load recent bookings
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _recentBookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load recent pets
      final petsSnapshot =
          await FirebaseFirestore.instance.collection('pets').limit(5).get();

      _recentPets = petsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot Testing'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildCurrentDataSection(),
                  const SizedBox(height: 24),
                  _buildTestingInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPolling ? Icons.check_circle : Icons.error,
                  color: _isPolling ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bot Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isPolling
                  ? 'Bot is running and listening for commands (2s intervals)'
                  : 'Bot is not running',
              style: TextStyle(
                color: _isPolling ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isPolling ? null : _startPolling,
                  child: const Text('Start Polling'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isPolling ? _stopPolling : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Stop Polling'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 Tip: Bot now responds within 2-4 seconds!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatIdController,
                    decoration: const InputDecoration(
                      labelText: 'Chat ID',
                      hintText: 'Enter your Telegram Chat ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendTestMessage,
                  child: const Text('Send Test'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildActionChip('Test /start', () => _testCommand('/start')),
                _buildActionChip('Test /help', () => _testCommand('/help')),
                _buildActionChip(
                    'Test /mybookings', () => _testCommand('/mybookings')),
                _buildActionChip('Test /mypets', () => _testCommand('/mypets')),
                _buildActionChip(
                    'Test /weather', () => _testCommand('/weather')),
                _buildActionChip(
                    'Test /recommend', () => _testCommand('/recommend')),
              ],
            ),
            const SizedBox(height: 16),
            _buildResponseTimeTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.purple.withOpacity(0.1),
      labelStyle: const TextStyle(color: Colors.purple),
    );
  }

  Widget _buildResponseTimeTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response Time Test',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test how quickly the bot responds to commands:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testResponseTime,
                    icon: const Icon(Icons.speed),
                    label: const Text('Test Response Time'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastResponseTime != null)
              Text(
                'Last response time: ${_lastResponseTime!.inMilliseconds}ms',
                style: TextStyle(
                  color: _lastResponseTime! < const Duration(seconds: 3)
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testResponseTime() async {
    if (_chatIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Chat ID first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      final success = await TelegramPollingService.sendTestMessage(
        _chatIdController.text,
      );

      stopwatch.stop();
      setState(() {
        _lastResponseTime = stopwatch.elapsed;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Response time: ${stopwatch.elapsed.inMilliseconds}ms'),
            backgroundColor: stopwatch.elapsed < const Duration(seconds: 3)
                ? Colors.green
                : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test failed - check your Chat ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCurrentDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Data',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildDataCard(
          'Users with Telegram',
          _usersWithTelegram.length,
          _usersWithTelegram
              .map((u) => '${u['name']}: ${u['telegramChatId']}')
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildDataCard(
          'Recent Bookings',
          _recentBookings.length,
          _recentBookings
              .map((b) => '${b['service']} for ${b['petName']}')
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildDataCard(
          'Recent Pets',
          _recentPets.length,
          _recentPets.map((p) => '${p['name']} (${p['breed']})').toList(),
        ),
      ],
    );
  }

  Widget _buildDataCard(String title, int count, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: count > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $item',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
              if (items.length > 3)
                Text(
                  '... and ${items.length - 3} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestingInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testing Instructions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              '1',
              'Connect to Bot',
              'Open Telegram → Search @CuddleCare_app1_bot → Send /start',
            ),
            _buildInstructionStep(
              '2',
              'Get Chat ID',
              'Use @userinfobot to get your Chat ID, or use @RawDataBot',
            ),
            _buildInstructionStep(
              '3',
              'Enter Chat ID',
              'Enter your Chat ID in the field above and click "Send Test"',
            ),
            _buildInstructionStep(
              '4',
              'Test Commands',
              'Send commands to the bot: /start, /help, /mybookings, etc.',
            ),
            _buildInstructionStep(
              '5',
              'Check Results',
              'The bot will respond with your data or demo data if no real data exists',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
      String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPolling() async {
    try {
      await TelegramPollingService.startPolling();
      setState(() => _isPolling = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bot polling started successfully!'),
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

  void _stopPolling() {
    TelegramPollingService.stopPolling();
    setState(() => _isPolling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bot polling stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _sendTestMessage() async {
    final chatId = _chatIdController.text.trim();
    if (chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Chat ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '''
🤖 <b>Test Message from CuddleCare!</b>

This is a test message to verify your bot connection.

<b>Your bot is working correctly!</b>

Try these commands:
/mybookings - View your bookings
/mypets - View your pets
/weather - Check weather
/recommend - Get recommendations

🐾 Welcome to CuddleCare!
''',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send test message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testCommand(String command) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send "$command" to @CuddleCare_app1_bot'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
