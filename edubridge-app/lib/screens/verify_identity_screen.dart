import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/home_router.dart'; // لاستدعاء homeScreenForRole بعد الموافقة

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> with WidgetsBindingObserver {
  final _nationalIdCtrl = TextEditingController();
  File? _idImage;
  bool _loading = false;
  String? _error;
  String? _verificationStatus; // none, pending, approved, rejected
  Timer? _timer;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // مراقبة حالة التطبيق
    _loadStatus();
    // فحص الحالة تلقائياً كل 5 ثوانٍ أثناء عرض "قيد المراجعة"
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_verificationStatus == 'pending') {
        _loadStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _nationalIdCtrl.dispose();
    super.dispose();
  }

  // عندما يعود المستخدم للتطبيق من الخلفية
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _verificationStatus == 'pending') {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final status = await ApiService.getVerificationStatus();
    if (mounted) {
      setState(() {
        _verificationStatus = status;
      });

      // إذا أصبحت الحالة "approved"، نوجهه فوراً للصلاحيات
      if (status == 'approved') {
        _timer?.cancel();
        final home = await homeScreenForRole();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => home),
            (route) => false,
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _idImage = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (_nationalIdCtrl.text.trim().isEmpty) {
      setState(() => _error = 'رقم الهوية مطلوب');
      return;
    }
    if (_idImage == null) {
      setState(() => _error = 'صورة الهوية مطلوبة');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.submitIdentityVerification(
        nationalId: _nationalIdCtrl.text.trim(),
        idImage: _idImage!,
      );

      if (!mounted) return;
      setState(() {
        _verificationStatus = 'pending';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    // 1. إذا كانت الحالة "قيد المراجعة"
    if (_verificationStatus == 'pending') {
      return Scaffold(
        appBar: JisrAppBar(title: 'توثيق الهوية'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top, size: 72, color: AppColors.orange),
                const SizedBox(height: 16),
                Text(
                  'طلبك قيد المراجعة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.heading),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم تفعيل حسابك فور موافقة الإدارة. شكراً لصبرك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                // زر تحديث الحالة يدوياً
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الحالة'),
                    onPressed: _loading ? null : _loadStatus,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('خروج'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. إذا كانت الحالة "مرفوضة"
    if (_verificationStatus == 'rejected') {
      return Scaffold(
        appBar: JisrAppBar(title: 'توثيق الهوية'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'تم رفض طلب التوثيق',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.heading),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى مراجعة البيانات وإعادة المحاولة، أو التواصل مع الدعم الفني.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _verificationStatus = 'none';
                        _error = null;
                      });
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. إذا لم يرسل الطلب بعد (none أو أي حالة أخرى)
    return Scaffold(
      appBar: JisrAppBar(title: 'توثيق الهوية'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: c.onTint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لا يمكنك استخدام الصلاحيات الكاملة قبل توثيق هويتك',
                      style: TextStyle(color: c.onTint, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nationalIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الهوية',
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'مثال: 1234567890',
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'صورة الهوية (jpg, png, webp, pdf) – حد 5 ميجابايت',
                    style: TextStyle(fontWeight: FontWeight.bold, color: c.onTint),
                  ),
                  const SizedBox(height: 8),
                  if (_idImage == null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('اختر ملف الهوية'),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: c.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _idImage!.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.onTint, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: c.onTint),
                          onPressed: () => setState(() => _idImage = null),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ وإرسال للتوثيق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}