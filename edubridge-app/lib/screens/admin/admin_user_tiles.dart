// lib/screens/admin/admin_user_tiles.dart
part of 'admin_screen.dart';

class _UserListTile extends StatelessWidget {
  final Map user;
  final Color color;
  final int assignedChildrenCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserListTile({
    required this.user,
    required this.color,
    required this.assignedChildrenCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = user['phone']?.toString();
    final initial = name.trim().isNotEmpty ? name.trim().characters.first : '؟';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      if (phone != null && phone.isNotEmpty)
                        Text(phone,
                            style: TextStyle(fontSize: 11.5, color: c.muted)),
                    ],
                  ),
                ),
                _ChildrenCountBadge(count: assignedChildrenCount),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(AppIcons.edit, size: 20, color: AppColors.brandBlue),
                  tooltip: 'تعديل',
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(AppIcons.delete, size: 20, color: AppColors.red),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildrenCountBadge extends StatelessWidget {
  final int count;
  const _ChildrenCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.brandTeal.withValues(alpha: 0.15)
            : c.line.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.child,
              size: 14, color: active ? AppColors.brandBlue : c.muted),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? AppColors.brandBlue : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildListTile extends StatelessWidget {
  final Map child;
  final Color color;
  final String? assignedTeacherName;
  final String? assignedSpecialistName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChildListTile({
    required this.child,
    required this.color,
    this.assignedTeacherName,
    this.assignedSpecialistName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = child['disability_type']?.toString();
    final initial = name.trim().isNotEmpty ? name.trim().characters.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'العمر: $age سنة'
                        '${disability != null && disability.isNotEmpty ? ' • $disability' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      if (assignedTeacherName != null && assignedTeacherName!.isNotEmpty)
                        _MiniIconRow(
                          icon: AppIcons.teacher,
                          text: assignedTeacherName!,
                          color: AppColors.brandBlue,
                        ),
                      if (assignedSpecialistName != null &&
                          assignedSpecialistName!.isNotEmpty)
                        _MiniIconRow(
                          icon: AppIcons.specialist,
                          text: assignedSpecialistName!,
                          color: AppColors.orangeDeep,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.edit, size: 20, color: AppColors.brandBlue),
                  tooltip: 'تعديل',
                  onPressed: onTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(AppIcons.delete, size: 20, color: AppColors.red),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniIconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniIconRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: color),
          ),
        ),
      ],
    );
  }
}