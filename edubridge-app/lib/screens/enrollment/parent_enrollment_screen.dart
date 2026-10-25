import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'school_history_screen.dart';
import '../../model/enrollment/enrollment_models.dart';
import '../../services/enrollment/enrollment_repository.dart';
import 'enrollment_controllers.dart';
import 'enrollment_labels.dart';
import 'enrollment_request_card.dart';

class ParentEnrollmentScreen extends StatefulWidget {
  const ParentEnrollmentScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.gateway,
  });
  final int childId;
  final String childName;
  final ParentEnrollmentGateway? gateway;
  @override
  State<ParentEnrollmentScreen> createState() => _ParentEnrollmentScreenState();
}

class _ParentEnrollmentScreenState extends State<ParentEnrollmentScreen>
    with WidgetsBindingObserver {
  late final ParentEnrollmentController _controller;
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ParentEnrollmentController(
      widget.gateway ?? ParentEnrollmentRepository(childId: widget.childId),
    );
    _controller.reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.enrollmentCancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.enrollmentConfirm),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _submit(EnrollmentSchool school) async {
    final confirmed = await _confirm(
      school.name,
      context.l10n.enrollmentSubmitNotice,
    );
    if (mounted && confirmed) await _controller.submit(school);
  }

  Future<void> _cancel(EnrollmentRequest request) async {
    final confirmed = await _confirm(
      context.l10n.enrollmentCancelRequest,
      context.l10n.enrollmentCancelNotice,
    );
    if (mounted && confirmed) await _controller.cancel(request);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final l10n = context.l10n;
      final data = _controller.snapshot;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          centerTitle: true,
          title: Text(l10n.enrollmentParentTitle, textAlign: TextAlign.center),
          actions: [
            IconButton(
              tooltip: l10n.enrollmentReload,
              onPressed: _controller.loading || _controller.busy
                  ? null
                  : _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _controller.reload,
          child: SafeArea(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          widget.childName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_controller.loading || _controller.busy)
                          const LinearProgressIndicator(),
                        if (_controller.saved)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l10n.enrollmentSaved,
                              key: const ValueKey('parent-enrollment-saved'),
                            ),
                          ),
                        if (_controller.error != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              enrollmentFailureMessage(
                                l10n,
                                _controller.error!,
                              ),
                              key: const ValueKey('parent-enrollment-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (data != null) ...[
                          if (data.activeEnrollment != null)
                            Text(
                              '${l10n.enrollmentActive}: ${data.activeEnrollment!.schoolName}',
                            ),
                          if (!data.canRequest)
                            Text(l10n.enrollmentPendingNotice),
                          TextField(
                            key: const ValueKey('enrollment-school-query'),
                            controller: _query,
                            textAlign: TextAlign.center,
                            enabled: !_controller.busy,
                            maxLength: 100,
                            onChanged: (_) => _controller.clearSearch(),
                            onSubmitted: _controller.search,
                            decoration: InputDecoration(
                              labelText: l10n.enrollmentSearch,
                              hintText: l10n.enrollmentSearchHint,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          FilledButton(
                            key: const ValueKey('enrollment-school-search'),
                            onPressed: _controller.busy
                                ? null
                                : () => _controller.search(_query.text),
                            child: Text(l10n.enrollmentSearchAction),
                          ),
                          if (_controller.searching)
                            const LinearProgressIndicator(),
                          if (_controller.searchError != null)
                            Text(
                              enrollmentFailureMessage(
                                l10n,
                                _controller.searchError!,
                              ),
                            ),
                          if (_controller.searched &&
                              _controller.schools.isEmpty)
                            Text(l10n.enrollmentNoSchools),
                          for (final school in _controller.schools)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(school.name),
                                    if (school.address.isNotEmpty)
                                      Text(school.address),
                                    FilledButton(
                                      key: ValueKey(
                                        'enrollment-submit-${school.id}',
                                      ),
                                      onPressed:
                                          _controller.canWrite &&
                                              data.canRequest
                                          ? () => _submit(school)
                                          : null,
                                      child: Text(l10n.enrollmentSubmit),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.enrollmentHistory,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (data.requests.isEmpty)
                            Text(l10n.enrollmentNoRequests),
                          for (final request in data.requests)
                            EnrollmentRequestCard(
                              request: request,
                              actions: [
                                if (request.status == EnrollmentStatus.pending)
                                  TextButton(
                                    key: ValueKey(
                                      'enrollment-cancel-${request.id}',
                                    ),
                                    onPressed: _controller.canWrite
                                        ? () => _cancel(request)
                                        : null,
                                    child: Text(l10n.enrollmentCancelRequest),
                                  ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const ValueKey('open-school-history'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SchoolHistoryScreen(
                                  childId: widget.childId,
                                  childName: widget.childName,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.history),
                            label: Text(l10n.schoolHistoryTitle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
