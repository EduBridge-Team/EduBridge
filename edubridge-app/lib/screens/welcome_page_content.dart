part of 'welcome_screen.dart';

extension _WelcomePageContent on _WelcomeScreenState {
  Widget _card(String title, String description, IconData icon, Color tint,
      {bool vision = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: dark ? const Color(0xFF1A3041) : vision ? const Color(0xFFE4F8FB) : Colors.white,
        borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFDDEBEF))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
          color: tint, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: _WelcomeScreenState._blue, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: dark ? Colors.lightBlue.shade200 : _WelcomeScreenState._blue,
            fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), Text(description, style: const TextStyle(fontSize: 16, height: 1.8)),
        ])),
      ]));
  }

  Widget _buildAbout() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 14),
    _card('رؤية بلا حدود', 'نسعى أن نكون المرجع الأول في الوطن العربي للتعليم الرقمي المتاح، حيث تذوب الفوارق الجسدية وتبرز القدرات العقلية والإبداعية.', Icons.visibility_outlined, const Color(0xFFD9F5FA), vision: true),
    _card('الدعم المستمر', 'مرافقة المتعلم في كل خطوة لضمان النجاح.', Icons.favorite_border, const Color(0xFFE3F8FA)),
    _card('تنوع المناهج', 'محتوى تعليمي يناسب مختلف أنواع الإعاقات.', Icons.menu_book_outlined, const Color(0xFFE7F3E3)),
    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('مسارات تعليمية متخصصة',
      style: TextStyle(color: _WelcomeScreenState._blue, fontSize: 24, fontWeight: FontWeight.w800))),
    _card('لغة الإشارة المتقدمة', 'دورة شاملة لتعلم لغة الإشارة من الأساسيات وحتى الاحتراف.', Icons.front_hand_outlined, const Color(0xFFE3F8FA)),
    _card('تقنيات القراءة الميسّرة', 'تدريب عملي لتعزيز استقلالية القراءة والتعلم لكل طفل.', Icons.menu_book_outlined, const Color(0xFFE7F3E3)),
    _card('المهارات الحياتية الرقمية', 'برنامج مخصص لتمكين الأطفال ذوي الإعاقات الإدراكية من التعامل مع العالم الرقمي بأمان.', Icons.extension_outlined, const Color(0xFFFFF1DF)),
    _button('اكتشف تجربة EduBridge', Icons.arrow_back, _startTour),
    const SizedBox(height: 12),
  ]);

  Widget _buildTour() {
    const titles = ['تعليم يتكيف مع كل طفل', 'أسرة ومعلم ومختص\nفي مكان واحد', 'بيئة آمنة ومريحة'];
    const descriptions = [
      'قراءة صوتية، ألوان هادئة، ورموز أكبر — نضبط حسب ما يساعد طفلك.',
      'تابعوا تقدم الطفل، وتبادلوا الرسائل والتقييمات بسهولة.',
      'استراحات حركية بين الدروس، وزر طوارئ يبلغ الأهل والمختص فوراً.',
    ];
    return Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text('الخطوة ${_page + 1} من 3')),
            const SizedBox(width: 12),
            TextButton(onPressed: _leaveTour, child: const Text('تخطي')),
          ])),
        Expanded(child: PageView.builder(controller: _controller, itemCount: 3,
          onPageChanged: _onTourPageChanged,
          itemBuilder: (_, index) => LayoutBuilder(builder: (context, viewport) {
            return SingleChildScrollView(
              key: ValueKey('onboarding-step-${index + 1}'),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0.0, viewport.maxHeight - 32)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: _illustration(index)),
                  const SizedBox(height: 20),
                  _motion(.15, Text(titles[index], textAlign: TextAlign.center,
                    style: const TextStyle(color: _WelcomeScreenState._blue,
                      fontSize: 24, height: 1.35, fontWeight: FontWeight.w800)),
                    active: index == _page),
                  const SizedBox(height: 10),
                  _motion(.3, Text(descriptions[index], textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.65)),
                    active: index == _page),
                ]),
              ),
            );
          }))),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 26 : 8, height: 8,
                decoration: BoxDecoration(color: i == _page
                  ? _WelcomeScreenState._blue : const Color(0xFFD9EBF0),
                  borderRadius: BorderRadius.circular(8))))),
            const SizedBox(height: 12),
            _button(_page == 2 ? 'ابدأ' : 'التالي',
              _page == 2 ? Icons.check : Icons.arrow_back, () {
                if (_page == 2) { _leaveTour(); }
                else { _movePage(1); }
              }),
            const SizedBox(height: 8),
            if (_page > 0) TextButton(onPressed: () => _movePage(-1),
              child: const Text('السابق'))
            else const SizedBox(height: 48),
          ])),
      ]),
    ));
  }

  Widget _illustration(int index) => SizedBox(
    height: index == 1 ? 300 : 280, width: 300,
    child: Stack(alignment: Alignment.center, children: [
      _artMotion(index, 0, Container(width: 220, height: 220,
        decoration: const BoxDecoration(color: Color(0xFFE3F8FA),
          shape: BoxShape.circle)), vertical: 0, pulse: true, pulseAmplitude: index == 1 ? .08 : .012),
      if (index == 0) ...[
        _artMotion(index, 1, Container(width: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 20)]),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_circle, color: _WelcomeScreenState._blue, size: 54),
            SizedBox(height: 14), LinearProgressIndicator(value: .8),
            SizedBox(height: 16), Text('استمع', style: TextStyle(color: _WelcomeScreenState._blue)),
          ])), vertical: 2),
        Positioned(top: 8, right: 0, child: _artMotion(index, 2,
          _label('قراءة صوتية', Icons.volume_up_outlined, toggle: true), horizontal: 2)),
        Positioned(left: 0, top: 116, child: _artMotion(index, 3,
          _label('ألوان هادئة', Icons.palette_outlined, toggle: true), horizontal: -2, vertical: 2)),
        Positioned(bottom: 8, right: 0, child: _artMotion(index, 4,
          _label('رموز أكبر', Icons.text_fields, toggle: true), vertical: 3)),
      ] else if (index == 1) ...[
        const Positioned.fill(child: IgnorePointer(child: CustomPaint(
          painter: _FamilyConnectionsPainter()))),
        _artMotion(index, 1, const CircleAvatar(radius: 46,
          backgroundColor: _WelcomeScreenState._blue,
          child: Icon(Icons.person_outline, size: 54, color: Colors.white)), vertical: 2),
        Positioned(top: 0, right: 16, child: _artMotion(index, 2,
          _person('المعلم', Icons.school_outlined, _WelcomeScreenState._teal), horizontal: 2)),
        Positioned(top: 0, left: 16, child: _artMotion(index, 3,
          _person('ولي الأمر', Icons.family_restroom, _WelcomeScreenState._blue), horizontal: -2)),
        Positioned(bottom: 0, left: 72, child: _artMotion(index, 4,
          _person('المختص', Icons.psychology_outlined, AppColors.brandGreenDeep), vertical: 2)),
      ] else ...[
        _artMotion(index, 1, const Icon(Icons.verified_user,
          color: _WelcomeScreenState._blue, size: 142), vertical: 2, pulse: true),
        Positioned(bottom: 44, right: 0, child: _artMotion(index, 2,
          _label('استراحة حركية', Icons.accessibility_new), horizontal: 2)),
        Positioned(bottom: 0, left: 0, child: _artMotion(index, 3,
          _label('طوارئ', Icons.notifications_active_outlined, emergency: true), vertical: 2)),
      ],
    ]),
  );

  Widget _label(String text, IconData icon, {bool toggle = false, bool emergency = false}) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: emergency ? const Color(0xFFC73535) : Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 14)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: emergency ? Colors.white : _WelcomeScreenState._teal, size: 22),
      const SizedBox(width: 8), Text(text, style: TextStyle(
        color: emergency ? Colors.white : _WelcomeScreenState._blue, fontWeight: FontWeight.w700)),
      if (toggle) ...[
        const SizedBox(width: 8),
        Container(width: 42, height: 24, alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: _WelcomeScreenState._teal,
            borderRadius: BorderRadius.circular(20)),
          child: const DecoratedBox(decoration: BoxDecoration(color: Colors.white,
            shape: BoxShape.circle), child: SizedBox(width: 18, height: 18))),
      ],
    ]));

  Widget _person(String text, IconData icon, Color color) => Column(children: [
    CircleAvatar(radius: 30, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 30)),
    const SizedBox(height: 6), Text(text, style: const TextStyle(color: _WelcomeScreenState._blue)),
  ]);
}

// Draw behind the avatars, stopping at their edges so the icons stay clear.
class _FamilyConnectionsPainter extends CustomPainter {
  const _FamilyConnectionsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2);
    final targets = [
      Offset(size.width - 46, 30),
      const Offset(46, 30),
      Offset(102, size.height - 54),
    ];
    final paint = Paint()
      ..color = AppColors.brandTealDeep.withValues(alpha: .65)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final target in targets) {
      final vector = target - origin;
      final length = vector.distance;
      final direction = vector / length;
      final start = origin + direction * 49;
      final end = target - direction * 33;
      final distance = (end - start).distance;
      for (double offset = 0; offset < distance; offset += 12) {
        canvas.drawLine(start + direction * offset,
          start + direction * math.min(offset + 6, distance), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FamilyConnectionsPainter oldDelegate) => false;
}
