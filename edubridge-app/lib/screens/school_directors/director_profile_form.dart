import 'package:flutter/material.dart';

import '../../theme.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_director.dart';
import 'director_failure_message.dart';
import 'school_directors_controller.dart';

class DirectorProfileForm extends StatefulWidget {
  const DirectorProfileForm({
    super.key,
    required this.controller,
    this.director,
  });
  final SchoolDirectorsController controller;
  final SchoolDirector? director;

  @override
  State<DirectorProfileForm> createState() => _DirectorProfileFormState();
}

class _DirectorProfileFormState extends State<DirectorProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _qualification;
  late final TextEditingController _experience;
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    final details = widget.director?.details;
    _name = TextEditingController(text: details?.name);
    _email = TextEditingController(text: details?.email);
    _phone = TextEditingController(text: details?.phone);
    _qualification = TextEditingController(text: details?.qualification);
    _experience = TextEditingController(
      text: '${details?.experienceYears ?? 0}',
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _qualification,
      _experience,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.controller.canMutate || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _attempted = true);
    final draft = DirectorDraft(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      qualification: _qualification.text,
      experienceYears: int.parse(_experience.text.trim()),
    );
    final saved = await widget.controller.saveProfile(
      draft,
      directorId: widget.director?.id,
    );
    if (mounted && saved) Navigator.of(context).pop();
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    required int maxLength,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('director-$key'),
      controller: controller,
      enabled: !widget.controller.saving,
      maxLength: maxLength,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) => PopScope(
        canPop: !widget.controller.saving,
        child: Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(
            widget.director == null ? l10n.directorAdd : l10n.directorEdit,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        'name',
                        l10n.directorName,
                        _name,
                        maxLength: 150,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l10n.directorRequired
                            : null,
                      ),
                      _field(
                        'email',
                        l10n.directorEmail,
                        _email,
                        maxLength: 190,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch((v ?? '').trim())
                            ? null
                            : l10n.schoolAccountEmailInvalid,
                      ),
                      _field(
                        'phone',
                        l10n.directorPhone,
                        _phone,
                        maxLength: 30,
                        keyboard: TextInputType.phone,
                      ),
                      _field(
                        'qualification',
                        l10n.directorQualification,
                        _qualification,
                        maxLength: 255,
                      ),
                      _field(
                        'experience',
                        l10n.directorExperience,
                        _experience,
                        maxLength: 2,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          final years = int.tryParse((v ?? '').trim());
                          return years == null || years < 0 || years > 80
                              ? l10n.directorExperienceInvalid
                              : null;
                        },
                      ),
                      if (_attempted && widget.controller.error != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            directorFailureMessage(
                              l10n,
                              widget.controller.error!,
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_attempted &&
                          !widget.controller.canMutate &&
                          !widget.controller.saving)
                        TextButton(
                          onPressed: widget.controller.reload,
                          child: Text(l10n.directorReload),
                        ),
                      FilledButton(
                        key: const ValueKey('director-save'),
                        onPressed: widget.controller.canMutate ? _submit : null,
                        child: Text(
                          widget.controller.saving
                              ? l10n.directorSaving
                              : l10n.directorSave,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
