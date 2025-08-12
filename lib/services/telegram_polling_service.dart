import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'telegram_bot_service.dart';
import 'telegram_webhook_handler.dart';
import 'bot_config_service.dart';

class TelegramPollingService {
  static Timer? _pollingTimer;
  static Timer? _healthCheckTimer;
  static int _lastUpdateId = 0;
  static bool _isPolling = false;
  static bool _isProcessing = false;
  static DateTime _lastSuccessfulPoll = DateTime.now();

  // Check if polling should be enabled
  static bool get _shouldEnablePolling {
    // Disable polling - using webhooks for production
    return false; // Always use webhooks
  }

  // Start polling for new messages
  static Future<void> startPolling() async {
    // Skip polling in debug mode
    if (!_shouldEnablePolling) {
      debugPrint('Debug mode: Skipping Telegram polling for faster hot reload');
      return;
    }

    if (_isPolling) {
      print('Polling already active');
      return;
    }

    // First, delete any existing webhook to avoid conflicts
    try {
      final token = await BotConfigService.getBotToken();
      if (token != null) {
        final baseUrl = 'https://api.telegram.org/bot$token';
        await http.post(Uri.parse('$baseUrl/deleteWebhook'));
        print('Deleted existing webhook to prevent conflicts');
      }
    } catch (e) {
      print('Error deleting webhook: $e');
    }

    // Force reset to 0 to catch all pending messages
    _lastUpdateId = 0;
    print('DEBUG: Force reset _lastUpdateId to 0 on startup');

    _isPolling = true;
    _lastSuccessfulPoll = DateTime.now();
    print('Starting Telegram bot polling with 2-second intervals...');

    // Start polling every 5 seconds to reduce debug spam
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isProcessing) {
        _pollForUpdates();
      }
    });

    // Start health check timer to restart polling if it gets stuck
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _performHealthCheck();
    });
  }

  // Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _isPolling = false;
    _isProcessing = false;
    print('Stopped Telegram bot polling');
  }

  // Restart polling (useful for resolving conflicts)
  static Future<void> restartPolling() async {
    print('Restarting Telegram bot polling...');
    stopPolling();

    // Wait a moment before restarting
    await Future.delayed(const Duration(seconds: 1));

    await startPolling();
  }

  // Poll for new updates from Telegram
  static Future<void> _pollForUpdates() async {
    if (_isProcessing) {
      print('DEBUG: Skipping poll - already processing');
      return; // Prevent overlapping requests
    }

    // Only log when there are updates to avoid spam
    _isProcessing = true;

    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) {
        print('Bot token not configured');
        return;
      }

      final baseUrl = 'https://api.telegram.org/bot$token';
      final url =
          '$baseUrl/getUpdates?offset=${_lastUpdateId + 1}&limit=10&timeout=5';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['ok'] == true && data['result'] != null) {
          final updates = data['result'] as List;

          // Update last successful poll time
          _lastSuccessfulPoll = DateTime.now();

          if (updates.isNotEmpty) {
            print('Received ${updates.length} updates');

            for (final update in updates) {
              print('DEBUG: Processing update ID: ${update['update_id']}');
              await _processUpdate(update);
              _lastUpdateId = update['update_id'];
            }
          }
        }
      } else if (response.statusCode == 409) {
        // Conflict error - stop polling and restart after delay
        print('Conflict detected (409). Stopping polling temporarily...');
        stopPolling();

        // Restart polling after 10 seconds (reduced from 30)
        Timer(const Duration(seconds: 10), () {
          if (!_isPolling) {
            startPolling();
          }
        });
      } else {
        print('Error polling updates: ${response.statusCode}');
        // Don't stop polling on HTTP errors, just continue
      }
    } catch (e) {
      print('Error in polling: $e');

      // Handle specific timeout errors more gracefully
      if (e.toString().contains('TimeoutException')) {
        print('Network timeout - continuing polling...');
      } else if (e.toString().contains('SocketException')) {
        print('Network connection issue - continuing polling...');
      } else {
        print('Unexpected polling error: $e');
      }

      // Don't stop polling on network errors, just continue
    } finally {
      _isProcessing = false;
    }
  }

  // Process a single update
  static Future<void> _processUpdate(Map<String, dynamic> update) async {
    try {
      print('DEBUG: Processing update: ${update['update_id']}');

      // Check if this is a message update
      if (update.containsKey('message')) {
        final message = update['message'];
        final chatId = message['chat']['id'].toString();
        final text = message['text'] ?? '';

        print('Processing message: "$text" from chat ID: $chatId');
        print('DEBUG: About to call TelegramWebhookHandler.handleWebhook');

        final result = await TelegramWebhookHandler.handleWebhook(update);
        print('Processed message: ${result['command']} - ${result['status']}');
        print('DEBUG: Finished processing update ${update['update_id']}');
      } else {
        print('DEBUG: Update ${update['update_id']} is not a message update');
      }
    } catch (e) {
      print('Error processing update: $e');
      print('DEBUG: Error details: ${e.toString()}');
    }
  }

  // Get current polling status
  static bool get isPolling => _isPolling;

  // Get last update ID
  static int get lastUpdateId => _lastUpdateId;

  // Initialize offset by getting recent updates without consuming them
  static Future<void> _initializeOffset() async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) return;

      final baseUrl = 'https://api.telegram.org/bot$token';
      // Get recent updates without consuming them (limit=1, no offset)
      final url = '$baseUrl/getUpdates?limit=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['result'] != null) {
          final updates = data['result'] as List;
          if (updates.isNotEmpty) {
            // Set offset to the latest update ID so we start fresh
            _lastUpdateId = updates.last['update_id'];
            print('DEBUG: Found latest update ID: $_lastUpdateId');
          } else {
            // No pending updates, start from 0
            _lastUpdateId = 0;
            print('DEBUG: No pending updates, starting from 0');
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error initializing offset: $e, starting from 0');
      _lastUpdateId = 0;
    }
  }

  // Reset the update ID to catch all pending messages
  static void resetUpdateId() {
    _lastUpdateId = 0;
    print('DEBUG: Reset _lastUpdateId to 0');
  }

  // Test the polling service
  static Future<bool> testPolling() async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) {
        return false;
      }
      final baseUrl = 'https://api.telegram.org/bot$token';
      final url = '$baseUrl/getUpdates?limit=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error testing polling: $e');
      return false;
    }
  }

  // Send a test message to verify bot is working
  static Future<bool> sendTestMessage(String chatId) async {
    try {
      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '''
🤖 <b>Test Message from CuddleCare Bot</b>

This is a test message to verify the bot is working correctly.

<b>Bot Status:</b> ✅ Active
<b>Polling:</b> ${isPolling ? '✅ Running' : '❌ Stopped'}
<b>Last Update ID:</b> $_lastUpdateId
<b>Response Time:</b> ⚡ Fast (2s intervals)

Try sending /start to see available commands!
''',
      );

      return success;
    } catch (e) {
      print('Error sending test message: $e');
      return false;
    }
  }

  // Perform health check and restart polling if needed
  static void _performHealthCheck() {
    if (!_isPolling) return;

    final now = DateTime.now();
    final timeSinceLastPoll = now.difference(_lastSuccessfulPoll);

    // If no successful poll in the last 5 minutes, restart polling
    if (timeSinceLastPoll.inMinutes >= 5) {
      print(
          'Health check failed: No successful poll in ${timeSinceLastPoll.inMinutes} minutes');
      print('Restarting Telegram bot polling due to health check failure...');

      // Restart polling
      restartPolling();
    } else {
      print(
          'Health check passed: Last successful poll ${timeSinceLastPoll.inMinutes} minutes ago');
    }
  }
}
