part of 'welcome_screen.dart';

extension _WelcomeMotion on _WelcomeScreenState {
  // One controller keeps the entrance sequence short and synchronized.
  Widget _motion(double delay, Widget child, {bool active = true}) {
    if (_reduceMotion || !active) return child;
    return AnimatedBuilder(
      animation: _entrance,
      child: child,
      builder: (_, content) {
        final progress = Curves.easeOutCubic.transform(
          ((_entrance.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(opacity: progress, child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress)), child: content));
      },
    );
  }

  Widget _floatingIllustration(int index) {
    final child = _illustration(index);
    if (_reduceMotion || index != _page) return child;
    return AnimatedBuilder(
      animation: _float,
      child: child,
      builder: (_, content) => Transform.translate(
        offset: Offset(0, math.sin(_float.value * math.pi * 2) * 4),
        child: content),
    );
  }
}
