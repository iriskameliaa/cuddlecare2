import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import 'edit_profile_screen.dart';
import 'package:cuddlecare2/screens/manage_pets_screen.dart';
import 'package:cuddlecare2/screens/view_bookings_screen.dart';
import 'package:cuddlecare2/screens/manage_services_screen.dart';
import 'package:cuddlecare2/screens/settings_screen.dart';
import 'package:cuddlecare2/screens/login_screen.dart';
import '../services/telegram_bot_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
          final data = doc.data()!;
          print('User data: $data'); // Debug: Print user data
          setState(() {
            _userProfile = UserProfile.fromMap(data);
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } catch (e) {
      print('Error signing out: $e');
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
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _userProfile!.profilePicUrl != null
                          ? NetworkImage(_userProfile!.profilePicUrl!)
                          : null,
                      child: _userProfile!.profilePicUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
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
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _userProfile!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userProfile!.phoneNumber != null)
                  Text(
                    _userProfile!.phoneNumber!,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              color: const Color(0xFFF7F8FA),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                children: [
                  _buildMenuCard(
                    icon: Icons.person,
                    text: 'My Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(userProfile: _userProfile!),
                        ),
                      ).then((updated) {
                        if (updated == true) _loadUserProfile();
                      });
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.emoji_nature,
                    text: 'My Pets',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManagePetsScreen(),
                        ),
                      );
                    },
                  ),
                  // Show services management only for providers
                  if (_userProfile!.isPetSitter ||
                      (_userProfile!.services != null &&
                          _userProfile!.services!.isNotEmpty))
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

                  _buildMenuCard(
                    icon: Icons.settings,
                    text: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ),
          // Delete Account Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _deleteAccount,
                child: Text(
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
          ),
        ],
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
