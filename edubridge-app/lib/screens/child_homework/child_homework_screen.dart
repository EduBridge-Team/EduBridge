import '../../l10n/l10n.dart';
// lib/screens/child_homework/child_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/accessibility/child_color_filter.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../widgets/accessibility/child_adaptation_scope.dart';
import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
import '../../widgets/accessibility/word_prediction_bar.dart';
import '../../widgets/accessibility/voice_draft_button.dart';
import '../../model/homework_model.dart';

part 'child_homework_card.dart';
part 'child_homework_submit_sheet.dart';
part 'child_homework_submit_sheet_widgets.dart';

class ChildHomeworkScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildHomeworkScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildHomeworkScreen> createState() => _ChildHomeworkScreenState();
}

class _ChildHomeworkScreenState extends State<ChildHomeworkScreen> {
  List<Homework> _homeworks = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    } else if (_loadFailed) {
      setState(() => _loadFailed = false);
    }
    try {
      final list = await ApiService.getHomeworks(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _homeworks = list
            .map((e) => Homework.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  Future<void> _submit(Homework hw) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitHomeworkSheet(
        homework: hw,
        childId: widget.childId,
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) => ChildAdaptationScope(
    childId: widget.childId, builder: _buildScreen);

  Widget _buildScreen(BuildContext context) {
    return ChildColorFilter(child: Scaffold(
      appBar: JisrAppBar(title: context.l10n.childHomeworkFor(widget.childName)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    ));
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(AppIcons.error, size: 56, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            context.l10n.homeworksLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: Text(context.l10n.retryAction),
              onPressed: _load,
            ),
          ),
        ],
      );
    }
    if (_homeworks.isEmpty) {
      final c = JisrColors.of(context);
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 110),
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.homework,
                size: 40,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.childHomeworkEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.childHomeworkEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.muted),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _homeworks.length,
      itemBuilder: (context, i) => _HomeworkCard(
        homework: _homeworks[i],
        childId: widget.childId,
        onSubmit: () => _submit(_homeworks[i]),
      ),
    );
  }
}
