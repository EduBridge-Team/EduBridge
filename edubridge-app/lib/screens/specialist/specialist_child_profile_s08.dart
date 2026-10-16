// S08: specialist child profile, API-backed, no fabricated progress values.
part of 'specialist_child_profile_screen.dart';

extension _S08SpecialistChildProfile on _SpecialistChildProfileScreenState {
  Future<void> _loadS08Metrics() async {
    try {
      final responses = await Future.wait([
        ApiService.authGet('/children/$_childId/lessons'),
        ApiService.authGet('/progress/child/$_childId'),
      ]);
      if (!mounted) return;

      int? lessonsCount;
      int? completionPct;
      final lessonResponse = responses[0];
      final progressResponse = responses[1];
      if (lessonResponse.statusCode == 200) {
        final data = ApiService.decodeMap(lessonResponse.body);
        final lessons = data['lessons'];
        if (lessons is List) {
          lessonsCount = lessons.length;
          if (progressResponse.statusCode == 200 && lessons.isNotEmpty) {
            final progressData = ApiService.decodeMap(progressResponse.body);
            final progress = progressData['progress'];
            if (progress is List) {
              final completedIds = <int>{};
              for (final entry in progress) {
                if (entry is Map && entry['status'] == 'done') {
                  final id = int.tryParse((entry['lesson_id'] ?? '').toString());
                  if (id != null) completedIds.add(id);
                }
              }
              final completedVisible = lessons.where((lesson) {
                if (lesson is! Map) return false;
                final id = int.tryParse((lesson['id'] ?? '').toString());
                return id != null && completedIds.contains(id);
              }).length;
              completionPct = (100 * completedVisible / lessons.length).round();
            }
          }
        }
      }
      _updateProfileState(() {
        _s08LessonsCount = lessonsCount;
        _s08CompletionPct = completionPct;
      });
    } catch (_) {
      if (!mounted) return;
      _updateProfileState(() {
        _s08LessonsCount = null;
        _s08CompletionPct = null;
      });
    }
  }

  Widget _buildS08Scaffold(BuildContext context, JisrColors c) {
    final student = _profile;
    final preview = student.isAssignmentPreview;
    final subtitle = [
      if (student.age != null) '${student.age} سنة',
      if (student.disability.isNotEmpty) student.disability,
    ].join(' • ');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF20B6C6), Color(0xFF1769C2)],
                  ),
                ),
              ),
              Positioned(
                left: -36,
                bottom: -58,
                child: Container(
                  width: 138,
                  height: 138,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .22),
                      width: 8,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: -61,
                child: Container(
                  width: 101,
                  height: 101,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                      width: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 64,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'رجوع',
          icon: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _childName.isEmpty ? 'ملف الطالب' : 'ملف $_childName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                _error!,
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
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
                'تظهر المعلومات المتاحة قبل قبول المتابعة. بيانات الهوية والمستندات تظهر بعد التعيين.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            _s08Metrics(c),
            if (!_loading && _error == null && !preview) ...[
              const SizedBox(height: 22),
              _s08Title(c, 'متابعة الطفل'),
              const SizedBox(height: 10),
              _s08Action(
                c,
                icon: Icons.edit_outlined,
                title: 'تقييم الطفل والخطة',
                subtitle: 'إضافة أو مراجعة تقييم الطفل',
                tint: const Color(0xFFDDF5F7),
                accent: const Color(0xFF04AABB),
                onTap: _evaluate,
              ),
              _s08Action(
                c,
                icon: Icons.trending_up_rounded,
                title: 'عرض التقدّم',
                subtitle: 'متابعة إنجاز الطفل وتطوره',
                tint: const Color(0xFFE4F5E7),
                accent: const Color(0xFF37B54A),
                badge: _s08CompletionPct == null
                    ? null : '${_s08CompletionPct}%',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildProgressScreen(
                      childId: _childId, childName: _childName,
                    ),
                  ),
                ),
              ),
              _s08Action(
                c,
                icon: Icons.menu_book_outlined,
                title: 'دروس الطفل',
                subtitle: 'عرض الدروس والمواد التعليمية',
                tint: const Color(0xFFE0EDFC),
                accent: const Color(0xFF1769C2),
                badge: _s08LessonsCount == null
                    ? null : '${_s08LessonsCount} درس',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildLessonsScreen(
                      childId: _childId, childName: _childName,
                    ),
                  ),
                ),
              ),
              _s08Action(
                c,
                icon: Icons.chat_bubble_outline,
                title: 'مناقشة الحالة',
                subtitle: 'التواصل مع فريق متابعة الطفل',
                tint: const Color(0xFFDFF6F8),
                accent: const Color(0xFF02B1C1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CaseDiscussionScreen(filterChildId: _childId),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _s08Title(c, 'تفاصيل الطفل'),
            const SizedBox(height: 10),
            _s08Details(c, 'معلومات الطفل', subtitle, Icons.badge_outlined, [
              _row(c, 'الاسم', _childName, Icons.person_outline),
              if (student.age != null)
                _row(c, 'العمر', '${student.age} سنة', Icons.cake_outlined),
              if (student.birthDate.isNotEmpty)
                _row(c, 'تاريخ الميلاد', student.birthDate, Icons.cake_outlined),
              if (student.gender.isNotEmpty)
                _row(c, 'الجنس', student.gender == 'female' ? 'أنثى' :
                    student.gender == 'male' ? 'ذكر' : student.gender,
                    Icons.person_outline),
              if (student.disability.isNotEmpty)
                _row(c, 'نوع الإعاقة', student.disability,
                    Icons.accessibility_new),
              if (student.description.isNotEmpty)
                _row(c, 'وصف الإعاقة', student.description, AppIcons.info),
              if (student.specialNeeds.isNotEmpty)
                _row(c, 'احتياجات خاصة', student.specialNeeds, AppIcons.support),
              if (student.preferredStyle.isNotEmpty)
                _row(c, 'أسلوب التعلّم', student.preferredStyle, AppIcons.lesson),
              if (student.strengths.isNotEmpty)
                _chips(c, 'نقاط القوة', student.strengths, AppColors.greenDeep),
              if (student.challenges.isNotEmpty)
                _chips(c, 'التحديات', student.challenges, AppColors.orangeDeep),
            ]),
            _s08Details(
              c, 'فريق المتابعة والخطة',
              [student.teacherName, student.specialistNames,
               student.organizationName].where((t) => t.isNotEmpty).join(' • '),
              Icons.groups_outlined,
              [
                if (student.guardianNames.isNotEmpty)
                  _row(c, 'ولي الأمر', student.guardianNames, AppIcons.parent),
                if (student.teacherName.isNotEmpty)
                  _row(c, 'المعلم', student.teacherName, Icons.school_outlined),
                if (student.specialistNames.isNotEmpty)
                  _row(c, 'المختصون', student.specialistNames, AppIcons.specialist),
                if (student.organizationName.isNotEmpty)
                  _row(c, 'المؤسسة', student.organizationName,
                      Icons.business_outlined),
                if (student.educationalPlan.isNotEmpty)
                  _row(c, 'الخطة التعليمية', student.educationalPlan,
                      AppIcons.lesson),
                _row(c, 'الحالة',
                    StudentProfileLabels.specialistStatus(student),
                    Icons.info_outline),
                if (student.notes.isNotEmpty)
                  _row(c, 'ملاحظات', student.notes, AppIcons.info),
              ],
            ),
            if (student.hasDocuments && !preview)
              _s08Details(c, 'المستندات والتوثيق', '',
                  Icons.description_outlined, [
                if (student.childNationalId.isNotEmpty)
                  _row(c, 'هوية الطفل', student.childNationalId,
                      Icons.badge_outlined),
                if (student.guardianNationalId.isNotEmpty)
                  _row(c, 'هوية ولي الأمر', student.guardianNationalId,
                      Icons.badge_outlined),
                if (student.guardianDocument.isNotEmpty)
                  _row(c, 'صورة هوية ولي الأمر', 'مرفقة', Icons.attachment),
                if (student.kinshipDocument.isNotEmpty)
                  _row(c, 'مستند صلة القرابة', 'مرفق', Icons.attachment),
                if (student.medicalReport.isNotEmpty)
                  _row(c, 'التقرير الطبي', 'مرفق', Icons.description_outlined),
              ]),
            if (!_loading && _error == null && !preview)
              _s08Details(c, 'أدوات متابعة إضافية',
                  'نور • التقارير • التكييف', Icons.more_horiz_rounded, [
                _actionTile(
                  c,
                  icon: Icons.auto_awesome_rounded,
                  title: 'اسأل نور عن هذا الطالب',
                  subtitle: 'ملخص ذكي مبني على بيانات الطالب',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentNoorScreen(
                        childId: _childId, childName: _childName,
                      ),
                    ),
                  ),
                ),
                _actionTile(
                  c,
                  icon: AppIcons.report,
                  title: 'التقدم الأسبوعي وتقارير المعلم',
                  subtitle: 'تقارير المعلم وسجل التقدم',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyReportScreen(
                        childId: _childId, childName: _childName,
                      ),
                    ),
                  ),
                ),
                if (_canAdapt)
                  _actionTile(
                    c,
                    icon: Icons.accessibility_new_rounded,
                    title: 'تكييف التعلّم',
                    subtitle: 'ضبط ميزات التكيّف',
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
                    title: 'تقييم الخطة الحالية',
                    subtitle: 'قياس فعالية الخطة التعليمية',
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
              ]),
            if (preview && widget.onAccept != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async => widget.onAccept!(_child),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('قبول متابعة الطفل'),
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

  Widget _s08Metrics(JisrColors c) => Row(
    children: [
      Expanded(child: _s08Metric(c, Icons.check_circle_outline,
          _s08CompletionPct == null ? '—' : '${_s08CompletionPct}%',
          'الإنجاز', const Color(0xFF42B751))),
      const SizedBox(width: 9),
      Expanded(child: _s08Metric(c, Icons.menu_book_outlined,
          _s08LessonsCount?.toString() ?? '—',
          'الدروس', const Color(0xFF1769C2))),
    ],
  );

  Widget _s08Metric(
    JisrColors c, IconData icon, String value, String label, Color accent,
  ) => Container(
    height: 116,
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: c.line),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: accent.withValues(alpha: .12),
          child: Icon(icon, color: accent, size: 19),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
            color: c.heading, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
      ],
    ),
  );

  Widget _s08Action(
    JisrColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required Color accent,
    required VoidCallback onTap,
    String? badge,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      color: c.heading,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(badge, style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  )),
                ),
              Icon(Icons.chevron_left_rounded, color: c.muted, size: 21),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _s08Details(
    JisrColors c,
    String title,
    String subtitle,
    IconData icon,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          leading: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EFFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.brandBlue, size: 23),
          ),
          title: Text(title, style: TextStyle(
            color: c.heading, fontSize: 15,
            fontWeight: FontWeight.w900,
          )),
          subtitle: subtitle.isEmpty ? null : Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          children: children,
        ),
      ),
    ),
  );
}
