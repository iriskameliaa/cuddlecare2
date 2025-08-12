import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telegram_bot_service.dart';
import 'bot_config_service.dart';

class SmartTelegramService {
  static const String _baseUrl = 'https://api.telegram.org/bot';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // USER-FOCUSED Smart Service Management Features

  // 1. Smart Service Recommendations for Users
  static Future<Map<String, dynamic>> getSmartServiceRecommendations({
    required String userId,
    required String petType,
    required String location,
  }) async {
    // Smart AI recommendations based on user's pets and preferences
    final recommendations = <String, dynamic>{
      'petType': petType,
      'location': location,
      'recommendedServices': [],
      'bestTimes': [],
      'careTips': [],
      'seasonalAdvice': [],
    };

    switch (petType.toLowerCase()) {
      case 'dog':
        recommendations['recommendedServices'] = [
          'Daily Walking (30-60 min)',
          'Pet Sitting (Home visits)',
          'Grooming (Monthly)',
          'Health Check-ups',
        ];
        recommendations['bestTimes'] = [
          'Morning walks: 7-9 AM',
          'Evening walks: 5-7 PM',
          'Health checks: Weekends',
        ];
        recommendations['careTips'] = [
          'Regular exercise prevents behavioral issues',
          'Socialization is important for dogs',
          'Consistent feeding schedule recommended',
        ];
        break;
      case 'cat':
        recommendations['recommendedServices'] = [
          'Pet Sitting (Home visits)',
          'Grooming (Bi-monthly)',
          'Litter Box Cleaning',
          'Play Time Sessions',
          'Health Monitoring',
        ];
        recommendations['bestTimes'] = [
          'Play time: Early morning or evening',
          'Grooming: When cat is relaxed',
          'Litter cleaning: Daily',
        ];
        recommendations['careTips'] = [
          'Cats prefer routine and consistency',
          'Indoor cats need mental stimulation',
          'Regular grooming prevents hairballs',
        ];
        break;
      default:
        recommendations['recommendedServices'] = [
          'Pet Sitting',
          'Basic Care Services',
          'Health Monitoring',
        ];
    }

    // Add seasonal recommendations
    final month = DateTime.now().month;
    if (month >= 6 && month <= 8) {
      recommendations['seasonalAdvice'] = [
        'Summer: Ensure pets stay hydrated',
        'Avoid hot pavement during walks',
        'Consider indoor activities during peak heat',
      ];
    } else if (month >= 12 || month <= 2) {
      recommendations['seasonalAdvice'] = [
        'Winter: Keep pets warm during walks',
        'Check for ice and salt on paws',
        'Indoor exercise options available',
      ];
    }

    return recommendations;
  }

  // 2. Smart Booking Management for Users
  static Future<Map<String, dynamic>> getUserSmartBookings({
    required String userId,
  }) async {
    try {
      // Get user's bookings from Firestore
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('date', descending: false)
          .get();

      final bookings = <Map<String, dynamic>>[];
      final upcomingBookings = <Map<String, dynamic>>[];
      final completedBookings = <Map<String, dynamic>>[];

      for (final doc in bookingsQuery.docs) {
        final booking = doc.data();
        booking['id'] = doc.id;

        final bookingDate = DateTime.parse(booking['date']);
        final now = DateTime.now();

        if (bookingDate.isAfter(now)) {
          upcomingBookings.add(booking);
        } else {
          completedBookings.add(booking);
        }

        bookings.add(booking);
      }

      return {
        'upcoming': upcomingBookings,
        'completed': completedBookings,
        'total': bookings.length,
        'nextBooking':
            upcomingBookings.isNotEmpty ? upcomingBookings.first : null,
      };
    } catch (e) {
      print('Error getting user smart bookings: $e');
      return {
        'upcoming': [],
        'completed': [],
        'total': 0,
        'nextBooking': null,
      };
    }
  }

  // 3. Smart Pet Care Dashboard for Users
  static Future<Map<String, dynamic>> getUserPetCareDashboard({
    required String userId,
  }) async {
    try {
      // Get user's pets
      final petsQuery = await FirebaseFirestore.instance
          .collection('pets')
          .where('ownerId', isEqualTo: userId)
          .get();

      final pets = <Map<String, dynamic>>[];
      for (final doc in petsQuery.docs) {
        final pet = doc.data();
        pet['id'] = doc.id;
        pets.add(pet);
      }

      // Get recent bookings for care insights
      final recentBookings = await getUserSmartBookings(userId: userId);

      // Calculate care insights
      final careInsights = <Map<String, dynamic>>[];
      for (final pet in pets) {
        final petBookings = recentBookings['completed']
            .where((booking) => booking['petName'] == pet['name'])
            .toList();

        careInsights.add({
          'petName': pet['name'],
          'petType': pet['type'],
          'lastService': petBookings.isNotEmpty
              ? petBookings.last['date']
              : 'No recent services',
          'servicesThisMonth': petBookings.length,
          'nextRecommendedService': _getNextRecommendedService(pet['type']),
        });
      }

      return {
        'pets': pets,
        'careInsights': careInsights,
        'totalPets': pets.length,
        'totalServices': recentBookings['total'],
      };
    } catch (e) {
      print('Error getting user pet care dashboard: $e');
      return {
        'pets': [],
        'careInsights': [],
        'totalPets': 0,
        'totalServices': 0,
      };
    }
  }

  // 4. Smart Weather Integration for User Services
  static Future<Map<String, dynamic>> getSmartWeatherForUser({
    required String location,
    required List<Map<String, dynamic>> upcomingBookings,
  }) async {
    // Simulate weather API call with user-specific insights
    final weatherData = <String, dynamic>{
      'location': location,
      'current': <String, dynamic>{
        'temperature': '22°C',
        'condition': 'Sunny',
        'humidity': '65%',
        'windSpeed': '10 km/h',
      },
      'forecast': <Map<String, dynamic>>[
        {'day': 'Today', 'temp': '22°C', 'condition': 'Sunny'},
        {'day': 'Tomorrow', 'temp': '18°C', 'condition': 'Partly Cloudy'},
        {'day': 'Day 3', 'temp': '20°C', 'condition': 'Sunny'},
      ],
      'serviceRecommendations': <Map<String, dynamic>>[],
      'safetyAlerts': <String>[],
    };

    // Generate service-specific recommendations
    for (final booking in upcomingBookings) {
      final service = booking['service'];
      final petName = booking['petName'];

      if (service.toString().toLowerCase().contains('walking')) {
        weatherData['serviceRecommendations']!.add({
          'service': service,
          'pet': petName,
          'recommendation':
              'Perfect weather for walking! Consider morning or evening walks.',
          'duration': '30-45 minutes recommended',
        });
      } else if (service.toString().toLowerCase().contains('sitting')) {
        weatherData['serviceRecommendations']!.add({
          'service': service,
          'pet': petName,
          'recommendation': 'Great weather for indoor/outdoor activities.',
          'duration': 'Flexible timing available',
        });
      }
    }

    // Add safety alerts based on weather
    if (weatherData['current']!['temperature'] == '22°C') {
      weatherData['safetyAlerts'] = [
        'Moderate temperature - ensure pets stay hydrated',
        'UV index moderate - consider pet sunscreen for light-colored pets',
      ];
    }

    return weatherData;
  }

  // 5. Smart Service Scheduling for Users
  static Future<Map<String, dynamic>> getSmartScheduleRecommendations({
    required String userId,
    required List<Map<String, dynamic>> pets,
  }) async {
    final scheduleRecommendations = <Map<String, dynamic>>[];

    for (final pet in pets) {
      final petType = pet['type'];
      final petName = pet['name'];

      Map<String, dynamic> recommendation = {
        'petName': petName,
        'petType': petType,
        'recommendedSchedule': [],
        'frequency': '',
        'bestTimes': [],
      };

      switch (petType.toLowerCase()) {
        case 'dog':
          recommendation['recommendedSchedule'] = [
            'Daily Walking: 2x per day (morning & evening)',
            'Pet Sitting: 3-4 times per week',
            'Grooming: Monthly',
            'Health Check-ups: Monthly',
          ];
          recommendation['frequency'] = 'High activity needs';
          recommendation['bestTimes'] = [
            'Morning walks: 7-9 AM',
            'Evening walks: 5-7 PM',
            'Health checks: Weekends 10 AM - 2 PM',
          ];
          break;
        case 'cat':
          recommendation['recommendedSchedule'] = [
            'Pet Sitting: Daily visits',
            'Play Time: 2-3 times per day',
            'Grooming: Bi-monthly',
            'Litter Cleaning: Daily',
          ];
          recommendation['frequency'] = 'Moderate activity needs';
          recommendation['bestTimes'] = [
            'Morning play: 7-8 AM',
            'Evening play: 6-7 PM',
            'Grooming: When cat is relaxed',
          ];
          break;
        default:
          recommendation['recommendedSchedule'] = [
            'Pet Sitting: As needed',
            'Basic Care: Weekly',
          ];
          recommendation['frequency'] = 'Low activity needs';
      }

      scheduleRecommendations.add(recommendation);
    }

    return {
      'recommendations': scheduleRecommendations,
      'totalPets': pets.length,
      'nextAction': 'Consider booking services based on recommendations',
    };
  }

  // 6. Smart Command Handler for Users
  static Future<Map<String, dynamic>> handleUserSmartCommand({
    required String chatId,
    required String command,
    required Map<String, dynamic> userData,
  }) async {
    final parts = command.split(' ');
    final action = parts[0].toLowerCase();

    switch (action) {
      case '/dashboard':
        return await _handleDashboardCommand(chatId, userData);
      case '/schedule':
        return await _handleScheduleCommand(chatId, parts, userData);
      case '/weather':
        return await _handleWeatherCommand(chatId, parts, userData);
      case '/recommend':
        return await _handleRecommendCommand(chatId, parts, userData);
      case '/care':
        return await _handleCareCommand(chatId, parts, userData);
      case '/tips':
        return await _handleTipsCommand(chatId, parts, userData);
      default:
        return await _handleUnknownSmartCommand(chatId, command);
    }
  }

  // Smart Dashboard Command
  static Future<Map<String, dynamic>> _handleDashboardCommand(
    String chatId,
    Map<String, dynamic> userData,
  ) async {
    final dashboard =
        await getUserPetCareDashboard(userId: userData['uid'] ?? '');

    String message = '''
📊 <b>Your Smart Pet Care Dashboard</b>

🐕 <b>Your Pets:</b> ${dashboard['totalPets']}
📅 <b>Total Services:</b> ${dashboard['totalServices']}

<b>Care Insights:</b>
''';

    for (final insight in dashboard['careInsights']) {
      message += '''
• ${insight['petName']} (${insight['petType']})
  📅 Last service: ${insight['lastService']}
  📊 Services this month: ${insight['servicesThisMonth']}
  💡 Next recommended: ${insight['nextRecommendedService']}
''';
    }

    message += '''
<b>Quick Actions:</b>
/weather - Check weather for services
/schedule - View smart schedule
/recommend - Get recommendations
/care - Pet care tips
''';

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'dashboard'};
  }

  // Smart Schedule Command
  static Future<Map<String, dynamic>> _handleScheduleCommand(
    String chatId,
    List<String> parts,
    Map<String, dynamic> userData,
  ) async {
    final dashboard =
        await getUserPetCareDashboard(userId: userData['uid'] ?? '');
    final schedule = await getSmartScheduleRecommendations(
      userId: userData['uid'] ?? '',
      pets: dashboard['pets'],
    );

    String message = '''
📅 <b>Smart Schedule Recommendations</b>

''';

    for (final rec in schedule['recommendations']) {
      message += '''
🐕 <b>${rec['petName']} (${rec['petType']})</b>
📊 Activity Level: ${rec['frequency']}

<b>Recommended Schedule:</b>
${rec['recommendedSchedule'].map((s) => '• $s').join('\n')}

<b>Best Times:</b>
${rec['bestTimes'].map((t) => '• $t').join('\n')}

''';
    }

    message += '''
💡 <b>Smart Tips:</b>
• Book recurring services for consistency
• Consider weather when scheduling outdoor activities
• Match service times to your pet's energy levels

Use /recommend to get personalized service suggestions!
''';

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'schedule'};
  }

  // Smart Weather Command
  static Future<Map<String, dynamic>> _handleWeatherCommand(
    String chatId,
    List<String> parts,
    Map<String, dynamic> userData,
  ) async {
    final bookings = await getUserSmartBookings(userId: userData['uid'] ?? '');
    final weather = await getSmartWeatherForUser(
      location: userData['location'] ?? 'Your Area',
      upcomingBookings: bookings['upcoming'],
    );

    String message = '''
🌤 <b>Smart Weather for Your Services</b>

📍 <b>Location:</b> ${weather['location']}
🌡 <b>Current:</b> ${weather['current']['temperature']} - ${weather['current']['condition']}
💨 <b>Wind:</b> ${weather['current']['windSpeed']}
💧 <b>Humidity:</b> ${weather['current']['humidity']}

<b>3-Day Forecast:</b>
${weather['forecast'].map((day) => '• ${day['day']}: ${day['temp']} - ${day['condition']}').join('\n')}

''';

    if (weather['serviceRecommendations'].isNotEmpty) {
      message += '''
<b>Service Recommendations:</b>
''';
      for (final rec in weather['serviceRecommendations']) {
        message += '''
• ${rec['service']} for ${rec['pet']}
  💡 ${rec['recommendation']}
  ⏰ ${rec['duration']}
''';
      }
    }

    if (weather['safetyAlerts'].isNotEmpty) {
      message += '''
⚠️ <b>Safety Alerts:</b>
${weather['safetyAlerts'].map((alert) => '• $alert').join('\n')}
''';
    }

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'weather'};
  }

  // Smart Recommendations Command
  static Future<Map<String, dynamic>> _handleRecommendCommand(
    String chatId,
    List<String> parts,
    Map<String, dynamic> userData,
  ) async {
    final recommendations = await getSmartServiceRecommendations(
      userId: userData['uid'] ?? '',
      petType: userData['petType'] ?? 'dog',
      location: userData['location'] ?? 'Your Area',
    );

    String message = '''
🤖 <b>Smart Service Recommendations</b>

🐕 <b>Pet Type:</b> ${recommendations['petType']}
📍 <b>Location:</b> ${recommendations['location']}

<b>Recommended Services:</b>
${recommendations['recommendedServices'].map((service) => '• $service').join('\n')}

<b>Best Times:</b>
${recommendations['bestTimes'].map((time) => '• $time').join('\n')}

<b>Care Tips:</b>
${recommendations['careTips'].map((tip) => '• $tip').join('\n')}

''';

    if (recommendations['seasonalAdvice'].isNotEmpty) {
      message += '''
🌤 <b>Seasonal Advice:</b>
${recommendations['seasonalAdvice'].map((advice) => '• $advice').join('\n')}
''';
    }

    message += '''
💡 <b>Next Steps:</b>
• Use /schedule to see recommended timing
• Use /weather to check conditions
• Book services through the CuddleCare app
''';

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'recommend'};
  }

  // Smart Care Tips Command
  static Future<Map<String, dynamic>> _handleCareCommand(
    String chatId,
    List<String> parts,
    Map<String, dynamic> userData,
  ) async {
    String message = '''
🐾 <b>Smart Pet Care Tips</b>

<b>Daily Care:</b>
• Fresh water available 24/7
• Regular feeding schedule
• Daily exercise and playtime
• Health monitoring

<b>Weekly Care:</b>
• Grooming and brushing
• Nail trimming (if needed)
• Health check-ups
• Health monitoring

<b>Monthly Care:</b>
• Professional grooming
• Vet check-ups
• Vaccination updates
• Parasite prevention

<b>Emergency Preparedness:</b>
• Keep vet contact info handy
• Have pet first aid kit
• Know emergency pet hospital locations
• Keep pet ID and microchip updated

💡 <b>Smart Features:</b>
• Use /weather to plan outdoor activities
• Use /schedule for consistent care routine
• Use /recommend for personalized advice
''';

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'care'};
  }

  // Smart Tips Command
  static Future<Map<String, dynamic>> _handleTipsCommand(
    String chatId,
    List<String> parts,
    Map<String, dynamic> userData,
  ) async {
    final tips = [
      '🐕 <b>Dog Tips:</b> Regular walks improve behavior and health',
      '🐱 <b>Cat Tips:</b> Cats need mental stimulation - try puzzle toys',
      '🌤 <b>Weather Tips:</b> Check weather before outdoor activities',
      '💧 <b>Hydration:</b> Always ensure pets have fresh water',
      '🏥 <b>Health:</b> Regular vet check-ups prevent issues',
      '🎾 <b>Exercise:</b> Match activity level to pet\'s age and breed',
      '🍽 <b>Nutrition:</b> Consistent feeding schedule is important',
      '🧸 <b>Comfort:</b> Provide safe spaces for pets to rest',
    ];

    final randomTips = tips.take(4).toList();

    String message = '''
💡 <b>Smart Pet Care Tips</b>

${randomTips.join('\n\n')}

<b>Get More Tips:</b>
• Use /care for comprehensive care guide
• Use /recommend for personalized advice
• Use /weather for activity planning
''';

    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: message,
    );
    return {'status': 'success', 'command': 'tips'};
  }

  // Handle Unknown Smart Commands
  static Future<Map<String, dynamic>> _handleUnknownSmartCommand(
    String chatId,
    String command,
  ) async {
    await TelegramBotService.sendNotification(
      chatId: chatId,
      message: '''
❓ <b>Smart Command Not Found</b>

Command: $command

<b>Available Smart Commands:</b>
/dashboard - Your pet care overview
/schedule - Smart scheduling recommendations
/weather - Weather for your services
/recommend - Personalized recommendations
/care - Pet care tips and guides
/tips - Quick care tips

<b>Basic Commands:</b>
/start - Welcome message
/help - Show all commands
/mybookings - View your bookings
/mypets - View your pets

Use /help for complete command list.
''',
    );
    return {'status': 'unknown', 'command': command};
  }

  // Helper function to get next recommended service
  static String _getNextRecommendedService(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return 'Daily walking or grooming';
      case 'cat':
        return 'Pet sitting or grooming';
      default:
        return 'Basic care service';
    }
  }

  // Get Smart Bot Info for Users
  static Future<Map<String, dynamic>?> getSmartBotInfo() async {
    try {
      final botInfo = await BotConfigService.getBotInfo();
      if (botInfo != null) {
        botInfo['smartFeatures'] = [
          'Smart service recommendations',
          'Weather-integrated planning',
          'Personalized care tips',
          'Smart scheduling',
          'Pet care dashboard',
          'Automated reminders',
          'Smart booking reminders',
          'Automatic follow-ups',
          'Sitter arrival feedback',
        ];
        return botInfo;
      }
      return null;
    } catch (e) {
      print('Error getting smart bot info: $e');
      return null;
    }
  }

  // SMART BOOKING REMINDER & FOLLOW-UP SYSTEM

  // 1. Send Smart Booking Reminder
  static Future<bool> sendSmartBookingReminder({
    required String bookingId,
    required String customerChatId,
    required String sitterName,
    required String service,
    required DateTime sessionDate,
    required String petName,
    required String location,
  }) async {
    try {
      final timeUntilSession = sessionDate.difference(DateTime.now());
      final hoursUntilSession = timeUntilSession.inHours;

      String reminderType = '';
      String emoji = '';

      if (hoursUntilSession <= 1) {
        reminderType = 'URGENT';
        emoji = '🚨';
      } else if (hoursUntilSession <= 24) {
        reminderType = 'TOMORROW';
        emoji = '📅';
      } else {
        reminderType = 'UPCOMING';
        emoji = '⏰';
      }

      String message = '''
$emoji <b>Smart Booking Reminder</b>

🐕 <b>Pet:</b> $petName
👤 <b>Sitter:</b> $sitterName
🛠 <b>Service:</b> $service
📅 <b>Date:</b> ${sessionDate.toString().split(' ')[0]}
⏰ <b>Time:</b> ${sessionDate.hour.toString().padLeft(2, '0')}:${sessionDate.minute.toString().padLeft(2, '0')}
📍 <b>Location:</b> $location

<b>Smart Features:</b>
✅ Weather check enabled
✅ Sitter arrival tracking
✅ Photo updates available
✅ Real-time status updates

<b>Quick Actions:</b>
/status $bookingId - Check booking status
/weather - Check weather for today
/mypets - View pet details

Have a great session! 🐾
''';

      if (hoursUntilSession <= 1) {
        message += '''
⚠️ <b>URGENT:</b> Your session starts in ${hoursUntilSession} hour(s)!
Please ensure your pet is ready and accessible.
''';
      }

      return await TelegramBotService.sendNotification(
        chatId: customerChatId,
        message: message,
      );
    } catch (e) {
      print('Error sending smart booking reminder: $e');
      return false;
    }
  }

  // 2. Send Session Start Notification
  static Future<bool> sendSessionStartNotification({
    required String bookingId,
    required String customerChatId,
    required String sitterName,
    required String service,
    required String petName,
  }) async {
    try {
      final message = '''
🎯 <b>Session Started!</b>

👤 <b>Sitter:</b> $sitterName has arrived
🐕 <b>Pet:</b> $petName
🛠 <b>Service:</b> $service

<b>What's happening:</b>
✅ Sitter has checked in
✅ Session is in progress
📸 Photo updates will be shared
⏰ Duration tracking active

<b>You'll receive:</b>
• Real-time updates
• Photo progress reports
• Completion notification
• Review request

Use /status $bookingId to track progress
''';

      return await TelegramBotService.sendNotification(
        chatId: customerChatId,
        message: message,
      );
    } catch (e) {
      print('Error sending session start notification: $e');
      return false;
    }
  }

  // 3. Send Session Completion Notification
  static Future<bool> sendSessionCompletionNotification({
    required String bookingId,
    required String customerChatId,
    required String sitterName,
    required String service,
    required String petName,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      final duration = sessionData['duration'] ?? 'Completed';
      final activities = sessionData['activities'] ?? 'Standard care';
      final notes = sessionData['notes'] ?? 'No special notes';

      final message = '''
✅ <b>Session Completed!</b>

👤 <b>Sitter:</b> $sitterName
🐕 <b>Pet:</b> $petName
🛠 <b>Service:</b> $service
⏱ <b>Duration:</b> $duration

<b>Session Summary:</b>
📝 Activities: $activities
📋 Notes: $notes

<b>Next Steps:</b>
1️⃣ Rate your experience
2️⃣ Leave a review
3️⃣ Book next session

<b>Quick Actions:</b>
/review $bookingId - Rate this session
/schedule - Book next session
/recommend - Get recommendations

Thank you for choosing CuddleCare! 🐾
''';

      return await TelegramBotService.sendNotification(
        chatId: customerChatId,
        message: message,
      );
    } catch (e) {
      print('Error sending session completion notification: $e');
      return false;
    }
  }

  // 4. Send Review Request
  static Future<bool> sendReviewRequest({
    required String bookingId,
    required String customerChatId,
    required String sitterName,
    required String service,
    required String petName,
  }) async {
    try {
      final message = '''
⭐ <b>How was your session?</b>

👤 <b>Sitter:</b> $sitterName
🐕 <b>Pet:</b> $petName
🛠 <b>Service:</b> $service

<b>Please rate your experience:</b>
1️⃣ Poor - Not satisfied
2️⃣ Fair - Could be better
3️⃣ Good - Met expectations
4️⃣ Very Good - Exceeded expectations
5️⃣ Excellent - Outstanding service

<b>To leave a review:</b>
• Reply with your rating (1-5)
• Add comments if desired
• Or use /review $bookingId

Your feedback helps us improve and helps other pet parents! 🐾
''';

      return await TelegramBotService.sendNotification(
        chatId: customerChatId,
        message: message,
      );
    } catch (e) {
      print('Error sending review request: $e');
      return false;
    }
  }

  // 5. Send Sitter Arrival Feedback Request
  static Future<bool> sendSitterArrivalFeedback({
    required String bookingId,
    required String customerChatId,
    required String sitterName,
    required String service,
    required String petName,
  }) async {
    try {
      final message = '''
👋 <b>Sitter Arrival Check</b>

👤 <b>Sitter:</b> $sitterName should arrive soon
🐕 <b>Pet:</b> $petName
🛠 <b>Service:</b> $service

<b>Please confirm:</b>
✅ Sitter arrived on time
⏰ Sitter arrived late
❌ Sitter hasn't arrived yet

<b>Quick Response:</b>
Reply with:
• "✅" for on time
• "⏰" for late arrival
• "❌" for no show

This helps us maintain quality service! 🐾
''';

      return await TelegramBotService.sendNotification(
        chatId: customerChatId,
        message: message,
      );
    } catch (e) {
      print('Error sending sitter arrival feedback: $e');
      return false;
    }
  }

  // 6. Process Review Response
  static Future<bool> processReviewResponse({
    required String chatId,
    required String bookingId,
    required String rating,
    String? comments,
  }) async {
    try {
      // Save review to Firestore
      final review = {
        'bookingId': bookingId,
        'rating': int.tryParse(rating) ?? 5,
        'comments': comments ?? '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedVia': 'telegram',
      };

      await FirebaseFirestore.instance.collection('reviews').add(review);

      // Update booking with review status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'reviewed': true,
        'reviewRating': int.tryParse(rating) ?? 5,
        'reviewComments': comments ?? '',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Send confirmation
      final message = '''
✅ <b>Review Submitted!</b>

⭐ <b>Rating:</b> $rating/5
${comments != null && comments.isNotEmpty ? '💬 <b>Comments:</b> $comments' : ''}

Thank you for your feedback! It helps us improve our services and helps other pet parents make informed decisions.

<b>Next Steps:</b>
/schedule - Book your next session
/recommend - Get personalized recommendations
/dashboard - View your pet care overview

Happy pet parenting! 🐾
''';

      return await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );
    } catch (e) {
      print('Error processing review response: $e');
      return false;
    }
  }

  // 7. Process Arrival Feedback Response
  static Future<bool> processArrivalFeedback({
    required String chatId,
    required String bookingId,
    required String feedback,
  }) async {
    try {
      String status = '';
      String message = '';

      switch (feedback.trim()) {
        case '✅':
          status = 'arrived_on_time';
          message = '''
✅ <b>Thank you for confirming!</b>

Great! Your sitter arrived on time. We hope you have a wonderful session!

<b>You'll receive:</b>
• Session progress updates
• Completion notification
• Review request after session

Enjoy your pet care session! 🐾
''';
          break;
        case '⏰':
          status = 'arrived_late';
          message = '''
⏰ <b>Late Arrival Noted</b>

We apologize for the delay. Your feedback helps us improve our service.

<b>What happens next:</b>
• We'll investigate the delay
• You'll receive compensation if applicable
• We'll ensure future punctuality

Thank you for your patience! 🐾
''';
          break;
        case '❌':
          status = 'no_show';
          message = '''
❌ <b>No Show Reported</b>

We sincerely apologize for this inconvenience. This is not acceptable.

<b>Immediate Actions:</b>
• We'll contact you immediately
• Full refund will be processed
• Alternative sitter will be arranged
• This will be investigated

Please contact support for immediate assistance.
''';
          break;
        default:
          message = '''
❓ <b>Invalid Response</b>

Please reply with:
• "✅" for on time arrival
• "⏰" for late arrival  
• "❌" for no show

Thank you!
''';
          return await TelegramBotService.sendNotification(
            chatId: chatId,
            message: message,
          );
      }

      // Save feedback to Firestore
      await FirebaseFirestore.instance.collection('booking_feedback').add({
        'bookingId': bookingId,
        'feedbackType': 'arrival',
        'status': status,
        'feedback': feedback,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      return await TelegramBotService.sendNotification(
        chatId: chatId,
        message: message,
      );
    } catch (e) {
      print('Error processing arrival feedback: $e');
      return false;
    }
  }

  // 8. Get Upcoming Bookings for Reminders
  static Future<List<Map<String, dynamic>>>
      getUpcomingBookingsForReminders() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final nextHour = now.add(const Duration(hours: 1));

      // Get bookings that need reminders
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isGreaterThanOrEqualTo: now.toIso8601String())
          .where('date', isLessThanOrEqualTo: tomorrow.toIso8601String())
          .where('status', isEqualTo: 'confirmed')
          .get();

      final bookings = <Map<String, dynamic>>[];

      for (final doc in bookingsQuery.docs) {
        final booking = doc.data();
        booking['id'] = doc.id;

        final bookingDate = DateTime.parse(booking['date']);
        final timeUntilSession = bookingDate.difference(now);

        // Check if reminder should be sent
        if (timeUntilSession.inHours <= 24 && timeUntilSession.inHours > 0) {
          // Get customer and sitter info
          final customer = await _getUserById(booking['customerId']);
          final sitter = await _getUserById(booking['providerId']);

          if (customer != null &&
              sitter != null &&
              customer['telegramChatId'] != null) {
            bookings.add({
              ...booking,
              'customer': customer,
              'sitter': sitter,
            });
          }
        }
      }

      return bookings;
    } catch (e) {
      print('Error getting upcoming bookings for reminders: $e');
      return [];
    }
  }

  // Helper method to get user by ID
  static Future<Map<String, dynamic>?> _getUserById(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}
