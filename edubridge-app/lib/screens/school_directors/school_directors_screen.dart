import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/schools/school_director_repository.dart';
import '../../theme.dart';
import 'director_directory_view.dart';
import 'director_failure_message.dart';
import 'director_profile_form.dart';
import 'school_directors_controller.dart';

class SchoolDirectorsScreen extends StatefulWidget {
  const SchoolDirectorsScreen({super.key, this.gateway});
  final SchoolDirectorGateway? gateway;

  @override
  State<SchoolDirectorsScreen> createState() => _SchoolDirectorsScreenState();
}

class _SchoolDirectorsScreenState extends State<SchoolDirectorsScreen>
    with WidgetsBindingObserver {
  late SchoolDirectorsController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  void _initializeController() {
    _controller = SchoolDirectorsController(
      widget.gateway ?? SchoolDirectorRepository(),
    );
    _controller.initialize();
  }

  @override
  void didUpdateWidget(covariant SchoolDirectorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gateway != oldWidget.gateway) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final l10n = context.l10n;
      final controller = _controller;
      final schools = controller.schools;
      return PopScope(canPop: !controller.saving, child: Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(l10n.directorTitle),
          actions: [
            IconButton(
              tooltip: l10n.directorReload,
              onPressed: _controller.loading || _controller.saving
                  ? null
                  : _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_controller.loading || _controller.saving)
                const LinearProgressIndicator(),
              if (_controller.schools.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    'director-school-${_controller.school?.id ?? 0}',
                  ),
                  initialValue: _controller.school?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.directorChooseSchool,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final school in _controller.schools)
                      DropdownMenuItem(
                        value: school.id,
                        child: Text(school.name),
                      ),
                  ],
                  onChanged: _controller.saving
                      ? null
                      : (id) {
                          if (id != null && identical(controller, _controller) &&
                              identical(controller.schools, schools) &&
                              !controller.saving) {
                            final matches = schools.where((school) => school.id == id);
                            if (matches.length == 1) controller.select(matches.single);
                          }
                        },
                ),
                const SizedBox(height: 16),
              ],
              if (_controller.saved)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.directorSaved,
                    key: const ValueKey('director-saved'),
                  ),
                ),
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      directorFailureMessage(l10n, _controller.error!),
                      key: const ValueKey('director-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (!_controller.loading &&
                  _controller.schools.isEmpty &&
                  _controller.error == null)
                Text(l10n.directorNoSchools),
              if (_controller.schools.isNotEmpty && _controller.school == null)
                Text(l10n.directorChooseSchoolHint),
              if (_controller.directory != null) ...[
                FilledButton.icon(
                  key: const ValueKey('director-add'),
                  onPressed: _controller.canMutate
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DirectorProfileForm(controller: _controller),
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.directorAdd),
                ),
                const SizedBox(height: 16),
                DirectorDirectoryView(controller: _controller),
              ],
            ],
          ),
        ),
      ));
    },
  );
}
