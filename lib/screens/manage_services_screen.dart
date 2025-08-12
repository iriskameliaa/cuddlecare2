import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  List<String> _selectedServices = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentServices();
  }

  Future<void> _loadCurrentServices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final currentServices = List<String>.from(data['services'] ?? []);
          // Filter out any services that are no longer available
          final validServices = currentServices
              .where(
                  (service) => UserProfile.availableServices.contains(service))
              .toList();
          setState(() {
            _selectedServices = validServices;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveServices() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Only save services that are in the available services list
        final validServices = _selectedServices
            .where((service) => UserProfile.availableServices.contains(service))
            .toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'services': validServices,
        });

        // Also update providers collection if it exists
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .update({
          'services': validServices,
        }).catchError((e) {
          // Ignore error if provider document doesn't exist
          print('Provider document not found (this is normal): $e');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Services updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text('Manage Services',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveServices,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the services you want to offer to pet owners',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: UserProfile.availableServices.length,
                    itemBuilder: (context, index) {
                      final service = UserProfile.availableServices[index];
                      final isSelected = _selectedServices.contains(service);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getServiceIcon(service),
                              color:
                                  isSelected ? Colors.orange : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          title: Text(
                            service,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.orange : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            _getServiceDescription(service),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) => _toggleService(service),
                            activeColor: Colors.orange,
                          ),
                          onTap: () => _toggleService(service),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedServices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Services (${_selectedServices.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedServices.map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getServiceIcon(service),
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    service,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'Pet Sitting':
        return Icons.house_siding;
      case 'Pet Grooming':
        return Icons.content_cut;
      case 'Pet Walking':
        return Icons.pets;
      case 'Pet Health Checkups':
        return Icons.local_hospital;
      default:
        return Icons.work;
    }
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'Pet Sitting':
        return 'Care for pets in their own home';
      case 'Pet Grooming':
        return 'Bathing, trimming, and styling services';
      case 'Pet Walking':
        return 'Regular exercise and outdoor activities';
      case 'Pet Health Checkups':
        return 'Basic health monitoring and care';
      default:
        return 'Professional pet care service';
    }
  }
}
