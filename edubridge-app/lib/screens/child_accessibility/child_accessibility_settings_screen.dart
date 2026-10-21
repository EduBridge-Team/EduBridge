// lib/screens/child_accessibility/child_accessibility_settings_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../widgets/disability/disability_display.dart';
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
        SnackBar(content: Text(context.l10n.adaptationSaveFailed)),
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
        figmaS30: true,
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
        content: Text(context.l10n.adaptationCategorySaved(DisabilityDisplay.label(result, context.l10n))),
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
        SnackBar(
          content: Text(context.l10n.adaptationEnterName),
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
      SnackBar(
        content: Text(context.l10n.adaptationCustomSaved),
        backgroundColor: AppColors.brandBlueLight,
      ),
    );
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
          Text(context.l10n.adaptationLoadFailed),
          TextButton(onPressed: _loadSettings, child: Text(context.l10n.retryAction)),
        ])),
      );
    }
    if (!_canEdit) {
      return Scaffold(
        appBar: buildChildSettingsAppBar(context, widget.childName),
        body: Center(child: Text(context.l10n.adaptationRestricted)),
      );
    }
    return buildView(context);
  }
}