import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_bookings_screen.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';

class ProviderMapScreen extends StatefulWidget {
  const ProviderMapScreen({super.key});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _radius = 50.0; // Reasonable radius for local providers
  String? _selectedPetType;
  String? _selectedService;
  DateTime? _selectedDate;
  List<String> _selectedPetIds = []; // Changed to support multiple pets
  List<DocumentSnapshot> _providers = [];
  bool _isLoading = false;
  String? _noResultsMsg;
  Set<Marker> _markers = {};
  bool _showPreFilter = true; // New: control whether to show pre-filter or map

  final List<String> _allPetTypes = ['Dog', 'Cat', 'Rabbit'];
  final List<String> _allServices = [
    'Pet Sitting',
    'Pet Grooming',
    'Pet Walking',
    'Pet Health Checkups',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _updateFarisLocation(); // Move Faris closer to user
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Get the user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _noResultsMsg = 'Could not get your location.';
      });
    }
  }

  /// Update Faris's location to be near user (one-time fix)
  Future<void> _updateFarisLocation() async {
    try {
      // Faris's user ID from logs: 60YOXUz0EdWn9a7J7yay3u9ICPo2
      const farisId = '60YOXUz0EdWn9a7J7yay3u9ICPo2';

      // New location near Melaka (about 5km from user)
      const newLocation = {
        'lat': 2.2300000, // Slightly north of user
        'lng': 102.4600000, // Slightly east of user
      };

      // Update in both collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(farisId)
          .update({'location': newLocation});

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(farisId)
          .update({'location': newLocation});

      print('✅ Faris location updated to be near user');
    } catch (e) {
      print('❌ Error updating Faris location: $e');
    }
  }

  /// Query providers from Firestore and filter locally by distance, pet type, service, and availability
  Future<void> _queryProviders() async {
    if (_currentPosition == null) {
      print('❌ ERROR: Current position is null! Cannot query providers.');
      return;
    }
    setState(() {
      _isLoading = true;
      _noResultsMsg = null;
    });

    try {
      final List<DocumentSnapshot> allProviders = [];

      // Run both queries in parallel for better performance
      final futures = <Future<QuerySnapshot>>[];

      // Search in providers collection (migrated providers)
      Query<Map<String, dynamic>> providersQuery =
          FirebaseFirestore.instance.collection('providers');
      if (_selectedService != null) {
        providersQuery =
            providersQuery.where('services', arrayContains: _selectedService);
      }
      if (_selectedPetType != null) {
        providersQuery =
            providersQuery.where('petTypes', arrayContains: _selectedPetType);
      }
      futures.add(providersQuery.get());

      // Also search in users collection for providers that haven't been migrated yet
      Query<Map<String, dynamic>> usersQuery = FirebaseFirestore.instance
          .collection('users')
          .where('isPetSitter', isEqualTo: true);
      if (_selectedService != null) {
        usersQuery =
            usersQuery.where('services', arrayContains: _selectedService);
      }
      if (_selectedPetType != null) {
        usersQuery =
            usersQuery.where('petTypes', arrayContains: _selectedPetType);
      }
      futures.add(usersQuery.get());

      // Wait for both queries to complete
      final results = await Future.wait(futures);
      // allProviders.addAll(results[0].docs);
      // allProviders.addAll(results[1].docs);

      Set<String> seenIdentifiers = {};
      allProviders.clear();

      for (int i = 0; i < results.length; i++) {
        final snapshot = results[i];
        print(
            '📦 Processing snapshot index $i with ${snapshot?.docs.length ?? 0} documents');

        if (snapshot != null) {
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;

            final name = (data['name'] ?? '').toString().toLowerCase().trim();
            final email = (data['email'] ?? '').toString().toLowerCase().trim();
            final phone =
                (data['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');

            final dedupKey = '$name|$email|$phone';

            if (name.isEmpty && email.isEmpty && phone.isEmpty) {
              print(
                  '⚠️ Skipping doc [${doc.id}]: Missing name, email, and phone');
              continue;
            }

            if (!seenIdentifiers.contains(dedupKey)) {
              seenIdentifiers.add(dedupKey);
              allProviders.add(doc);
              print('✅ Added provider [${doc.id}]: $dedupKey');
            } else {
              print('❌ Duplicate skipped [${doc.id}]: $dedupKey');
            }
          }
        } else {
          print('⚠️ Snapshot at index $i is null and was skipped.');
        }
      }

      print('🎯 Total unique providers added: ${allProviders.length}');

      print('🔍 DEBUG: Found ${allProviders.length} total providers');

      // 🆕 DEBUG: Show current location for distance calculation verification
      print('\n📍 CURRENT USER LOCATION:');
      print('  Latitude: ${_currentPosition!.latitude}');
      print('  Longitude: ${_currentPosition!.longitude}');
      print('  Search Radius: ${_radius}km');
      print('');

      // 🆕 DEBUG: Console output for ALL providers WITHOUT filtering
      print('\n=== 🔍 ALL PROVIDERS WITHOUT FILTERING (DEBUG) ===');
      for (int i = 0; i < allProviders.length; i++) {
        final doc = allProviders[i];
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final email = data['email'] ?? 'No email';
        final location = data['location'] ?? data['geoPointLocation'];
        final isPetSitter = data['isPetSitter'] ?? false;
        final role = data['role'] ?? 'None';
        final services = data['services'] as List?;
        final petTypes = data['petTypes'] as List?;
        final availability = data['availability'];
        final verified = data['isVerified'] ?? false;

        print('Provider ${i + 1}/${allProviders.length}:');
        print('  📛 Name: $name');
        print('  📧 Email: $email');
        print('  📍 Location: $location');
        print('  🐾 Pet Sitter: $isPetSitter');
        print('  👤 Role: $role');
        print('  🛠️ Services: $services');
        print('  🐕 Pet Types: $petTypes');
        print('  📅 Availability: $availability');
        print('  ✅ Verified: $verified');
        print('  📄 Document ID: ${doc.id}');
        print('  ---');
      }
      print('=== END ALL PROVIDERS DEBUG ===\n');

      for (final doc in allProviders) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final location = data['location'] ?? data['geoPointLocation'];
        final isPetSitter = data['isPetSitter'] ?? false;
        final role = data['role'] ?? 'None';
        final services = data['services'] as List?;
        final petTypes = data['petTypes'] as List?;
        print(
            '  - $name: location=$location, isPetSitter=$isPetSitter, role=$role, services=$services, petTypes=$petTypes');
      }

      final List<DocumentSnapshot> filtered = [];

      // Process providers in batches for better performance
      const batchSize = 10;
      for (int i = 0; i < allProviders.length; i += batchSize) {
        final end = (i + batchSize < allProviders.length)
            ? i + batchSize
            : allProviders.length;

        for (int j = i; j < end; j++) {
          final doc = allProviders[j];
          final data = doc.data() as Map<String, dynamic>;
          final pos = data['location'] ?? data['geoPointLocation'];
          if (pos == null) {
            final providerName = data['name'] ?? 'Unknown';
            print('❌ $providerName filtered out: no location data');
            continue;
          }

          // Handle different location formats
          double lat, lng;
          if (pos is Map) {
            // Location stored as {lat: x, lng: y}
            if (pos['lat'] == null || pos['lng'] == null) continue;
            lat = (pos['lat'] as num).toDouble();
            lng = (pos['lng'] as num).toDouble();
          } else if (pos is GeoPoint) {
            // Location stored as GeoPoint
            lat = pos.latitude;
            lng = pos.longitude;
          } else {
            continue;
          }

          // Quick distance check first
          final double actualDistance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lng,
              ) /
              1000.0;

          // Filter by distance
          final providerName = data['name'] ?? 'Unknown';
          if (actualDistance > _radius) {
            print(
                '❌ $providerName filtered out: distance ${actualDistance.toStringAsFixed(1)}km > ${_radius.toStringAsFixed(1)}km');
            continue;
          }

          // Simplified availability check - only if date is selected
          if (_selectedDate != null) {
            final availabilityRaw = data['availability'];
            bool isAvailable = false;

            if (availabilityRaw is Map) {
              final dayName = _getDayName(_selectedDate!.weekday).toLowerCase();
              if (availabilityRaw[dayName] != null) {
                final dayData =
                    availabilityRaw[dayName] as Map<String, dynamic>;
                isAvailable = dayData['available'] == true;
              }
            } else if (availabilityRaw is List) {
              final dateStr = _selectedDate!.toIso8601String().substring(0, 10);
              isAvailable = availabilityRaw.contains(dateStr);
            }

            if (!isAvailable) continue;
          }

          filtered.add(doc);
        }

        // Update UI periodically to show progress
        if (filtered.length % batchSize == 0) {
          setState(() {
            _providers = List.from(filtered);
            _markers = _buildMarkers();
          });
        }
      }

      // 🆕 SORT PROVIDERS BY DISTANCE (Nearest to Furthest)
      filtered.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        final posA = dataA['location'] ?? dataA['geoPointLocation'];
        final posB = dataB['location'] ?? dataB['geoPointLocation'];

        double distanceA = double.infinity;
        double distanceB = double.infinity;

        if (posA != null && posA is Map) {
          final latA = (posA['lat'] as num).toDouble();
          final lngA = (posA['lng'] as num).toDouble();
          distanceA = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                latA,
                lngA,
              ) /
              1000.0;
        }

        if (posB != null && posB is Map) {
          final latB = (posB['lat'] as num).toDouble();
          final lngB = (posB['lng'] as num).toDouble();
          distanceB = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                latB,
                lngB,
              ) /
              1000.0;
        }

        return distanceA
            .compareTo(distanceB); // Ascending order (nearest first)
      });

      // 🆕 DEBUG: Show final filtered results (now sorted by distance)
      print(
          '\n🎯 FINAL FILTERED PROVIDERS (SORTED BY DISTANCE): ${filtered.length}');
      for (int i = 0; i < filtered.length; i++) {
        final doc = filtered[i];
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final pos = data['location'] ?? data['geoPointLocation'];
        double? distance;
        if (pos != null && pos is Map) {
          final lat = (pos['lat'] as num).toDouble();
          final lng = (pos['lng'] as num).toDouble();
          distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lng,
              ) /
              1000.0;
        }
        print(
            '✅ Provider ${i + 1}: $name (${distance?.toStringAsFixed(1)}km) - ID: ${doc.id}');
      }
      print('');

      setState(() {
        _providers = filtered;
        _isLoading = false;
        _noResultsMsg = filtered.isEmpty ? 'No providers found.' : null;
        _markers = _buildMarkers();
      });

      // Auto-focus map on providers if found
      if (filtered.isNotEmpty && _mapController != null) {
        // Small delay to ensure map is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _focusOnProviders();
          }
        });
      }
    } catch (e) {
      print('Error querying providers: $e');
      setState(() {
        _isLoading = false;
        _noResultsMsg = 'Error loading providers: $e';
      });
    }
  }

  /// Build Google Map markers for the user and providers
  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    // Add user's location marker (blue)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Tap to center map here',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Add provider markers (green for available, red for unavailable)
    for (int i = 0; i < _providers.length; i++) {
      final doc = _providers[i];
      final data = doc.data() as Map<String, dynamic>;
      final pos = data['location'] ?? data['geoPointLocation'];
      if (pos == null) continue;

      // Handle different location formats
      double lat, lng;
      if (pos is Map) {
        // Location stored as {lat: x, lng: y}
        if (pos['lat'] == null || pos['lng'] == null) continue;
        lat = (pos['lat'] as num).toDouble();
        lng = (pos['lng'] as num).toDouble();
      } else if (pos is GeoPoint) {
        // Location stored as GeoPoint
        lat = pos.latitude;
        lng = pos.longitude;
      } else {
        continue;
      }

      // Calculate distance for info window
      double distance = 0;
      if (_currentPosition != null) {
        distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            ) /
            1000.0;
      }

      // Get pet types and services for info window
      final petTypes = (data['petTypes'] as List?)?.join(', ') ??
          (data['preferredPetTypes'] as List?)?.join(', ') ??
          'N/A';
      final services = (data['services'] as List?)?.join(', ') ?? 'N/A';

      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: data['name'] ?? 'Pet Care Provider',
            snippet:
                '${distance.toStringAsFixed(1)} km away\nPet Types: $petTypes\nServices: $services',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          // Removed overlay popup functionality to prevent duplication
          // Providers are now only shown in the list below the map
        ),
      );
    }
    return markers;
  }

  // Helper method to convert weekday number to day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  // Focus map on provider markers
  void _focusOnProviders() {
    if (_providers.isEmpty || _mapController == null) return;

    // Calculate bounds to include all providers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var doc in _providers) {
      final data = doc.data() as Map<String, dynamic>;
      final pos = data['location'] ?? data['geoPointLocation'];
      if (pos == null) continue;

      double lat, lng;
      if (pos is Map) {
        if (pos['lat'] == null || pos['lng'] == null) continue;
        lat = (pos['lat'] as num).toDouble();
        lng = (pos['lng'] as num).toDouble();
      } else if (pos is GeoPoint) {
        lat = pos.latitude;
        lng = pos.longitude;
      } else {
        continue;
      }

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    // Add some padding around the bounds
    const padding = 0.01; // About 1km padding
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    // Create bounds
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate camera to show all providers
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0), // 50px padding
    );
  }

  /// Build the provider card widget
  Widget _buildProviderCard(DocumentSnapshot provider, double distance) {
    final data = provider.data() as Map<String, dynamic>;
    final profilePicUrl = data['profilePicUrl'] as String?;
    final name = data['name'] ?? 'Pet Care Provider';
    final petTypes = (data['petTypes'] as List?)?.join(', ') ?? 'N/A';
    final services = (data['services'] as List?)?.join(', ') ?? 'N/A';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

    // Restore availability calculation for next 90 days (3 months)
    final availabilityRaw = data['availability'];
    List<String> availability = [];
    if (availabilityRaw is Map) {
      final now = DateTime.now();
      for (int i = 0; i < 90; i++) {
        // Extended from 7 to 90 days
        final date = now.add(Duration(days: i));
        final dayName = _getDayName(date.weekday).toLowerCase();
        if (availabilityRaw[dayName] != null) {
          final dayData = availabilityRaw[dayName] as Map<String, dynamic>;
          if (dayData['available'] == true) {
            availability.add(date.toIso8601String().substring(0, 10));
          }
        }
      }
    } else if (availabilityRaw is List) {
      availability = availabilityRaw.map((e) => e.toString()).toList();
    }

    // If no availability data, generate default availability for next 90 days
    if (availability.isEmpty) {
      final now = DateTime.now();
      for (int i = 0; i < 90; i++) {
        // Extended from 7 to 90 days
        final date = now.add(Duration(days: i));
        availability.add(date.toIso8601String().substring(0, 10));
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                  ? NetworkImage(profilePicUrl)
                  : null,
              child: (profilePicUrl == null || profilePicUrl.isEmpty)
                  ? Icon(Icons.person, color: Colors.deepOrange, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            // Info and actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(
                        ' ${rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' ($reviewCount)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pet Types: $petTypes',
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Services: $services',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${distance.toStringAsFixed(2)} km away',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            // Start chat with provider
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final messagingService = MessagingService();
                              final chatRoomId =
                                  await messagingService.createOrGetChatRoom(
                                user.uid,
                                provider.id,
                              );

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatRoomId: chatRoomId,
                                      otherUserName: name,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please log in to start chatting'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('Chat',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _showBookingSheet(
                              data,
                              provider.id,
                              (data['services'] as List?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  [],
                              availability,
                            );
                          },
                          icon: const Icon(Icons.book_online, size: 16),
                          label: const Text('Book Now',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show filter modal/bottom sheet
  void _showFilterModal() async {
    String? petType = _selectedPetType;
    String? service = _selectedService;
    DateTime? date = _selectedDate;
    double radius = _radius;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pet Type Dropdown
                  DropdownButtonFormField<String>(
                    value: petType,
                    items: _allPetTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) => setModalState(() => petType = val),
                    decoration: const InputDecoration(labelText: 'Pet Type'),
                  ),
                  const SizedBox(height: 12),
                  // Service Type Chips
                  Wrap(
                    spacing: 8,
                    children: _allServices.map((serviceType) {
                      final selected = service == serviceType;
                      return ChoiceChip(
                        label: Text(serviceType),
                        selected: selected,
                        onSelected: (_) =>
                            setModalState(() => service = serviceType),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Date Picker
                  ListTile(
                    title: Text(date == null
                        ? 'Select Date'
                        : date.toString().substring(0, 10)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Distance Slider
                  Row(
                    children: [
                      Text('Distance: ${radius.toStringAsFixed(1)} km'),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max:
                              15000, // Increased from 100 to 15000 km for testing purposes
                          value: radius,
                          onChanged: (val) => setModalState(() => radius = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPetType = petType;
                              _selectedService = service;
                              _selectedDate = date;
                              _radius = radius;
                            });
                            Navigator.pop(context);
                            _queryProviders();
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedPetType = null;
                              _selectedService = null;
                              _selectedDate = null;
                              _radius = 50.0; // Reset to reasonable 50km radius
                            });
                            Navigator.pop(context);
                            _queryProviders();
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingSheet(Map<String, dynamic> providerData, String providerId,
      List<String> services, List<String> availableDates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BookingForm(
          providerId: providerId,
          providerName: providerData['name'] ?? 'Provider',
          services: services,
          availableDates: availableDates,
          userId: user.uid,
          userName: providerData['userName'] ?? '',
        );
      },
    );
  }

  /// Show the pre-filtering screen
  Widget _buildPreFilterScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Find Pet Care'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'What do you need?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about your pet care needs and we\'ll find the perfect provider for you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Pet Selection
              Text(
                'Choose Your Pet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('pets')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading pets...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error loading pets: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final pets = snapshot.data?.docs ?? [];

                  if (pets.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Pets Found',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add a pet to your profile to book services',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/manage_pets');
                            },
                            child: Text(
                              'Add Pet',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your pets:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...pets.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final petId = doc.id;
                          final isSelected = _selectedPetIds.contains(petId);
                          return CheckboxListTile(
                            title: Text('${data['name']} (${data['type']})'),
                            subtitle: data['breed'] != null &&
                                    data['breed'].isNotEmpty
                                ? Text('${data['breed']}')
                                : null,
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPetIds.add(petId);
                                } else {
                                  _selectedPetIds.remove(petId);
                                }
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                        if (_selectedPetIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedPetIds.length} pet${_selectedPetIds.length == 1 ? '' : 's'} selected',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Service Selection
              Text(
                'Service Type',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _allServices.map((service) {
                  final isSelected = _selectedService == service;
                  return ChoiceChip(
                    label: Text(service),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedService = service),
                    backgroundColor: Colors.white,
                    selectedColor: Colors.orange.shade100,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.orange.shade800 : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Date Selection
              Text(
                'When do you need the service?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select a date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Text(
                        _selectedDate == null ? 'Choose Date' : 'Change',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Find Providers Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedService != null &&
                          _selectedDate != null &&
                          _selectedPetIds.isNotEmpty
                      ? () {
                          setState(() => _showPreFilter = false);
                          _queryProviders();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Find Providers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('Finding Providers'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Searching for providers...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show pre-filter screen first
    if (_showPreFilter) {
      return _buildPreFilterScreen();
    }

    // Show map with filtered providers
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Providers'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _showPreFilter = true);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Provider count indicator
                if (_providers.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.green.shade50,
                    child: Text(
                      '${_providers.length} provider${_providers.length == 1 ? '' : 's'} found nearby',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Stack(
                  children: [
                    SizedBox(
                      height: 300,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null
                              ? LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude)
                              : const LatLng(0, 0),
                          zoom: 12,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                      ),
                    ),
                    // Focus on providers button
                    if (_providers.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FloatingActionButton.small(
                          onPressed: _focusOnProviders,
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.center_focus_strong),
                        ),
                      ),
                  ],
                ),
                if (_noResultsMsg != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_noResultsMsg!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                // Vertical list of provider cards
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    itemCount: _providers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = _providers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final pos = data['location'];
                      final double lat = (pos['lat'] as num).toDouble();
                      final double lng = (pos['lng'] as num).toDouble();
                      final double distance = Geolocator.distanceBetween(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            lat,
                            lng,
                          ) /
                          1000.0;
                      return _buildProviderCard(doc, distance);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class BookingForm extends StatefulWidget {
  final String providerId;
  final String providerName;
  final List<String> services;
  final List<String> availableDates;
  final String userId;
  final String userName;

  const BookingForm({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.services,
    required this.availableDates,
    required this.userId,
    required this.userName,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  List<String> _selectedPetIds = []; // Changed to support multiple pets
  String? _selectedService;
  String? _selectedDate;
  String? _selectedTime;
  String? _notes;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pets = [];

  // Add a field to hold provider rates
  Map<String, dynamic>? _providerRates;

  // Time slots available for booking
  final List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
    '09:00 PM'
  ];

  // Get available time slots based on selected date and provider availability
  List<String> _getAvailableTimeSlots() {
    // For now, return all time slots
    // In the future, this could be filtered based on provider's actual availability
    return _timeSlots;
  }

  @override
  void initState() {
    super.initState();
    _fetchPets();

    // Auto-select service if only one is available
    if (widget.services.length == 1) {
      _selectedService = widget.services.first;
    }
    // Fetch provider rates from Firestore
    _fetchProviderRates();
  }

  Future<void> _fetchPets() async {
    setState(() => _isLoading = true);
    try {
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('pets')
          .get();
      setState(() {
        _pets = petsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Ensure the document ID is included
          return data;
        }).toList();
        _isLoading = false;
      });
      print(
          'Loaded ${_pets.length} pets: ${_pets.map((p) => '${p['name']} (${p['id']})').toList()}');
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading pets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pets: $e')),
      );
    }
  }

  Future<void> _fetchProviderRates() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .get();
      if (doc.exists) {
        setState(() {
          _providerRates = (doc.data() ?? {})['rates'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error fetching provider rates: $e');
    }
  }

  Future<void> _submitBooking() async {
    print('=== FIREBASE PERMISSION TEST ===');

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing Firebase permissions...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Validate inputs
    if (_selectedPetIds.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      print('Validation failed - missing required fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select at least one pet, service, date, and time.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, check user's role
      print('Checking user role...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String?;
      print('User role: $userRole');

      // Fix lowercase role issue
      if (userRole == 'user') {
        print('Fixing lowercase role...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'role': 'User'});
        print('Role updated to "User"');
      } else if (userRole != 'User') {
        throw Exception('User role is "$userRole" but needs to be "User"');
      }

      print('User role is correct: User');

      print('Finding selected pets...');
      final selectedPets =
          _pets.where((p) => _selectedPetIds.contains(p['id'])).toList();
      print('Selected pets: ${selectedPets.map((p) => p['name']).join(', ')}');

      print('Creating booking data...');

      // Get user's name from Firestore
      final userDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final userName = userDataDoc.data()?['name'] ?? 'Customer';

      // Create booking data with multiple pets
      final petIds = selectedPets.map((p) => p['id']).toList();
      final petNames = selectedPets.map((p) => p['name']).toList();

      final bookingData = {
        'providerId': widget.providerId,
        'providerName': widget.providerName,
        'userId': widget.userId,
        'userName': userName,
        'petIds': petIds, // Array of pet IDs
        'petNames': petNames, // Array of pet names
        'petCount': selectedPets.length, // Number of pets
        // Keep legacy fields for backward compatibility
        'petId': petIds.isNotEmpty ? petIds.first : '',
        'petName': petNames.isNotEmpty ? petNames.first : '',
        'service': _selectedService,
        'date': _selectedDate,
        'time': _selectedTime,
        'notes': _notes ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };
      print('Booking data: $bookingData');

      print('Saving to Firestore...');
      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);
      print('Booking saved with ID: ${docRef.id}');

      // Show success page instead of snackbar
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet first

        // Show success page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessPage(
              bookingId: docRef.id,
              providerId: widget.providerId,
              providerName: widget.providerName,
              service: _selectedService!,
              date: _selectedDate!,
              time: _selectedTime!,
              petName:
                  petNames.isNotEmpty ? petNames.join(', ') : 'Multiple Pets',
            ),
          ),
        );
      }

      print('Booking completed successfully');
    } catch (e) {
      print('Error during Firebase booking: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase booking failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 8),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasDates = widget.availableDates.isNotEmpty;

    // Debug information to help identify the issue
    print('=== BOOKING FORM DEBUG ===');
    print('hasDates: $hasDates');
    print('availableDates count: ${widget.availableDates.length}');
    print('availableDates: ${widget.availableDates}');
    print('_selectedDate: $_selectedDate');
    print('_selectedPetIds: $_selectedPetIds');
    print('_selectedService: $_selectedService');
    print('_isLoading: $_isLoading');
    print('_pets count: ${_pets.length}');
    print('Button disabled conditions:');
    print('  - _isLoading: $_isLoading');
    print('  - !hasDates: ${!hasDates}');
    print('  - _selectedDate == null: ${_selectedDate == null}');
    print(
        'Button will be disabled: ${_isLoading || !hasDates || _selectedDate == null}');
    print('========================');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Book a Service',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  // Show rates for the selected service
                  if (_selectedService != null &&
                      _providerRates != null &&
                      _providerRates![_selectedService] != null) ...[
                    Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rates for $_selectedService',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(
                                'Per Hour: RM 0${_providerRates![_selectedService]['per_hour'] ?? '-'}'),
                            Text(
                                'Per Visit: RM 0${_providerRates![_selectedService]['per_visit'] ?? '-'}'),
                            Text(
                                'Per Day: RM 0${_providerRates![_selectedService]['per_day'] ?? '-'}'),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Pet selection (multi-select)
                  const Text('Select Pets',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _pets.map((pet) {
                        final petId = pet['id']?.toString() ?? '';
                        final isSelected = _selectedPetIds.contains(petId);
                        return CheckboxListTile(
                          title: Text('${pet['name']} (${pet['type']})'),
                          subtitle:
                              pet['breed'] != null && pet['breed'].isNotEmpty
                                  ? Text('${pet['breed']}')
                                  : null,
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPetIds.add(petId);
                              } else {
                                _selectedPetIds.remove(petId);
                              }
                            });
                            print('Selected pets: $_selectedPetIds');
                          },
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedPetIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_selectedPetIds.length} pet${_selectedPetIds.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Service selection
                  const Text('Select Service',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: widget.services
                        .map((service) => ChoiceChip(
                              label: Text(service),
                              selected: _selectedService == service,
                              onSelected: (selected) {
                                print(
                                    'Service selected: $service, selected: $selected');
                                if (selected) {
                                  setState(() => _selectedService = service);
                                } else {
                                  setState(() => _selectedService = null);
                                }
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Date selection
                  const Text('Select Date',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  if (!hasDates)
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'No available dates for this provider.',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  DropdownButtonFormField<String>(
                    value: _selectedDate,
                    items: widget.availableDates
                        .map((date) => DropdownMenuItem<String>(
                              value: date.toString(),
                              child: Text(date),
                            ))
                        .toList(),
                    onChanged: hasDates
                        ? (val) {
                            print('Date selected: $val');
                            setState(() => _selectedDate = val);
                          }
                        : null,
                    decoration:
                        const InputDecoration(hintText: 'Choose a date'),
                    disabledHint: const Text('No dates available'),
                  ),
                  const SizedBox(height: 16),
                  // Time selection
                  const Text('Select Time',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _getAvailableTimeSlots().length,
                      itemBuilder: (context, index) {
                        final timeSlot = _getAvailableTimeSlots()[index];
                        final isSelected = _selectedTime == timeSlot;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTime = isSelected ? null : timeSlot;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.orange : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                timeSlot,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  const Text('Notes (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextFormField(
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (val) => _notes = val,
                    decoration: const InputDecoration(
                        hintText: 'Add any notes for the provider'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ||
                              !hasDates ||
                              _selectedDate == null ||
                              _selectedTime == null
                          ? null
                          : () {
                              print('=== BUTTON CLICKED ===');
                              print('Button conditions:');
                              print('  - _isLoading: $_isLoading');
                              print('  - !hasDates: ${!hasDates}');
                              print(
                                  '  - _selectedDate == null: ${_selectedDate == null}');
                              print(
                                  '  - Button should be enabled: ${!(_isLoading || !hasDates || _selectedDate == null)}');

                              // Show immediate feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Button clicked! Starting booking...'),
                                  duration: Duration(seconds: 1),
                                  backgroundColor: Colors.orange,
                                ),
                              );

                              _submitBooking();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )
                          : Text('Confirm Booking',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class BookingSuccessPage extends StatelessWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final String service;
  final String date;
  final String time;
  final String petName;

  const BookingSuccessPage({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.date,
    required this.time,
    required this.petName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Your Appointment is Pending'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Pending Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  size: 80,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Pending Title
              Text(
                'Your Appointment is Pending',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Pending Message
              Text(
                '$providerName will notify you once they confirm your booking.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Booking ID
                    _buildDetailRow('Booking ID', bookingId),
                    const SizedBox(height: 8),

                    // Provider
                    _buildDetailRow('Provider', providerName),
                    const SizedBox(height: 8),

                    // Service
                    _buildDetailRow('Service', service),
                    const SizedBox(height: 8),

                    // Date
                    _buildDetailRow('Date', date),
                    const SizedBox(height: 8),

                    // Time
                    _buildDetailRow('Time', time),
                    const SizedBox(height: 8),

                    // Pet
                    _buildDetailRow('Pet', petName),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewBookingsScreen(),
                          ),
                          (route) => false, // Clear all previous routes
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Bookings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Start chat with provider
                        final messagingService = MessagingService();
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final chatRoomId =
                              await messagingService.createOrGetChatRoom(
                            user.uid,
                            providerId,
                            bookingId: bookingId,
                          );

                          if (context.mounted) {
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
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProviderMapScreen(),
                      ),
                      (route) => false, // Clear all previous routes
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.deepOrange),
                  ),
                  child: Text(
                    'Find More Providers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
