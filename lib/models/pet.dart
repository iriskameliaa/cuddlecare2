class Pet {
  final String id;
  String name;
  String type; // e.g. Dog, Cat
  String breed;
  int age;
  String notes;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'breed': breed,
        'age': age,
        'notes': notes,
      };

  factory Pet.fromMap(Map<String, dynamic> map) => Pet(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        breed: map['breed'],
        age: map['age'],
        notes: map['notes'] ?? '',
      );
}
