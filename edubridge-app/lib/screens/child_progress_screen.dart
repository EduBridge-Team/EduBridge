// lib/screens/child_progress_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import 'specialist/specialist_screen.dart';
import '../services/api_service.dart';
import '../services/reward_service.dart';
import '../theme.dart';
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

  Future<void> _refreshProgress() async {
    await Future.wait([_loadProgress(showLoader: false), _loadStars()]);
  }

  Future<void> _loadProgress({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }

    try {
      final responses = await Future.wait([
        ApiService.authGet('/progress/child/${widget.childId}/summary'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      final summaryRes = responses[0];
      final detailsRes = responses[1];

      if (!mounted) return;
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
      if (!mounted) return;
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
        backgroundColor: const Color(0xFFF5F9FC),
        appBar: AppBar(
          toolbarHeight: 116,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Stack(fit: StackFit.expand, children: [
              const DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [Color(0xFF20B6C6), Color(0xFF1769C2)]))),
              // S09 decorative illustration: overlapping translucent arcs.
              const Positioned(
                left: 0,
                bottom: 0,
                width: 177,
                height: 116,
                child: IgnorePointer(
                  child: CustomPaint(painter: _S09HeaderArtwork()),
                ),
              ),
            ]),
          ),
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: () => Navigator.maybePop(context),
            icon: const CircleAvatar(
              radius: 21, backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.arrow_forward_rounded,
                size: 23, color: Colors.white)),
          ),
          title: Text('تقدّم ${widget.childName}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w800)),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProgress,
          child: _buildBody(),
        ),
      ),
    );
  }
}

/// Decorative, resolution-independent artwork matching the two overlapping
/// turquoise arcs in the supplied S09 Figma header.
class _S09HeaderArtwork extends CustomPainter {
  const _S09HeaderArtwork();

  @override
  void paint(Canvas canvas, Size size) {
    final largeArc = Paint()
      ..color = const Color(0x6689DCE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..isAntiAlias = true;
    final crossingArc = Paint()
      ..color = const Color(0x619AE4ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..isAntiAlias = true;

    canvas.drawCircle(const Offset(-12, 147), 106, largeArc);
    canvas.drawCircle(const Offset(67, 152), 84, crossingArc);
  }

  @override
  bool shouldRepaint(covariant _S09HeaderArtwork oldDelegate) => false;
}
