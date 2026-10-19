part of 'legal_links_button.dart';

extension _LegalLinksButtonView on LegalLinksButton {
  Widget buildView(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
      tooltip: context.l10n.privacyAndDeletion,
      onPressed: () => show(context),
    );
  
  }
}
