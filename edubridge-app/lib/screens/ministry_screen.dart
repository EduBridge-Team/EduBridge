// شاشة الوزارة — لوحة إدارة شاملة (عرض فقط)
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/approval_service.dart';
import '../theme.dart';
import '../widgets/legal_links_button.dart';
import '../widgets/dashboard_menu.dart';
import 'chats_screen.dart';
import 'lessons_screen.dart';
import 'support_sheet.dart';
import 'admin_screen.dart';

class MinistryScreen extends StatefulWidget {
  const MinistryScreen({super.key});

  @override
  State<MinistryScreen> createState() => _MinistryScreenState();
}

class _MinistryScreenState extends State<MinistryScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(c),
          // شريط التبويبات
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _TabBar(
              index: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? const _OverviewTab()
                : _tabIndex == 1
                    ? const _ApprovalsTab()
                    : const _UsersTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/brand_icon.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'EduBridge · وزارة/مؤسسة',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DashboardMenu(
                    actions: [
                      DashboardMenuAction(
                        id: 'support',
                        label: 'الدعم الفني',
                        icon: Icons.headset_mic,
                        onSelected: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SupportSheet(),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'chats',
                        label: 'المحادثات',
                        icon: Icons.chat_outlined,
                        onSelected: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatsScreen()),
                        ),
                      ),
                      DashboardMenuAction(
                        id: 'legal',
                        label: 'الخصوصية والحساب',
                        icon: Icons.privacy_tip_outlined,
                        onSelected: () =>
                            const LegalLinksButton().show(context),
                      ),
                      DashboardMenuAction(
                        id: 'logout',
                        label: 'تسجيل الخروج',
                        icon: Icons.logout,
                        destructive: true,
                        onSelected: () async {
                          await ApiService.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: ApiService.getName(),
                builder: (context, snap) {
                  final name = snap.data ?? 'الوزارة';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً $name 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'إدارة شاملة للمؤسسات والموافقات',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// شريط التبويبات
// ═══════════════════════════════════════════════════════
class _TabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _TabBar({required this.index, required this.onChanged});

  static const _tabs = [
    ('📊', 'نظرة عامة'),
    ('📤', 'الطلبات'),
    ('👥', 'المستخدمون'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == index;
          final (icon, label) = _tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.tealDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$icon $label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : c.muted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 1. تبويب النظرة العامة
// ═══════════════════════════════════════════════════════
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.getMinistryStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalChildren = _stats?['children_count'] ?? 0;
    final totalUsers = _stats?['users_count'] ?? 0;
    final pendingApprovals = _stats?['pending_approvals'] ?? 0;
    final schools = _stats?['schools_count'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _InfoCard(
                icon: '👶',
                value: '$totalChildren',
                label: 'طفل',
                tint: c.tintTeal,
              ),
              const SizedBox(width: 10),
              _InfoCard(
                icon: '👥',
                value: '$totalUsers',
                label: 'مستخدم',
                tint: c.tintGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoCard(
                icon: '📤',
                value: '$pendingApprovals',
                label: 'طلب معلّق',
                tint: c.tintOrange,
              ),
              const SizedBox(width: 10),
              _InfoCard(
                icon: '🏫',
                value: '$schools',
                label: 'مؤسسة',
                tint: c.tintYellow,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'أدوات الإدارة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: '📚',
            tint: c.tintTeal,
            title: 'تصفح الدروس',
            subtitle: 'عرض جميع الدروس المضافة',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LessonsScreen()),
            ),
          ),
          _MenuTile(
            icon: '🔍',
            tint: c.tintGreen,
            title: 'البحث بالهوية',
            subtitle: 'البحث عن طالب أو مستخدم',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchByIdentityScreen()),
            ),
          ),
          _MenuTile(
            icon: '📈',
            tint: c.tintOrange,
            title: 'التقارير الشهرية',
            subtitle: 'إحصائيات مفصّلة (قريباً)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 2. تبويب الطلبات المعلقة
// ═══════════════════════════════════════════════════════
class _ApprovalsTab extends StatefulWidget {
  const _ApprovalsTab();

  @override
  State<_ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<_ApprovalsTab> {
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _processed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final serverPending = await ApiService.getPendingApprovals();
      final serverProcessed = await ApiService.getAllApprovals(
        status: 'approved,rejected',
      );

      if (serverPending.isEmpty) {
        final localPending = await ApprovalService.getPendingApprovals();
        final localApproved = await ApprovalService.getApprovedPlans();
        final localRejected = await ApprovalService.getRejectedPlans();

        setState(() {
          _pending = localPending;
          _processed = [...localApproved, ...localRejected];
          _loading = false;
        });
      } else {
        setState(() {
          _pending = serverPending.cast<Map<String, dynamic>>();
          _processed = serverProcessed.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleApprove(Map approval) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('اعتماد الخطة'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من اعتماد خطة الطفل "${approval['child_name']}"؟\n\n'
          'سيتم إشعار المختص والمعلم.',
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.check),
            label: const Text('اعتماد'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApprovalService.approve(
      approvalId: approval['id'].toString(),
      specialistName: 'الوزارة',
    );

    final serverId = approval['server_id'] ?? approval['id'];
    await ApiService.approveMinistryRequest(
      serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم اعتماد الخطة وإشعار المختص والمعلم'),
        backgroundColor: Colors.green,
      ),
    );
    _load();
  }

  Future<void> _handleReject(Map approval) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('رفض الخطة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رفض خطة الطفل "${approval['child_name']}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                hintText: 'مثال: تحتاج مراجعة أهداف الخطة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.close),
            label: const Text('رفض'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApprovalService.reject(
      approvalId: approval['id'].toString(),
      reason:
          reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );

    final serverId = approval['server_id'] ?? approval['id'];
    await ApiService.rejectMinistryRequest(
      serverId is int ? serverId : int.tryParse(serverId.toString()) ?? 0,
      reason: reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ تم رفض الخطة وإشعار المختص'),
        backgroundColor: Colors.red,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionHeader(
            c,
            '📤 طلبات بانتظار المراجعة',
            '${_pending.length}',
            AppColors.orange,
          ),
          if (_pending.isEmpty)
            _emptyCard(c, 'لا توجد طلبات معلّقة حالياً')
          else
            ..._pending.map((a) => _approvalCard(a, c)),

          const SizedBox(height: 24),

          if (_processed.isNotEmpty) ...[
            _sectionHeader(
              c,
              '📋 سجل القرارات',
              '${_processed.length}',
              AppColors.teal,
            ),
            ..._processed.take(20).map((a) => _processedCard(a, c)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(JisrColors c, String title, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.heading,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(JisrColors c, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 60, color: c.muted),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: c.muted, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _approvalCard(Map a, JisrColors c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    (a['child_name'] ?? '؟').toString().characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['child_name'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'أُرسل: ${_formatDate(a['submitted_at'])}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '⏳ قيد المراجعة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orangeDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _miniRow('📚 الخطة التعليمية', a['educational_plan'], c),
            if (a['recommendations'] != null)
              _miniRow('📝 التوصيات', a['recommendations'], c),
            if (a['teacher_name'] != null)
              _miniRow('👨‍🏫 المعلم المقترح', a['teacher_name'], c),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    onPressed: () => _handleReject(a),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('اعتماد'),
                    onPressed: () => _handleApprove(a),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _processedCard(Map a, JisrColors c) {
    final status = a['status'] ?? 'pending';
    final isApproved = status == 'approved';
    final color = isApproved ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ),
        title: Text(
          a['child_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${isApproved ? "✅ معتمدة" : "❌ مرفوضة"} • ${_formatDate(a['decided_at'] ?? a['submitted_at'])}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
      ),
    );
  }

  Widget _miniRow(String label, dynamic value, JisrColors c) {
    if (value == null) return const SizedBox.shrink();
    final text = value.toString();
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.body),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final d = DateTime.tryParse(value.toString());
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ═══════════════════════════════════════════════════════
// 3. تبويب المستخدمون والأطفال (عرض فقط)
//    نفس تصميم الأدمن — لكن بدون تعديل/حذف
// ═══════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List _users = [];
  List _children = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.getMinistryUsers(),
        ApiService.getMinistryChildren(),
      ]);

      setState(() {
        _users = responses[0];
        _children = responses[1];
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  // ─── فلترة حسب الدور + البحث ───
  List _byRole(String role) {
    final term = _search.trim().toLowerCase();
    return _users.where((u) {
      if ((u['role'] ?? '').toString() != role) return false;
      if (term.isEmpty) return true;
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(term) || email.contains(term);
    }).toList();
  }

  List get _teachers => _byRole('teacher');
  List get _specialists => _byRole('specialist');
  List get _parents => _byRole('parent');

  // ─── الأطفال المرتبطون بمستخدم ───
  List _childrenForUser(Map user) {
    final userId = user['id'];
    final role = (user['role'] ?? '').toString();
    return _children.where((c) {
      if (role == 'teacher') {
        return c['assigned_teacher_id'] == userId;
      }
      if (role == 'specialist') {
        return c['assigned_specialist_id'] == userId ||
            c['specialist_id'] == userId;
      }
      if (role == 'parent') {
        return c['parent_id'] == userId || c['user_id'] == userId;
      }
      return false;
    }).toList();
  }

  List get _filteredChildren {
    final term = _search.trim().toLowerCase();
    if (term.isEmpty) return _children;
    return _children.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(term);
    }).toList();
  }

  String? _teacherNameFor(Map child) {
    final id = child['assigned_teacher_id'];
    if (id == null) return child['assigned_teacher_name']?.toString();
    for (final u in _users) {
      if (u['id'] == id && u['role'] == 'teacher') {
        return u['name']?.toString();
      }
    }
    return child['assigned_teacher_name']?.toString();
  }

  String? _specialistNameFor(Map child) {
    final id = child['assigned_specialist_id'] ?? child['specialist_id'];
    if (id == null) return child['specialist_name']?.toString();
    for (final u in _users) {
      if (u['id'] == id && u['role'] == 'specialist') {
        return u['name']?.toString();
      }
    }
    return child['specialist_name']?.toString();
  }

  // ─── عرض أطفال مستخدم (عرض فقط) ───
  void _showUserChildren(Map user) {
    final children = _childrenForUser(user);
    final role = (user['role'] ?? '').toString();
    final roleLabel = role == 'teacher'
        ? 'المعلّم'
        : role == 'specialist'
            ? 'المختص'
            : 'ولي الأمر';
    final roleEmoji =
        role == 'teacher' ? '👨‍🏫' : role == 'specialist' ? '🧩' : '👪';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: JisrColors.of(context).card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(roleEmoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أطفال $roleLabel ${user['name'] ?? ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: JisrColors.of(context).heading,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: JisrColors.of(context).tintTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.child_care,
                          size: 16, color: AppColors.tealDeep),
                      const SizedBox(width: 6),
                      Text(
                        '${children.length} ${children.length == 1 ? 'طفل' : 'أطفال'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // شارة "عرض فقط"
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.visibility,
                          size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'عرض فقط',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off,
                          size: 48, color: JisrColors.of(context).muted),
                      const SizedBox(height: 8),
                      Text(
                        'لا يوجد أطفال مرتبطون حالياً',
                        style: TextStyle(
                          color: JisrColors.of(context).muted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final child = children[i];
                    final name = (child['name'] ?? '').toString();
                    final age = child['age'] ?? '?';
                    final status =
                        (child['status'] ?? 'pending').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors
                            .kidPalette[i % AppColors.kidPalette.length],
                        child: Text(
                          name.isNotEmpty ? name.characters.first : '🙂',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('العمر: $age سنة'),
                      trailing: _StatusBadge(status: status),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _StateBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ─── شريط "عرض فقط" ───
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility,
                    color: AppColors.tealDeep, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'وضع العرض فقط — لا يمكن التعديل أو الحذف',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.onTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── حقل البحث ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '🔍 ابحث بالاسم أو البريد...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 16),

          // ─── المعلمون ───
          _buildUserSection(
            emoji: '👨‍🏫',
            title: 'المعلّمون',
            users: _teachers,
            color: AppColors.greenDeep,
            bgTint: c.tintGreen,
          ),

          // ─── المختصون ───
          _buildUserSection(
            emoji: '🧩',
            title: 'المختصون',
            users: _specialists,
            color: AppColors.orangeDeep,
            bgTint: c.tintOrange,
          ),

          // ─── أولياء الأمور ───
          _buildUserSection(
            emoji: '👪',
            title: 'أولياء الأمور',
            users: _parents,
            color: AppColors.tealDeep,
            bgTint: c.tintTeal,
          ),

          // ─── الأطفال ───
          _buildChildrenSection(),
        ],
      ),
    );
  }

  // ─── قسم المستخدمين (بدون أزرار) ───
  Widget _buildUserSection({
    required String emoji,
    required String title,
    required List users,
    required Color color,
    required Color bgTint,
  }) {
    final c = JisrColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${users.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (users.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Center(
                child: Text(
                  'لا يوجد $title مسجّلون',
                  style: TextStyle(color: c.muted, fontSize: 14),
                ),
              ),
            )
          else
            ...users.map((u) => _UserListTile(
                  user: u,
                  color: color,
                  assignedChildrenCount: _childrenForUser(u).length,
                  onTap: () => _showUserChildren(u),
                )),
        ],
      ),
    );
  }

  // ─── قسم الأطفال ───
  Widget _buildChildrenSection() {
    final c = JisrColors.of(context);
    final children = _filteredChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.tintYellow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('👶', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'الأطفال',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${children.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orangeDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Center(
              child: Text(
                'لا يوجد أطفال مسجّلون',
                style: TextStyle(color: c.muted, fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(children.length, (i) {
            final child = children[i];
            return _ChildListTile(
              child: child,
              color:
                  AppColors.kidPalette[i % AppColors.kidPalette.length],
              assignedTeacherName: _teacherNameFor(child),
              assignedSpecialistName: _specialistNameFor(child),
            );
          }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  بطاقة مستخدم (عرض فقط)
// ═══════════════════════════════════════════════════════
class _UserListTile extends StatelessWidget {
  final Map user;
  final Color color;
  final int assignedChildrenCount;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.color,
    required this.assignedChildrenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = user['phone']?.toString();
    final initial =
        name.trim().isNotEmpty ? name.trim().characters.first : '؟';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      if (phone != null && phone.isNotEmpty)
                        Text(
                          '📞 $phone',
                          style:
                              TextStyle(fontSize: 11.5, color: c.muted),
                        ),
                    ],
                  ),
                ),
                // شارة "X أطفال"
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: assignedChildrenCount > 0
                        ? AppColors.teal.withValues(alpha: 0.15)
                        : c.line.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👶', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '$assignedChildrenCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: assignedChildrenCount > 0
                              ? AppColors.tealDeep
                              : c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_left, color: c.muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  بطاقة طفل (عرض فقط)
// ═══════════════════════════════════════════════════════
class _ChildListTile extends StatelessWidget {
  final Map child;
  final Color color;
  final String? assignedTeacherName;
  final String? assignedSpecialistName;

  const _ChildListTile({
    required this.child,
    required this.color,
    this.assignedTeacherName,
    this.assignedSpecialistName,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = child['disability_type']?.toString();
    final status = (child['status'] ?? 'pending').toString();
    final initial =
        name.trim().isNotEmpty ? name.trim().characters.first : '🧒';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    'العمر: $age سنة'
                    '${disability != null && disability.isNotEmpty ? ' • $disability' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                  if (assignedTeacherName != null &&
                      assignedTeacherName!.isNotEmpty)
                    Text(
                      '👨‍🏫 $assignedTeacherName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.tealDeep,
                      ),
                    ),
                  if (assignedSpecialistName != null &&
                      assignedSpecialistName!.isNotEmpty)
                    Text(
                      '🧩 $assignedSpecialistName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.orangeDeep,
                      ),
                    ),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  شارة حالة الطفل
// ═══════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case 'evaluated':
        label = 'تم التقييم';
        color = AppColors.green;
        break;
      case 'assigned':
        label = 'تم التعيين';
        color = AppColors.teal;
        break;
      default:
        label = 'قيد الانتظار';
        color = AppColors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// مكوّنات مشتركة
// ═══════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color tint;

  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final Widget child;

  const _StateBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
