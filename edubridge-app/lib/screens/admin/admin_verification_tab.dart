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
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(AppIcons.error, size: 54, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: c.tintTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.shield,
                          size: 38,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'لا توجد طلبات معلقة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ستظهر هنا طلبات التوثيق التي تحتاج إلى مراجعة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: c.muted),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
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
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.brandBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w800,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
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
                        fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w800,
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
          const SizedBox(width: 10),
          Column(
            children: [
              SizedBox(
                width: 92,
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('اعتماد'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 92,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(
                      color: AppColors.red.withValues(alpha: .45),
                    ),
                  ),
                  child: const Text('رفض'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}