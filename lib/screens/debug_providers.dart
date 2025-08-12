import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugProviders extends StatefulWidget {
  const DebugProviders({super.key});

  @override
  State<DebugProviders> createState() => _DebugProvidersState();
}

class _DebugProvidersState extends State<DebugProviders> {
  List<DocumentSnapshot> _providers = [];
  List<DocumentSnapshot> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load from providers collection
      final providersSnapshot =
          await FirebaseFirestore.instance.collection('providers').get();

      // Load from users collection
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isPetSitter', isEqualTo: true)
          .get();

      setState(() {
        _providers = providersSnapshot.docs;
        _users = usersSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Provider Data'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Providers Collection (${_providers.length} docs)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._providers
                      .map((doc) => _buildProviderCard(doc, 'providers')),
                  const SizedBox(height: 24),
                  Text(
                    'Users Collection - Pet Sitters (${_users.length} docs)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._users.map((doc) => _buildProviderCard(doc, 'users')),
                ],
              ),
            ),
    );
  }

  Widget _buildProviderCard(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>?;
    final services = data['services'] as List?;
    final petTypes = data['petTypes'] ?? data['preferredPetTypes'] as List?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        collection == 'providers' ? Colors.blue : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    collection.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: ${doc.id}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Name: ${data['name'] ?? 'No name'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (location != null) ...[
              const SizedBox(height: 4),
              Text(
                'Location: ${location['lat']?.toStringAsFixed(4)}, ${location['lng']?.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (services != null && services.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Services: ${services.join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (petTypes != null && petTypes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Pet Types: ${petTypes.join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'isPetSitter: ${data['isPetSitter'] ?? 'Not set'}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'role: ${data['role'] ?? 'Not set'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
