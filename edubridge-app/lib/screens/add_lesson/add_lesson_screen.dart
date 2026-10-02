import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'add_lesson_sheet.dart';
import '../../widgets/teacher_navigation_bar.dart';

class AddLessonScreen extends StatefulWidget {
  final List types;
  final bool forParents;

  const AddLessonScreen({
    super.key,
    required this.types,
    this.forParents = false,
  });

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  bool? _verified;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final verified = await ApiService.isVerified();
      if (!mounted) return;
      setState(() => _verified = verified);
    } catch (_) {
      if (!mounted) return;
      setState(() => _verified = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة درس جديد',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
      body: _verified == null
          ? const Center(child: CircularProgressIndicator())
          : _verified == false
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.verified,
                            size: 48,
                            color: AppColors.brandTealDeep,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'توثيق الهوية مطلوب',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يجب توثيق حساب المعلم قبل إضافة درس جديد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.muted, height: 1.5),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('رجوع'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : AddLessonSheet(
                  types: widget.types,
                  fullScreen: true,
                  forParents: widget.forParents,
                  onClose: () => Navigator.pop(context),
                  onCreated: (lesson) => Navigator.pop(context, lesson),
                ),
      bottomNavigationBar: const TeacherNavigationBar(),
    );
  }
}
