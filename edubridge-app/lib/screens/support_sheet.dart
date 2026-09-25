// lib/screens/support_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTicket() async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _sending = true;
      _error = null;
    });

    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      setState(() {
        _error = 'الرجاء تعبئة الموضوع والرسالة';
        _sending = false;
      });
      return;
    }

    try {
      final res = await ApiService.authPost('/support', {
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
      });
      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح')),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر إرسال الرسالة';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر الاتصال بالسيرفر';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: safeModalBottom(context)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.support,
                    color: AppColors.brandBlue, size: 26),
                const SizedBox(width: 8),
                Text(
                  'تواصل مع الدعم الفني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'الموضوع',
                hintText: 'مثال: مشكلة في تسجيل الدخول',
                prefixIcon: Icon(AppIcons.edit),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الرسالة',
                hintText: 'اكتب تفاصيل المشكلة هنا...',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sending ? null : _sendTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                minimumSize: const Size(0, 52),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(AppIcons.send),
              label: Text(_sending ? 'جارٍ الإرسال...' : 'إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}