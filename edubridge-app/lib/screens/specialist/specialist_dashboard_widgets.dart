// Specialist dashboard view helpers extracted from specialist_screen.dart.
part of 'specialist_screen.dart';

extension _SpecialistDashboardWidgetsExtension on _SpecialistDashboardScreenState {

  Widget _buildFilterCard(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _scopeButton(
                c: c,
                selected: _showOnlyMine,
                icon: AppIcons.profile,
                label: context.l10n.myChildren,
                count: _showOnlyMine ? _filteredChildren.length : null,
                onTap: () => _refreshState(() => _showOnlyMine = true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _scopeButton(
                c: c,
                selected: !_showOnlyMine,
                icon: AppIcons.clock,
                label: context.l10n.waitingList,
                count: !_showOnlyMine ? _filteredChildren.length : null,
                onTap: () => _refreshState(() => _showOnlyMine = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeButton({
    required JisrColors c,
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? count,
  }) {
    return Material(
      color: selected ? const Color(0xFF1967C2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19,
                color: selected ? Colors.white : c.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : c.muted,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Color(0xFF1967C2),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text(context.sharedMessage(_error),
                  style:
                      const TextStyle(fontSize: 16, color: AppColors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.refresh, size: 28),
                  label: Text(context.l10n.retryAction,
                      style: TextStyle(fontSize: 18)),
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddModal() {
    return Positioned.fill(
      child: AddLessonSheet(
        types: _types,
        onClose: () => _setAdding(false),
        onCreated: (lesson) {
          inlineModalOpen.value = false;
          _refreshState(() {
            _lessons = [lesson, ..._lessons];
            _adding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.lessonAdded),
              backgroundColor: AppColors.brandGreen,
            ),
          );
        },
      ),
    );
  }
}
