import 'package:flutter/material.dart';

enum SupportRecommendationTarget { specialist, parent }

class SupportTargetDialogS28 extends StatefulWidget {
  final String childName;
  const SupportTargetDialogS28({super.key, required this.childName});

  @override
  State<SupportTargetDialogS28> createState() => _SupportTargetDialogS28State();
}

class _SupportTargetDialogS28State extends State<SupportTargetDialogS28> {
  SupportRecommendationTarget? _target;
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF196BC7);
    const ink = Color(0xFF102F4C);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : ink;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: dark ? Theme.of(context).colorScheme.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * .85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.lightbulb_outline_rounded, color: blue, size: 23),
                const SizedBox(width: 8),
                Expanded(child: Text('اقتراح دعم تعليمي — ${widget.childName}',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 16),
              RadioGroup<SupportRecommendationTarget>(
                groupValue: _target,
                onChanged: (value) => setState(() {
                  _target = value;
                  _showError = false;
                }),
                child: Column(children: [
                  for (final target in SupportRecommendationTarget.values)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF20384C) : const Color(0xFFF0F6FB),
                        borderRadius: BorderRadius.circular(17)),
                      child: RadioListTile<SupportRecommendationTarget>(
                        key: ValueKey('s28-${target.name}'),
                        value: target,
                        activeColor: blue,
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        dense: true,
                        title: Text(target == SupportRecommendationTarget.specialist
                            ? 'مختص دعم تعليمي' : 'ولي الأمر',
                          style: TextStyle(color: textColor, fontSize: 16)),
                      ),
                    ),
                ]),
              ),
              if (_showError) ...[
                const Text('اختر جهة اقتراح الدعم', style: TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              Row(children: [
                Expanded(child: SizedBox(height: 36, child: OutlinedButton(
                  key: const ValueKey('s28-cancel'),
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blue, backgroundColor: dark ? null : const Color(0xFFE6F1FD),
                    side: const BorderSide(color: blue), shape: const StadiumBorder(),
                    padding: EdgeInsets.zero),
                  child: const Text('إلغاء'),
                ))),
                const SizedBox(width: 8),
                Expanded(child: SizedBox(height: 36, child: FilledButton(
                  key: const ValueKey('s28-next'),
                  onPressed: () {
                    if (_target == null) {
                      setState(() => _showError = true);
                    } else {
                      Navigator.pop(context, _target);
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: blue,
                    foregroundColor: Colors.white, shape: const StadiumBorder(), padding: EdgeInsets.zero),
                  child: const Text('التالي'),
                ))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
