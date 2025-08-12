class PetSitterService {
  final String id;
  final String petSitterId;
  final String title;
  final String description;
  final double price;
  final String serviceType; // e.g., "Dog Walking", "Pet Sitting", "House Visit"
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetSitterService({
    required this.id,
    required this.petSitterId,
    required this.title,
    required this.description,
    required this.price,
    required this.serviceType,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petSitterId': petSitterId,
      'title': title,
      'description': description,
      'price': price,
      'serviceType': serviceType,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PetSitterService.fromMap(Map<String, dynamic> map) {
    return PetSitterService(
      id: map['id'] as String,
      petSitterId: map['petSitterId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      serviceType: map['serviceType'] as String,
      isActive: map['isActive'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
