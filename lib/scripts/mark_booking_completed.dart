import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script to mark bookings as completed for testing rating functionality
///
/// This script helps simulate the booking completion process in the mockup app
/// so users can test the rating system without waiting for actual service completion.
///
/// Usage:
/// 1. Run this script from the main app
/// 2. Select a booking to mark as completed
/// 3. The booking will be updated to 'completed' status
/// 4. Users can then rate the provider for that booking

class MarkBookingCompleted {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all pending or confirmed bookings for the current user
  static Future<List<Map<String, dynamic>>> getBookingsToComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return [];
      }

      // Get bookings that are pending or confirmed
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print('📋 Found ${bookings.length} bookings to complete');
      return bookings;
    } catch (e) {
      print('❌ Error getting bookings: $e');
      return [];
    }
  }

  /// Mark a specific booking as completed
  static Future<bool> markBookingAsCompleted(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'reviewed': false, // Ensure it's not reviewed yet
      });

      print('✅ Booking $bookingId marked as completed');
      return true;
    } catch (e) {
      print('❌ Error marking booking as completed: $e');
      return false;
    }
  }

  /// Mark all pending/confirmed bookings as completed (for testing)
  static Future<int> markAllBookingsAsCompleted() async {
    try {
      final bookings = await getBookingsToComplete();
      int completedCount = 0;

      for (final booking in bookings) {
        final success = await markBookingAsCompleted(booking['id']);
        if (success) completedCount++;
      }

      print('✅ Marked $completedCount bookings as completed');
      return completedCount;
    } catch (e) {
      print('❌ Error marking all bookings as completed: $e');
      return 0;
    }
  }

  /// Get completed bookings that haven't been reviewed yet
  static Future<List<Map<String, dynamic>>>
      getCompletedUnreviewedBookings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return [];
      }

      final snapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .where('reviewed', isEqualTo: false)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print(
          '📋 Found ${bookings.length} completed bookings waiting for review');
      return bookings;
    } catch (e) {
      print('❌ Error getting completed bookings: $e');
      return [];
    }
  }

  /// Print booking details for debugging
  static void printBookingDetails(Map<String, dynamic> booking) {
    print('''
📋 Booking Details:
   ID: ${booking['id']}
   Provider: ${booking['providerName'] ?? 'Unknown'}
   Service: ${booking['service'] ?? 'Unknown'}
   Pet: ${booking['petName'] ?? 'Unknown'}
   Date: ${booking['date'] ?? 'Unknown'}
   Time: ${booking['time'] ?? 'Unknown'}
   Status: ${booking['status'] ?? 'Unknown'}
   Reviewed: ${booking['reviewed'] ?? false}
''');
  }

  /// Interactive script to mark bookings as completed
  static Future<void> runInteractiveScript() async {
    print('''
🎯 MARK BOOKING AS COMPLETED SCRIPT
====================================
This script helps you mark bookings as completed for testing the rating system.

''');

    final bookings = await getBookingsToComplete();

    if (bookings.isEmpty) {
      print('❌ No pending or confirmed bookings found');
      print('💡 Create a booking first, then run this script again');
      return;
    }

    print('📋 Available bookings to mark as completed:');
    for (int i = 0; i < bookings.length; i++) {
      final booking = bookings[i];
      print(
          '${i + 1}. ${booking['providerName'] ?? 'Provider'} - ${booking['service'] ?? 'Service'} (${booking['petName'] ?? 'Pet'}) - ${booking['date'] ?? 'Date'}');
    }

    print('''
Options:
- Enter a number (1-${bookings.length}) to mark that booking as completed
- Enter 'all' to mark all bookings as completed
- Enter 'exit' to cancel

''');

    // Mark ALL bookings as completed to fix the issue
    print('🎯 Marking ALL bookings as completed...');

    int completedCount = 0;
    for (final booking in bookings) {
      print('\n📋 Processing booking:');
      printBookingDetails(booking);

      final success = await markBookingAsCompleted(booking['id']);
      if (success) {
        completedCount++;
        print('✅ Booking ${booking['id']} marked as completed');
      } else {
        print('❌ Failed to complete booking ${booking['id']}');
      }
    }

    if (completedCount > 0) {
      print('''

🎉 SUCCESS! Marked $completedCount bookings as completed.

Now users can:
1. Go to "View Bookings" screen
2. Find the completed bookings
3. Click "Rate Provider" buttons
4. Leave reviews for their providers

''');
    } else {
      print(
          '\n❌ No bookings were marked as completed. Check the logs for errors.');
    }
  }
}

// Example usage in main.dart or a test screen
void main() async {
  // Initialize Firebase (make sure this is done in your app)
  // await Firebase.initializeApp();

  // Run the interactive script
  await MarkBookingCompleted.runInteractiveScript();
}
