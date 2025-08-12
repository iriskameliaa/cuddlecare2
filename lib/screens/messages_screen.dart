import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cuddlecare2/screens/chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (currentUser == null) return;

    try {
      // Get all bookings for this pet sitter
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('petSitterId', isEqualTo: currentUser!.uid)
          .get();

      // Get unique user IDs from bookings
      final userIds = bookingsSnapshot.docs
          .map((doc) => doc.data()['petOwnerId'] as String)
          .toSet()
          .toList();

      // Get user details for each booking
      final conversations = <Map<String, dynamic>>[];
      for (final userId in userIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final lastMessage = await _getLastMessage(userId);

          conversations.add({
            'userId': userId,
            'userName': userData['name'] ?? 'Unknown User',
            'userPhotoUrl': userData['profilePicUrl'],
            'lastMessage': lastMessage['message'],
            'lastMessageTime': lastMessage['timestamp'],
            'unreadCount': lastMessage['unreadCount'],
          });
        }
      }

      // Sort conversations by last message time
      conversations.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getLastMessage(String userId) async {
    try {
      final chatId = _getChatId(userId);
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesSnapshot.docs.isEmpty) {
        return {
          'message': 'No messages yet',
          'timestamp': null,
          'unreadCount': 0,
        };
      }

      final lastMessage = messagesSnapshot.docs.first.data();
      final unreadCount = await _getUnreadCount(chatId);

      return {
        'message': lastMessage['text'],
        'timestamp': lastMessage['timestamp'],
        'unreadCount': unreadCount,
      };
    } catch (e) {
      print('Error getting last message: $e');
      return {
        'message': 'Error loading messages',
        'timestamp': null,
        'unreadCount': 0,
      };
    }
  }

  Future<int> _getUnreadCount(String chatId) async {
    try {
      final unreadSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser!.uid)
          .get();

      return unreadSnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  String _getChatId(String userId) {
    // Create a unique chat ID by sorting user IDs
    final ids = [currentUser!.uid, userId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.message_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Messages will appear here when users contact you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: conversation['userPhotoUrl'] != null
                  ? NetworkImage(conversation['userPhotoUrl'])
                  : null,
              child: conversation['userPhotoUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(conversation['userName']),
            subtitle: Text(
              conversation['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation['lastMessageTime'] != null)
                  Text(
                    DateFormat('MMM d').format(
                      (conversation['lastMessageTime'] as Timestamp).toDate(),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (conversation['unreadCount'] > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conversation['unreadCount'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    userId: conversation['userId'],
                    userName: conversation['userName'],
                    userPhotoUrl: conversation['userPhotoUrl'],
                  ),
                ),
              ).then((_) => _loadConversations());
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (currentUser == null) return;

    _chatId = _getChatId(widget.userId);
    await _loadMessages();
    _markMessagesAsRead();
  }

  String _getChatId(String userId) {
    final ids = [currentUser!.uid, userId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _loadMessages() async {
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _messages = messagesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _isLoading = false;
      });

      if (_messages.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final message = {
        'text': _messageController.text.trim(),
        'senderId': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(message);

      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser!.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userPhotoUrl != null
                  ? NetworkImage(widget.userPhotoUrl!)
                  : null,
              child:
                  widget.userPhotoUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
            Text(widget.userName),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == currentUser!.uid;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
