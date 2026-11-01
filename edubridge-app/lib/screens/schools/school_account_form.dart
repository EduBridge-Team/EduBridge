import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_account.dart';
import '../../services/schools/school_account_repository.dart';
import '../../theme.dart';
import 'school_account_failure_message.dart';
import 'school_account_receipt.dart';

enum SchoolAccountScope { independent, affiliated }

/// Shared presentation for both provisioning flows; HTTP belongs in the repository.
class SchoolAccountForm extends StatefulWidget {
  const SchoolAccountForm({super.key, required this.scope, this.repository});
  final SchoolAccountScope scope;
  final SchoolAccountRepository? repository;

  @override
  State<SchoolAccountForm> createState() => _SchoolAccountFormState();
}

class _SchoolAccountFormState extends State<SchoolAccountForm> {
  var _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  late SchoolAccountRepository _repository;
  bool _submitting = false;
  SchoolAccount? _createdAccount;
  int _generation = 0;
  SchoolAccountException? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SchoolAccountRepository();
  }

  @override
  void didUpdateWidget(covariant SchoolAccountForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope || oldWidget.repository != widget.repository) {
      _generation++;
      _formKey = GlobalKey<FormState>();
      _repository = widget.repository ?? SchoolAccountRepository();
      _submitting = false;
      _createdAccount = null;
      _error = null;
      for (final controller in [_name, _email, _password, _passwordConfirmation, _phone, _address]) {
        controller.clear();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _passwordConfirmation,
      _phone,
      _address,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _createdAccount != null) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final request = SchoolAccountRequest(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      passwordConfirmation: _passwordConfirmation.text,
      phone: _phone.text,
      address: _address.text,
    );
    final generation = _generation;
    final repository = _repository;
    final scope = widget.scope;
    setState(() => _submitting = true);
    try {
      final account = scope == SchoolAccountScope.independent
          ? await repository.createIndependent(request)
          : await repository.createAffiliated(request);
      if (!mounted || generation != _generation) return;
      setState(() => _createdAccount = account);
    } on SchoolAccountException catch (error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    } on Exception {
      if (mounted && generation == _generation) {
        setState(
          () => _error = const SchoolAccountException(
            SchoolAccountFailure.uncertain,
          ),
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _submitting = false);
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    int? maxLength,
    bool secret = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('school-account-$key'),
      controller: controller,
      enabled: !_submitting,
      maxLength: maxLength,
      obscureText: secret,
      autocorrect: !secret,
      enableSuggestions: !secret,
      keyboardType: keyboard,
      validator: validator,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: _error?.fields.contains(key) == true
            ? context.l10n.schoolAccountFieldRejected
            : null,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final independent = widget.scope == SchoolAccountScope.independent;
    return PopScope(canPop: !_submitting, child: Scaffold(
      appBar: BrandAppBar(
          leading: const BackButton(),
        title: Text(
          independent
              ? l10n.schoolAccountIndependentTitle
              : l10n.schoolAccountAffiliatedTitle,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _createdAccount != null
                  ? SchoolAccountReceipt(account: _createdAccount!)
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            independent
                                ? l10n.schoolAccountIndependentHint
                                : l10n.schoolAccountAffiliatedHint,
                          ),
                          const SizedBox(height: 20),
                          _field(
                            'name',
                            l10n.schoolAccountName,
                            _name,
                            maxLength: 150,
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? l10n.schoolAccountNameRequired
                                : null,
                          ),
                          _field(
                            'email',
                            l10n.schoolAccountEmail,
                            _email,
                            maxLength: 190,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch((v ?? '').trim()) &&
                                    !(v ?? '').trim().toLowerCase().endsWith('.edubridge')
                                ? null
                                : l10n.schoolAccountEmailInvalid,
                          ),
                          _field(
                            'password',
                            l10n.schoolAccountPassword,
                            _password,
                            maxLength: 128,
                            secret: true,
                            validator: (v) => (v ?? '').length >= 12 && (v ?? '').length <= 128
                                ? null
                                : l10n.schoolAccountPasswordInvalid,
                          ),
                          _field(
                            'password_confirmation',
                            Localizations.localeOf(context).languageCode == 'en'
                              ? 'Confirm password' : 'تأكيد كلمة المرور',
                            _passwordConfirmation,
                            maxLength: 128,
                            secret: true,
                            validator: (v) => v == _password.text
                                ? null
                                : l10n.schoolAccountPasswordMismatch,
                          ),
                          _field(
                            'phone',
                            l10n.schoolAccountPhone,
                            _phone,
                            maxLength: 30,
                            keyboard: TextInputType.phone,
                          ),
                          _field(
                            'address',
                            l10n.schoolAccountAddress,
                            _address,
                            maxLength: 255,
                          ),
                          if (_error != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                schoolAccountFailureMessage(
                                  l10n,
                                  _error!.failure,
                                ),
                                key: const ValueKey('school-account-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            key: const ValueKey('school-account-submit'),
                            onPressed: _submitting ? null : _submit,
                            child: Text(
                              _submitting
                                  ? l10n.schoolAccountSubmitting
                                  : l10n.schoolAccountSubmit,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ));
  }
}
