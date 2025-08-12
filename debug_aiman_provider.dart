import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔍 Debugging Aiman Provider Issue...\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCG1JqYhiojSmns7GkfElPmppfDKhE_l4w',
        appId: '1:959094650804:android:598989e0677afe564de4e1',
        messagingSenderId: '959094650804',
        projectId: 'cuddlecare2-dd913',
        storageBucket: 'cuddlecare2-dd913.firebasestorage.app',
      ),
    );
    
    final firestore = FirebaseFirestore.instance;
    
    // Step 1: Search for Aiman in users collection
    print('1️⃣ Searching for "Aiman" in users collection...');
    final usersSnapshot = await firestore.collection('users').get();
    
    List<QueryDocumentSnapshot> aimanUsers = [];
    for (final doc in usersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final displayName = (data['displayName'] ?? '').toString().toLowerCase();
      
      if (name.contains('aiman') || email.contains('aiman') || displayName.contains('aiman')) {
        aimanUsers.add(doc);
        print('   ✅ Found Aiman in users: ${doc.id}');
        print('      Name: ${data['name']}');
        print('      Email: ${data['email']}');
        print('      isPetSitter: ${data['isPetSitter']}');
        print('      Role: ${data['role']}');
        print('      Services: ${data['services']}');
        print('      PetTypes: ${data['petTypes']}');
        print('      Location: ${data['location'] ?? data['geoPointLocation']}');
        print('      Verified: ${data['isVerified']}');
        print('');
      }
    }
    
    if (aimanUsers.isEmpty) {
      print('   ❌ No users found with "Aiman" in name, email, or displayName');
    }
    
    // Step 2: Search for Aiman in providers collection
    print('2️⃣ Searching for "Aiman" in providers collection...');
    final providersSnapshot = await firestore.collection('providers').get();
    
    List<QueryDocumentSnapshot> aimanProviders = [];
    for (final doc in providersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      
      if (name.contains('aiman') || email.contains('aiman')) {
        aimanProviders.add(doc);
        print('   ✅ Found Aiman in providers: ${doc.id}');
        print('      Name: ${data['name']}');
        print('      Email: ${data['email']}');
        print('      Services: ${data['services']}');
        print('      PetTypes: ${data['petTypes']}');
        print('      Location: ${data['location']}');
        print('      VerificationStatus: ${data['verificationStatus']}');
        print('      SetupCompleted: ${data['setupCompleted']}');
        print('');
      }
    }
    
    if (aimanProviders.isEmpty) {
      print('   ❌ No providers found with "Aiman" in name or email');
    }
    
    // Step 3: Check all pet sitters in users collection
    print('3️⃣ Checking all pet sitters in users collection...');
    final petSittersSnapshot = await firestore
        .collection('users')
        .where('isPetSitter', isEqualTo: true)
        .get();
    
    print('   📊 Total pet sitters found: ${petSittersSnapshot.docs.length}');
    for (final doc in petSittersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] ?? 'Unknown';
      final email = data['email'] ?? 'No email';
      final services = data['services'] as List?;
      final petTypes = data['petTypes'] as List?;
      final location = data['location'] ?? data['geoPointLocation'];
      final verified = data['isVerified'] ?? false;
      
      print('   - $name ($email)');
      print('     Services: $services');
      print('     PetTypes: $petTypes');
      print('     Location: $location');
      print('     Verified: $verified');
      print('');
    }
    
    // Step 4: Check filtering conditions that might exclude providers
    print('4️⃣ Analyzing potential filtering issues...');
    
    if (aimanUsers.isNotEmpty) {
      for (final doc in aimanUsers) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        
        print('   🔍 Analyzing $name:');
        
        // Check isPetSitter
        final isPetSitter = data['isPetSitter'] ?? false;
        if (!isPetSitter) {
          print('     ❌ ISSUE: isPetSitter is false or missing');
        } else {
          print('     ✅ isPetSitter: true');
        }
        
        // Check services
        final services = data['services'] as List?;
        if (services == null || services.isEmpty) {
          print('     ❌ ISSUE: No services defined');
        } else {
          print('     ✅ Services: $services');
        }
        
        // Check petTypes
        final petTypes = data['petTypes'] as List?;
        if (petTypes == null || petTypes.isEmpty) {
          print('     ❌ ISSUE: No petTypes defined');
        } else {
          print('     ✅ PetTypes: $petTypes');
        }
        
        // Check location
        final location = data['location'] ?? data['geoPointLocation'];
        if (location == null) {
          print('     ❌ ISSUE: No location data');
        } else {
          print('     ✅ Location: $location');
        }
        
        // Check verification
        final verified = data['isVerified'] ?? false;
        if (!verified) {
          print('     ⚠️  Not verified (may still show in results)');
        } else {
          print('     ✅ Verified');
        }
        
        print('');
      }
    }
    
    // Step 5: Recommendations
    print('5️⃣ RECOMMENDATIONS:');
    print('');
    
    if (aimanUsers.isEmpty && aimanProviders.isEmpty) {
      print('❌ PROBLEM: Aiman does not exist in the database');
      print('💡 SOLUTION: Create Aiman\'s account first');
      print('   1. Register Aiman as a user');
      print('   2. Set isPetSitter: true');
      print('   3. Complete provider setup');
    } else if (aimanUsers.isNotEmpty) {
      final aimanData = aimanUsers.first.data() as Map<String, dynamic>;
      
      if (!(aimanData['isPetSitter'] ?? false)) {
        print('❌ PROBLEM: Aiman exists but isPetSitter is false');
        print('💡 SOLUTION: Update Aiman\'s profile to be a pet sitter');
      } else if ((aimanData['services'] as List?)?.isEmpty ?? true) {
        print('❌ PROBLEM: Aiman is a pet sitter but has no services');
        print('💡 SOLUTION: Add services to Aiman\'s profile');
      } else if ((aimanData['petTypes'] as List?)?.isEmpty ?? true) {
        print('❌ PROBLEM: Aiman has services but no pet types');
        print('💡 SOLUTION: Add pet types to Aiman\'s profile');
      } else if (aimanData['location'] == null && aimanData['geoPointLocation'] == null) {
        print('❌ PROBLEM: Aiman has no location data');
        print('💡 SOLUTION: Add location to Aiman\'s profile');
      } else {
        print('✅ Aiman\'s profile looks complete');
        print('💡 POSSIBLE ISSUES:');
        print('   - Distance filtering (too far from search location)');
        print('   - Service/pet type filtering (doesn\'t match search criteria)');
        print('   - App cache (try refreshing the Find Providers screen)');
      }
    }
    
    print('');
    print('🎯 NEXT STEPS:');
    print('1. Check if Aiman exists in the database (see results above)');
    print('2. If missing, create Aiman\'s account');
    print('3. If exists, fix any issues identified above');
    print('4. Test Find Providers with no filters applied');
    print('5. Check distance and service filters');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
