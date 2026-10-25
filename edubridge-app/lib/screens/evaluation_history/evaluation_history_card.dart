import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/evaluations/evaluation_record.dart';
import 'evaluation_history_labels.dart';

class EvaluationHistoryCard extends StatelessWidget {
  const EvaluationHistoryCard({
    super.key,
    required this.record,
    required this.onOpen,
  });
  final EvaluationRecord record;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: Semantics(
      button: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evaluationRecordTitle(context.l10n, record),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                  ),
                ],
              ),
              Text(
                context.l10n.evaluationDate(
                  MaterialLocalizations.of(context)
                      .formatFullDate(record.createdAt.toLocal()),
                ),
              ),
              if (record.author?.trim().isNotEmpty == true)
                Text(record.author!),
            ],
          ),
        ),
      ),
    ),
  );
}
