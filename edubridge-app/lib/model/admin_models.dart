class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role; // 1: Parent, 2: Teacher, 3: Specialist
  final List<Child> children;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.children = const [],
  });

  // دالة منJson المفقودة (هنا سبب الخطأ)
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'].toString(),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => Child.fromJson(e))
          .toList(),
    );
  }
}

class Child {
  final String id;
  final String name;
  final int age;

  Child({
    required this.id,
    required this.name,
    required this.age,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
    );
  }
}