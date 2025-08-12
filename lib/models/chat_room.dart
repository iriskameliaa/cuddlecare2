import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String userId;
  final String providerId;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String lastMessage;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.userId,
    required this.providerId,
    this.bookingId,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isActive': isActive,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      providerId: map['providerId'] ?? '',
      bookingId: map['bookingId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: map['unreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? userId,
    String? providerId,
    String? bookingId,
    DateTime? createdAt,
    DateTime? lastMessageTime,
    String? lastMessage,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      providerId: providerId ?? this.providerId,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
