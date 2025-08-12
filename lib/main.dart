import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/screens/welcome_screen.dart';
import 'package:cuddlecare2/screens/main_navigation_screen.dart';
import 'package:cuddlecare2/screens/admin_login_screen.dart';
import 'package:cuddlecare2/screens/bot_control_screen.dart';
import 'package:cuddlecare2/screens/login_screen.dart';
import 'package:cuddlecare2/services/bot_config_service.dart';
import 'package:cuddlecare2/services/telegram_polling_service.dart';
import 'dart:async'; // Added for Timer
import 'dart:io'; // Added for Platform

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize Firebase
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_api_key',
        appId: '1:959094650804:android:598989e0677afe564de4e1',
        messagingSenderId: '959094650804',
        projectId: 'cuddlecare2-dd913',
        storageBucket: 'cuddlecare2-dd913.firebasestorage.app',
      ),
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize bot configuration for testing (enabled in debug mode)
  try {
    debugPrint('Initializing bot configuration...');
    await BotConfigService.initializeBotConfig();
    debugPrint('Bot configuration initialized successfully');

    // Telegram bot now uses webhooks instead of polling
    debugPrint('Telegram bot configured for webhook mode');
    debugPrint('Use Bot Control screen to set up webhook');

    // Polling is disabled when using webhooks to avoid conflicts
    // Use the Bot Control screen to set up webhooks instead
  } catch (e) {
    debugPrint('Bot configuration initialization failed: $e');
  }

  // Setup admin user
  await _setupAdminUserIfNeeded();

  runApp(const MyApp());
}

// Temporary function to setup admin user
Future<void> _setupAdminUserIfNeeded() async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Retrieve admin password from environment variable
    final adminPassword =
        Platform.environment['ADMIN_PASSWORD'] ?? 'YOUR_ADMIN_PASSWORD';

    // Check if admin user already exists
    try {
      final adminCredential = await auth.signInWithEmailAndPassword(
        email: 'admin@cuddlecare.com',
        password: adminPassword,
      );

      print('Admin user already exists! UID: ${adminCredential.user!.uid}');

      // Update the user document to ensure admin role
      await firestore.collection('users').doc(adminCredential.user!.uid).set({
        'email': 'admin@cuddlecare.com',
        'role': 'admin',
        'isAdmin': true,
        'displayName': 'Admin User',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Admin user document updated successfully!');

      // Sign out after setup
      await auth.signOut();
    } catch (e) {
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        print('Creating new admin user...');

        // Create admin user with email and password
        final UserCredential userCredential =
            await auth.createUserWithEmailAndPassword(
          email: 'admin@cuddlecare.com',
          password: adminPassword,
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Add admin user to Firestore
          await firestore.collection('users').doc(user.uid).set({
            'email': 'admin@cuddlecare.com',
            'role': 'admin',
            'isAdmin': true,
            'displayName': 'Admin User',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('Admin user created successfully!');
          print('UID: ${user.uid}');
          print('Email: admin@cuddlecare.com');
          print('Password: $adminPassword');

          // Sign out after creation
          await auth.signOut();
        }
      } else {
        print('Error checking/creating admin user: $e');
      }
    }
  } catch (e) {
    print('Error in admin setup: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CuddleCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/bot-control': (context) => const BotControlScreen(),
      },
    );
  }
}
