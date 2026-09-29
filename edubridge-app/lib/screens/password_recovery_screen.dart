import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'أدخل بريداً إلكترونياً صالحاً');
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
        _notice =
            'إذا كان البريد مسجلاً فستصلك رسالة استعادة. افتح الرابط في الرسالة أو الصقه هنا لإكمال التغيير.';
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: const JisrAppBar(title: 'استعادة كلمة المرور'),
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
                      'نسيت كلمة المرور؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.heading,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل بريدك وسنرسل رابط استعادة صالحاً لمدة 60 دقيقة.',
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
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
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
                                _error!,
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
                                _notice!,
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
                        _loading ? 'جارِ الإرسال...' : 'إرسال رابط الاستعادة',
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
                      label: const Text('لدي رابط استعادة'),
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

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialToken;

  const ResetPasswordScreen({
    super.key,
    this.initialEmail,
    this.initialToken,
  });

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
  String? _error;

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
      setState(() => _error = 'رابط الاستعادة غير صالح');
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
      setState(() => _error = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'تأكيد كلمة المرور غير مطابق');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _tokenCtrl.text.trim().isEmpty) {
      setState(() => _error = 'الصق رابط الاستعادة أولاً');
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'تعيين كلمة مرور جديدة'),
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
                    const Text(
                      'الصق رابط الاستعادة الذي وصلك بالبريد، ثم اختر كلمة مرور جديدة.',
                      style: TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _linkCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'رابط الاستعادة',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _parseLink,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('قراءة الرابط'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.red)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _reset,
                      child: Text(_loading
                          ? 'جارِ التحديث...'
                          : 'تغيير كلمة المرور'),
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
