// lib/screens/care_team_screen.dart — النسخة الموسّعة
import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _specialists; // {psychological: ..., educational: ...}
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
      // 1. جلب المعلمين
      final teachers = await ApiService.getChildTeachers(widget.childId);

      // 2. جلب المختصين
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
      appBar: JisrAppBar(title: '👥 فريق ${widget.childName}'),
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

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );

  Widget _buildBody() {
    final c = JisrColors.of(context);
    final totalSpecialists = _countSpecialists();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── ملخص الفريق ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.groups, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                '${_teachers.length + totalSpecialists} أعضاء في الفريق',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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

        // ═══════════════════════════════════════════
        //  المختصون (نفسي + تعليمي + إضافيون)
        // ═══════════════════════════════════════════
        if (totalSpecialists > 0) ...[
          _sectionTitle('🧠 المختصون', c),
          const SizedBox(height: 10),

          if (_specialists?['psychological'] != null)
            _specialistCard(
              _specialists!['psychological'],
              'مختص نفسي',
              Icons.psychology,
              AppColors.purple,
            ),

          if (_specialists?['educational'] != null)
            _specialistCard(
              _specialists!['educational'],
              'مختص تعليمي',
              Icons.menu_book,
              AppColors.navy,
            ),

          // مختصون إضافيون (إن وُجدوا)
          if (_specialists?['others'] is List)
            ...(_specialists!['others'] as List).map((s) =>
                _specialistCard(s, 'مختص', Icons.person, AppColors.pink)),

          const SizedBox(height: 20),
        ],

        // ═══════════════════════════════════════════
        //  المعلمون (متعددون)
        // ═══════════════════════════════════════════
        if (_teachers.isNotEmpty) ...[
          _sectionTitle('👨‍🏫 المعلمون (${_teachers.length})', c),
          const SizedBox(height: 10),
          ..._teachers.map((t) => _teacherCard(t)),
        ],

        if (_teachers.isEmpty && totalSpecialists == 0) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 72, color: c.muted),
                const SizedBox(height: 12),
                Text(
                  'لم يتم تعيين فريق بعد',
                  style: TextStyle(fontSize: 16, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int _countSpecialists() {
    if (_specialists == null) return 0;
    int count = 0;
    if (_specialists!['psychological'] != null) count++;
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
        fontWeight: FontWeight.bold,
        color: c.heading,
      ),
    );
  }

  Widget _teacherCard(Map t) {
    final c = JisrColors.of(context);
    final name = (t['name'] ?? '').toString();
    final subject = t['subject']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.green,
          child: Text(
            name.isNotEmpty ? name.characters.first : '؟',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          child: const Text(
            '👨‍🏫',
            style: TextStyle(fontSize: 16),
          ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            name.isNotEmpty ? name.characters.first : '؟',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
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