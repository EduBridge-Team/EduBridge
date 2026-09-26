// lib/screens/case_discussion/case_discussion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
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

  const CaseDiscussionScreen({
    super.key,
    this.discussionId,
    this.filterChildId,
  });

  @override
  State<CaseDiscussionScreen> createState() => _CaseDiscussionScreenState();
}

class _CaseDiscussionScreenState extends State<CaseDiscussionScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.discussionId == null) {
      return _CaseDiscussionList(filterChildId: widget.filterChildId);
    }
    return _CaseDiscussionDetail(discussionId: widget.discussionId!);
  }
}