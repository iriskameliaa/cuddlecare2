import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_profile.dart';

class PetSitterSetupScreen extends StatefulWidget {
  const PetSitterSetupScreen({super.key});

  @override
  State<PetSitterSetupScreen> createState() => _PetSitterSetupScreenState();
}

class _PetSitterSetupScreenState extends State<PetSitterSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _rateController = TextEditingController();

  File? _profileImage;
  List<File> _certificates = [];
  String? _profileImageUrl;
  List<String> _certificateUrls = [];

  String _selectedExperience = 'Beginner';
  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Expert'];

  final List<String> _services = [
    'Dog Walking',
    'Pet Sitting',
    'Feeding',
    'Grooming'
  ];
  final List<String> _selectedServices = [];

  final List<String> _petTypes = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  final List<String> _selectedPetTypes = [];

  bool _isLoading = false;

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

  Future<String> _uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

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
        'isPetSitter': true,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Sitter Profile Setup'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _pickProfileImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio/Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Hourly Rate
                    TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (RM)',
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
                    const SizedBox(height: 16),

                    // Experience Level
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
                        if (newValue != null) {
                          setState(() {
                            _selectedExperience = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Select Services
                    const Text(
                      'Select Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: UserProfile.availableServices.map((service) {
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
                          selectedColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Pet Types Accepted
                    const Text(
                      'Pet Types Accepted',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _petTypes.map((String type) {
                        return FilterChip(
                          label: Text(type),
                          selected: _selectedPetTypes.contains(type),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedPetTypes.add(type);
                              } else {
                                _selectedPetTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Certificates
                    ElevatedButton.icon(
                      onPressed: _pickCertificates,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Certificates'),
                    ),
                    if (_certificates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${_certificates.length} file(s) selected'),
                    ],
                    const SizedBox(height: 24),

                    // Manage Availability Button
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to availability management
                      },
                      icon: const Icon(Icons.access_time),
                      label: const Text('Manage Availability'),
                    ),
                    const SizedBox(height: 24),

                    // Save Profile Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
