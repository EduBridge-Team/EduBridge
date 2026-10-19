import '../l10n/l10n.dart';
// lib/screens/support_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const SupportSheet(),
  );

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  Object? _error;

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
        _error = SharedUiMessage.supportFieldsRequired;
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
          SnackBar(content: Text(context.l10n.supportMessageSent)),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? context.l10n.supportSendFailed;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = SharedUiMessage.connectionFailed;
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
                  Flexible(
                    child: Text(
                      context.l10n.contactSupport,
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
                  textDirection: Directionality.of(context),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  decoration: _s14FieldDecoration(
                    context.l10n.subject,
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
                  textDirection: Directionality.of(context),
                  textAlign: TextAlign.start,
                  textAlignVertical: TextAlignVertical.top,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: _s14FieldDecoration(context.l10n.message),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  context.sharedMessage(_error),
                  textAlign: TextAlign.start,
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
                        child: Text(context.l10n.cancel, style: TextStyle(
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(context.l10n.send, style: TextStyle(
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
  Widget build(BuildContext context) => Directionality(
    textDirection: Directionality.of(context),
    child: _buildS14Dialog(context),
  );
}
