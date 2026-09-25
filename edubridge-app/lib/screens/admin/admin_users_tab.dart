// lib/screens/admin/admin_users_tab.dart
part of 'admin_screen.dart';

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
          childrenList = childrenData['children'] ?? childrenData['data'] ?? [];
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
      if (role == 'teacher') return c['assigned_teacher_id'] == userId;
      if (role == 'specialist') {
        return c['assigned_specialist_id'] == userId || c['specialist_id'] == userId;
      }
      if (role == 'parent') return c['parent_id'] == userId || c['user_id'] == userId;
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
      if (u['id'] == id && u['role'] == 'teacher') return u['name']?.toString();
    }
    return child['assigned_teacher_name']?.toString();
  }

  String? _specialistNameFor(Map child) {
    final id = child['assigned_specialist_id'] ?? child['specialist_id'];
    if (id == null) return child['specialist_name']?.toString();
    for (final u in _users) {
      if (u['id'] == id && u['role'] == 'specialist') return u['name']?.toString();
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
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
          setState(() => _children.removeWhere((c) => c['id'] == child['id']));
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
          _users = _users.map((u) => u['id'] == updated['id'] ? updated : u).toList();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserChildrenSheet(
        user: user,
        children: children,
        onEditChild: _openEditChild,
      ),
    );
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
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
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
          _buildSearchBar(c),
          const SizedBox(height: 16),
          _buildUserSection(
            icon: AppIcons.teacher, title: 'المعلّمون',
            users: _teachers, color: AppColors.greenDeep, bgTint: c.tintGreen,
          ),
          _buildUserSection(
            icon: AppIcons.specialist, title: 'المختصون',
            users: _specialists, color: AppColors.brandTealDeep, bgTint: c.tintOrange,
          ),
          _buildUserSection(
            icon: AppIcons.parent, title: 'أولياء الأمور',
            users: _parents, color: AppColors.brandBlue, bgTint: c.tintTeal,
          ),
          _buildChildrenSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(JisrColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'ابحث بالاسم أو البريد...',
          prefixIcon: Icon(AppIcons.search),
          border: InputBorder.none,
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildUserSection({
    required IconData icon,
    required String title,
    required List users,
    required Color color,
    required Color bgTint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: icon, title: title, count: users.length,
            color: color, bgTint: bgTint,
          ),
          const SizedBox(height: 10),
          if (users.isEmpty)
            _EmptyBox(text: 'لا يوجد $title مسجّلون')
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
        _SectionHeader(
          icon: AppIcons.child, title: 'الأطفال', count: children.length,
          color: AppColors.brandTealDeep, bgTint: c.tintYellow,
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          const _EmptyBox(text: 'لا يوجد أطفال مسجّلون')
        else
          ...List.generate(children.length, (i) {
            final child = children[i];
            return _ChildListTile(
              child: child,
              color: AppColors.kidPalette[i % AppColors.kidPalette.length],
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

// ─── Bottom Sheet: أطفال المستخدم ───
