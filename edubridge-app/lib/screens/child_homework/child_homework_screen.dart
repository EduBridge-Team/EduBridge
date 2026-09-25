// lib/screens/child_homework/child_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_icons.dart';
import '../../services/accessibility_service.dart';
import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';
import '../../model/homework_model.dart';

part 'child_homework_card.dart';
part 'child_homework_submit_sheet.dart';

class ChildHomeworkScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildHomeworkScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildHomeworkScreen> createState() => _ChildHomeworkScreenState();
}

class _ChildHomeworkScreenState extends State<ChildHomeworkScreen> {
  List<Homework> _homeworks = [];
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
      final list = await ApiService.getHomeworks(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _homeworks = list
            .map((e) => Homework.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الواجبات';
        _loading = false;
      });
    }
  }

  Future<void> _submit(Homework hw) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitHomeworkSheet(
        homework: hw,
        childId: widget.childId,
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: 'واجبات ${widget.childName}'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(AppIcons.error,
                    size: 64, color: JisrColors.of(context).muted),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16, color: AppColors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(AppIcons.refresh),
                  label: const Text('إعادة المحاولة'),
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_homeworks.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(AppIcons.homework,
              size: 80, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد واجبات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'سيظهر هنا أي واجب يضيفه معلمك',
              style: TextStyle(
                fontSize: 14,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _homeworks.length,
      itemBuilder: (context, i) => _HomeworkCard(
        homework: _homeworks[i],
        childId: widget.childId,
        onSubmit: () => _submit(_homeworks[i]),
      ),
    );
  }
}