import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import 'package:geolocator/geolocator.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userProfile.name ?? '');
    _phoneController =
        TextEditingController(text: widget.userProfile.phoneNumber ?? '');
    _emailController =
        TextEditingController(text: widget.userProfile.email ?? '');
    _dobController =
        TextEditingController(text: widget.userProfile.birthday ?? '');
    _profileImageUrl = widget.userProfile.profilePicUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
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

  Future<String?> _uploadProfileImage(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      // You may want to use Firebase Storage for real image uploads
      // For now, just return null (placeholder)
      // TODO: Implement Firebase Storage upload and return URL
      return null;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
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
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        // TODO: Upload to Firebase Storage and get URL
        imageUrl = await _uploadProfileImage(_profileImage!);
      }
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'birthday': _dobController.text,
        'profilePicUrl': imageUrl ?? '',
      };
      // If provider, update location
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['role'] == 'provider' || userData['isPetSitter'] == true) {
          Position? position = await _getCurrentLocation();
          if (position != null) {
            updateData['location'] = {
              'lat': position.latitude,
              'lng': position.longitude,
            };
          }
        }
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 80),
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null) as ImageProvider<Object>?,
                          child:
                              _profileImage == null && _profileImageUrl == null
                                  ? const Icon(Icons.person, size: 44)
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _pickProfileImage,
                        child: const Text('Change Photo',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFF7F8FA),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Name',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        _buildCardField(_nameController, 'Name'),
                        const SizedBox(height: 16),
                        const Text('Phone Number',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        _buildCardField(_phoneController, 'Phone Number',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        const Text('Email',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        _buildCardField(_emailController, 'Email',
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        const Text('Date of Birth',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        _buildCardField(
                          _dobController,
                          'Date of Birth',
                          readOnly: true,
                          onTap: () async {
                            FocusScope.of(context).requestFocus(FocusNode());
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _dobController.text.isNotEmpty
                                  ? DateTime.tryParse(_dobController.text) ??
                                      DateTime(2000, 1, 1)
                                  : DateTime(2000, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              _dobController.text =
                                  picked.toIso8601String().substring(0, 10);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField(TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $hint';
            }
            return null;
          },
        ),
      ),
    );
  }
}
