part of 'teacher_screen.dart';

extension _TeacherChildCardView on _TeacherChildCard {
  Widget buildView(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final status = child['status'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name.characters.first : '؟',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.heading,
                )),
            subtitle: _buildSubtitle(status, c),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherChildDetailsScreen(
                    childId: child['id'],
                    childName: name,
                  ),
                ),
              );
              onReload();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildActionButtons(context, child),
          ),
        ],
      ),
    );
  
  }
}
