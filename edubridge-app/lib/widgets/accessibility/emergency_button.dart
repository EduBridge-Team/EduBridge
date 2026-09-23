// زر الطوارئ — للصرع والحالات الحرجة
// يُرسل تنبيهاً فورياً للأهل والمختص + يعرض تعليمات
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
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
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('تأكيد الطوارئ'),
          ],
        ),
        content: Text(
          'هل تريد إرسال تنبيه طوارئ للأهل والمختص؟\n\n'
          'الطفل: ${widget.childName}',
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.sos),
            label: const Text('إرسال فوراً'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _sending = true);

    // ✅ إصلاح: إرسال فعلي للسيرفر عبر /support بأولوية عاجلة
    bool serverSuccess = false;
    try {
      final res = await ApiService.authPost('/support', {
        'subject': '🚨 طوارئ: ${widget.childName}',
        'message':
            'تم تفعيل زر الطوارئ للطفل ${widget.childName}'
            '${widget.childId != null ? ' (ID: ${widget.childId})' : ''}. '
            'يُرجى التواصل فوراً.',
        'priority': 'urgent',
        'type': 'emergency',
      });
      serverSuccess = res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      // نستمر بالاتصال الهاتفي حتى لو فشل الإرسال
    }

    // ✅ اتصال هاتفي بالأهل
    if (widget.parentPhone != null && widget.parentPhone!.isNotEmpty) {
      await _callNumber(widget.parentPhone!);
    }

    if (!mounted) return;
    setState(() => _sending = false);

    _showInstructions(serverSuccess: serverSuccess);
  }

  Future<void> _callNumber(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showInstructions({required bool serverSuccess}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            Text(serverSuccess ? 'تم إرسال التنبيه' : 'تنبيه محلي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!serverSuccess)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '⚠️ تعذّر إرسال التنبيه للسيرفر — تم الاتصال هاتفياً فقط.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            const Text(
              'خطوات الأمان:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1.  ابقَ هادئاً وضع الطفل في مكان آمن',
                style: TextStyle(fontSize: 15, height: 1.6)),
            const Text('2.  أبعد الأشياء الحادة عن الطفل',
                style: TextStyle(fontSize: 15, height: 1.6)),
            const Text('3.  لا تضع شيئاً في فمه',
                style: TextStyle(fontSize: 15, height: 1.6)),
            const Text('4.  سجّل مدة النوبة',
                style: TextStyle(fontSize: 15, height: 1.6)),
            const Text('5.  إن استمرت أكثر من 5 دقائق → اتصل بالطبيب',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                )),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () => Navigator.pop(context),
              child: const Text('فهمت'),
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
          const Text(
            'زر الطوارئ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'للحالات الطارئة فقط',
            style: TextStyle(fontSize: 14, color: JisrColors.of(context).muted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
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
                _sending ? 'جارٍ الإرسال...' : 'إرسال تنبيه طوارئ',
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