// lib/screens/specialist_suggestions_screen.dart
// اقتراحات المتابعة الواردة للمختص
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
            Icon(Icons.check_circle, color: Colors.green, size: 28),
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
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        SnackBar(content: Text('❌ $err'), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تمت إضافة الطفل لمتابعتك'),
        backgroundColor: Colors.green,
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
            Icon(Icons.cancel, color: Colors.red, size: 28),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        SnackBar(content: Text('❌ $err'), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفض الاقتراح'),
        backgroundColor: Colors.orange,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: '🤝 اقتراحات المتابعة',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── الفلاتر ───
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
                _filterChip('الكل', 'all', AppColors.navy),
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

  Widget _buildBody(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _filter == 'pending'
                  ? 'لا توجد اقتراحات معلقة'
                  : 'لا توجد اقتراحات',
              style: TextStyle(fontSize: 16, color: c.muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _suggestions.length,
      itemBuilder: (context, i) =>
          _buildSuggestionCard(_suggestions[i], c),
    );
  }

  Widget _buildSuggestionCard(Map s, JisrColors c) {
    final status = s['status'] ?? 'pending';
    final isLearningSupport = s['specialty'] == 'learning_support';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = '✅ مقبول';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = '❌ مرفوض';
        break;
      default:
        statusColor = AppColors.orange;
        statusLabel = '⏳ معلّق';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الرأس ───
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isLearningSupport ? AppColors.purple : AppColors.navy,
                  child: Text(
                    (s['child_name'] ?? '؟').toString().characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['child_name'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'من: ${s['suggested_by_name'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── التخصص + السبب ───
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isLearningSupport ? AppColors.purple : AppColors.navy)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isLearningSupport ? Icons.psychology : Icons.school,
                    color: isLearningSupport ? AppColors.purple : AppColors.navy,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLearningSupport ? 'مختص دعم تعليمي' : 'مختص تعليمي',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLearningSupport ? AppColors.purple : AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💬 ${s['reason'] ?? ''}',
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body),
            ),

            // ─── أزرار ───
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      onPressed: () => _reject(s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('قبول ومتابعة'),
                      onPressed: () => _accept(s),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}