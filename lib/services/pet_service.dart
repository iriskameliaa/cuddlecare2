import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuddlecare2/models/pet.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference: /users/{userId}/pets/{petId}
  CollectionReference<Map<String, dynamic>> petsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('pets');
  }

  Future<void> addPet(String userId, Pet pet) async {
    await petsRef(userId).doc(pet.id).set(pet.toMap());
  }

  Future<void> updatePet(String userId, Pet pet) async {
    await petsRef(userId).doc(pet.id).update(pet.toMap());
  }

  Future<void> deletePet(String userId, String petId) async {
    await petsRef(userId).doc(petId).delete();
  }

  Future<List<Pet>> getPets(String userId) async {
    final snapshot = await petsRef(userId).get();
    return snapshot.docs.map((doc) => Pet.fromMap(doc.data())).toList();
  }
}
