import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'debug_providers.dart';

class AdminLocationSetter extends StatefulWidget {
  const AdminLocationSetter({super.key});

  @override
  State<AdminLocationSetter> createState() => _AdminLocationSetterState();
}

class _AdminLocationSetterState extends State<AdminLocationSetter> {
  List<DocumentSnapshot> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final List<DocumentSnapshot> allProviders = [];

      // Load from providers collection
      try {
        final providersSnapshot =
            await FirebaseFirestore.instance.collection('providers').get();
        allProviders.addAll(providersSnapshot.docs);
      } catch (e) {
        print('Error loading from providers collection: $e');
      }

      // Also load from users collection (for backward compatibility)
      try {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('isPetSitter', isEqualTo: true)
            .get();
        allProviders.addAll(usersSnapshot.docs);
      } catch (e) {
        print('Error loading from users collection: $e');
      }

      setState(() {
        _providers = allProviders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading providers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setProviderLocation(
      String providerId, double lat, double lng) async {
    try {
      // Try to update in providers collection first
      try {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .update({
          'location': {
            'lat': lat,
            'lng': lng,
          }
        });
      } catch (e) {
        print('Failed to update providers collection: $e');
      }

      // Also update in users collection (for backward compatibility)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .update({
          'location': {
            'lat': lat,
            'lng': lng,
          }
        });
      } catch (e) {
        print('Failed to update users collection: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated for provider $providerId'),
          backgroundColor: Colors.green,
        ),
      );

      _loadProviders(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationDialog(DocumentSnapshot provider) {
    final data = provider.data() as Map<String, dynamic>;
    final currentLocation = data['location'] as Map<String, dynamic>?;

    final latController = TextEditingController(
        text: currentLocation?['lat']?.toString() ?? '0.0');
    final lngController = TextEditingController(
        text: currentLocation?['lng']?.toString() ?? '0.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Location for ${data['name'] ?? 'Provider'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 3.1390',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 101.6869',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Set Options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    latController.text = '3.1390';
                    lngController.text = '101.6869';
                  },
                  child: const Text('Kuala Lumpur'),
                ),
                ElevatedButton(
                  onPressed: () {
                    latController.text = '3.1590';
                    lngController.text = '101.7069';
                  },
                  child: const Text('2km North'),
                ),
                ElevatedButton(
                  onPressed: () {
                    latController.text = '3.1190';
                    lngController.text = '101.6669';
                  },
                  child: const Text('2km South'),
                ),
                ElevatedButton(
                  onPressed: () {
                    latController.text = '3.1390';
                    lngController.text = '101.7269';
                  },
                  child: const Text('2km East'),
                ),
                ElevatedButton(
                  onPressed: () {
                    latController.text = '3.1390';
                    lngController.text = '101.6469';
                  },
                  child: const Text('2km West'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final lat = double.parse(latController.text);
                final lng = double.parse(lngController.text);
                _setProviderLocation(provider.id, lat, lng);
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid coordinates: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Set Provider Locations'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugProviders(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final provider = _providers[index];
                final data = provider.data() as Map<String, dynamic>;
                final location = data['location'] as Map<String, dynamic>?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(data['name']?[0] ?? 'P'),
                    ),
                    title: Text(data['name'] ?? 'Unknown Provider'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${provider.id}'),
                        if (location != null)
                          Text(
                            'Location: ${location['lat']?.toStringAsFixed(4)}, ${location['lng']?.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showLocationDialog(provider),
                      child: const Text('Set Location'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
