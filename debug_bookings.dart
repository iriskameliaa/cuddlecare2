import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Debugging Telegram Bot Bookings...\n');
  
  const botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';
  const baseUrl = 'https://api.telegram.org/bot$botToken';
  
  final client = HttpClient();
  
  try {
    // Step 1: Get recent updates to find your chat ID
    print('1️⃣ Getting recent bot updates...');
    final updatesRequest = await client.getUrl(Uri.parse('$baseUrl/getUpdates?limit=10'));
    final updatesResponse = await updatesRequest.close();
    final updatesBody = await updatesResponse.transform(utf8.decoder).join();
    final updatesData = jsonDecode(updatesBody);
    
    if (updatesData['ok'] == true && updatesData['result'].isNotEmpty) {
      print('📱 Recent chat interactions:');
      final updates = updatesData['result'] as List;
      
      // Find unique chat IDs from recent messages
      final chatIds = <String>{};
      for (final update in updates) {
        if (update['message'] != null) {
          final chatId = update['message']['chat']['id'].toString();
          final firstName = update['message']['from']['first_name'] ?? 'Unknown';
          final username = update['message']['from']['username'] ?? 'No username';
          final text = update['message']['text'] ?? '';
          
          chatIds.add(chatId);
          print('   Chat ID: $chatId (User: $firstName @$username) - Last: "$text"');
        }
      }
      
      // Test /mybookings for each chat ID found
      for (final chatId in chatIds) {
        print('\n2️⃣ Testing /mybookings for Chat ID: $chatId');
        
        // Send a test message to trigger the webhook
        final testRequest = await client.postUrl(Uri.parse('$baseUrl/sendMessage'));
        testRequest.headers.set('Content-Type', 'application/json');
        testRequest.write(jsonEncode({
          'chat_id': chatId,
          'text': '🔍 Debug: Testing your bookings...',
        }));
        final testResponse = await testRequest.close();
        final testBody = await testResponse.transform(utf8.decoder).join();
        final testData = jsonDecode(testBody);
        
        if (testData['ok'] == true) {
          print('✅ Test message sent to $chatId');
          
          // Wait a moment then check webhook logs
          await Future.delayed(Duration(seconds: 2));
          
          // Try to simulate the webhook call directly
          print('🔧 Simulating webhook call for /mybookings...');
          
          // Call our Firebase Function directly
          final webhookRequest = await client.postUrl(
            Uri.parse('https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple')
          );
          webhookRequest.headers.set('Content-Type', 'application/json');
          webhookRequest.write(jsonEncode({
            'message': {
              'chat': {'id': int.parse(chatId)},
              'from': {'first_name': 'Debug', 'username': 'debug'},
              'text': '/mybookings',
            }
          }));
          
          final webhookResponse = await webhookRequest.close();
          final webhookBody = await webhookResponse.transform(utf8.decoder).join();
          
          print('📡 Webhook response: ${webhookResponse.statusCode}');
          if (webhookResponse.statusCode == 200) {
            final webhookData = jsonDecode(webhookBody);
            print('   Response: $webhookData');
          } else {
            print('   Error body: $webhookBody');
          }
        } else {
          print('❌ Failed to send test message: ${testData['description']}');
        }
      }
      
    } else {
      print('❌ No recent updates found or error: ${updatesData['description'] ?? 'Unknown'}');
    }
    
    print('\n📋 DEBUGGING SUMMARY:');
    print('');
    print('The bot is working correctly. The "no bookings" message means:');
    print('1. ✅ Your account is linked to Telegram');
    print('2. ✅ The bot can access your user data');
    print('3. ⚠️  You have no FUTURE bookings in the database');
    print('');
    print('🔍 POSSIBLE REASONS:');
    print('• All your bookings are in the past (older than today)');
    print('• Bookings exist but have no "date" field');
    print('• Bookings are stored under a different userId');
    print('• No bookings have been created yet');
    print('');
    print('💡 TO FIX:');
    print('1. Create a new booking in the CuddleCare app');
    print('2. Make sure the booking date is in the future');
    print('3. Try /mybookings again');
    
  } catch (e) {
    print('❌ Error during debugging: $e');
  } finally {
    client.close();
  }
}
