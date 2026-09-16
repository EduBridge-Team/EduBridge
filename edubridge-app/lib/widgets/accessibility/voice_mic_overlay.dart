// زر مايك عائم — للأوامر الصوتية
// - نقرة واحدة: ابدأ/أوقف الاستماع
// - ضغطة طويلة: اسحب لتغيير الموضع
// - يظهر فقط لولي الأمر (parent)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/overlay_visibility_service.dart';
import '../../services/voice_command_service.dart';
import '../../theme.dart';
import '../../utils/navigation.dart';
import 'read_mode_badge.dart';

class VoiceMicOverlay extends StatefulWidget {
  final Widget child;
  const VoiceMicOverlay({super.key, required this.child});

  @override
  State<VoiceMicOverlay> createState() => _VoiceMicOverlayState();
}

class _VoiceMicOverlayState extends State<VoiceMicOverlay> {
  static const double _size = 68;
  static const double _margin = 14;
  static const String _xKey = 'voice_mic_x_fraction';
  static const String _yKey = 'voice_mic_y_fraction';

  final _service = VoiceCommandService.instance;
  final _overlayKey = GlobalKey();

  double _xFraction = 0.05;
  double _yFraction = 0.85;
  bool _dragging = false;
  bool _positionReady = false;

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = (prefs.getDouble(_xKey) ?? 0.05).clamp(0.0, 1.0);
    final y = (prefs.getDouble(_yKey) ?? 0.85).clamp(0.0, 1.0);
    if (!mounted) return;
    setState(() {
      _xFraction = x;
      _yFraction = y;
      _positionReady = true;
    });
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_xKey, _xFraction),
      prefs.setDouble(_yKey, _yFraction),
    ]);
  }

  ({double minX, double maxX, double minY, double maxY}) _bounds(
    BoxConstraints constraints,
    MediaQueryData mq,
  ) {
    final minX = _margin;
    final minY = mq.padding.top + _margin;
    final maxX = (constraints.maxWidth - _size - _margin).clamp(minX, 9999.0);
    final maxY =
        (constraints.maxHeight - _size - mq.padding.bottom - _margin)
            .clamp(minY, 9999.0);
    return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  void _onPanUpdate(
    LongPressMoveUpdateDetails d,
    BoxConstraints constraints,
    MediaQueryData mq,
  ) {
    final box = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.globalToLocal(d.globalPosition);
    final b = _bounds(constraints, mq);
    final x = (pos.dx - _size / 2).clamp(b.minX, b.maxX).toDouble();
    final y = (pos.dy - _size / 2).clamp(b.minY, b.maxY).toDouble();
    final hRange = b.maxX - b.minX;
    final vRange = b.maxY - b.minY;
    setState(() {
      _xFraction = hRange == 0 ? 0 : ((x - b.minX) / hRange).clamp(0.0, 1.0);
      _yFraction = vRange == 0 ? 0 : ((y - b.minY) / vRange).clamp(0.0, 1.0);
    });
  }

  void _onTap() {
    if (_dragging) return;
    if (_service.isListening.value) {
      _service.stopListening();
    } else {
      _service.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OverlayVisibilityService.microphoneVisible,
      builder: (context, microphoneEnabled, _) => LayoutBuilder(
        builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final b = _bounds(constraints, mq);
        final x = b.minX + (b.maxX - b.minX) * _xFraction;
        final y = b.minY + (b.maxY - b.minY) * _yFraction;

        return Stack(
          key: _overlayKey,
          children: [
            widget.child,
            // ✅ التحقق من الدور: يظهر فقط لولي الأمر
            ValueListenableBuilder<String?>(
              valueListenable: ApiService.userRole,
              builder: (context, role, _) {
                // ❌ ليس ولي أمر → لا تعرض شيئاً
                if (role != 'parent') return const SizedBox.shrink();

                return ValueListenableBuilder<bool>(
                  valueListenable: ApiService.isAuthenticated,
                  builder: (context, signedIn, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: assistantScreenVisible,
                      builder: (context, assistantVisible, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: modalSheetOpen,
                          builder: (context, modalOpen, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: inlineModalOpen,
                              builder: (context, inlineOpen, _) {
                                final keyboardOpen =
                                    mq.viewInsets.bottom > 0;
                                if (!microphoneEnabled ||
                                    !signedIn ||
                                    assistantVisible ||
                                    modalOpen ||
                                    inlineOpen ||
                                    keyboardOpen ||
                                    !_positionReady) {
                                  return const SizedBox.shrink();
                                }

                                return Positioned(
                                  left: x,
                                  top: y,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // شارة وضع القراءة
                                      const ReadModeBadge(),
                                      // فقاعة "ما سمعته"
                                      _ListeningBubble(service: _service),
                                      // الزر
                                      GestureDetector(
                                        onTap: _onTap,
                                        onLongPressStart: (_) {
                                          HapticFeedback
                                              .selectionClick();
                                          setState(
                                              () => _dragging = true);
                                        },
                                        onLongPressMoveUpdate: (d) =>
                                            _onPanUpdate(
                                                d, constraints, mq),
                                        onLongPressEnd: (_) {
                                          setState(
                                              () => _dragging = false);
                                          _savePosition();
                                          HapticFeedback
                                              .lightImpact();
                                        },
                                        child: _MicButton(
                                            service: _service),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
        },
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoiceCommandService service;
  const _MicButton({required this.service});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.isListening,
      builder: (context, listening, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: listening ? Colors.red : AppColors.tealDeep,
            border: Border.all(
              color: listening ? Colors.red.shade200 : AppColors.yellow,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (listening ? Colors.red : AppColors.navy)
                    .withValues(alpha: 0.4),
                blurRadius: listening ? 22 : 14,
                spreadRadius: listening ? 4 : 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            listening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 36,
          ),
        );
      },
    );
  }
}

class _ListeningBubble extends StatelessWidget {
  final VoiceCommandService service;
  const _ListeningBubble({required this.service});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.isListening,
      builder: (context, listening, _) {
        return ValueListenableBuilder<String>(
          valueListenable: service.lastHeard,
          builder: (context, heard, _) {
            if (!listening && heard.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    heard.isEmpty ? '🎤 أتكلّم...' : '« $heard »',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (heard.isNotEmpty && !listening) ...[
                    const SizedBox(height: 4),
                    ValueListenableBuilder<String>(
                      valueListenable: service.lastReply,
                      builder: (context, reply, _) {
                        if (reply.isEmpty) return const SizedBox.shrink();
                        return Text(
                          reply,
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
