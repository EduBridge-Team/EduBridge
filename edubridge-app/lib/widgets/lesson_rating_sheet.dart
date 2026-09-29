import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

Future<void> showLessonRatingSheet(
  BuildContext context, {
  required int lessonId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _LessonRatingSheet(lessonId: lessonId),
  );
}

class _LessonRatingSheet extends StatefulWidget {
  final int lessonId;

  const _LessonRatingSheet({required this.lessonId});

  @override
  State<_LessonRatingSheet> createState() => _LessonRatingSheetState();
}

class _LessonRatingSheetState extends State<_LessonRatingSheet> {
  final _commentCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _stars = 0;
  double _average = 0;
  int _count = 0;
  List<dynamic> _ratings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet(
        '/lessons/${widget.lessonId}/ratings',
      );
      final data = ApiService.decodeMap(res.body);
      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'تعذّر تحميل التقييمات');
      }

      final mine = data['my_rating'];
      if (!mounted) return;
      setState(() {
        _average = (data['average'] as num?)?.toDouble() ?? 0;
        _count = (data['count'] as num?)?.toInt() ?? 0;
        _ratings = data['ratings'] is List ? data['ratings'] : const [];
        if (mine is Map) {
          _stars = (mine['stars'] as num?)?.toInt() ?? 0;
          _commentCtrl.text = (mine['comment'] ?? '').toString();
        }
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

  Future<void> _save() async {
    if (_stars < 1) {
      setState(() => _error = 'اختر عدد النجوم أولاً');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPost(
        '/lessons/${widget.lessonId}/ratings',
        {
          'stars': _stars,
          'comment': _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
        },
      );
      final data = res.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(data['error'] ?? 'تعذّر حفظ التقييم');
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _loading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'تقييم الدرس',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    'المتوسط: ${_average.toStringAsFixed(1)} من 5 · $_count تقييم',
                    style: TextStyle(color: c.muted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        tooltip: '$value نجوم',
                        onPressed: () => setState(() => _stars = value),
                        icon: Icon(
                          value <= _stars ? Icons.star : Icons.star_border,
                          color: AppColors.yellow,
                          size: 38,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentCtrl,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'تعليق اختياري',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.star),
                    label: Text(_saving
                        ? 'جارِ الحفظ...'
                        : _stars > 0
                            ? 'حفظ التقييم'
                            : 'اختر تقييمك'),
                  ),
                  if (_ratings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'آراء المستخدمين',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._ratings.take(10).map((item) {
                      final row = item is Map
                          ? Map<String, dynamic>.from(item)
                          : <String, dynamic>{};
                      final stars = (row['stars'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text((row['user_name'] ?? 'مستخدم').toString()),
                        subtitle: (row['comment'] ?? '').toString().isEmpty
                            ? null
                            : Text(row['comment'].toString()),
                        trailing: Text('★' * stars),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}
