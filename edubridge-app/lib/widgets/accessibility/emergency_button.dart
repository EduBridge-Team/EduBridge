import '../../l10n/l10n.dart';
// زر الطوارئ — للصرع والحالات الحرجة
// يُرسل تنبيهاً فورياً للأهل والمختص + يعرض تعليمات
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/adaptive_helper.dart';
import '../../theme.dart';

class EmergencyButton extends StatefulWidget {
  final String childName;
  final String? parentPhone;
  final String? specialistPhone;
  final int? childId;

  const EmergencyButton({
    super.key,
    required this.childName,
    this.parentPhone,
    this.specialistPhone,
    this.childId,
  });

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> {
  bool _sending = false;

  Future<void> _triggerEmergency() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Expanded(child: Text(dialogContext.l10n.emergencyConfirmTitle)),
          ],
        ),
        content: Text(
          dialogContext.l10n.emergencyConfirmBody(widget.childName),
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.sos),
            label: Text(dialogContext.l10n.emergencySendNow),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    AdaptiveHelper.hapticFeedback();

    setState(() => _sending = true);

    bool serverSuccess = false;
    int notifiedRecipients = 0;
    if (widget.childId != null) {
      try {
        final res = await ApiService.authPost(
          '/children/${widget.childId}/emergency-alerts',
          {
            'source': 'app',
            'message':
                'تم تفعيل زر الطوارئ للطفل ${widget.childName}. '
                'يُرجى التواصل فوراً.',
          },
        );
        serverSuccess = res.statusCode == 201;
        if (serverSuccess && res.body.isNotEmpty) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          notifiedRecipients =
              (body['notified_recipients'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {
        // نستمر بخيارات الاتصال المحلي حتى لو فشل إرسال التنبيه.
      }
    }

    if (widget.parentPhone != null && widget.parentPhone!.isNotEmpty) {
      await _callNumber(widget.parentPhone!);
    } else if (widget.specialistPhone != null &&
        widget.specialistPhone!.isNotEmpty) {
      await _callNumber(widget.specialistPhone!);
    }

    if (!mounted) return;
    setState(() => _sending = false);

    _showInstructions(
      serverSuccess: serverSuccess,
      notifiedRecipients: notifiedRecipients,
    );
  }

  Future<void> _callNumber(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showInstructions({
    required bool serverSuccess,
    int notifiedRecipients = 0,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              serverSuccess ? Icons.check_circle : Icons.warning_amber,
              color: serverSuccess ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(serverSuccess ? dialogContext.l10n.emergencySent : dialogContext.l10n.emergencyLocal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (serverSuccess && notifiedRecipients > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  dialogContext.l10n.emergencyNotified(notifiedRecipients),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!serverSuccess)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dialogContext.l10n.emergencyServerFailed,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            Text(
              dialogContext.l10n.emergencySafety,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(dialogContext.l10n.emergencySafePlace,
                style: TextStyle(fontSize: 15, height: 1.6)),
            Text(dialogContext.l10n.emergencySharpObjects,
                style: TextStyle(fontSize: 15, height: 1.6)),
            Text(dialogContext.l10n.emergencyMouth,
                style: TextStyle(fontSize: 15, height: 1.6)),
            Text(dialogContext.l10n.emergencyDuration,
                style: TextStyle(fontSize: 15, height: 1.6)),
            Text(dialogContext.l10n.emergencyDoctor,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                )),
          ],
        ),
        actions: [
          if (widget.parentPhone != null && widget.parentPhone!.isNotEmpty)
            TextButton.icon(
              onPressed: () => _callNumber(widget.parentPhone!),
              icon: const Icon(Icons.call),
              label: Text(dialogContext.l10n.emergencyCallParent),
            ),
          if (widget.specialistPhone != null &&
              widget.specialistPhone!.isNotEmpty)
            TextButton.icon(
              onPressed: () => _callNumber(widget.specialistPhone!),
              icon: const Icon(Icons.medical_services_outlined),
              label: Text(dialogContext.l10n.emergencyCallSpecialist),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () => Navigator.pop(context),
              child: Text(dialogContext.l10n.emergencyUnderstood),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.emergency, color: Colors.red, size: 44),
          const SizedBox(height: 10),
          Text(
            context.l10n.emergencyTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.emergencyOnly,
            style: TextStyle(fontSize: 14, color: JisrColors.of(context).muted),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sos, size: 32),
              label: Text(
                _sending ? context.l10n.emergencySending : context.l10n.emergencySend,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _sending ? null : _triggerEmergency,
            ),
          ),
        ],
      ),
    );
  }
}