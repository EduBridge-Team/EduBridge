part of 'ministry_screen.dart';

class _MinistryLessonsTab extends StatefulWidget {
  const _MinistryLessonsTab();

  @override
  State<_MinistryLessonsTab> createState() => _MinistryLessonsTabState();
}

class _MinistryLessonsTabState extends State<_MinistryLessonsTab> {
  String _status = 'pending';
  List<dynamic> _lessons = const [];
  bool _loading = true;
  int? _reviewingId;
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
      final res = await ApiService.authGet(
        '/ministry/lessons?status=$_status',
      );
      final data = ApiService.decodeMap(res.body);
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'تعذّر تحميل الدروس');
      }
      if (!mounted) return;
      setState(() {
        _lessons = data['lessons'] is List ? data['lessons'] : const [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _review(Map lesson, String status) async {
    String note = '';
    if (status == 'rejected') {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('سبب رفض الدرس'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'ملاحظة للمعلم (اختياري)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('رفض الدرس'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) return;
      note = result;
    }

    final id = (lesson['id'] as num?)?.toInt();
    if (id == null) return;

    setState(() => _reviewingId = id);
    try {
      final res = await ApiService.authPut(
        '/ministry/lessons/$id',
        {
          'status': status,
          'note': note.isEmpty ? null : note,
        },
      );
      final data = ApiService.decodeMap(res.body);
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'تعذّرت مراجعة الدرس');
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _reviewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final entry in const [
                ('pending', 'معلّقة'),
                ('approved', 'معتمدة'),
                ('rejected', 'مرفوضة'),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _status == entry.$1,
                  onSelected: (_) {
                    if (_status == entry.$1) return;
                    setState(() => _status = entry.$1);
                    _load();
                  },
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'لا توجد دروس في هذه الحالة',
                  style: TextStyle(color: c.muted),
                ),
              ),
            )
          else
            ..._lessons.map((item) {
              final lesson = item is Map
                  ? Map<String, dynamic>.from(item)
                  : <String, dynamic>{};
              final id = (lesson['id'] as num?)?.toInt();
              final busy = id != null && _reviewingId == id;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (lesson['title'] ?? 'درس').toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      if ((lesson['content'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          lesson['content'].toString(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        [
                          if ((lesson['education_level'] ?? '').toString().isNotEmpty)
                            'المستوى: ${lesson['education_level']}',
                          if ((lesson['disability_name'] ?? '').toString().isNotEmpty)
                            'الفئة: ${lesson['disability_name']}',
                          if ((lesson['teacher_name'] ?? '').toString().isNotEmpty)
                            'المعلم: ${lesson['teacher_name']}',
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      if ((lesson['review_note'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ملاحظة المراجعة: ${lesson['review_note']}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                      if (_status != 'approved') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => _review(lesson, 'approved'),
                                icon: const Icon(Icons.check),
                                label: const Text('اعتماد'),
                              ),
                            ),
                            if (_status != 'rejected') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _review(lesson, 'rejected'),
                                  icon: const Icon(Icons.close),
                                  label: const Text('رفض'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
