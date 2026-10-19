import 'package:flutter/material.dart';

/// Revalidate previously submitted forms after a locale change, preserving drafts.
mixin LocaleFormValidation<T extends StatefulWidget> on State<T> {
  GlobalKey<FormState> get validationFormKey;
  bool _validationStarted = false;
  Locale? _validationLocale;

  bool validateLocalizedForm() {
    _validationStarted = true;
    return validationFormKey.currentState?.validate() ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_validationStarted && _validationLocale != locale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) validationFormKey.currentState?.validate();
      });
    }
    _validationLocale = locale;
  }
}
