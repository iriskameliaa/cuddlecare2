import 'package:flutter/material.dart';
import '../services/telegram_bot_diagnostics.dart';
import '../services/bot_config_service.dart';
import '../services/telegram_polling_service.dart';

class BotDiagnosticsScreen extends StatefulWidget {
  const BotDiagnosticsScreen({super.key});

  @override
  State<BotDiagnosticsScreen> createState() => _BotDiagnosticsScreenState();
}

class _BotDiagnosticsScreenState extends State<BotDiagnosticsScreen> {
  Map<String, dynamic>? _diagnosticResults;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running diagnostics...';
    });

    try {
      final results = await TelegramBotDiagnostics.runDiagnostics();
      setState(() {
        _diagnosticResults = results;
        _isLoading = false;
        _statusMessage = 'Diagnostics complete';
      });

      // Print to console for debugging
      TelegramBotDiagnostics.printDiagnostics(results);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _deleteWebhook() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting webhook...';
    });

    final success = await TelegramBotDiagnostics.deleteWebhook();
    setState(() {
      _isLoading = false;
      _statusMessage =
          success ? 'Webhook deleted successfully' : 'Failed to delete webhook';
    });

    if (success) {
      await _runDiagnostics();
    }
  }

  Future<void> _startPolling() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting polling...';
    });

    try {
      await TelegramPollingService.startPolling();
      setState(() {
        _isLoading = false;
        _statusMessage = 'Polling started successfully';
      });
      await _runDiagnostics();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Failed to start polling: $e';
      });
    }
  }

  Future<void> _setWebhook() async {
    // Your actual Firebase Functions URL (confirmed from deployment)
    const webhookUrl =
        'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';

    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting webhook...';
    });

    final success = await TelegramBotDiagnostics.setWebhook(webhookUrl);
    setState(() {
      _isLoading = false;
      _statusMessage =
          success ? 'Webhook set successfully' : 'Failed to set webhook';
    });

    if (success) {
      await _runDiagnostics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Diagnostics'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDiagnostics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Diagnostics',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Diagnostic Results
            if (!_isLoading && _diagnosticResults != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDiagnosticCard(),
                      const SizedBox(height: 20),
                      _buildRecommendationsCard(),
                      const SizedBox(height: 20),
                      _buildActionsCard(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard() {
    final results = _diagnosticResults!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bot Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
                'Token Available', results['token_available'] ?? false),
            _buildStatusRow(
                'Token Valid', results['token_format_valid'] ?? false),
            _buildStatusRow(
                'Bot Connected', results['bot_connection'] ?? false),
            _buildStatusRow(
                'Webhook Active', results['webhook_active'] ?? false),
            if (results['bot_info'] != null) ...[
              const SizedBox(height: 8),
              Text('Bot: @${results['bot_info']['username']}'),
              Text('Name: ${results['bot_info']['first_name']}'),
            ],
            if (results['webhook_info'] != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final webhookInfo =
                      results['webhook_info'] as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Webhook URL: ${webhookInfo['url'] ?? 'None'}'),
                      Text(
                          'Pending Updates: ${webhookInfo['pending_update_count'] ?? 0}'),
                      if (webhookInfo['last_error_message'] != null)
                        Text(
                          'Last Error: ${webhookInfo['last_error_message']}',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations =
        _diagnosticResults!['recommendations'] as List<String>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(rec),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteWebhook,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Webhook'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startPolling,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Polling'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _setWebhook,
                  icon: const Icon(Icons.webhook),
                  label: const Text('Set Webhook'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
