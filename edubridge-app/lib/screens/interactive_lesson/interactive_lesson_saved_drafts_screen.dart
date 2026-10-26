import 'package:flutter/material.dart';

import '../../services/interactive_draft_repository.dart';

/// Read-only list of the signed-in educator's saved lesson drafts.
class InteractiveLessonSavedDraftsScreen extends StatefulWidget {
  const InteractiveLessonSavedDraftsScreen({super.key});

  @override
  State<InteractiveLessonSavedDraftsScreen> createState() => _InteractiveLessonSavedDraftsScreenState();
}

class _InteractiveLessonSavedDraftsScreenState extends State<InteractiveLessonSavedDraftsScreen> {
  late Future<List<InteractiveDraftSummary>> _drafts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _drafts = const InteractiveDraftRepository().list();
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _drafts;
    } catch (_) {
      // The error state is rendered by FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مسودات دروسي المحفوظة')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<InteractiveDraftSummary>>(
          future: _drafts,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('تعذّر تحميل المسودات. اسحب للأسفل لإعادة المحاولة.')),
                ],
              );
            }
            final drafts = snapshot.data ?? const <InteractiveDraftSummary>[];
            if (drafts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('لا توجد مسودات محفوظة بعد.')),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return Card(
                  child: ListTile(
                    key: ValueKey('saved-draft-${draft.id}'),
                    title: Text(draft.title),
                    subtitle: Text(draft.objective),
                    trailing: Text('v${draft.version}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
