import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class TelegramNotificationService {
  static const String _baseUrl =
      'https://us-central1-cuddlecare2-dd913.cloudfunctions.net';

  /// Send booking confirmation notification
  static Future<void> sendBookingConfirmation({
    required String userId,
    required String petName,
    required String providerName,
    required String date,
    required String time,
    required String location,
    required double cost,
  }) async {
    await _sendNotification(
      type: 'booking_confirmed',
      userId: userId,
      data: {
        'petName': petName,
        'providerName': providerName,
        'date': date,
        'time': time,
        'location': location,
        'cost': cost,
      },
    );
  }

  /// Send provider arrival notification
  static Future<void> sendProviderArriving({
    required String userId,
    required String providerName,
    required String petName,
    required int eta,
    required String currentLocation,
    required String phone,
  }) async {
    await _sendNotification(
      type: 'provider_arriving',
      userId: userId,
      data: {
        'providerName': providerName,
        'petName': petName,
        'eta': eta,
        'currentLocation': currentLocation,
        'phone': phone,
      },
    );
  }

  /// Send service completion notification
  static Future<void> sendServiceCompleted({
    required String userId,
    required String petName,
    required String providerName,
    required String duration,
    required double cost,
    String? photos,
    String? notes,
  }) async {
    await _sendNotification(
      type: 'service_completed',
      userId: userId,
      data: {
        'petName': petName,
        'providerName': providerName,
        'duration': duration,
        'cost': cost,
        'photos': photos,
        'notes': notes,
      },
    );
  }

  /// Send emergency alert notification
  static Future<void> sendEmergencyAlert({
    required String userId,
    required String petName,
    required String issue,
    required String providerPhone,
    required String nearestVet,
  }) async {
    await _sendNotification(
      type: 'emergency_alert',
      userId: userId,
      data: {
        'petName': petName,
        'issue': issue,
        'providerPhone': providerPhone,
        'nearestVet': nearestVet,
      },
    );
  }

  /// Send reminder notification
  static Future<void> sendReminder({
    required String userId,
    required String service,
    required String petName,
    required String providerName,
    required String timeUntil,
    required String location,
  }) async {
    await _sendNotification(
      type: 'reminder',
      userId: userId,
      data: {
        'service': service,
        'petName': petName,
        'providerName': providerName,
        'timeUntil': timeUntil,
        'location': location,
      },
    );
  }

  /// Private method to send notification to Firebase Function
  static Future<void> _sendNotification({
    required String type,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendBookingNotification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'userId': userId,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Telegram notification sent: $type');
      } else {
        print('❌ Failed to send Telegram notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending Telegram notification: $e');
    }
  }

  /// Set up webhook URL with Telegram (call this once during setup)
  static Future<void> setupWebhook() async {
    const String botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';
    const String webhookUrl = '$_baseUrl/telegramWebhookSimple';

    try {
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/setWebhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': webhookUrl,
          'allowed_updates': ['message'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok']) {
          print('✅ Telegram webhook set up successfully');
          print('📡 Webhook URL: $webhookUrl');
        } else {
          print('❌ Failed to set webhook: ${data['description']}');
        }
      } else {
        print('❌ HTTP error setting webhook: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error setting up webhook: $e');
    }
  }

  /// Remove webhook (for testing)
  static Future<void> removeWebhook() async {
    const String botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';

    try {
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/deleteWebhook'),
      );

      if (response.statusCode == 200) {
        print('✅ Telegram webhook removed');
      } else {
        print('❌ Failed to remove webhook: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error removing webhook: $e');
    }
  }

  /// Get webhook info (for debugging)
  static Future<void> getWebhookInfo() async {
    const String botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';

    try {
      final response = await http.get(
        Uri.parse('https://api.telegram.org/bot$botToken/getWebhookInfo'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 Webhook Info: ${data['result']}');
      } else {
        print('❌ Failed to get webhook info: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting webhook info: $e');
    }
  }
}
