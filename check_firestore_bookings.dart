import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔍 Checking Firestore Bookings Data...\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: '1:959094650804:android:598989e0677afe564de4e1',
        messagingSenderId: '959094650804',
        projectId: 'cuddlecare2-dd913',
        storageBucket: 'cuddlecare2-dd913.firebasestorage.app',
      ),
    );

    final firestore = FirebaseFirestore.instance;

    // Step 1: Check all users to find your account
    print('1️⃣ Checking users with Telegram links...');
    final usersSnapshot = await firestore.collection('users').get();

    String? yourUserId;
    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      if (userData['telegramChatId'] != null) {
        print(
            '   User: ${userData['email'] ?? 'No email'} (ID: ${userDoc.id})');
        print('   Telegram Chat ID: ${userData['telegramChatId']}');
        print(
            '   Name: ${userData['name'] ?? userData['displayName'] ?? 'No name'}');
        yourUserId = userDoc.id; // Assume this is you for now
        print('');
      }
    }

    if (yourUserId == null) {
      print('❌ No users found with Telegram links!');
      print('💡 Make sure you\'ve linked your account with /link command');
      return;
    }

    // Step 2: Check all bookings for your user ID
    print('2️⃣ Checking bookings for user: $yourUserId');
    final bookingsSnapshot = await firestore
        .collection('bookings')
        .where('userId', isEqualTo: yourUserId)
        .get();

    if (bookingsSnapshot.docs.isEmpty) {
      print('❌ No bookings found for your user ID!');
      print('💡 Create a booking in the CuddleCare app first');
    } else {
      print('📅 Found ${bookingsSnapshot.docs.length} booking(s):');

      final now = DateTime.now();
      int futureBookings = 0;
      int pastBookings = 0;

      for (final bookingDoc in bookingsSnapshot.docs) {
        final bookingData = bookingDoc.data();
        final bookingId = bookingDoc.id;
        final service = bookingData['service'] ?? 'Unknown Service';
        final dateStr = bookingData['date'] ?? 'No date';
        final status = bookingData['status'] ?? 'No status';
        final petName = bookingData['petName'] ??
            bookingData['petNames']?[0] ??
            'Unknown Pet';

        print('');
        print('   📋 Booking ID: $bookingId');
        print('   🐾 Service: $service');
        print('   🐕 Pet: $petName');
        print('   📅 Date: $dateStr');
        print('   📊 Status: $status');

        // Check if date is in the future
        if (dateStr != 'No date') {
          try {
            final bookingDate = DateTime.parse(dateStr);
            if (bookingDate.isAfter(now)) {
              print('   ✅ FUTURE booking (will show in Telegram)');
              futureBookings++;
            } else {
              print('   ⏰ PAST booking (won\'t show in Telegram)');
              pastBookings++;
            }
          } catch (e) {
            print('   ❌ Invalid date format: $e');
          }
        } else {
          print('   ❌ No date set (won\'t show in Telegram)');
        }
      }

      print('');
      print('📊 SUMMARY:');
      print('   Total bookings: ${bookingsSnapshot.docs.length}');
      print('   Future bookings: $futureBookings (will show in Telegram)');
      print('   Past bookings: $pastBookings (won\'t show in Telegram)');
    }

    // Step 3: Check all bookings in the system (debug)
    print('');
    print('3️⃣ Checking all bookings in the system...');
    final allBookingsSnapshot =
        await firestore.collection('bookings').limit(10).get();

    if (allBookingsSnapshot.docs.isEmpty) {
      print('❌ No bookings exist in the entire system!');
    } else {
      print('📋 Sample bookings in the system:');
      for (final doc in allBookingsSnapshot.docs) {
        final data = doc.data();
        print(
            '   ID: ${doc.id} | User: ${data['userId']} | Service: ${data['service']} | Date: ${data['date']}');
      }
    }

    print('');
    print('🎯 CONCLUSION:');
    if (futureBookings > 0) {
      print('✅ You have future bookings! The Telegram bot should show them.');
      print('💡 Try /mybookings again in Telegram');
    } else {
      print('⚠️  You have no future bookings in the database.');
      print('💡 To see bookings in Telegram:');
      print('   1. Open CuddleCare app');
      print('   2. Create a new booking');
      print('   3. Set the date to tomorrow or later');
      print('   4. Try /mybookings in Telegram again');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
