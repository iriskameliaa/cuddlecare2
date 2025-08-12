import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_profile.dart';
import '../models/provider_verification.dart';
import '../services/verification_service.dart';

class EnhancedProviderSetupScreen extends StatefulWidget {
  const EnhancedProviderSetupScreen({super.key});

  @override
  State<EnhancedProviderSetupScreen> createState() =>
      _EnhancedProviderSetupScreenState();
}

class _EnhancedProviderSetupScreenState
    extends State<EnhancedProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _rateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _profileImage;
  List<File> _certificates = [];
  List<File> _identityDocuments = [];
  String? _profileImageUrl;
  List<String> _certificateUrls = [];
  List<String> _identityDocumentUrls = [];

  String _selectedExperience = 'Beginner';
  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Expert'];

  final List<String> _services = [
    'Pet Sitting',
    'Pet Grooming',
    'Pet Walking',
    'Pet Health Checkups'
  ];
  final List<String> _selectedServices = [];

  final List<String> _petTypes = [
    'Dog',
    'Cat',
    'Rabbit',
    'Bird',
    'Fish',
    'Reptile',
    'Other'
  ];
  final List<String> _selectedPetTypes = [];

  bool _isLoading = false;
  bool _agreedToBackgroundCheck = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacyPolicy = false;

  final VerificationService _verificationService = VerificationService();

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
          _locationController.text = data['location'] ?? '';
          _rateController.text = (data['rate']?.toString()) ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
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

  Future<void> _pickCertificates() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _certificates.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  Future<void> _pickIdentityDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _identityDocuments.addAll(result.files.map((file) => File(file.path!)));
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
    if (!_agreedToTerms || !_agreedToPrivacyPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to terms and privacy policy')),
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

      // Upload certificates
      _certificateUrls = [];
      for (var i = 0; i < _certificates.length; i++) {
        final url = await _uploadFile(
          _certificates[i],
          'users/${user.uid}/certificates/certificate_$i',
        );
        _certificateUrls.add(url);
      }

      // Upload identity documents
      List<String> identityUrls = [];
      for (var i = 0; i < _identityDocuments.length; i++) {
        final url = await _uploadFile(
          _identityDocuments[i],
          'users/${user.uid}/identity/identity_$i',
        );
        identityUrls.add(url);
      }

      // Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'experience': _selectedExperience,
        'services': _selectedServices,
        'petTypes': _selectedPetTypes,
        'profilePicUrl': _profileImageUrl,
        'certificateUrls': _certificateUrls,
        'identityDocumentUrls': identityUrls,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also save to providers collection
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
        'name': _nameController.text,
        'bio': _bioController.text,
        'location': _locationController.text,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'experience': _selectedExperience,
        'services': _selectedServices,
        'petTypes': _selectedPetTypes,
        'profilePicUrl': _profileImageUrl,
        'certificateUrls': _certificateUrls,
        'identityDocumentUrls': identityUrls,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'isPetSitter': true,
        'role': 'provider',
        'setupCompleted': true,
        'setupCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Initialize verification process
      await _verificationService.initializeVerification(user.uid);

      // Request background check if agreed
      if (_agreedToBackgroundCheck) {
        await _verificationService.requestBackgroundCheck(user.uid);
      }

      // Add certificates for verification
      for (final certificateUrl in _certificateUrls) {
        await _verificationService.addCertificate(user.uid, certificateUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile saved successfully! Verification process started.'),
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
        title: const Text('Enhanced Provider Setup'),
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trust & Verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete verification to build trust with pet owners',
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

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),

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
                maxLines: 2,
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
                  labelText: 'Bio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Services & Experience
              _buildSectionTitle('Services & Experience'),
              const SizedBox(height: 16),

              // Experience Level
              DropdownButtonFormField<String>(
                value: _selectedExperience,
                decoration: const InputDecoration(
                  labelText: 'Experience Level *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExperience = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Services
              _buildRoundedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Services Offered *',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _services.map((service) {
                        return FilterChip(
                          label: Text(service),
                          selected: _selectedServices.contains(service),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pet Types
              _buildRoundedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pet Types You Handle *',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _petTypes.map((petType) {
                        return FilterChip(
                          label: Text(petType),
                          selected: _selectedPetTypes.contains(petType),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPetTypes.add(petType);
                              } else {
                                _selectedPetTypes.remove(petType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rate
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (RM) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your hourly rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Verification Documents
              _buildSectionTitle('Verification Documents'),
              const SizedBox(height: 16),

              // Certificates
              _buildRoundedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Text('Certificates & Training',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload pet care certificates, training documents, or professional qualifications',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickCertificates,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Certificates'),
                    ),
                    if (_certificates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Selected: ${_certificates.length} files'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Identity Documents
              _buildRoundedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.badge, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('Identity Verification',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload government ID, passport, or other identity documents for verification',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickIdentityDocuments,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload ID Documents'),
                    ),
                    if (_identityDocuments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Selected: ${_identityDocuments.length} files'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Background Check
              _buildSectionTitle('Background Check'),
              const SizedBox(height: 16),

              _buildRoundedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        const Text('Background Check',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We conduct background checks to ensure the safety of pets and their owners',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

              // Terms & Conditions
              _buildSectionTitle('Terms & Conditions'),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text('I agree to the Terms of Service'),
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('I agree to the Privacy Policy'),
                value: _agreedToPrivacyPolicy,
                onChanged: (value) {
                  setState(() {
                    _agreedToPrivacyPolicy = value ?? false;
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
                      : const Text('Complete Setup & Start Verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRoundedField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
