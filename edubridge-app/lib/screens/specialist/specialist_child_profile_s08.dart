// S08: specialist child profile, API-backed, no fabricated progress values.
part of 'specialist_child_profile_screen.dart';

extension _S08SpecialistChildProfile on _SpecialistChildProfileScreenState {
  Widget _buildS08Scaffold(BuildContext context, JisrColors c) {
    final student = _profile;
    final preview = student.isAssignmentPreview;
    final subtitle = [
      if (student.age != null)
        context.l10n.childAgeYears(student.age.toString()),
      if (student.disability.isNotEmpty) student.disability,
    ].join(' • ');
    return Scaffold(
      appBar: BrandAppBar(
        toolbarHeight: 96,
        centerTitle: false,
        leading: IconButton(
          tooltip: context.l10n.back,
          icon: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _childName.isEmpty
              ? context.l10n.studentProfile
              : context.l10n.studentProfileFor(_childName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          children: [
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              Text(
                context.sharedMessage(_error),
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _load,
                child: Text(context.l10n.retryAction),
              ),
              const SizedBox(height: 12),
            ],
            _heroCard(
              c,
              age: student.age,
              disability: student.disability,
              isPreview: preview,
            ),
            if (preview) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.previewInformationNotice,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            StudentLearningMetricsCards(
              lessonsCount: _s08LessonsCount,
              completionPercent: _s08CompletionPct,
            ),
            if (!_loading && _error == null && !preview) ...[
              const SizedBox(height: 22),
              _s08Title(c, context.l10n.childFollowUp),
              const SizedBox(height: 10),
              StudentProfileActionCard(
                icon: Icons.edit_outlined,
                title: context.l10n.evaluateChildPlan,
                subtitle: context.l10n.addReviewChildEvaluation,
                tint: const Color(0xFFDDF5F7),
                accent: const Color(0xFF04AABB),
                onTap: _evaluate,
              ),
              StudentProfileActionCard(
                icon: Icons.trending_up_rounded,
                title: context.l10n.viewProgress,
                subtitle: context.l10n.trackChildDevelopment,
                tint: const Color(0xFFE4F5E7),
                accent: const Color(0xFF37B54A),
                badge: _s08CompletionPct == null ? null : '$_s08CompletionPct%',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildProgressScreen(
                      childId: _childId,
                      childName: _childName,
                    ),
                  ),
                ),
              ),
              StudentProfileActionCard(
                icon: Icons.menu_book_outlined,
                title: context.l10n.childLessons,
                subtitle: context.l10n.viewLessonsMaterials,
                tint: const Color(0xFFE0EDFC),
                accent: const Color(0xFF1769C2),
                badge: _s08LessonsCount == null
                    ? null
                    : context.l10n.profileLessonCount(_s08LessonsCount!),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildLessonsScreen(
                      childId: _childId,
                      childName: _childName,
                      specialistS10: true,
                    ),
                  ),
                ),
              ),
              StudentProfileActionCard(
                icon: Icons.lightbulb_outline_rounded,
                title: context.l10n.recommendSupportSpecialist,
                subtitle: context.l10n.recommendSpecialistForChild,
                tint: const Color(0xFFE0EDFC),
                accent: const Color(0xFF1769C2),
                onTap: () async {
                  final sent = await showChildSpecialistSuggestion(
                    context,
                    child: _child,
                  );
                  if (sent && mounted) await _load();
                },
              ),
              StudentProfileActionCard(
                icon: Icons.chat_bubble_outline,
                title: context.l10n.discussCase,
                subtitle: context.l10n.contactChildCareTeam,
                tint: const Color(0xFFDFF6F8),
                accent: const Color(0xFF02B1C1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaseDiscussionScreen(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _s08Title(c, context.l10n.childDetails),
            const SizedBox(height: 10),
            StudentProfileDetailsSection(
              title: context.l10n.childInformation,
              subtitle: subtitle,
              icon: Icons.badge_outlined,
              children: [
                _row(c, context.l10n.name, _childName, Icons.person_outline),
                if (student.age != null)
                  _row(
                    c,
                    context.l10n.age,
                    context.l10n.childAgeYears(student.age.toString()),
                    Icons.cake_outlined,
                  ),
                if (student.birthDate.isNotEmpty)
                  _row(
                    c,
                    context.l10n.birthDate,
                    student.birthDate,
                    Icons.cake_outlined,
                  ),
                if (student.gender.isNotEmpty)
                  _row(
                    c,
                    context.l10n.gender,
                    student.gender == 'female'
                        ? context.l10n.female
                        : student.gender == 'male'
                        ? context.l10n.male
                        : student.gender,
                    Icons.person_outline,
                  ),
                if (student.disability.isNotEmpty)
                  _row(
                    c,
                    context.l10n.disabilityType,
                    student.disability,
                    Icons.accessibility_new,
                  ),
                if (student.description.isNotEmpty)
                  _row(
                    c,
                    context.l10n.disabilityDescription,
                    student.description,
                    AppIcons.info,
                  ),
                if (student.specialNeeds.isNotEmpty)
                  _row(
                    c,
                    context.l10n.specialNeeds,
                    student.specialNeeds,
                    AppIcons.support,
                  ),
                if (student.preferredStyle.isNotEmpty)
                  _row(
                    c,
                    context.l10n.learningStyle,
                    student.preferredStyle,
                    AppIcons.lesson,
                  ),
                if (student.strengths.isNotEmpty)
                  _chips(
                    c,
                    context.l10n.strengths,
                    student.strengths,
                    AppColors.greenDeep,
                  ),
                if (student.challenges.isNotEmpty)
                  _chips(
                    c,
                    context.l10n.challenges,
                    student.challenges,
                    AppColors.orangeDeep,
                  ),
              ],
            ),
            StudentProfileDetailsSection(
              title: context.l10n.followUpTeamPlan,
              subtitle: [
                student.teacherName,
                student.specialistNames,
                student.organizationName,
              ].where((t) => t.isNotEmpty).join(' • '),
              icon: Icons.groups_outlined,
              children: [
                if (student.guardianNames.isNotEmpty)
                  _row(
                    c,
                    context.l10n.parentRole,
                    student.guardianNames,
                    AppIcons.parent,
                  ),
                if (student.teacherName.isNotEmpty)
                  _row(
                    c,
                    context.l10n.teacherRole,
                    student.teacherName,
                    Icons.school_outlined,
                  ),
                if (student.specialistNames.isNotEmpty)
                  _row(
                    c,
                    context.l10n.specialists,
                    student.specialistNames,
                    AppIcons.specialist,
                  ),
                if (student.organizationName.isNotEmpty)
                  _row(
                    c,
                    context.l10n.institutionRole,
                    student.organizationName,
                    Icons.business_outlined,
                  ),
                if (student.educationalPlan.isNotEmpty)
                  _row(
                    c,
                    context.l10n.educationalPlan,
                    student.educationalPlan,
                    AppIcons.lesson,
                  ),
                _row(
                  c,
                  context.l10n.status,
                  StudentProfileLabels.specialistStatus(
                    student,
                    strings: context.l10n,
                  ),
                  Icons.info_outline,
                ),
                if (student.notes.isNotEmpty)
                  _row(c, context.l10n.notes, student.notes, AppIcons.info),
              ],
            ),
            if (student.hasDocuments && !preview)
              StudentProfileDetailsSection(
                title: context.l10n.documentsVerification,
                subtitle: '',
                icon: Icons.description_outlined,
                children: [
                  if (student.childNationalId.isNotEmpty)
                    _row(
                      c,
                      context.l10n.childNationalId,
                      student.childNationalId,
                      Icons.badge_outlined,
                    ),
                  if (student.guardianNationalId.isNotEmpty)
                    _row(
                      c,
                      context.l10n.guardianNationalId,
                      student.guardianNationalId,
                      Icons.badge_outlined,
                    ),
                  if (student.guardianDocument.isNotEmpty)
                    _row(
                      c,
                      context.l10n.guardianIdPhoto,
                      context.l10n.attached,
                      Icons.attachment,
                    ),
                  if (student.kinshipDocument.isNotEmpty)
                    _row(
                      c,
                      context.l10n.kinshipDocument,
                      context.l10n.attached,
                      Icons.attachment,
                    ),
                  if (student.medicalReport.isNotEmpty)
                    _row(
                      c,
                      context.l10n.medicalReport,
                      context.l10n.attached,
                      Icons.description_outlined,
                    ),
                ],
              ),
            if (!_loading && _error == null && !preview)
              StudentProfileDetailsSection(
                title: context.l10n.additionalFollowUpTools,
                subtitle: context.l10n.noorReportsAdaptation,
                icon: Icons.more_horiz_rounded,
                children: [
                  _actionTile(
                    c,
                    icon: Icons.auto_awesome_rounded,
                    title: context.l10n.askNoorAboutStudent,
                    subtitle: context.l10n.studentDataSummary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentNoorScreen(
                          childId: _childId,
                          childName: _childName,
                        ),
                      ),
                    ),
                  ),
                  _actionTile(
                    c,
                    icon: AppIcons.report,
                    title: context.l10n.weeklyProgressTeacherReports,
                    subtitle: context.l10n.teacherReportsProgressHistory,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeeklyReportScreen(
                          specialistS26: true,
                          childId: _childId,
                          childName: _childName,
                        ),
                      ),
                    ),
                  ),
                  if (_canAdapt)
                    _actionTile(
                      c,
                      icon: Icons.accessibility_new_rounded,
                      title: context.l10n.adaptLearning,
                      subtitle: context.l10n.adjustAdaptationFeatures,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildAccessibilitySettingsScreen(
                            childId: _childId,
                            childName: _childName,
                            disabilityTypeHint: student.disability,
                          ),
                        ),
                      ),
                    ),
                  if (student.currentPlanId != null)
                    _actionTile(
                      c,
                      icon: Icons.fact_check_outlined,
                      title: context.l10n.evaluateCurrentPlan,
                      subtitle: context.l10n.measurePlanEffectiveness,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanEvaluationScreen(
                            childId: _childId,
                            childName: _childName,
                            planId: student.currentPlanId!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            if (preview && widget.onAccept != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async => widget.onAccept!(_child),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n.acceptChildFollowUp),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _s08Title(JisrColors c, String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 3),
    child: Text(
      label,
      style: TextStyle(
        color: c.heading,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
