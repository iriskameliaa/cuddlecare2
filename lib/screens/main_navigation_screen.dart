import 'package:flutter/material.dart';
import 'package:cuddlecare2/screens/home_screen.dart';
import 'package:cuddlecare2/screens/profile_screen.dart';
import 'package:cuddlecare2/screens/provider_map_screen.dart';
import 'package:cuddlecare2/screens/chat_list_screen.dart';
import 'package:cuddlecare2/screens/admin_tools_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuddlecare2/screens/login_screen.dart';
import 'package:cuddlecare2/services/messaging_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final MessagingService _messagingService = MessagingService();
  bool _isAdmin = false;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ProviderMapScreen(),
    ChatListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print('🔍 Checking admin status for user: ${user.email} (${user.uid})');
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final isAdmin = data['isAdmin'] == true || data['role'] == 'admin';
          print('📊 User data: $data');
          print('🔑 Admin status: $isAdmin');
          setState(() {
            _isAdmin = isAdmin;
          });
        } else {
          print('❌ User document does not exist');
        }
      } catch (e) {
        print('Error checking admin status: $e');
      }
    } else {
      print('❌ No current user found');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevents back button
        title: Row(
          children: const [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Icon(Icons.pets, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'CUDDLECARE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              onPressed: () {
                print('🔧 Admin Tools button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminToolsScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Tools',
            ),
          ] else
            // Debug: Show what _isAdmin value is
            Builder(
              builder: (context) {
                print('🚫 Admin button hidden - _isAdmin: $_isAdmin');
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: _buildMessagesIconWithBadge(),
            label: 'Messages',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildMessagesIconWithBadge() {
    return StreamBuilder<int>(
      stream: _messagingService.getTotalUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.message),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
