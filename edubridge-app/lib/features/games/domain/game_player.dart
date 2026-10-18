/// The child's identity is supplied by the caller, never by a game factory.
class GamePlayer {
  final int? childId;
  final String name;
  final int age;

  const GamePlayer({required this.childId, required this.name, required this.age});

  static GamePlayer? fromChild(Map<String, dynamic> child) {
    final id = int.tryParse('${child['id']}');
    final age = int.tryParse('${child['age']}');
    final name = (child['name'] ?? '').toString().trim();
    if (id == null || id <= 0 || age == null || age <= 0 || name.isEmpty) return null;
    return GamePlayer(childId: id, name: name, age: age);
  }
}
