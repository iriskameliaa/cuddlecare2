import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Testing Telegram Bot...\n');
  
  const botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';
  const baseUrl = 'https://api.telegram.org/bot$botToken';
  
  final client = HttpClient();
  
  try {
    // Test 1: Check bot info
    print('1️⃣ Testing bot connection...');
    final botInfoRequest = await client.getUrl(Uri.parse('$baseUrl/getMe'));
    final botInfoResponse = await botInfoRequest.close();
    final botInfoBody = await botInfoResponse.transform(utf8.decoder).join();
    final botInfoData = jsonDecode(botInfoBody);
    
    if (botInfoData['ok'] == true) {
      final botInfo = botInfoData['result'];
      print('✅ Bot connected successfully!');
      print('   Bot Username: @${botInfo['username']}');
      print('   Bot Name: ${botInfo['first_name']}');
      print('   Bot ID: ${botInfo['id']}');
    } else {
      print('❌ Bot connection failed: ${botInfoData['description']}');
      return;
    }
    
    print('');
    
    // Test 2: Check webhook status
    print('2️⃣ Checking webhook status...');
    final webhookRequest = await client.getUrl(Uri.parse('$baseUrl/getWebhookInfo'));
    final webhookResponse = await webhookRequest.close();
    final webhookBody = await webhookResponse.transform(utf8.decoder).join();
    final webhookData = jsonDecode(webhookBody);
    
    if (webhookData['ok'] == true) {
      final webhookInfo = webhookData['result'];
      final webhookUrl = webhookInfo['url'] ?? '';
      final pendingUpdates = webhookInfo['pending_update_count'] ?? 0;
      final lastErrorDate = webhookInfo['last_error_date'];
      final lastErrorMessage = webhookInfo['last_error_message'];
      
      print('📡 Webhook Status:');
      print('   URL: ${webhookUrl.isEmpty ? 'None (using polling)' : webhookUrl}');
      print('   Pending Updates: $pendingUpdates');
      
      if (lastErrorDate != null) {
        print('   ❌ Last Error: $lastErrorMessage');
        final errorTime = DateTime.fromMillisecondsSinceEpoch(lastErrorDate * 1000);
        print('   ⏰ Error Time: $errorTime');
      } else {
        print('   ✅ No recent errors');
      }
      
      // Check if webhook URL matches expected
      const expectedUrl = 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';
      if (webhookUrl == expectedUrl) {
        print('   ✅ Webhook URL is correct');
      } else if (webhookUrl.isEmpty) {
        print('   ⚠️  No webhook set (bot will only work with polling)');
      } else {
        print('   ⚠️  Webhook URL is different from expected');
        print('   Expected: $expectedUrl');
      }
    }
    
    print('');
    
    // Test 3: Test webhook endpoint (if set)
    const webhookUrl = 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';
    print('3️⃣ Testing webhook endpoint...');
    
    try {
      final webhookTestRequest = await client.getUrl(Uri.parse(webhookUrl));
      final webhookTestResponse = await webhookTestRequest.close();
      
      if (webhookTestResponse.statusCode == 405) {
        print('✅ Webhook endpoint is accessible (returns 405 Method Not Allowed for GET, which is expected)');
      } else {
        print('⚠️  Webhook endpoint returned status: ${webhookTestResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Webhook endpoint is not accessible: $e');
    }
    
    print('');
    
    // Recommendations
    print('📋 RECOMMENDATIONS:');
    
    final webhookRequest2 = await client.getUrl(Uri.parse('$baseUrl/getWebhookInfo'));
    final webhookResponse2 = await webhookRequest2.close();
    final webhookBody2 = await webhookResponse2.transform(utf8.decoder).join();
    final webhookData2 = jsonDecode(webhookBody2);
    
    if (webhookData2['ok'] == true) {
      final webhookInfo = webhookData2['result'];
      final webhookUrl = webhookInfo['url'] ?? '';
      final pendingUpdates = webhookInfo['pending_update_count'] ?? 0;
      final lastErrorMessage = webhookInfo['last_error_message'];
      
      if (webhookUrl.isEmpty) {
        print('   🔧 Set up webhook for production use');
        print('   💡 Use the "Setup Webhook" button in Bot Control');
      } else if (lastErrorMessage != null) {
        print('   ❌ Fix webhook errors: $lastErrorMessage');
        print('   💡 Check Firebase Functions logs');
      } else if (pendingUpdates > 0) {
        print('   ⚠️  $pendingUpdates pending updates - webhook may not be processing messages');
        print('   💡 Check webhook URL and Firebase Functions');
      } else {
        print('   ✅ Bot configuration looks good!');
        print('   💡 Try sending /start to your bot');
      }
    }
    
    print('');
    print('🤖 Bot Test Complete!');
    print('');
    print('To test your bot:');
    print('1. Open Telegram');
    print('2. Search for your bot username (shown above)');
    print('3. Send: /start');
    print('4. You should get a welcome message');
    
  } catch (e) {
    print('❌ Error during bot test: $e');
  } finally {
    client.close();
  }
}
