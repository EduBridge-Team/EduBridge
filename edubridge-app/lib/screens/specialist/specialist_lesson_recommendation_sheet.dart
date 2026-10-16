// Real lesson recommendation: select an assigned child, then notify their parents.
part of 'specialist_screen.dart';

extension _SpecialistLessonRecommendation on _SpecialistDashboardScreenState {
  Future<void> _recommendLessonToChild(Map lesson) async {
    if (!await _checkVerification() || !mounted) return;

    final lessonId = int.tryParse((lesson['id'] ?? '').toString());
    if (lessonId == null) return;

    final children = <Map<String, dynamic>>[];
    final seenIds = <int>{};
    for (final row in _rows) {
      final raw = row['child'];
      if (raw is! Map) continue;
      final child = Map<String, dynamic>.from(raw);
      final id = int.tryParse((child['id'] ?? '').toString());
      if (id == null || !_isMyChild(child) || !seenIds.add(id)) continue;
      children.add(child);
    }

    int? selectedId;
    bool sending = false;
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) {
          Future<void> send() async {
            if (selectedId == null || sending) return;
            update(() {
              sending = true;
              errorMessage = null;
            });
            try {
              final response = await ApiService.authPost(
                '/lessons/$lessonId/recommend',
                {'child_id': selectedId},
              );
              final payload = jsonDecode(response.body);
              final data = payload is Map ? payload : const {};
              if (response.statusCode != 200 && response.statusCode != 201) {
                if (!sheetContext.mounted) return;
                update(() {
                  sending = false;
                  errorMessage = (data['error'] ?? 'تعذّر إرسال الاقتراح')
                      .toString();
                });
                return;
              }
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      (data['message'] ?? 'تم إرسال اقتراح الدرس').toString(),
                    ),
                  ),
                );
              }
            } catch (_) {
              if (!sheetContext.mounted) return;
              update(() {
                sending = false;
                errorMessage = 'تعذّر الاتصال بالسيرفر';
              });
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اقتراح درس لطفل',
                    style: TextStyle(
                      color: JisrColors.of(sheetContext).heading,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    (lesson['title'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: JisrColors.of(sheetContext).muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'لا يوجد أطفال مرتبطون بحسابك لإرسال الاقتراح لهم.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: children.length,
                        itemBuilder: (ctx, index) {
                          final child = children[index];
                          final id = int.tryParse(child['id'].toString());
                          final selected = id != null && id == selectedId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            enabled: !sending,
                            title: Text((child['name'] ?? '').toString()),
                            leading: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? AppColors.brandBlue
                                  : JisrColors.of(ctx).muted,
                            ),
                            onTap: () => update(() => selectedId = id),
                          );
                        },
                      ),
                    ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: selectedId == null || sending ? null : send,
                    icon: sending
                        ? const SizedBox(
                            height: 17,
                            width: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      sending ? 'جارٍ الإرسال...' : 'إرسال الاقتراح لولي الأمر',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
