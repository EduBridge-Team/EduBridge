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
    final strengths = (child['strengths'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final challenges = (child['challenges'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final preferredStyle =
        (child['preferred_learning_style'] ?? '').toString();
    final specialNeeds = (child['special_needs'] ?? '').toString();

    final color = AppColors
        .kidPalette[_rows.indexOf(row) % AppColors.kidPalette.length];
    final isAdding = _approvingId == child['id'];
    final hasSpecialty = _mySpecialty != null;

    final specType = _mySpecialty == 'learning_support'
        ? 'مختص دعم تعليمي'
        : _mySpecialty == 'educational'
            ? 'مختص تعليمي'
            : 'مختص (تخصصك غير محدد)';

    final specIcon = _mySpecialty == 'learning_support'
        ? AppIcons.specialist
        : AppIcons.lesson;

    final specColor = _mySpecialty == 'learning_support'
        ? AppColors.purple
        : AppColors.brandBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '؟',
                    style: const TextStyle(
                      fontSize: 20,
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
                      Text(name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          )),
                      Text(
                        'العمر: $age سنة'
                        '${disability.isNotEmpty ? ' • $disability' : ''}',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('متاح',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              _infoRowExt('وصف الإعاقة', description, c),
            if (medicalHistory.isNotEmpty)
              _infoRowExt('التاريخ الطبي', medicalHistory, c),
            if (specialNeeds.isNotEmpty)
              _infoRowExt('احتياجات خاصة', specialNeeds, c),
            if (preferredStyle.isNotEmpty)
              _infoRowExt('أسلوب التعلم', preferredStyle, c),
            if (strengths.isNotEmpty)
              _chipsRowExt('نقاط القوة', strengths, c, AppColors.greenDeep,
                  c.tintGreen),
            if (challenges.isNotEmpty)
              _chipsRowExt('التحديات', challenges, c, AppColors.orangeDeep,
                  c.tintOrange),
            const SizedBox(height: 12),

            if (!hasSpecialty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(AppIcons.info, size: 20),
                  label: const Text(
                    'حدد تخصصك أولاً',
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
                      setState(() => _mySpecialty = result);
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
                    isAdding ? 'جارٍ الإضافة...' : 'أضفني كـ$specType',
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

  // ═══════════════════════════════════════════════════════════
  //  بطاقة "طفلي"
  // ═══════════════════════════════════════════════════════════
}
