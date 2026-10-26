import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_academic_records.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/institution_academic_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_state.dart';
import 'institution_academic_content.dart';

class InstitutionAcademicScreen extends StatefulWidget {
  const InstitutionAcademicScreen({
    super.key,
    required this.organizationSlug,
    required this.schoolId,
    this.gateway,
  });
  final String organizationSlug;
  final int schoolId;
  final InstitutionAcademicGateway? gateway;
  @override
  State<InstitutionAcademicScreen> createState() =>
      _InstitutionAcademicScreenState();
}

class _InstitutionAcademicScreenState extends State<InstitutionAcademicScreen>
    with WidgetsBindingObserver {
  late EnrollmentState<InstitutionAcademicRecords> _state;
  void _initialize() {
    final slug = widget.organizationSlug, school = widget.schoolId;
    final gateway =
        widget.gateway ??
        InstitutionAcademicRepository(organizationSlug: slug, schoolId: school);
    _state = EnrollmentState(() async {
      final data = await gateway.load();
      if (data.organizationSlug != slug || data.school.id != school) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      return data;
    });
    _state.reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant InstitutionAcademicScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolId != widget.schoolId ||
        oldWidget.organizationSlug != widget.organizationSlug ||
        oldWidget.gateway != widget.gateway) {
      _state.dispose();
      _initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final l = context.l10n;
      final data = _state.snapshot;
      final error = switch (_state.error) {
        null => null,
        EnrollmentFailure.session => l.enrollmentSession,
        EnrollmentFailure.forbidden => l.institutionAcademicForbidden,
        EnrollmentFailure.invalidResponse => l.institutionAcademicInvalid,
        _ => l.institutionAcademicFailed,
      };
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(
            l.institutionAcademicTitle,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          actions: [
            IconButton(
              tooltip: l.enrollmentReload,
              onPressed: _state.loading ? null : _state.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _state.reload,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_state.loading) const LinearProgressIndicator(),
                    if (error != null)
                      Semantics(liveRegion: true, child: Text(error)),
                    if (data != null)
                      InstitutionAcademicContent(
                        key: ValueKey((
                          widget.organizationSlug,
                          widget.schoolId,
                        )),
                        records: data,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
