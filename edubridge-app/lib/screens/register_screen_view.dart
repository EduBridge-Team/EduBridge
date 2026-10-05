part of 'register_screen.dart';

extension _RegisterScreenStateView on _RegisterScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const JisrAppBar(title: 'إنشاء حساب'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const BrandLockup(
                      iconSize: 42,
                      fontSize: 25,
                      gap: 6,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ابدأ رحلتك مع EduBridge',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أنشئ حسابك الآن، ويمكنك استكمال بياناتك وتوثيق حسابك لاحقًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: c.line),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(
                              alpha: isDark ? .04 : .06,
                            ),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'المعلومات الأساسية',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل',
                              prefixIcon: Icon(AppIcons.profile),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'الاسم مطلوب'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'البريد الإلكتروني مطلوب';
                              }
                              final email = v.trim();
                              if (!email.contains('@') ||
                                  !email.split('@').last.contains('.')) {
                                return 'صيغة البريد الإلكتروني غير صحيحة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Divider(color: c.line),
                          const SizedBox(height: 16),
                          Text(
                            'نوع الحساب',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'اختر الدور الذي سيُستخدم للوصول إلى ميزات EduBridge المناسبة لك.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _role,
                            isExpanded: true,
                            alignment: AlignmentDirectional.centerStart,
                            decoration: const InputDecoration(
                              labelText: 'الدور',
                              prefixIcon: Icon(AppIcons.users),
                            ),
                            items: _RegisterScreenState._roles.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(e.value),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _loading
                                ? null
                                : (v) {
                                    _refreshState(() {
                                      _role = v ?? 'parent';
                                      if (_role != 'specialist') {
                                        _specialty = 'learning_support';
                                      }
                                    });
                                  },
                          ),
                          if (_needsSpecialty) ...[
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _specialty,
                              isExpanded: true,
                              alignment: AlignmentDirectional.centerStart,
                              decoration: const InputDecoration(
                                labelText: 'التخصص',
                                prefixIcon: Icon(AppIcons.specialist),
                              ),
                              items: _RegisterScreenState._specialties.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(e.value),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _loading
                                  ? null
                                  : (v) => _refreshState(
                                        () => _specialty =
                                            v ?? 'learning_support',
                                      ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Divider(color: c.line),
                          const SizedBox(height: 16),
                          Text(
                            'الأمان',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'استخدم كلمة مرور لا تقل عن 8 أحرف.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            maxLength: 128,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(AppIcons.lock),
                              counterText: '',
                              suffixIcon: IconButton(
                                onPressed: () => _refreshState(
                                  () => _obscurePassword =
                                      !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                tooltip: _obscurePassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'كلمة المرور مطلوبة';
                              }
                              if (v.length < 8 || v.length > 128) {
                                return 'كلمة المرور يجب أن تكون بين 8 و128 حرفاً';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirmPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) {
                              if (!_loading) _register();
                            },
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: const Icon(AppIcons.lock),
                              suffixIcon: IconButton(
                                onPressed: () => _refreshState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                tooltip: _obscureConfirmPassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'أعد كتابة كلمة المرور';
                              }
                              return v != _passwordCtrl.text
                                  ? 'كلمتا المرور غير متطابقتين'
                                  : null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppColors.red.withValues(alpha: .16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    AppIcons.error,
                                    color: AppColors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _loading ? null : _register,
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Icon(AppIcons.check),
                            label: Text(
                              _loading
                                  ? 'جارٍ إنشاء الحساب...'
                                  : 'إنشاء الحساب',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'بإنشاء الحساب، ستحتاج إلى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
