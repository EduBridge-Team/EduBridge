// lib/screens/specialist_suggestions_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

part 'specialist_suggestions_widgets.dart';

class SpecialistSuggestionsScreen extends StatefulWidget {
  const SpecialistSuggestionsScreen({super.key});

  @override
  State<SpecialistSuggestionsScreen> createState() =>
      _SpecialistSuggestionsScreenState();
}

class _SpecialistSuggestionsScreenState
    extends State<SpecialistSuggestionsScreen> {
  List _suggestions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'pending';

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
      final list = await ApiService.getMySpecialistSuggestions(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الاقتراحات';
        _loading = false;
      });
    }
  }

  Future<void> _accept(Map s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(AppIcons.check, color: AppColors.green, size: 28),
            SizedBox(width: 8),
            Text('تأكيد القبول'),
          ],
        ),
        content: Text(
          'هل تريد متابعة "${s['child_name']}" كـ'
          '${s['specialty'] == 'learning_support' ? 'مختص دعم تعليمي' : 'مختص تعليمي'}؟',
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final err = await ApiService.acceptSuggestion(s['id'] as int);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة الطفل لمتابعتك'),
        backgroundColor: AppColors.green,
      ),
    );
    _load();
  }

  Future<void> _reject(Map s) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(AppIcons.error, color: AppColors.red, size: 28),
            SizedBox(width: 8),
            Text('رفض الاقتراح'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رفض متابعة "${s['child_name']}"',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final err = await ApiService.rejectSuggestion(
      s['id'] as int,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفض الاقتراح'),
        backgroundColor: AppColors.orange,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: 'اقتراحات المتابعة',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip('معلقة', 'pending', AppColors.orange),
                const SizedBox(width: 8),
                _filterChip('مقبولة', 'accepted', AppColors.green),
                const SizedBox(width: 8),
                _filterChip('مرفوضة', 'rejected', AppColors.red),
                const SizedBox(width: 8),
                _filterChip('الكل', 'all', AppColors.brandBlue),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filter = value);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
