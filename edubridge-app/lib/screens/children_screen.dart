// شاشة قائمة الأطفال
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'child_lessons_screen.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

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
      appBar: AppBar(title: const Text('الأطفال')),
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
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 26,
              child: Icon(Icons.child_care, size: 28),
            ),
            title: Text(
              child['name'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_left), // اتجاه RTL
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildLessonsScreen(
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
