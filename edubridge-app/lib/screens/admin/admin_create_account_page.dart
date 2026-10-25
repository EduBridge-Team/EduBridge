part of 'admin_screen.dart';

class _CreateAccountForm extends StatefulWidget {
  const _CreateAccountForm({required this.initialRole});

  final String initialRole;

  @override
  State<_CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<_CreateAccountForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _error = null; });
    try {
      final response = await ApiService.authPost('/users', {
        'name': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': _phone.text.trim(),
        'role': _role,
        'password': _password.text,
        'password_confirmation': _confirmation.text,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        return;
      }
      final data = ApiService.decodeMap(response.body);
      setState(() => _error = data['error'] ?? data['message'] ?? SharedUiMessage.accountCreateFailed);
    } catch (_) {
      if (mounted) setState(() => _error = SharedUiMessage.connectionFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name, enabled: !_saving, maxLength: 150,
                  decoration: InputDecoration(labelText: context.l10n.institutionMinistryName),
                  validator: (value) => (value ?? '').trim().isEmpty ? context.l10n.adminNameRequired : null,
                ),
                TextFormField(
                  controller: _email, enabled: !_saving, maxLength: 255,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: context.l10n.email),
                  validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim()) ? null : context.l10n.validEmailRequired,
                ),
                TextFormField(
                  controller: _phone, enabled: !_saving, maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: context.l10n.phoneOptional),
                ),
                TextFormField(
                  controller: _password, enabled: !_saving, obscureText: true,
                  autocorrect: false, enableSuggestions: false,
                  decoration: InputDecoration(labelText: context.l10n.password),
                  validator: (value) => (value ?? '').length < 8 || (value ?? '').length > 128 ? context.l10n.passwordLengthRange : null,
                ),
                TextFormField(
                  controller: _confirmation, enabled: !_saving, obscureText: true,
                  autocorrect: false, enableSuggestions: false,
                  decoration: InputDecoration(labelText: context.l10n.confirmPassword),
                  validator: (value) => value != _password.text ? context.l10n.passwordConfirmationMismatch : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(context.sharedMessage(_error), style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? context.l10n.creatingAccount : context.l10n.createAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCreateAccountPage extends StatelessWidget {
  const _AdminCreateAccountPage({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(
            '${context.l10n.createAccount} — ${role == 'institution' ? context.l10n.institutionRole : context.l10n.ministryRole}',
          ),
        ),
        body: _CreateAccountForm(initialRole: role),
      );
}
