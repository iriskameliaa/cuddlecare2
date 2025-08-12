import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telegram_bot_service.dart';
import 'bot_config_service.dart';
import 'smart_telegram_service.dart';
import 'telegram_polling_service.dart';

class TelegramWebhookHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Process incoming webhook data from Telegram
  static Future<Map<String, dynamic>> handleWebhook(
      Map<String, dynamic> webhookData) async {
    try {
      // Extract message from webhook data
      final message = webhookData['message'];
      if (message == null) {
        return {
          'status': 'no_message',
          'message': 'No message in webhook data'
        };
      }

      final chatId = message['chat']['id'].toString();
      final text = message['text'] ?? '';
      final from = message['from'];

      print('Received message: $text from chat ID: $chatId');

      // Get user data from Firestore by chat ID
      final user = await _getUserByChatId(chatId);

      // Handle different commands
      if (text.startsWith('/start')) {
        return await _handleStartCommand(chatId, from);
      } else if (text.startsWith('/help')) {
        return await _handleHelpCommand(chatId);
      } else if (text.startsWith('/status')) {
        return await _handleStatusCommand(chatId, text);
      } else if (text.startsWith('/mybookings')) {
        return await _handleMyBookingsCommand(chatId);
      } else if (text.startsWith('/mypets')) {
        return await _handleMyPetsCommand(chatId);
      } else if (text.startsWith('/link')) {
        return await _handleLinkCommand(chatId, text);
      } else if (text.startsWith('/unlink')) {
        return await _handleUnlinkCommand(chatId);
      } else if (text.startsWith('/reset')) {
        return await _handleResetCommand(chatId);
      } else if (text.startsWith('/review')) {
        return await _handleReviewCommand(chatId, text, user);
      } else if (_isReviewResponse(text)) {
        return await _handleReviewResponse(chatId, text, user);
      } else if (_isArrivalFeedback(text)) {
        return await _handleArrivalFeedback(chatId, text, user);
      } else {
        return await _handleUnknownCommand(chatId, text);
      }
    } catch (e) {
      print('Error handling webhook: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Handle /start command
  static Future<Map<String, dynamic>> _handleStartCommand(
      String chatId, Map<String, dynamic> from) async {
    // Try to auto-link user by email
    final userEmail =
        from['username'] != null ? '${from['username']}@telegram.com' : null;
    final userFirstName = from['first_name'] ?? '';
    final userLastName = from['last_name'] ?? '';

    Map<String, dynamic>? linkedUser;
    String linkMessage = '';

    if (userEmail != null) {
      // Try to find user by email
      linkedUser = await _getUserByEmail(userEmail);

      if (linkedUser != null) {
        // Auto-link the Telegram chat ID
        await _linkTelegramAccount(linkedUser['uid'], chatId);
        linkMessage = '''
✅ <b>Account Linked Successfully!</b>

Welcome back, ${linkedUser['name'] ?? userFirstName}!
Your Telegram account has been automatically linked to your CuddleCare account.

You can now:
• View your real bookings with /mybookings
• Check your pets with /mypets
• Receive booking notifications

''';
      }
    }

    // If no auto-link, show manual linking instructions
    if (linkedUser == null) {
      linkMessage = '''
🔗 <b>Link Your CuddleCare Account</b>

To see your real bookings and pets, please link your account:

<b>Option 1: Email Link</b>
Reply with your CuddleCare email:
/link email@example.com

<b>Option 2: App Link</b>
1. Open the CuddleCare app
2. Go to Profile → Telegram Settings
3. Enter your Telegram username: @${from['username'] ?? 'your_username'}

<b>Once linked, you'll see your real data!</b>
''';
    }

    final message = '''
🤖 <b>Welcome to CuddleCare Smart Service Bot!</b>

$linkMessage

<b>Available Commands:</b>
/start - Show this welcome message
/help - Show help information
/status [booking_id] - Check your booking status
/mybookings - View your upcoming bookings
/mypets - View your pet information

<b>What you'll receive:</b>
✅ Booking confirmations
✅ Service reminders
✅ Status updates
✅ Completion notifications

For support, contact us through the CuddleCare app.
''';

    final success = await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );

    return {
      'status': success ? 'success' : 'error',
      'command': 'start',
      'message':
          success ? 'Welcome message sent' : 'Failed to send welcome message'
    };
  }

  // Handle /help command
  static Future<Map<String, dynamic>> _handleHelpCommand(String chatId) async {
    final message = '''
📋 <b>CuddleCare Bot Help</b>

<b>Available Commands:</b>
• /start - Welcome message and account linking
• /help - This help message
• /link [email] - Link your CuddleCare account
• /unlink - Disconnect your Telegram account
• /status [booking_id] - Check your booking status
• /mybookings - View your upcoming bookings
• /mypets - View your pet information

<b>Account Linking:</b>
• Use /link email@example.com to link your account
• Or the bot will try to auto-link on first use
• Once linked, you'll see your real data

<b>Notifications you'll receive:</b>
• ✅ Booking confirmations
• ✅ Service reminders
• ✅ Status updates
• ✅ Completion notifications

For detailed support, use the CuddleCare app.
''';

    final success = await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );

    return {
      'status': success ? 'success' : 'error',
      'command': 'help',
      'message': success ? 'Help message sent' : 'Failed to send help message'
    };
  }

  // Handle /status command
  static Future<Map<String, dynamic>> _handleStatusCommand(
      String chatId, String text) async {
    final parts = text.split(' ');
    if (parts.length < 2) {
      final message = '''
❌ <b>Status Command Usage</b>

Please provide a booking ID:
/status [booking_id]

Example: /status booking_123
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'status',
        'message': 'Missing booking ID'
      };
    }

    final bookingId = parts[1];
    print('DEBUG: Looking up booking ID: $bookingId');

    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);
      print(
          'DEBUG: User lookup result: ${user != null ? 'Found user ${user['email']}' : 'User not found'}');

      if (user == null) {
        final message = '''
❌ <b>Account Not Linked</b>

Please link your CuddleCare account first:
/link your.email@example.com

Once linked, you can check your real booking status.
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'error' : 'error',
          'command': 'status',
          'message': 'Account not linked'
        };
      }

      // Get real booking from Firestore
      print('DEBUG: Looking for booking with ID: $bookingId');

      // First try exact match
      var bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      print('DEBUG: Exact match exists: ${bookingDoc.exists}');

      // If not found, try partial match (for user-friendly short IDs)
      if (!bookingDoc.exists) {
        print('DEBUG: Trying partial match for: $bookingId');
        // Use the new function to get ALL bookings (past and future)
        final allUserBookings = await _getAllUserBookings(user['uid']);

        // Find booking that starts with the provided ID
        final matchingBookings = allUserBookings
            .where((booking) => booking['id'].startsWith(bookingId))
            .toList();

        print(
            'DEBUG: Found ${matchingBookings.length} partial matches (including past bookings)');

        if (matchingBookings.length == 1) {
          // Get the document for the matching booking
          bookingDoc = await _firestore
              .collection('bookings')
              .doc(matchingBookings.first['id'])
              .get();
          print('DEBUG: Using partial match: ${bookingDoc.id}');
        } else if (matchingBookings.length > 1) {
          final message = '''
❌ <b>Multiple Bookings Found</b>

The ID "$bookingId" matches multiple bookings:
${matchingBookings.map((booking) => '• ${booking['id']} - ${booking['service'] ?? 'Unknown'}').join('\n')}

Please use a more specific booking ID.
''';

          final success = await TelegramBotService.sendNotification(
            chatId: chatId,
            message: message,
          );

          return {
            'status': success ? 'error' : 'error',
            'command': 'status',
            'booking_id': bookingId,
            'message': 'Multiple matches found'
          };
        }
      }

      if (!bookingDoc.exists) {
        final message = '''
❌ <b>Booking Not Found</b>

Booking ID: $bookingId

This booking doesn't exist or you don't have access to it.
Please check the booking ID and try again.
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'error' : 'error',
          'command': 'status',
          'booking_id': bookingId,
          'message': 'Booking not found'
        };
      }

      final booking = bookingDoc.data()!;

      // Verify the booking belongs to this user
      if (booking['userId'] != user['uid']) {
        final message = '''
❌ <b>Access Denied</b>

This booking doesn't belong to your account.
Please check the booking ID and try again.
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'error' : 'error',
          'command': 'status',
          'booking_id': bookingId,
          'message': 'Access denied'
        };
      }

      // Get provider information
      final provider = await _getProviderInfo(booking['providerId'] ?? '');

      final message = '''
🔍 <b>Booking Status</b>

🆔 <b>Booking ID:</b> $bookingId
📊 <b>Status:</b> ${booking['status']?.toUpperCase() ?? 'PENDING'}
👨‍💼 <b>Provider:</b> ${provider?['name'] ?? 'TBD'}
🛠 <b>Service:</b> ${booking['service'] ?? 'Unknown'}
🐕 <b>Pet:</b> ${booking['petName'] ?? 'Unknown'}
📅 <b>Date:</b> ${booking['date'] ?? 'TBD'}
🕐 <b>Time:</b> ${booking['time'] ?? 'TBD'}
📍 <b>Location:</b> ${booking['location'] ?? 'TBD'}
💰 <b>Price:</b> \$${booking['price']?.toString() ?? 'TBD'}

${booking['notes'] != null ? '📝 <b>Notes:</b> ${booking['notes']}\n' : ''}
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'status',
        'booking_id': bookingId,
        'message': success ? 'Real status sent' : 'Failed to send status'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Booking</b>

Unable to load booking status at the moment.
Please try again later or contact support.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'status',
        'booking_id': bookingId,
        'message': 'Error loading booking'
      };
    }
  }

  // Handle /schedule command
  static Future<Map<String, dynamic>> _handleScheduleCommand(
      String chatId, String text) async {
    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        final message = '''
📅 <b>Schedule Management</b>

To view and manage your schedule, please link your CuddleCare account:

<b>Quick Link:</b>
/link your.email@example.com

Once linked, you can:
• View your real schedule
• Manage your bookings
• Get scheduling recommendations
• Track your availability
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'schedule',
          'message': success
              ? 'Linking instructions sent'
              : 'Failed to send instructions'
        };
      }

      final parts = text.split(' ');
      final subCommand = parts.length > 1 ? parts[1].toLowerCase() : 'view';

      String message;
      switch (subCommand) {
        case 'view':
          // Get real user bookings
          final bookings = await _getUserBookings(user['uid']);
          final today = DateTime.now();
          final tomorrow = today.add(const Duration(days: 1));

          final todayBookings = bookings.where((b) {
            final bookingDate = DateTime.tryParse(b['date'] ?? '');
            return bookingDate != null &&
                bookingDate.year == today.year &&
                bookingDate.month == today.month &&
                bookingDate.day == today.day;
          }).toList();

          final tomorrowBookings = bookings.where((b) {
            final bookingDate = DateTime.tryParse(b['date'] ?? '');
            return bookingDate != null &&
                bookingDate.year == tomorrow.year &&
                bookingDate.month == tomorrow.month &&
                bookingDate.day == tomorrow.day;
          }).toList();

          message = '''
📅 <b>Your Schedule</b>

''';

          if (todayBookings.isNotEmpty) {
            message += '<b>Today (${today.toString().split(' ')[0]}):</b>\n';
            for (final booking in todayBookings) {
              message +=
                  '''⏰ ${booking['time'] ?? 'TBD'} - ${booking['service'] ?? 'Unknown'} (${booking['petName'] ?? 'Unknown'})\n''';
            }
            message += '\n';
          } else {
            message += '<b>Today:</b> No bookings scheduled\n\n';
          }

          if (tomorrowBookings.isNotEmpty) {
            message += '<b>Tomorrow:</b>\n';
            for (final booking in tomorrowBookings) {
              message +=
                  '''⏰ ${booking['time'] ?? 'TBD'} - ${booking['service'] ?? 'Unknown'} (${booking['petName'] ?? 'Unknown'})\n''';
            }
            message += '\n';
          } else {
            message += '<b>Tomorrow:</b> No bookings scheduled\n\n';
          }

          message += '''
<b>This Week:</b>
• Total Bookings: ${bookings.length}
• Total Value: \$${bookings.fold(0.0, (sum, b) => sum + (b['price'] ?? 0.0)).toStringAsFixed(2)}

Use /mybookings for detailed booking information!
''';
          break;
        case 'add':
          message = '''
✅ <b>Schedule Management</b>

To add a new booking, please use the CuddleCare app:

1. Open the CuddleCare app
2. Browse available providers
3. Select a service and time
4. Confirm your booking

Your new booking will appear in your schedule here!
''';
          break;
        default:
          message = '''
📅 <b>Schedule Commands</b>

/schedule view - View your real schedule
/schedule add - Instructions for adding bookings

<b>Note:</b> Bookings are managed through the CuddleCare app for the best experience.
''';
      }

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'schedule',
        'subcommand': subCommand,
        'message':
            success ? 'Real schedule info sent' : 'Failed to send schedule info'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Schedule</b>

Unable to load your schedule at the moment.
Please try again later.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'schedule',
        'message': 'Error loading schedule'
      };
    }
  }

  // Handle /weather command
  static Future<Map<String, dynamic>> _handleWeatherCommand(
      String chatId) async {
    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        final message = '''
🌤 <b>Weather Information</b>

To get personalized weather alerts for your pet services, please link your CuddleCare account:

<b>Quick Link:</b>
/link your.email@example.com

Once linked, you'll receive:
• Weather alerts for your service locations
• Pet care recommendations based on weather
• Service scheduling suggestions
• Safety tips for different weather conditions
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'weather',
          'message': success
              ? 'Linking instructions sent'
              : 'Failed to send instructions'
        };
      }

      // Get user's upcoming bookings to provide weather context
      final bookings = await _getUserBookings(user['uid']);
      final todayBookings = bookings.where((b) {
        final bookingDate = DateTime.tryParse(b['date'] ?? '');
        return bookingDate != null &&
            bookingDate.year == DateTime.now().year &&
            bookingDate.month == DateTime.now().month &&
            bookingDate.day == DateTime.now().day;
      }).toList();

      String message = '''
🌤 <b>Weather for Your Pet Services</b>

📍 <b>Location:</b> ${user['location'] ?? 'Your Area'}
🌡 <b>Temperature:</b> 22°C
☀️ <b>Condition:</b> Sunny

''';

      if (todayBookings.isNotEmpty) {
        message += '<b>Today\'s Services:</b>\n';
        for (final booking in todayBookings) {
          message += '''
⏰ ${booking['time'] ?? 'TBD'} - ${booking['service'] ?? 'Unknown'} (${booking['petName'] ?? 'Unknown'})
✅ Perfect weather for outdoor activities
☀️ Consider sunscreen for pets
💧 Hydration reminder enabled

''';
        }
      } else {
        message += '''
<b>No services scheduled today</b>
✅ Great weather for outdoor activities
☀️ Perfect conditions for pet walks
💧 Stay hydrated during outdoor time

''';
      }

      message += '''
<b>Weather Tips:</b>
• Great weather for outdoor activities
• Bring water for your pets
• Consider a light jacket for early morning
• Perfect conditions for outdoor services

Your pets will enjoy the beautiful weather! 🐕
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'weather',
        'message': success ? 'Weather info sent' : 'Failed to send weather info'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Weather</b>

Unable to load weather information at the moment.
Please try again later.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'weather',
        'message': 'Error loading weather'
      };
    }
  }

  // Handle /recommend command
  static Future<Map<String, dynamic>> _handleRecommendCommand(
      String chatId) async {
    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        final message = '''
🤖 <b>Personalized Recommendations</b>

To get personalized service recommendations based on your pets, please link your CuddleCare account:

<b>Quick Link:</b>
/link your.email@example.com

Once linked, you'll receive:
• Recommendations based on your actual pets
• Service suggestions for their specific needs
• Care tips tailored to your pets
• Personalized scheduling advice
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'recommend',
          'message': success
              ? 'Linking instructions sent'
              : 'Failed to send instructions'
        };
      }

      // Get user's pets for personalized recommendations
      final pets = await _getUserPets(user['uid']);

      if (pets.isEmpty) {
        final message = '''
🤖 <b>Personalized Recommendations</b>

You don't have any pets registered yet.

To get personalized recommendations:
1. Add your pets in the CuddleCare app
2. We'll analyze their needs
3. Provide tailored service suggestions

This helps us recommend the best services for your furry friends!
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'recommend',
          'message': success ? 'No pets message sent' : 'Failed to send message'
        };
      }

      // Build personalized recommendations based on real pets
      String message = '''
🤖 <b>Personalized Service Recommendations</b>

🐕 <b>Based on your pets:</b>
''';

      for (final pet in pets) {
        final name = pet['name'] ?? pet['type'] ?? 'Unknown';
        final breed = pet['breed'] ?? 'Unknown';
        final age = pet['age']?.toString() ?? 'Unknown';

        message += '''• $name ($breed) - Age: $age years\n''';
      }

      message += '''
<b>Recommended Services:</b>
''';

      // Generate recommendations based on pet types and breeds
      for (final pet in pets) {
        final name = pet['name'] ?? pet['type'] ?? 'Unknown';
        final type = pet['type']?.toString().toLowerCase() ?? 'pet';
        final breed = pet['breed']?.toString().toLowerCase() ?? '';

        if (type.contains('dog')) {
          message +=
              '''• 🐕 Dog Walking - Perfect for $name's energy level\n''';
          if (breed.contains('puppy') || breed.contains('young')) {
            message +=
                '''• 🏥 Health Check-up - Important for $name's development\n''';
          }
        } else if (type.contains('cat')) {
          message += '''• 🏠 Pet Sitting - Ideal for $name's comfort\n''';
          if (breed.contains('long') || breed.contains('persian')) {
            message += '''• ✂️ Grooming - Essential for $name's coat care\n''';
          }
        }
      }

      message += '''
<b>Why these services?</b>
Based on your pets' breeds, ages, and activity levels, these services will provide the best care and enrichment.

<b>Next Steps:</b>
• Book services through the CuddleCare app
• Set up recurring appointments
• Get personalized care tips

Your pets deserve the best care! 🐾
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'recommend',
        'message': success
            ? 'Personalized recommendations sent'
            : 'Failed to send recommendations'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Recommendations</b>

Unable to load personalized recommendations at the moment.
Please try again later.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'recommend',
        'message': 'Error loading recommendations'
      };
    }
  }

  // Handle /link command
  static Future<Map<String, dynamic>> _handleLinkCommand(
      String chatId, String text) async {
    print(
        'DEBUG: _handleLinkCommand called with chatId: $chatId, text: "$text"');

    final parts = text.split(' ');
    print('DEBUG: Split parts: $parts');

    if (parts.length < 2) {
      final message = '''
🔗 <b>Link Your Account</b>

Please provide your CuddleCare email:
/link email@example.com

Example: /link john.doe@example.com
''';

      print('DEBUG: Sending "missing email" message to chatId: $chatId');
      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );
      print('DEBUG: Send notification result: $success');

      return {
        'status': success ? 'error' : 'error',
        'command': 'link',
        'message': 'Missing email'
      };
    }

    final email = parts[1].trim();
    print('DEBUG: Looking up user with email: $email');

    final user = await _getUserByEmail(email);
    print(
        'DEBUG: User lookup result: ${user != null ? 'Found user' : 'User not found'}');

    if (user == null) {
      final message = '''
❌ <b>Account Not Found</b>

No CuddleCare account found with email: $email

Please check your email or create an account in the CuddleCare app first.

If you need help, contact support through the app.
''';

      print('DEBUG: Sending "account not found" message to chatId: $chatId');
      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );
      print('DEBUG: Send notification result for account not found: $success');

      return {
        'status': success ? 'error' : 'error',
        'command': 'link',
        'message': 'Account not found'
      };
    }

    // Link the account
    await _linkTelegramAccount(user['uid'], chatId);

    final message = '''
✅ <b>Account Linked Successfully!</b>

Welcome back, ${user['name'] ?? 'User'}!
Your Telegram account has been linked to your CuddleCare account.

You can now:
• View your real bookings with /mybookings
• Check your pets with /mypets
• Get personalized recommendations
• Receive booking notifications

Try /mybookings to see your upcoming bookings!
''';

    final success = await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );

    return {
      'status': success ? 'success' : 'error',
      'command': 'link',
      'email': email,
      'message': success ? 'Account linked' : 'Failed to link account'
    };
  }

  // Handle /unlink command
  static Future<Map<String, dynamic>> _handleUnlinkCommand(
      String chatId) async {
    try {
      // Check if user is currently linked
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        final message = '''
❌ <b>Account Not Linked</b>

Your Telegram account is not currently linked to any CuddleCare account.

To link an account, use:
/link your.email@example.com
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'error' : 'error',
          'command': 'unlink',
          'message': 'Account not linked'
        };
      }

      // Unlink the account by removing the telegramChatId
      await _unlinkTelegramAccount(user['uid'], chatId);

      final message = '''
✅ <b>Account Unlinked Successfully</b>

Your Telegram account has been disconnected from CuddleCare.

You will no longer receive:
• Booking notifications
• Status updates
• Personalized recommendations

To link again in the future, use:
/link your.email@example.com

Thank you for using CuddleCare! 🐾
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'unlink',
        'message': success ? 'Account unlinked' : 'Failed to unlink account'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Unlinking Account</b>

Unable to unlink your account at the moment.
Please try again later or contact support.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'error' : 'error',
        'command': 'unlink',
        'message': 'Error unlinking account'
      };
    }
  }

  // Handle /reset command (for debugging)
  static Future<Map<String, dynamic>> _handleResetCommand(String chatId) async {
    // Import the polling service to reset the offset
    TelegramPollingService.resetUpdateId();

    final message = '''
🔄 <b>Bot Reset</b>

The bot offset has been reset to catch all pending messages.
Try sending your commands again!
''';

    final success = await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );

    return {
      'status': success ? 'success' : 'error',
      'command': 'reset',
      'message': success ? 'Bot reset' : 'Failed to reset'
    };
  }

  // Handle unknown commands
  static Future<Map<String, dynamic>> _handleUnknownCommand(
      String chatId, String text) async {
    final message = '''
❓ <b>Unknown Command</b>

Command: $text

<b>Available Commands:</b>
/start - Welcome message and account linking
/help - Show help information
/link [email] - Link your CuddleCare account
/unlink - Disconnect your Telegram account
/status [booking_id] - Check your booking status
/mybookings - View your upcoming bookings
/mypets - View your pet information

Use /help to see all available commands.
''';

    final success = await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );

    return {
      'status': success ? 'unknown' : 'error',
      'command': 'unknown',
      'text': text,
      'message':
          success ? 'Unknown command response sent' : 'Failed to send response'
    };
  }

  // Handle /mybookings command
  static Future<Map<String, dynamic>> _handleMyBookingsCommand(
      String chatId) async {
    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        // Show linking instructions for unlinked users
        final message = '''
📅 <b>Your Upcoming Bookings</b>

To view your real bookings, please link your CuddleCare account:

<b>Quick Link:</b>
/link your.email@example.com

<b>Or link via app:</b>
1. Open CuddleCare app
2. Go to Profile → Telegram Settings  
3. Enter your Telegram username

<b>Once linked, you'll see:</b>
• Your actual upcoming bookings
• Service details and times
• Provider information
• Booking status updates

No demo data - only your real CuddleCare information!
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'mybookings',
          'message': success
              ? 'Linking instructions sent'
              : 'Failed to send instructions'
        };
      }

      // Get real user bookings
      final bookings = await _getUserBookings(user['uid']);

      if (bookings.isEmpty) {
        final message = '''
📅 <b>Your Upcoming Bookings</b>

You don't have any upcoming bookings at the moment.

To book a service:
1. Open the CuddleCare app
2. Browse available providers
3. Select a service and time
4. Confirm your booking

You'll receive notifications about your bookings here!
''';

        await TelegramBotService.sendNotification(
            chatId: chatId, message: message);
        return {'status': 'success', 'message': 'No bookings found'};
      }

      // Build real bookings message
      String message = '''
📅 <b>Your Upcoming Bookings</b>

''';

      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final todayBookings = bookings.where((b) {
        final bookingDate = DateTime.tryParse(b['date'] ?? '');
        return bookingDate != null &&
            bookingDate.year == today.year &&
            bookingDate.month == today.month &&
            bookingDate.day == today.day;
      }).toList();

      final tomorrowBookings = bookings.where((b) {
        final bookingDate = DateTime.tryParse(b['date'] ?? '');
        return bookingDate != null &&
            bookingDate.year == tomorrow.year &&
            bookingDate.month == tomorrow.month &&
            bookingDate.day == tomorrow.day;
      }).toList();

      if (todayBookings.isNotEmpty) {
        message += '<b>Today (${today.toString().split(' ')[0]}):</b>\n';
        for (final booking in todayBookings) {
          final provider = await _getProviderInfo(booking['providerId'] ?? '');
          message += '''
⏰ ${booking['time'] ?? 'TBD'} - ${booking['service'] ?? 'Unknown'} (${booking['petName'] ?? 'Unknown'})
👨‍💼 Provider: ${provider?['name'] ?? 'TBD'}
📍 Location: ${booking['location'] ?? 'TBD'}

''';
        }
      }

      if (tomorrowBookings.isNotEmpty) {
        message += '<b>Tomorrow:</b>\n';
        for (final booking in tomorrowBookings) {
          final provider = await _getProviderInfo(booking['providerId'] ?? '');
          message += '''
⏰ ${booking['time'] ?? 'TBD'} - ${booking['service'] ?? 'Unknown'} (${booking['petName'] ?? 'Unknown'})
👨‍💼 Provider: ${provider?['name'] ?? 'TBD'}
📍 Location: ${booking['location'] ?? 'TBD'}

''';
        }
      }

      message += '''
<b>This Week:</b>
• Total Bookings: ${bookings.length}
• Services: ${bookings.map((b) => b['service'] ?? 'Unknown').toSet().join(', ')}
• Total Cost: \$${bookings.fold(0.0, (sum, b) => sum + (b['price'] ?? 0.0)).toStringAsFixed(2)}

<b>Your Booking IDs:</b>
${bookings.map((b) => '🆔 ${b['id']} - ${b['service'] ?? 'Unknown'}').join('\n')}

Use /status [booking_id] to check specific booking details.
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'mybookings',
        'message': success ? 'Real bookings sent' : 'Failed to send bookings'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Bookings</b>

Unable to load your bookings at the moment.
Please try again later or contact support.
''';

      await TelegramBotService.sendNotification(
          chatId: chatId, message: message);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Handle /mypets command
  static Future<Map<String, dynamic>> _handleMyPetsCommand(
      String chatId) async {
    try {
      // Get user by chat ID
      final user = await _getUserByChatId(chatId);

      if (user == null) {
        // Show linking instructions for unlinked users
        final message = '''
🐕 <b>Your Pets</b>

To view your real pets, please link your CuddleCare account:

<b>Quick Link:</b>
/link your.email@example.com

<b>Or link via app:</b>
1. Open CuddleCare app
2. Go to Profile → Telegram Settings
3. Enter your Telegram username

<b>Once linked, you'll see:</b>
• Your actual pets and their details
• Pet care information
• Personalized service recommendations
• Health and activity tracking

No demo data - only your real CuddleCare pet information!
''';

        final success = await TelegramBotService.sendNotification(
          chatId: chatId,
          message: message,
        );

        return {
          'status': success ? 'success' : 'error',
          'command': 'mypets',
          'message': success
              ? 'Linking instructions sent'
              : 'Failed to send instructions'
        };
      }

      // Get real user pets
      final pets = await _getUserPets(user['uid']);

      print('Found ${pets.length} pets for user ${user['uid']}');
      if (pets.isNotEmpty) {
        print(
            'Pet details: ${pets.map((p) => '${p['name']} (${p['breed']})').toList()}');
      }

      if (pets.isEmpty) {
        final message = '''
🐕 <b>Your Pets</b>

You don't have any pets registered yet.

To add your pets:
1. Open the CuddleCare app
2. Go to "My Pets" section
3. Add your pet information
4. You'll see your pets here!

This helps us provide better service recommendations.
''';

        await TelegramBotService.sendNotification(
            chatId: chatId, message: message);
        return {'status': 'success', 'message': 'No pets found'};
      }

      // Build real pets message
      String message = '''
🐕 <b>Your Pets</b>

''';

      for (final pet in pets) {
        final name = pet['name'] ?? pet['type'] ?? 'Unknown';
        final breed = pet['breed'] ?? 'Unknown';
        final age = pet['age']?.toString() ?? 'Unknown';
        final weight = pet['weight']?.toString() ?? 'Unknown';
        final specialNeeds = pet['specialNeeds'] ?? pet['notes'] ?? 'None';
        final activities = pet['favoriteActivities'] ?? 'Unknown';

        message += '''
<b>$name ($breed)</b>
• Age: $age years
• Weight: $weight lbs
• Special Needs: $specialNeeds
• Favorite Activities: $activities

''';
      }

      message += '''
<b>Pet Care Tips:</b>
• Regular exercise keeps pets healthy
• Proper grooming maintains coat health
• Health monitoring provides peace of mind
• Regular vet checkups are important
''';

      final success = await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );

      return {
        'status': success ? 'success' : 'error',
        'command': 'mypets',
        'message': success ? 'Real pets sent' : 'Failed to send pets'
      };
    } catch (e) {
      final message = '''
❌ <b>Error Loading Pets</b>

Unable to load your pets at the moment.
Please try again later or contact support.
''';

      await TelegramBotService.sendNotification(
          chatId: chatId, message: message);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Get user data from Firestore by chat ID
  static Future<Map<String, dynamic>?> _getUserByChatId(String chatId) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('telegramChatId', isEqualTo: chatId)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting user by chat ID: $e');
      return null;
    }
  }

  // Get user's bookings from Firestore
  static Future<List<Map<String, dynamic>>> _getUserBookings(
      String userId) async {
    try {
      // Simple query to get all bookings for the user
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      // Filter future bookings in memory instead of in query
      final now = DateTime.now();
      final futureBookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).where((booking) {
        final bookingDate = DateTime.tryParse(booking['date'] ?? '');
        return bookingDate != null && bookingDate.isAfter(now);
      }).toList();

      // Sort by date
      futureBookings.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateA.compareTo(dateB);
      });

      // Return first 10 bookings
      return futureBookings.take(10).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  // Get ALL user's bookings (past and future) from Firestore
  static Future<List<Map<String, dynamic>>> _getAllUserBookings(
      String userId) async {
    try {
      // Simple query to get all bookings for the user
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      // Get all bookings (no date filtering)
      final allBookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by date (most recent first)
      allBookings.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Reverse order for most recent first
      });

      return allBookings;
    } catch (e) {
      print('Error getting all user bookings: $e');
      return [];
    }
  }

  // Get user's pets from Firestore
  static Future<List<Map<String, dynamic>>> _getUserPets(String userId) async {
    try {
      print('Looking for pets for user: $userId');

      // First, try to get pets from the pets collection (for test data)
      final petsSnapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> pets = petsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      print('Found ${pets.length} pets in pets collection');

      // If no pets found in pets collection, try user's pets subcollection
      if (pets.isEmpty) {
        print('No pets in pets collection, checking user subcollection...');

        final userPetsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('pets')
            .get();

        pets = userPetsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        print('Found ${pets.length} pets in user subcollection');
      }

      return pets;
    } catch (e) {
      print('Error getting user pets: $e');
      return [];
    }
  }

  // Get provider information
  static Future<Map<String, dynamic>?> _getProviderInfo(
      String providerId) async {
    try {
      final providerDoc =
          await _firestore.collection('users').doc(providerId).get();

      if (providerDoc.exists) {
        return providerDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting provider info: $e');
      return null;
    }
  }

  // Get user by email
  static Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Link Telegram account to user
  static Future<void> _linkTelegramAccount(String userId, String chatId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'telegramChatId': chatId,
        'telegramLinkedAt': FieldValue.serverTimestamp(),
      });
      print('Linked Telegram chat ID $chatId to user $userId');
    } catch (e) {
      print('Error linking Telegram account: $e');
    }
  }

  // Unlink Telegram account from user
  static Future<void> _unlinkTelegramAccount(
      String userId, String chatId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'telegramChatId': FieldValue.delete(),
        'telegramUnlinkedAt': FieldValue.serverTimestamp(),
      });
      print('Unlinked Telegram chat ID $chatId from user $userId');
    } catch (e) {
      print('Error unlinking Telegram account: $e');
    }
  }

  // Get user by ID
  static Future<Map<String, dynamic>?> _getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Handle smart commands for users
  static Future<Map<String, dynamic>> _handleSmartCommand(
    String chatId,
    String text,
    Map<String, dynamic>? user,
  ) async {
    try {
      if (user == null) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '''
❌ <b>Account Not Linked</b>

Please link your CuddleCare account first:
1. Use /link email@example.com
2. Or open the CuddleCare app and link your Telegram account

Once linked, you can view your bookings and pet information.
''',
        );
        return {'status': 'error', 'message': 'Account not linked'};
      }

      // Prepare user data for smart service
      final userData = {
        'uid': user['uid'] ?? user['id'],
        'name': user['name'] ?? user['firstName'] ?? 'User',
        'email': user['email'] ?? '',
        'location': user['location'] ?? 'Your Area',
        'petType': user['petType'] ?? 'dog',
      };

      // Handle smart command using SmartTelegramService
      final result = await SmartTelegramService.handleUserSmartCommand(
        chatId: chatId,
        command: text,
        userData: userData,
      );

      return result;
    } catch (e) {
      print('Error handling smart command: $e');
      await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '''
❌ <b>Smart Command Error</b>

Unable to process your request at the moment.
Please try again later or contact support.

Error: $e
''',
      );
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Handle review command
  static Future<Map<String, dynamic>> _handleReviewCommand(
    String chatId,
    String text,
    Map<String, dynamic>? user,
  ) async {
    try {
      if (user == null) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '❌ Please link your account first to leave reviews.',
        );
        return {'status': 'error', 'message': 'Account not linked'};
      }

      final parts = text.split(' ');
      if (parts.length < 2) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '''
❌ <b>Review Command Usage</b>

Please provide a booking ID:
/review [booking_id]

Example: /review booking123
''',
        );
        return {'status': 'error', 'message': 'Missing booking ID'};
      }

      final bookingId = parts[1];

      // Get booking details
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '❌ Booking not found. Please check the booking ID.',
        );
        return {'status': 'error', 'message': 'Booking not found'};
      }

      final booking = bookingDoc.data()!;
      final sitter = await _getUserById(booking['providerId']);

      // Send review request
      await SmartTelegramService.sendReviewRequest(
        bookingId: bookingId,
        customerChatId: chatId,
        sitterName: sitter?['name'] ?? 'Your sitter',
        service: booking['service'] ?? 'Pet care service',
        petName: booking['petName'] ?? 'Your pet',
      );

      return {
        'status': 'success',
        'command': 'review',
        'booking_id': bookingId
      };
    } catch (e) {
      print('Error handling review command: $e');
      await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '❌ Error processing review request. Please try again.',
      );
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Check if message is a review response (1-5 rating)
  static bool _isReviewResponse(String text) {
    final rating = int.tryParse(text.trim());
    return rating != null && rating >= 1 && rating <= 5;
  }

  // Handle review response
  static Future<Map<String, dynamic>> _handleReviewResponse(
    String chatId,
    String text,
    Map<String, dynamic>? user,
  ) async {
    try {
      if (user == null) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '❌ Please link your account first to leave reviews.',
        );
        return {'status': 'error', 'message': 'Account not linked'};
      }

      final rating = text.trim();

      // Find the most recent completed booking for this user
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: user['uid'] ?? user['id'])
          .where('status', isEqualTo: 'completed')
          .where('reviewed', isEqualTo: false)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (bookingsQuery.docs.isEmpty) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '''
❌ <b>No Pending Reviews</b>

You don't have any completed bookings waiting for review.
Reviews are automatically requested after session completion.
''',
        );
        return {'status': 'error', 'message': 'No pending reviews'};
      }

      final booking = bookingsQuery.docs.first;
      final bookingId = booking.id;

      // Process the review
      await SmartTelegramService.processReviewResponse(
        chatId: chatId,
        bookingId: bookingId,
        rating: rating,
      );

      return {
        'status': 'success',
        'command': 'review_response',
        'rating': rating
      };
    } catch (e) {
      print('Error handling review response: $e');
      await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '❌ Error processing review. Please try again.',
      );
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Check if message is arrival feedback (✅, ⏰, ❌)
  static bool _isArrivalFeedback(String text) {
    final feedback = text.trim();
    return feedback == '✅' || feedback == '⏰' || feedback == '❌';
  }

  // Handle arrival feedback
  static Future<Map<String, dynamic>> _handleArrivalFeedback(
    String chatId,
    String text,
    Map<String, dynamic>? user,
  ) async {
    try {
      if (user == null) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '❌ Please link your account first to provide feedback.',
        );
        return {'status': 'error', 'message': 'Account not linked'};
      }

      final feedback = text.trim();

      // Find the most recent confirmed booking for this user
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: user['uid'] ?? user['id'])
          .where('status', isEqualTo: 'confirmed')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (bookingsQuery.docs.isEmpty) {
        await TelegramBotService.sendNotification(
          chatId: chatId,
          message: '''
❌ <b>No Active Bookings</b>

You don't have any active bookings for arrival feedback.
Feedback is requested when sitters are scheduled to arrive.
''',
        );
        return {'status': 'error', 'message': 'No active bookings'};
      }

      final booking = bookingsQuery.docs.first;
      final bookingId = booking.id;

      // Process the arrival feedback
      await SmartTelegramService.processArrivalFeedback(
        chatId: chatId,
        bookingId: bookingId,
        feedback: feedback,
      );

      return {
        'status': 'success',
        'command': 'arrival_feedback',
        'feedback': feedback
      };
    } catch (e) {
      print('Error handling arrival feedback: $e');
      await TelegramBotService.sendNotification(
        chatId: chatId,
        message: '❌ Error processing feedback. Please try again.',
      );
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
