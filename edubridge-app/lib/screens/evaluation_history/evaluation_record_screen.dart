import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/evaluations/evaluation_record.dart';
import '../../theme.dart';
import 'evaluation_history_labels.dart';

class EvaluationRecordScreen extends StatelessWidget {
  const EvaluationRecordScreen({super.key, required this.record});
  final EvaluationRecord record;
  Widget _field(String label, String? value, String id) =>
      value == null || value.trim().isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(value, key: ValueKey('evaluation-detail-$id')),
            ],
          ),
        );
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(l10n.evaluationDetails),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  evaluationRecordTitle(l10n, record),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  l10n.evaluationDate(
                    MaterialLocalizations.of(context)
                        .formatFullDate(record.createdAt.toLocal()),
                  ),
                ),
                const SizedBox(height: 16),
                _field(l10n.evaluationHistoryAuthor, record.author, 'author'),
                _field(l10n.cognitiveAssessment, record.cognitive, 'cognitive'),
                _field(l10n.motorAssessment, record.motor, 'motor'),
                _field(l10n.learningInteraction, record.emotional, 'emotional'),
                _field(l10n.socialAssessment, record.social, 'social'),
                _field(
                  l10n.recommendations,
                  record.recommendations,
                  'recommendations',
                ),
                _field(l10n.educationalPlan, record.plan, 'plan'),
                for (
                  var index = 0;
                  index < record.teachingMethods.length;
                  index++
                )
                  _field(
                    index == 0 ? l10n.evaluationHistoryMethods : '',
                    record.teachingMethods[index],
                    'method-$index',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
