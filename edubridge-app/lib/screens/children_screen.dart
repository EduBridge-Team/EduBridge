// شاشة قائمة الأطفال
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'child_lessons_screen.dart';
import 'child_progress_screen.dart';

class ChildrenScreen extends StatefulWidget {
  /// عند true: اختيار الطفل يفتح تقدّمه ومكافآته مباشرة بدل دروسه
  final bool forProgress;

  const ChildrenScreen({super.key, this.forProgress = false});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  List _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          _children = data['children'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الأطفال';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
          title: widget.forProgress ? 'اختر طفلاً لعرض تقدّمه' : 'الأطفال'),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.red)),
      );
    }
    if (_children.isEmpty) {
      return const Center(child: Text('لا يوجد أطفال بعد', style: TextStyle(fontSize: 18)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _children.length,
      itemBuilder: (context, i) {
        final child = _children[i];
        // لون متناوب لكل طفل من لوحة الهوية + الحرف الأول من اسمه
        final color = AppColors.kidPalette[i % AppColors.kidPalette.length];
        // تحويل صريح إلى String — القيمة القادمة من JSON نوعها dynamic
        final String name = (child['name'] ?? '').toString();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name.characters.first : '🙂',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JisrColors.of(context).heading,
              ),
            ),
            trailing: const Icon(Icons.chevron_left), // اتجاه RTL
            onTap: () {
              // حسب مصدر الدخول: التقدّم والمكافآت مباشرة، أو الدروس
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => widget.forProgress
                      ? ChildProgressScreen(
                          childId: child['id'],
                          childName: child['name'] ?? '',
                        )
                      : ChildLessonsScreen(
                          childId: child['id'],
                          childName: child['name'] ?? '',
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
