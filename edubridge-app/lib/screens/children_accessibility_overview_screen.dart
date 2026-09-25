// lib/screens/children_accessibility_overview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_button.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';
import 'child_accessibility/child_accessibility_settings_screen.dart';

part 'children_accessibility_overview_widgets.dart';

class ChildrenAccessibilityOverviewScreen extends StatefulWidget {
  const ChildrenAccessibilityOverviewScreen({super.key});

  @override
  State<ChildrenAccessibilityOverviewScreen> createState() =>
      _ChildrenAccessibilityOverviewScreenState();
}

class _ChildrenAccessibilityOverviewScreenState
    extends State<ChildrenAccessibilityOverviewScreen> {
  List _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final list = data['children'] ?? [];

        for (final c in list) {
          final id = c['id'] as int;
          if (AccessibilityService.instance.profileForChild(id) == null) {
            await AccessibilityService.instance.ensureChildProfile(
              id,
              disabilityTypeHint: c['disability_type']?.toString(),
            );
          }
        }

        if (!mounted) return;
        setState(() {
          _children = list;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الأطفال';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _openChildSettings(Map child) async {
    final id = child['id'] as int;
    final name = (child['name'] ?? '').toString();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAccessibilitySettingsScreen(
          childId: id,
          childName: name,
          disabilityTypeHint: child['disability_type']?.toString(),
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: 'احتياجات الأبناء الخاصة',
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.accessibility_new, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'احتياجات الأبناء',
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(AppIcons.refresh, color: Colors.white),
              tooltip: 'تحديث',
              onPressed: _load,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

}
