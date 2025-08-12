import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bot_config_service.dart';

class TelegramBotService {
  static String? _botToken;
  static String? _baseUrl;

  // Initialize bot token and base URL
  static Future<void> _initializeBot() async {
    if (_botToken == null) {
      _botToken = await BotConfigService.getBotToken();
      _baseUrl = 'https://api.telegram.org/bot$_botToken';
    }
  }

  // Get base URL with current token
  static Future<String> get _getBaseUrl async {
    await _initializeBot();
    return _baseUrl ?? 'https://api.telegram.org/bot';
  }

  // Send notification to user
  static Future<bool> sendNotification({
    required String chatId,
    required String message,
    String? parseMode = 'HTML',
  }) async {
    try {
      final baseUrl = await _getBaseUrl;
      print('DEBUG: sendNotification - baseUrl: $baseUrl');
      print('DEBUG: sendNotification - chatId: $chatId');
      print('DEBUG: sendNotification - message length: ${message.length}');

      print('DEBUG: sendNotification - About to make HTTP request');
      final response = await http
          .post(
            Uri.parse('$baseUrl/sendMessage'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': chatId,
              'text': message,
              'parse_mode': parseMode,
            }),
          )
          .timeout(const Duration(seconds: 10));
      print('DEBUG: sendNotification - HTTP request completed');

      print(
          'DEBUG: sendNotification - response status: ${response.statusCode}');
      print('DEBUG: sendNotification - response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['ok'] == true;
        print('DEBUG: sendNotification - Telegram API ok: ${data['ok']}');
        return success;
      }
      print('DEBUG: sendNotification - HTTP error: ${response.statusCode}');
      return false;
    } catch (e) {
      print('DEBUG: sendNotification - Exception caught: $e');
      if (e.toString().contains('TimeoutException')) {
        print('DEBUG: sendNotification - Request timed out after 10 seconds');
      }
      print('Error sending Telegram notification: $e');
      return false;
    }
  }

  // Send booking notification to provider
  static Future<bool> sendBookingNotification({
    required String providerChatId,
    required String customerName,
    required String service,
    required String date,
    required String petName,
    required String bookingId,
  }) async {
    final message = '''
🔔 <b>New Booking Received!</b>

👤 <b>Customer:</b> $customerName
🐕 <b>Pet:</b> $petName
🛠 <b>Service:</b> $service
📅 <b>Date:</b> $date
🆔 <b>Booking ID:</b> $bookingId

Please respond to this booking in the CuddleCare app.
''';
    return await sendNotification(
      chatId: providerChatId,
      message: message,
    );
  }

  // Send status update notification
  static Future<bool> sendStatusUpdate({
    required String chatId,
    required String bookingId,
    required String status,
    required String providerName,
  }) async {
    final statusEmoji = _getStatusEmoji(status);
    final message = '''
$statusEmoji <b>Booking Status Update</b>

🆔 <b>Booking ID:</b> $bookingId
👨‍💼 <b>Provider:</b> $providerName
📊 <b>Status:</b> ${status.toUpperCase()}

Your booking status has been updated. Check the CuddleCare app for more details.
''';
    return await sendNotification(
      chatId: chatId,
      message: message,
    );
  }

  // Send service completion notification
  static Future<bool> sendServiceCompletion({
    required String customerChatId,
    required String providerName,
    required String service,
    required String bookingId,
  }) async {
    final message = '''
✅ <b>Service Completed!</b>

👨‍💼 <b>Provider:</b> $providerName
🛠 <b>Service:</b> $service
🆔 <b>Booking ID:</b> $bookingId

Your pet care service has been completed. Please leave a review in the CuddleCare app.
''';
    return await sendNotification(
      chatId: customerChatId,
      message: message,
    );
  }

  // Get status emoji
  static String _getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'cancelled':
        return '❌';
      case 'completed':
        return '🎉';
      default:
        return '📊';
    }
  }

  // Set up webhook for bot (admin function)
  static Future<bool> setWebhook(String webhookUrl) async {
    try {
      final baseUrl = await _getBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/setWebhook'),
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

  // Get bot info
  static Future<Map<String, dynamic>?> getBotInfo() async {
    try {
      final baseUrl = await _getBaseUrl;
      final response = await http.get(Uri.parse('$baseUrl/getMe'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting bot info: $e');
      return null;
    }
  }

  // Find user by Telegram ID
  static Future<Map<String, dynamic>?> findUserByTelegramId(
      String telegramId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('telegramId', isEqualTo: telegramId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return {
          'uid': querySnapshot.docs.first.id,
          ...userData,
        };
      }
      return null;
    } catch (e) {
      print('Error finding user by Telegram ID: $e');
      return null;
    }
  }

  // Send notification to user by Telegram ID
  static Future<bool> sendNotificationByTelegramId({
    required String telegramId,
    required String message,
    String? parseMode = 'HTML',
  }) async {
    try {
      final user = await findUserByTelegramId(telegramId);
      if (user != null) {
        return await sendNotification(
          chatId: telegramId,
          message: message,
          parseMode: parseMode,
        );
      }
      return false;
    } catch (e) {
      print('Error sending notification by Telegram ID: $e');
      return false;
    }
  }

  // Handle incoming messages (for webhook)
  static Future<Map<String, dynamic>> handleIncomingMessage(
      Map<String, dynamic> update) async {
    try {
      final message = update['message'];
      if (message == null) return {'status': 'no_message'};
      final chatId = message['chat']['id'].toString();
      final text = message['text'] ?? '';
      final from = message['from'];
      // Handle different commands
      if (text.startsWith('/start')) {
        return _handleStartCommand(chatId, from);
      } else if (text.startsWith('/help')) {
        return _handleHelpCommand(chatId);
      } else if (text.startsWith('/status')) {
        return _handleStatusCommand(chatId, text);
      } else if (text.startsWith('/bookings')) {
        return await _handleBookingsCommand(chatId,
            await findUserByTelegramId(chatId), from['first_name'] ?? 'User');
      } else {
        return _handleUnknownCommand(chatId, text);
      }
    } catch (e) {
      print('Error handling incoming message: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Handle /start command
  static Map<String, dynamic> _handleStartCommand(
      String chatId, Map<String, dynamic> from) {
    final message = '''
🤖 <b>Welcome to CuddleCare Bot!</b>

I'm here to help you with your pet care services.

<b>Available commands:</b>
/start - Show this welcome message
/help - Show help information
/status [booking_id] - Check booking status
/mybookings - View your upcoming bookings
/mypets - View your pet information

For support, contact us through the CuddleCare app.
''';
    sendNotification(chatId: chatId, message: message);
    return {'status': 'success', 'command': 'start'};
  }

  // Handle /help command
  static Map<String, dynamic> _handleHelpCommand(String chatId) {
    final message = '''
📋 <b>CuddleCare Bot Help</b>

<b>Commands:</b>
• /start - Welcome message
• /help - This help message
• /status [booking_id] - Check your booking status
• /mybookings - View your upcoming bookings
• /mypets - View your pet information

<b>Features:</b>
• Receive booking notifications
• Get status updates
• Service reminders
• Completion notifications

For detailed support, use the CuddleCare app.
''';
    sendNotification(chatId: chatId, message: message);
    return {'status': 'success', 'command': 'help'};
  }

  // Handle /status command
  static Map<String, dynamic> _handleStatusCommand(String chatId, String text) {
    final parts = text.split(' ');
    if (parts.length < 2) {
      sendNotification(
        chatId: chatId,
        message: '❌ Please provide a booking ID: /status [booking_id]',
      );
      return {'status': 'error', 'message': 'Missing booking ID'};
    }
    final bookingId = parts[1];
    // TODO: Implement booking status lookup from Firestore
    sendNotification(
      chatId: chatId,
      message:
          '🔍 Looking up booking status for ID: $bookingId\n\nThis feature is coming soon!',
    );
    return {'status': 'success', 'command': 'status', 'booking_id': bookingId};
  }

  // Handle unknown commands
  static Map<String, dynamic> _handleUnknownCommand(
      String chatId, String text) {
    sendNotification(
      chatId: chatId,
      message:
          '❓ Unknown command: $text\n\nUse /help to see available commands.',
    );
    return {'status': 'unknown_command', 'text': text};
  }

  // Handle /bookings command
  static Future<Map<String, dynamic>> _handleBookingsCommand(
      String chatId, Map<String, dynamic>? user, String userName) async {
    if (user == null) {
      sendNotification(
        chatId: chatId,
        message:
            '<b>User Not Found</b>\n\nIt looks like you havent registered with CuddleCare yet. Please register in the app first and add your Telegram ID to your profile.\n\nYour Telegram ID: <code>$chatId</code>',
      );
      return {'status': 'error', 'message': 'User not found'};
    }
    try {
      // Get user's bookings from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user['uid'])
          .orderBy('date', descending: true)
          .limit(5)
          .get();
      if (querySnapshot.docs.isEmpty) {
        sendNotification(
          chatId: chatId,
          message:
              '👋 <b>Your Bookings</b>\n\nHello $userName! You don\'t have any bookings yet.\n\nUse the CuddleCare app to book your first pet care service!',
        );
        return {'status': 'success', 'command': 'bookings', 'count': 0};
      }
      final bookings = querySnapshot.docs;
      final message = '''
📋 <b>Your Recent Bookings</b>\n\nHello $userName! Here are your recent bookings:\n\n${bookings.map((doc) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final statusEmoji = _getStatusEmoji(status);
        return '$statusEmoji <b>${data['service'] ?? 'Service'}</b>\n👨‍💼 ${data['providerName'] ?? 'Provider'}\n📅 ${data['date'] ?? 'Date TBD'}🆔 ${doc.id}\n';
      }).join('\n')}\n\nUse the CuddleCare app for more details and to manage your bookings.''';
      sendNotification(chatId: chatId, message: message);
      return {
        'status': 'success',
        'command': 'bookings',
        'count': bookings.length
      };
    } catch (e) {
      print('Error fetching bookings: $e');
      sendNotification(
        chatId: chatId,
        message: '❌ Error fetching your bookings. Please try again later.',
      );
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
