import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../theme.dart';
import '../child_progress_screen.dart';

class SpecialistChildProfileScreen extends StatefulWidget {
  final Map<String, dynamic> child;

  const SpecialistChildProfileScreen({
    super.key,
    required this.child,
  });

  @override
  State<SpecialistChildProfileScreen> createState() =>
      _SpecialistChildProfileScreenState();
}

class _SpecialistChildProfileScreenState
    extends State<SpecialistChildProfileScreen> {
  late final int _childId;
  late final String _childName;

  @override
  void initState() {
    super.initState();
    _childId = widget.child['id'] as int;
    _childName = (widget.child['name'] ?? '').toString();
    AccessibilityService.instance.setActiveChild(
      _childId,
      disabilityTypeHint: widget.child['disability_type']?.toString(),
      forceReload: true,
    );
  }

  @override
  void dispose() {
    AccessibilityService.instance.setActiveChild(null);
    super.dispose();
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  List<String> _list(dynamic value) =>
      (value as List? ?? []).map((e) => e.toString()).toList();

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final child = widget.child;

    final age = child['age'];
    final disability = _text(child['disability_type']);
    final description = _text(child['disability_description']);
    final medicalHistory = _text(child['medical_history']);
    final specialNeeds = _text(child['special_needs']);
    final preferredStyle = _text(child['preferred_learning_style']);
    final psychologistNotes = _text(child['psychologist_notes']);
    final strengths = _list(child['strengths']);
    final challenges = _list(child['challenges']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _childName.isEmpty ? 'ملف الطالب' : _childName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _childName.isNotEmpty ? _childName.characters.first : '؟',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _childName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age == null ? 'العمر غير محدد' : '$age سنة',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            c,
            title: 'معلومات الطالب',
            children: [
              if (disability.isNotEmpty)
                _row(c, 'نوع الإعاقة', disability, Icons.accessibility_new),
              if (description.isNotEmpty)
                _row(c, 'وصف الإعاقة', description, AppIcons.info),
              if (preferredStyle.isNotEmpty)
                _row(c, 'أسلوب التعلم المفضّل', preferredStyle, AppIcons.lesson),
              if (specialNeeds.isNotEmpty)
                _row(c, 'الاحتياجات الخاصة', specialNeeds, AppIcons.support),
            ],
          ),
          if (medicalHistory.isNotEmpty || psychologistNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              c,
              title: 'معلومات داعمة',
              children: [
                if (medicalHistory.isNotEmpty)
                  _row(c, 'التاريخ الطبي', medicalHistory, AppIcons.certificate),
                if (psychologistNotes.isNotEmpty)
                  _row(c, 'ملاحظات نفسية', psychologistNotes, AppIcons.cognitive),
              ],
            ),
          ],
          if (strengths.isNotEmpty || challenges.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              c,
              title: 'نقاط القوة والتحديات',
              children: [
                if (strengths.isNotEmpty)
                  _chips(c, 'نقاط القوة', strengths, AppColors.greenDeep),
                if (challenges.isNotEmpty)
                  _chips(c, 'التحديات', challenges, AppColors.orangeDeep),
              ],
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildProgressScreen(
                  childId: _childId,
                  childName: _childName,
                ),
              ),
            ),
            icon: const Icon(AppIcons.progress),
            label: const Text('عرض التقدّم'),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _section(
    JisrColors c, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(JisrColors c, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: c.body, height: 1.5),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(
    JisrColors c,
    String label,
    List<String> values,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => Chip(
                    label: Text(value),
                    side: BorderSide(color: color.withValues(alpha: .25)),
                    backgroundColor: color.withValues(alpha: .08),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
