import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../domain/notification_filter.dart';
import 'notification_center_labels.dart';

/// Presentation of a loaded feed. Reads, writes and pagination stay with owner.
class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key, required this.rows,
    required this.hasMore, required this.loadingMore, required this.markingAll,
    required this.unreadCount, required this.onRefresh, required this.onLoadMore,
    required this.onMarkAllRead, required this.displayTitle, required this.tileBuilder});
  final List<dynamic> rows;
  final bool hasMore, loadingMore, markingAll;
  final int unreadCount;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore, onMarkAllRead;
  final String Function(Map) displayTitle;
  final Widget Function(Map) tileBuilder;

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  final _search = TextEditingController();
  var _status = NotificationReadFilter.all;

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _clear() => setState(() {
    _search.clear();
    _status = NotificationReadFilter.all;
  });

  @override
  Widget build(BuildContext context) {
    final labels = NotificationCenterLabels(context);
    final strings = context.l10n;
    final visible = NotificationFilter.apply(widget.rows, status: _status,
        query: _search.text, displayTitle: widget.displayTitle);
    final loaded = widget.rows.whereType<Map>().length;
    final busy = widget.loadingMore || widget.markingAll;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        itemCount: visible.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('notification-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: labels.search,
                  prefixIcon: const Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final status in NotificationReadFilter.values)
                  ChoiceChip(key: ValueKey('notification-filter-${status.name}'),
                    label: Text(labels.status(status)), selected: _status == status,
                    onSelected: (_) => setState(() => _status = status)),
                if (_search.text.isNotEmpty || _status != NotificationReadFilter.all)
                  TextButton(onPressed: _clear, child: Text(labels.clear)),
              ]),
              const SizedBox(height: 8),
              Text(labels.results(visible.length, loaded),
                  key: const ValueKey('notification-result-count')),
              if (widget.hasMore) ...[
                const SizedBox(height: 6), Text(labels.loadedOnly),
              ],
              Align(alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  key: const ValueKey('notification-mark-all'),
                  onPressed: busy || widget.unreadCount == 0 ? null : widget.onMarkAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                  label: Text(strings.markAllRead))),
              if (visible.isEmpty) Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(loaded == 0 ? strings.noNotifications : labels.empty,
                  key: const ValueKey('notification-empty'), textAlign: TextAlign.center)),
              const SizedBox(height: 8),
            ],
          );
          if (index <= visible.length) return widget.tileBuilder(visible[index - 1]);
          return widget.hasMore ? TextButton(
            key: const ValueKey('notification-load-older'),
            onPressed: busy ? null : widget.onLoadMore,
            child: Text(widget.loadingMore ? strings.loadingDots : strings.loadOlderNotifications),
          ) : const SizedBox.shrink();
        },
      ),
    );
  }
}
