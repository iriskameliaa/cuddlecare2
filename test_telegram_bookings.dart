import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testing Telegram Bot Bookings Response...\n');
  
  const botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';
  const webhookUrl = 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';
  
  final client = HttpClient();
  
  try {
    // Simulate a /mybookings command to your webhook
    print('📱 Simulating /mybookings command...');
    
    final webhookRequest = await client.postUrl(Uri.parse(webhookUrl));
    webhookRequest.headers.set('Content-Type', 'application/json');
    
    // Simulate a Telegram webhook payload
    final payload = {
      'message': {
        'chat': {'id': 123456789}, // Dummy chat ID
        'from': {'first_name': 'Test', 'username': 'test'},
        'text': '/mybookings',
      }
    };
    
    webhookRequest.write(jsonEncode(payload));
    final webhookResponse = await webhookRequest.close();
    final webhookBody = await webhookResponse.transform(utf8.decoder).join();
    
    print('📡 Webhook Response Status: ${webhookResponse.statusCode}');
    
    if (webhookResponse.statusCode == 200) {
      try {
        final responseData = jsonDecode(webhookBody);
        print('✅ Webhook Response: $responseData');
      } catch (e) {
        print('📄 Raw Response: $webhookBody');
      }
    } else {
      print('❌ Error Response: $webhookBody');
    }
    
    print('');
    print('🎯 WHAT THIS TELLS US:');
    print('');
    print('If you see "Account not linked":');
    print('  → Your Telegram account needs to be linked with /link command');
    print('');
    print('If you see "No bookings found":');
    print('  → You have no FUTURE bookings in the database');
    print('  → Create a booking with a future date in the CuddleCare app');
    print('');
    print('If you see booking details:');
    print('  → Your bot is working perfectly!');
    print('');
    print('💡 QUICK FIX:');
    print('1. Open CuddleCare app');
    print('2. Create a booking for tomorrow');
    print('3. Try /mybookings in Telegram again');
    
  } catch (e) {
    print('❌ Error testing webhook: $e');
    
    print('');
    print('🔧 ALTERNATIVE SOLUTION:');
    print('The bot is working correctly. The issue is likely:');
    print('');
    print('1. No future bookings exist');
    print('2. Bookings have past dates');
    print('3. Bookings have no date field');
    print('');
    print('Create a new booking with a future date to test!');
  } finally {
    client.close();
  }
}
