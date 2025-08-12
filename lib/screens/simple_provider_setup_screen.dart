import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';

class SimpleProviderSetupScreen extends StatefulWidget {
  const SimpleProviderSetupScreen({super.key});

  @override
  State<SimpleProviderSetupScreen> createState() =>
      _SimpleProviderSetupScreenState();
}

class _SimpleProviderSetupScreenState extends State<SimpleProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();

  File? _profileImage;
  String? _profileImageUrl;

  String _selectedExperience = 'Beginner';
  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Expert'];

  final List<String> _services = [
    'Pet Sitting',
    'Pet Walking',
    'Pet Grooming',
    'Pet Health Checkups'
  ];
  final List<String> _selectedServices = [];

  final List<String> _petTypes = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  final List<String> _selectedPetTypes = [];

  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _rateController.text = (data['rate']?.toString()) ?? '';
          _selectedExperience = data['experience'] ?? 'Beginner';
          _profileImageUrl = data['profilePicUrl'];
        });
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }
    if (_selectedPetTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pet type')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms of service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload profile image if selected
      if (_profileImage != null) {
        _profileImageUrl = await _uploadFile(
          _profileImage!,
          'users/${user.uid}/profile_image.jpg',
        );
      }

      // Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'experience': _selectedExperience,
        'services': _selectedServices,
        'petTypes': _selectedPetTypes,
        'profilePicUrl': _profileImageUrl,
        'phoneNumber': _phoneController.text,
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'basic', // Simple verification status
        'trustLevel': 'new', // Start with new provider trust level
      }, SetOptions(merge: true));

      // Also save to providers collection
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'experience': _selectedExperience,
        'services': _selectedServices,
        'petTypes': _selectedPetTypes,
        'profilePicUrl': _profileImageUrl,
        'phoneNumber': _phoneController.text,
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
        'verificationStatus': 'basic',
        'trustLevel': 'new',
        'completedBookings': 0,
        'rating': 0.0,
        'reviewCount': 0,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile saved successfully! You can now start accepting bookings.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Setup'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simple Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pets, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Your Pet Care Journey',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete your profile to start accepting bookings',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider?,
                      child: _profileImage == null && _profileImageUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickProfileImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'About You',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText:
                      'Tell pet owners about your experience and passion for pets...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Rate
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (USD)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Experience Level
              Text(
                'Experience Level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedExperience,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _experienceLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedExperience = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Services
              Text(
                'Services You Offer *',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all services you can provide:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((service) {
                  final isSelected = _selectedServices.contains(service);
                  return FilterChip(
                    label: Text(service),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add(service);
                        } else {
                          _selectedServices.remove(service);
                        }
                      });
                    },
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Pet Types
              Text(
                'Pet Types You Work With *',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all pet types you have experience with:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _petTypes.map((petType) {
                  final isSelected = _selectedPetTypes.contains(petType);
                  return FilterChip(
                    label: Text(petType),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPetTypes.add(petType);
                        } else {
                          _selectedPetTypes.remove(petType);
                        }
                      });
                    },
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Terms
              CheckboxListTile(
                title: const Text('I agree to the Terms of Service'),
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Setup & Start Accepting Bookings'),
                ),
              ),
              const SizedBox(height: 16),

              // Trust Building Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Building Trust',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trust level will increase as you complete bookings and receive positive reviews. You can add certificates and undergo background checks later to earn higher trust levels.',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
