import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/models/pet_sitter_service.dart';
import 'package:uuid/uuid.dart';

class PetSitterServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pet_sitter_services';

  // Get all services for a pet sitter
  Future<List<PetSitterService>> getPetSitterServices(
      String petSitterId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('petSitterId', isEqualTo: petSitterId)
        .get();

    return snapshot.docs
        .map((doc) => PetSitterService.fromMap(doc.data()))
        .toList();
  }

  // Add a new service
  Future<void> addService(PetSitterService service) async {
    await _firestore
        .collection(_collection)
        .doc(service.id)
        .set(service.toMap());
  }

  // Update an existing service
  Future<void> updateService(PetSitterService service) async {
    await _firestore
        .collection(_collection)
        .doc(service.id)
        .update(service.toMap());
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection(_collection).doc(serviceId).delete();
  }

  // Toggle service active status
  Future<void> toggleServiceStatus(String serviceId, bool isActive) async {
    await _firestore.collection(_collection).doc(serviceId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get all active services
  Future<List<PetSitterService>> getActiveServices() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => PetSitterService.fromMap(doc.data()))
        .toList();
  }
}
