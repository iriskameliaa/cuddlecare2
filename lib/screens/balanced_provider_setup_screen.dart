import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';

class BalancedProviderSetupScreen extends StatefulWidget {
  const BalancedProviderSetupScreen({super.key});

  @override
  State<BalancedProviderSetupScreen> createState() =>
      _BalancedProviderSetupScreenState();
}

class _BalancedProviderSetupScreenState
    extends State<BalancedProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  File? _idDocument;
  String? _profileImageUrl;
  String? _idDocumentUrl;

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
  bool _agreedToBackgroundCheck = false;
  bool _hasPetCareExperience = false;
  bool _hasReferences = false;

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
          _addressController.text = data['address'] ?? '';
          _selectedExperience = data['experience'] ?? 'Beginner';
          _profileImageUrl = data['profilePicUrl'];
          _idDocumentUrl = data['idDocumentUrl'];
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

  Future<void> _pickIdDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _idDocument = File(result.files.first.path!);
      });
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  String _calculateReliabilityScore() {
    int score = 0;

    // Basic requirements (40 points)
    if (_nameController.text.isNotEmpty) score += 10;
    if (_phoneController.text.isNotEmpty) score += 10;
    if (_addressController.text.isNotEmpty) score += 10;
    if (_profileImage != null || _profileImageUrl != null) score += 10;

    // Experience and qualifications (30 points)
    if (_selectedExperience == 'Expert')
      score += 15;
    else if (_selectedExperience == 'Intermediate')
      score += 10;
    else
      score += 5;

    if (_hasPetCareExperience) score += 10;
    if (_hasReferences) score += 5;

    // Identity verification (20 points)
    if (_idDocument != null || _idDocumentUrl != null) score += 20;

    // Background check consent (10 points)
    if (_agreedToBackgroundCheck) score += 10;

    return score.toString();
  }

  String _getReliabilityLevel(int score) {
    if (score >= 90) return '🔒 Premium Trusted';
    if (score >= 75) return '✅ Highly Trusted';
    if (score >= 60) return '👍 Trusted';
    if (score >= 40) return '⚠️ Basic Trust';
    return '❓ New Provider';
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
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

    // Get location data - MANDATORY for providers
    Position? position = await _getCurrentLocation();
    if (position == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location access is required to complete setup. Please enable location services.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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

      // Upload ID document if selected
      if (_idDocument != null) {
        _idDocumentUrl = await _uploadFile(
          _idDocument!,
          'users/${user.uid}/id_document.pdf',
        );
      }

      final reliabilityScore = int.parse(_calculateReliabilityScore());
      final reliabilityLevel = _getReliabilityLevel(reliabilityScore);

      // Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'experience': _selectedExperience,
        'services': _selectedServices,
        'petTypes': _selectedPetTypes,
        'profilePicUrl': _profileImageUrl,
        'idDocumentUrl': _idDocumentUrl,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
        'reliabilityScore': reliabilityScore,
        'reliabilityLevel': reliabilityLevel,
        'hasPetCareExperience': _hasPetCareExperience,
        'hasReferences': _hasReferences,
        'backgroundCheckConsent': _agreedToBackgroundCheck,
        'verificationStatus': reliabilityScore >= 60 ? 'verified' : 'pending',
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
        'idDocumentUrl': _idDocumentUrl,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        },
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
        'reliabilityScore': reliabilityScore,
        'reliabilityLevel': reliabilityLevel,
        'hasPetCareExperience': _hasPetCareExperience,
        'hasReferences': _hasReferences,
        'backgroundCheckConsent': _agreedToBackgroundCheck,
        'verificationStatus': reliabilityScore >= 60 ? 'verified' : 'pending',
        'completedBookings': 0,
        'rating': 0.0,
        'reviewCount': 0,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Profile saved successfully! Your reliability level: $reliabilityLevel'),
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
    final reliabilityScore = int.parse(_calculateReliabilityScore());
    final reliabilityLevel = _getReliabilityLevel(reliabilityScore);

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
              // Reliability Score Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: reliabilityScore >= 75
                      ? Colors.green.shade50
                      : reliabilityScore >= 60
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: reliabilityScore >= 75
                        ? Colors.green.shade200
                        : reliabilityScore >= 60
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      reliabilityScore >= 75
                          ? Icons.verified
                          : reliabilityScore >= 60
                              ? Icons.warning
                              : Icons.info,
                      color: reliabilityScore >= 75
                          ? Colors.green.shade700
                          : reliabilityScore >= 60
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reliability Score: $reliabilityScore/100',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: reliabilityScore >= 75
                                  ? Colors.green.shade700
                                  : reliabilityScore >= 60
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                          Text(
                            reliabilityLevel,
                            style: TextStyle(
                              color: reliabilityScore >= 75
                                  ? Colors.green.shade600
                                  : reliabilityScore >= 60
                                      ? Colors.orange.shade600
                                      : Colors.red.shade600,
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

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
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

              // Identity Verification
              Text(
                'Identity Verification',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a government ID to increase your reliability score',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('Government ID',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a valid government ID (driver\'s license, passport, etc.)',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickIdDocument,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload ID Document'),
                    ),
                    if (_idDocument != null || _idDocumentUrl != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('ID Document uploaded',
                              style:
                                  TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Experience Level
              Text(
                'Experience & Qualifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedExperience,
                decoration: const InputDecoration(
                  labelText: 'Experience Level',
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
              const SizedBox(height: 16),

              // Experience checkboxes
              CheckboxListTile(
                title: const Text('I have previous pet care experience'),
                subtitle:
                    const Text('Professional or personal experience with pets'),
                value: _hasPetCareExperience,
                onChanged: (value) {
                  setState(() {
                    _hasPetCareExperience = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('I can provide references'),
                subtitle: const Text(
                    'Previous clients or employers who can vouch for me'),
                value: _hasReferences,
                onChanged: (value) {
                  setState(() {
                    _hasReferences = value ?? false;
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

              // Background Check Consent
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
                        Icon(Icons.security, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('Background Check',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We conduct background checks to ensure the safety of pets and their owners',
                      style:
                          TextStyle(color: Colors.blue.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title:
                          const Text('I agree to undergo a background check'),
                      subtitle:
                          const Text('This helps build trust with pet owners'),
                      value: _agreedToBackgroundCheck,
                      onChanged: (value) {
                        setState(() {
                          _agreedToBackgroundCheck = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
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

              // Reliability Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Building Reliability',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your reliability score increases with: ID verification, experience, references, and background check consent. Higher scores help you get more bookings!',
                      style: TextStyle(
                        color: Colors.green.shade600,
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
