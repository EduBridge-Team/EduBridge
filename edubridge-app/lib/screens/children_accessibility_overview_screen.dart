// شاشة تعرض كل الأبناء وحالة التكييف الخاصة بكل واحد
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'child_accessibility_settings_screen.dart';

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

          // الخادم هو المصدر المشترك بين الأجهزة. إن لم يكن للبروفايل
          // سجل بعد، ننشئ التوصية الافتراضية محلياً ونرفعها تلقائياً.
          final synced =
              await AccessibilityService.instance.syncChildProfile(id);
          if (!synced &&
              AccessibilityService.instance.profileForChild(id) == null) {
            await AccessibilityService.instance.setActiveChild(
              id,
              disabilityTypeHint: c['disability_type']?.toString(),
            );
            await AccessibilityService.instance.setActiveChild(null);
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

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: const JisrAppBar(title: 'احتياجات الأبناء الخاصة'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Color.fromARGB(255, 54, 165, 244))))
              : _children.isEmpty
                  ? const Center(
                      child: Text('لا يوجد أبناء مسجّلون بعد',
                          style: TextStyle(fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _children.length,
                        itemBuilder: (context, i) {
                          final child = _children[i];
                          final name = (child['name'] ?? '').toString();
                          final id = child['id'] as int;
                          final profile = AccessibilityService
                                  .instance
                                  .profileForChild(id) ??
                              const AccessibilityProfile(
                                  type: DisabilityType.none);
                          final color = AppColors
                              .kidPalette[i % AppColors.kidPalette.length];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: color,
                                child: Text(
                                  name.isNotEmpty
                                      ? name.characters.first
                                      : '🙂',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: c.heading,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  disabilityLabels[profile.type] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: c.muted,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_left,
                                color: c.muted,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChildAccessibilitySettingsScreen(
                                      childId: id,
                                      childName: name,
                                      disabilityTypeHint: child['disability_type']
                                          ?.toString(),
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
