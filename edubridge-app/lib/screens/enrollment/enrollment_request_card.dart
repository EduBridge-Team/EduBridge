import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/enrollment/enrollment_models.dart';
import 'enrollment_labels.dart';

class EnrollmentRequestCard extends StatelessWidget {
  const EnrollmentRequestCard({
    super.key,
    required this.request,
    this.actions = const [],
  });
  final EnrollmentRequest request;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            request.childName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(request.schoolName),
          Text(enrollmentStatusLabel(context.l10n, request.status)),
          Text(request.createdAt.toLocal().toIso8601String().split('T').first),
          if (request.reason?.isNotEmpty == true)
            Text('${context.l10n.enrollmentReason}: ${request.reason}'),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    ),
  );
}
