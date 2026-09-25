// lib/screens/ministry/ministry_users_tab.dart
part of 'ministry_screen.dart';

class _MinistryUsersTab extends StatefulWidget {
  const _MinistryUsersTab();

  @override
  State<_MinistryUsersTab> createState() => _MinistryUsersTabState();
}

class _MinistryUsersTabState extends State<_MinistryUsersTab> {
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

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.view, color: AppColors.brandBlue, size: 18),
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
          Container(
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
          ),
          const SizedBox(height: 16),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.teacher,
            title: 'المعلّمون',
            users: _teachers,
            color: AppColors.greenDeep,
            bgTint: c.tintGreen,
            childrenForUser: _childrenForUser,
          ),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.specialist,
            title: 'المختصون',
            users: _specialists,
            color: AppColors.orangeDeep,
            bgTint: c.tintOrange,
            childrenForUser: _childrenForUser,
          ),
          _buildMinistryUserSection(
            context: context,
            icon: AppIcons.parent,
            title: 'أولياء الأمور',
            users: _parents,
            color: AppColors.brandBlue,
            bgTint: c.tintTeal,
            childrenForUser: _childrenForUser,
          ),
        ],
      ),
    );
  }
}

Widget _buildMinistryUserSection({
  required BuildContext context,
  required IconData icon,
  required String title,
  required List users,
  required Color color,
  required Color bgTint,
  required List Function(Map) childrenForUser,
}) {
  final c = JisrColors.of(context);

  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${users.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
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
              child: Text('لا يوجد $title مسجّلون',
                  style: TextStyle(color: c.muted, fontSize: 14)),
            ),
          )
        else
          ...users.map((u) => _MinistryUserTile(
                user: u,
                color: color,
                childrenCount: childrenForUser(u).length,
              )),
      ],
    ),
  );
}

class _MinistryUserTile extends StatelessWidget {
  final Map user;
  final Color color;
  final int childrenCount;

  const _MinistryUserTile({
    required this.user,
    required this.color,
    required this.childrenCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = user['phone']?.toString();
    final initial = name.trim().isNotEmpty ? name.trim().characters.first : '؟';

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
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.muted)),
                  if (phone != null && phone.isNotEmpty)
                    Text(phone, style: TextStyle(fontSize: 11.5, color: c.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: childrenCount > 0
                    ? AppColors.brandTeal.withValues(alpha: 0.15)
                    : c.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.child,
                      size: 14,
                      color: childrenCount > 0 ? AppColors.brandBlue : c.muted),
                  const SizedBox(width: 4),
                  Text('$childrenCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: childrenCount > 0 ? AppColors.brandBlue : c.muted,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}