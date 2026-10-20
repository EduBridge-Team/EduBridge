import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import 'add_lesson_sheet.dart';
import '../../widgets/teacher_navigation_bar.dart';

class AddLessonScreen extends StatefulWidget {
  final List types;
  final bool forParents;
  final int? initialChildId;
  final String? initialChildName;
  final bool showBottomNavigation;

  const AddLessonScreen({
    super.key,
    required this.types,
    this.forParents = false,
    this.initialChildId,
    this.initialChildName,
    this.showBottomNavigation = false,
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
      appBar: BrandAppBar(
        toolbarHeight: 88 * MediaQuery.textScalerOf(context).scale(1),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: context.l10n.back,
          onPressed: () => Navigator.pop(context),
          icon: const BackButtonIcon(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.lessonCreateTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.initialChildName == null
                  ? context.l10n.lessonCreateIntro
                  : context.l10n.lessonForStudentSubtitle(widget.initialChildName!),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
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
                            context.l10n.verificationRequired,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.lessonVerificationHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.muted, height: 1.5),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.l10n.back),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  top: false,
                  bottom: false,
                  child: AddLessonSheet(
                    types: widget.types,
                    fullScreen: true,
                    forParents: widget.forParents,
                    initialChildId: widget.initialChildId,
                    initialChildName: widget.initialChildName,
                    onClose: () => Navigator.pop(context),
                    onCreated: (lesson) => Navigator.pop(context, lesson),
                  ),
                ),
      bottomNavigationBar:
          widget.showBottomNavigation ? const TeacherNavigationBar() : null,
    );
  }
}
