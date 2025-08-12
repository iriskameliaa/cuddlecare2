import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import 'edit_profile_screen.dart';
import 'manage_availability_screen.dart';
import 'view_bookings_screen.dart';
import 'manage_services_screen.dart';
import 'admin_location_setter.dart';
import 'enhanced_provider_setup_screen.dart';
import 'balanced_provider_setup_screen.dart';
import 'admin_verification_dashboard.dart';
import 'provider_reviews_screen.dart';
import 'login_screen.dart';
import '../services/review_service.dart';
import 'package:geolocator/geolocator.dart';

class PetSitterProfileScreen extends StatefulWidget {
  const PetSitterProfileScreen({super.key});

  @override
  State<PetSitterProfileScreen> createState() => _PetSitterProfileScreenState();
}

class _PetSitterProfileScreenState extends State<PetSitterProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userProfile = UserProfile.fromMap(doc.data()!);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile_image.jpg');

      final uploadTask = await ref.putFile(_profileImage!);
      final url = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profilePicUrl': url});

      await _loadUserProfile();
    } catch (e) {
      print('Error uploading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<bool> _showDeleteAccountDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await _showDeleteAccountDialog();

    if (shouldDelete) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete user data from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // Delete the user account
          await user.delete();

          if (mounted) {
            // Navigate to login screen and show success message
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );

            // Show success message after navigation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        }
      } catch (e) {
        print('Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showServicesDialog() async {
    if (_userProfile?.services == null || _userProfile!.services!.isEmpty)
      return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('My Services'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _userProfile!.services!.map((service) {
                IconData serviceIcon;
                switch (service) {
                  case 'Pet Sitting':
                    serviceIcon = Icons.home;
                    break;
                  case 'Pet Grooming':
                    serviceIcon = Icons.content_cut;
                    break;
                  case 'Pet Walking':
                    serviceIcon = Icons.directions_walk;
                    break;
                  case 'Pet Health Checkups':
                    serviceIcon = Icons.medical_services;
                    break;
                  default:
                    serviceIcon = Icons.pets;
                }
                return Chip(
                  avatar: Icon(serviceIcon, size: 18, color: Colors.orange),
                  label: Text(service),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('Profile not found')),
      );
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    userProfile: _userProfile!,
                  ),
                ),
              ).then((updated) {
                if (updated == true) {
                  _loadUserProfile();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          // Hidden admin feature - long press to access location setter
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLocationSetter(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _userProfile!.profilePicUrl != null
                              ? NetworkImage(_userProfile!.profilePicUrl!)
                              : null,
                          child: _userProfile!.profilePicUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userProfile!.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _userProfile!.bio!,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),

            // Main Content
            Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manage Services (always show for providers)
                  _buildMenuCard(
                    icon: Icons.work,
                    text: 'Manage Services',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageServicesScreen(),
                        ),
                      ).then((updated) {
                        if (updated == true) _loadUserProfile();
                      });
                    },
                  ),

                  // My Reviews & Ratings
                  _buildMenuCard(
                    icon: Icons.star,
                    text: 'My Reviews & Ratings',
                    onTap: () {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderReviewsScreen(
                              providerId: currentUser.uid,
                              providerName: _userProfile?.name ?? 'You',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  // Balanced Provider Setup
                  _buildMenuCard(
                    icon: Icons.verified_user,
                    text: 'Setup & Reliability Verification',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BalancedProviderSetupScreen(),
                        ),
                      ).then((updated) {
                        if (updated == true) _loadUserProfile();
                      });
                    },
                  ),

                  // Pet Types Section
                  if (_userProfile!.preferredPetTypes != null &&
                      _userProfile!.preferredPetTypes!.isNotEmpty)
                    _buildSection(
                      'Accepted Pet Types',
                      Icons.pets,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _userProfile!.preferredPetTypes!.map((petType) {
                          return Chip(
                            label: Text(petType),
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Availability Section
                  _buildSection(
                    'Availability',
                    Icons.calendar_today,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage your working hours and availability',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageAvailabilityScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_calendar),
                          label: const Text('Manage Availability'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMenuCard(
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Delete Account Section
            Center(
              child: GestureDetector(
                onTap: _deleteAccount,
                child: const Text(
                  'Delete My Account',
                  style: TextStyle(
                    color: Colors.red,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.orange),
          title:
              Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          onTap: onTap,
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.black38),
        ),
      ),
    );
  }
}
