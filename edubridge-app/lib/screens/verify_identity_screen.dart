import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/home_router.dart';

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen>
    with WidgetsBindingObserver {
  final _nationalIdCtrl = TextEditingController();
  final _certificateTitleCtrl = TextEditingController();
  File? _idImage;
  File? _certificateFile;
  bool _loading = false;
  String? _error;
  String? _verificationStatus;
  Timer? _timer;
  bool _isTeacherOrSpecialist = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRole();
    _loadStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_verificationStatus == 'pending') _loadStatus();
    });
  }

  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacherOrSpecialist = role == 'teacher' || role == 'specialist';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _nationalIdCtrl.dispose();
    _certificateTitleCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _verificationStatus == 'pending') {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final status = await ApiService.getVerificationStatus();
    if (!mounted) return;

    setState(() => _verificationStatus = status);

    if (status == 'verified') {
      _timer?.cancel();
      final home = await homeScreenForRole();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    }
  }

  Future<void> _pickIdImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _idImage = File(image.path));
  }

  Future<void> _captureIdImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) setState(() => _idImage = File(image.path));
  }

  Future<void> _pickCertificate() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _certificateFile = File(image.path));
  }

  Future<void> _captureCertificate() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) setState(() => _certificateFile = File(image.path));
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
    if (_isTeacherOrSpecialist) {
      if (_certificateTitleCtrl.text.trim().isEmpty) {
        setState(() => _error = 'عنوان الشهادة مطلوب');
        return;
      }
      if (_certificateFile == null) {
        setState(() => _error = 'صورة الشهادة مطلوبة');
        return;
      }
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

      if (_isTeacherOrSpecialist && _certificateFile != null) {
        await ApiService.submitCertificate(
          title: _certificateTitleCtrl.text.trim(),
          file: _certificateFile!,
        );
      }

      if (!mounted) return;
      setState(() {
        _verificationStatus = 'pending';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    // 1) قيد المراجعة
    if (_verificationStatus == 'pending') {
      return Scaffold(
        appBar: JisrAppBar(title: 'توثيق الهوية'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top,
                    size: 72, color: AppColors.tealDeep),
                const SizedBox(height: 16),
                Text(
                  'طلبك قيد المراجعة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isTeacherOrSpecialist
                      ? 'سيتم التحقق من هويتك وشهادتك خلال 24 ساعة. شكراً لصبرك.'
                      : 'سيتم تفعيل حسابك فور موافقة الإدارة. شكراً لصبرك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
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

    // 2) مرفوض
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى مراجعة البيانات والصور وإعادة المحاولة، أو التواصل مع الدعم الفني.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
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

    // 3) نموذج جديد
    return Scaffold(
      appBar: JisrAppBar(title: 'توثيق الهوية'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // تنبيه
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
                      _isTeacherOrSpecialist
                          ? 'مطلوب توثيق الهوية + رفع الشهادة العلمية لتفعيل صلاحياتك الكاملة.'
                          : 'لا يمكنك استخدام الصلاحيات الكاملة قبل توثيق هويتك.',
                      style: TextStyle(
                        color: c.onTint,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // رقم الهوية
            TextField(
              controller: _nationalIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الهوية *',
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'مثال: 1234567890',
              ),
            ),
            const SizedBox(height: 16),

            // صورة الهوية
            _fileCard(
              c: c,
              title: 'صورة الهوية *',
              subtitle: 'jpg, png, webp — صورة واضحة للوجه الأمامي',
              icon: Icons.badge_outlined,
              color: AppColors.teal,
              file: _idImage,
              onPick: _pickIdImage,
              onCapture: _captureIdImage,
              onClear: () => setState(() => _idImage = null),
            ),

            // قسم الشهادة (للمعلم/المختص)
            if (_isTeacherOrSpecialist) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.tintYellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: AppColors.orangeDeep, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الشهادة العلمية *',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: c.heading,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'إلزامي',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _certificateTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الشهادة *',
                        hintText: 'مثال: بكالوريوس تربية خاصة',
                        prefixIcon: Icon(Icons.school),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_certificateFile == null)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('من المعرض'),
                                onPressed: _pickCertificate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.orange,
                                  side: const BorderSide(
                                      color: AppColors.orange, width: 1.5),
                                ),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('الكاميرا'),
                                onPressed: _captureCertificate,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _certificateFile!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _certificateFile!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.onTint,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 20),
                            onPressed: () =>
                                setState(() => _certificateFile = null),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealDeep,
                ),
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading ? 'جارٍ الإرسال...' : 'حفظ وإرسال للتوثيق',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileCard({
    required JisrColors c,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required File? file,
    required VoidCallback onPick,
    VoidCallback? onCapture,
    required VoidCallback onClear,
  }) {
    final hasFile = file != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasFile ? color.withValues(alpha: 0.08) : c.tintTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFile ? color : c.line,
          width: hasFile ? 2 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
              if (hasFile)
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 10),
          if (!hasFile)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('من المعرض'),
                      onPressed: onPick,
                    ),
                  ),
                ),
                if (onCapture != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color, width: 1.5),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('الكاميرا'),
                        onPressed: onCapture,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: c.line,
                      child: Icon(Icons.image, color: c.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.onTint,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: color, size: 20),
                  onPressed: onPick,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onClear,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}