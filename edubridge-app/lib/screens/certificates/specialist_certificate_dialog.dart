import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';

class SpecialistCertificateDialog extends StatelessWidget {
  const SpecialistCertificateDialog({
    super.key,
    required this.titleController,
    required this.fileName,
    required this.saving,
    required this.error,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onSave,
  });

  final TextEditingController titleController;
  final String? fileName;
  final bool saving;
  final Object? error;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: blue,
                    size: 24,
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      context.l10n.addQualificationCertificate,
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
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 53),
                child: TextField(
                  key: const ValueKey('s18_certificate_title'),
                  controller: titleController,
                  enabled: !saving,
                  maxLines: 1,
                  textDirection: Directionality.of(context),
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: context.l10n.certificateTitle,
                    hintStyle: const TextStyle(
                      color: Color(0xFF708DA9),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      color: blue,
                      size: 21,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: blue, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Text(
                context.l10n.certificateFileLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (fileName == null)
                Semantics(
                  button: true,
                  label: context.l10n.chooseImageOrPdf,
                  child: CustomPaint(
                    foregroundPainter: const _S18DashedOutlinePainter(),
                    child: Material(
                      color: light,
                      borderRadius: BorderRadius.circular(17),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const ValueKey('s18_choose_certificate_file'),
                        onTap: saving ? null : onPickFile,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 53),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                color: blue,
                                size: 21,
                              ),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  context.l10n.chooseImageOrPdf,
                                  style: TextStyle(color: blue, fontSize: 14),
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
                  foregroundPainter: const _S18DashedOutlinePainter(),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 53),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: light,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: blue, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.removeSelectedFile,
                          onPressed: saving ? null : onRemoveFile,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: blue,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: 9),
                Text(
                  context.sharedMessage(error),
                  textAlign: TextAlign.start,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blue,
                          backgroundColor: light,
                          side: const BorderSide(color: blue),
                          padding: EdgeInsets.zero,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          context.l10n.cancel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
                      child: FilledButton(
                        key: const ValueKey('s18_submit_certificate'),
                        onPressed: saving ? null : onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          shape: const StadiumBorder(),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.outbox_outlined,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      context.l10n.submitForReview,
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
}

/// Rounded dashed blue border used by the Figma S18 file chooser.
class _S18DashedOutlinePainter extends CustomPainter {
  const _S18DashedOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(17)),
      );
    final paint = Paint()
      ..color = const Color(0xFF1971DA)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final metric in outline.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 9) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + 5).clamp(0.0, metric.length).toDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _S18DashedOutlinePainter oldDelegate) => false;
}
