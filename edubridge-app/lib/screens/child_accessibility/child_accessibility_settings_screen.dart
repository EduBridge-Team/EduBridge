// lib/screens/child_accessibility/child_accessibility_settings_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../features/adaptation/data/adaptation_settings_loader.dart';
import '../../theme.dart';
import '../../widgets/disability/disability_catalog.dart';
import '../../widgets/disability/disability_picker_sheet.dart';
import '../../widgets/accessibility/adaptive_wrapper.dart';

part 'child_accessibility_shared_widgets.dart';
part 'child_accessibility_settings_view.dart';

class ChildAccessibilitySettingsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final String? disabilityTypeHint;
  final bool deactivateOnExit;

  const ChildAccessibilitySettingsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.disabilityTypeHint,
    this.deactivateOnExit = true,
  });

  @override
  State<ChildAccessibilitySettingsScreen> createState() =>
      _ChildAccessibilitySettingsScreenState();
}

class _ChildAccessibilitySettingsScreenState
    extends State<ChildAccessibilitySettingsScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _settingsLoader = AdaptationSettingsLoader();

  final _customNameCtrl = TextEditingController();
  String? _selectedDisability;
  bool _canEdit = false;
  bool _saving = false;
  bool _loadingSettings = true;
  bool _profileError = false;
  bool get _canChange => _canEdit && !_saving && !_loadingSettings && !_profileError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _selectedDisability = widget.disabilityTypeHint;
    _customNameCtrl.text = widget.disabilityTypeHint ?? '';
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loadingSettings = true;
      _profileError = false;
    });
    try {
      final canEdit = await _settingsLoader.load(widget.childId,
        disabilityHint: widget.disabilityTypeHint);
      if (mounted) _canEdit = canEdit;
    } catch (_) {
      _profileError = true;
    } finally {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    if (widget.deactivateOnExit) {
      AccessibilityService.instance.setActiveChild(null);
    }
    super.dispose();
  }

  AccessibilityProfile get _p =>
      AccessibilityService.instance.profileForChild(widget.childId) ??
      const AccessibilityProfile(type: DisabilityType.none);

  Future<bool> _set(AccessibilityProfile next) async {
    if (!_canChange) return false;
    setState(() => _saving = true);
    try {
      await AccessibilityService.instance.updateForChild(widget.childId, next);
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر حفظ إعدادات التكيف')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDisabilityPicker() async {
    if (!_canChange) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisabilityPickerSheet(
        currentValue: _selectedDisability,
      ),
    );

    if (!mounted || result == null) return;
    final previous = _selectedDisability;

    setState(() => _selectedDisability = result);

    if (result == 'أخرى') return;

    final type = disabilityTypeForCategory(result);
    final saved = await _set(_p.withDisability(
      type, customName: type == DisabilityType.other ? result : null,
    ));
    if (!saved) {
      if (mounted) setState(() => _selectedDisability = previous);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ التصنيف مع الحفاظ على إعدادات التكيف لـ "$result"'),
        backgroundColor: AppColors.brandBlueLight,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _applyCustom() async {
    if (!_canChange) return;
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة اسم الإعاقة'),
          backgroundColor: AppColors.brandTealDeep,
        ),
      );
      return;
    }
    final saved = await _set(_p.withDisability(DisabilityType.other, customName: name));
    if (!saved) return;
    if (!mounted) return;
    setState(() => _selectedDisability = name);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعاقة المخصّصة'),
        backgroundColor: AppColors.brandBlueLight,
      ),
    );
  }

  Future<void> _applyRecommendations() async {
    if (!_canChange) return;
    final profile = _p;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تطبيق الإعدادات المقترحة؟'),
        content: const Text('سيستبدل هذا إعدادات التكيف الحالية باقتراحات أولية. راجعها وعدّلها حسب احتياج الطفل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تطبيق')),
        ],
      ),
    );
    if (!mounted || confirmed != true || !_canChange) return;
    await _set(AccessibilityProfile.recommendedFor(profile.type,
        customName: profile.customDisabilityName));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSettings) {
      return Scaffold(appBar: buildChildSettingsAppBar(context, widget.childName),
        body: const Center(child: CircularProgressIndicator()));
    }
    if (_profileError) {
      return Scaffold(
        appBar: buildChildSettingsAppBar(context, widget.childName),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('تعذّر تحميل إعدادات الطفل'),
          TextButton(onPressed: _loadSettings, child: const Text('إعادة المحاولة')),
        ])),
      );
    }
    if (!_canEdit) {
      return Scaffold(
        appBar: buildChildSettingsAppBar(context, widget.childName),
        body: const Center(child: Text('إعدادات التكيف متاحة للمختص المعيّن للطفل فقط.')),
      );
    }
    return buildView(context);
  }
}