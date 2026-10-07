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
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('الخطوة ${_page + 1} من 3'),
          TextButton(onPressed: _leaveTour, child: const Text('تخطي')),
        ])),
      Expanded(child: PageView.builder(controller: _controller, itemCount: 3,
        onPageChanged: (index) { setState(() => _page = index); _reveal(); },
        itemBuilder: (_, index) => SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
            child: Column(children: [
              _motion(0, _floatingIllustration(index), active: index == _page), const SizedBox(height: 28),
              _motion(.15, Text(titles[index], textAlign: TextAlign.center, style: const TextStyle(
                color: _WelcomeScreenState._blue, fontSize: 27, height: 1.4, fontWeight: FontWeight.w800)), active: index == _page),
              const SizedBox(height: 14), _motion(.3, Text(descriptions[index], textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.8)), active: index == _page),
            ]))))),
      Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
          duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _page ? 26 : 8, height: 8, decoration: BoxDecoration(
            color: i == _page ? _WelcomeScreenState._blue : const Color(0xFFD9EBF0), borderRadius: BorderRadius.circular(8))))),
        const SizedBox(height: 16),
        _button(_page == 2 ? 'ابدأ' : 'التالي', _page == 2 ? Icons.check : Icons.arrow_back, () {
          if (_page == 2) { _authenticate(); }
          else { _movePage(1); }
        }),
        TextButton(onPressed: () {
          if (_page == 0) { _leaveTour(); }
          else { _movePage(-1); }
        }, child: Text(_page == 0 ? 'العودة' : 'السابق')),
      ])),
    ]);
  }

  Widget _illustration(int index) => SizedBox(height: 260, width: 300, child: Stack(alignment: Alignment.center, children: [
    Container(width: 220, height: 220, decoration: const BoxDecoration(color: Color(0xFFE3F8FA), shape: BoxShape.circle)),
    if (index == 0) ...[
      Container(width: 180, padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 20)]),
        child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_circle, color: _WelcomeScreenState._blue, size: 54),
          SizedBox(height: 14), LinearProgressIndicator(value: .8), SizedBox(height: 16), Text('استمع', style: TextStyle(color: _WelcomeScreenState._blue))])),
      Positioned(top: 12, right: 0, child: _label('قراءة صوتية', Icons.volume_up_outlined)),
      Positioned(left: 0, top: 112, child: _label('ألوان هادئة', Icons.palette_outlined)),
      Positioned(bottom: 8, right: 0, child: _label('رموز أكبر', Icons.text_fields)),
    ] else if (index == 1) ...[
      const CircleAvatar(radius: 46, backgroundColor: _WelcomeScreenState._blue, child: Icon(Icons.person_outline, size: 54, color: Colors.white)),
      Positioned(top: 0, right: 16, child: _person('المعلم', Icons.school_outlined, _WelcomeScreenState._teal)),
      Positioned(top: 0, left: 16, child: _person('ولي الأمر', Icons.family_restroom, _WelcomeScreenState._blue)),
      Positioned(bottom: 0, child: _person('المختص', Icons.psychology_outlined, const Color(0xFF56A447))),
    ] else ...[
      const Icon(Icons.verified_user, color: _WelcomeScreenState._blue, size: 142),
      Positioned(bottom: 40, right: 0, child: _label('استراحة حركية', Icons.accessibility_new)),
      Positioned(bottom: 0, left: 0, child: _label('طوارئ', Icons.notifications_active_outlined)),
    ],
  ]));

  Widget _label(String text, IconData icon) => Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 14)]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: _WelcomeScreenState._teal, size: 22),
      const SizedBox(width: 8), Text(text, style: const TextStyle(color: _WelcomeScreenState._blue, fontWeight: FontWeight.w700))]));

  Widget _person(String text, IconData icon, Color color) => Column(children: [
    CircleAvatar(radius: 30, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 30)),
    const SizedBox(height: 6), Text(text, style: const TextStyle(color: _WelcomeScreenState._blue)),
  ]);
}
