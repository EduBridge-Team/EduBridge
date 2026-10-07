// lib/screens/child_accessibility/child_accessibility_settings_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../features/adaptation/data/adaptation_permission_repository.dart';
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

  final _permissionRepository = AdaptationPermissionRepository();

  final _customNameCtrl = TextEditingController();
  String? _selectedDisability;
  bool _canEdit = false;
  bool _saving = false;
  bool _loadingPermission = true;
  bool get _canChange => _canEdit && !_saving;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityTypeHint,
      forceReload: true,
    );
    _loadEditPermission();
    _selectedDisability = widget.disabilityTypeHint;
    _customNameCtrl.text = widget.disabilityTypeHint ?? '';
  }

  Future<void> _loadEditPermission() async {
    final canEdit = await _permissionRepository.canEdit(widget.childId);
    if (!mounted) return;
    setState(() {
      _canEdit = canEdit;
      _loadingPermission = false;
    });
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
    final saved = await _set(AccessibilityProfile.recommendedFor(
      type, customName: type == DisabilityType.other ? result : null,
    ));
    if (!saved) {
      if (mounted) setState(() => _selectedDisability = previous);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تطبيق التكييف الموصى به لـ "$result"'),
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
    final saved = await _set(AccessibilityProfile.recommendedFor(DisabilityType.other, customName: name));
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

  @override
  Widget build(BuildContext context) {
    if (_loadingPermission) {
      return Scaffold(appBar: JisrAppBar(title: 'إعدادات التكيف'),
        body: const Center(child: CircularProgressIndicator()));
    }
    if (!_canEdit) {
      return Scaffold(
        appBar: JisrAppBar(title: 'إعدادات التكيف'),
        body: const Center(child: Text('إعدادات التكيف متاحة للمختص المعيّن للطفل فقط.')),
      );
    }
    return buildView(context);
  }
}