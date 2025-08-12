import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import '../services/telegram_bot_service.dart';
import 'chat_screen.dart';

class TestMessagingScreen extends StatefulWidget {
  const TestMessagingScreen({super.key});

  @override
  State<TestMessagingScreen> createState() => _TestMessagingScreenState();
}

class _TestMessagingScreenState extends State<TestMessagingScreen> {
  final MessagingService _messagingService = MessagingService();
  String? _testChatRoomId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Messaging'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messaging System Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Current User: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not logged in'}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTestChatRoom,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create Test Chat Room'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkExistingChatRooms,
                      child: const Text('Check Existing Chat Rooms'),
                    ),
                    if (_testChatRoomId != null) ...[
                      const SizedBox(height: 16),
                      Text('Chat Room ID: $_testChatRoomId'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: _testChatRoomId!,
                                otherUserName: 'Test Provider',
                                bookingId: 'test_booking_123',
                              ),
                            ),
                          );
                        },
                        child: const Text('Open Chat'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telegram Bot Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testTelegramBot,
                      child: const Text('Test Telegram Bot'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestChatRoom() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      // Create a test chat room with a dummy provider ID
      final chatRoomId = await _messagingService.createOrGetChatRoom(
        user.uid,
        'test_provider_123',
        bookingId: 'test_booking_123',
      );

      setState(() {
        _testChatRoomId = chatRoomId;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat room created: $chatRoomId')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _checkExistingChatRooms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      print('Checking existing chat rooms for user: ${user.uid}');

      // Get all chat rooms
      final snapshot =
          await FirebaseFirestore.instance.collection('chat_rooms').get();

      print('Total chat rooms in collection: ${snapshot.docs.length}');

      final userChatRooms = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final providerId = data['providerId'] as String?;

        print('Chat room ${doc.id}: userId=$userId, providerId=$providerId');

        if (userId == user.uid || providerId == user.uid) {
          userChatRooms.add(doc.id);
        }
      }

      print('Chat rooms for current user: ${userChatRooms.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${userChatRooms.length} chat rooms for you'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error checking chat rooms: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _testTelegramBot() async {
    try {
      // Test the bot info endpoint
      final botInfo = await TelegramBotService.getBotInfo();

      if (botInfo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bot info: ${botInfo['username']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bot token not configured')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telegram bot error: $e')),
      );
    }
  }
}
