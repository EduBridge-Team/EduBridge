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
  String? _error;

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
          _error = data['error']?.toString() ?? 'تعذّر جلب الشكاوى';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  Future<void> _resolveTicket(Map ticket) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حل الشكوى'),
        content: const Text(
            'هل أنت متأكد من حل هذه الشكوى؟ سيتم إرسال إشعار للمستخدم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تم الحل', style: TextStyle(color: Colors.green)),
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
            const SnackBar(
                content: Text('تم حل الشكوى وإرسال إشعار للمستخدم')),
          );
        } else {
          setState(() {
            _error = 'تعذّر حل الشكوى. تأكد من دعم الـ Backend.';
          });
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _StateBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTickets,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: _tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: c.muted),
                  const SizedBox(height: 12),
                  Text('لا توجد شكاوى حالياً',
                      style: TextStyle(fontSize: 16, color: c.muted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final user = ticket['user'] ?? {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(AppIcons.support, color: AppColors.orange),
                    title: Text(ticket['subject']?.toString() ?? 'بدون موضوع'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket['message']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.body),
                        ),
                        if (user['name'] != null)
                          Text(
                            'من: ${user['name']}',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                      ],
                    ),
                    trailing: TextButton(
                      onPressed: () => _resolveTicket(ticket),
                      child: const Text('تم الحل',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}