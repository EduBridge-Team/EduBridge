// شاشة اختيار المختص للتواصل
import 'package:flutter/material.dart';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'تواصل مع مختص',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اختر المختص للتواصل بشأن $childName',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 16),
          ...specialists.map((specialist) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.orange,
                  child: Text(
                    (specialist['name'] ?? 'م').characters.first,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(specialist['name'] ?? 'مختص'),
                subtitle: Text(specialist['email'] ?? ''),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () => onSelect(specialist),
              )),
          if (specialists.isEmpty)
            Center(
              child: Text(
                'لا يوجد مختصون متاحون حالياً',
                style: TextStyle(color: c.muted),
              ),
            ),
        ],
      ),
    );
  }
}