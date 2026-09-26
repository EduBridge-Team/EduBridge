// Voice command execution extracted from voice_command_routing.dart.
part of 'voice_command_service.dart';

extension _VoiceCommandExecutionExtension on VoiceCommandService {
  Future<void> _executeCommand(String rawText) async {
    final text = _normalize(rawText);
    final nav = appNavigatorKey.currentState;

    // ═══ 1. القراءة باللمس ═══
    if (_matches(text, [
      'اقرا', 'اقراء', 'قراءه', 'قرايه',
      'شغل القراءه', 'فعل القراءه', 'ابدا القراءه', 'وضع القراءه',
    ])) {
      if (!TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('وضع القراءة باللمس مُفعّل');
      return;
    }
    if (_matches(text, ['اوقف القراءه', 'اقفل القراءه', 'الغ القراءه'])) {
      if (TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('أوقفت وضع القراءة');
      return;
    }

    // ═══ 2. الإيقاف ═══
    if (_matches(text, ['اوقف', 'اسكت', 'سكوت', 'هدوء', 'صمت'])) {
      await TtsService.instance.stop();
      await _reply('تم الإيقاف');
      return;
    }

    // ═══ 3. التحقق من التنقل ═══
    if (nav == null) {
      await _reply('تعذّر التنقل');
      return;
    }

    // ═══ 4. الرئيسية / الرجوع ═══
    if (_matches(text, [
      'رئيسيه', 'الرئيسيه', 'رئيسي', 'الصفحه الاولى',
      'البدايه', 'هوم',
    ])) {
      await _reply('سأرجع للرئيسية');
      nav.popUntil((r) => r.isFirst);
      return;
    }
    if (_matches(text, ['ارجع', 'رجوع', 'للخلف', 'خلف', 'باك'])) {
      if (nav.canPop()) {
        nav.pop();
        await _reply('رجعت للخلف');
      } else {
        await _reply('لا يوجد شيء للرجوع');
      }
      return;
    }

    // ═══ 5. الثيم ═══
    if (_matches(text, ['ليلي', 'الليلي', 'ظلام', 'داكن', 'مظلم'])) {
      if (jisrThemeMode.value != ThemeMode.dark) await toggleThemeMode();
      await _reply('بدّلت للوضع الليلي');
      return;
    }
    if (_matches(text, ['فاتح', 'الفاتح', 'نهاري', 'نهار', 'صبح'])) {
      if (jisrThemeMode.value != ThemeMode.light) await toggleThemeMode();
      await _reply('بدّلت للوضع الفاتح');
      return;
    }

    // ═══ 6. الأوامر الخاصة بالطفل (قبل العامة) ═══
    await _ensureChildrenLoaded();

    if (await _tryExecuteChildCommand(text, nav)) return;

    // ═══ 7. الألعاب ═══
    final gameId = _detectGame(text);
    if (gameId != null) {
      final widget = _gameWidgetFor(gameId);
      if (widget != null) {
        await _reply('سأفتح ${_gameDisplayName(gameId)}');
        nav.push(MaterialPageRoute(builder: (_) => widget));
        return;
      }
    }

    if (_matches(text, [
      'الالعاب', 'العاب', 'قائمه الالعاب', 'شاشه الالعاب', 'العب',
    ])) {
      await _reply('سأفتح شاشة الألعاب');
      nav.push(MaterialPageRoute(
        builder: (_) => const EducationalGamesScreen(
          childName: 'بطل',
          age: 8,
        ),
      ));
      return;
    }

    // ═══ 8. الشاشات العامة ═══
    if (_matches(text, [
      'الاطفال', 'اطفال', 'الاولاد', 'اولاد', 'قائمه الاطفال',
    ])) {
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    if (_matches(text, [
      'دروس ولي الامر', 'دروس لولي الامر', 'دروس للاهل', 'نصائح',
    ])) {
      await _reply('سأفتح دروس ولي الأمر');
      nav.push(MaterialPageRoute(
        builder: (_) => const ParentLessonsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'اشعارات', 'الاشعارات', 'تنبيهات', 'جرس',
    ])) {
      await _reply('سأفتح الإشعارات');
      nav.push(MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'محادثات', 'المحادثات', 'رسائل', 'شات',
    ])) {
      await _reply('سأفتح المحادثات');
      nav.push(MaterialPageRoute(builder: (_) => const ChatsScreen()));
      return;
    }

    if (_matches(text, [
      'مساعد', 'المساعد', 'نور', 'روبوت', 'اسال',
    ])) {
      await _reply('سأفتح المساعد نور');
      nav.push(MaterialPageRoute(
        builder: (_) => const AssistantScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'احتياجات', 'الاحتياجات', 'احتياجات الابناء', 'تخصيص',
    ])) {
      await _reply('سأفتح احتياجات الأبناء');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'الملف الشخصي', 'ملفي', 'بروفايل', 'حسابي',
    ])) {
      await _reply('سأفتح ملفك الشخصي');
      nav.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }

    if (_matches(text, [
      'كلمه المرور', 'كلمة السر', 'الباسورد',
    ])) {
      await _reply('سأفتح تغيير كلمة المرور');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'توثيق', 'توثيق الهويه', 'تحقق', 'هويتي',
    ])) {
      await _reply('سأفتح توثيق الهوية');
      nav.push(MaterialPageRoute(
        builder: (_) => const VerifyIdentityScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'جلسات', 'الجلسات', 'اجتماعات دعم', 'اجتماعات الدعم',
    ])) {
      await _reply('سأفتح الجلسات');
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportMeetingsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'طلبات', 'الطلبات', 'طلبات الدعم',
    ])) {
      await _reply('سأفتح طلبات الدعم');
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportRequestsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'تواصل', 'التواصل', 'تواصل بالصور', 'aac',
    ])) {
      await _reply('سأفتح التواصل بالصور');
      nav.push(MaterialPageRoute(
        builder: (_) => const AACCommunicationScreen(childName: 'بطل'),
      ));
      return;
    }

    if (_matches(text, [
      'اضف طفل', 'اضافه طفل', 'ضيف طفل', 'طفل جديد',
    ])) {
      final role = await ApiService.getRole();
      if (role != 'parent' && role != 'admin') {
        await _reply('إضافة طفل متاحة لولي الأمر والأدمن فقط');
        return;
      }
      await _reply('سأفتح إضافة طفل جديد');
      nav.push(MaterialPageRoute(
        builder: (_) => const AddChildScreen(),
      ));
      return;
    }

    if (_matches(text, ['دروس عامه', 'الدروس العامه', 'مكتبه الدروس'])) {
      await _reply('سأفتح مكتبة الدروس');
      nav.push(MaterialPageRoute(builder: (_) => const LessonsScreen()));
      return;
    }

    // ═══ 9. المساعدة ═══
    if (_matches(text, [
      'مساعده', 'مساعدة', 'اوامر', 'الاوامر', 'ساعدني',
    ])) {
      await _reply(
        'تقدر تقول: '
        'افتح دروس [اسم الطفل]، افتح واجبات [اسم الطفل]، '
        'افتح تقدم [اسم الطفل]، افتح تقرير [اسم الطفل]، '
        'افتح دراسة حالة [اسم الطفل]. '
        'كمان: الألعاب، الأطفال، الإشعارات، المحادثات، المساعد، '
        'التواصل بالصور، دروس ولي الأمر، احتياجات الأبناء، '
        'الملف الشخصي، توثيق الهوية. '
        'وتقدر تقول: اقرأ، أوقف، ارجع، الرئيسية، الوضع الليلي',
      );
      return;
    }

    // ═══ غير مفهوم ═══
    await _reply(
      'سمعتك تقول: $rawText. جرّب: افتح دروس محمد، أو افتح الألعاب',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الألعاب
  // ═══════════════════════════════════════════════════════════
}
