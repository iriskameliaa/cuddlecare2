import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/telegram_bot_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildMenuCard(
            icon: Icons.telegram,
            text: 'Telegram Bot Integration',
            subtitle: _userProfile?.telegramChatId != null &&
                    _userProfile!.telegramChatId!.isNotEmpty
                ? 'Connected'
                : 'Not connected',
            onTap: () {
              _showTelegramIntegration();
            },
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildMenuCard(
            icon: Icons.notifications,
            text: 'Push Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Implement push notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Push notification settings coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.language,
            text: 'Language',
            subtitle: 'English',
            onTap: () {
              // TODO: Implement language settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language settings coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.dark_mode,
            text: 'Dark Mode',
            subtitle: 'Light',
            onTap: () {
              // TODO: Implement dark mode toggle
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark mode coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader('Privacy & Security'),
          _buildMenuCard(
            icon: Icons.security,
            text: 'Privacy Policy',
            onTap: () {
              // TODO: Show privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy policy coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          _buildMenuCard(
            icon: Icons.description,
            text: 'Terms of Service',
            onTap: () {
              // TODO: Show terms of service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of service coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildMenuCard(
            icon: Icons.info,
            text: 'App Version',
            subtitle: '1.0.0',
            onTap: null, // No action needed
          ),
          _buildMenuCard(
            icon: Icons.help,
            text: 'Help & Support',
            onTap: () {
              // TODO: Show help and support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help and support coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String text,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.orange),
          title:
              Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onTap: onTap,
          trailing: onTap != null
              ? const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black38)
              : null,
        ),
      ),
    );
  }

  void _showTelegramIntegration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telegram Bot Integration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect your Telegram account to receive booking notifications and updates.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Booking confirmations'),
            const Text('• Service reminders'),
            const Text('• Status updates'),
            const Text('• Weather alerts'),
            const Text('• Pet care tips'),
            const SizedBox(height: 16),
            const Text(
              'To connect:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Open Telegram'),
            const Text('2. Search for @CuddleCare_app1_bot'),
            const Text('3. Send /start to the bot'),
            const Text('4. Copy your chat ID from the bot'),
            const Text('5. Enter it below'),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(
                text: _userProfile?.telegramChatId ?? '',
              ),
              decoration: const InputDecoration(
                labelText: 'Telegram Chat ID',
                hintText: 'e.g., 123456789',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateTelegramChatId(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _testTelegramConnection();
            },
            child: const Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTelegramChatId(String chatId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'telegramChatId': chatId});

        // Reload user profile
        await _loadUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telegram Chat ID updated: $chatId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating Telegram Chat ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testTelegramConnection() async {
    try {
      if (_userProfile?.telegramChatId == null ||
          _userProfile!.telegramChatId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your Telegram Chat ID first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final success = await TelegramBotService.sendNotification(
        chatId: _userProfile!.telegramChatId!,
        message: '''
🤖 <b>Connection Test Successful!</b>

Hello ${_userProfile!.name}! Your Telegram account is now connected to CuddleCare.

<b>What you'll receive:</b>
✅ Booking confirmations
✅ Service reminders  
✅ Status updates
✅ Weather alerts
✅ Pet care tips

<b>Try these commands:</b>
/mybookings - View your bookings
/mypets - View your pets
/weather - Check weather
/recommend - Get recommendations

Welcome to CuddleCare! 🐾
''',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test successful! Check your Telegram.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection test failed. Check your Chat ID.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing connection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
