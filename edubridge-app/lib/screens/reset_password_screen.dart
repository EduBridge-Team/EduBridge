import '../widgets/language_selector.dart';
import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialEmail, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tokenCtrl;
  final _linkCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _tokenCtrl = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _linkCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _parseLink() {
    final value = _linkCtrl.text.trim();
    final uri = Uri.tryParse(value);
    final email = uri?.queryParameters['email'];
    final token = uri?.queryParameters['token'];
    if (email == null || token == null || email.isEmpty || token.isEmpty) {
      setState(() => _error = SharedUiMessage.invalidRecoveryLink);
      return;
    }
    setState(() {
      _emailCtrl.text = email;
      _tokenCtrl.text = token;
      _error = null;
    });
  }

  Future<void> _reset() async {
    if (_passwordCtrl.text.length < 8) {
      setState(() => _error = SharedUiMessage.passwordEightMinimum);
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = SharedUiMessage.passwordConfirmationMismatch);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _tokenCtrl.text.trim().isEmpty) {
      setState(() => _error = SharedUiMessage.pasteRecoveryLinkFirst);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await ApiService.resetPassword(
      _emailCtrl.text.trim(),
      _tokenCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
        title: context.l10n.setNewPassword,
        actions: const [LanguageMenuButton(color: Colors.white)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.pasteRecoveryLinkDescription,
                      style: TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _linkCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: context.l10n.recoveryLink,
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _parseLink,
                      icon: const Icon(Icons.auto_fix_high),
                      label: Text(context.l10n.readLink),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: context.l10n.newPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: context.l10n.confirmPassword,
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.sharedMessage(_error),
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _reset,
                      child: Text(
                        _loading
                            ? context.l10n.updating
                            : context.l10n.changePassword,
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
