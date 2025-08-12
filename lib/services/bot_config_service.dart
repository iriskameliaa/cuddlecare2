import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BotConfigService {
  static String? _botToken;
  static String? _webhookUrl;
  static const String _baseUrl = 'https://api.telegram.org/bot';
  static const String _tokenKey = 'bot_token';
  static const String _webhookKey = 'webhook_url';

  // Fallback token for development (replace this with your actual token)
  static const String _fallbackToken =
      '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';

  // Check if bot services should be enabled
  static bool get _shouldEnableBotServices {
    // Enable bot services in debug mode for testing
    return true; // Changed from !kDebugMode to true for testing
  }

  // Get bot token from persistent storage
  static Future<String?> getBotToken() async {
    // Skip bot operations in debug mode
    if (!_shouldEnableBotServices) {
      debugPrint('Debug mode: Skipping bot token retrieval');
      return null;
    }

    if (_botToken != null) {
      return _botToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _botToken = prefs.getString(_tokenKey);

      // If SharedPreferences fails or returns null, use fallback token
      if (_botToken == null || _botToken!.isEmpty) {
        _botToken = _fallbackToken;
        print('Using fallback bot token');
      }

      return _botToken;
    } catch (e) {
      print('Error getting bot token: $e');
      // Use fallback token if SharedPreferences fails
      _botToken = _fallbackToken;
      print('Using fallback bot token due to SharedPreferences error');
      return _botToken;
    }
  }

  // Save bot token to persistent storage
  static Future<bool> saveBotToken(String token) async {
    try {
      _botToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('Bot token saved: ${token.substring(0, 10)}...');
      return true;
    } catch (e) {
      print('Error saving bot token: $e');
      // Still save to memory even if SharedPreferences fails
      _botToken = token;
      print('Bot token saved to memory only');
      return true;
    }
  }

  // Get webhook URL from persistent storage
  static Future<String?> getWebhookUrl() async {
    if (_webhookUrl != null) {
      return _webhookUrl;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _webhookUrl = prefs.getString(_webhookKey);
      return _webhookUrl;
    } catch (e) {
      print('Error getting webhook URL: $e');
      // Return empty string instead of null to avoid crashes
      return '';
    }
  }

  // Save webhook URL to persistent storage
  static Future<bool> saveWebhookUrl(String url) async {
    try {
      _webhookUrl = url;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webhookKey, url);
      print('Webhook URL saved: $url');
      return true;
    } catch (e) {
      print('Error saving webhook URL: $e');
      return false;
    }
  }

  // Validate bot token format
  static bool isValidToken(String token) {
    return token.contains(':') && token.length > 20;
  }

  // Test bot connection
  static Future<Map<String, dynamic>?> testBotConnection(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$token/getMe'),
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
      print('Error testing bot connection: $e');
      return null;
    }
  }

  // Get bot info with current token
  static Future<Map<String, dynamic>?> getBotInfo() async {
    final token = await getBotToken();
    if (token == null) return null;

    return await testBotConnection(token);
  }

  // Send test message
  static Future<bool> sendTestMessage(String chatId) async {
    try {
      final token = await getBotToken();
      if (token == null) return false;

      final message = '''
🤖 <b>Test Message from CuddleCare Bot</b>

This is a test message to verify your bot is working correctly.

✅ Bot is connected
✅ Messages can be sent
✅ Ready for smart services

Time: ${DateTime.now().toString()}
''';

      final response = await http.post(
        Uri.parse('$_baseUrl$token/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending test message: $e');
      return false;
    }
  }

  // Test bot API without sending message
  static Future<Map<String, dynamic>?> testBotAPI() async {
    try {
      final token = await getBotToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl$token/getMe'),
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
      print('Error testing bot API: $e');
      return null;
    }
  }

  // Set webhook
  static Future<bool> setWebhook(String webhookUrl) async {
    try {
      final token = await getBotToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl$token/setWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': webhookUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error setting webhook: $e');
      return false;
    }
  }

  // Delete webhook
  static Future<bool> deleteWebhook() async {
    try {
      final token = await getBotToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl$token/deleteWebhook'),
        headers: {'Content-Type': 'application/json'},
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

  // Get webhook info
  static Future<Map<String, dynamic>?> getWebhookInfo() async {
    try {
      final token = await getBotToken();
      if (token == null) return null;

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

  // Clear all bot configuration
  static Future<bool> clearConfiguration() async {
    try {
      _botToken = null;
      _webhookUrl = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_webhookKey);
      print('Configuration cleared');
      return true;
    } catch (e) {
      print('Error clearing configuration: $e');
      return false;
    }
  }

  // Check if bot is configured
  static Future<bool> isConfigured() async {
    final token = await getBotToken();
    return token != null && isValidToken(token);
  }

  // Check if bot is ready for testing
  static Future<bool> isBotReady() async {
    final token = await getBotToken();
    if (token == null || !isValidToken(token)) {
      return false;
    }

    // Test the token by making a simple API call
    try {
      final botInfo = await testBotConnection(token);
      return botInfo != null;
    } catch (e) {
      print('Error testing bot readiness: $e');
      return false;
    }
  }

  // Get configuration status
  static Future<Map<String, dynamic>> getConfigurationStatus() async {
    final token = await getBotToken();
    final webhookUrl = await getWebhookUrl();
    final botInfo = await getBotInfo();
    final webhookInfo = await getWebhookInfo();

    return {
      'tokenConfigured': token != null && isValidToken(token),
      'webhookConfigured': webhookUrl != null && webhookUrl.isNotEmpty,
      'botConnected': botInfo != null,
      'webhookActive': webhookInfo != null && webhookInfo['url'] != null,
      'botUsername': botInfo?['username'],
      'botName': botInfo?['first_name'],
    };
  }

  // Get current token for debugging
  static String? getCurrentToken() {
    return _botToken;
  }

  // Initialize bot configuration (call this on app startup)
  static Future<void> initializeBotConfig() async {
    try {
      await getBotToken(); // This will load from storage
      await getWebhookUrl(); // This will load from storage
      print('Bot configuration initialized');
    } catch (e) {
      print('Error initializing bot configuration: $e');
      // Continue even if initialization fails
    }
  }
}
