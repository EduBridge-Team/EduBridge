import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/iep/iep_plan_history.dart';
import '../../model/iep/iep_version.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../../theme.dart';
import 'iep_evaluation_reference.dart';
import 'iep_goal_card.dart';
import 'iep_labels.dart';

class IepVersionScreen extends StatelessWidget {
  const IepVersionScreen({
    super.key,
    required this.plan,
    required this.version,
    this.evaluationGateway,
  });
  final IepPlan plan;
  final IepVersion version;
  final EvaluationHistoryGateway? evaluationGateway;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(
          l10n.iepVersionDetails,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SelectableText(
                  plan.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${l10n.iepVersionNumber}: ${version.number}'),
                Text(iepStatusLabel(l10n, version.status)),
                if (plan.closed) Text(l10n.iepClosed),
                if (plan.currentApprovedId == version.id)
                  Text(l10n.iepCurrentApproved),
                if (version.author?.trim().isNotEmpty == true)
                  SelectableText(
                    '${l10n.evaluationHistoryAuthor}: ${version.author}',
                  ),
                Text(
                  l10n.evaluationDate(
                    dates.formatFullDate(version.createdAt.toLocal()),
                  ),
                ),
                Text(
                  '${dates.formatMediumDate(version.start)} — ${dates.formatMediumDate(version.end)}',
                ),
                Text(
                  '${l10n.iepReviewDate}: ${dates.formatMediumDate(version.reviewOn)}',
                ),
                if (version.summary?.trim().isNotEmpty == true)
                  SelectableText(version.summary!),
                if (version.returnReason?.trim().isNotEmpty == true)
                  SelectableText(
                    '${l10n.iepReturnReason}: ${version.returnReason}',
                    key: const ValueKey('iep-return-reason'),
                  ),
                IepEvaluationReference(
                  childId: version.childId,
                  evaluationId: version.evaluationId,
                  gateway: evaluationGateway,
                ),
                Text(
                  l10n.iepGoals,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (version.goals.isEmpty) Text(l10n.iepNoGoals),
                for (final goal in version.goals)
                  IepGoalCard(key: ValueKey('iep-goal-${goal.id}'), goal: goal),
                if (version.accommodations.isNotEmpty) ...[
                  Text(
                    l10n.iepAccommodations,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final text in version.accommodations)
                    SelectableText(text),
                ],
                Text(
                  l10n.iepComments,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (version.comments.isEmpty) Text(l10n.iepNoComments),
                for (final comment in version.comments)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (comment.author?.trim().isNotEmpty == true)
                            Text(comment.author!),
                          Text(
                            dates.formatFullDate(comment.createdAt.toLocal()),
                          ),
                          SelectableText(comment.text),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
