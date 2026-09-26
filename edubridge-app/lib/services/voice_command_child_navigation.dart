part of 'voice_command_service.dart';

extension _VoiceCommandChildNavigationExtension on VoiceCommandService {
  Future<bool> _tryExecuteChildCommand(String text, NavigatorState nav) async {
    // ═══ 6.1 دروس الطفل ═══
    if (this._matches(text, [
      'دروس', 'الدروس', 'درس', 'افتح دروس', 'دروس الطفل',
    ])) {
      // استثناء: "دروس ولي الأمر" له أولوية أعلى
      if (this._matches(text, ['ولي الامر', 'ولي الأمر', 'لولي الامر'])) {
        await this._reply('سأفتح دروس ولي الأمر');
        nav.push(MaterialPageRoute(
          builder: (_) => const ParentLessonsScreen(),
        ));
        return true;
      }

      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح دروس ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildLessonsScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
            age: child['age'] is int ? child['age'] as int : 8,
            disabilityType: child['disability_type']?.toString(),
            parentPhone: child['parent_phone']?.toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return true;
    }

    // ═══ 6.2 واجبات الطفل ═══
    if (this._matches(text, [
      'واجب', 'واجبات', 'الواجبات', 'الواجب',
      'افتح واجب', 'افتح واجبات',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح واجبات ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildHomeworkScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return true;
    }

    // ═══ 6.3 تقدّم الطفل ═══
    if (this._matches(text, [
      'تقدم', 'التقدم', 'انجاز', 'انجازات', 'مكافات',
      'نجوم', 'افتح تقدم', 'تقدم الطفل',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح تقدّم ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildProgressScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenScreen(forProgress: true),
      ));
      return true;
    }

    // ═══ 6.4 تقرير الطفل ═══
    if (this._matches(text, [
      'تقرير', 'التقرير', 'تقارير', 'التقارير',
      'تقرير اسبوعي', 'افتح تقرير',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح تقرير ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => WeeklyReportScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenScreen(forProgress: true),
      ));
      return true;
    }

    // ═══ 6.5 فريق الطفل ═══
    if (this._matches(text, [
      'فريق', 'الفريق', 'فريق الطفل', 'افتح فريق',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح فريق ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CareTeamScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return true;
    }

    // ═══ 6.6 طلب دعم تعليمي للطفل ═══
    if (this._matches(text, [
      'طلب دعم', 'دعم تعليمي', 'طلب دعم تعليمي',
      'افتح دعم تعليمي',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح طلب دعم تعليمي لـ ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CreateLearningSupportRequestScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return true;
    }

    // ═══ 6.7 إعدادات التكييف للطفل ═══
    if (this._matches(text, [
      'تكييف', 'إعدادات التكييف', 'اعدادات التكييف',
      'تكييف الطفل',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح إعدادات تكييف ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildAccessibilitySettingsScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
            disabilityTypeHint: child['disability_type']?.toString(),
          ),
        ));
        return true;
      }
      await this._reply('سأفتح احتياجات الأبناء');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return true;
    }

    // ═══ 6.8 دراسة حالة للطفل ═══
    if (this._matches(text, [
      'دراسه', 'دراسة الحاله', 'دراسه الحاله', 'نقاش', 'مناقشه',
    ])) {
      final child = this._findChild(text);
      if (child != null) {
        await this._reply('سأفتح دراسة حالة ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CaseDiscussionScreen(
            filterChildId: child['id'],
          ),
        ));
        return true;
      }
      await this._reply('سأفتح دراسات الحالة');
      nav.push(MaterialPageRoute(
        builder: (_) => const CaseDiscussionScreen(),
      ));
      return true;
    }


    return false;
  }
}
