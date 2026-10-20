import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

enum _RatingError { load, save, starsRequired }

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
  _RatingError? _error;
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
        throw const FormatException();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _RatingError.load;
      });
    }
  }

  Future<void> _save() async {
    if (_stars < 1) {
      setState(() => _error = _RatingError.starsRequired);
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
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw const FormatException();
      }
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = _RatingError.save);
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
                          context.l10n.lessonRatingTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.close,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    context.l10n.lessonRatingSummary(_average.toStringAsFixed(1), _count),
                    style: TextStyle(color: c.muted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        tooltip: context.l10n.lessonRatingStars(value),
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
                    decoration: InputDecoration(
                      labelText: context.l10n.lessonRatingComment,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(switch (_error!) {
                      _RatingError.load => context.l10n.lessonRatingsLoadFailed,
                      _RatingError.save => context.l10n.lessonRatingSaveFailed,
                      _RatingError.starsRequired => context.l10n.lessonRatingStarsRequired,
                    },
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
                        ? context.l10n.saving
                        : _stars > 0
                            ? context.l10n.saveEvaluation
                            : context.l10n.lessonRatingChoose),
                  ),
                  if (_ratings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.lessonRatingReviews,
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
                        title: Text((row['user_name'] ?? context.l10n.user).toString()),
                        subtitle: (row['comment'] ?? '').toString().isEmpty
                            ? null
                            : Text(row['comment'].toString()),
                        trailing: Text(List.filled(stars, '★').join()),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}
