// lib/models/user.dart

class User {
  final String id;
  final String name;
  final String email;
  final DateTime memberSince;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.memberSince,
  });

  String get initials {
    final parts = name.trim().split(' ').where((n) => n.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get firstName => name.trim().split(' ').first;

  /// Receives the nested 'user' sub-object from the API response:
  /// { "id"/"_id": "...", "name": "...", "email": "...", "memberSince": "..." }
  factory User.fromJson(Map<String, dynamic> json) {
    // Support both 'id' (REST) and '_id' (MongoDB raw)
    final id = json['id']?.toString() ??
        json['_id']?.toString() ??
        json['userId']?.toString() ??
        '';

    return User(
      id: id,
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      email: json['email']?.toString() ?? json['Email']?.toString() ?? '',
      memberSince:
          DateTime.tryParse(json['memberSince']?.toString() ?? '') ??
              DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'memberSince': memberSince.toIso8601String(),
      };
}