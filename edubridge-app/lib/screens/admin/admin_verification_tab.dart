// lib/screens/admin/admin_verification_tab.dart
part of 'admin_screen.dart';

class _VerificationTab extends StatefulWidget {
  const _VerificationTab();

  @override
  State<_VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<_VerificationTab> {
  List _requests = [];
  bool _loading = true;
  String? _error;
  String _filter = 'users';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await ApiService.getVerificationRequests();
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر جلب الطلبات';
        _loading = false;
      });
    }
  }

  Future<void> _handleVerification(Map request, bool approve) async {
    final id = request['id'];
    bool success;
    if (approve) {
      success = await ApiService.approveVerification(id);
    } else {
      success = await ApiService.rejectVerification(id);
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _requests.removeWhere((r) => r['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'تم اعتماد الطلب' : 'تم رفض الطلب'),
          backgroundColor: approve ? AppColors.green : AppColors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشلت العملية')),
      );
    }
  }

  List get _filteredRequests {
    return _requests.where((r) => r['type'] == _filter || _filter == 'all').toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'المستخدمون',
                selected: _filter == 'users',
                onTap: () => setState(() => _filter = 'users'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'الأطفال',
                selected: _filter == 'children',
                onTap: () => setState(() => _filter = 'children'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'الشهادات',
                selected: _filter == 'certificates',
                onTap: () => setState(() => _filter = 'certificates'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: c.muted),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد طلبات معلقة',
                        style: TextStyle(fontSize: 18, color: c.muted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredRequests.length,
                  itemBuilder: (context, i) {
                    final request = _filteredRequests[i];
                    return _VerificationRequestCard(
                      request: request,
                      onApprove: () => _handleVerification(request, true),
                      onReject: () => _handleVerification(request, false),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brandBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _VerificationRequestCard extends StatelessWidget {
  final Map request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = request['name'] ?? '';
    final email = request['email'] ?? '';
    final type = request['type'];
    final createdAt = request['created_at'] != null
        ? DateTime.parse(request['created_at'])
        : null;

    IconData getIcon() {
      switch (type) {
        case 'children': return AppIcons.child;
        case 'certificates': return AppIcons.certificate;
        default: return AppIcons.profile;
      }
    }

    String getTypeName() {
      switch (type) {
        case 'children': return 'طفل';
        case 'certificates': return 'شهادة';
        default: return 'مستخدم';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: c.tintTeal,
              child: Icon(getIcon(), color: AppColors.brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                  Text(email, style: TextStyle(fontSize: 14, color: c.muted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getTypeName(),
                      style: TextStyle(
                        fontSize: 12,
                        color: c.onTint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('اعتماد'),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('رفض'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}