// Voice command execution extracted from voice_command_routing.dart.
part of 'voice_command_service.dart';

extension _VoiceCommandExecutionExtension on VoiceCommandService {
  Future<void> _executeCommand(String rawText) async {
    final userId = await ApiService.getUserId();
    if (userId == null) { await _reply(_strings.voiceCommandSignIn); return; }
    final text = _normalize(rawText);
    final nav = appNavigatorKey.currentState;

    // ═══ 1. القراءة باللمس ═══
    if (_matches(text, ['اوقف القراءه', 'اقفل القراءه', 'الغ القراءه'])) {
      if (TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply(_strings.voiceCommandReadingOff);
      return;
    }

    if (_matches(text, [
      'اقرا', 'اقراء', 'قراءه', 'قرايه',
      'شغل القراءه', 'فعل القراءه', 'ابدا القراءه', 'وضع القراءه',
    ])) {
      if (!TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply(_strings.voiceCommandReadingOn);
      return;
    }
    // ═══ 2. الإيقاف ═══
    if (_matches(text, ['اوقف', 'اسكت', 'سكوت', 'هدوء', 'صمت'])) {
      await TtsService.instance.stop();
      await _reply(_strings.voiceCommandStopped);
      return;
    }

    // ═══ 3. التحقق من التنقل ═══
    if (nav == null) {
      await _reply(_strings.voiceCommandNavigationFailed);
      return;
    }

    // ═══ 4. الرئيسية / الرجوع ═══
    if (_matches(text, [
      'رئيسيه', 'الرئيسيه', 'رئيسي', 'الصفحه الاولى',
      'البدايه', 'هوم',
    ])) {
      await _reply(_strings.voiceCommandHome);
      nav.popUntil((r) => r.isFirst);
      return;
    }
    if (_matches(text, ['ارجع', 'رجوع', 'للخلف', 'خلف', 'باك'])) {
      if (nav.canPop()) {
        nav.pop();
        await _reply(_strings.voiceCommandBack);
      } else {
        await _reply(_strings.voiceCommandNoBack);
      }
      return;
    }

    // ═══ 5. الثيم ═══
    if (_matches(text, ['ليلي', 'الليلي', 'ظلام', 'داكن', 'مظلم'])) {
      if (jisrThemeMode.value != ThemeMode.dark) await toggleThemeMode();
      await _reply(_strings.voiceCommandDark);
      return;
    }
    if (_matches(text, ['فاتح', 'الفاتح', 'نهاري', 'نهار', 'صبح'])) {
      if (jisrThemeMode.value != ThemeMode.light) await toggleThemeMode();
      await _reply(_strings.voiceCommandLight);
      return;
    }

    final role = await ApiService.getRole();
    final accountCommand = _matches(text, ['الملف الشخصي', 'ملفي', 'بروفايل', 'حسابي', 'كلمه المرور', 'كلمه السر', 'الباسورد', 'توثيق', 'توثيق الهويه', 'تحقق', 'هويتي']);
    if (accountCommand) {
      if (await ApiService.getUserId() != userId) return;
      final Widget screen;
      if (_matches(text, ['توثيق', 'توثيق الهويه', 'تحقق', 'هويتي'])) {
        screen = const VerifyIdentityScreen();
      } else if (_matches(text, ['كلمه المرور', 'كلمه السر', 'الباسورد'])) {
        screen = const ChangePasswordScreen();
      } else {
        screen = const ProfileScreen();
      }
      await _reply(_strings.voiceCommandAccount);
      nav.push(MaterialPageRoute(builder: (_) => screen));
      return;
    }
    if (!['admin', 'parent'].contains(role) && !await ApiService.isVerified()) {
      if (await ApiService.getUserId() != userId) return;
      await _reply(_strings.voiceCommandVerify);
      nav.push(MaterialPageRoute(builder: (_) => const VerifyIdentityScreen()));
      return;
    }
    if (await ApiService.getUserId() != userId) return;
    final childRole = ['parent', 'teacher', 'specialist', 'admin'].contains(role);
    if (_matches(text, ['دروس ولي الامر', 'دروس لولي الامر', 'دروس للاهل', 'نصائح', 'دروس عامه', 'الدروس العامه', 'مكتبه الدروس'])) {
      final parentLessons = !_matches(text, ['دروس عامه', 'الدروس العامه', 'مكتبه الدروس']);
      if (parentLessons && !childRole) { await _reply(_strings.voiceCommandDenied); return; }
      await _reply(parentLessons ? _strings.voiceCommandParentLessons : _strings.voiceCommandLibrary);
      nav.push(MaterialPageRoute(builder: (_) => parentLessons ? const ParentLessonsScreen() : const LessonsScreen()));
      return;
    }
    if (_matches(text, ['طلبات الدعم', 'طلبات الدعم التعليمي', 'اجتماعات الدعم التعليمي'])) {
      if (!['parent', 'specialist', 'admin'].contains(role)) { await _reply(_strings.voiceCommandDenied); return; }
      await _reply(_strings.voiceCommandSupport);
      nav.push(MaterialPageRoute(builder: (_) => const LearningSupportRequestsScreen()));
      return;
    }
    if (_matches(text, ['جلسات', 'الجلسات', 'اجتماعات الدعم', 'اجتماعات دعم', 'طلبات', 'الطلبات', 'طلبات الدعم', 'طلب دعم', 'دعم تعليمي']) &&
        !_matches(text, ['فريق', 'الفريق']) && !['parent', 'specialist', 'admin'].contains(role)) {
      await _reply(_strings.voiceCommandSupportDenied); return;
    }
    if (_matches(text, ['دراسه', 'دراسه الحاله', 'دراسات الحاله', 'نقاش', 'مناقشه']) && !['teacher', 'specialist', 'admin'].contains(role)) {
      await _reply(_strings.voiceCommandCasesDenied); return;
    }
    if (_matches(text, ['الاطفال', 'اطفال', 'الطلاب', 'طلاب', 'طلابي', 'طفل', 'دروس', 'الدروس', 'درس', 'واجب', 'واجبات', 'الواجبات', 'الواجب', 'تقدم', 'التقدم', 'تقارير', 'التقارير', 'تقرير', 'التقرير', 'فريق', 'الفريق', 'العاب', 'الالعاب', 'العب']) && !childRole) {
      await _reply(_strings.voiceCommandDenied); return;
    }
    if (_matches(text, ['دروس', 'الدروس', 'درس', 'واجب', 'واجبات', 'الواجبات', 'الواجب', 'تقدم', 'التقدم', 'تقرير', 'التقرير', 'تقارير', 'التقارير', 'فريق', 'الفريق', 'طلب دعم', 'دعم تعليمي', 'تكييف', 'تكيف', 'دراسه', 'دراسات الحاله', 'نقاش', 'مناقشه'])) {
      await _ensureChildrenLoaded();
      if (await ApiService.getUserId() != userId) return;
      if (await _tryExecuteChildCommand(text, nav)) return;
    }

    // ═══ 7. الألعاب ═══
    final gameId = _detectGame(text);
    final wantsCatalog = _matches(text, [
      'الالعاب', 'العاب', 'قائمه الالعاب', 'شاشه الالعاب', 'العب',
    ]);
    if ((gameId != null || wantsCatalog) && childRole) {
      await _openChildGame(text, nav, userId: userId, gameId: gameId);
      return;
    }

    // ═══ 8. الشاشات العامة ═══
    if (_matches(text, [
      'الاطفال', 'اطفال', 'الطلاب', 'طلاب', 'طلابي', 'الاولاد', 'اولاد', 'قائمه الاطفال',
    ])) {
      await _reply(_strings.voiceCommandChildren);
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    if (_matches(text, [
      'دروس ولي الامر', 'دروس لولي الامر', 'دروس للاهل', 'نصائح',
    ])) {
      await _reply(_strings.voiceCommandParentLessons);
      nav.push(MaterialPageRoute(
        builder: (_) => const ParentLessonsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'اشعارات', 'الاشعارات', 'تنبيهات', 'جرس',
    ])) {
      await _reply(_strings.voiceCommandNotifications);
      nav.push(MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'محادثات', 'المحادثات', 'رسائل', 'شات',
    ])) {
      await _reply(_strings.voiceCommandChats);
      nav.push(MaterialPageRoute(builder: (_) => const ChatsScreen()));
      return;
    }

    if (_matches(text, [
      'مساعد', 'المساعد', 'نور', 'روبوت', 'اسال',
    ])) {
      await _reply(_strings.voiceCommandAssistant);
      nav.push(MaterialPageRoute(
        builder: (_) => const AssistantScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'احتياجات', 'الاحتياجات', 'احتياجات الابناء', 'تخصيص',
    ])) {
      if (await ApiService.getRole() != 'specialist') {
        await _reply(_strings.voiceCommandSpecialistOnly);
        return;
      }
      await _reply(_strings.voiceCommandNeeds);
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'جلسات', 'الجلسات', 'اجتماعات دعم', 'اجتماعات الدعم',
    ])) {
      await _reply(_strings.voiceCommandSessions);
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportMeetingsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'طلبات', 'الطلبات', 'طلبات الدعم',
    ])) {
      await _reply(_strings.voiceCommandSupport);
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportRequestsScreen(),
      ));
      return;
    }

    if (_matches(text, [
  'تواصل', 'التواصل',
]    )) {
  await _reply(_strings.voiceCommandChats);
  nav.push(MaterialPageRoute(builder: (_) => const ChatsScreen()));
  return;
}

    if (_matches(text, [
      'اضف طفل', 'اضافه طفل', 'ضيف طفل', 'طفل جديد',
    ])) {
      final role = await ApiService.getRole();
      if (role != 'parent') {
        await _reply(_strings.voiceCommandParentOnly);
        return;
      }
      await _reply(_strings.voiceCommandAddChild);
      nav.push(MaterialPageRoute(
        builder: (_) => const AddChildScreen(),
      ));
      return;
    }

    if (_matches(text, ['دروس عامه', 'الدروس العامه', 'مكتبه الدروس'])) {
      await _reply(_strings.voiceCommandLibrary);
      nav.push(MaterialPageRoute(builder: (_) => const LessonsScreen()));
      return;
    }

    // ═══ 9. المساعدة ═══
    if (_matches(text, [
      'مساعده', 'مساعدة', 'اوامر', 'الاوامر', 'ساعدني',
    ])) {
      await _reply(_strings.voiceCommandHelp);
      return;
    }

    // ═══ غير مفهوم ═══
    await _reply(
      _strings.voiceCommandUnknown(rawText),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الألعاب
  // ═══════════════════════════════════════════════════════════
}
