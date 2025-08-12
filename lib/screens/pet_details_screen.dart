import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cuddlecare2/models/pet.dart';
import 'package:cuddlecare2/services/pet_service.dart';

class PetDetailsScreen extends StatefulWidget {
  final Pet? pet;
  const PetDetailsScreen({super.key, this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final _petService = PetService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _typeController.text = widget.pet!.type;
      _breedController.text = widget.pet!.breed;
      _ageController.text = widget.pet!.age.toString();
      _notesController.text = widget.pet!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final pet = Pet(
        id: widget.pet?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        notes: _notesController.text.trim(),
      );
      if (widget.pet == null) {
        await _petService.addPet(user.uid, pet);
      } else {
        await _petService.updatePet(user.uid, pet);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving pet: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Add Pet' : 'Edit Pet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter pet name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration:
                    const InputDecoration(labelText: 'Type (Dog, Cat, etc.)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter pet type' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter age' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePet,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.pet == null ? 'Add Pet' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
