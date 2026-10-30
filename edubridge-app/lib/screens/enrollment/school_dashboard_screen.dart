import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/enrollment/enrollment_models.dart';
import '../../services/api_service.dart';
import '../../services/enrollment/enrollment_repository.dart';
import '../../theme.dart';
import '../../widgets/dashboard_header_actions.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/dashboard_profile_identity.dart';
import '../../widgets/legal_links_button.dart';
import '../login_screen.dart';
import '../academics/academic_screen.dart';
import 'school_annual_promotion_screen.dart';
import 'enrollment_controllers.dart';
import 'enrollment_labels.dart';
import 'enrollment_request_card.dart';
import 'school_enrollment_decision_dialog.dart';

class SchoolDashboardScreen extends StatefulWidget {
  const SchoolDashboardScreen({super.key, this.gateway});
  final SchoolEnrollmentGateway? gateway;
  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen>
    with WidgetsBindingObserver {
  late SchoolEnrollmentController _controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = SchoolEnrollmentController(
      widget.gateway ?? SchoolEnrollmentRepository(),
    );
    _controller.reload();
  }

  @override
  void didUpdateWidget(covariant SchoolDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) {
      _controller.dispose();
      _controller = SchoolEnrollmentController(widget.gateway ?? SchoolEnrollmentRepository())..reload();
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

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _decide(EnrollmentRequest request, bool approve) async {
    final controller = _controller, expected = _controller.snapshot;
    if (!controller.canWrite || expected == null) return;
    final decision = await showDialog<EnrollmentDecision>(
      context: context,
      builder: (_) => SchoolEnrollmentDecisionDialog(
        approve: approve,
        request: request,
        sections: expected.sections,
      ),
    );
    if (mounted && decision != null && identical(controller, _controller) && identical(expected, controller.snapshot)) {
      await controller.decide(request, decision);
    }
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
          toolbarHeight: MediaQuery.textScalerOf(context)
              .scale(80)
              .clamp(96, 160)
              .toDouble(),
          title: DashboardProfileIdentity(
            roleLabel: l10n.schoolRole,
            subtitle: data?.identity.school.name ?? l10n.enrollmentSchoolTitle,
          ),
          actions: [
            DashboardHeaderActions(
              menuIcon: Icons.menu,
              actions: [
                DashboardMenuAction(
                  id: 'theme',
                  label: l10n.switchAppearance,
                  icon: Icons.brightness_6_outlined,
                  onSelected: toggleThemeMode,
                ),
                DashboardMenuAction(
                  id: 'legal',
                  label: l10n.privacyAndAccount,
                  icon: Icons.privacy_tip_outlined,
                  onSelected: () => const LegalLinksButton().show(context),
                ),
                DashboardMenuAction(
                  id: 'logout',
                  label: l10n.logout,
                  icon: Icons.logout,
                  destructive: true,
                  onSelected: _logout,
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _controller.reload,
          child: SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.enrollmentSchoolTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                OutlinedButton.icon(
                  onPressed: _controller.loading || _controller.busy
                      ? null
                      : _controller.reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.enrollmentReload),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('open-school-academics'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AcademicScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(l10n.academicTitle),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('open-school-annual-promotion'),
                  onPressed: _controller.loading || _controller.busy || data == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SchoolAnnualPromotionScreen(),
                          ),
                        ),
                  icon: const Icon(Icons.school_outlined),
                  label: Text(Localizations.localeOf(context).languageCode == 'en'
                      ? 'Annual promotion'
                      : 'الترفيع السنوي'),
                ),
                if (_controller.loading || _controller.busy)
                  const LinearProgressIndicator(),
                if (_controller.saved)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.enrollmentSaved,
                      key: const ValueKey('school-enrollment-saved'),
                    ),
                  ),
                if (_controller.error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      enrollmentFailureMessage(l10n, _controller.error!),
                      key: const ValueKey('school-enrollment-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (data != null) ...[
                  Text(
                    data.identity.school.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${l10n.enrollmentPending}: ${data.requests.where((r) => r.status == EnrollmentStatus.pending).length}',
                  ),
                  Text(
                    l10n.enrollmentRequests,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (data.requests.isEmpty) Text(l10n.enrollmentNoRequests),
                  if (data.sections.isEmpty) Text(l10n.enrollmentNoSections),
                  for (final request in data.requests)
                    EnrollmentRequestCard(
                      request: request,
                      actions: [
                        if (request.status == EnrollmentStatus.pending) ...[
                          FilledButton(
                            key: ValueKey('enrollment-approve-${request.id}'),
                            onPressed:
                                _controller.canWrite && data.sections.isNotEmpty
                                ? () => _decide(request, true)
                                : null,
                            child: Text(l10n.enrollmentApprove),
                          ),
                          OutlinedButton(
                            key: ValueKey('enrollment-reject-${request.id}'),
                            onPressed: _controller.canWrite
                                ? () => _decide(request, false)
                                : null,
                            child: Text(l10n.enrollmentReject),
                          ),
                        ],
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
