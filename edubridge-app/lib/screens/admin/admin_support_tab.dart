// lib/screens/admin/admin_support_tab.dart
part of 'admin_screen.dart';

class _SupportTicketsTab extends StatefulWidget {
  final Map admin;
  const _SupportTicketsTab({required this.admin});

  @override
  State<_SupportTicketsTab> createState() => _SupportTicketsTabState();
}

class _SupportTicketsTabState extends State<_SupportTicketsTab> {
  List _tickets = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/support/tickets');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        List ticketsList = [];
        if (data is List) {
          ticketsList = data;
        } else if (data is Map) {
          ticketsList = data['tickets'] ?? data['data'] ?? [];
        }
        setState(() {
          _tickets = ticketsList;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? SharedUiMessage.ticketsLoadFailed;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = SharedUiMessage.connectionFailed;
        _loading = false;
      });
    }
  }

  Future<void> _resolveTicket(Map ticket) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.resolveTicket),
        content: Text(
            context.l10n.resolveTicketConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.resolvedStatus, style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.authPut(
          '/support/tickets/${ticket['id']}/resolve', {});
        if (!mounted) return;
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(() {
            _tickets.removeWhere((t) => t['id'] == ticket['id']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.ticketResolvedNotice)),
          );
        } else {
          setState(() {
            _error = SharedUiMessage.ticketResolveFailed;
          });
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.connectionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(AppIcons.error, size: 54, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            context.sharedMessage(_error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(AppIcons.refresh),
              label: Text(context.l10n.retryAction),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: _tickets.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 90),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.support,
                      size: 38,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.noTickets,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.ticketsEmptyDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: c.muted),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final user = ticket['user'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.tintOrange,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          AppIcons.support,
                          color: AppColors.orangeDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket['subject']?.toString() ?? context.l10n.noSubject,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: c.heading,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ticket['message']?.toString() ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: c.body,
                              ),
                            ),
                            if (user['name'] != null) ...[
                              const SizedBox(height: 7),
                              Text(
                                context.l10n.ticketFromUser((user['name'] ?? '').toString()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _resolveTicket(ticket),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          minimumSize: const Size(82, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          context.l10n.resolvedStatus,
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}