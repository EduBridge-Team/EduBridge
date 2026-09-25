// Splash background widgets.
part of 'splash_screen.dart';

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
