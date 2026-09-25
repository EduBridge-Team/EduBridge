part of 'admin_screen.dart';

class _UserChildrenSheet extends StatelessWidget {
  final Map user;
  final List children;
  final void Function(Map child) onEditChild;

  const _UserChildrenSheet({
    required this.user,
    required this.children,
    required this.onEditChild,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final role = (user['role'] ?? '').toString();
    final roleLabel = role == 'teacher'
        ? 'المعلّم'
        : role == 'specialist'
            ? 'المختص'
            : 'ولي الأمر';
    final roleIcon = role == 'teacher'
        ? AppIcons.teacher
        : role == 'specialist'
            ? AppIcons.specialist
            : AppIcons.parent;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 26, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أطفال $roleLabel ${user['name'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.child, size: 16, color: AppColors.brandBlue),
                const SizedBox(width: 6),
                Text(
                  '${children.length} ${children.length == 1 ? 'طفل' : 'أطفال'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: c.muted),
                    const SizedBox(height: 8),
                    Text('لا يوجد أطفال مرتبطون حالياً',
                        style: TextStyle(color: c.muted, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: children.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final child = children[i];
                  final name = (child['name'] ?? '').toString();
                  final age = child['age'] ?? '?';
                  final status = (child['status'] ?? 'pending').toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.kidPalette[i % AppColors.kidPalette.length],
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('العمر: $age سنة'),
                    trailing: _StatusBadge(status: status),
                    onTap: () {
                      Navigator.pop(context);
                      onEditChild(child);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}