import '../../l10n/l10n.dart';
import '../../widgets/disability/disability_display.dart';

// lib/screens/case_discussion/case_discussion_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/teacher_navigation_bar.dart';
import '../../app_icons.dart';
import '../../model/case_discussion_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/accessibility/profile_avatar_button.dart';
import '../specialist/specialist_screen.dart';
import '../profile/profile_screen.dart';
import '../chats_screen.dart';
import '../learning_support_requests/learning_support_requests_screen.dart';
import '../notifications_screen.dart';

import 'case_new_discussion_sheet.dart';
export 'case_discussion_s21.dart' show NewCaseStudyDialogS21;

part 'case_discussion_list.dart';
part 'case_discussion_detail.dart';
part 'case_discussion_message_bubble.dart';

part 'case_discussion_detail_view.dart';
part 'case_discussion_s07.dart';
part 'case_discussion_s20.dart';

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

String _caseStatusLabel(BuildContext context, CaseDiscussion discussion) =>
    switch (discussion.status) {
      CaseDiscussionStatus.open => context.l10n.caseOpen,
      CaseDiscussionStatus.inReview => context.l10n.underReview,
      CaseDiscussionStatus.resolved => context.l10n.caseResolved,
    };
