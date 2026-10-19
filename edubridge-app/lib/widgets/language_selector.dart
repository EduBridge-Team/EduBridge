import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/app_locale_controller.dart';

Future<void> showLanguageSelector(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _LanguageSelector(),
);

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector();
  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _choose(String language) async {
    setState(() { _saving = true; _failed = false; });
    try {
      await AppLocaleController.instance.setLocale(Locale(language));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _saving = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return AlertDialog(
      title: Text(strings.chooseLanguage),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final language in ['ar', 'en'])
          ListTile(
            key: ValueKey('language_$language'),
            title: Text(language == 'ar' ? strings.arabicLanguage : strings.englishLanguage),
            selected: AppLocaleController.instance.value.languageCode == language,
            trailing: AppLocaleController.instance.value.languageCode == language
                ? const Icon(Icons.check) : null,
            enabled: !_saving,
            onTap: () => _choose(language),
          ),
        if (_saving) const Padding(padding: EdgeInsets.all(12),
          child: CircularProgressIndicator()),
        if (_failed) Text(strings.genericError, semanticsLabel: strings.genericError),
      ]),
      actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: Text(strings.cancel))],
    );
  }
}

/// Language remains reachable before sign-in, through the same menu convention.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: context.l10n.moreOptions,
    icon: Icon(Icons.menu_rounded, color: color),
    onSelected: (_) => showLanguageSelector(context),
    itemBuilder: (context) => [PopupMenuItem<String>(
      value: 'language', child: Text(context.l10n.language),
    )],
  );
}
