import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to remove "Pet Training" from all provider service lists
/// This ensures only allowed services remain: Pet Sitting, Pet Grooming, Pet Walking, Pet Health Checkups
class PetTrainingCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _totalProvidersChecked = 0;
  int _providersUpdated = 0;
  int _errors = 0;
  final List<String> _errorMessages = [];

  /// Clean up "Pet Training" from all providers in both users and providers collections
  Future<void> cleanupPetTrainingService() async {
    print('🧹 Starting Pet Training service cleanup...');
    print('📋 This will remove "Pet Training" from all provider service lists');
    print('✅ Allowed services: Pet Sitting, Pet Grooming, Pet Walking, Pet Health Checkups\n');

    try {
      // Clean up providers collection
      await _cleanupCollection('providers');
      
      // Clean up users collection (for providers that haven't been migrated)
      await _cleanupUsersCollection();
      
      _printResults();
    } catch (e) {
      print('❌ Cleanup failed: $e');
      _errorMessages.add('Cleanup failed: $e');
      _printResults();
    }
  }

  /// Clean up a specific collection
  Future<void> _cleanupCollection(String collectionName) async {
    print('🔍 Checking $collectionName collection...');
    
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      print('📋 Found ${snapshot.docs.length} documents in $collectionName');

      for (final doc in snapshot.docs) {
        await _cleanupProviderDocument(doc, collectionName);
      }
    } catch (e) {
      print('❌ Error processing $collectionName collection: $e');
      _errorMessages.add('Error processing $collectionName: $e');
      _errors++;
    }
  }

  /// Clean up users collection (only providers)
  Future<void> _cleanupUsersCollection() async {
    print('🔍 Checking users collection for providers...');
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isPetSitter', isEqualTo: true)
          .get();
      
      print('📋 Found ${snapshot.docs.length} providers in users collection');

      for (final doc in snapshot.docs) {
        await _cleanupProviderDocument(doc, 'users');
      }
    } catch (e) {
      print('❌ Error processing users collection: $e');
      _errorMessages.add('Error processing users collection: $e');
      _errors++;
    }
  }

  /// Clean up a single provider document
  Future<void> _cleanupProviderDocument(DocumentSnapshot doc, String collectionName) async {
    try {
      _totalProvidersChecked++;
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        print('⚠️  Document ${doc.id} has no data');
        return;
      }

      final services = data['services'] as List<dynamic>?;
      if (services == null || services.isEmpty) {
        return; // No services to clean up
      }

      // Check if "Pet Training" exists in services
      final servicesList = services.cast<String>();
      if (!servicesList.contains('Pet Training')) {
        return; // No Pet Training to remove
      }

      // Remove "Pet Training" from services
      final cleanedServices = servicesList.where((service) => service != 'Pet Training').toList();
      
      print('🔄 Updating ${doc.id}: Removing "Pet Training"');
      print('   Before: $servicesList');
      print('   After:  $cleanedServices');

      // Update the document
      await _firestore.collection(collectionName).doc(doc.id).update({
        'services': cleanedServices,
        'lastUpdated': FieldValue.serverTimestamp(),
        'petTrainingRemovedAt': FieldValue.serverTimestamp(),
      });

      _providersUpdated++;
      print('   ✅ Successfully updated ${doc.id}');

    } catch (e) {
      _errors++;
      final errorMsg = 'Failed to update ${doc.id}: $e';
      print('   ❌ $errorMsg');
      _errorMessages.add(errorMsg);
    }
  }

  /// Print cleanup results
  void _printResults() {
    print('\n📊 Pet Training Cleanup Results:');
    print('=' * 50);
    print('Total providers checked: $_totalProvidersChecked');
    print('Providers updated: $_providersUpdated');
    print('Errors: $_errors');
    
    if (_errorMessages.isNotEmpty) {
      print('\n❌ Errors encountered:');
      for (final error in _errorMessages) {
        print('  • $error');
      }
    }
    
    if (_errors == 0) {
      print('\n✅ Cleanup completed successfully!');
      if (_providersUpdated > 0) {
        print('🎉 $_providersUpdated providers had "Pet Training" removed from their services');
      } else {
        print('ℹ️  No providers had "Pet Training" in their services');
      }
    } else {
      print('\n⚠️  Cleanup completed with $_errors errors');
    }
    
    print('\n🔧 Allowed services are now:');
    print('  • Pet Sitting');
    print('  • Pet Grooming'); 
    print('  • Pet Walking');
    print('  • Pet Health Checkups');
  }

  /// Verify cleanup was successful
  Future<void> verifyCleanup() async {
    print('\n🔍 Verifying cleanup...');
    
    try {
      // Check providers collection
      final providersWithTraining = await _firestore
          .collection('providers')
          .where('services', arrayContains: 'Pet Training')
          .get();
      
      // Check users collection
      final usersWithTraining = await _firestore
          .collection('users')
          .where('services', arrayContains: 'Pet Training')
          .get();
      
      final totalWithTraining = providersWithTraining.docs.length + usersWithTraining.docs.length;
      
      if (totalWithTraining == 0) {
        print('✅ Verification successful! No providers have "Pet Training" in their services');
      } else {
        print('⚠️  Verification found $totalWithTraining providers still have "Pet Training"');
        print('   Providers collection: ${providersWithTraining.docs.length}');
        print('   Users collection: ${usersWithTraining.docs.length}');
      }
    } catch (e) {
      print('❌ Verification failed: $e');
    }
  }
}

/// Main function to run the cleanup
Future<void> main() async {
  final cleanup = PetTrainingCleanupService();
  
  // Run cleanup
  await cleanup.cleanupPetTrainingService();
  
  // Verify results
  await cleanup.verifyCleanup();
}
