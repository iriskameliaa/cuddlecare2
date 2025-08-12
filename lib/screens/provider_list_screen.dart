import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';

class ProviderListScreen extends StatefulWidget {
  final String selectedService;

  const ProviderListScreen({
    super.key,
    required this.selectedService,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  Position? _currentUserPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      // Optionally, show a dialog to ask the user to enable location services
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        // Optionally, show a dialog explaining why location is needed
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      // Optionally, show a dialog with instructions to enable permission from settings
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentUserPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // Handle error, e.g., show a snackbar
    }
  }

  double? _calculateDistance(GeoPoint providerLocation) {
    if (_currentUserPosition == null) return null;
    return Geolocator.distanceBetween(
          _currentUserPosition!.latitude,
          _currentUserPosition!.longitude,
          providerLocation.latitude,
          providerLocation.longitude,
        ) /
        1000; // Convert to kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedService} Providers'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Fetching your location...'),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isPetSitter', isEqualTo: true)
                  .where('services', arrayContains: widget.selectedService)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final providers = snapshot.data?.docs ?? [];

                if (providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No providers found for ${widget.selectedService}',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final providerData =
                        providers[index].data() as Map<String, dynamic>;
                    final provider = UserProfile.fromMap(providerData);
                    final distance = provider.geoPointLocation != null
                        ? _calculateDistance(provider.geoPointLocation!)
                        : null;

                    return _buildProviderCard(provider, distance);
                  },
                );
              },
            ),
    );
  }

  Widget _buildProviderCard(UserProfile provider, double? distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (provider.profilePicUrl != null &&
                          provider.profilePicUrl!.isNotEmpty)
                      ? Image.network(
                          provider.profilePicUrl!,
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback for failed network image loads
                            return Image.asset(
                              'assets/images/placeholder.png',
                              width: 100,
                              height: 140,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/placeholder.png', // Local placeholder
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Colors.black54, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.name} Pet sitting',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Name: ${provider.name}'),
                  const SizedBox(height: 4),
                  Text(
                    provider.bio ?? 'Your pets are in great hands.',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Text('Location: ${provider.location ?? 'Not specified'}'),
                  if (distance != null)
                    Text('Distance: ${distance.toStringAsFixed(1)} km away'),
                  const SizedBox(height: 4),
                  if (provider.availability != null &&
                      provider.availability!.isNotEmpty) ...[
                    _buildAvailability(provider.availability!),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Text('Pet Type: '),
                      if (provider.preferredPetTypes?.contains('Dog') ?? false)
                        const Icon(Icons.pets, size: 16), // Dog icon
                      if (provider.preferredPetTypes?.contains('Cat') ?? false)
                        const Icon(Icons.pets, size: 16), // Cat icon for now
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ratings
                      Column(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (provider.rating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          const Text('Ratings', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '₹ ${provider.rates?['per_visit'] ?? 200}', // Example rate
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Per Visit',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      )
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

  Widget _buildAvailability(Map<String, dynamic> availability) {
    final availableDays = availability.entries
        .where((day) =>
            day.value is bool && day.value == true ||
            day.value is Map && day.value['available'] == true)
        .map((day) => day.key.substring(0, 3))
        .toList();

    if (availableDays.isEmpty) {
      return const Text(
        'Availability: Not specified',
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4.0,
          runSpacing: 4.0,
          children: availableDays
              .map(
                (day) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
