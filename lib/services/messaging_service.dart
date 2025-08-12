import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/chat_room.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _messagesCollection = 'messages';
  final String _chatRoomsCollection = 'chat_rooms';

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or get existing chat room
  Future<String> createOrGetChatRoom(String userId, String providerId,
      {String? bookingId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Validate parameters
    if (userId.isEmpty) throw Exception('User ID cannot be empty');
    if (providerId.isEmpty) throw Exception('Provider ID cannot be empty');

    print(
        'createOrGetChatRoom - userId: $userId, providerId: $providerId, bookingId: $bookingId');

    // Check if chat room already exists
    final existingRoom = await _firestore
        .collection(_chatRoomsCollection)
        .where('userId', isEqualTo: userId)
        .where('providerId', isEqualTo: providerId)
        .limit(1)
        .get();

    if (existingRoom.docs.isNotEmpty) {
      return existingRoom.docs.first.id;
    }

    // Create new chat room
    final chatRoomId = const Uuid().v4();
    final chatRoom = ChatRoom(
      id: chatRoomId,
      userId: userId,
      providerId: providerId,
      bookingId: bookingId,
      createdAt: DateTime.now(),
      lastMessageTime: DateTime.now(),
      lastMessage: 'Chat started',
      lastMessageSenderId: currentUser.uid,
    );

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .set(chatRoom.toMap());

    return chatRoomId;
  }

  // Send a message
  Future<void> sendMessage(String chatRoomId, String content,
      {String? imageUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final messageId = const Uuid().v4();
    final message = Message(
      id: messageId,
      senderId: currentUser.uid,
      receiverId: '', // Will be set based on chat room
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      messageType: imageUrl != null ? 'image' : 'text',
    );

    // Get chat room to determine receiver
    final chatRoomDoc =
        await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).get();

    if (!chatRoomDoc.exists) throw Exception('Chat room not found');

    final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
    final receiverId = currentUser.uid == chatRoomData['userId']
        ? chatRoomData['providerId']
        : chatRoomData['userId'];

    final messageWithReceiver = message.copyWith(receiverId: receiverId);

    // Save message
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .set(messageWithReceiver.toMap());

    // Update chat room with last message
    await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': currentUser.uid,
      'unreadCount': FieldValue.increment(1),
    });
  }

  // Get messages for a chat room
  Stream<List<Message>> getMessages(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  // Get all chat rooms for current user (as user or provider) - Simple version
  Stream<List<ChatRoom>> getAllChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    print('getAllChatRooms - Current user: ${currentUser.uid}');

    return _firestore
        .collection(_chatRoomsCollection)
        .snapshots()
        .map((snapshot) {
      print(
          'getAllChatRooms - Total docs in collection: ${snapshot.docs.length}');

      final chatRooms = <ChatRoom>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Create chat room with document ID as the chat room ID
        final chatRoom = ChatRoom(
          id: doc.id, // Use document ID as chat room ID
          userId: data['userId'] ?? '',
          providerId: data['providerId'] ?? '',
          bookingId: data['bookingId'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageSenderId: data['lastMessageSenderId'] ?? '',
          unreadCount: data['unreadCount'] ?? 0,
          isActive: data['isActive'] ?? true,
        );

        // Only include chat rooms where current user is involved
        if (chatRoom.userId == currentUser.uid ||
            chatRoom.providerId == currentUser.uid) {
          chatRooms.add(chatRoom);
          print(
              'getAllChatRooms - Found room: ${chatRoom.id}, userId: ${chatRoom.userId}, providerId: ${chatRoom.providerId}');
        }
      }

      // Sort by last message time
      chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      print('getAllChatRooms - Final result count: ${chatRooms.length}');
      return chatRooms;
    });
  }

  // Get chat rooms for providers
  Stream<List<ChatRoom>> getProviderChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_chatRoomsCollection)
        .where('providerId', isEqualTo: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatRoom(
                id: doc.id, // Use document ID as chat room ID
                userId: data['userId'] ?? '',
                providerId: data['providerId'] ?? '',
                bookingId: data['bookingId'],
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                lastMessageTime:
                    (data['lastMessageTime'] as Timestamp).toDate(),
                lastMessage: data['lastMessage'] ?? '',
                lastMessageSenderId: data['lastMessageSenderId'] ?? '',
                unreadCount: data['unreadCount'] ?? 0,
                isActive: data['isActive'] ?? true,
              );
            }).toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final messagesQuery = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Reset unread count
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .update({'unreadCount': 0});
  }

  // Get unread message count for a chat room
  Stream<int> getUnreadCount(String chatRoomId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread count for current user
  Stream<int> getTotalUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection(_chatRoomsCollection)
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.fold(
            0, (sum, doc) => sum + ((doc.data()['unreadCount'] as int?) ?? 0)));
  }

  // Delete a message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .delete();
  }

  // Delete a chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    // Delete all messages in the chat room
    final messagesQuery = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete the chat room
    await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).delete();
  }
}
