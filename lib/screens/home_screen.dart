// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuddlecare2/screens/login_screen.dart';
import 'package:cuddlecare2/screens/profile_screen.dart';
import 'package:cuddlecare2/screens/service_selection_screen.dart';
import 'package:cuddlecare2/models/user_profile.dart';
import 'package:cuddlecare2/screens/provider_list_screen.dart';
import 'package:cuddlecare2/screens/view_bookings_screen.dart';
import 'package:cuddlecare2/screens/provider_map_screen.dart';
import 'package:cuddlecare2/screens/chat_list_screen.dart';
import 'package:cuddlecare2/screens/test_messaging_screen.dart';
import 'package:cuddlecare2/screens/manage_pets_screen.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentAddress = 'Getting location...';
  final MessagingService _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();

    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        setState(() {
          _currentAddress = '${placemark.locality}, ${placemark.subLocality}';
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _currentAddress = 'Could not get location';
      });
    }
  }

  // Add the missing images list
  final List<String> images = [
    'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&h=400&fit=crop',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Only open profile page from the bottom nav when profile tab is tapped
  }

  Future<void> _startChatWithProvider(Map<String, dynamic> bookingData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to start chatting'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final providerId = bookingData['providerId'] as String?;
      final providerName = bookingData['providerName'] as String? ?? 'Provider';
      final bookingId = bookingData['id'] as String?;

      if (providerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create or get chat room
      final chatRoomId = await _messagingService.createOrGetChatRoom(
        user.uid,
        providerId,
        bookingId: bookingId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              otherUserName: providerName,
              bookingId: bookingId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> bookingData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bookingId = bookingData['id'] as String?;
      final providerName = bookingData['providerName'] as String? ?? 'Provider';
      final service = bookingData['service'] as String? ?? 'Service';
      final date = bookingData['date'] as String? ?? 'Date';

      if (bookingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking information not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final shouldCancel = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Cancel Booking'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Are you sure you want to cancel this booking?'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provider: $providerName'),
                          Text('Service: $service'),
                          Text('Date: $date'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Note: Cancellation policies may apply. Please check with your provider.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep Booking'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!shouldCancel) return;

      // Update booking status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return Center(child: Text('Search', style: TextStyle(fontSize: 24)));
      case 2:
        return Center(child: Text('Favorites', style: TextStyle(fontSize: 24)));
      case 3:
        return const ChatListScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    _currentAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Personalized Dashboard Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .snapshots(),
                builder: (context, snapshot) {
                  final allBookings = snapshot.data?.docs ?? [];
                  final userBookings = allBookings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['userId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                  }).toList();

                  final upcomingBookings = userBookings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'pending';
                    final dateString = data['date'] as String?;

                    // Only count as upcoming if status is pending/confirmed AND date is in the future
                    if (status != 'pending' && status != 'confirmed') {
                      return false;
                    }

                    if (dateString == null) {
                      return false; // No date means we can't determine if it's upcoming
                    }

                    try {
                      final bookingDate = DateTime.parse(dateString);
                      final now = DateTime.now();

                      // Create a date for today at midnight for comparison
                      final today = DateTime(now.year, now.month, now.day);
                      final bookingDateOnly = DateTime(
                          bookingDate.year, bookingDate.month, bookingDate.day);

                      // Consider it upcoming if the booking date is today or in the future
                      return bookingDateOnly.isAtSameMomentAs(today) ||
                          bookingDateOnly.isAfter(today);
                    } catch (e) {
                      print(
                          'Error parsing booking date: $dateString, error: $e');
                      return false; // Invalid date format
                    }
                  }).toList();

                  return Column(
                    children: [
                      // Welcome message
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.orange.shade700,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  'Ready to care for your pets?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Booking summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${upcomingBookings.length} upcoming booking${upcomingBookings.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  if (upcomingBookings.isNotEmpty) ...[
                                    Builder(
                                      builder: (context) {
                                        final firstBookingData =
                                            upcomingBookings.first.data()
                                                as Map<String, dynamic>;
                                        return Text(
                                          'Next: ${firstBookingData['date'] ?? 'Date TBD'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        );
                                      },
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Telegram Bot Information Card
                      InkWell(
                        onTap: () => _showTelegramInstructions(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.telegram,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CuddleCare Telegram Bot',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Get instant updates & smart notifications',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '@CuddleCare_app1_bot',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Actions Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          _buildQuickActionCard(
                            icon: Icons.search,
                            title: 'Find Providers',
                            subtitle: 'Book new service',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProviderMapScreen(),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionCard(
                            icon: Icons.calendar_today,
                            title: 'View Bookings',
                            subtitle: 'Manage bookings',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewBookingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionCard(
                            icon: Icons.chat,
                            title: 'Messages',
                            subtitle: 'Chat with providers',
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatListScreen(),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionCard(
                            icon: Icons.pets,
                            title: 'My Pets',
                            subtitle: 'Update pet info',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManagePetsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
    );
  }

  void _showTelegramInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.telegram,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Connect to CuddleCare Bot',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Follow these simple steps to connect:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionStep(
                  '1',
                  'Open Telegram',
                  'Launch the Telegram app on your phone or computer',
                  Icons.phone_android,
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '2',
                  'Search for the Bot',
                  'Search for @CuddleCare_app1_bot and tap on it',
                  Icons.search,
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '3',
                  'Start the Bot',
                  'Send /start to begin receiving notifications',
                  Icons.play_arrow,
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '4',
                  'Link Your Account',
                  'Send /link followed by your email to connect your account',
                  Icons.link,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What you\'ll get:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Instant booking confirmations\n• Weather-based pet care tips\n• Service reminders\n• Provider updates\n• Smart recommendations',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // You could add logic here to open Telegram directly if possible
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Open Telegram and search for @CuddleCare_app1_bot'),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.telegram),
              label: const Text('Open Telegram'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionStep(
      String number, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
