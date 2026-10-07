// Available-child card extracted from specialist_child_cards.dart.
part of 'specialist_screen.dart';

extension _AvailableChildCardExtension on _SpecialistDashboardScreenState {
  Widget buildAvailableChildCard(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'] as Map<String, dynamic>;
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = (child['disability_type'] ?? '').toString();
    final description = (child['disability_description'] ?? '').toString();
    final medicalHistory = (child['medical_history'] ?? '').toString();
    final psychologistNotes = (child['psychologist_notes'] ?? '').toString();
    final specialNeeds = (child['special_needs'] ?? '').toString();
    final preferredStyle =
        (child['preferred_learning_style'] ?? '').toString();
    final strengths = (child['strengths'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final challenges = (child['challenges'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    final color = AppColors.kidPalette[
        _rows.indexOf(row) % AppColors.kidPalette.length];
    final isAdding = _approvingId == child['id'];
    final hasSpecialty = _mySpecialty != null;

    final specType = _mySpecialty == 'learning_support'
        ? 'مختص دعم تعليمي'
        : _mySpecialty == 'educational'
            ? 'مختص تعليمي'
            : 'مختص';

    final specIcon = _mySpecialty == 'learning_support'
        ? AppIcons.specialist
        : AppIcons.lesson;

    final specColor = _mySpecialty == 'learning_support'
        ? AppColors.brandTealDeep
        : AppColors.brandBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openChildProfile(child),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildChildHeader(
                  name: name,
                  age: age,
                  disability: disability,
                  color: color,
                  c: c,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (disability.isNotEmpty) _buildDisabilityBadge(disability, c),
            if (description.isNotEmpty)
              _buildInfoBlock(
                label: 'وصف الإعاقة',
                value: description,
                icon: AppIcons.info,
                color: AppColors.brandBlue,
                c: c,
              ),
            if (medicalHistory.isNotEmpty)
              _buildInfoBlock(
                label: 'التاريخ الطبي',
                value: medicalHistory,
                icon: AppIcons.certificate,
                color: AppColors.brandTealDeep,
                c: c,
              ),
            if (specialNeeds.isNotEmpty)
              _buildInfoBlock(
                label: 'احتياجات خاصة',
                value: specialNeeds,
                icon: AppIcons.support,
                color: AppColors.orangeDeep,
                c: c,
              ),
            if (preferredStyle.isNotEmpty)
              _buildInfoBlock(
                label: 'أسلوب التعلم المفضّل',
                value: preferredStyle,
                icon: AppIcons.lesson,
                color: AppColors.purple,
                c: c,
              ),
            if (psychologistNotes.isNotEmpty)
              _buildInfoBlock(
                label: 'ملاحظات نفسية',
                value: psychologistNotes,
                icon: AppIcons.cognitive,
                color: AppColors.pink,
                c: c,
              ),
            if (strengths.isNotEmpty)
              _buildChipsBlock(
                label: 'نقاط القوة',
                items: strengths,
                fg: AppColors.greenDeep,
                bg: c.tintGreen,
                icon: AppIcons.starFilled,
                c: c,
              ),
            if (challenges.isNotEmpty)
              _buildChipsBlock(
                label: 'التحديات',
                items: challenges,
                fg: AppColors.orangeDeep,
                bg: c.tintOrange,
                icon: AppIcons.warning,
                c: c,
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.info,
                      size: 18, color: AppColors.brandTealDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'راجع معلومات الحالة ثم قرر إن كانت مناسبة لتخصصك قبل قبول المتابعة.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: c.onTint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!hasSpecialty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlueDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(AppIcons.info, size: 20),
                  label: const Text(
                    'حدّد تخصصك أولاً',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChooseSpecialtyScreen(),
                      ),
                    );
                    if (result != null && mounted) {
                      _refreshState(() => _mySpecialty = result);
                    }
                  },
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: specColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(specIcon, size: 20),
                  label: Text(
                    isAdding ? 'جارٍ قبول المتابعة...' : 'متابعة الطفل كـ $specType',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed:
                      isAdding ? null : () => _addMyselfToChild(child),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildHeader({
    required String name,
    required dynamic age,
    required String disability,
    required Color color,
    required JisrColors c,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: color,
          child: Text(
            PresentationText.initial(name, fallback: '؟'),
            style: const TextStyle(
              fontSize: 22,
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
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              Text(
                'العمر: $age سنة',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.clock, size: 12, color: AppColors.blue),
              SizedBox(width: 4),
              Text(
                'متاح',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisabilityBadge(String disability, JisrColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.specialist, size: 20, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              disability,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required JisrColors c,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: c.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsBlock({
    required String label,
    required List<String> items,
    required Color fg,
    required Color bg,
    required IconData icon,
    required JisrColors c,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: fg.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
