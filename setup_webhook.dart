import 'dart:convert';
import 'dart:io';

void main() async {
  print('🚀 Setting up Telegram Bot Webhook...\n');
  
  const botToken = '7583657491:AAGfNFb60aDPkquorxgZ4Lg8t5uN1-JGSDo';
  const baseUrl = 'https://api.telegram.org/bot$botToken';
  const webhookUrl = 'https://us-central1-cuddlecare2-dd913.cloudfunctions.net/telegramWebhookSimple';
  
  final client = HttpClient();
  
  try {
    // Step 1: Delete existing webhook (if any)
    print('1️⃣ Deleting existing webhook...');
    final deleteRequest = await client.postUrl(Uri.parse('$baseUrl/deleteWebhook'));
    deleteRequest.headers.set('Content-Type', 'application/json');
    deleteRequest.write(jsonEncode({
      'drop_pending_updates': true,
    }));
    final deleteResponse = await deleteRequest.close();
    final deleteBody = await deleteResponse.transform(utf8.decoder).join();
    final deleteData = jsonDecode(deleteBody);
    
    if (deleteData['ok'] == true) {
      print('✅ Existing webhook deleted');
    } else {
      print('⚠️  Delete webhook response: ${deleteData['description']}');
    }
    
    // Wait a moment
    await Future.delayed(Duration(seconds: 2));
    
    // Step 2: Set new webhook
    print('2️⃣ Setting new webhook...');
    final setRequest = await client.postUrl(Uri.parse('$baseUrl/setWebhook'));
    setRequest.headers.set('Content-Type', 'application/json');
    setRequest.write(jsonEncode({
      'url': webhookUrl,
      'allowed_updates': ['message'],
      'drop_pending_updates': true,
    }));
    final setResponse = await setRequest.close();
    final setBody = await setResponse.transform(utf8.decoder).join();
    final setData = jsonDecode(setBody);
    
    if (setData['ok'] == true) {
      print('✅ Webhook set successfully!');
      print('   URL: $webhookUrl');
    } else {
      print('❌ Failed to set webhook: ${setData['description']}');
      return;
    }
    
    // Wait a moment for webhook to be active
    await Future.delayed(Duration(seconds: 3));
    
    // Step 3: Verify webhook
    print('3️⃣ Verifying webhook...');
    final verifyRequest = await client.getUrl(Uri.parse('$baseUrl/getWebhookInfo'));
    final verifyResponse = await verifyRequest.close();
    final verifyBody = await verifyResponse.transform(utf8.decoder).join();
    final verifyData = jsonDecode(verifyBody);
    
    if (verifyData['ok'] == true) {
      final webhookInfo = verifyData['result'];
      final currentUrl = webhookInfo['url'] ?? '';
      final pendingUpdates = webhookInfo['pending_update_count'] ?? 0;
      
      print('📡 Webhook Status:');
      print('   URL: $currentUrl');
      print('   Pending Updates: $pendingUpdates');
      
      if (currentUrl == webhookUrl) {
        print('✅ Webhook is correctly configured!');
      } else {
        print('❌ Webhook URL mismatch');
      }
    }
    
    print('');
    print('🎉 WEBHOOK SETUP COMPLETE!');
    print('');
    print('Your bot should now respond to commands.');
    print('');
    print('🧪 TEST YOUR BOT:');
    print('1. Open Telegram');
    print('2. Search for: @CuddleCare_app1_bot');
    print('3. Send: /start');
    print('4. You should get a welcome message!');
    print('');
    print('📱 AVAILABLE COMMANDS:');
    print('• /start - Welcome message');
    print('• /link your.email@example.com - Link your account');
    print('• /mybookings - View bookings');
    print('• /mypets - View pets');
    
  } catch (e) {
    print('❌ Error setting up webhook: $e');
  } finally {
    client.close();
  }
}
