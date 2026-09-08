import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'conversations_screen.dart';
import 'lessons_screen.dart';
import 'welcome_screen.dart';

/// لوحة وزارة التربية والتعليم.
class MinistryScreen extends StatefulWidget {
  const MinistryScreen({super.key});

  @override
  State<MinistryScreen> createState() => _MinistryScreenState();
}

class _MinistryScreenState extends State<MinistryScreen> {
  bool _loading = true;
  String? _error;
  int _usersCount = 0;
  int _childrenCount = 0;
  int _lessonsCount = 0;
  int _pendingUsersCount = 0;
  bool _usersAvailable = false;
  bool _childrenAvailable = false;
  bool _lessonsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        ApiService.getUsers().catchError((_) => <dynamic>[]),
        ApiService.getChildren().catchError((_) => null),
        ApiService.getLessons().catchError((_) => <dynamic>[]),
      ]);
      final users = results[0] as List<dynamic>;
      final childrenData = results[1] as Map<String, dynamic>?;
      final lessons = results[2] as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _usersCount = users.length;
        _usersAvailable = true;
        _pendingUsersCount = users
            .where((user) => user['verification_status'] == 'pending')
            .length;
        _childrenAvailable = childrenData != null;
        _childrenCount = childrenData == null
            ? 0
            : (childrenData['children'] as List<dynamic>? ?? []).length;
        _lessonsAvailable = true;
        _lessonsCount = lessons.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل بيانات لوحة الوزارة';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final colors = JisrColors.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(colors),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else
              _buildContent(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JisrColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset('assets/icon.png', width: 36, height: 36),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'جسر التعليمي - وزارة التربية والتعليم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'المحادثات',
                  icon: const Icon(Icons.chat_bubble, color: Colors.white),
                  onPressed: () => _open(const ConversationsScreen()),
                ),
                IconButton(
                  tooltip: 'خروج',
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<String?>(
              future: ApiService.getName(),
              builder: (context, snapshot) => Text(
                'مرحباً ${snapshot.data ?? 'بكم'} 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'متابعة مؤشرات التعليم وإدارة المحتوى والمستخدمين',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(JisrColors colors) {
    final usersValue = _usersAvailable ? '$_usersCount' : '-';
    final childrenValue = _childrenAvailable ? '$_childrenCount' : '-';
    final lessonsValue = _lessonsAvailable ? '$_lessonsCount' : '-';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المؤشرات الرئيسية',
            style: TextStyle(
              color: colors.heading,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // اجعل البطاقة أطول من أجل احتواء العنوان والقيمة دون overflow.
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard('المستخدمون', usersValue, Icons.people, colors.tintTeal,
                  colors),
              _statCard('الأطفال', childrenValue, Icons.child_care,
                  colors.tintOrange, colors),
              _statCard('الدروس', lessonsValue, Icons.menu_book,
                  colors.tintGreen, colors),
              _statCard('بانتظار المراجعة', '$_pendingUsersCount',
                  Icons.pending_actions, colors.tintYellow, colors),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'الخدمات',
            style: TextStyle(
              color: colors.heading,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _actionTile(
            icon: Icons.people_alt,
            title: 'دليل المستخدمين',
            subtitle: 'استعراض المستخدمين المسجلين في المنصة',
            color: colors.tintTeal,
            onTap: () => _open(const _MinistryUsersScreen()),
          ),
          _actionTile(
            icon: Icons.menu_book,
            title: 'المحتوى التعليمي',
            subtitle: 'تصفح الدروس والمواد التعليمية',
            color: colors.tintGreen,
            onTap: () => _open(const LessonsScreen()),
          ),
          _actionTile(
            icon: Icons.chat,
            title: 'المحادثات',
            subtitle: 'التواصل مع مستخدمي المنصة',
            color: colors.tintOrange,
            onTap: () => _open(const ConversationsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color tint,
      JisrColors colors) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.heading),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: colors.heading,
              ),
            ),
            Flexible(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.body),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: AppColors.navy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class _MinistryUsersScreen extends StatefulWidget {
  const _MinistryUsersScreen();

  @override
  State<_MinistryUsersScreen> createState() => _MinistryUsersScreenState();
}

class _MinistryUsersScreenState extends State<_MinistryUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await ApiService.getUsers();
      if (mounted)
        setState(() {
          _users = users;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'دليل المستخدمين'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (_, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text((user['name'] ?? 'مستخدم').toString()),
                      subtitle: Text(
                          '${user['email'] ?? ''}\n${_roleName(user['role'])}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _roleName(dynamic role) {
    const names = {
      'parent': 'ولي أمر',
      'teacher': 'معلّم',
      'specialist': 'مختص',
      'ministry': 'وزارة',
      'institution': 'مؤسسة',
      'admin': 'أدمن',
    };
    return names[role] ?? 'مستخدم';
  }
}
