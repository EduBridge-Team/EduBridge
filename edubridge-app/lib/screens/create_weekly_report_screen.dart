// lib/screens/create_weekly_report_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
part 'create_weekly_report_view.dart';

class CreateWeeklyReportScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CreateWeeklyReportScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CreateWeeklyReportScreen> createState() =>
      _CreateWeeklyReportScreenState();
}

class _CreateWeeklyReportScreenState extends State<CreateWeeklyReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── الحقول ───
  final _lessonsCtrl = TextEditingController();
  final _teacherNotesCtrl = TextEditingController();
  final _achievementsCtrl = TextEditingController();
  final _concernsCtrl = TextEditingController();

  DateTime _weekStart = _lastMonday();
  int _progressPercent = 50;

  // ─── القوائم ───
  final List<String> _achievements = [];
  final List<String> _concerns = [];

  bool _saving = false;
  String? _error;

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _lessonsCtrl.dispose();
    _teacherNotesCtrl.dispose();
    _achievementsCtrl.dispose();
    _concernsCtrl.dispose();
    super.dispose();
  }

  void _addAchievement() {
    final text = _achievementsCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _achievements.add(text);
      _achievementsCtrl.clear();
    });
  }

  void _addConcern() {
    final text = _concernsCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _concerns.add(text);
      _concernsCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPost('/reports/weekly', {
        'child_id': widget.childId,
        'week_start': _weekStart.toIso8601String(),
        'lessons_completed': int.tryParse(_lessonsCtrl.text) ?? 0,
        'progress_percentage': _progressPercent,
        'teacher_notes': _teacherNotesCtrl.text.trim(),
        'achievements': _achievements,
        'concerns': _concerns,
      });

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التقرير الأسبوعي'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          _error = data['error']?.toString() ?? 'فشل الحفظ';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}