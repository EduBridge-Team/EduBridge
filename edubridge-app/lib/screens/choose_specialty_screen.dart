// lib/screens/choose_specialty_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
part 'choose_specialty_view.dart';

class ChooseSpecialtyScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const ChooseSpecialtyScreen({super.key, this.onDone});

  @override
  State<ChooseSpecialtyScreen> createState() => _ChooseSpecialtyScreenState();
}

class _ChooseSpecialtyScreenState extends State<ChooseSpecialtyScreen> {
  String? _selected;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_selected == null) {
      setState(() => _error = 'اختر تخصصك');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final res = await ApiService.authPut('/me/specialty', {
        'specialty': _selected,
      });

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ تخصصك بنجاح'),
            backgroundColor: AppColors.green,
          ),
        );
        widget.onDone?.call();
        Navigator.pop(context, _selected);
      } else {
        final data = res.body.isNotEmpty
            ? jsonDecode(res.body) as Map<String, dynamic>
            : <String, dynamic>{};
        setState(() {
          _error = data['error']?.toString() ?? 'فشل الحفظ';
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}

class _SpecialtyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SpecialtyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : c.line,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 28,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: selected ? color : c.heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(AppIcons.check, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}