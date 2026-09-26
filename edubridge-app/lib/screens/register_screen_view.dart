part of 'register_screen.dart';

extension _RegisterScreenStateView on _RegisterScreenState {
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'إنشاء حساب'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const BrandLockup(iconSize: 68, fontSize: 38, gap: 10),
                  const SizedBox(height: 14),
                  Text(
                    'ابدأ رحلتك مع EduBridge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: JisrColors.of(context).heading,
                    ),
                  ),
                  const SizedBox(height: 22),

                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(AppIcons.profile),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'الإيميل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(AppIcons.notifications),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'الإيميل مطلوب';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'صيغة الإيميل غير صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    style: TextStyle(
                        fontSize: 18, color: JisrColors.of(context).body),
                    decoration: const InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(AppIcons.users),
                    ),
                    items: _RegisterScreenState._roles.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 18)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      _refreshState(() {
                        _role = v ?? 'parent';
                        if (_role != 'specialist') {
                          _specialty = 'learning_support';
                        }
                      });
                    },
                  ),

                  if (_needsSpecialty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _specialty,
                      decoration: const InputDecoration(
                        labelText: 'التخصص',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(AppIcons.specialist),
                      ),
                      items: _RegisterScreenState._specialties.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          _refreshState(() => _specialty = v ?? 'learning_support'),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    maxLength: 128,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(AppIcons.lock),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 8 || v.length > 128) {
                        return 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(AppIcons.lock),
                    ),
                    validator: (v) =>
                        v != _passwordCtrl.text
                            ? 'كلمتا المرور غير متطابقتين'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(AppIcons.error,
                                color: AppColors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: AppColors.red, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                      ),
                      onPressed: _loading ? null : _register,
                      icon: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(AppIcons.check),
                      label: Text(
                        _loading ? 'جارٍ الإنشاء...' : 'إنشاء الحساب',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  
  }
}
