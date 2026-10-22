part of 'login_screen.dart';

extension _LoginScreenStateView on _LoginScreenState {
  Widget buildView(BuildContext context) {
    final colors = JisrColors.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

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
                      const Align(alignment: AlignmentDirectional.centerEnd,
                        child: LanguageCircleButton()),
                      const BrandLockup(
                        iconSize: 50,
                        fontSize: 32,
                        gap: 8,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.welcomeBack,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          height: 1.2,
                          color: colors.heading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
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
                                context.l10n.loginDetails,
                                style: textTheme.titleSmall?.copyWith(
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
                                decoration: InputDecoration(
                                  labelText: context.l10n.email,
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
                                  labelText: context.l10n.password,
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
                                        ? context.l10n.showPassword
                                        : context.l10n.hidePassword,
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
                                  child: Text(context.l10n.forgotPasswordQuestion),
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
                                          context.sharedMessage(_error),
                                          style: textTheme.bodyMedium?.copyWith(
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
                                          context.sharedMessage(_notice),
                                          style: textTheme.bodyMedium?.copyWith(
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
                                      ? context.l10n.signingIn
                                      : context.l10n.signIn,
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
                                        context.l10n.orContinueWith,
                                        style: textTheme.labelSmall?.copyWith(
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
                                              context.l10n.signInWithGoogle,
                                              style: textTheme.bodyMedium?.copyWith(
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
                                        decoration: InputDecoration(
                                          labelText:
                                              context.l10n.newAccountType,
                                          prefixIcon:
                                              Icon(Icons.badge_outlined),
                                        ),
                                        items: _googleRoles.entries
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
                                        context.l10n.newGoogleAccountRoleNotice,
                                        style: textTheme.bodySmall?.copyWith(
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
                                        label: Text(
                                          context.l10n.continueWithGoogle,
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
                                label: Text(
                                  context.l10n.resendVerificationEmail,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            context.l10n.noAccountQuestion,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: Text(context.l10n.createAccountLink),
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
