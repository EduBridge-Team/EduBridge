import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_director.dart';
import 'school_directors_controller.dart';

/// Collect dates and explicit consent before any access-changing request.
Future<void> assignSchoolDirector(
  BuildContext context,
  SchoolDirectorsController controller,
  SchoolDirector director,
) async {
  if (!controller.canMutate) return;
  final expected = controller.directory;
  final previous = expected?.current;
  final today = DateUtils.dateOnly(DateTime.now());
  final start = await showDatePicker(
    context: context,
    helpText: context.l10n.directorStarts,
    initialDate: today,
    firstDate: previous?.startsOn ?? DateTime(1900),
    lastDate: today,
  );
  if (start == null || !context.mounted || !controller.canMutate ||
      !identical(controller.directory, expected)) return;
  final confirm = await _confirm(
    context,
    context.l10n.directorConfirmAssign,
    previous == null
        ? context.l10n.directorAssignNotice
        : context.l10n.directorReplaceNotice,
  );
  if (confirm && context.mounted && controller.canMutate &&
      identical(controller.directory, expected)) {
    await controller.assign(director.id, start);
  }
}

Future<void> endSchoolDirector(
  BuildContext context,
  SchoolDirectorsController controller,
  DirectorAssignment assignment,
) async {
  if (!controller.canMutate) return;
  final expected = controller.directory;
  final today = DateUtils.dateOnly(DateTime.now());
  final end = await showDatePicker(
    context: context,
    helpText: context.l10n.directorEnded,
    initialDate: today,
    firstDate: assignment.startsOn,
    lastDate: today,
  );
  if (end == null || !context.mounted || !controller.canMutate ||
      !identical(controller.directory, expected)) return;
  final confirm = await _confirm(
    context,
    context.l10n.directorEnd,
    context.l10n.directorEndNotice,
  );
  if (confirm && context.mounted && controller.canMutate &&
      identical(controller.directory, expected)) {
    await controller.end(assignment, end);
  }
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.directorCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.directorConfirm),
          ),
        ],
      ),
    ) ??
    false;
