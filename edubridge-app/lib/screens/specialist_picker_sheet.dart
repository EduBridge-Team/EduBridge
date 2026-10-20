import '../utils/presentation_text.dart';
// lib/screens/specialist_picker_sheet.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../app_icons.dart';
import '../theme.dart';

class SpecialistPickerSheet extends StatelessWidget {
  final List specialists;
  final String childName;
  final void Function(Map) onSelect;

  const SpecialistPickerSheet({
    super.key,
    required this.specialists,
    required this.childName,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.chat, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Expanded(child: Text(
                context.l10n.specialistPickerTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              )),
              IconButton(
                tooltip: context.l10n.close,
                icon: const Icon(AppIcons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.specialistPickerIntro(childName),
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 16),
          ...specialists.map((specialist) {
            final name = (specialist['name'] ?? '').toString();
            final email = (specialist['email'] ?? '').toString();
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.orange,
                child: Text(
                  PresentationText.initial(name, trim: true, fallback: context.l10n.specialistRole.characters.first),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(name.isEmpty ? context.l10n.specialistRole : name),
              subtitle: Text(email),
              trailing: const Icon(AppIcons.chat),
              onTap: () => onSelect(specialist),
            );
          }),
          if (specialists.isEmpty)
            Center(
              child: Text(
                context.l10n.specialistPickerEmpty,
                style: TextStyle(color: c.muted),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}
