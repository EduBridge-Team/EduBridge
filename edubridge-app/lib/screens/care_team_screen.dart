// lib/screens/care_team_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CareTeamScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CareTeamScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends State<CareTeamScreen> {
  List<Map<String, dynamic>> _teachers = [];
  Map<String, dynamic>? _specialists;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teachers = await ApiService.getChildTeachers(widget.childId);
      final specialistsMap =
          await ApiService.getChildSpecialists(widget.childId);

      if (!mounted) return;
      setState(() {
        _teachers = teachers.cast<Map<String, dynamic>>();
        _specialists = specialistsMap;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الفريق';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: 'فريق ${widget.childName}'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  Widget _buildError() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(AppIcons.error, size: 56, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ),
        ],
      );

  Widget _buildBody() {
    final c = JisrColors.of(context);
    final totalSpecialists = _countSpecialists();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(AppIcons.users, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                '${_teachers.length + totalSpecialists} أعضاء في الفريق',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_teachers.length} معلم • $totalSpecialists مختص',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (totalSpecialists > 0) ...[
          _sectionTitle('المختصون', c),
          const SizedBox(height: 10),

          if (_specialists?['learning_support'] != null)
            _specialistCard(
              _specialists!['learning_support'],
              'مختص دعم تعليمي',
              AppIcons.specialist,
              AppColors.purple,
            ),

          if (_specialists?['educational'] != null)
            _specialistCard(
              _specialists!['educational'],
              'مختص تعليمي',
              AppIcons.lesson,
              AppColors.brandBlue,
            ),

          if (_specialists?['others'] is List)
            ...(_specialists!['others'] as List).map((s) =>
                _specialistCard(s, 'مختص', AppIcons.specialist,
                    AppColors.pink)),

          const SizedBox(height: 20),
        ],

        if (_teachers.isNotEmpty) ...[
          _sectionTitle('المعلمون (${_teachers.length})', c),
          const SizedBox(height: 10),
          ..._teachers.map((t) => _teacherCard(t)),
        ],

        if (_teachers.isEmpty && totalSpecialists == 0) ...[
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لم يتم تعيين فريق بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
        ],
      ],
    );
  }

  int _countSpecialists() {
    if (_specialists == null) return 0;
    int count = 0;
    if (_specialists!['learning_support'] != null) count++;
    if (_specialists!['educational'] != null) count++;
    if (_specialists!['others'] is List) {
      count += (_specialists!['others'] as List).length;
    }
    return count;
  }

  Widget _sectionTitle(String title, JisrColors c) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: c.heading,
      ),
    );
  }

  Widget _teacherCard(Map t) {
    final c = JisrColors.of(context);
    final name = (t['name'] ?? '').toString();
    final subject = t['subject']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name.characters.first : '؟',
            style: const TextStyle(
              color: AppColors.greenDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subject != null && subject.isNotEmpty
              ? 'معلّم — $subject'
              : 'معلّم',
          style: TextStyle(color: c.muted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(AppIcons.teacher,
              size: 18, color: AppColors.greenDeep),
        ),
      ),
    );
  }

  Widget _specialistCard(
    dynamic data,
    String roleLabel,
    IconData icon,
    Color color,
  ) {
    final c = JisrColors.of(context);
    if (data is! Map) return const SizedBox.shrink();

    final name = (data['name'] ?? '').toString();
    final specialty = data['specialty']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name.characters.first : '؟',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          roleLabel + (specialty != null ? ' — $specialty' : ''),
          style: TextStyle(color: c.muted),
        ),
        trailing: Icon(icon, color: color, size: 26),
      ),
    );
  }
}