part of 'login_screen.dart';

extension _LoginScreenStateView on _LoginScreenState {
  Widget buildView(BuildContext context) {
    final colors = JisrColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          PositionedDirectional(
            top: -90,
            start: -100,
            child: _GlowCircle(
              size: 270,
              color: AppColors.brandTeal
                  .withValues(alpha: isDark ? .10 : .14),
            ),
          ),
          PositionedDirectional(
            bottom: -120,
            end: -90,
            child: _GlowCircle(
              size: 310,
              color: AppColors.brandBlue
                  .withValues(alpha: isDark ? .12 : .08),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const BrandLockup(
                        iconSize: 50,
                        fontSize: 29,
                        gap: 8,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'أهلاً بعودتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: colors.heading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'سجّل الدخول لمتابعة رحلة التعلّم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: colors.line),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandBlue
                                  .withValues(alpha: isDark ? .04 : .07),
                              blurRadius: 34,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'بيانات الدخول',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: colors.heading,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon:
                                      Icon(Icons.mail_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) {
                                  if (!_loading) _login();
                                },
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
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
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          ),
                                  child: const Text('نسيت كلمة المرور؟'),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.red
                                        .withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.red
                                          .withValues(alpha: .16),
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
                              if (_notice != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.green
                                        .withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.green
                                          .withValues(alpha: .16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mark_email_read_outlined,
                                        color: AppColors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _notice!,
                                          style: const TextStyle(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: _loading ? null : _login,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(
                                  _loading
                                      ? 'جارِ الدخول...'
                                      : 'تسجيل الدخول',
                                ),
                              ),
                              if (GoogleAuthService.isConfigured) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: colors.line)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'أو تابع باستخدام',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: colors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: colors.line)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue.withValues(
                                      alpha: isDark ? .08 : .04,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: colors.line),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_circle_outlined,
                                            color: AppColors.brandBlue,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'تسجيل الدخول باستخدام Google',
                                              style: TextStyle(
                                                color: colors.heading,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: _googleRole,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'نوع الحساب للحساب الجديد',
                                          prefixIcon:
                                              Icon(Icons.badge_outlined),
                                        ),
                                        items: _LoginScreenState
                                            ._googleRoles.entries
                                            .map(
                                              (entry) =>
                                                  DropdownMenuItem<String>(
                                                value: entry.key,
                                                child: Text(entry.value),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: _loading
                                            ? null
                                            : (value) {
                                                if (value != null) {
                                                  _refreshState(
                                                    () => _googleRole = value,
                                                  );
                                                }
                                              },
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        'هذا الاختيار للحسابات الجديدة فقط. الحساب الموجود يحتفظ بدوره الحالي.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: colors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed:
                                            _loading ? null : _googleLogin,
                                        icon: const Icon(
                                          Icons.account_circle_outlined,
                                        ),
                                        label: const Text(
                                          'المتابعة باستخدام Google',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed:
                                    _loading ? null : _resendVerification,
                                icon: const Icon(
                                  Icons.forward_to_inbox_outlined,
                                  size: 19,
                                ),
                                label: const Text(
                                  'إعادة إرسال رسالة تأكيد البريد',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: TextStyle(color: colors.muted),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text('أنشئ حساباً جديداً'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
