// لوحة التحكم الإدارية — أدمن فقط
// تبويبان: جميع المستخدمين · ربط طفل بولي أمر
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
    ('👥', 'جميع المستخدمين'),
    ('🔗', 'ربط طفل بولي أمر'),
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
                : const _LinkTab(),
          ),
        ],
      ),
    );
  }
}

/// شريط تبويبات دائري — مطابق لتصميم الموقع
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

/* ============ تبويب: جميع المستخدمين ============ */
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
        setState(() {
          _users = data['users'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب المستخدمين';
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

  void _onUserSaved(Map updated) {
    setState(() {
      _users = _users
          .map((u) => u['id'] == updated['id'] ? updated : u)
          .toList();
    });
  }

  void _openEdit(Map user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserSheet(
        user: user,
        onSaved: (updated) {
          _onUserSaved(updated);
          Navigator.pop(context);
        },
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
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
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

  const _UserCard({required this.user, required this.onEdit});

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
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              textStyle: const TextStyle(fontSize: 15),
            ),
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }
}

/* ============ نافذة تعديل مستخدم ============ */
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

/* ============ تبويب: ربط طفل بولي أمر ============ */
class _LinkTab extends StatefulWidget {
  const _LinkTab();

  @override
  State<_LinkTab> createState() => _LinkTabState();
}

class _LinkTabState extends State<_LinkTab> {
  List _children = [];
  List _parents = [];
  bool _loading = true;
  String? _error;

  String? _childId;
  String? _parentId;
  bool _submitting = false;
  String? _resultMsg;
  bool _resultOk = false;

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
      final results = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/users?role=parent'),
      ]);
      final childData = jsonDecode(results[0].body);
      final parentData = jsonDecode(results[1].body);

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        setState(() {
          _children = childData['children'] ?? [];
          _parents = parentData['users'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = childData['error'] ?? parentData['error'] ?? 'تعذّر التحميل';
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

  Future<void> _submit() async {
    setState(() => _resultMsg = null);

    if (_childId == null || _parentId == null) {
      setState(() {
        _resultOk = false;
        _resultMsg = 'اختر الطفل وولي الأمر أولاً';
      });
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await ApiService.authPost('/children/$_childId/parents', {
        'parent_id': int.parse(_parentId!),
      });
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final childName = _children
            .cast<Map>()
            .firstWhere((c) => c['id'].toString() == _childId)['name'];
        final parentName = _parents
            .cast<Map>()
            .firstWhere((p) => p['id'].toString() == _parentId)['name'];
        setState(() {
          _resultOk = true;
          _resultMsg = 'تم ربط «$childName» بولي الأمر «$parentName»';
          _childId = null;
          _parentId = null;
          _submitting = false;
        });
      } else {
        setState(() {
          _resultOk = false;
          _resultMsg = data['error'] ?? 'تعذّر الربط';
          _submitting = false;
        });
      }
    } catch (_) {
      setState(() {
        _resultOk = false;
        _resultMsg = 'تعذّر الاتصال بالسيرفر';
        _submitting = false;
      });
    }
  }

  String _parentLabel(Map parent) {
    final name = parent['name']?.toString() ?? '';
    final email = parent['email']?.toString() ?? '';
    return email.isNotEmpty ? '$name ($email)' : name;
  }

  Future<void> _pickChild(BuildContext context) async {
    if (_children.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet(
        title: 'اختر الطفل',
        items: _children.map((c) {
          final id = c['id'].toString();
          return (id, c['name']?.toString() ?? '');
        }).toList(),
      ),
    );
    if (picked != null) setState(() => _childId = picked);
  }

  Future<void> _pickParent(BuildContext context) async {
    if (_parents.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet(
        title: 'اختر ولي الأمر',
        items: _parents.map((p) {
          final id = p['id'].toString();
          return (id, _parentLabel(p));
        }).toList(),
      ),
    );
    if (picked != null) setState(() => _parentId = picked);
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
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                Text('🔗', style: TextStyle(fontSize: 22, color: c.heading)),
                const SizedBox(width: 8),
                Text(
                  'ربط طفل بولي أمر',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PickerField(
              label: 'الطفل',
              value: _childId == null
                  ? null
                  : (_children.cast<Map>().firstWhere(
                        (c) => c['id'].toString() == _childId,
                        orElse: () => {},
                      )['name']
                      ?.toString()),
              placeholder: '— اختر الطفل —',
              onTap: () => _pickChild(context),
            ),
            const SizedBox(height: 16),
            _PickerField(
              label: 'ولي الأمر',
              value: _parentId == null
                  ? null
                  : _parentLabel(
                      _parents.cast<Map>().firstWhere(
                        (p) => p['id'].toString() == _parentId,
                        orElse: () => {},
                      ),
                    ),
              placeholder: '— اختر ولي الأمر —',
              onTap: () => _pickParent(context),
            ),
            if (_resultMsg != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _resultOk ? c.tintGreen : AppColors.tintOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultMsg!,
                  style: TextStyle(
                    color: _resultOk ? c.success : AppColors.orangeDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'جارِ الربط...' : '🔗 ربط'),
            ),
            if (_children.isEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'لا يوجد أطفال بعد لربطهم.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted),
              ),
            ],
            if (_parents.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'لا يوجد أولياء أمور مسجّلون بعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted),
              ),
            ],
          ],
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

/// حقل اختيار — يفتح قائمة من الأسفل بدل القائمة المنسدلة (أنسب للموبايل)
class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final display = (value != null && value!.isNotEmpty) ? value! : placeholder;
    final isPlaceholder = value == null || value!.isEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.expand_more, color: c.muted),
        ),
        child: Text(
          display,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            color: isPlaceholder ? c.muted : c.body,
          ),
        ),
      ),
    );
  }
}

/// قائمة اختيار من الأسفل
class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String id, String label)> items;

  const _PickerSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.55;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: c.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: c.line),
              itemBuilder: (context, i) {
                final (id, label) = items[i];
                return ListTile(
                  title: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
