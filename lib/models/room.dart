// lib/models/room.dart
class Room {
  final String id;
  final String name;
  final int capacity;
  final String location;
  final List<String> amenities;
  final String imageUrl;
  bool isAvailable;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    required this.amenities,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      location: json['location']?.toString() ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
      imageUrl: json['imageUrl']?.toString() ?? '',
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'location': location,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}
