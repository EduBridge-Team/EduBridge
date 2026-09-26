// lib/screens/child_accessibility/child_accessibility_settings_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
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

  final _customNameCtrl = TextEditingController();
  String? _selectedDisability;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityTypeHint,
      forceReload: true,
    );
    _selectedDisability = widget.disabilityTypeHint;
    _customNameCtrl.text = widget.disabilityTypeHint ?? '';
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

  Future<void> _set(AccessibilityProfile next) =>
      AccessibilityService.instance.updateForChild(widget.childId, next);

  Future<void> _openDisabilityPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisabilityPickerSheet(
        currentValue: _selectedDisability,
      ),
    );

    if (result == null) return;

    setState(() => _selectedDisability = result);

    if (result == 'أخرى') return;

    final type = disabilityTypeForCategory(result);
    await AccessibilityService.instance.applyRecommendedForChild(
      widget.childId,
      type,
      customName: type == DisabilityType.other ? result : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تطبيق التكييف الموصى به لـ "$result"'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _applyCustom() async {
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة اسم الإعاقة'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }
    await AccessibilityService.instance.applyRecommendedForChild(
      widget.childId,
      DisabilityType.other,
      customName: name,
    );
    if (!mounted) return;
    setState(() => _selectedDisability = name);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الإعاقة المخصّصة'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}