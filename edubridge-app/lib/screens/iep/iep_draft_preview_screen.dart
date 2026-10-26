import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_draft.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../theme.dart';
import 'iep_draft_goal_card.dart';
import 'iep_evaluation_reference.dart';

/// Read-only review of an immutable preparation snapshot, never a saved version.
class IepDraftPreviewScreen extends StatelessWidget {
  const IepDraftPreviewScreen({
    super.key,
    required this.draft,
    this.childName = '',
    this.evaluationGateway,
  });
  final IepPlanDraft draft;
  final String childName;
  final EvaluationHistoryGateway? evaluationGateway;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(
          l.iepComposePreview,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (childName.trim().isNotEmpty)
                    Text(
                      childName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  Text(
                    l.iepComposePreviewNotice,
                    key: const ValueKey('iep-preview-notice'),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    draft.title,
                    key: const ValueKey('iep-preview-title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${l.academicStart}: ${dates.formatMediumDate(draft.start)}',
                  ),
                  Text(
                    '${l.academicEnd}: ${dates.formatMediumDate(draft.end)}',
                  ),
                  Text(
                    '${l.iepReviewDate}: ${dates.formatMediumDate(draft.reviewOn)}',
                  ),
                  if (draft.summary.isNotEmpty) ...[
                    Text(
                      l.iepComposeSummary,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SelectableText(draft.summary),
                  ],
                  IepEvaluationReference(
                    childId: draft.childId,
                    evaluationId: draft.evaluationId,
                    gateway: evaluationGateway,
                  ),
                  Text(
                    l.iepGoals,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (var i = 0; i < draft.goals.length; i++)
                    IepDraftGoalCard(
                      key: ValueKey('iep-preview-goal-$i'),
                      goal: draft.goals[i],
                    ),
                  if (draft.accommodations.isNotEmpty) ...[
                    Text(
                      l.iepAccommodations,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    for (final accommodation in draft.accommodations)
                      SelectableText(accommodation),
                  ],
                  OutlinedButton.icon(
                    key: const ValueKey('iep-return-to-editor'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l.iepComposeBackToEdit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
