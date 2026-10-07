// احتفال بصري — يتكيّف تلقائياً مع كل إعاقة
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import '../../services/encouragement_service.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

class VisualCelebration extends StatefulWidget {
  final String message;
  final String? emoji;
  final Duration duration;
  final bool calmMode;
  final bool blindMode;
  final bool deafMode;
  final bool noMotion;
  final VoidCallback? onDismiss;

  const VisualCelebration({
    super.key,
    this.message = 'أحسنت!',
    this.emoji,
    this.duration = const Duration(seconds: 3),
    this.calmMode = false,
    this.blindMode = false,
    this.deafMode = false,
    this.noMotion = false,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String message = 'أحسنت!',
    String? emoji,
    Duration duration = const Duration(seconds: 3),
    bool playSound = true,
    String? childName,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final profile = AccessibilityService.instance.profile.value;

    final isCalm = profile.sensoryCalmMode || profile.reducedAnimations ||
        profile.noFlashing || MediaQuery.disableAnimationsOf(context);
    final isBlind = profile.type == DisabilityType.blind;
    final isDeaf = profile.type == DisabilityType.deaf;
    final isDown = profile.type == DisabilityType.downSyndrome;
    final isAutismSevere = profile.type == DisabilityType.autismSevere;

    final noMotion = profile.reducedAnimations || profile.noFlashing ||
        MediaQuery.disableAnimationsOf(context);
    final untimed = profile.noTimedInteractions || profile.noTimers || profile.unlimitedTime;
    // ─── الصوت ───
    if (playSound && !profile.sensoryCalmMode && !isDeaf) {
      if (isDown) {
        EncouragementService.instance.praiseForDown(childName: childName);
      } else if (isAutismSevere) {
        TtsService.instance.speakLine('أحسنت');
      } else if (childName != null && childName.isNotEmpty) {
        EncouragementService.instance.praiseByName(childName);
      } else {
        EncouragementService.instance.praiseSuccess();
      }
    }

    // ─── للأعمى ───
    if (isBlind && profile.vibrationAlerts && !profile.sensoryCalmMode) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.mediumImpact();
    }

    // ─── للأصمّ ───
    if (isDeaf && profile.vibrationAlerts && !profile.sensoryCalmMode) {
      for (var i = 0; i < 3; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    final actualDuration = isCalm
        ? const Duration(seconds: 2)
        : isDeaf || isBlind
            ? const Duration(seconds: 4)
            : duration;

    final dismissed = Completer<void>();
    late OverlayEntry entry;
    void close() {
      if (dismissed.isCompleted) return;
      entry.remove();
      dismissed.complete();
    }
    entry = OverlayEntry(
      builder: (_) => VisualCelebration(
        message: message,
        emoji: emoji,
        duration: actualDuration,
        calmMode: isCalm,
        blindMode: isBlind,
        deafMode: isDeaf,
        noMotion: noMotion || untimed,
        onDismiss: untimed ? close : null,
      ),
    );

    try {
      overlay.insert(entry);
    } catch (_) {
      return;
    }

    if (untimed) {
      await dismissed.future;
    } else {
      await Future.delayed(actualDuration + const Duration(milliseconds: 500));
      close();
    }
  }

  @override
  State<VisualCelebration> createState() => _VisualCelebrationState();
}

class _VisualCelebrationState extends State<VisualCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (!widget.noMotion) _ctrl.forward();

    final int starCount;
    final List<String> emojis;
    final double speedFactor;

    if (widget.calmMode) {
      starCount = 8;
      emojis = ['⭐', '✨'];
      speedFactor = 0.5;
    } else if (widget.blindMode) {
      starCount = 6;
      emojis = ['⭐'];
      speedFactor = 0.7;
    } else if (widget.deafMode) {
      starCount = 40;
      emojis = ['⭐', '🌟', '✨', '💫', '🏆', '🎉', '🎊'];
      speedFactor = 1.2;
    } else {
      starCount = 30;
      emojis = ['⭐', '🌟', '✨', '💫', '🏆', '🎉', '🎊'];
      speedFactor = 1.0;
    }

    final rnd = Random();
    _stars = List.generate(starCount, (_) {
      return _Star(
        startX: 0.35 + rnd.nextDouble() * 0.3,
        startY: 0.4 + rnd.nextDouble() * 0.2,
        angle: rnd.nextDouble() * 2 * pi,
        distance: (120 + rnd.nextDouble() * 220) * speedFactor,
        size: 14 + rnd.nextDouble() * 20,
        emoji: emojis[rnd.nextInt(emojis.length)],
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noMotion) {
      return Positioned.fill(child: Center(child: Card(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.emoji ?? '⭐', style: const TextStyle(fontSize: 64)),
          Text(widget.message, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          if (widget.onDismiss != null) TextButton(onPressed: widget.onDismiss,
            child: const Text('متابعة')),
        ]),
      ))));
    }
    final size = MediaQuery.of(context).size;
    final messageFontSize = widget.deafMode ? 32.0 : 26.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final progress = _ctrl.value;
            return Container(
              color: Colors.black.withValues(alpha: progress * 0.35),
              child: Stack(
                children: [
                  ..._stars.map((star) {
                    final cx = size.width * star.startX +
                        cos(star.angle) * star.distance * progress;
                    final cy = size.height * star.startY +
                        sin(star.angle) * star.distance * progress;
                    final opacity = (1 - progress).clamp(0.0, 1.0);
                    final scale = 1.0 + progress * 0.5;

                    return Positioned(
                      left: cx - star.size / 2,
                      top: cy - star.size / 2,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Transform.rotate(
                            angle: progress * pi * 2,
                            child: Text(
                              star.emoji,
                              style: TextStyle(fontSize: star.size),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Center(
                    child: Transform.scale(
                      scale: _ctrl.value < 0.3
                          ? _ctrl.value / 0.3
                          : (1 + sin(_ctrl.value * pi) * 0.15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.emoji ?? '🎉',
                            style: TextStyle(
                              fontSize: widget.deafMode ? 110 : 90,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.deafMode ? 36 : 28,
                              vertical: widget.deafMode ? 22 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: messageFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orangeDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ✅ إصلاح: حذف حقل color الميت
class _Star {
  final double startX, startY, angle, distance, size;
  final String emoji;

  _Star({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.distance,
    required this.size,
    required this.emoji,
  });
}