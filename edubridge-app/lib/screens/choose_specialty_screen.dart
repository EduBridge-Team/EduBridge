// lib/screens/choose_specialty_screen.dart
// شاشة اختيار التخصص للمختص (عند عدم تحديده)
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
            content: Text('✅ تم حفظ تخصصك بنجاح'),
            backgroundColor: Colors.green,
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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: '🎯 تحديد التخصص'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── تنبيه ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.orangeDeep, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تخصصك غير محدد',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orangeDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'لتتمكن من متابعة الأطفال، يجب تحديد تخصصك. لا يمكن تغييره لاحقاً إلا عبر الدعم.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: c.onTint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'اختر تخصصك:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 16),

            // ─── مختص دعم تعليمي ───
            _SpecialtyCard(
              icon: Icons.psychology,
              title: 'مختص دعم تعليمي',
              description:
                  'متابعة الجانب الدعم تعليمي والعاطفي للأطفال، تشخيص الحالات، وتقديم الدعم التعليمي',
              color: AppColors.purple,
              selected: _selected == 'learning_support',
              onTap: () => setState(() => _selected = 'learning_support'),
            ),
            const SizedBox(height: 12),

            // ─── مختص تعليمي ───
            _SpecialtyCard(
              icon: Icons.school,
              title: 'مختص تعليمي',
              description:
                  'تقييم الجانب التعليمي، تصميم الخطط التعليمية، ومتابعة تقدّم الأطفال',
              color: AppColors.navy,
              selected: _selected == 'educational',
              onTap: () => setState(() => _selected = 'educational'),
            ),

            const Spacer(),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ─── زر الحفظ ───
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected == null
                      ? Colors.grey
                      : (_selected == 'learning_support'
                          ? AppColors.purple
                          : AppColors.navy),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _saving ? 'جارٍ الحفظ...' : 'تأكيد التخصص',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed:
                    _selected == null || _saving ? null : _save,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ بعد الحفظ، لا يمكن التغيير إلا بالتواصل مع الدعم الفني',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: c.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
