import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';
import 'rate_provider_screen.dart';

class ViewBookingsScreen extends StatefulWidget {
  const ViewBookingsScreen({super.key});

  @override
  State<ViewBookingsScreen> createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  final MessagingService _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use a simple query and filter on client side to avoid index issues
        final snapshot =
            await FirebaseFirestore.instance.collection('bookings').get();

        final allBookings = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Filter bookings for this user
        final userBookings = allBookings.where((booking) {
          return booking['userId'] == user.uid;
        }).toList();

        // Sort by date
        userBookings.sort((a, b) {
          final aDate = a['date'] as String? ?? '';
          final bDate = b['date'] as String? ?? '';
          return aDate.compareTo(bDate);
        });

        setState(() {
          _bookings = userBookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

      await _loadBookings();
    } catch (e) {
      print('Error updating booking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking status: $e')),
      );
    }
  }

  Future<void> _cancelBooking(
      String bookingId, Map<String, dynamic> booking) async {
    // Show cancellation reason dialog
    final cancellationReason = await _showCancellationReasonDialog();
    if (cancellationReason == null) return; // User cancelled the dialog

    // Show confirmation dialog
    final shouldCancel = await _showCancellationConfirmationDialog(booking);
    if (!shouldCancel) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'cancellationReason': cancellationReason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': FirebaseAuth.instance.currentUser?.uid,
      });

      await _loadBookings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showCancellationReasonDialog() async {
    final List<String> reasons = [
      'Change of plans',
      'Found another provider',
      'Pet is sick',
      'Weather conditions',
      'Emergency',
      'Other',
    ];

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? selectedReason = reasons.first;

        return AlertDialog(
          title: const Text('Cancellation Reason'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please select a reason for cancelling this booking:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...reasons.map((reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      )),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedReason),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showCancellationConfirmationDialog(
      Map<String, dynamic> booking) async {
    final providerName = booking['providerName'] as String? ?? 'Provider';
    final service = booking['service'] as String? ?? 'Service';
    final date = booking['date'] as String? ?? 'Date';

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cancel Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to cancel this booking?'),
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
                  _buildCancellationPolicyInfo(),
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
  }

  Widget _buildCancellationPolicyInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Cancellation Policy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Free cancellation up to 24 hours before service\n'
            '• 50% refund for cancellations 2-24 hours before\n'
            '• No refund for cancellations within 2 hours',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCancellationDate(dynamic cancelledAt) {
    if (cancelledAt == null) return 'Unknown date';

    try {
      if (cancelledAt is Timestamp) {
        final date = cancelledAt.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _startChatWithProvider(Map<String, dynamic> booking) async {
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

      final providerId = booking['providerId'] as String?;
      final providerName = booking['providerName'] as String? ?? 'Provider';
      final bookingId = booking['id'] as String?;

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

  Future<void> _rateProvider(Map<String, dynamic> booking) async {
    final bookingId = booking['id'] as String;
    final providerId = booking['providerId'] as String;
    final providerName = booking['providerName'] as String? ?? 'Provider';
    final service = booking['service'] as String? ?? 'Service';
    // Handle multiple pets or single pet
    String petName;
    if (booking['petNames'] != null &&
        booking['petNames'] is List &&
        (booking['petNames'] as List).length > 1) {
      petName = (booking['petNames'] as List).join(', ');
    } else {
      petName =
          booking['petName'] as String? ?? booking['petNames']?[0] ?? 'Pet';
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateProviderScreen(
          providerId: providerId,
          providerName: providerName,
          bookingId: bookingId,
          service: service,
          petName: petName,
        ),
      ),
    );

    // Refresh bookings if review was submitted
    if (result == true) {
      await _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try to pop first, if that fails, navigate to a safe route
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If we can't pop, navigate to the main screen
              try {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              } catch (e) {
                // If that fails too, try the welcome screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              }
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(
                  child: Text(
                    'No bookings found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Booking #${booking['id'].substring(0, 6)}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(booking['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    booking['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(booking['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.pets,
                              _buildPetDisplayText(booking),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person,
                              'Provider: ${booking['providerName'] ?? 'Provider'}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Date: ${booking['date'] ?? 'Date not set'}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.access_time,
                              'Time: ${booking['time'] ?? 'Time not set'}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.work,
                              'Service: ${booking['service'] ?? 'Service'}',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _startChatWithProvider(booking),
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Chat with Provider'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                if (booking['status'] == 'pending' ||
                                    booking['status'] == 'confirmed') ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _cancelBooking(
                                          booking['id'], booking),
                                      icon: const Icon(Icons.cancel, size: 18),
                                      label: const Text('Cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side:
                                            const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Rate button for completed bookings
                            if (booking['status'] == 'completed' &&
                                (booking['reviewed'] != true)) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _rateProvider(booking),
                                  icon: const Icon(Icons.star, size: 18),
                                  label: const Text('Rate Provider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            // Show reviewed status
                            if (booking['status'] == 'completed' &&
                                booking['reviewed'] == true) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Review Submitted',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _buildPetDisplayText(Map<String, dynamic> booking) {
    // Handle multiple pets or single pet
    if (booking['petNames'] != null &&
        booking['petNames'] is List &&
        (booking['petNames'] as List).length > 1) {
      final petNames = booking['petNames'] as List;
      final petCount = booking['petCount'] ?? petNames.length;
      return 'Pets ($petCount): ${petNames.join(', ')}';
    } else {
      final petName =
          booking['petName'] as String? ?? booking['petNames']?[0] ?? 'Pet';
      return 'Pet: $petName';
    }
  }
}
