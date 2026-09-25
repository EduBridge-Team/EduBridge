// Splash logo painter and animation helpers.
part of 'splash_screen.dart';

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
