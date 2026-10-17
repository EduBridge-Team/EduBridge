// lib/screens/add_certificate_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';

class AddCertificateSheet extends StatefulWidget {
  final VoidCallback onSaved;
  /// Specialist-only Figma S18 centered modal. Other roles keep their sheet.
  final bool figmaS18;

  const AddCertificateSheet({
    super.key,
    required this.onSaved,
    this.figmaS18 = false,
  });

  @override
  State<AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<AddCertificateSheet> {
  final _titleCtrl = TextEditingController();
  File? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() {
        _file = File(path);
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الشهادة مطلوب');
      return;
    }
    if (_file == null) {
      setState(() => _error = 'ملف الشهادة مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.submitCertificate(
        title: _titleCtrl.text.trim(),
        file: _file!,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      widget.onSaved();
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الشهادة للمراجعة'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Widget _buildS18Dialog() {
    const blue = Color(0xFF196BC7);
    const ink = Color(0xFF102E4B);
    const light = Color(0xFFE6F1FC);
    const border = Color(0xFFD6E6F3);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  const Icon(Icons.workspace_premium_outlined,
                      color: blue, size: 24),
                  const SizedBox(width: 9),
                  const Flexible(
                    child: Text(
                      'إضافة شهادة (إثبات أهلية)',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 53,
                child: TextField(
                  key: const ValueKey('s18_certificate_title'),
                  controller: _titleCtrl,
                  enabled: !_saving,
                  maxLines: 1,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'عنوان الشهادة',
                    hintStyle: const TextStyle(
                      color: Color(0xFF708DA9),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_outlined, color: blue, size: 21),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: blue, width: 1.5)),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: border)),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              const Text(
                'ملف الشهادة (صورة أو PDF)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (_file == null)
                Semantics(
                  button: true,
                  label: 'اختيار صورة أو ملف PDF',
                  child: CustomPaint(
                    painter: const _S18DashedOutlinePainter(),
                    child: Material(
                      color: light,
                      borderRadius: BorderRadius.circular(17),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const ValueKey('s18_choose_certificate_file'),
                        onTap: _saving ? null : _pickFile,
                        child: const SizedBox(
                          height: 53,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                color: blue, size: 21),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'اختيار صورة أو ملف PDF',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                CustomPaint(
                  painter: const _S18DashedOutlinePainter(),
                  child: Container(
                    height: 53,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: light,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                          color: blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _file!.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: blue, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          tooltip: 'إزالة الملف المختار',
                          onPressed: _saving
                              ? null : () => setState(() => _file = null),
                          icon: const Icon(Icons.close_rounded,
                              color: blue, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 9),
                Text(
                  _error!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          backgroundColor: light,
                          side: const BorderSide(color: blue),
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('إلغاء',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton(
                        key: const ValueKey('s18_submit_certificate'),
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          shape: const StadiumBorder(),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 17, height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.outbox_outlined,
                                    color: Colors.white, size: 17),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'إرسال للمراجعة',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
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
    if (widget.figmaS18) return _buildS18Dialog();
    final c = JisrColors.of(context);
    final bottom = safeModalBottom(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.certificate,
                      color: AppColors.orange, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إضافة شهادة (إثبات أهلية)',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'أضف اسم الوثيقة وارفق صورة واضحة أو ملف PDF لإرسالها للمراجعة.',
                style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الشهادة',
                  hintText: 'مثال: بكالوريوس تربية خاصة',
                  prefixIcon: Icon(AppIcons.edit),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.attach,
                            size: 20, color: AppColors.greenDeep),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملف الشهادة (صورة أو PDF)',
                            softWrap: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: c.onTint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_file == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          icon: const Icon(AppIcons.upload),
                          label: const Text(
                            'اختيار صورة أو ملف PDF',
                            textAlign: TextAlign.center,
                          ),
                          onPressed: _pickFile,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(AppIcons.check, color: c.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _file!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: c.onTint,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(AppIcons.close, color: c.onTint),
                            onPressed: () => setState(() => _file = null),
                          ),
                        ],
                      ),
                  ],
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
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(AppIcons.save),
                      onPressed: _saving ? null : _save,
                      label: Text(_saving ? 'جارِ الحفظ...' : 'إرسال للمراجعة'),
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
}

/// Rounded dashed blue border used by the Figma S18 file chooser.
class _S18DashedOutlinePainter extends CustomPainter {
  const _S18DashedOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(17)));
    final paint = Paint()
      ..color = const Color(0xFF1971DA)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final metric in outline.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 9) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 5).clamp(0.0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _S18DashedOutlinePainter oldDelegate) => false;
}
