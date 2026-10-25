import '../widgets/language_selector.dart';
import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  Object? _error;
  Object? _notice;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = SharedUiMessage.validEmailRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    final error = await ApiService.forgotPassword(email);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (error == null) {
        _notice = SharedUiMessage.recoveryEmailNotice;
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: context.l10n.passwordRecovery,
        actions: const [LanguageMenuButton(color: Colors.white)],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: .06),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 58,
                      color: AppColors.brandBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.forgotPasswordQuestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.heading,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.recoveryDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) {
                        if (!_loading) _send();
                      },
                      decoration: InputDecoration(
                        labelText: context.l10n.email,
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.sharedMessage(_error),
                                style: const TextStyle(
                                  color: AppColors.red,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_notice != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: const TextStyle(
                                  color: AppColors.green,
                                  height: 1.45,
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
                      onPressed: _loading ? null : _send,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.forward_to_inbox_outlined),
                      label: Text(
                        _loading
                            ? context.l10n.sending
                            : context.l10n.sendRecoveryLink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.link_rounded, size: 18),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(
                            initialEmail: _emailCtrl.text.trim(),
                          ),
                        ),
                      ),
                      label: Text(context.l10n.haveRecoveryLink),
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
