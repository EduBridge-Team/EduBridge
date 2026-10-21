import '../l10n/l10n.dart';
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

enum _ProgressLoadError { fetch, connection }

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
  _ProgressLoadError? _error;

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
          _error = _ProgressLoadError.fetch;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _ProgressLoadError.connection;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: context.l10n.childProgressFor(widget.childName),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        appBar: BrandAppBar(
          toolbarHeight: 116,
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 48,
          leading: IconButton(
            tooltip: context.l10n.back,
            onPressed: () => Navigator.maybePop(context),
            icon: const CircleAvatar(
              radius: 21, backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.arrow_back_rounded,
                size: 23, color: Colors.white)),
          ),
          title: Text(context.l10n.childProgressFor(widget.childName),
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
