import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuddlecare2/models/pet.dart';
import 'package:cuddlecare2/services/pet_service.dart';
import 'package:cuddlecare2/screens/pet_details_screen.dart';

class ManagePetsScreen extends StatefulWidget {
  const ManagePetsScreen({super.key});

  @override
  State<ManagePetsScreen> createState() => _ManagePetsScreenState();
}

class _ManagePetsScreenState extends State<ManagePetsScreen> {
  final PetService _petService = PetService();
  List<Pet> _pets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final pets = await _petService.getPets(user.uid);
        setState(() => _pets = pets);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pets: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _petService.deletePet(user.uid, pet.id);
        _loadPets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pet.name} deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting pet: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PetDetailsScreen(),
                    ),
                  );
                  if (result == true) _loadPets();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Pet'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pets.isEmpty
                      ? const Center(child: Text('No pets added yet.'))
                      : ListView.builder(
                          itemCount: _pets.length,
                          itemBuilder: (context, index) {
                            final pet = _pets[index];
                            return Card(
                              child: ListTile(
                                title: Text(pet.name),
                                subtitle: Text(
                                    '${pet.type} • ${pet.breed} • Age: ${pet.age}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PetDetailsScreen(pet: pet),
                                          ),
                                        );
                                        if (result == true) _loadPets();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deletePet(pet),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
