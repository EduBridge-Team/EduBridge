// lib/screens/verify_identity/verify_identity_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

part 'verify_identity_states.dart';

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

  Future<void> _loadRole() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacherOrSpecialist = role == 'teacher' || role == 'specialist';
    });
  }

  Future<void> _loadStatus() async {
    final status = await ApiService.getVerificationStatus();
    if (!mounted) return;

    setState(() => _verificationStatus = status);

    if (status == 'verified') {
      _timer?.cancel();
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

    // 1) موثّق — ابقَ في الشاشة واعرض الحالة بدلاً من إعادة التوجيه تلقائياً.
    if (_verificationStatus == 'verified') {
      return buildVerifiedState(
        context: context,
        c: c,
        isTeacherOrSpecialist: _isTeacherOrSpecialist,
      );
    }

    // 2) قيد المراجعة
    if (_verificationStatus == 'pending') {
      return buildPendingState(
        context: context,
        c: c,
        isTeacherOrSpecialist: _isTeacherOrSpecialist,
        loading: _loading,
        onRefresh: _loadStatus,
      );
    }

    // 3) مرفوض
    if (_verificationStatus == 'rejected') {
      return buildRejectedState(
        context: context,
        c: c,
        onRetry: () {
          setState(() {
            _verificationStatus = 'none';
            _error = null;
          });
        },
      );
    }

    // 4) نموذج جديد
    return buildFormState(
      context: context,
      c: c,
      isTeacherOrSpecialist: _isTeacherOrSpecialist,
      nationalIdCtrl: _nationalIdCtrl,
      certificateTitleCtrl: _certificateTitleCtrl,
      idImage: _idImage,
      certificateFile: _certificateFile,
      loading: _loading,
      error: _error,
      onPickId: _pickIdImage,
      onCaptureId: _captureIdImage,
      onRemoveId: () => setState(() => _idImage = null),
      onPickCertificate: _pickCertificate,
      onCaptureCertificate: _captureCertificate,
      onRemoveCertificate: () => setState(() => _certificateFile = null),
      onSubmit: _submit,
    );
  }
}