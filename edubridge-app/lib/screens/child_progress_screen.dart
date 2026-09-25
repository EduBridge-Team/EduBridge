// lib/screens/child_progress_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/reward_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';

part 'child_progress_widgets.dart';

class ChildProgressScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildProgressScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  Map? _summary;
  List _progress = [];
  int _stars = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadStars();
  }

  Future<void> _loadStars() async {
    final stars = await RewardService.instance.getStars(widget.childId);
    if (!mounted) return;
    setState(() => _stars = stars);
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/progress/child/${widget.childId}/summary'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      final summaryRes = responses[0];
      final detailsRes = responses[1];

      if (summaryRes.statusCode == 200 && detailsRes.statusCode == 200) {
        setState(() {
          _summary = jsonDecode(summaryRes.body)['summary'];
          _progress = jsonDecode(detailsRes.body)['progress'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'تعذّر جلب التقدّم';
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
    return AdaptiveWrapper(
      screenTitle: 'تقدّم ${widget.childName}',
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
              const Icon(AppIcons.progress, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'تقدّم ${widget.childName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.starFilled,
                      size: 18, color: AppColors.yellow),
                  const SizedBox(width: 4),
                  Text(
                    '$_stars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadProgress,
          child: _buildBody(),
        ),
      ),
    );
  }
}
