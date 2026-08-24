import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
    setState(() {
      _sending = true;
      _error = null;
    });

    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
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

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح')),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر إرسال الرسالة';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text(
              'تواصل مع الدعم الفني',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.heading),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'الموضوع',
                hintText: 'مثال: مشكلة في تسجيل الدخول',
                prefixIcon: Icon(Icons.subject),
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
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sending ? null : _sendTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealDeep,
              ),
              child: _sending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}