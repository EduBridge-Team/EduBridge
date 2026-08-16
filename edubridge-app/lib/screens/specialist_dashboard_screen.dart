// لوحة المختص — متابعة وتقييم الخطط العلاجية
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/tts_text.dart';
import '../widgets/tts_toggle_button.dart';
import 'child_progress_screen.dart';
import 'welcome_screen.dart';

class SpecialistDashboardScreen extends StatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  State<SpecialistDashboardScreen> createState() =>
      _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends State<SpecialistDashboardScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  int? _approvingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  bool _isToday(String? ts) {
    if (ts == null || ts.isEmpty) return false;
    final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Map<String, dynamic> _computeStats(List progress) {
    final total = progress.length;
    final done =
        progress.where((r) => r['status'] == 'done').length;
    final inProgress =
        progress.where((r) => r['status'] == 'in_progress').length;
    final doneToday = progress
        .where((r) =>
            r['status'] == 'done' && _isToday(r['completed_at']?.toString()))
        .length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final current = progress.cast<Map?>().firstWhere(
          (r) => r?['status'] == 'in_progress',
          orElse: () => null,
        );
    return {
      'total': total,
      'done': done,
      'inProgress': inProgress,
      'doneToday': doneToday,
      'pct': pct,
      'current': current,
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الأطفال';
          _loading = false;
        });
        return;
      }

      final children = (data['children'] ?? []) as List;
      final rows = <Map<String, dynamic>>[];

      for (final child in children) {
        final pRes =
            await ApiService.authGet('/progress/child/${child['id']}');
        final pData = jsonDecode(pRes.body);
        final progress =
            pRes.statusCode == 200 ? (pData['progress'] ?? []) : [];
        rows.add({
          'child': child,
          'progress': progress,
          'stats': _computeStats(progress),
        });
      }

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final current = row['stats']['current'];
    if (current == null) return;

    final childId = row['child']['id'];
    setState(() => _approvingId = childId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': childId,
        'lesson_id': current['lesson_id'],
        'status': 'done',
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _load();
      } else {
        final data = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'فشل الاعتماد')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  int get _totalChildren => _rows.length;
  int get _doneToday =>
      _rows.fold(0, (s, r) => s + (r['stats']['doneToday'] as int));
  int get _pending =>
      _rows.fold(0, (s, r) => s + (r['stats']['inProgress'] as int));

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(c),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _buildContent(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/icon.png', width: 32, height: 32),
                  const Spacer(),
                  const TtsToggleButton(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'خروج',
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const TtsText(
                '🩺 لوحة المختص — متابعة وتقييم الخطط العلاجية',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'المختص';
                  return TtsText(
                    'مرحباً $name، إليك نظرة عامة على تقدّم الأطفال وخططهم العلاجية اليوم.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  );
                },
              ),
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
              TtsText(_error!,
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(JisrColors c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقات المؤشرات
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: '⏳',
                value: '$_pending',
                label: 'مهام قيد الانتظار',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '✅',
                value: '$_doneToday',
                label: 'مهام منجزة (اليوم)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: '👪',
                value: '$_totalChildren',
                label: 'إجمالي الأطفال',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TtsText(
          'جميع الأطفال والتقدّم',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: c.heading,
          ),
        ),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: TtsText('لا يوجد أطفال بعد',
                  style: TextStyle(fontSize: 17, color: c.muted)),
            ),
          )
        else
          ..._rows.map((row) => _buildProgressRow(row, c)),
      ],
    );
  }

  Widget _buildProgressRow(Map<String, dynamic> row, JisrColors c) {
    final child = row['child'];
    final stats = row['stats'] as Map<String, dynamic>;
    final current = stats['current'];
    final name = (child['name'] ?? '').toString();
    final need = (child['disability_name'] ?? '').toString();
    final childId = child['id'];
    final approving = _approvingId == childId;
    final color = AppColors.kidPalette[
        _rows.indexOf(row) % AppColors.kidPalette.length];

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
                    name.isNotEmpty ? name.characters.first : '🧒',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildProgressScreen(
                            childId: childId,
                            childName: name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TtsText(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        if (need.isNotEmpty)
                          TtsText(
                            'احتياج: $need',
                            style: TextStyle(fontSize: 13, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ),
                TtsText(
                  '${stats['pct']}% ⭐',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (current != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TtsText(
                      '🕒 ${current['lesson_title'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                if ((stats['inProgress'] as int) > 0)
                  _CountBadge(
                    '${stats['inProgress']}',
                    color: AppColors.orange,
                  ),
                if ((stats['done'] as int) > 0)
                  _CountBadge(
                    '${stats['done']} ✅',
                    color: AppColors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: current != null
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      icon: const Icon(Icons.check, size: 22),
                      label: Text(
                        approving ? 'جارٍ...' : '✔ اعتماد كمنجز',
                        style: const TextStyle(fontSize: 15),
                      ),
                      onPressed:
                          approving ? null : () => _approve(row),
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.hourglass_empty, size: 20),
                      label: const Text('⏳ بانتظار البدء'),
                      onPressed: null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            TtsText(
              '$icon $value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TtsText(
              label,
              style: TextStyle(fontSize: 11, color: c.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CountBadge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TtsText(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
