import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix chat rooms with empty provider IDs
  static Future<void> fixEmptyProviderIds() async {
    try {
      print('🔧 Starting chat room fix...');
      
      // Get all chat rooms with empty provider IDs
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('providerId', isEqualTo: '')
          .get();

      print('📊 Found ${snapshot.docs.length} chat rooms with empty provider IDs');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookingId = data['bookingId'] as String?;
        
        print('🔍 Processing chat room ${doc.id} with booking ID: $bookingId');

        if (bookingId != null && bookingId.isNotEmpty) {
          // Try to find the booking to get the provider ID
          final bookingSnapshot = await _firestore
              .collection('bookings')
              .doc(bookingId)
              .get();

          if (bookingSnapshot.exists) {
            final bookingData = bookingSnapshot.data() as Map<String, dynamic>;
            final providerId = bookingData['providerId'] as String?;
            
            if (providerId != null && providerId.isNotEmpty) {
              // Update the chat room with the correct provider ID
              await doc.reference.update({'providerId': providerId});
              print('✅ Updated chat room ${doc.id} with provider ID: $providerId');
            } else {
              print('❌ No provider ID found in booking $bookingId');
            }
          } else {
            print('❌ Booking $bookingId not found');
          }
        } else {
          print('❌ No booking ID found for chat room ${doc.id}');
          // Consider deleting this chat room as it's orphaned
          print('🗑️ Consider deleting orphaned chat room ${doc.id}');
        }
      }

      print('🎉 Chat room fix completed!');
    } catch (e) {
      print('❌ Error fixing chat rooms: $e');
      rethrow;
    }
  }

  /// Delete orphaned chat rooms (those without valid booking or provider info)
  static Future<void> deleteOrphanedChatRooms() async {
    try {
      print('🧹 Starting orphaned chat room cleanup...');
      
      // Get all chat rooms with empty provider IDs
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('providerId', isEqualTo: '')
          .get();

      print('📊 Found ${snapshot.docs.length} potential orphaned chat rooms');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookingId = data['bookingId'] as String?;
        
        if (bookingId == null || bookingId.isEmpty) {
          // Delete chat room without booking ID
          await doc.reference.delete();
          print('🗑️ Deleted orphaned chat room ${doc.id} (no booking ID)');
        } else {
          // Check if booking exists
          final bookingSnapshot = await _firestore
              .collection('bookings')
              .doc(bookingId)
              .get();

          if (!bookingSnapshot.exists) {
            // Delete chat room with non-existent booking
            await doc.reference.delete();
            print('🗑️ Deleted orphaned chat room ${doc.id} (booking $bookingId not found)');
          }
        }
      }

      print('🎉 Orphaned chat room cleanup completed!');
    } catch (e) {
      print('❌ Error cleaning up orphaned chat rooms: $e');
      rethrow;
    }
  }
}
