// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════
//  الألوان
// ═══════════════════════════════════════════════════════════
const _bgTop = Color(0xFF3878C4);
const _bgMid = Color(0xFF4596D2);
const _bgBottom = Color(0xFF52A8DC);

/// ✅ لون الشعار أبيض (ليظهر على الخلفية الزرقاء)
const _logoColor = Colors.white;
const _glowColor = Color(0xFFB8DCFF);

const _canvasW = 1080.0;
const _canvasH = 1920.0;
const _assetScale = 0.571;
const _totalSeconds = 5.2;

// Timeline
const _fallEnd = 0.533;
const _bounceEnd = 0.767;
const _holeStart = 0.867;
const _holeEnd = 1.167;
const _drawStart = 1.008;
const _drawEnd = 1.583;
const _capStart = 1.4;
const _capLand = 1.8;
const _capSettle = 1.93;
const _exitStart = 2.117;
const _firstLanding = 2.6;
const _hop = 1 / 6;
const _rollOffDuration = 0.37;
const _glowStart = 4.467;
const _glowEnd = 5.083;

// Layout
const _ringOrigin = Offset(482, 821);
const _infinityOrigin = Offset(418, 873);
const _capOrigin = Offset(464, 743.5);
const _ringHole = Rect.fromLTWH(20, 20, 92, 89);
const _lift = 300.0;

// ✅ معدّلة: حروف "Bridge" مُقرّبة من "Edu" (بدون مسافة)
//    تم إزاحة حروف B, r, i, d, g, e بمقدار -50 بكسل على X
//    لتصبح المسافة بين "u" و "B" = 106 بكسل مثل باقي المسافات
const _letters = <_LetterSpec>[
  _LetterSpec('letter_1_E', Offset(87, 1032), 138),
  _LetterSpec('letter_2_d', Offset(189, 1025), 243),
  _LetterSpec('letter_3_u', Offset(304, 1058), 358),
  _LetterSpec('letter_4_B', Offset(408, 1032), 464),
  _LetterSpec('letter_5_r', Offset(524, 1056), 556),
  _LetterSpec('letter_6_i', Offset(593, 1018), 614),
  _LetterSpec('letter_7_d', Offset(638, 1025), 692),
  _LetterSpec('letter_8_g', Offset(748, 1057), 802),
  _LetterSpec('letter_9_e', Offset(854, 1057), 900),
];

const _ballDiameter = 26.0;
const _groundY = 994.0;
const _hopHeight = 14.0;
const _rollOffX = 992.0;

const _exitArc = <Offset>[
  Offset(503, 933), Offset(481, 916), Offset(451, 903),
  Offset(414, 895), Offset(375, 894), Offset(332, 900),
  Offset(286, 912), Offset(241, 931), Offset(198, 954),
  Offset(159, 978), Offset(137, 994),
];

const _infinityCenterline = <double>[
  173.8, 112.8, 167.3, 106.6, 160.6, 100.5, 154.6, 93.8, 148.6, 87.0,
  142.6, 80.2, 136.6, 73.5, 130.7, 66.7, 124.7, 59.9, 118.7, 53.2,
  112.7, 46.4, 106.7, 39.7, 100.1, 33.4, 93.2, 27.6, 86.1, 22.1,
  78.4, 17.3, 70.4, 13.2, 61.7, 10.9, 52.7, 10.0, 43.7, 10.4,
  35.0, 12.7, 27.3, 17.4, 21.0, 23.8, 16.1, 31.4, 12.7, 39.7,
  11.1, 48.6, 10.0, 57.6, 10.5, 66.6, 11.5, 75.6, 13.7, 84.3,
  16.5, 92.9, 20.6, 100.9, 25.4, 108.6, 31.0, 115.7, 37.2, 122.2,
  44.1, 128.0, 51.5, 133.2, 59.5, 137.5, 67.7, 141.2, 76.2, 144.3,
  85.0, 146.1, 94.0, 147.3, 103.0, 147.7, 111.9, 146.9, 120.8, 145.4,
  129.6, 143.1, 138.0, 140.0, 146.2, 136.1, 154.2, 131.9, 161.8, 127.0,
  168.1, 120.6, 174.6, 114.5, 182.5, 110.3, 189.0, 104.1, 195.7, 97.9,
  201.5, 91.1, 207.6, 84.3, 213.6, 77.6, 219.8, 71.1, 225.9, 64.4,
  232.1, 57.9, 238.5, 51.5, 245.1, 45.3, 252.2, 39.7, 259.8, 34.8,
  267.8, 30.7, 276.4, 27.8, 285.4, 27.0, 294.3, 27.8, 302.8, 30.8,
  310.0, 36.2, 315.7, 43.2, 319.2, 51.5, 320.9, 60.4, 321.1, 69.4,
  320.6, 78.4, 319.3, 87.3, 316.3, 95.8, 312.5, 104.0, 307.2, 111.4,
  301.3, 118.2, 294.6, 124.2, 287.4, 129.6, 279.5, 134.0, 271.2, 137.6,
  262.6, 140.4, 253.7, 141.7, 244.8, 142.9, 235.8, 142.4, 226.8, 141.0,
  218.0, 139.0, 209.6, 135.8, 201.6, 131.7, 194.0, 126.8, 186.7, 121.4,
  180.2, 115.2,
];

const _revealWidth = 24.0;
const _drawCurve = Cubic(0.354, 0.028, 0.782, 0.942);

final Path _infinityPath = () {
  final path = Path()..moveTo(_infinityCenterline[0], _infinityCenterline[1]);
  for (var i = 2; i < _infinityCenterline.length; i += 2) {
    path.lineTo(_infinityCenterline[i], _infinityCenterline[i + 1]);
  }
  return path;
}();

final double _infinityLength = _infinityPath.computeMetrics().first.length;

// ═══════════════════════════════════════════════════════════
//  Classes
// ═══════════════════════════════════════════════════════════
class _LetterSpec {
  const _LetterSpec(this.asset, this.origin, this.landingX);
  final String asset;
  final Offset origin;
  final double landingX;
}

class _Sprite {
  _Sprite(this.image, this.origin);
  final ui.Image image;
  final Offset origin;

  Rect get rect =>
      origin & Size(image.width * _assetScale, image.height * _assetScale);
}

class _Sprites {
  _Sprites({
    required this.cap,
    required this.ring,
    required this.infinity,
    required this.letters,
  });

  final _Sprite cap;
  final _Sprite ring;
  final _Sprite infinity;
  final List<_Sprite> letters;

  static Future<_Sprites> load() async {
    final cap = _load('shape_cap');
    final ring = _load('shape_circle');
    final infinity = _load('shape_infinity');
    final letters = [for (final l in _letters) _load(l.asset)];

    return _Sprites(
      cap: _Sprite(await cap, _capOrigin),
      ring: _Sprite(await ring, _ringOrigin),
      infinity: _Sprite(await infinity, _infinityOrigin),
      letters: [
        for (var i = 0; i < _letters.length; i++)
          _Sprite(await letters[i], _letters[i].origin),
      ],
    );
  }

  static Future<ui.Image> _load(String name) async {
    // ✅ المسار الصحيح — الصور في assets/ مباشرة
    final path = 'assets/$name.png';

    try {
      final data = await rootBundle.load(path);

      // ✅ التصحيح الحاسم: استخدام offsetInBytes و lengthInBytes
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('❌ فشل تحميل $path: $e');
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  خلفية الأيقونات
// ═══════════════════════════════════════════════════════════
class _IntroBackground extends StatelessWidget {
  const _IntroBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgMid, _bgBottom],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: const Stack(
        children: [
          _BgIcon(Icons.menu_book, Alignment(-0.80, -0.78), 48),
          _BgIcon(Icons.edit_outlined, Alignment(0.82, -0.88), 48,
              rotation: 0.5),
          _BgIcon(Icons.star_border, Alignment(-0.85, -0.45), 38),
          _BgIcon(Icons.star_border, Alignment(0.75, -0.60), 46),
          _BgIcon(Icons.view_in_ar, Alignment(-0.78, -0.25), 42),
          _BgIcon(Icons.view_in_ar, Alignment(0.82, -0.30), 42),
          _BgIcon(Icons.settings_outlined, Alignment(-0.85, 0.05), 44),
          _BgIcon(Icons.settings_outlined, Alignment(0.80, 0.05), 44,
              rotation: -0.3),
          _BgIcon(Icons.menu_book, Alignment(0.88, 0.20), 42),
          _BgIcon(Icons.diamond_outlined, Alignment(-0.80, 0.38), 46,
              rotation: 0.3),
          _BgIcon(Icons.diamond_outlined, Alignment(0.82, 0.40), 46,
              rotation: -0.3),
          _BgIcon(Icons.description_outlined, Alignment(-0.82, 0.70), 38),
          _BgIcon(Icons.lightbulb_outline, Alignment(0.82, 0.72), 42),
        ],
      ),
    );
  }
}

class _BgIcon extends StatelessWidget {
  final IconData icon;
  final Alignment alignment;
  final double size;
  final double rotation;

  const _BgIcon(this.icon, this.alignment, this.size, {this.rotation = 0});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          icon,
          size: size,
          color: Colors.white.withValues(alpha: 0.13),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Wrapper
// ═══════════════════════════════════════════════════════════
class EduBridgeSplashScreen extends StatelessWidget {
  const EduBridgeSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const LogoIntro();
}

// ═══════════════════════════════════════════════════════════
//  LogoIntro
// ═══════════════════════════════════════════════════════════
class LogoIntro extends StatefulWidget {
  const LogoIntro({super.key});

  @override
  State<LogoIntro> createState() => _LogoIntroState();
}

class _LogoIntroState extends State<LogoIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_totalSeconds * 1000).round()),
  );
  _Sprites? _sprites;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sprites = await _Sprites.load();
      if (!mounted) return;
      setState(() => _sprites = sprites);
      _controller.forward();
    } catch (e, st) {
      debugPrint('══════════════════════════════════════');
      debugPrint('❌ فشل تحميل شعار البداية');
      debugPrint('السبب: $e');
      debugPrint('$st');
      debugPrint('══════════════════════════════════════');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgMid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ═══ 1. الخلفية الأزرق + الأيقونات ═══
          const _IntroBackground(),

          // ═══ 2. الأنيميشن ═══
          if (_sprites != null)
            RepaintBoundary(
              child: CustomPaint(
                painter: _LogoPainter(_controller, _sprites!),
                size: Size.infinite,
              ),
            ),

          // ═══ 3. Fallback — لو فشل التحميل ═══
          if (_error != null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 110),
                  SizedBox(height: 24),
                  Text(
                    // ✅ "EduBridge" بدون مسافة
                    'EduBridge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: 56,
                    height: 3,
                    child: ColoredBox(color: Color(0xFF7BE49A)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'قدرات مختلفة وإمكانات متساوية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ═══ 4. مؤشر التحميل ═══
          if (_sprites == null && _error == null)
            const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Painter — نفس الحركة الأصلية + لون أبيض
// ═══════════════════════════════════════════════════════════
class _LogoPainter extends CustomPainter {
  _LogoPainter(this.controller, this.sprites) : super(repaint: controller);

  final AnimationController controller;
  final _Sprites sprites;

  @override
  void paint(Canvas canvas, Size size) {
    final t = controller.value * _totalSeconds;

    final scale = math.min(size.width / _canvasW, size.height / 1000);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-_canvasW / 2, -_canvasH / 2);
    final screenTop = _canvasH / 2 - size.height / (2 * scale);

    final glow = math.sin(math.pi * _seg(t, _glowStart, _glowEnd));
    if (glow > 0) _paintGlow(canvas, glow);

    _paintInfinity(canvas, t);
    _paintHead(canvas, t, screenTop);
    _paintCap(canvas, t);
    _paintLetters(canvas, t);
    _paintBall(canvas, t);
  }

  void _paintGlow(Canvas canvas, double amount) {
    final bounds = const Rect.fromLTRB(87, 744, 993, 1178).inflate(80);
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
    );
    final paint = _tint(_glowColor.withValues(alpha: amount * 0.55));
    _drawSprite(canvas, sprites.infinity, paint);
    _drawSprite(canvas, sprites.ring, paint);
    _drawSprite(canvas, sprites.cap, paint);
    for (final letter in sprites.letters) {
      _drawSprite(canvas, letter, paint);
    }
    canvas.restore();
  }

  void _paintInfinity(Canvas canvas, double t) {
    final progress = _seg(t, _drawStart, _drawEnd, _drawCurve);
    if (progress <= 0) return;
    final sprite = sprites.infinity;
    if (progress >= 1) {
      _drawSprite(canvas, sprite, _tint(_logoColor));
      return;
    }

    canvas.save();
    canvas.translate(sprite.origin.dx, sprite.origin.dy);
    canvas.scale(_assetScale);
    final bounds =
        Offset.zero &
        Size(sprite.image.width.toDouble(), sprite.image.height.toDouble());
    canvas.saveLayer(bounds.inflate(_revealWidth), Paint());
    canvas.drawImage(sprite.image, Offset.zero, _tint(_logoColor));
    canvas.saveLayer(
      bounds.inflate(_revealWidth),
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.drawPath(
      _infinityPath.computeMetrics().first.extractPath(
        0,
        math.max(_infinityLength * progress, 0.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _revealWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  void _paintHead(Canvas canvas, double t, double screenTop) {
    final ring = sprites.ring;
    final restRect = ring.rect;

    double bottom;
    double sx;
    double sy;
    if (t < _fallEnd) {
      final e = Curves.easeInQuad.transform(t / _fallEnd);
      bottom = ui.lerpDouble(screenTop - 12, restRect.bottom, e)!;
      sx = 1 - 0.04 * e;
      sy = 1 + 0.05 * e;
    } else {
      final u = _seg(t, _fallEnd, _bounceEnd);
      bottom = restRect.bottom - 30 * 4 * u * (1 - u);
      final q = t - _fallEnd;
      if (q < 0.035) {
        final a = q / 0.035;
        sx = ui.lerpDouble(0.96, 1.06, a)!;
        sy = ui.lerpDouble(1.05, 0.93, a)!;
      } else {
        final a = Curves.easeOut.transform(((q - 0.035) / 0.085).clamp(0, 1));
        sx = ui.lerpDouble(1.06, 1, a)!;
        sy = ui.lerpDouble(0.93, 1, a)!;
      }
    }

    final width = restRect.width * sx;
    final height = restRect.height * sy;
    final rect = Rect.fromLTWH(
      restRect.center.dx - width / 2,
      bottom - height,
      width,
      height,
    );

    final holeOpen = _seg(t, _holeStart, _holeEnd, Curves.easeOutCubic);
    if (holeOpen >= 1) {
      canvas.drawImageRect(
        ring.image,
        Offset.zero &
            Size(ring.image.width.toDouble(), ring.image.height.toDouble()),
        rect,
        _tint(_logoColor),
      );
      return;
    }

    final imageW = ring.image.width.toDouble();
    final imageH = ring.image.height.toDouble();
    final holeCentre = Offset(
      rect.left + _ringHole.center.dx / imageW * rect.width,
      rect.top + _ringHole.center.dy / imageH * rect.height,
    );
    final disc = Path()..addOval(rect);
    final hole = Path()
      ..addOval(
        Rect.fromCenter(
          center: holeCentre,
          width: _ringHole.width / imageW * rect.width * holeOpen,
          height: _ringHole.height / imageH * rect.height * holeOpen,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, disc, hole),
      Paint()..color = _logoColor,
    );
  }

  void _paintCap(Canvas canvas, double t) {
    if (t < _capStart) return;
    final sprite = sprites.cap;
    double lift;
    if (t < _capLand) {
      final e = Curves.easeInQuad.transform(_seg(t, _capStart, _capLand));
      lift = _lift * (1 - e);
    } else {
      lift = -9 * math.sin(math.pi * _seg(t, _capLand, _capSettle));
    }
    final opacity = _seg(t, _capStart, _capStart + 0.15);
    canvas.save();
    canvas.translate(0, -lift);
    _drawSprite(canvas, sprite, _tint(_logoColor.withValues(alpha: opacity)));
    canvas.restore();
  }

  void _paintLetters(Canvas canvas, double t) {
    for (var i = 0; i < sprites.letters.length; i++) {
      final landed = _firstLanding + i * _hop;
      final opacity = _seg(t, landed - 0.01, landed + 0.07);
      if (opacity <= 0) continue;
      _drawSprite(
        canvas,
        sprites.letters[i],
        _tint(_logoColor.withValues(alpha: opacity)),
      );
    }
  }

  void _paintBall(Canvas canvas, double t) {
    if (t < _exitStart) return;

    var centre = Offset.zero;
    var diameter = _ballDiameter;
    var sx = 1.0;
    var sy = 1.0;

    if (t < _firstLanding) {
      centre = _sampleArc(_seg(t, _exitStart, _firstLanding));
      diameter *= _seg(t, _exitStart, _exitStart + 0.12, Curves.easeOut);
    } else {
      final elapsed = t - _firstLanding;
      final hop = math.min(elapsed ~/ _hop, _letters.length - 1);
      final u = (elapsed - hop * _hop) / _hop;
      if (hop < _letters.length - 1) {
        final from = _letters[hop].landingX;
        final to = _letters[hop + 1].landingX;
        centre = Offset(
          ui.lerpDouble(from, to, u)!,
          _groundY - _hopHeight * 4 * u * (1 - u),
        );
      } else {
        final v = _seg(
          t,
          _firstLanding + hop * _hop,
          _firstLanding + hop * _hop + _rollOffDuration,
        );
        if (v >= 1) return;
        centre = Offset(
          ui.lerpDouble(_letters.last.landingX, _rollOffX, v)!,
          _groundY - _hopHeight * 4 * v * (1 - v),
        );
        diameter *= 1 - math.pow(v, 2.2);
      }
      final sinceLanding = elapsed - hop * _hop;
      if (sinceLanding < 0.06) {
        final bump = math.sin(math.pi * sinceLanding / 0.06);
        sx = 1 + 0.08 * bump;
        sy = 1 - 0.12 * bump;
      }
    }

    final bottom = centre.dy + diameter / 2;
    canvas.drawOval(
      Rect.fromLTRB(
        centre.dx - diameter * sx / 2,
        bottom - diameter * sy,
        centre.dx + diameter * sx / 2,
        bottom,
      ),
      Paint()..color = _logoColor,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.sprites != sprites;
}

double _seg(double t, double from, double to, [Curve curve = Curves.linear]) =>
    curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

Offset _sampleArc(double u) {
  final x = u * (_exitArc.length - 1);
  final i = math.min(x.floor(), _exitArc.length - 2);
  return Offset.lerp(_exitArc[i], _exitArc[i + 1], x - i)!;
}

Paint _tint(Color color) => Paint()
  ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
  ..filterQuality = FilterQuality.medium;

void _drawSprite(Canvas canvas, _Sprite sprite, Paint paint) {
  canvas.drawImageRect(
    sprite.image,
    Offset.zero &
        Size(sprite.image.width.toDouble(), sprite.image.height.toDouble()),
    sprite.rect,
    paint,
  );
}