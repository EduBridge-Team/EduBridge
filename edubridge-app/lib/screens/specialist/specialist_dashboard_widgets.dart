// Specialist dashboard view helpers extracted from specialist_screen.dart.
part of 'specialist_screen.dart';

extension _SpecialistDashboardWidgetsExtension on _SpecialistDashboardScreenState {

  Widget _buildFilterCard(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _scopeButton(
                c: c,
                selected: _showOnlyMine,
                icon: AppIcons.profile,
                label: 'أطفالي',
                onTap: () => _refreshState(() => _showOnlyMine = true),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _scopeButton(
                c: c,
                selected: !_showOnlyMine,
                icon: AppIcons.clock,
                label: 'قائمة الانتظار',
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
  }) {
    return Material(
      color: selected
          ? AppColors.brandBlue.withValues(alpha: .10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.brandBlue : c.muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.brandBlue : c.body,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${_filteredChildren.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
              Text(_error!,
                  style:
                      const TextStyle(fontSize: 16, color: AppColors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.refresh, size: 28),
                  label: const Text('إعادة المحاولة',
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
            const SnackBar(
              content: Text('تم إضافة الدرس بنجاح'),
              backgroundColor: AppColors.brandGreen,
            ),
          );
        },
      ),
    );
  }
}
