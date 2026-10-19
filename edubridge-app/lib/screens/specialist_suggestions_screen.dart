// lib/screens/specialist_suggestions_screen.dart
import 'package:flutter/material.dart';
import '../widgets/teacher_navigation_bar.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

part 'specialist_suggestions_widgets.dart';

class SpecialistSuggestionsScreen extends StatefulWidget {
  const SpecialistSuggestionsScreen({super.key});

  @override
  State<SpecialistSuggestionsScreen> createState() =>
      _SpecialistSuggestionsScreenState();
}

class _SpecialistSuggestionsScreenState
    extends State<SpecialistSuggestionsScreen> {
  List _suggestions = [];
  bool _loading = true;
  Object? _error;
  String _filter = 'pending';
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getMySpecialistSuggestions(
        status: _filter == 'all' ? null : _filter,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = SharedUiMessage.followupSuggestionsLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _accept(Map s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(AppIcons.check, color: AppColors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(context.l10n.followupConfirmAccept)),
          ],
        ),
        content: Text(
          context.l10n.followupAcceptQuestion((s['child_name'] ?? '').toString(), s['specialty'] == 'learning_support' ? context.l10n.learningSupportSpecialist : context.l10n.educationalSpecialist),
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.followupAccept),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final err = await ApiService.acceptSuggestion(s['id'] as int);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.sharedMessage(err)), backgroundColor: AppColors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.followupAcceptedNotice),
        backgroundColor: AppColors.green,
      ),
    );
    _load();
  }

  Future<void> _reject(Map s) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _FollowupRejectionDialog(
        childName: (s['child_name'] ?? '').toString(),
      ),
    );
    if (reason == null || !mounted) return;

    final err = await ApiService.rejectSuggestion(
      s['id'] as int,
      reason: reason,
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.sharedMessage(err)), backgroundColor: AppColors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.followupRejectedNotice),
        backgroundColor: AppColors.orange,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      bottomNavigationBar: const TeacherNavigationBar(),
      appBar: JisrAppBar(
        title: context.l10n.followupSuggestionsTitle,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: context.l10n.followupRefresh,
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(context.l10n.followupPendingFilter, 'pending', AppColors.orange),
                _filterChip(context.l10n.followupAcceptedFilter, 'accepted', AppColors.green),
                _filterChip(context.l10n.rejectedStatus, 'rejected', AppColors.red),
                _filterChip(context.l10n.all, 'all', AppColors.brandBlue),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? color : JisrColors.of(context).muted,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) {
        if (_filter == value) return;
        setState(() => _filter = value);
        _load();
      },
    );
  }
}
