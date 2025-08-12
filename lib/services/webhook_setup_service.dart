import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bot_config_service.dart';

class WebhookSetupService {
  static const String _baseUrl = 'https://api.telegram.org/bot';
  static const String _webhookUrl = 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';

  /// Set up webhook for the Telegram bot
  static Future<Map<String, dynamic>> setupWebhook() async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No bot token available'
        };
      }

      // First, delete any existing webhook
      await _deleteWebhook(token);
      
      // Wait a moment for the deletion to process
      await Future.delayed(const Duration(seconds: 2));

      // Set the new webhook
      final response = await http.post(
        Uri.parse('$_baseUrl$token/setWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': _webhookUrl,
          'allowed_updates': ['message'],
          'drop_pending_updates': true, // Clear any pending updates
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          // Verify the webhook was set correctly
          final webhookInfo = await _getWebhookInfo(token);
          return {
            'success': true,
            'message': 'Webhook set successfully',
            'webhook_url': _webhookUrl,
            'webhook_info': webhookInfo,
          };
        } else {
          return {
            'success': false,
            'error': data['description'] ?? 'Unknown error setting webhook'
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: $e'
      };
    }
  }

  /// Delete existing webhook
  static Future<bool> _deleteWebhook(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$token/deleteWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'drop_pending_updates': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting webhook: $e');
      return false;
    }
  }

  /// Get current webhook information
  static Future<Map<String, dynamic>?> _getWebhookInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$token/getWebhookInfo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting webhook info: $e');
      return null;
    }
  }

  /// Test the webhook by sending a test message to Telegram API
  static Future<Map<String, dynamic>> testWebhook() async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No bot token available'
        };
      }

      // Get webhook info
      final webhookInfo = await _getWebhookInfo(token);
      if (webhookInfo == null) {
        return {
          'success': false,
          'error': 'Could not get webhook info'
        };
      }

      final webhookUrl = webhookInfo['url'];
      final pendingUpdates = webhookInfo['pending_update_count'] ?? 0;
      final lastErrorDate = webhookInfo['last_error_date'];
      final lastErrorMessage = webhookInfo['last_error_message'];

      String status = 'Unknown';
      if (webhookUrl == null || webhookUrl.toString().isEmpty) {
        status = 'No webhook set';
      } else if (webhookUrl == _webhookUrl) {
        if (lastErrorDate != null) {
          status = 'Webhook has errors';
        } else if (pendingUpdates > 0) {
          status = 'Webhook may not be working (pending updates)';
        } else {
          status = 'Webhook appears to be working';
        }
      } else {
        status = 'Webhook set to different URL';
      }

      return {
        'success': true,
        'status': status,
        'webhook_url': webhookUrl,
        'expected_url': _webhookUrl,
        'pending_updates': pendingUpdates,
        'last_error_date': lastErrorDate,
        'last_error_message': lastErrorMessage,
        'webhook_info': webhookInfo,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: $e'
      };
    }
  }

  /// Get bot information
  static Future<Map<String, dynamic>> getBotInfo() async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'No bot token available'
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$token/getMe'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return {
            'success': true,
            'bot_info': data['result'],
          };
        } else {
          return {
            'success': false,
            'error': data['description'] ?? 'Unknown error getting bot info'
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: $e'
      };
    }
  }

  /// Complete webhook setup with verification
  static Future<Map<String, dynamic>> completeWebhookSetup() async {
    print('🚀 Starting complete webhook setup...');
    
    // Step 1: Get bot info
    final botInfoResult = await getBotInfo();
    if (!botInfoResult['success']) {
      return {
        'success': false,
        'step': 'bot_info',
        'error': botInfoResult['error']
      };
    }

    print('✅ Bot info retrieved: @${botInfoResult['bot_info']['username']}');

    // Step 2: Setup webhook
    final webhookResult = await setupWebhook();
    if (!webhookResult['success']) {
      return {
        'success': false,
        'step': 'webhook_setup',
        'error': webhookResult['error']
      };
    }

    print('✅ Webhook set successfully');

    // Step 3: Test webhook
    await Future.delayed(const Duration(seconds: 3)); // Wait for webhook to be active
    final testResult = await testWebhook();

    return {
      'success': true,
      'bot_info': botInfoResult['bot_info'],
      'webhook_result': webhookResult,
      'test_result': testResult,
      'message': 'Webhook setup completed successfully! Your bot should now respond to /start commands.'
    };
  }
}
