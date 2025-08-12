import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bot_config_service.dart';

class TelegramBotDiagnostics {
  static const String _baseUrl = 'https://api.telegram.org/bot';

  /// Run comprehensive bot diagnostics
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check bot token
      final token = await BotConfigService.getBotToken();
      results['token_available'] = token != null;
      results['token_format_valid'] = token != null && BotConfigService.isValidToken(token);
      
      if (token == null) {
        results['error'] = 'No bot token available';
        return results;
      }

      // 2. Test bot connection
      final botInfo = await _testBotConnection(token);
      results['bot_connection'] = botInfo != null;
      results['bot_info'] = botInfo;

      // 3. Check webhook status
      final webhookInfo = await _getWebhookInfo(token);
      results['webhook_info'] = webhookInfo;
      results['webhook_active'] = webhookInfo?['url'] != null && webhookInfo!['url'].toString().isNotEmpty;

      // 4. Test sending a message (if we have a test chat ID)
      // results['message_test'] = await _testSendMessage(token, 'YOUR_TEST_CHAT_ID');

      // 5. Check for conflicts
      results['polling_enabled'] = await _checkPollingStatus();
      
      // 6. Recommendations
      results['recommendations'] = _generateRecommendations(results);

    } catch (e) {
      results['error'] = 'Diagnostic failed: $e';
    }

    return results;
  }

  /// Test bot connection by calling getMe
  static Future<Map<String, dynamic>?> _testBotConnection(String token) async {
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

  /// Check if polling is currently enabled
  static Future<bool> _checkPollingStatus() async {
    // This would check your polling service status
    // For now, return false as we're focusing on webhooks
    return false;
  }

  /// Test sending a message to a specific chat
  static Future<bool> _testSendMessage(String token, String chatId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$token/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': '🤖 Bot diagnostic test message',
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

  /// Generate recommendations based on diagnostic results
  static List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];

    if (results['token_available'] != true) {
      recommendations.add('❌ Bot token is missing. Configure it in BotConfigService.');
    }

    if (results['token_format_valid'] != true) {
      recommendations.add('❌ Bot token format is invalid. Should be like: 123456789:ABC-DEF...');
    }

    if (results['bot_connection'] != true) {
      recommendations.add('❌ Cannot connect to Telegram API. Check token and internet connection.');
    }

    if (results['webhook_active'] == true && results['polling_enabled'] == true) {
      recommendations.add('⚠️ Both webhook and polling are active. This can cause conflicts.');
    }

    if (results['webhook_active'] != true) {
      recommendations.add('⚠️ No webhook is set. Bot will only work with polling or manual webhook setup.');
    }

    final webhookInfo = results['webhook_info'] as Map<String, dynamic>?;
    if (webhookInfo != null) {
      final pendingUpdateCount = webhookInfo['pending_update_count'] ?? 0;
      if (pendingUpdateCount > 0) {
        recommendations.add('⚠️ $pendingUpdateCount pending updates. Webhook might not be working properly.');
      }

      final lastErrorDate = webhookInfo['last_error_date'];
      if (lastErrorDate != null) {
        final lastErrorMessage = webhookInfo['last_error_message'] ?? 'Unknown error';
        recommendations.add('❌ Webhook error: $lastErrorMessage');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ Bot configuration looks good!');
    }

    return recommendations;
  }

  /// Delete webhook (useful for switching to polling)
  static Future<bool> deleteWebhook() async {
    try {
      final token = await BotConfigService.getBotToken();
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

  /// Set webhook to a specific URL
  static Future<bool> setWebhook(String webhookUrl) async {
    try {
      final token = await BotConfigService.getBotToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl$token/setWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': webhookUrl,
          'allowed_updates': ['message'],
        }),
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

  /// Print diagnostic results in a readable format
  static void printDiagnostics(Map<String, dynamic> results) {
    print('\n🔍 TELEGRAM BOT DIAGNOSTICS');
    print('=' * 40);
    
    print('Token Available: ${results['token_available'] ? '✅' : '❌'}');
    print('Token Valid: ${results['token_format_valid'] ? '✅' : '❌'}');
    print('Bot Connected: ${results['bot_connection'] ? '✅' : '❌'}');
    print('Webhook Active: ${results['webhook_active'] ? '✅' : '❌'}');
    
    final botInfo = results['bot_info'] as Map<String, dynamic>?;
    if (botInfo != null) {
      print('Bot Username: @${botInfo['username']}');
      print('Bot Name: ${botInfo['first_name']}');
    }

    final webhookInfo = results['webhook_info'] as Map<String, dynamic>?;
    if (webhookInfo != null) {
      print('Webhook URL: ${webhookInfo['url'] ?? 'None'}');
      print('Pending Updates: ${webhookInfo['pending_update_count'] ?? 0}');
    }

    print('\n📋 RECOMMENDATIONS:');
    final recommendations = results['recommendations'] as List<String>? ?? [];
    for (final rec in recommendations) {
      print('  $rec');
    }
    
    print('=' * 40);
  }
}
