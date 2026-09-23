import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/accessibility/profile_avatar_button.dart';
import '../widgets/dashboard_menu.dart';
import '../widgets/legal_links_button.dart';
import '../utils/safe_bottom.dart';
import 'edit_child_screen.dart';

const _roleNames = {
  'parent': 'ولي أمر',
  'teacher': 'معلّم',
  'specialist': 'مختص',
  'admin': 'أدمن',
};

class AdminScreen extends StatefulWidget {
  final Map admin;

  const AdminScreen({super.key, required this.admin});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  static const _tabs = [
    ('👥', 'المستخدمون'),
    ('🛡️', 'مراجعة التوثيق'),
    ('🎧', 'الدعم الفني'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      // ✅ AppBar مخصص مع: رجوع + بحث + بروفايل + هامبرغر
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
       
        title: const Text(
          'لوحة التحكم الإدارية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: false,
        actions: [
          // ✅ زر البحث بالهوية
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'البحث بالهوية',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchByIdentityScreen(),
                ),
              );
            },
          ),

          // ✅ زر البروفايل
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: ProfileAvatarButton(
                size: 38,
                backgroundColor: Colors.white,
              ),
            ),
          ),

          // ✅ قائمة الهامبرغر
          DashboardMenu(
            actions: [
              DashboardMenuAction(
                id: 'legal',
                label: 'الخصوصية والحساب',
                icon: Icons.privacy_tip_outlined,
                onSelected: () => const LegalLinksButton().show(context),
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
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text('⚙️', style: TextStyle(fontSize: 24, color: c.heading)),
                const SizedBox(width: 8),
                Text(
                  'لوحة التحكم الإدارية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AdminTabBar(
              tabs: _tabs,
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tab == 0
                ? _UsersTab(admin: widget.admin)
                : _tab == 1
                    ? const _VerificationTab()
                    : _SupportTicketsTab(admin: widget.admin),
          ),
        ],
      ),
    );
  }
}

// ===== شريط التبويبات =====
class _AdminTabBar extends StatelessWidget {
  final List<(String, String)> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const _AdminTabBar({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          final (icon, label) = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.tealDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color:
                                AppColors.tealDeep.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$icon $label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
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

// ═══════════════════════════════════════════════════════════
//  تبويب موحّد: المستخدمون + الأطفال
// ═══════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final Map admin;
  const _UsersTab({required this.admin});

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
        ApiService.authGet('/users'),
        ApiService.authGet('/children'),
      ]);

      final usersRes = responses[0];
      final childrenRes = responses[1];

      if (usersRes.statusCode != 200) {
        final data = jsonDecode(usersRes.body);
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر جلب المستخدمين';
          _loading = false;
        });
        return;
      }

      final usersData = jsonDecode(usersRes.body);
      List usersList = [];
      if (usersData is List) {
        usersList = usersData;
      } else if (usersData is Map) {
        usersList = usersData['users'] ?? usersData['data'] ?? [];
      }

      List childrenList = [];
      if (childrenRes.statusCode == 200) {
        final childrenData = jsonDecode(childrenRes.body);
        if (childrenData is Map) {
          childrenList =
              childrenData['children'] ?? childrenData['data'] ?? [];
        } else if (childrenData is List) {
          childrenList = childrenData;
        }
      }

      setState(() {
        _users = usersList;
        _children = childrenList;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

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
        return c['parent_id'] == userId ||
            c['user_id'] == userId;
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
    if (id == null) return null;
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

  Future<void> _deleteUser(Map user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف "${user['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.authDelete('/users/${user['id']}');
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(() => _users.removeWhere((u) => u['id'] == user['id']));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر حذف المستخدم')),
          );
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    }
  }

  Future<void> _deleteChild(Map child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطفل'),
        content: Text('هل أنت متأكد من حذف "${child['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.authDelete('/children/${child['id']}');
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(
              () => _children.removeWhere((c) => c['id'] == child['id']));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الطفل بنجاح')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر حذف الطفل')),
          );
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    }
  }

  void _openEdit(Map user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserSheet(
        user: user,
        onSaved: (updated) => setState(() {
          _users = _users
              .map((u) => u['id'] == updated['id'] ? updated : u)
              .toList();
        }),
      ),
    );
  }

  void _openEditChild(Map child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditChildScreen(
          child: child,
          currentUserRole: 'admin',
          currentUser: widget.admin,
        ),
      ),
    ).then((result) {
      if (result == true) _load();
    });
  }

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
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openEditChild(child);
                      },
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

          _buildUserSection(
            emoji: '👨‍🏫',
            title: 'المعلّمون',
            users: _teachers,
            color: AppColors.greenDeep,
            bgTint: c.tintGreen,
          ),
          _buildUserSection(
            emoji: '🧩',
            title: 'المختصون',
            users: _specialists,
            color: AppColors.orangeDeep,
            bgTint: c.tintOrange,
          ),
          _buildUserSection(
            emoji: '👪',
            title: 'أولياء الأمور',
            users: _parents,
            color: AppColors.tealDeep,
            bgTint: c.tintTeal,
          ),
          _buildChildrenSection(),
        ],
      ),
    );
  }

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
                  onEdit: () => _openEdit(u),
                  onDelete: () => _deleteUser(u),
                )),
        ],
      ),
    );
  }

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
              onTap: () => _openEditChild(child),
              onDelete: () => _deleteChild(child),
            );
          }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة مستخدم
// ═══════════════════════════════════════════════════════════
class _UserListTile extends StatelessWidget {
  final Map user;
  final Color color;
  final int assignedChildrenCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserListTile({
    required this.user,
    required this.color,
    required this.assignedChildrenCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit,
                      size: 20, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: onEdit,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined,
                      size: 20, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة طفل
// ═══════════════════════════════════════════════════════════
class _ChildListTile extends StatelessWidget {
  final Map child;
  final Color color;
  final String? assignedTeacherName;
  final String? assignedSpecialistName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChildListTile({
    required this.child,
    required this.color,
    this.assignedTeacherName,
    this.assignedSpecialistName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (child['name'] ?? '').toString();
    final age = child['age'] ?? '?';
    final disability = child['disability_type']?.toString();
    final initial =
        name.trim().isNotEmpty ? name.trim().characters.first : '🧒';

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
                IconButton(
                  icon: const Icon(Icons.edit_attributes_outlined,
                      size: 20, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: onTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined,
                      size: 20, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  شارة حالة الطفل
// ═══════════════════════════════════════════════════════════
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

// ===== تبويب مراجعة التوثيق =====
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

    if (success) {
      setState(() {
        _requests.removeWhere((r) => r['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? '✅ تم اعتماد الطلب' : '❌ تم رفض الطلب'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشلت العملية')),
      );
    }
  }

  List get _filteredRequests {
    return _requests
        .where((r) => r['type'] == _filter || _filter == 'all')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadRequests,
                child: const Text('إعادة المحاولة')),
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
                  child: Text(
                    'لا توجد طلبات معلقة',
                    style: TextStyle(fontSize: 18, color: c.muted),
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
          color: selected ? AppColors.tealDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.tealDeep : Colors.grey.shade300),
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
        case 'children':
          return Icons.child_care;
        case 'certificates':
          return Icons.workspace_premium;
        default:
          return Icons.person;
      }
    }

    String getTypeName() {
      switch (type) {
        case 'children':
          return 'طفل';
        case 'certificates':
          return 'شهادة';
        default:
          return 'مستخدم';
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
              child: Icon(getIcon(), color: AppColors.tealDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: c.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.tintOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      getTypeName(),
                      style: TextStyle(
                          fontSize: 12,
                          color: c.onTint,
                          fontWeight: FontWeight.bold),
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
                    backgroundColor: Colors.green,
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
                    foregroundColor: Colors.red,
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

// ===== تبويب الدعم الفني =====
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
        content: Text(
            'هل أنت متأكد من حل هذه الشكوى؟ سيتم إرسال إشعار للمستخدم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('تم الحل', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.authPut(
            '/support/tickets/${ticket['id']}/resolve', {});
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    }
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
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadTickets,
                child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: _tickets.isEmpty
          ? const Center(child: Text('لا توجد شكاوى حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                final user = ticket['user'] ?? {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.support_agent,
                        color: AppColors.orange),
                    title: Text(ticket['subject']?.toString() ??
                        'بدون موضوع'),
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
                            style: TextStyle(
                                fontSize: 12, color: c.muted),
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

// ===== تعديل مستخدم (BottomSheet) =====
class _EditUserSheet extends StatefulWidget {
  final Map user;
  final ValueChanged<Map> onSaved;

  const _EditUserSheet({required this.user, required this.onSaved});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late String _role;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name =
        TextEditingController(text: widget.user['name']?.toString() ?? '');
    _email =
        TextEditingController(text: widget.user['email']?.toString() ?? '');
    _phone =
        TextEditingController(text: widget.user['phone']?.toString() ?? '');
    _role = widget.user['role']?.toString() ?? 'parent';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPut('/users/${widget.user['id']}', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'role': _role,
        'phone': _phone.text.trim(),
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        widget.onSaved(data['user']);
        Navigator.pop(context);
      } else {
        setState(() {
          _error = data['error'] ?? 'تعذّر حفظ التعديلات';
          _saving = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final bottom = safeModalBottom(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'تعديل المستخدم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_role),
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: _roleNames.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: 'اختياري',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green),
                      child: Text(_saving ? 'جارِ الحفظ...' : 'حفظ'),
                    ),
                  ),
                ],
              ),
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

// ===== شاشة البحث بالهوية =====
class SearchByIdentityScreen extends StatefulWidget {
  const SearchByIdentityScreen({super.key});

  @override
  State<SearchByIdentityScreen> createState() =>
      _SearchByIdentityScreenState();
}

class _SearchByIdentityScreenState extends State<SearchByIdentityScreen> {
  final _searchCtrl = TextEditingController();
  List _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await ApiService.searchByIdentity(query);
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر البحث';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'البحث بالهوية'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رقم الهوية...',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('بحث'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 64, color: c.muted),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد نتائج مطابقة',
                                  style: TextStyle(
                                      fontSize: 18, color: c.muted),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final result = _results[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: c.tintTeal,
                                    child: Icon(
                                      result['type'] == 'child'
                                          ? Icons.child_care
                                          : Icons.person,
                                      color: AppColors.tealDeep,
                                    ),
                                  ),
                                  title: Text(result['name'] ?? ''),
                                  subtitle: Text(
                                    '${result['type'] == 'child' ? 'طفل' : result['role'] == 'parent' ? 'ولي أمر' : result['role']} • ${result['national_id'] ?? ''}',
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_left),
                                  onTap: () {
                                    // يمكنك فتح تفاصيل المستخدم/الطفل هنا
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}