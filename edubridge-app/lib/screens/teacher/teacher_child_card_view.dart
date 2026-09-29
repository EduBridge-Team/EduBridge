part of 'teacher_screen.dart';

extension _TeacherChildCardView on _TeacherChildCard {
  Widget buildView(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final status = child['status'];
    final age = child['age'];
    final disability = (child['disability_type'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '؟',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                    color: c.heading,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(status),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (age != null)
                                _metaChip(
                                  icon: Icons.cake_outlined,
                                  text: '$age سنة',
                                ),
                              if (disability.isNotEmpty)
                                _metaChip(
                                  icon: Icons.accessibility_new_rounded,
                                  text: disability,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_back_rounded, color: c.muted, size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                _buildActionButtons(context, child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: c.tintTeal.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            _statusText(status),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
