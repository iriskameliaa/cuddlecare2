import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

class ProviderMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalProviders = 0;
  int _successfulMigrations = 0;
  int _failedMigrations = 0;
  List<String> _errors = [];

  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCG1JqYhiojSmns7GkfElPmppfDKhE_l4w',
          appId: '1:959094650804:android:598989e0677afe564de4e1',
          messagingSenderId: '959094650804',
          projectId: 'cuddlecare2-dd913',
          storageBucket: 'cuddlecare2-dd913.firebasestorage.app',
        ),
      );
      print('✅ Firebase initialized');
    } catch (e) {
      print('❌ Firebase init failed: $e');
      throw Exception('Firebase initialization failed');
    }
  }

  bool _isProvider(Map<String, dynamic> userData) {
    if (userData.containsKey('role')) {
      return userData['role'] == 'provider';
    }
    if (userData.containsKey('isProvider')) {
      return userData['isProvider'] == true;
    }
    if (userData.containsKey('userType')) {
      return userData['userType'] == 'provider';
    }
    return false;
  }

  Future<bool> _migrateProvider(
      String docId, Map<String, dynamic> providerData) async {
    try {
      await _firestore.collection('providers').doc(docId).set(providerData);
      await _firestore.collection('providers').doc(docId).update({
        'migratedAt': FieldValue.serverTimestamp(),
        'migratedFrom': 'users',
      });
      return true;
    } catch (e) {
      _errors.add('Failed to migrate $docId: $e');
      return false;
    }
  }

  Future<bool> _deleteFromUsers(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).delete();
      return true;
    } catch (e) {
      _errors.add('Failed to delete $docId from users: $e');
      return false;
    }
  }

  Future<void> migrateProviders({bool deleteFromUsers = false}) async {
    print('🚀 Starting provider migration...');
    print('📊 Delete from users: ${deleteFromUsers ? "Yes" : "No"}');

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      print('📋 Found ${usersSnapshot.docs.length} total users');

      final providers = <QueryDocumentSnapshot>[];
      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (_isProvider(data)) {
          providers.add(doc);
        }
      }

      _totalProviders = providers.length;
      print('👥 Found $_totalProviders providers to migrate');

      if (_totalProviders == 0) {
        print('✅ No providers found');
        return;
      }

      for (final providerDoc in providers) {
        final docId = providerDoc.id;
        final providerData = providerDoc.data() as Map<String, dynamic>;

        print('🔄 Migrating: $docId');

        final migrationSuccess = await _migrateProvider(docId, providerData);

        if (migrationSuccess) {
          _successfulMigrations++;

          if (deleteFromUsers) {
            final deleteSuccess = await _deleteFromUsers(docId);
            print(deleteSuccess
                ? '  ✅ Migrated and deleted'
                : '  ⚠️  Migrated but delete failed');
          } else {
            print('  ✅ Migrated successfully');
          }
        } else {
          _failedMigrations++;
          print('  ❌ Migration failed');
        }
      }

      _printResults();
    } catch (e) {
      print('❌ Migration failed: $e');
      _errors.add('Migration failed: $e');
      _printResults();
    }
  }

  void _printResults() {
    print('\n' + '=' * 50);
    print('📊 MIGRATION RESULTS');
    print('=' * 50);
    print('Total providers: $_totalProviders');
    print('Successful: $_successfulMigrations');
    print('Failed: $_failedMigrations');
    print(
        'Success rate: ${_totalProviders > 0 ? (_successfulMigrations / _totalProviders * 100).toStringAsFixed(1) : 0}%');

    if (_errors.isNotEmpty) {
      print('\n❌ ERRORS:');
      for (final error in _errors) {
        print('  - $error');
      }
    }
    print('=' * 50);
  }

  Future<void> verifyMigration() async {
    print('\n🔍 Verifying migration...');

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final providersSnapshot = await _firestore.collection('providers').get();

      int remainingProvidersInUsers = 0;
      for (final doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (_isProvider(data)) {
          remainingProvidersInUsers++;
        }
      }

      print('📊 Verification:');
      print('  Providers in users: $remainingProvidersInUsers');
      print('  Providers in providers: ${providersSnapshot.docs.length}');
      print('  Expected total: $_totalProviders');

      if (remainingProvidersInUsers == 0 &&
          providersSnapshot.docs.length == _totalProviders) {
        print('✅ Verification successful!');
      } else {
        print('⚠️  Verification shows discrepancies');
      }
    } catch (e) {
      print('❌ Verification failed: $e');
    }
  }
}

Future<void> main() async {
  final migration = ProviderMigration();

  try {
    await migration.initializeFirebase();
    await migration.migrateProviders(deleteFromUsers: false);
    await migration.verifyMigration();
  } catch (e) {
    print('❌ Script failed: $e');
    exit(1);
  }

  print('\n🎉 Migration completed!');
  exit(0);
}
