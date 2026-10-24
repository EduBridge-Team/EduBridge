import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_director.dart';
import 'director_assignment_actions.dart';
import 'director_profile_form.dart';
import 'school_directors_controller.dart';

class DirectorDirectoryView extends StatelessWidget {
  const DirectorDirectoryView({super.key, required this.controller});
  final SchoolDirectorsController controller;

  void _edit(BuildContext context, SchoolDirector director) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DirectorProfileForm(controller: controller, director: director),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final directory = controller.directory!;
    final current = directory.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.directorCurrent,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (current == null) Text(l10n.directorNoCurrent),
        if (directory.directors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.directorNoProfiles),
          ),
        for (final director in directory.directors)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(director.details.name),
                    subtitle: Text(director.details.email),
                    trailing: IconButton(
                      tooltip: l10n.directorEdit,
                      onPressed: controller.canMutate
                          ? () => _edit(context, director)
                          : null,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  if (director.details.phone.isNotEmpty)
                    Text('${l10n.directorPhone}: ${director.details.phone}'),
                  if (director.details.qualification.isNotEmpty)
                    Text(
                      '${l10n.directorQualification}: ${director.details.qualification}',
                    ),
                  Text(
                    '${l10n.directorExperience}: ${director.details.experienceYears}',
                  ),
                  if (current != null && current.directorId == director.id) ...[
                    Chip(label: Text(l10n.directorActive)),
                    Text(
                      '${l10n.directorStarts}: ${directorDateString(current.startsOn)}',
                    ),
                    OutlinedButton(
                      onPressed: controller.canMutate
                          ? () =>
                                endSchoolDirector(context, controller, current)
                          : null,
                      child: Text(l10n.directorEnd),
                    ),
                  ] else
                    FilledButton.tonal(
                      onPressed: controller.canMutate
                          ? () => assignSchoolDirector(
                              context,
                              controller,
                              director,
                            )
                          : null,
                      child: Text(l10n.directorAssign),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.directorHistory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (directory.assignments.isEmpty) Text(l10n.directorNoHistory),
        for (final assignment in directory.assignments)
          ListTile(
            title: Text(
              directory.directors
                  .firstWhere((d) => d.id == assignment.directorId)
                  .details
                  .name,
            ),
            subtitle: Text(
              '${l10n.directorStarts}: ${directorDateString(assignment.startsOn)}\n'
              '${assignment.isActive ? l10n.directorActive : '${l10n.directorEnded}: ${directorDateString(assignment.endedOn!)}'}',
            ),
          ),
      ],
    );
  }
}
