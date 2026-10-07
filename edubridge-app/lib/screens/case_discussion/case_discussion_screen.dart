import '../../utils/presentation_text.dart';
// lib/screens/case_discussion/case_discussion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/teacher_navigation_bar.dart';
import '../../app_icons.dart';
import '../../model/case_discussion_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

part 'case_discussion_list.dart';
part 'case_discussion_detail.dart';
part 'case_discussion_message_bubble.dart';
part 'case_new_discussion_sheet.dart';
part 'case_discussion_detail_view.dart';

class CaseDiscussionScreen extends StatefulWidget {
  final int? discussionId;
  final int? filterChildId;
  final bool embedded;
  final bool showBottomNavigation;

  const CaseDiscussionScreen({
    super.key,
    this.discussionId,
    this.filterChildId,
    this.embedded = false,
    this.showBottomNavigation = false,
  });

  @override
  State<CaseDiscussionScreen> createState() => _CaseDiscussionScreenState();
}

class _CaseDiscussionScreenState extends State<CaseDiscussionScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.discussionId == null) {
      return _CaseDiscussionList(
        filterChildId: widget.filterChildId,
        embedded: widget.embedded,
        showBottomNavigation: widget.showBottomNavigation,
      );
    }
    return _CaseDiscussionDetail(discussionId: widget.discussionId!);
  }
}
