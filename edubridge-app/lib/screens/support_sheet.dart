// lib/screens/support_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key, this.figmaS14 = false});

  /// Figma S14 modal treatment used by the specialist dashboard only.
  final bool figmaS14;

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

  InputDecoration _s14FieldDecoration(String label, {Widget? icon}) {
    const lineColor = Color(0xFFD8E7F2);
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        color: Color(0xFF738FA8),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: icon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: lineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Color(0xFF1C69C5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: AppColors.red),
      ),
    );
  }

  Widget _buildS14Dialog(BuildContext context) {
    const blue = Color(0xFF196AC5);
    const heading = Color(0xFF13314D);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.headset_mic_outlined,
                    size: 23, color: blue),
                  const SizedBox(width: 9),
                  const Flexible(
                    child: Text(
                      'تواصل مع الدعم الفني',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: heading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: TextField(
                  controller: _subjectController,
                  enabled: !_sending,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  decoration: _s14FieldDecoration(
                    'الموضوع',
                    icon: const Icon(Icons.edit_outlined, size: 20,
                      color: blue),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: TextField(
                  controller: _messageController,
                  enabled: !_sending,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  textAlignVertical: TextAlignVertical.top,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: _s14FieldDecoration('الرسالة'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: OutlinedButton(
                        onPressed: _sending
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          backgroundColor: const Color(0xFFE5F1FD),
                          side: const BorderSide(color: blue),
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('إلغاء', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendTicket,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('إرسال', style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 6),
                                  Icon(Icons.mail_outline_rounded, size: 19),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.figmaS14) return _buildS14Dialog(context);
    final c = JisrColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: safeModalBottom(context)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 60, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
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
                Icon(AppIcons.support, color: c.infoText, size: 26),
                const SizedBox(width: 8),
                Text(
                  'تواصل مع الدعم الفني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
                    Icon(AppIcons.error, color: c.dangerText, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: c.dangerText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _sending ? null : _sendTicket,
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
