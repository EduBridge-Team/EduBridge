

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role; // 1: Parent, 2: Teacher, 3: Specialist
  final List<AdminChild> children;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.children = const [],
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'].toString(),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => AdminChild.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// ملخص طفل للعرض في قوائم الأدمن فقط.
/// لبيانات الطفل الكاملة استخدم Child من child_model.dart
class AdminChild {
  final String id;
  final String name;
  final int age;

  AdminChild({
    required this.id,
    required this.name,
    required this.age,
  });

  factory AdminChild.fromJson(Map<String, dynamic> json) {
    return AdminChild(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
    );
  }
}