import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

const _roleNames = {
  'parent': 'ولي أمر',
  'teacher': 'معلّم',
  'specialist': 'مختص',
  'admin': 'أدمن',
};

const _roleIcons = {
  'admin': '🛡️',
  'teacher': '📚',
  'specialist': '🧩',
  'parent': '👪',
};

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  static const _tabs = [
    ('👥', 'المستخدمين'),
    ('👶', 'الأطفال'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: const JisrAppBar(title: 'لوحة التحكم الإدارية'),
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
                ? const _UsersTab()
                : const _ChildrenTab(),
          ),
        ],
      ),
    );
  }
}

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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.tealDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.tealDeep.withValues(alpha: 0.45),
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

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List _users = [];
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
      final res = await ApiService.authGet('/users');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        List usersList = [];
        if (data is List) {
          usersList = data;
        } else if (data is Map) {
          usersList = data['users'] ?? data['data'] ?? [];
        }
        setState(() {
          _users = usersList;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر جلب المستخدمين';
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

  Future<void> _deleteUser(Map user) async {
    bool? confirm = await showDialog<bool>(
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
        // هنا يتم حذف المستخدم. تأكد أن الـ Backend يدعم هذا المسار
        // إذا لم يكن يدعم، سيظهر خطأ ويجب إضافة المسار في Laravel
        final res = await ApiService.authDelete('/users/${user['id']}'); 
        
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(() {
            _users.removeWhere((u) => u['id'] == user['id']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
          );
        } else {
          setState(() {
            _error = 'تعذّر حذف المستخدم. تأكد من دعم الـ Backend لهذه الخاصية.';
          });
        }
      } catch (_) {
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

  List get _filtered {
    final term = _search.trim().toLowerCase();
    if (term.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(term) || email.contains(term);
    }).toList();
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
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('👥', style: TextStyle(fontSize: 22, color: c.heading)),
                        const SizedBox(width: 8),
                        Text(
                          'إدارة المستخدمين',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '🔍 ابحث عن مستخدم...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('لا يوجد مستخدمون مطابقون', style: TextStyle(fontSize: 16)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _UserCard(
                    user: _filtered[i],
                    onEdit: () => _openEdit(_filtered[i]),
                    onDelete: () => _deleteUser(_filtered[i]),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  (Color bg, Color fg) _roleColors(String role) {
    switch (role) {
      case 'teacher':
        return (AppColors.tintGreen, AppColors.greenDeep);
      case 'specialist':
        return (AppColors.tintOrange, AppColors.orangeDeep);
      case 'admin':
        return (const Color(0xFFE6EDF4), AppColors.navy);
      default:
        return (const Color(0xFFECEFF2), AppColors.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final role = (user['role'] ?? 'parent').toString();
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = user['phone']?.toString();
    final (pillBg, pillFg) = _roleColors(role);
    final initial = name.trim().isNotEmpty ? name.trim().characters.first : '؟';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_roleIcons[role] ?? '👤'} ${_roleNames[role] ?? role}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pillFg,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: c.tintTeal,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tealDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('📞 $phone', style: TextStyle(fontSize: 12, color: c.muted)),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  child: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildrenTab extends StatefulWidget {
  const _ChildrenTab();

  @override
  State<_ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<_ChildrenTab> {
  List _children = [];
  bool _loading = true;
  String? _error;

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
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        List childrenList = [];
        if (data is List) {
          childrenList = data;
        } else if (data is Map) {
          childrenList = data['children'] ?? data['data'] ?? [];
        }
        setState(() {
          _children = childrenList;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر جلب الأطفال';
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

  Future<void> _deleteChild(Map child) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطفل'),
        content: Text('هل أنت متأكد من حuyذف "${child['name']}"؟'),
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
        // تأكد من وجود هذا المسار في الـ Backend
        final res = await ApiService.authDelete('/children/${child['id']}');
        
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(() {
            _children.removeWhere((c) => c['id'] == child['id']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الطفل بنجاح')),
          );
        } else {
          setState(() {
            _error = 'تعذّر حذف الطفل. تأكد من دعم الـ Backend لهذه الخاصية.';
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
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _children.isEmpty
          ? const Center(child: Text('لا يوجد أطفال مسجلين'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: const Icon(Icons.child_care, size: 40),
                  title: Text(child['name']?.toString() ?? ''),
                  subtitle: Text('العمر: ${child['age']?.toString() ?? '-'} سنة'),
                  trailing: IconButton(
                    onPressed: () => _deleteChild(child),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
}

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
    _name = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _email = TextEditingController(text: widget.user['email']?.toString() ?? '');
    _phone = TextEditingController(text: widget.user['phone']?.toString() ?? '');
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_role),
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: _roleNames.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
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