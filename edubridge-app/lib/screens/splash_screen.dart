import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Branded Flutter splash shown immediately after the native Android splash.
///
/// The sequence intentionally mirrors the supplied motion reference:
/// dot -> logo reveal -> EduBridge wordmark -> tagline -> progress completion.
class EduBridgeSplashScreen extends StatefulWidget {
  const EduBridgeSplashScreen({super.key});

  @override
  State<EduBridgeSplashScreen> createState() => _EduBridgeSplashScreenState();
}

class _EduBridgeSplashScreenState extends State<EduBridgeSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..forward();

  double _stage(double start, double end, {Curve curve = Curves.easeOutCubic}) {
    final raw = (_controller.value - start) / (end - start);
    final value = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return curve.transform(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        // Match Android's mandatory native splash color exactly during the
        // hand-off. The Flutter gradient fades in only after the first frame.
        systemNavigationBarColor: const Color(0xFF3D66B8),
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF3D66B8),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final logo = _stage(0.10, 0.34, curve: Curves.easeOutBack);
                final wordmark = _stage(0.31, 0.62);
                final details = _stage(0.55, 0.78);
                final progress = _stage(0.18, 0.94, curve: Curves.easeInOutCubic);
                final background = _stage(0.03, 0.45);
                // Android 12+ only supports a solid native splash background.
                // Start Flutter on the exact same solid color, then softly
                // reveal the full branded gradient so no screen change is
                // visible between the two splash layers.
                // Keep the first Flutter frames identical to Android's
                // mandatory native splash. The gradient becomes part of the
                // animation only after the logo reveal has already started,
                // so the native -> Flutter hand-off is visually invisible.
                final gradientReveal =
                    _stage(0.22, 0.46, curve: Curves.easeInOutCubic);

                return ColoredBox(
                  color: const Color(0xFF3D66B8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: gradientReveal,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF3D66B8),
                                  Color(0xFF438BCB),
                                  Color(0xFF4DB5D9),
                                ],
                                stops: [0, 0.48, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _EducationBackdrop(
                        progress: background,
                        phase: _controller.value,
                        size: size,
                      ),

                      // Small seed dot, matching the opening beat of the video.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Opacity(
                              opacity: 1 - logo,
                              child: Transform.scale(
                                scale: 0.75 + (logo * 0.35),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.22),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: const Alignment(0, -0.03),
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - logo)),
                          child: Opacity(
                            opacity: logo,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 224,
                                  height: 224,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _HaloRing(
                                        size: 222,
                                        opacity: 0.07 * logo,
                                      ),
                                      _HaloRing(
                                        size: 174,
                                        opacity: 0.09 * logo,
                                      ),
                                      Container(
                                        width: 142,
                                        height: 142,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.17 * logo,
                                              ),
                                              blurRadius: 38,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Transform.scale(
                                          scale: 0.68 + (0.32 * logo),
                                          child: _AnimatedEduBridgeMark(
                                            progress: _controller.value,
                                            size: 142,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: wordmark,
                                      child: const Text(
                                        'EduBridge',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 46,
                                          height: 1,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Opacity(
                                  opacity: details,
                                  child: Transform.translate(
                                    offset: Offset(0, 8 * (1 - details)),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF72E0C5),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 28,
                                          ),
                                          child: Text(
                                            'قدرات مختلفة وإمكانات متساوية',
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              height: 1.45,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: math.max(26.0, size.height * 0.075),
                        child: Opacity(
                          opacity: details,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                color: Colors.white.withOpacity(0.18),
                                size: 27,
                              ),
                              const SizedBox(height: 6),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Container(
                                  width: 150,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.24,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'EduBridge',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.15,
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
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedEduBridgeMark extends StatelessWidget {
  final double progress;
  final double size;

  const _AnimatedEduBridgeMark({
    required this.progress,
    required this.size,
  });

  double _part(
    double start,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    final raw = (progress - start) / (end - start);
    final value = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return curve.transform(value);
  }

  @override
  Widget build(BuildContext context) {
    // Match the supplied reference: the mark is assembled in visible pieces
    // instead of fading in as one bitmap.
    final cap = _part(0.10, 0.19, curve: Curves.easeOutBack);
    final tassel = _part(0.16, 0.25);
    final center = _part(0.21, 0.31, curve: Curves.easeOutBack);
    final leftBridge = _part(0.27, 0.38);
    final rightBridge = _part(0.33, 0.44);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LogoSlice(
            progress: cap,
            clip: const Rect.fromLTWH(0.08, 0.02, 0.80, 0.31),
            offset: const Offset(0, -16),
          ),
          _LogoSlice(
            progress: tassel,
            clip: const Rect.fromLTWH(0.72, 0.10, 0.24, 0.39),
            offset: const Offset(10, -5),
          ),
          _LogoSlice(
            progress: center,
            clip: const Rect.fromLTWH(0.25, 0.29, 0.50, 0.39),
            offset: const Offset(0, 12),
          ),
          _LogoSlice(
            progress: leftBridge,
            clip: const Rect.fromLTWH(0.00, 0.53, 0.55, 0.43),
            offset: const Offset(-14, 8),
          ),
          _LogoSlice(
            progress: rightBridge,
            clip: const Rect.fromLTWH(0.45, 0.53, 0.55, 0.43),
            offset: const Offset(14, 8),
          ),
        ],
      ),
    );
  }
}

class _LogoSlice extends StatelessWidget {
  final double progress;
  final Rect clip;
  final Offset offset;

  const _LogoSlice({
    required this.progress,
    required this.clip,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(
          offset.dx * (1 - progress),
          offset.dy * (1 - progress),
        ),
        child: ClipRect(
          clipper: _NormalizedRectClipper(clip),
          child: Transform.scale(
            scale: 0.94 + (0.06 * progress),
            child: Image.asset(
              'assets/brand_icon.png',
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalizedRectClipper extends CustomClipper<Rect> {
  final Rect normalizedRect;

  const _NormalizedRectClipper(this.normalizedRect);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      normalizedRect.left * size.width,
      normalizedRect.top * size.height,
      normalizedRect.width * size.width,
      normalizedRect.height * size.height,
    );
  }

  @override
  bool shouldReclip(covariant _NormalizedRectClipper oldClipper) {
    return oldClipper.normalizedRect != normalizedRect;
  }
}

class _HaloRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _HaloRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 1.4,
        ),
      ),
    );
  }
}

class _EducationBackdrop extends StatelessWidget {
  final double progress;
  final double phase;
  final Size size;

  const _EducationBackdrop({
    required this.progress,
    required this.phase,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_BackdropItem>[
      const _BackdropItem(Icons.menu_book_outlined, 0.08, 0.12, 48, -0.2),
      const _BackdropItem(Icons.edit_outlined, 0.82, 0.08, 54, 0.5),
      const _BackdropItem(Icons.star_border_rounded, 0.14, 0.22, 32, 0.1),
      const _BackdropItem(Icons.star_border_rounded, 0.73, 0.18, 42, -0.5),
      const _BackdropItem(Icons.view_in_ar_outlined, 0.07, 0.34, 42, 0.6),
      const _BackdropItem(Icons.view_in_ar_outlined, 0.83, 0.37, 46, -0.3),
      const _BackdropItem(Icons.auto_awesome_outlined, 0.10, 0.50, 39, 0.2),
      const _BackdropItem(Icons.auto_awesome_outlined, 0.82, 0.48, 42, -0.7),
      const _BackdropItem(Icons.menu_book_outlined, 0.81, 0.62, 44, 0.4),
      const _BackdropItem(Icons.change_history_outlined, 0.14, 0.69, 42, -0.4),
      const _BackdropItem(Icons.change_history_outlined, 0.78, 0.73, 38, 0.8),
      const _BackdropItem(Icons.edit_note_outlined, 0.08, 0.82, 46, 0.0),
      const _BackdropItem(Icons.school_outlined, 0.80, 0.83, 42, 0.5),
      const _BackdropItem(Icons.star_border_rounded, 0.44, 0.86, 30, -0.2),
    ];

    return IgnorePointer(
      child: Opacity(
        opacity: 0.42 * progress,
        child: Stack(
          children: [
            for (var i = 0; i < items.length; i++)
              _buildItem(items[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(_BackdropItem item, int index) {
    final drift = math.sin((phase * math.pi * 2) + item.phase + index) * 5;
    return Positioned(
      left: size.width * item.x,
      top: size.height * item.y + drift,
      child: Transform.rotate(
        angle: item.phase * 0.12,
        child: Icon(
          item.icon,
          size: item.size,
          color: Colors.white.withOpacity(0.28),
        ),
      ),
    );
  }
}

class _BackdropItem {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double phase;

  const _BackdropItem(this.icon, this.x, this.y, this.size, this.phase);
}
