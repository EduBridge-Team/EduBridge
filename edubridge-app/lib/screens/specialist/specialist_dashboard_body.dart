import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'specialist_dashboard_statistics.dart';

/// Renders the dashboard content from state supplied by its coordinator.
class SpecialistDashboardBody extends StatelessWidget {
  const SpecialistDashboardBody({
    super.key,
    required this.tabIndex,
    required this.loading,
    required this.hasError,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.filter,
    required this.pendingCount,
    required this.doneToday,
    required this.pendingProgress,
    required this.errorBuilder,
    required this.progressBuilder,
    required this.lessonsBuilder,
    this.overlay,
  });

  final int tabIndex;
  final bool loading;
  final bool hasError;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Widget filter;
  final int pendingCount;
  final int doneToday;
  final int pendingProgress;
  final WidgetBuilder errorBuilder;
  final WidgetBuilder progressBuilder;
  final WidgetBuilder lessonsBuilder;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Stack(
      children: [
        Column(
          children: [
            if (tabIndex == 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextFormField(
                  initialValue: searchQuery,
                  textInputAction: TextInputAction.search,
                  textDirection: Directionality.of(context),
                  onChanged: (value) => onSearchChanged(value.trim()),
                  decoration: InputDecoration(
                    hintText: context.l10n.searchChildrenByName,
                    prefixIcon: const Icon(
                      AppIcons.search,
                      color: Color(0xFF1A73C9),
                    ),
                    filled: true,
                    fillColor: c.card,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF1A73C9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              filter,
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (tabIndex == 0 && !loading)
                      SliverToBoxAdapter(
                        child: SpecialistDashboardStatistics(
                          pending: pendingCount,
                          doneToday: doneToday,
                          inProgress: pendingProgress,
                        ),
                      ),
                    if (loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: errorBuilder(context),
                      )
                    else if (tabIndex == 0)
                      progressBuilder(context)
                    else
                      lessonsBuilder(context),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (overlay != null) overlay!,
      ],
    );
  }
}
